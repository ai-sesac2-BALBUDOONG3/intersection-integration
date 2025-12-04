from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.security import OAuth2PasswordBearer
from sqlmodel import Session, select
from sqlalchemy import or_
from typing import List

from ..models import ChatRoom, ChatMessage, User, UserReport, UserBlock, get_kst_now
from ..schemas import ChatRoomCreate, ChatRoomRead, ChatMessageCreate, ChatMessageRead
from ..db import engine
from ..auth import decode_access_token

router = APIRouter(prefix="/chat", tags=["chat"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")


# WebSocket 연결 관리
class ConnectionManager:
    def __init__(self):
        # {user_id: WebSocket}
        self.active_connections: dict[int, WebSocket] = {}

    async def connect(self, user_id: int, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[user_id] = websocket

    def disconnect(self, user_id: int):
        if user_id in self.active_connections:
            del self.active_connections[user_id]

    async def send_message(self, user_id: int, message: dict):
        """특정 사용자에게 메시지 전송"""
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_json(message)


manager = ConnectionManager()


def get_current_user_id(token: str = Depends(oauth2_scheme)) -> int:
    """토큰에서 사용자 ID 추출"""
    payload = decode_access_token(token)
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user_id


# ------------------------------------------------------
# 1. 채팅방 생성 또는 조회
# ------------------------------------------------------
@router.post("/rooms", response_model=ChatRoomRead)
def create_or_get_chat_room(
    data: ChatRoomCreate,
    current_user_id: int = Depends(get_current_user_id)
):
    """
    친구와의 채팅방을 생성하거나 기존 채팅방을 반환합니다.
    """
    with Session(engine) as session:
        friend_id = data.friend_id
        
        # 자기 자신과는 채팅 불가
        if current_user_id == friend_id:
            raise HTTPException(status_code=400, detail="Cannot chat with yourself")
        
        # ========================================
        # ✅ 신고/차단 확인 (양방향)
        # ========================================
        # 1. 차단 확인
        block_statement = select(UserBlock).where(
            or_(
                (UserBlock.user_id == current_user_id) & (UserBlock.blocked_user_id == friend_id),
                (UserBlock.user_id == friend_id) & (UserBlock.blocked_user_id == current_user_id)
            )
        )
        is_blocked = session.exec(block_statement).first()
        if is_blocked:
            raise HTTPException(status_code=403, detail="차단된 사용자와는 채팅할 수 없습니다")
        
        # 2. 신고 확인
        report_statement = select(UserReport).where(
            or_(
                (UserReport.reporter_id == current_user_id) & (UserReport.reported_user_id == friend_id),
                (UserReport.reporter_id == friend_id) & (UserReport.reported_user_id == current_user_id)
            )
        )
        is_reported = session.exec(report_statement).first()
        if is_reported:
            raise HTTPException(status_code=403, detail="신고된 사용자와는 채팅할 수 없습니다")
        
        # ========================================
        
        # 기존 채팅방 확인 (user1_id와 user2_id 순서 무관)
        statement = select(ChatRoom).where(
            or_(
                (ChatRoom.user1_id == current_user_id) & (ChatRoom.user2_id == friend_id),
                (ChatRoom.user1_id == friend_id) & (ChatRoom.user2_id == current_user_id)
            )
        )
        existing_room = session.exec(statement).first()
        
        if existing_room:
            room = existing_room
        else:
            # 새 채팅방 생성
            room = ChatRoom(
                user1_id=current_user_id,
                user2_id=friend_id
            )
            session.add(room)
            session.commit()
            session.refresh(room)
        
        # 상대방 정보 조회
        friend = session.get(User, friend_id)
        friend_name = friend.name if friend else "Unknown"
        friend_profile_image = friend.profile_image if friend else None  # ✅ 프로필 이미지 추가
        
        # 마지막 메시지 조회
        last_msg_statement = select(ChatMessage).where(
            ChatMessage.room_id == room.id
        ).order_by(ChatMessage.created_at.desc()).limit(1)
        last_message = session.exec(last_msg_statement).first()
        
        # 읽지 않은 메시지 수 (상대방이 보낸 메시지 중 내가 안 읽은 것)
        unread_statement = select(ChatMessage).where(
            ChatMessage.room_id == room.id,
            ChatMessage.sender_id == friend_id,
            ChatMessage.is_read == False
        )
        unread_count = len(session.exec(unread_statement).all())
        
        # ========================================
        # ✅ 신고/차단 상태 확인 (통합)
        # ========================================
        # 1. 내가 상대방을 신고/차단했는지 (i_reported_them = i_blocked_them)
        i_reported_statement = select(UserReport).where(
            UserReport.reporter_id == current_user_id,
            UserReport.reported_user_id == friend_id
        )
        i_reported_them = session.exec(i_reported_statement).first() is not None
        
        i_blocked_statement = select(UserBlock).where(
            UserBlock.user_id == current_user_id,
            UserBlock.blocked_user_id == friend_id
        )
        i_blocked_them = session.exec(i_blocked_statement).first() is not None
        
        # 신고 또는 차단 중 하나라도 했으면 True
        i_reported_or_blocked = i_reported_them or i_blocked_them
        
        # 2. 상대방이 나를 신고/차단했는지 (they_blocked_me = they_reported_me)
        they_reported_statement = select(UserReport).where(
            UserReport.reporter_id == friend_id,
            UserReport.reported_user_id == current_user_id
        )
        they_reported_me = session.exec(they_reported_statement).first() is not None
        
        they_blocked_statement = select(UserBlock).where(
            UserBlock.user_id == friend_id,
            UserBlock.blocked_user_id == current_user_id
        )
        they_blocked_me_real = session.exec(they_blocked_statement).first() is not None
        
        # 신고 또는 차단 중 하나라도 당했으면 True
        they_blocked_or_reported = they_reported_me or they_blocked_me_real
        
        # ✅ 상대방이 채팅방을 나갔는지 확인
        they_left = (room.left_user_id == friend_id)
        
        return ChatRoomRead(
            id=room.id,
            user1_id=room.user1_id,
            user2_id=room.user2_id,
            friend_id=friend_id,
            friend_name=friend_name,
            last_message=last_message.content if last_message else None,
            last_message_time=last_message.created_at.isoformat() if last_message else None,
            unread_count=unread_count,
            created_at=room.created_at.isoformat(),
            # ✅ 마지막 메시지 상세 정보 추가
            last_message_type=last_message.message_type if last_message else None,
            last_file_url=last_message.file_url if last_message else None,
            last_file_name=last_message.file_name if last_message else None,
            # ✅ 친구 프로필 이미지 추가
            friend_profile_image=friend_profile_image,
            # ✅ 신고/차단 상태 추가 (통합)
            i_reported_them=i_reported_or_blocked,
            they_blocked_me=they_blocked_or_reported,
            # ✅ 채팅방 나가기 상태 추가
            they_left=they_left
        )


# ------------------------------------------------------
# 2. 내 채팅방 목록 조회
# ------------------------------------------------------
@router.get("/rooms", response_model=List[ChatRoomRead])
def get_my_chat_rooms(current_user_id: int = Depends(get_current_user_id)):
    """
    내가 참여한 모든 채팅방 목록을 반환합니다.
    """
    with Session(engine) as session:
        # 내가 user1 또는 user2인 채팅방 조회 (나간 채팅방 제외)
        statement = select(ChatRoom).where(
            or_(
                ChatRoom.user1_id == current_user_id,
                ChatRoom.user2_id == current_user_id
            )
        ).where(
            or_(
                ChatRoom.left_user_id != current_user_id,
                ChatRoom.left_user_id == None
            )
        ).order_by(ChatRoom.updated_at.desc())
        
        rooms = session.exec(statement).all()
        result = []
        
        for room in rooms:
            # 상대방 ID 찾기
            friend_id = room.user2_id if room.user1_id == current_user_id else room.user1_id
            friend = session.get(User, friend_id)
            friend_name = friend.name if friend else "Unknown"
            friend_profile_image = friend.profile_image if friend else None  # ✅ 프로필 이미지 추가
            
            # 마지막 메시지 조회
            last_msg_statement = select(ChatMessage).where(
                ChatMessage.room_id == room.id
            ).order_by(ChatMessage.created_at.desc()).limit(1)
            last_message = session.exec(last_msg_statement).first()
            
            # ✅ 메시지가 없는 채팅방은 목록에서 제외
            if not last_message:
                continue
            
            # 읽지 않은 메시지 수
            unread_statement = select(ChatMessage).where(
                ChatMessage.room_id == room.id,
                ChatMessage.sender_id == friend_id,
                ChatMessage.is_read == False
            )
            unread_count = len(session.exec(unread_statement).all())
            
            # ========================================
            # ✅ 신고/차단 상태 확인 (통합)
            # ========================================
            # 1. 내가 상대방을 신고/차단했는지
            i_reported_statement = select(UserReport).where(
                UserReport.reporter_id == current_user_id,
                UserReport.reported_user_id == friend_id
            )
            i_reported_them = session.exec(i_reported_statement).first() is not None
            
            i_blocked_statement = select(UserBlock).where(
                UserBlock.user_id == current_user_id,
                UserBlock.blocked_user_id == friend_id
            )
            i_blocked_them = session.exec(i_blocked_statement).first() is not None
            
            i_reported_or_blocked = i_reported_them or i_blocked_them
            
            # 2. 상대방이 나를 신고/차단했는지
            they_reported_statement = select(UserReport).where(
                UserReport.reporter_id == friend_id,
                UserReport.reported_user_id == current_user_id
            )
            they_reported_me = session.exec(they_reported_statement).first() is not None
            
            they_blocked_statement = select(UserBlock).where(
                UserBlock.user_id == friend_id,
                UserBlock.blocked_user_id == current_user_id
            )
            they_blocked_me_real = session.exec(they_blocked_statement).first() is not None
            
            they_blocked_or_reported = they_reported_me or they_blocked_me_real
            
            # ✅ 상대방이 채팅방을 나갔는지 확인
            they_left = (room.left_user_id == friend_id)
            
            result.append(ChatRoomRead(
                id=room.id,
                user1_id=room.user1_id,
                user2_id=room.user2_id,
                friend_id=friend_id,
                friend_name=friend_name,
                last_message=last_message.content if last_message else None,
                last_message_time=last_message.created_at.isoformat() if last_message else None,
                unread_count=unread_count,
                created_at=room.created_at.isoformat(),
                # ✅ 마지막 메시지 상세 정보 추가
                last_message_type=last_message.message_type if last_message else None,
                last_file_url=last_message.file_url if last_message else None,
                last_file_name=last_message.file_name if last_message else None,
                # ✅ 친구 프로필 이미지 추가
                friend_profile_image=friend_profile_image,
                # ✅ 신고/차단 상태 추가 (통합)
                i_reported_them=i_reported_or_blocked,
                they_blocked_me=they_blocked_or_reported,
                # ✅ 채팅방 나가기 상태 추가
                they_left=they_left,
                # ✅ 고정 여부 추가
                is_pinned=room.is_pinned
            ))
        
        # 고정된 채팅방을 먼저 정렬
        result.sort(key=lambda x: (
            not (x.is_pinned or False),  # 고정된 것이 먼저 (False가 먼저)
            x.last_message_time or ""  # 시간 역순
        ), reverse=True)
        
        return result


# ------------------------------------------------------
# 3. 채팅방의 메시지 목록 조회
# ------------------------------------------------------
@router.get("/rooms/{room_id}/messages", response_model=List[ChatMessageRead])
def get_chat_messages(
    room_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    """
    특정 채팅방의 모든 메시지를 조회합니다.
    """
    with Session(engine) as session:
        # 채팅방 권한 확인
        room = session.get(ChatRoom, room_id)
        if not room:
            raise HTTPException(status_code=404, detail="Chat room not found")
        
        if room.user1_id != current_user_id and room.user2_id != current_user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # 메시지 조회
        statement = select(ChatMessage).where(
            ChatMessage.room_id == room_id
        ).order_by(ChatMessage.created_at.asc())
        
        messages = session.exec(statement).all()
        
        # 상대방이 보낸 메시지를 읽음 처리
        for msg in messages:
            if msg.sender_id != current_user_id and not msg.is_read:
                msg.is_read = True
        
        session.commit()
        
        # ✅ 파일 정보 포함하여 반환 (고정된 메시지를 먼저 정렬)
        messages_list = [
            ChatMessageRead(
                id=msg.id,
                room_id=msg.room_id,
                sender_id=msg.sender_id,
                content=msg.content,
                message_type=msg.message_type,
                is_read=msg.is_read,
                created_at=msg.created_at.isoformat(),
                # ✅ 파일 정보 추가
                file_url=msg.file_url,
                file_name=msg.file_name,
                file_size=msg.file_size,
                file_type=msg.file_type,
                # ✅ 고정 여부 추가
                is_pinned=msg.is_pinned
            )
            for msg in messages
        ]
        
        # 시간 순서대로만 정렬 (고정 여부와 관계없이 원래 위치 유지)
        messages_list.sort(key=lambda x: x.created_at)
        
        return messages_list


# ------------------------------------------------------
# 4. 메시지 전송 (REST API) - ✅ 파일 업로드 지원
# ------------------------------------------------------
@router.post("/rooms/{room_id}/messages", response_model=ChatMessageRead)
def send_chat_message(
    room_id: int,
    data: ChatMessageCreate,
    current_user_id: int = Depends(get_current_user_id)
):
    """
    채팅방에 메시지를 전송합니다.
    파일 업로드 지원 - file_url이 있으면 파일 메시지로 전송
    """
    with Session(engine) as session:
        # 채팅방 권한 확인
        room = session.get(ChatRoom, room_id)
        if not room:
            raise HTTPException(status_code=404, detail="Chat room not found")
        
        if room.user1_id != current_user_id and room.user2_id != current_user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # 나간 채팅방인지 확인
        if room.left_user_id is not None and room.left_user_id == current_user_id:
            raise HTTPException(status_code=403, detail="나간 채팅방에서는 메시지를 보낼 수 없습니다")
        
        # ========================================
        # ✅ 신고/차단 확인 (양방향)
        # ========================================
        friend_id = room.user2_id if room.user1_id == current_user_id else room.user1_id
        
        # 1. 차단 확인 (양방향)
        block_statement = select(UserBlock).where(
            or_(
                (UserBlock.user_id == current_user_id) & (UserBlock.blocked_user_id == friend_id),
                (UserBlock.user_id == friend_id) & (UserBlock.blocked_user_id == current_user_id)
            )
        )
        is_blocked = session.exec(block_statement).first()
        if is_blocked:
            raise HTTPException(status_code=403, detail="차단된 사용자와는 채팅할 수 없습니다")
        
        # 2. 신고 확인 (양방향)
        report_statement = select(UserReport).where(
            or_(
                (UserReport.reporter_id == current_user_id) & (UserReport.reported_user_id == friend_id),
                (UserReport.reporter_id == friend_id) & (UserReport.reported_user_id == current_user_id)
            )
        )
        is_reported = session.exec(report_statement).first()
        if is_reported:
            raise HTTPException(status_code=403, detail="신고된 사용자와는 채팅할 수 없습니다")
        
        # ========================================
        # ✅ message_type 자동 설정 (개선)
        # ========================================
        message_type = "normal"
        
        if data.file_url:
            # 1. file_type으로 확인 (가장 정확)
            if data.file_type:
                file_type_lower = data.file_type.lower()
                if ('image' in file_type_lower or 
                    'png' in file_type_lower or 
                    'jpg' in file_type_lower or 
                    'jpeg' in file_type_lower or
                    'gif' in file_type_lower or
                    'webp' in file_type_lower):
                    message_type = "image"
                else:
                    message_type = "file"
            # 2. file_name으로 확인 (file_type이 없을 경우)
            elif data.file_name:
                file_name_lower = data.file_name.lower()
                if (file_name_lower.endswith('.png') or 
                    file_name_lower.endswith('.jpg') or 
                    file_name_lower.endswith('.jpeg') or
                    file_name_lower.endswith('.gif') or
                    file_name_lower.endswith('.webp')):
                    message_type = "image"
                else:
                    message_type = "file"
            # 3. file_url로 확인 (최후 수단)
            else:
                file_url_lower = data.file_url.lower()
                if (file_url_lower.endswith('.png') or 
                    file_url_lower.endswith('.jpg') or 
                    file_url_lower.endswith('.jpeg') or
                    file_url_lower.endswith('.gif') or
                    file_url_lower.endswith('.webp')):
                    message_type = "image"
                else:
                    message_type = "file"
        
        # 메시지 생성
        message = ChatMessage(
            room_id=room_id,
            sender_id=current_user_id,
            content=data.content,
            message_type=message_type,
            # ✅ 파일 정보 저장
            file_url=data.file_url,
            file_name=data.file_name,
            file_size=data.file_size,
            file_type=data.file_type
        )
        session.add(message)
        
        # 채팅방 업데이트 시간 갱신 (한국 시간)
        room.updated_at = get_kst_now()
        
        session.commit()
        session.refresh(message)
        
        return ChatMessageRead(
            id=message.id,
            room_id=message.room_id,
            sender_id=message.sender_id,
            content=message.content,
            message_type=message.message_type,
            is_read=message.is_read,
            created_at=message.created_at.isoformat(),
            # ✅ 파일 정보 반환
            file_url=message.file_url,
            file_name=message.file_name,
            file_size=message.file_size,
            file_type=message.file_type,
            # ✅ 고정 여부 반환
            is_pinned=message.is_pinned
        )


@router.put("/rooms/{room_id}/pin")
def toggle_pin_chat_room(
    room_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    """
    채팅방 고정/고정 해제
    """
    with Session(engine) as session:
        room = session.get(ChatRoom, room_id)
        if not room:
            raise HTTPException(status_code=404, detail="Chat room not found")
        
        if room.user1_id != current_user_id and room.user2_id != current_user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        room.is_pinned = not room.is_pinned
        session.add(room)
        session.commit()
        session.refresh(room)
        
        return {"is_pinned": room.is_pinned}


@router.put("/rooms/{room_id}/messages/{message_id}/pin")
def toggle_pin_message(
    room_id: int,
    message_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    """
    메시지 고정/고정 해제
    """
    with Session(engine) as session:
        # 채팅방 권한 확인
        room = session.get(ChatRoom, room_id)
        if not room:
            raise HTTPException(status_code=404, detail="Chat room not found")
        
        if room.user1_id != current_user_id and room.user2_id != current_user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # 메시지 조회
        message = session.get(ChatMessage, message_id)
        if not message:
            raise HTTPException(status_code=404, detail="Message not found")
        
        if message.room_id != room_id:
            raise HTTPException(status_code=400, detail="Message does not belong to this room")
        
        message.is_pinned = not message.is_pinned
        session.add(message)
        session.commit()
        session.refresh(message)
        
        return {"is_pinned": message.is_pinned}


@router.delete("/rooms/{room_id}")
def leave_chat_room(
    room_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    """채팅방 나가기 (나간 사용자만 제외, 상대방에게 시스템 메시지 전송)"""
    with Session(engine) as session:
        room = session.get(ChatRoom, room_id)
        if not room:
            raise HTTPException(status_code=404, detail="채팅방을 찾을 수 없습니다")
        
        # 참여자 확인
        if current_user_id != room.user1_id and current_user_id != room.user2_id:
            raise HTTPException(status_code=403, detail="이 채팅방의 참여자가 아닙니다")
        
        # 이미 나간 채팅방인지 확인
        if room.left_user_id == current_user_id:
            raise HTTPException(status_code=400, detail="이미 나간 채팅방입니다")
        
        # ✅ 상대방이 이미 나갔는지 확인
        friend_id = room.user2_id if room.user1_id == current_user_id else room.user1_id
        other_user_already_left = (room.left_user_id == friend_id)
        
        # ✅ 양쪽 다 나간 경우: 채팅방과 메시지 모두 삭제
        if other_user_already_left:
            # 1. 채팅방의 모든 메시지 삭제
            delete_messages_statement = select(ChatMessage).where(
                ChatMessage.room_id == room_id
            )
            messages = session.exec(delete_messages_statement).all()
            for msg in messages:
                session.delete(msg)
            
            # 2. 채팅방 삭제
            session.delete(room)
            session.commit()
            
            return {"message": "채팅방을 나갔습니다. 대화 내용이 삭제되었습니다."}
        
        # ✅ 한쪽만 나간 경우: left_user_id 업데이트
        room.left_user_id = current_user_id
        session.add(room)
        
        # 상대방에게 시스템 메시지 전송
        system_message = ChatMessage(
            room_id=room_id,
            sender_id=current_user_id,
            content="상대방이 채팅방을 나갔습니다.",
            message_type="system",
            is_read=False
        )
        session.add(system_message)
        
        # 채팅방 업데이트 시간 갱신
        room.updated_at = get_kst_now()
        
        session.commit()
        
        return {"message": "채팅방을 나갔습니다"}


# ------------------------------------------------------
# 5. WebSocket 실시간 채팅
# ------------------------------------------------------
@router.websocket("/ws/{room_id}")
async def websocket_chat(websocket: WebSocket, room_id: int, token: str):
    """
    WebSocket을 통한 실시간 채팅
    사용법: ws://localhost:8000/chat/ws/{room_id}?token=YOUR_JWT_TOKEN
    """
    # 토큰 검증
    try:
        payload = decode_access_token(token)
        user_id = payload.get("user_id")
        if not user_id:
            await websocket.close(code=1008)
            return
    except:
        await websocket.close(code=1008)
        return
    
    # 채팅방 권한 확인
    with Session(engine) as session:
        room = session.get(ChatRoom, room_id)
        if not room:
            await websocket.close(code=1008)
            return
        
        if room.user1_id != user_id and room.user2_id != user_id:
            await websocket.close(code=1008)
            return
        
        # 상대방 ID
        friend_id = room.user2_id if room.user1_id == user_id else room.user1_id
    
    # WebSocket 연결
    await manager.connect(user_id, websocket)
    
    try:
        while True:
            # 메시지 수신
            data = await websocket.receive_json()
            content = data.get("content")
            
            if not content:
                continue
            
            # DB에 메시지 저장
            with Session(engine) as session:
                message = ChatMessage(
                    room_id=room_id,
                    sender_id=user_id,
                    content=content
                )
                session.add(message)
                
                # 채팅방 업데이트 시간 갱신 (한국 시간)
                room = session.get(ChatRoom, room_id)
                room.updated_at = get_kst_now()
                
                session.commit()
                session.refresh(message)
                
                # 응답 데이터
                response = {
                    "id": message.id,
                    "room_id": message.room_id,
                    "sender_id": message.sender_id,
                    "content": message.content,
                    "is_read": message.is_read,
                    "created_at": message.created_at.isoformat()
                }
                
                # 본인에게 전송
                await manager.send_message(user_id, response)
                
                # 상대방에게 전송 (온라인이면)
                await manager.send_message(friend_id, response)
    
    except WebSocketDisconnect:
        manager.disconnect(user_id)