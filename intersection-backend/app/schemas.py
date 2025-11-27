from typing import Optional
from pydantic import BaseModel

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: Optional[int]

class UserCreate(BaseModel):
    login_id: str
    password: str
    name: Optional[str] = None
    nickname: Optional[str] = None
    birth_year: Optional[int] = None
    gender: Optional[str] = None
    region: Optional[str] = None
    school_name: Optional[str] = None
    school_type: Optional[str] = None
    admission_year: Optional[int] = None
    profile_image: Optional[str] = None
    background_image: Optional[str] = None    

class UserRead(BaseModel):
    id: int
    name: Optional[str] = None
    birth_year: Optional[int] = None
    region: Optional[str] = None
    school_name: Optional[str] = None


class UserUpdate(BaseModel):
    name: Optional[str] = None
    nickname: Optional[str] = None
    birth_year: Optional[int] = None
    gender: Optional[str] = None
    region: Optional[str] = None
    school_name: Optional[str] = None
    school_type: Optional[str] = None
    admission_year: Optional[int] = None
    profile_image: Optional[str] = None
    background_image: Optional[str] = None

class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None  # 📷 [추가됨]

class PostRead(BaseModel):
    id: int
    author_id: int
    content: str
    image_url: Optional[str] = None  # 📷 [추가됨]
    created_at: Optional[str] = None

class CommentCreate(BaseModel):
    content: str

class CommentRead(BaseModel):
    id: int
    post_id: int
    user_id: int
    content: str
    user_name: Optional[str] = None
    created_at: Optional[str] = None
