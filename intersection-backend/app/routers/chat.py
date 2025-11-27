from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.security import OAuth2PasswordBearer
from sqlmodel import Session, select
from typing import List

from ..models import ChatRoom, ChatMessage, User, get_kst_now
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
        
        # 기존 채팅방 확인 (user1_id와 user2_id 순서 무관)
        statement = select(ChatRoom).where(
            ((ChatRoom.user1_id == current_user_id) & (ChatRoom.user2_id == friend_id)) |
            ((ChatRoom.user1_id == friend_id) & (ChatRoom.user2_id == current_user_id))
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
        
        return ChatRoomRead(
            id=room.id,
            user1_id=room.user1_id,
            user2_id=room.user2_id,
            friend_id=friend_id,
            friend_name=friend_name,
            last_message=last_message.content if last_message else None,
            last_message_time=last_message.created_at.isoformat() if last_message else None,
            unread_count=unread_count,
            created_at=room.created_at.isoformat()
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
        # 내가 user1 또는 user2인 채팅방 조회
        statement = select(ChatRoom).where(
            (ChatRoom.user1_id == current_user_id) | (ChatRoom.user2_id == current_user_id)
        ).order_by(ChatRoom.updated_at.desc())
        
        rooms = session.exec(statement).all()
        result = []
        
        for room in rooms:
            # 상대방 ID 찾기
            friend_id = room.user2_id if room.user1_id == current_user_id else room.user1_id
            friend = session.get(User, friend_id)
            friend_name = friend.name if friend else "Unknown"
            
            # 마지막 메시지 조회
            last_msg_statement = select(ChatMessage).where(
                ChatMessage.room_id == room.id
            ).order_by(ChatMessage.created_at.desc()).limit(1)
            last_message = session.exec(last_msg_statement).first()
            
            # 읽지 않은 메시지 수
            unread_statement = select(ChatMessage).where(
                ChatMessage.room_id == room.id,
                ChatMessage.sender_id == friend_id,
                ChatMessage.is_read == False
            )
            unread_count = len(session.exec(unread_statement).all())
            
            result.append(ChatRoomRead(
                id=room.id,
                user1_id=room.user1_id,
                user2_id=room.user2_id,
                friend_id=friend_id,
                friend_name=friend_name,
                last_message=last_message.content if last_message else None,
                last_message_time=last_message.created_at.isoformat() if last_message else None,
                unread_count=unread_count,
                created_at=room.created_at.isoformat()
            ))
        
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
        
        return [
            ChatMessageRead(
                id=msg.id,
                room_id=msg.room_id,
                sender_id=msg.sender_id,
                content=msg.content,
                is_read=msg.is_read,
                created_at=msg.created_at.isoformat()
            )
            for msg in messages
        ]


# ------------------------------------------------------
# 4. 메시지 전송 (REST API)
# ------------------------------------------------------
@router.post("/rooms/{room_id}/messages", response_model=ChatMessageRead)
def send_chat_message(
    room_id: int,
    data: ChatMessageCreate,
    current_user_id: int = Depends(get_current_user_id)
):
    """
    채팅방에 메시지를 전송합니다.
    """
    with Session(engine) as session:
        # 채팅방 권한 확인
        room = session.get(ChatRoom, room_id)
        if not room:
            raise HTTPException(status_code=404, detail="Chat room not found")
        
        if room.user1_id != current_user_id and room.user2_id != current_user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # 메시지 생성
        message = ChatMessage(
            room_id=room_id,
            sender_id=current_user_id,
            content=data.content
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
            is_read=message.is_read,
            created_at=message.created_at.isoformat()
        )


@router.delete("/rooms/{room_id}")
def delete_chat_room(
    room_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    """채팅방 나가기 (삭제)"""
    with Session(engine) as session:
        room = session.get(ChatRoom, room_id)
        if not room:
            raise HTTPException(status_code=404, detail="채팅방을 찾을 수 없습니다")
        
        # 참여자 확인
        if current_user_id != room.user1_id and current_user_id != room.user2_id:
            raise HTTPException(status_code=403, detail="이 채팅방의 참여자가 아닙니다")
        
        # 채팅방과 관련된 모든 메시지 삭제
        messages_statement = select(ChatMessage).where(ChatMessage.room_id == room_id)
        messages = session.exec(messages_statement).all()
        for message in messages:
            session.delete(message)
        
        # 채팅방 삭제
        session.delete(room)
        session.commit()
        
        return {"message": "채팅방이 삭제되었습니다"}


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

