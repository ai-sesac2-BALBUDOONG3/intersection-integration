from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..schemas import PostCreate, PostRead
from ..models import Post, User
from ..db import engine
from sqlmodel import Session, select
from ..routers.users import get_current_user

router = APIRouter(tags=["posts"])


@router.post("/users/me/posts/", response_model=PostRead)
def create_post(payload: PostCreate, current_user: User = Depends(get_current_user)):
    """게시글 작성 (이미지 URL 포함)"""
    with Session(engine) as session:
        # 1. DB에 게시글 저장
        post = Post(
            author_id=current_user.id, 
            content=payload.content, 
            image_url=payload.image_url  # 📷 이미지 URL 저장
        )
        session.add(post)
        session.commit()
        session.refresh(post)

        # 2. 응답 생성 (작성자 정보 포함)
        return PostRead(
            id=post.id, 
            author_id=post.author_id, 
            content=post.content, 
            image_url=post.image_url,
            created_at=post.created_at.isoformat(),
            author_name=current_user.name,       # 작성자 이름
            author_school=current_user.school_name, # 작성자 학교
            author_region=current_user.region    # 작성자 지역
        )


@router.get("/posts/", response_model=List[PostRead])
def list_posts():
    """전체 게시글 조회 (작성자 정보 포함)"""
    with Session(engine) as session:
        # 👇 Post와 User를 조인(Join)하여 작성자 정보를 함께 가져옵니다.
        # 최신순(created_at 내림차순)으로 정렬
        statement = select(Post, User).join(User, Post.author_id == User.id).order_by(Post.created_at.desc()).limit(100)
        results = session.exec(statement).all()
        
        post_reads = []
        for post, user in results:
            post_reads.append(PostRead(
                id=post.id,
                author_id=post.author_id,
                content=post.content,
                image_url=post.image_url,
                created_at=post.created_at.isoformat(),
                # 👇 유저 테이블에서 가져온 정보를 채워줍니다.
                author_name=user.name,
                author_school=user.school_name,
                author_region=user.region
            ))
        return post_reads


@router.put("/posts/{post_id}", response_model=PostRead)
def update_post(post_id: int, payload: PostCreate, current_user: User = Depends(get_current_user)):
    """게시글 수정"""
    with Session(engine) as session:
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        if post.author_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not post author")
            
        post.content = payload.content
        post.image_url = payload.image_url  # 📷 수정 시 이미지도 변경 가능
        
        session.add(post)
        session.commit()
        session.refresh(post)
        
        # 👇 수정 후 응답에도 작성자 정보 포함
        return PostRead(
            id=post.id, 
            author_id=post.author_id, 
            content=post.content, 
            image_url=post.image_url,
            created_at=post.created_at.isoformat(),
            author_name=current_user.name,
            author_school=current_user.school_name,
            author_region=current_user.region
        )


@router.delete("/posts/{post_id}")
def delete_post(post_id: int, current_user: User = Depends(get_current_user)):
    """게시글 삭제"""
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