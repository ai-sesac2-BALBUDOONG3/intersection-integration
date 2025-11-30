from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlmodel import Session, select, func
from ..schemas import PostCreate, PostRead, PostReportCreate, PostReportRead
# 👇 Notification 추가 임포트
from ..models import Post, User, PostLike, PostReport, UserBlock, Notification
from ..db import engine
from ..routers.users import get_current_user

router = APIRouter(tags=["posts"])

# ------------------------------------------------------
# 게시글 작성
# ------------------------------------------------------
@router.post("/users/me/posts/", response_model=PostRead)
def create_post(payload: PostCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        post = Post(
            author_id=current_user.id, 
            content=payload.content, 
            image_url=payload.image_url
        )
        session.add(post)
        session.commit()
        session.refresh(post)

        return PostRead(
            id=post.id, 
            author_id=post.author_id, 
            content=post.content, 
            image_url=post.image_url,
            created_at=post.created_at.isoformat(),
            author_name=current_user.name,
            author_school=current_user.school_name,
            author_region=current_user.region,
            like_count=0,
            is_liked=False
        )

# ------------------------------------------------------
# 게시글 목록 조회
# ------------------------------------------------------
@router.get("/posts/", response_model=List[PostRead])
def list_posts(
    skip: int = 0,    
    limit: int = 10,  
    current_user: Optional[User] = Depends(get_current_user)
):
    """전체 게시글 조회"""
    with Session(engine) as session:
        statement = select(Post, User).join(User, Post.author_id == User.id)

        if current_user:
            blocking_stmt = select(UserBlock.blocked_user_id).where(UserBlock.user_id == current_user.id)
            blocking_ids = session.exec(blocking_stmt).all()
            
            blocked_by_stmt = select(UserBlock.user_id).where(UserBlock.blocked_user_id == current_user.id)
            blocked_by_ids = session.exec(blocked_by_stmt).all()
            
            excluded_ids = list(set(blocking_ids + blocked_by_ids))
            
            if excluded_ids:
                statement = statement.where(Post.author_id.notin_(excluded_ids))

        statement = statement.order_by(Post.created_at.desc()).offset(skip).limit(limit)
        results = session.exec(statement).all()
        
        post_reads = []
        for post, user in results:
            like_count = session.exec(select(func.count(PostLike.id)).where(PostLike.post_id == post.id)).one()
            
            is_liked = False
            if current_user:
                liked_check = session.exec(
                    select(PostLike).where(PostLike.post_id == post.id, PostLike.user_id == current_user.id)
                ).first()
                if liked_check:
                    is_liked = True

            post_reads.append(PostRead(
                id=post.id,
                author_id=post.author_id,
                content=post.content,
                image_url=post.image_url,
                created_at=post.created_at.isoformat(),
                author_name=user.name,
                author_school=user.school_name,
                author_region=user.region,
                like_count=like_count,
                is_liked=is_liked
            ))
        return post_reads

# ------------------------------------------------------
# 게시글 상세 조회
# ------------------------------------------------------
@router.get("/posts/{post_id}", response_model=PostRead)
def get_post(post_id: int, current_user: Optional[User] = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(Post, User).where(Post.id == post_id).join(User, Post.author_id == User.id)
        result = session.exec(statement).first()
        
        if not result:
            raise HTTPException(status_code=404, detail="Post not found")
            
        post, user = result
        
        if current_user:
            block_check = session.exec(
                select(UserBlock).where(
                    (UserBlock.user_id == current_user.id) & (UserBlock.blocked_user_id == user.id) |
                    (UserBlock.user_id == user.id) & (UserBlock.blocked_user_id == current_user.id)
                )
            ).first()
            if block_check:
                raise HTTPException(status_code=403, detail="Blocked user's post")

        like_count = session.exec(select(func.count(PostLike.id)).where(PostLike.post_id == post.id)).one()
        is_liked = False
        if current_user:
            liked_check = session.exec(
                select(PostLike).where(PostLike.post_id == post.id, PostLike.user_id == current_user.id)
            ).first()
            if liked_check:
                is_liked = True
        
        return PostRead(
            id=post.id,
            author_id=post.author_id,
            content=post.content,
            image_url=post.image_url,
            created_at=post.created_at.isoformat(),
            author_name=user.name,
            author_school=user.school_name,
            author_region=user.region,
            like_count=like_count,
            is_liked=is_liked
        )

# ------------------------------------------------------
# 게시글 수정
# ------------------------------------------------------
@router.put("/posts/{post_id}", response_model=PostRead)
def update_post(post_id: int, payload: PostCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        if post.author_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not post author")
            
        post.content = payload.content
        post.image_url = payload.image_url
        
        session.add(post)
        session.commit()
        session.refresh(post)
        
        like_count = session.exec(select(func.count(PostLike.id)).where(PostLike.post_id == post.id)).one()
        liked_check = session.exec(
            select(PostLike).where(PostLike.post_id == post.id, PostLike.user_id == current_user.id)
        ).first()
        is_liked = bool(liked_check)

        return PostRead(
            id=post.id, 
            author_id=post.author_id, 
            content=post.content, 
            image_url=post.image_url,
            created_at=post.created_at.isoformat(),
            author_name=current_user.name,
            author_school=current_user.school_name,
            author_region=current_user.region,
            like_count=like_count,
            is_liked=is_liked
        )

# ------------------------------------------------------
# 게시글 삭제
# ------------------------------------------------------
@router.delete("/posts/{post_id}")
def delete_post(post_id: int, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        if post.author_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not post author")
            
        session.delete(post)
        session.commit()
        return {"ok": True}

# ------------------------------------------------------
# 👍 1. 게시글 좋아요 (🔔 알림 기능 추가됨)
# ------------------------------------------------------
@router.post("/posts/{post_id}/like")
def like_post(post_id: int, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        post = session.get(Post, post_id)
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")

        existing_like = session.exec(
            select(PostLike).where(PostLike.post_id == post_id, PostLike.user_id == current_user.id)
        ).first()

        liked = False
        if existing_like:
            session.delete(existing_like)
            session.commit()
            liked = False
        else:
            new_like = PostLike(user_id=current_user.id, post_id=post_id)
            session.add(new_like)
            session.commit()
            liked = True
            
            # 🔔 [추가됨] 좋아요 알림 생성
            # 내 글 좋아요는 알림 제외, 중복 알림 방지
            if post.author_id != current_user.id:
                # 같은 사람이 같은 글에 이미 '좋아요' 알림을 보냈는지 확인 (도배 방지)
                existing_notif = session.exec(
                    select(Notification).where(
                        Notification.receiver_id == post.author_id,
                        Notification.sender_id == current_user.id,
                        Notification.type == "like",
                        Notification.related_post_id == post.id
                    )
                ).first()
                
                if not existing_notif:
                    sender_name = current_user.name or current_user.nickname or "알 수 없음"
                    notif = Notification(
                        receiver_id=post.author_id,
                        sender_id=current_user.id,
                        type="like",
                        message=f"{sender_name}님이 회원님의 게시글을 좋아합니다.",
                        related_post_id=post.id
                    )
                    session.add(notif)
                    session.commit()
            
        like_count = session.exec(select(func.count(PostLike.id)).where(PostLike.post_id == post.id)).one()
        
        return {"ok": True, "is_liked": liked, "like_count": like_count}

# ------------------------------------------------------
# 🚨 2. 게시글 신고
# ------------------------------------------------------
@router.post("/posts/{post_id}/report", response_model=PostReportRead)
def report_post(
    post_id: int, 
    report_data: PostReportCreate, 
    current_user: User = Depends(get_current_user)
):
    with Session(engine) as session:
        post = session.get(Post, post_id)
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
            
        if post.author_id == current_user.id:
            raise HTTPException(status_code=400, detail="Cannot report your own post")

        new_report = PostReport(
            reporter_id=current_user.id,
            reported_post_id=post_id,
            reason=report_data.reason,
            status="pending"
        )
        session.add(new_report)
        session.commit()
        session.refresh(new_report)
        
        return PostReportRead(
            id=new_report.id,
            reason=new_report.reason,
            status=new_report.status,
            created_at=new_report.created_at.isoformat()
        )