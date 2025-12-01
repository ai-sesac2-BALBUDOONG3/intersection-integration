from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional, List
from pydantic import BaseModel
from sqlmodel import Session, select, desc
from sqlalchemy import or_

# 🔥 스키마 및 모델 임포트
from ..schemas import UserCreate, UserRead, UserUpdate, Token, NotificationRead
from ..models import User, Post, Notification, UserBlock, UserReport  # ✅ UserBlock, UserReport 추가
from ..db import engine
from ..auth import get_password_hash, verify_password, create_access_token, decode_access_token
from fastapi.security import OAuth2PasswordBearer
from ..services import assign_community, get_recommended_friends

router = APIRouter(tags=["users"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")


def get_user_by_id(session: Session, user_id: int) -> Optional[User]:
    statement = select(User).where(User.id == user_id)
    return session.exec(statement).first()


def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")

    with Session(engine) as session:
        user = get_user_by_id(session, int(user_id))
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user


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

        user = User(
            login_id=data.login_id, 
            name=data.name, 
            nickname=data.nickname, 
            birth_year=data.birth_year, 
            gender=data.gender,
            region=data.region, 
            school_name=data.school_name,
            school_type=data.school_type,
            admission_year=data.admission_year,
            email=data.login_id,
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
            birth_year=user.birth_year, 
            region=user.region, 
            school_name=user.school_name,
            profile_image=user.profile_image,
            background_image=user.background_image
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
            region=current_user.region, 
            school_name=current_user.school_name,
            profile_image=current_user.profile_image,
            background_image=current_user.background_image,
            feed_images=feed_images_list
        )


@router.get("/users/me/recommended", response_model=list[UserRead])
def recommended(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        # ✅ 차단한 사용자 ID 목록 조회
        blocked_statement = select(UserBlock.blocked_user_id).where(
            UserBlock.user_id == current_user.id
        )
        blocked_ids = set([row for row in session.exec(blocked_statement).all()])
        
        # ✅ 신고한 사용자 ID 목록 조회
        reported_statement = select(UserReport.reported_user_id).where(
            UserReport.reporter_id == current_user.id,
            UserReport.status == "pending"
        )
        reported_ids = set([row for row in session.exec(reported_statement).all()])
        
        # ✅ 제외할 사용자 ID 합치기
        excluded_ids = blocked_ids | reported_ids
        
        # 추천 친구 서비스 호출
        friends = get_recommended_friends(session, current_user)
        
        # ✅ 차단/신고한 사용자 제외
        return [
            UserRead(
                id=u.id, 
                name=u.name, 
                birth_year=u.birth_year, 
                region=u.region, 
                school_name=u.school_name,
                profile_image=u.profile_image,
                background_image=u.background_image
            ) for u in friends if u.id not in excluded_ids  # ✅ 필터링 추가
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
        user = get_user_by_id(session, int(user_id))
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # 필드 업데이트
        if data.name is not None: user.name = data.name
        if data.nickname is not None: user.nickname = data.nickname
        if data.birth_year is not None: user.birth_year = data.birth_year
        if data.gender is not None: user.gender = data.gender
        if data.region is not None: user.region = data.region
        if data.school_name is not None: user.school_name = data.school_name
        if data.school_type is not None: user.school_type = data.school_type
        if data.admission_year is not None: user.admission_year = data.admission_year
        
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
            birth_year=user.birth_year, 
            region=user.region, 
            school_name=user.school_name,
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
                sender_profile_image=sender.profile_image, # 보낸 사람 프사
                type=notif.type,
                message=notif.message,
                related_post_id=notif.related_post_id,
                is_read=notif.is_read,
                created_at=notif.created_at.isoformat()
            ))
            
        return notif_list
    
# ------------------------------------------------------

# 기존 import 아래에 추가할 것 없음
# 맨 아래나 적절한 위치에 이 함수를 추가하세요.

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
        
        # (선택) 차단한 유저 제외 로직을 여기에 추가할 수도 있습니다.
        
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