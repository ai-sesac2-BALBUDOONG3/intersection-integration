from typing import Optional, List
from pydantic import BaseModel

# ------------------------------------------------------
# 🔐 인증 & 토큰
# ------------------------------------------------------
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: Optional[int] = None

# ------------------------------------------------------
# 👤 사용자 (User)
# ------------------------------------------------------
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

    # 👇 [추가] 프로필/배경 이미지 URL 필드
    profile_image: Optional[str] = None
    background_image: Optional[str] = None

    # 🖼️ [추가됨] 프로필 피드에 보여줄 이미지 목록 (URL 문자열 리스트)
    feed_images: List[str] = []

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

# ------------------------------------------------------
# 📝 게시글 (Post)
# ------------------------------------------------------
class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None  # 📷 [추가됨]

class PostRead(BaseModel):
    id: int
    author_id: int
    content: str
    image_url: Optional[str] = None  # 📷 [추가됨]
    created_at: Optional[str] = None

    # 👇 [추가] 작성자 정보 필드 추가
    author_name: Optional[str] = None
    author_school: Optional[str] = None
    author_region: Optional[str] = None

    # 👍 [추가됨] 좋아요 관련 필드
    like_count: int = 0       # 좋아요 수
    is_liked: bool = False    # 내가 좋아요 눌렀는지 여부

class PostReportCreate(BaseModel):
    """게시글 신고 요청"""
    reason: str

class PostReportRead(BaseModel):
    """게시글 신고 응답"""
    id: int
    reason: str
    status: str
    created_at: str

# ------------------------------------------------------
# 💬 댓글 (Comment)
# ------------------------------------------------------
class CommentCreate(BaseModel):
    content: str

class CommentRead(BaseModel):
    id: int
    post_id: int
    user_id: int
    content: str
    created_at: Optional[str] = None
    
    # 👤 작성자 정보
    user_name: Optional[str] = None
    author_profile_image: Optional[str] = None # 🔥 [추가] 프론트 요청사항

    # 👍 [추가] 좋아요 정보
    like_count: int = 0
    is_liked: bool = False

class CommentUpdate(BaseModel):
    """댓글 수정 요청"""
    content: str

class CommentReportCreate(BaseModel):
    """댓글 신고 요청"""
    comment_id: int # router에서 경로로 받지 않고 body로 받을 경우 사용
    reason: str

class CommentReportRead(BaseModel):
    """댓글 신고 응답"""
    id: int
    reporter_id: int
    reported_comment_id: int
    reason: str
    status: str
    created_at: str

# ------------------------------------------------------
# 🗨️ Chat (채팅) 스키마
# ------------------------------------------------------
class ChatRoomCreate(BaseModel):
    """채팅방 생성 요청"""
    friend_id: int  # 채팅할 친구 ID

class ChatRoomRead(BaseModel):
    """채팅방 조회 응답"""
    id: int
    user1_id: int
    user2_id: int
    friend_id: int  # 상대방 ID
    friend_name: Optional[str] = None
    last_message: Optional[str] = None
    last_message_time: Optional[str] = None
    unread_count: int = 0
    created_at: str

class ChatMessageCreate(BaseModel):
    """메시지 전송 요청"""
    content: str
    # ✅ 파일 업로드 관련 필드 추가 (선택사항)
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    file_type: Optional[str] = None

class ChatMessageRead(BaseModel):
    """메시지 조회 응답"""
    id: int
    room_id: int
    sender_id: int
    content: str
    message_type: str = "normal"  # normal, system, file, image
    is_read: bool
    created_at: str
    # ✅ 파일 업로드 관련 필드 추가
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    file_type: Optional[str] = None

# ------------------------------------------------------
# 🚫 차단 & 사용자 신고 스키마
# ------------------------------------------------------
class UserBlockCreate(BaseModel):
    """사용자 차단 요청"""
    blocked_user_id: int

class UserBlockRead(BaseModel):
    """차단 목록 조회 응답"""
    id: int
    user_id: int
    blocked_user_id: int
    blocked_user_name: Optional[str] = None
    created_at: str

class UserReportCreate(BaseModel):
    """사용자 신고 요청"""
    reported_user_id: int
    reason: str  # 신고 사유 (스팸, 욕설, 허위정보 등)
    content: Optional[str] = None  # 상세 내용

class UserReportRead(BaseModel):
    """신고 내역 조회 응답"""
    id: int
    reporter_id: int
    reported_user_id: int
    reason: str
    status: str
    created_at: str

# ------------------------------------------------------
# 🔔 알림 스키마
# ------------------------------------------------------
class NotificationRead(BaseModel):
    """알림 조회 응답"""
    id: int
    sender_id: int
    sender_name: Optional[str] = None          # 알림 보낸 사람 이름
    sender_profile_image: Optional[str] = None # 알림 보낸 사람 프사 (선택 사항)
    
    type: str
    message: str
    related_post_id: Optional[int] = None
    
    is_read: bool
    created_at: str