from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from sqlmodel import Session, select
from ..db import engine
# 👇 Notification 모델 추가 임포트
from ..models import Comment, Post, User, CommentReport, Notification
from ..schemas import (
    CommentCreate, 
    CommentRead, 
    CommentUpdate, 
    CommentReportCreate, 
    CommentReportRead
)
from ..routers.users import get_current_user

router = APIRouter(tags=["comments"])


# ------------------------------------------------------
# 1. 댓글 작성 (🔔 알림 기능 추가됨)
# ------------------------------------------------------
@router.post("/posts/{post_id}/comments", response_model=CommentRead)
def create_comment(post_id: int, payload: CommentCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        # 게시글 존재 확인
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
            
        # 댓글 저장
        comment = Comment(post_id=post_id, user_id=current_user.id, content=payload.content)
        session.add(comment)
        session.commit()
        session.refresh(comment)
        
        # 🔔 [추가됨] 알림 생성 로직
        # 내 글에 내가 댓글 단 건 알림 안 보냄
        if post.author_id != current_user.id:
            sender_name = current_user.name or current_user.nickname or "알 수 없음"
            notif = Notification(
                receiver_id=post.author_id,    # 받는 사람: 글쓴이
                sender_id=current_user.id,     # 보낸 사람: 댓글 쓴 사람
                type="comment",
                message=f"{sender_name}님이 회원님의 게시글에 댓글을 남겼습니다.",
                related_post_id=post.id
            )
            session.add(notif)
            session.commit()
        
        # 작성자 이름 결정
        display_name = current_user.name or current_user.nickname or current_user.login_id
        
        return CommentRead(
            id=comment.id, 
            post_id=comment.post_id, 
            user_id=comment.user_id, 
            content=comment.content, 
            user_name=display_name, 
            created_at=comment.created_at.isoformat()
        )


# ------------------------------------------------------
# 2. 댓글 목록 조회
# ------------------------------------------------------
@router.get("/posts/{post_id}/comments", response_model=List[CommentRead])
def list_comments(post_id: int):
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
            
            comments_list.append(CommentRead(
                id=comment.id, 
                post_id=comment.post_id, 
                user_id=comment.user_id, 
                content=comment.content, 
                user_name=display_name, 
                created_at=comment.created_at.isoformat()
            ))

        return comments_list


# ------------------------------------------------------
# 3. 댓글 수정 API
# ------------------------------------------------------
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

        return CommentRead(
            id=comment.id,
            post_id=comment.post_id,
            user_id=comment.user_id,
            content=comment.content,
            user_name=display_name,
            created_at=comment.created_at.isoformat()
        )


# ------------------------------------------------------
# 4. 댓글 삭제 API
# ------------------------------------------------------
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
            
        session.delete(comment)
        session.commit()
        return {"ok": True}


# ------------------------------------------------------
# 5. 댓글 신고 API
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