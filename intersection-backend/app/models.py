from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship
from datetime import datetime, timezone, timedelta

# 한국 시간대 (KST = UTC+9)
KST = timezone(timedelta(hours=9))

def get_kst_now():
    """현재 한국 시간을 반환"""
    return datetime.now(KST)

# ------------------------------------------------------
# 1. Community (커뮤니티) 모델
# ------------------------------------------------------
class Community(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str  # 커뮤니티 이름
    
    # 교집합 조건들
    school_name: str
    admission_year: int
    region: str

    created_at: datetime = Field(default_factory=get_kst_now)

    # Relationship
    users: List["User"] = Relationship(back_populates="community")


# ------------------------------------------------------
# 2. User (사용자) 모델
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
    region: Optional[str] = None
    school_name: Optional[str] = None
    school_type: Optional[str] = None
    admission_year: Optional[int] = None

    # 프로필 이미지 & 배경 이미지 URL
    profile_image: Optional[str] = None      
    background_image: Optional[str] = None

    # 커뮤니티 관계
    community_id: Optional[int] = Field(default=None, foreign_key="community.id")
    community: Optional[Community] = Relationship(back_populates="users")

    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# 3. Post (게시글) 모델
# ------------------------------------------------------
class Post(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    author_id: int = Field(foreign_key="user.id")
    content: str

    # 게시글 이미지 URL
    image_url: Optional[str] = None

    created_at: datetime = Field(default_factory=get_kst_now)
    updated_at: Optional[datetime] = None


# ------------------------------------------------------
# 4. Comment (댓글) 모델
# ------------------------------------------------------
class Comment(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    post_id: int = Field(foreign_key="post.id")
    user_id: int = Field(foreign_key="user.id")
    content: str
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# 5. UserFriendship (친구 관계) 모델
# ------------------------------------------------------
class UserFriendship(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    friend_user_id: int = Field(foreign_key="user.id")
    status: Optional[str] = "accepted"
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# 💬 Chat (채팅) 모델
# ------------------------------------------------------
class ChatRoom(SQLModel, table=True):
    """1:1 채팅방 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user1_id: int = Field(foreign_key="user.id")
    user2_id: int = Field(foreign_key="user.id")
    left_user_id: Optional[int] = Field(default=None, foreign_key="user.id")
    is_pinned: bool = Field(default=False)  # ✅ 고정 여부
    created_at: datetime = Field(default_factory=get_kst_now)
    updated_at: datetime = Field(default_factory=get_kst_now)


class ChatMessage(SQLModel, table=True):
    """채팅 메시지 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    room_id: int = Field(foreign_key="chatroom.id")
    sender_id: int = Field(foreign_key="user.id")
    content: str
    message_type: str = Field(default="normal")  # normal, system, file, image
    is_read: bool = Field(default=False)
    is_pinned: bool = Field(default=False)  # ✅ 고정 여부
    
    # 파일 업로드 관련 필드
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    file_type: Optional[str] = None
    
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# 🚫 차단 & 신고 모델
# ------------------------------------------------------
class UserBlock(SQLModel, table=True):
    """사용자 차단 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    blocked_user_id: int = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=get_kst_now)


class UserReport(SQLModel, table=True):
    """사용자 신고 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    reporter_id: int = Field(foreign_key="user.id")
    reported_user_id: int = Field(foreign_key="user.id")
    reason: str
    content: Optional[str] = None
    status: str = Field(default="pending")
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# ❤️ PostLike (게시글 좋아요) 모델
# ------------------------------------------------------
class PostLike(SQLModel, table=True):
    """게시글 좋아요 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    post_id: int = Field(foreign_key="post.id")
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# ❤️ CommentLike (댓글 좋아요) 모델 [추가됨]
# ------------------------------------------------------
class CommentLike(SQLModel, table=True):
    """댓글 좋아요 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    comment_id: int = Field(foreign_key="comment.id")
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# 🚨 PostReport (게시글 신고) 모델
# ------------------------------------------------------
class PostReport(SQLModel, table=True):
    """게시글 신고 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    reporter_id: int = Field(foreign_key="user.id")
    reported_post_id: int = Field(foreign_key="post.id")
    reason: str
    status: str = Field(default="pending")
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# 🚨 CommentReport (댓글 신고) 모델
# ------------------------------------------------------
class CommentReport(SQLModel, table=True):
    """댓글 신고 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    reporter_id: int = Field(foreign_key="user.id")
    reported_comment_id: int = Field(foreign_key="comment.id")
    reason: str
    status: str = Field(default="pending")
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# 🔔 Notification (알림) 모델
# ------------------------------------------------------
class Notification(SQLModel, table=True):
    """사용자 알림 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    receiver_id: int = Field(foreign_key="user.id")
    sender_id: int = Field(foreign_key="user.id")
    
    type: str      # comment, like, friend, system
    message: str
    
    related_post_id: Optional[int] = Field(default=None, foreign_key="post.id")
    
    is_read: bool = Field(default=False)
    created_at: datetime = Field(default_factory=get_kst_now)