from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlmodel import Session, select, func
from ..db import engine
# 👇 CommentLike 추가됨
from ..models import Comment, Post, User, CommentReport, Notification, CommentLike
from ..schemas import (
    CommentCreate, 
    CommentRead, 
    CommentUpdate, 
    CommentReportCreate, 
    CommentReportRead
)
from ..routers.users import get_current_user

router = APIRouter(tags=["comments"])

@router.post("/posts/{post_id}/comments", response_model=CommentRead)
def create_comment(post_id: int, payload: CommentCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
            
        comment = Comment(post_id=post_id, user_id=current_user.id, content=payload.content)
        session.add(comment)
        session.commit()
        session.refresh(comment)
        
        # 🔔 알림 생성 (작성자가 본인이 아닐 경우)
        if post.author_id != current_user.id:
            sender_name = current_user.name or current_user.nickname or "알 수 없음"
            # 중복 알림 방지 (선택 사항)
            notif = Notification(
                receiver_id=post.author_id,
                sender_id=current_user.id,
                type="comment",
                message=f"{sender_name}님이 회원님의 게시글에 댓글을 남겼습니다.",
                related_post_id=post.id
            )
            session.add(notif)
            session.commit()
        
        display_name = current_user.name or current_user.nickname or current_user.login_id
        
        return CommentRead(
            id=comment.id, 
            post_id=comment.post_id, 
            user_id=comment.user_id, 
            content=comment.content, 
            user_name=display_name,
            author_profile_image=current_user.profile_image, # 🔥 프로필 이미지 추가
            created_at=comment.created_at.isoformat(),
            like_count=0,    # 초기값 0
            is_liked=False   # 초기값 False
        )

@router.get("/posts/{post_id}/comments", response_model=List[CommentRead])
def list_comments(
    post_id: int,
    current_user: Optional[User] = Depends(get_current_user) # 🔥 좋아요 여부 확인을 위해 current_user 필요
):
    with Session(engine) as session:
        statement = (
            select(Comment, User)
            .join(User, Comment.user_id == User.id)
            .where(Comment.post_id == post_id)
            .order_by(Comment.created_at.asc())
        )
        results = session.exec(statement).all()
        
        comments_list = []
        for comment, user in results:
            display_name = user.name or user.nickname or user.login_id or "알 수 없음"
            
            # ❤️ 좋아요 수 계산
            like_count = session.exec(
                select(func.count(CommentLike.id)).where(CommentLike.comment_id == comment.id)
            ).one()
            
            # ❤️ 내가 좋아요 눌렀는지 확인
            is_liked = False
            if current_user:
                liked_check = session.exec(
                    select(CommentLike).where(
                        CommentLike.comment_id == comment.id, 
                        CommentLike.user_id == current_user.id
                    )
                ).first()
                if liked_check:
                    is_liked = True

            comments_list.append(CommentRead(
                id=comment.id, 
                post_id=comment.post_id, 
                user_id=comment.user_id, 
                content=comment.content, 
                user_name=display_name, 
                author_profile_image=user.profile_image, # 🔥 프로필 이미지 추가
                created_at=comment.created_at.isoformat(),
                like_count=like_count, # 🔥 좋아요 수
                is_liked=is_liked      # 🔥 좋아요 여부
            ))

        return comments_list

@router.put("/posts/{post_id}/comments/{comment_id}", response_model=CommentRead)
def update_comment(
    post_id: int, 
    comment_id: int, 
    comment_data: CommentUpdate, 
    current_user: User = Depends(get_current_user)
):
    with Session(engine) as session:
        comment = session.get(Comment, comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")
        
        if comment.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to edit this comment")
            
        comment.content = comment_data.content
        session.add(comment)
        session.commit()
        session.refresh(comment)
        
        display_name = current_user.name or current_user.nickname or current_user.login_id

        # 좋아요 정보 재조회
        like_count = session.exec(
            select(func.count(CommentLike.id)).where(CommentLike.comment_id == comment.id)
        ).one()
        
        is_liked = session.exec(
            select(CommentLike).where(
                CommentLike.comment_id == comment.id, 
                CommentLike.user_id == current_user.id
            )
        ).first() is not None

        return CommentRead(
            id=comment.id,
            post_id=comment.post_id,
            user_id=comment.user_id,
            content=comment.content,
            user_name=display_name,
            author_profile_image=current_user.profile_image, # 🔥 프로필 이미지
            created_at=comment.created_at.isoformat(),
            like_count=like_count,
            is_liked=is_liked
        )

@router.delete("/posts/{post_id}/comments/{comment_id}")
def delete_comment(
    post_id: int, 
    comment_id: int, 
    current_user: User = Depends(get_current_user)
):
    with Session(engine) as session:
        comment = session.get(Comment, comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")
            
        if comment.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this comment")
            
        # 🔥 좋아요 데이터도 함께 삭제 (FK 오류 방지)
        session.exec(select(CommentLike).where(CommentLike.comment_id == comment_id)).all()
        # Cascade 설정에 따라 자동 삭제될 수도 있지만 명시적 삭제 권장
        
        session.delete(comment)
        session.commit()
        return {"ok": True}

# ------------------------------------------------------
# ❤️ [추가] 댓글 좋아요 기능
# ------------------------------------------------------
@router.post("/comments/{comment_id}/like")
def like_comment(comment_id: int, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        comment = session.get(Comment, comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")

        existing_like = session.exec(
            select(CommentLike).where(
                CommentLike.comment_id == comment_id, 
                CommentLike.user_id == current_user.id
            )
        ).first()

        if existing_like:
            return {"ok": True} # 이미 좋아요 상태

        new_like = CommentLike(user_id=current_user.id, comment_id=comment_id)
        session.add(new_like)
        session.commit()
        
        # (선택 사항) 댓글 좋아요 알림도 필요하다면 여기에 추가
        
        return {"ok": True}

@router.delete("/comments/{comment_id}/like")
def unlike_comment(comment_id: int, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        existing_like = session.exec(
            select(CommentLike).where(
                CommentLike.comment_id == comment_id, 
                CommentLike.user_id == current_user.id
            )
        ).first()

        if existing_like:
            session.delete(existing_like)
            session.commit()
        
        return {"ok": True}

# ------------------------------------------------------
# 🚨 댓글 신고 기능
# ------------------------------------------------------
@router.post("/posts/{post_id}/comments/{comment_id}/report", response_model=CommentReportRead)
def report_comment(
    post_id: int,
    comment_id: int,
    report_data: CommentReportCreate,
    current_user: User = Depends(get_current_user)
):
    with Session(engine) as session:
        comment = session.get(Comment, comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")

        if comment.user_id == current_user.id:
             raise HTTPException(status_code=400, detail="Cannot report your own comment")

        new_report = CommentReport(
            reporter_id=current_user.id,
            reported_comment_id=comment_id,
            reason=report_data.reason,
            status="pending"
        )
        session.add(new_report)
        session.commit()
        session.refresh(new_report)
        
        return CommentReportRead(
            id=new_report.id,
            reporter_id=new_report.reporter_id,
            reported_comment_id=new_report.reported_comment_id,
            reason=new_report.reason,
            status=new_report.status,
            created_at=new_report.created_at.isoformat()
        )