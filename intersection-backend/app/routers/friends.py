from fastapi import APIRouter, Depends, HTTPException
from ..models import User, UserFriendship, UserBlock, UserReport
from ..db import engine
from sqlmodel import Session, select
from ..routers.users import get_current_user
from ..schemas import UserRead

router = APIRouter(tags=["friends"])


@router.post("/friends/{target_user_id}")
def add_friend(target_user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id == target_user_id:
        raise HTTPException(status_code=400, detail="Cannot add yourself")

    with Session(engine) as session:
        # check if target exists
        statement = select(User).where(User.id == target_user_id)
        target = session.exec(statement).first()
        if not target:
            raise HTTPException(status_code=404, detail="Target user not found")

        # 중복 친구 추가 체크
        existing_friendship = session.exec(
            select(UserFriendship).where(
                UserFriendship.user_id == current_user.id,
                UserFriendship.friend_user_id == target_user_id
            )
        ).first()
        
        if existing_friendship:
            raise HTTPException(status_code=400, detail="Already friends")

        # create friendship (simple, auto-accepted)
        friendship = UserFriendship(user_id=current_user.id, friend_user_id=target_user_id)
        session.add(friendship)
        session.commit()
        session.refresh(friendship)
        return {"ok": True}


@router.get("/friends/me", response_model=list[UserRead])
def list_friends(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        # 차단한 사용자 ID 목록 조회
        blocked_statement = select(UserBlock.blocked_user_id).where(
            UserBlock.user_id == current_user.id
        )
        blocked_ids = [row for row in session.exec(blocked_statement).all()]
        
        # 신고한 사용자 ID 목록 조회 (pending 상태만)
        reported_statement = select(UserReport.reported_user_id).where(
            UserReport.reporter_id == current_user.id,
            UserReport.status == "pending"
        )
        reported_ids = [row for row in session.exec(reported_statement).all()]
        
        # 차단 + 신고한 사용자 ID 합치기
        excluded_ids = set(blocked_ids + reported_ids)
        
        statement = select(UserFriendship).where(UserFriendship.user_id == current_user.id)
        rows = session.exec(statement).all()
        friends = []
        for row in rows:
            # 차단하거나 신고한 사용자는 제외
            if row.friend_user_id in excluded_ids:
                continue
            u = session.get(User, row.friend_user_id)
            if u:
                friends.append(UserRead(id=u.id, name=u.name, birth_year=u.birth_year, region=u.region, school_name=u.school_name))
        return friends