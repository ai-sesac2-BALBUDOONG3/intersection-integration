from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional, List
from pydantic import BaseModel
from sqlmodel import Session, select, desc
from sqlalchemy import or_

# 🔥 스키마 및 모델 임포트
from ..schemas import UserCreate, UserRead, UserUpdate, Token, NotificationRead
from ..models import (
    User, Post, Comment, UserFriendship, ChatRoom, ChatMessage, 
    UserBlock, UserReport, PostLike, CommentLike, PostReport, 
    CommentReport, Notification
)
from ..db import engine
from ..auth import get_password_hash, verify_password, create_access_token, decode_access_token
from fastapi.security import OAuth2PasswordBearer
from ..services import assign_community, get_recommended_friends

# 🔥 [핵심 수정] 순환 참조 해결을 위해 dependencies에서 가져옴
from ..dependencies import get_current_user

router = APIRouter(tags=["users"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")

class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/token", response_model=Token, tags=["auth"])
def login_for_token(login_data: LoginRequest):
    with Session(engine) as session:
        statement = select(User).where(
            or_(
                User.email == login_data.email,
                User.login_id == login_data.email
            )
        )
        user = session.exec(statement).first()

        if not user or not verify_password(login_data.password, user.password_hash):
            raise HTTPException(status_code=401, detail="Incorrect email or password")

        token = create_access_token({"user_id": user.id})
        return {"access_token": token, "token_type": "bearer"}


@router.post("/users/", response_model=UserRead)
def create_user(data: UserCreate):
    with Session(engine) as session:
        statement = select(User).where(User.login_id == data.login_id)
        exists = session.exec(statement).first()
        if exists:
            raise HTTPException(status_code=400, detail="login_id already exists")

        # 여러 학교 정보를 JSON 형식으로 저장
        schools_json = None
        if data.schools:
            schools_json = data.schools
        elif data.school_name:  # 하위 호환성: 기존 단일 학교 정보를 JSON으로 변환
            schools_json = [{
                "name": data.school_name,
                "school_type": data.school_type,
                "admission_year": data.admission_year
            }]

        user = User(
            login_id=data.login_id, 
            name=data.name, 
            nickname=data.nickname, 
            birth_year=data.birth_year, 
            gender=data.gender,
            region=data.region, 
            school_name=data.school_name,  # 하위 호환성
            school_type=data.school_type,  # 하위 호환성
            admission_year=data.admission_year,  # 하위 호환성
            schools=schools_json,  # 여러 학교 정보 (JSON)
            email=data.login_id,
            phone=data.phone,
            profile_image=data.profile_image,
            background_image=data.background_image
        )
        user.password_hash = get_password_hash(data.password)
        session.add(user)
        session.commit()
        session.refresh(user)

        # 커뮤니티 자동 배정
        assign_community(session, user)
        session.add(user)
        session.commit()
        session.refresh(user)

        return UserRead(
            id=user.id, 
            name=user.name,
            nickname=user.nickname,
            birth_year=user.birth_year,
            gender=user.gender,
            region=user.region, 
            school_name=user.school_name,  # 하위 호환성
            school_type=user.school_type,  # 하위 호환성
            admission_year=user.admission_year,  # 하위 호환성
            schools=user.schools if isinstance(user.schools, list) else (list(user.schools.values()) if user.schools else None),  # 여러 학교 정보 (JSON)
            phone=user.phone,
            profile_image=user.profile_image,
            background_image=user.background_image,
            feed_images=[]
        )


@router.get("/users/me", response_model=UserRead)
def get_my_info(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        # 내 게시글 이미지들 (피드용)
        statement = (
            select(Post)
            .where(Post.author_id == current_user.id)
            .where(Post.image_url != None)
            .order_by(desc(Post.created_at))
        )
        my_posts = session.exec(statement).all()
        feed_images_list = [post.image_url for post in my_posts if post.image_url]

        return UserRead(
            id=current_user.id, 
            name=current_user.name, 
            nickname=current_user.nickname,
            birth_year=current_user.birth_year,
            gender=current_user.gender,
            region=current_user.region, 
            school_name=current_user.school_name,  # 하위 호환성
            school_type=current_user.school_type,  # 하위 호환성
            admission_year=current_user.admission_year,  # 하위 호환성
            schools=current_user.schools if isinstance(current_user.schools, list) else (list(current_user.schools.values()) if current_user.schools else None),  # 여러 학교 정보 (JSON)
            phone=current_user.phone,
            profile_image=current_user.profile_image,
            background_image=current_user.background_image,
            feed_images=feed_images_list
        )


@router.get("/users/{user_id}", response_model=UserRead)
def get_user_by_id_api(
    user_id: int,
    current_user: User = Depends(get_current_user)
):
    """
    특정 사용자 정보 조회 API (피드 이미지 포함)
    """
    with Session(engine) as session:
        user = get_user_by_id(session, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # 해당 사용자의 게시글 이미지들 (피드용)
        statement = (
            select(Post)
            .where(Post.author_id == user_id)
            .where(Post.image_url != None)
            .order_by(desc(Post.created_at))
        )
        user_posts = session.exec(statement).all()
        feed_images_list = [post.image_url for post in user_posts if post.image_url]
        
        return UserRead(
            id=user.id, 
            name=user.name, 
            nickname=user.nickname,
            birth_year=user.birth_year,
            gender=user.gender,
            region=user.region, 
            school_name=user.school_name,  # 하위 호환성
            school_type=user.school_type,  # 하위 호환성
            admission_year=user.admission_year,  # 하위 호환성
            schools=user.schools if isinstance(user.schools, list) else (list(user.schools.values()) if user.schools else None),  # 여러 학교 정보 (JSON)
            phone=user.phone,
            profile_image=user.profile_image,
            background_image=user.background_image,
            feed_images=feed_images_list
        )


@router.get("/users/me/recommended", response_model=list[UserRead])
def recommended(current_user: User = Depends(get_current_user)):
    """
    추천 친구 목록 조회
    - 차단/신고 필터링은 services.py 내부에서 이미 처리되어 나옵니다.
    - 여기서는 그냥 받아서 넘겨주기만 하면 됩니다. (중복 제거됨)
    """
    with Session(engine) as session:
        # ✅ await 없이 일반 함수로 호출 (Redis 없음)
        friends = get_recommended_friends(session, current_user)
        
        return [
            UserRead(
                id=u.id, 
                name=u.name, 
                birth_year=u.birth_year, 
                region=u.region, 
                school_name=u.school_name,
                profile_image=u.profile_image,
                background_image=u.background_image
            ) for u in friends
        ]


@router.put("/users/me", response_model=UserRead)
def update_my_info(data: UserUpdate, token: str = Depends(oauth2_scheme)):
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")

    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")

    with Session(engine) as session:
        # 순환 참조 방지를 위해 여기서 직접 조회하거나 get_user_by_id를 별도로 구현
        # 여기서는 Session으로 직접 조회
        user = session.get(User, int(user_id))
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # 필드 업데이트
        if data.name is not None: user.name = data.name
        if data.nickname is not None: user.nickname = data.nickname
        if data.birth_year is not None: user.birth_year = data.birth_year
        if data.gender is not None: user.gender = data.gender
        if data.region is not None: user.region = data.region
        if data.school_name is not None: user.school_name = data.school_name  # 하위 호환성
        if data.school_type is not None: user.school_type = data.school_type  # 하위 호환성
        if data.admission_year is not None: user.admission_year = data.admission_year  # 하위 호환성
        if data.schools is not None: user.schools = data.schools  # 여러 학교 정보 (JSON)
        
        if data.profile_image is not None:
            user.profile_image = data.profile_image
        if data.background_image is not None:
            user.background_image = data.background_image

        session.add(user)
        session.commit()
        session.refresh(user)

        # 정보 변경에 따른 커뮤니티 재배정
        assign_community(session, user)
        session.add(user)
        session.commit()
        session.refresh(user)

        # 피드 이미지 재조회
        statement = (
            select(Post)
            .where(Post.author_id == user.id)
            .where(Post.image_url != None)
            .order_by(desc(Post.created_at))
        )
        my_posts = session.exec(statement).all()
        feed_images_list = [post.image_url for post in my_posts if post.image_url]

        return UserRead(
            id=user.id, 
            name=user.name,
            nickname=user.nickname,
            birth_year=user.birth_year,
            gender=user.gender,
            region=user.region, 
            school_name=user.school_name,  # 하위 호환성
            school_type=user.school_type,  # 하위 호환성
            admission_year=user.admission_year,  # 하위 호환성
            schools=user.schools if isinstance(user.schools, list) else (list(user.schools.values()) if user.schools else None),  # 여러 학교 정보 (JSON)
            phone=user.phone,
            profile_image=user.profile_image,
            background_image=user.background_image,
            feed_images=feed_images_list 
        )


# ------------------------------------------------------
# 🔔 내 알림 목록 조회 API
# ------------------------------------------------------
@router.get("/users/me/notifications", response_model=List[NotificationRead])
def get_my_notifications(current_user: User = Depends(get_current_user)):
    """내 알림 목록 조회 (최신순)"""
    with Session(engine) as session:
        statement = (
            select(Notification, User)
            .join(User, Notification.sender_id == User.id)
            .where(Notification.receiver_id == current_user.id)
            .order_by(Notification.created_at.desc())
        )
        results = session.exec(statement).all()
        
        notif_list = []
        for notif, sender in results:
            sender_name = sender.name or sender.nickname or "알 수 없음"
            
            notif_list.append(NotificationRead(
                id=notif.id,
                sender_id=notif.sender_id,
                sender_name=sender_name,
                sender_profile_image=sender.profile_image, 
                type=notif.type,
                message=notif.message,
                related_post_id=notif.related_post_id,
                is_read=notif.is_read,
                created_at=notif.created_at.isoformat()
            ))
            
        return notif_list


# ------------------------------------------------------
# 🔍 유저 검색 API (신규 추가됨)
# ------------------------------------------------------
@router.get("/users/search", response_model=List[UserRead])
def search_users(
    keyword: str, 
    current_user: User = Depends(get_current_user)
):
    """
    🔍 유저 검색 API (이름 또는 닉네임)
    """
    if not keyword:
        return []

    with Session(engine) as session:
        statement = select(User).where(
            or_(
                User.name.contains(keyword),
                User.nickname.contains(keyword)
            )
        ).where(User.id != current_user.id)  # 나 자신은 검색 제외
        
        # 차단한 유저 제외가 필요하면 여기에 추가
        
        results = session.exec(statement).limit(20).all() # 최대 20명만
        
        return [
            UserRead(
                id=u.id, 
                name=u.name, 
                nickname=u.nickname,
                birth_year=u.birth_year, 
                region=u.region, 
                school_name=u.school_name,
                profile_image=u.profile_image,
                background_image=u.background_image
            ) for u in results
        ]

@router.delete("/users/me", status_code=status.HTTP_204_NO_CONTENT)
def withdraw_account(current_user: User = Depends(get_current_user)):
    """
    🗑️ 회원탈퇴 (계정 삭제)
    - 사용자의 모든 활동 데이터(게시글, 댓글, 좋아요, 친구, 채팅 등)를 먼저 삭제합니다.
    - 마지막으로 사용자 정보를 DB에서 완전히 삭제합니다.
    - 삭제 후에는 로그인이 불가능합니다.
    """
    with Session(engine) as session:
        # 현재 세션에서 유저를 다시 조회 (안전한 삭제를 위해)
        user_in_db = session.get(User, current_user.id)
        if not user_in_db:
            return # 이미 삭제된 경우

        user_id = user_in_db.id
        
        # 1. 💬 채팅 관련 데이터 삭제
        chat_rooms = session.exec(
            select(ChatRoom).where(
                or_(ChatRoom.user1_id == user_id, ChatRoom.user2_id == user_id)
            )
        ).all()
        
        for room in chat_rooms:
            # 채팅방의 모든 메시지 삭제
            messages = session.exec(select(ChatMessage).where(ChatMessage.room_id == room.id)).all()
            for msg in messages:
                session.delete(msg)
            # 채팅방 자체 삭제
            session.delete(room)

        # 2. 📝 내 게시글과 그 하위 데이터 삭제
        my_posts = session.exec(select(Post).where(Post.author_id == user_id)).all()
        for post in my_posts:
            # 댓글 삭제
            comments = session.exec(select(Comment).where(Comment.post_id == post.id)).all()
            for comment in comments:
                # 댓글 좋아요/신고 삭제
                for cl in session.exec(select(CommentLike).where(CommentLike.comment_id == comment.id)).all():
                    session.delete(cl)
                for cr in session.exec(select(CommentReport).where(CommentReport.reported_comment_id == comment.id)).all():
                    session.delete(cr)
                session.delete(comment)
            
            # 게시글 좋아요/신고/알림 삭제
            for pl in session.exec(select(PostLike).where(PostLike.post_id == post.id)).all():
                session.delete(pl)
            for pr in session.exec(select(PostReport).where(PostReport.reported_post_id == post.id)).all():
                session.delete(pr)
            for n in session.exec(select(Notification).where(Notification.related_post_id == post.id)).all():
                session.delete(n)
            
            session.delete(post)

        # 3. ✍️ 내가 쓴 댓글 삭제
        my_comments = session.exec(select(Comment).where(Comment.user_id == user_id)).all()
        for comment in my_comments:
            for cl in session.exec(select(CommentLike).where(CommentLike.comment_id == comment.id)).all():
                session.delete(cl)
            for cr in session.exec(select(CommentReport).where(CommentReport.reported_comment_id == comment.id)).all():
                session.delete(cr)
            session.delete(comment)

        # 4. ❤️ 기타 활동 내역 삭제 (좋아요, 신고, 차단)
        for pl in session.exec(select(PostLike).where(PostLike.user_id == user_id)).all():
            session.delete(pl)
        for cl in session.exec(select(CommentLike).where(CommentLike.user_id == user_id)).all():
            session.delete(cl)

        for pr in session.exec(select(PostReport).where(PostReport.reporter_id == user_id)).all():
            session.delete(pr)
        for cr in session.exec(select(CommentReport).where(CommentReport.reporter_id == user_id)).all():
            session.delete(cr)
        
        user_reports = session.exec(select(UserReport).where(
            or_(UserReport.reporter_id == user_id, UserReport.reported_user_id == user_id)
        )).all()
        for ur in user_reports: session.delete(ur)

        user_blocks = session.exec(select(UserBlock).where(
            or_(UserBlock.user_id == user_id, UserBlock.blocked_user_id == user_id)
        )).all()
        for ub in user_blocks: session.delete(ub)

        # 5. 🤝 친구 관계 및 알림 삭제
        friendships = session.exec(select(UserFriendship).where(
            or_(UserFriendship.user_id == user_id, UserFriendship.friend_user_id == user_id)
        )).all()
        for f in friendships: session.delete(f)

        notifications = session.exec(select(Notification).where(
            or_(Notification.receiver_id == user_id, Notification.sender_id == user_id)
        )).all()
        for n in notifications: session.delete(n)

        # 6. 👤 [최종] 사용자 정보 삭제
        session.delete(user_in_db)
        session.commit()