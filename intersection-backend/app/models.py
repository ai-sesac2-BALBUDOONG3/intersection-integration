from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship
from datetime import datetime, timezone, timedelta

# 한국 시간대 (KST = UTC+9)
KST = timezone(timedelta(hours=9))

def get_kst_now():
    """현재 한국 시간을 반환"""
    return datetime.now(KST)

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

    created_at: datetime = Field(default_factory=get_kst_now)

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

    created_at: datetime = Field(default_factory=get_kst_now)


# (나머지 Post, Comment 등 기존 코드는 그대로 두시면 됩니다)
class Post(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    author_id: int = Field(foreign_key="user.id")
    content: str

    # 📷 [추가됨] 게시글 이미지 URL (여러 장이면 쉼표로 구분하거나 별도 테이블 필요하지만, 일단 1장으로 시작)
    image_url: Optional[str] = None

    created_at: datetime = Field(default_factory=get_kst_now)
    updated_at: Optional[datetime] = None

class Comment(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    post_id: int = Field(foreign_key="post.id")
    user_id: int = Field(foreign_key="user.id")
    content: str
    created_at: datetime = Field(default_factory=get_kst_now)

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
    user1_id: int = Field(foreign_key="user.id")  # 채팅방 생성자
    user2_id: int = Field(foreign_key="user.id")  # 채팅 상대방
    left_user_id: Optional[int] = Field(default=None, foreign_key="user.id")  # 나간 사용자 (있으면 해당 사용자는 채팅방에서 제외)
    created_at: datetime = Field(default_factory=get_kst_now)
    updated_at: datetime = Field(default_factory=get_kst_now)  # 마지막 메시지 시간


class ChatMessage(SQLModel, table=True):
    """채팅 메시지 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    room_id: int = Field(foreign_key="chatroom.id")
    sender_id: int = Field(foreign_key="user.id")
    content: str  # 메시지 내용
    message_type: str = Field(default="normal")  # normal, system, file, image
    is_read: bool = Field(default=False)  # 읽음 여부
    
    # ✅ 파일 업로드 관련 필드 추가 (4개)
    file_url: Optional[str] = None  # 파일 URL
    file_name: Optional[str] = None  # 원본 파일명
    file_size: Optional[int] = None  # 파일 크기 (bytes)
    file_type: Optional[str] = None  # 파일 MIME 타입 (image/jpeg, application/pdf 등)
    
    created_at: datetime = Field(default_factory=get_kst_now)


# ------------------------------------------------------
# 3. CommentReport (댓글 신고) 모델 추가
# ------------------------------------------------------
class CommentReport(SQLModel, table=True):
    """댓글 신고 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    reporter_id: int = Field(foreign_key="user.id")          # 신고한 사람
    reported_comment_id: int = Field(foreign_key="comment.id") # 신고된 댓글
    reason: str                                              # 신고 사유
    status: str = Field(default="pending")                   # 처리 상태 (pending, resolved 등)
    created_at: datetime = Field(default_factory=get_kst_now)

# -----------------------------------------------------
# 🚫 차단 & 신고 모델
# ------------------------------------------------------
class UserBlock(SQLModel, table=True):
    """사용자 차단 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")  # 차단한 사람
    blocked_user_id: int = Field(foreign_key="user.id")  # 차단된 사람
    created_at: datetime = Field(default_factory=get_kst_now)


class UserReport(SQLModel, table=True):
    """사용자 신고 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    reporter_id: int = Field(foreign_key="user.id")  # 신고한 사람
    reported_user_id: int = Field(foreign_key="user.id")  # 신고된 사람
    reason: str  # 신고 사유
    content: Optional[str] = None  # 상세 내용
    status: str = Field(default="pending")  # pending, reviewed, resolved
    created_at: datetime = Field(default_factory=get_kst_now)

    # ------------------------------------------------------
# 4. PostLike (게시글 좋아요) 모델 추가
# ------------------------------------------------------
class PostLike(SQLModel, table=True):
    """게시글 좋아요 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    post_id: int = Field(foreign_key="post.id")
    created_at: datetime = Field(default_factory=get_kst_now)

# ------------------------------------------------------
# 5. PostReport (게시글 신고) 모델 추가
# ------------------------------------------------------
class PostReport(SQLModel, table=True):
    """게시글 신고 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    reporter_id: int = Field(foreign_key="user.id")          # 신고한 사람
    reported_post_id: int = Field(foreign_key="post.id")     # 신고된 게시글
    reason: str                                              # 신고 사유
    status: str = Field(default="pending")                   # 상태
    created_at: datetime = Field(default_factory=get_kst_now)

    # ------------------------------------------------------
# 6. Notification (알림) 모델 추가
# ------------------------------------------------------
class Notification(SQLModel, table=True):
    """사용자 알림 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    receiver_id: int = Field(foreign_key="user.id")  # 알림 받는 사람 (게시글 주인 등)
    sender_id: int = Field(foreign_key="user.id")    # 알림 발생시킨 사람 (댓글 쓴 사람)
    
    type: str      # 알림 유형 ("comment", "like", "friend", "system")
    message: str   # 알림 텍스트 ("OO님이 회원님의 글을 좋아합니다.")
    
    # 클릭 시 이동할 타겟 정보 (게시글 ID 등)
    related_post_id: Optional[int] = Field(default=None, foreign_key="post.id")
    
    is_read: bool = Field(default=False) # 읽음 여부
    created_at: datetime = Field(default_factory=get_kst_now)