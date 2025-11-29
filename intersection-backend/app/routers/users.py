from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional, List
from pydantic import BaseModel
from ..schemas import UserCreate, UserRead, UserUpdate, Token
from ..models import User, Post  # 👈 Post 모델 추가 (피드 조회를 위해)
from ..db import engine
from sqlmodel import Session, select, desc # 👈 desc 추가 (최신순 정렬)
from ..auth import get_password_hash, verify_password, create_access_token, decode_access_token
from fastapi.security import OAuth2PasswordBearer

# 💡 추천 함수 서비스 임포트
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
        from sqlalchemy import or_
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
            # 📷 회원가입 시에도 이미지가 온다면 저장
            profile_image=data.profile_image,
            background_image=data.background_image
        )
        user.password_hash = get_password_hash(data.password)
        session.add(user)
        session.commit()
        session.refresh(user)

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


# 💡 [핵심 수정] 내 정보 조회 시 피드(게시글 사진들)와 프로필 사진 반환
@router.get("/users/me", response_model=UserRead)
def get_my_info(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        # 1. 내 게시글 중 이미지가 있는 것만 최신순으로 가져오기
        statement = (
            select(Post)
            .where(Post.author_id == current_user.id)
            .where(Post.image_url != None)
            .order_by(desc(Post.created_at))
        )
        my_posts = session.exec(statement).all()
        
        # 2. 이미지 URL 리스트 생성
        feed_images_list = [post.image_url for post in my_posts if post.image_url]

        # 3. 반환
        return UserRead(
            id=current_user.id, 
            name=current_user.name, 
            nickname=current_user.nickname,
            birth_year=current_user.birth_year, 
            region=current_user.region, 
            school_name=current_user.school_name,
            # 📷 프로필 & 배경 이미지
            profile_image=current_user.profile_image,
            background_image=current_user.background_image,
            # 🖼️ 피드 이미지 목록
            feed_images=feed_images_list
        )


@router.get("/users/me/recommended", response_model=list[UserRead])
def recommended(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        friends = get_recommended_friends(session, current_user)
        
        return [
            UserRead(
                id=u.id, 
                name=u.name, 
                birth_year=u.birth_year, 
                region=u.region, 
                school_name=u.school_name,
                profile_image=u.profile_image,      # 친구의 프로필 사진도 반환
                background_image=u.background_image 
            ) for u in friends
        ]


# 💡 [핵심 수정] 프로필 수정 시 이미지 URL 저장 로직 추가
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

        # 기존 텍스트 정보 업데이트
        if data.name is not None:
            user.name = data.name
        if data.nickname is not None:
            user.nickname = data.nickname
        if data.birth_year is not None:
            user.birth_year = data.birth_year
        if data.gender is not None:
            user.gender = data.gender
        if data.region is not None:
            user.region = data.region
        if data.school_name is not None:
            user.school_name = data.school_name
        if data.school_type is not None:
            user.school_type = data.school_type
        if data.admission_year is not None:
            user.admission_year = data.admission_year
        
        # 📷 [추가됨] 이미지 URL 업데이트
        if data.profile_image is not None:
            user.profile_image = data.profile_image
        if data.background_image is not None:
            user.background_image = data.background_image

        session.add(user)
        session.commit()
        session.refresh(user)

        # 커뮤니티 재배정 로직 (학교/지역 등이 바뀌었을 수 있으므로)
        assign_community(session, user)
        session.add(user)
        session.commit()
        session.refresh(user)

        # 수정된 정보 반환 (이미지 포함)
        return UserRead(
            id=user.id, 
            name=user.name, 
            birth_year=user.birth_year, 
            region=user.region, 
            school_name=user.school_name,
            profile_image=user.profile_image,
            background_image=user.background_image
        )