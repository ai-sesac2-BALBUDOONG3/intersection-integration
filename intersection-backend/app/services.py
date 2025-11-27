from sqlmodel import Session, select
from sqlalchemy import case, desc
from .models import Community, User, UserFriendship  # 👈 UserFriendship 추가됨

def assign_community(session: Session, user: User) -> User:
    """
    유저의 학교/입학년도/지역 정보를 바탕으로 커뮤니티를 자동 배정합니다.
    """
    if not (user.school_name and user.admission_year and user.region):
        return user

    statement = select(Community).where(
        Community.school_name == user.school_name,
        Community.admission_year == user.admission_year,
        Community.region == user.region
    )
    results = session.exec(statement)
    community = results.first()

    if not community:
        community_name = f"{user.school_name} {user.admission_year}년 입학"
        community = Community(
            name=community_name,
            school_name=user.school_name,
            admission_year=user.admission_year,
            region=user.region
        )
        session.add(community)
        session.commit()
        session.refresh(community)

    user.community_id = community.id
    return user


def get_recommended_friends(session: Session, user: User, limit: int = 20) -> list[User]:
    """
    추천 친구 알고리즘 (Phase 2 + Filter)
    - 학교, 입학년도, 지역이 일치하는 항목마다 점수를 부여 (+1점씩)
    - 🔥 [수정됨] 이미 친구 추가한 사람은 목록에서 제외합니다.
    - 점수가 높은 순으로 정렬하여 반환
    """
    
    # 1. 내가 이미 추가한 친구들의 ID 목록 조회 (SubQuery)
    #    (친구 관계 테이블에서 user_id가 '나'인 데이터의 friend_id를 찾음)
    friend_subquery = select(UserFriendship.friend_user_id).where(
        UserFriendship.user_id == user.id
    )

    # 2. 점수 계산 로직
    score_expression = (
        case((User.school_name == user.school_name, 1), else_=0) +
        case((User.admission_year == user.admission_year, 1), else_=0) +
        case((User.region == user.region, 1), else_=0)
    ).label("score")

    # 3. 쿼리 작성 (친구 제외 조건 추가)
    statement = (
        select(User, score_expression)
        .where(User.id != user.id)   # 나 자신 제외
        .where(User.name.isnot(None)) # 유령 회원 제외
        .where(User.id.notin_(friend_subquery)) # 🔥 핵심: 이미 친구인 사람 제외!
        .order_by(desc("score"))     # 점수순 정렬
        .limit(limit)
    )

    results = session.exec(statement).all()
    
    # 교집합 점수가 1점 이상인 사람만 반환
    recommended_users = [row[0] for row in results if row[1] > 0]
    
    return recommended_users