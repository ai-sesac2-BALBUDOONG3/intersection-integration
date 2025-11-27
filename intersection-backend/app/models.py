from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship
from datetime import datetime

# ------------------------------------------------------
# 1. Community (커뮤니티) 모델 추가
# ------------------------------------------------------
class Community(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str  # 커뮤니티 이름 (예: "서울신동초등학교 2010년 입학")
    
    # 교집합 조건들
    school_name: str
    admission_year: int
    region: str

    created_at: datetime = Field(default_factory=datetime.utcnow)

    # 이 커뮤니티에 속한 유저들 (User 모델과 연결)
    users: List["User"] = Relationship(back_populates="community")


# ------------------------------------------------------
# 2. User (사용자) 모델 수정
# ------------------------------------------------------
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    login_id: str = Field(index=True, unique=True)
    password_hash: Optional[str] = None
    name: Optional[str] = None
    nickname: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    
    birth_year: Optional[int] = None
    gender: Optional[str] = None
    region: Optional[str] = None        # 지역
    school_name: Optional[str] = None   # 학교명
    school_type: Optional[str] = None
    admission_year: Optional[int] = None # 입학년도

    # 📷 [추가됨] 프로필 이미지 & 배경 이미지 URL
    profile_image: Optional[str] = None      
    background_image: Optional[str] = None

    # 🔥 새로 추가된 부분: 커뮤니티 ID와 관계 설정
    community_id: Optional[int] = Field(default=None, foreign_key="community.id")
    community: Optional[Community] = Relationship(back_populates="users")

    created_at: datetime = Field(default_factory=datetime.utcnow)




# (나머지 Post, Comment 등 기존 코드는 그대로 두시면 됩니다)
class Post(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    author_id: int = Field(foreign_key="user.id")
    content: str

# 📷 [추가됨] 게시글 이미지 URL (여러 장이면 쉼표로 구분하거나 별도 테이블 필요하지만, 일단 1장으로 시작)
    image_url: Optional[str] = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None

class Comment(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    post_id: int = Field(foreign_key="post.id")
    user_id: int = Field(foreign_key="user.id")
    content: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class UserFriendship(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    friend_user_id: int = Field(foreign_key="user.id")
    status: Optional[str] = "accepted"
    created_at: datetime = Field(default_factory=datetime.utcnow)