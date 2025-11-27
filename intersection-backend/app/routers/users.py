from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from pydantic import BaseModel
from ..schemas import UserCreate, UserRead, UserUpdate, Token
from ..models import User
from ..db import engine
from sqlmodel import Session, select
from ..auth import get_password_hash, verify_password, create_access_token, decode_access_token
from fastapi.security import OAuth2PasswordBearer

# 💡 [추가됨] 방금 만든 커뮤니티 자동 배정 함수 가져오기
from ..services import assign_community

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
        # Try to find user by email or login_id
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
        # simple uniqueness check
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
            email=data.login_id
        )
        user.password_hash = get_password_hash(data.password)
        session.add(user)
        session.commit()
        session.refresh(user)

        # 💡 [추가됨] 회원가입 직후, 입력한 정보로 커뮤니티 자동 배정 시도
        assign_community(session, user)
        session.add(user)   # 변경된 community_id 저장
        session.commit()
        session.refresh(user)

        return UserRead(id=user.id, name=user.name, birth_year=user.birth_year, region=user.region, school_name=user.school_name)


@router.get("/users/me", response_model=UserRead)
def get_my_info(current_user: User = Depends(get_current_user)):
    return UserRead(id=current_user.id, name=current_user.name, birth_year=current_user.birth_year, region=current_user.region, school_name=current_user.school_name)


@router.get("/users/me/recommended", response_model=list[UserRead])
def recommended(current_user: User = Depends(get_current_user)):
    # simple stub — return an empty list or a few users
    with Session(engine) as session:
        statement = select(User).limit(10)
        users = session.exec(statement).all()
        return [UserRead(id=u.id, name=u.name, birth_year=u.birth_year, region=u.region, school_name=u.school_name) for u in users if u.id != current_user.id]


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

        session.add(user)
        session.commit()
        session.refresh(user)

        # 💡 [추가됨] 정보 수정 후, 커뮤니티 재배정 시도
        # (학교나 지역을 바꿨을 수 있으므로 다시 체크)
        assign_community(session, user)
        session.add(user)
        session.commit()
        session.refresh(user)

        return UserRead(id=user.id, name=user.name, birth_year=user.birth_year, region=user.region, school_name=user.school_name)