from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlmodel import Session, select
from ..db import engine
from ..models import User, UserFriendship, UserBlock, UserReport
from ..schemas import UserRead
from ..routers.users import get_current_user

router = APIRouter(tags=["friends"])


@router.post("/friends/{target_user_id}")
def add_friend(target_user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id == target_user_id:
        raise HTTPException(status_code=400, detail="Cannot add yourself")

    with Session(engine) as session:
        # check if target exists
        target = session.get(User, target_user_id)
        if not target:
            raise HTTPException(status_code=404, detail="Target user not found")

        # 이미 친구인지 체크 (단방향만 체크해도 양방향 로직상 충분하지만 안전하게)
        existing_friendship = session.exec(
            select(UserFriendship).where(
                UserFriendship.user_id == current_user.id,
                UserFriendship.friend_user_id == target_user_id
            )
        ).first()
        
        if existing_friendship:
            return {"ok": True, "message": "Already friends"}

        # 🔥 [수정] 양방향 친구 추가 (A -> B, B -> A)
        # 친구 관계는 상호적이므로 양쪽 모두에게 레코드를 생성합니다.
        friendship1 = UserFriendship(user_id=current_user.id, friend_user_id=target_user_id, status="accepted")
        friendship2 = UserFriendship(user_id=target_user_id, friend_user_id=current_user.id, status="accepted")
        
        session.add(friendship1)
        session.add(friendship2)
        session.commit()
        
        return {"ok": True}


@router.get("/friends/me", response_model=List[UserRead])
def list_friends(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        # 1. 차단/신고한 사용자 ID 수집
        blocked_ids = session.exec(
            select(UserBlock.blocked_user_id).where(UserBlock.user_id == current_user.id)
        ).all()
        
        reported_ids = session.exec(
            select(UserReport.reported_user_id).where(
                UserReport.reporter_id == current_user.id,
                UserReport.status == "pending"
            )
        ).all()
        
        excluded_ids = set(blocked_ids + reported_ids)
        
        # 2. 친구 목록 조회 (JOIN 사용 + 차단/신고 필터링)
        # 🔥 [수정] for문 조회 대신 JOIN을 사용하여 한 번에 조회 (속도 개선)
        statement = (
            select(User)
            .join(UserFriendship, UserFriendship.friend_user_id == User.id)
            .where(UserFriendship.user_id == current_user.id)
        )
        
        # 차단/신고 유저가 있다면 필터링 조건 추가
        if excluded_ids:
            statement = statement.where(User.id.notin_(excluded_ids))
            
        friends = session.exec(statement).all()
        
        # 3. UserRead 변환 (🔥 프로필 이미지 포함!)
        return [
            UserRead(
                id=u.id, 
                name=u.name, 
                birth_year=u.birth_year, 
                region=u.region, 
                school_name=u.school_name,
                profile_image=u.profile_image,       # 🔥 추가됨
                background_image=u.background_image, # 🔥 추가됨
                feed_images=[] 
            ) for u in friends
        ]