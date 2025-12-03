from sqlmodel import Session, select
from sqlalchemy import case, desc
from .models import Community, User, UserFriendship, UserBlock, UserReport

def assign_community(session: Session, user: User) -> User:
    """
    유저의 학교/입학년도/지역 정보를 바탕으로 커뮤니티를 자동 배정합니다.
    (기존 기능 유지)
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
    🚀 추천 친구 알고리즘 (Redis 없이 DB로만 구현)
    
    [로직 순서]
    1. 제외 대상 필터링 (이미 친구, 차단, 신고)
    2. 후보군 조회 (학교, 입학년도, 지역 중 하나라도 같은 사람)
    3. 점수 계산:
       - 기본 점수: 학교/지역/입학년도 일치 (+1점씩)
       - 함께 아는 친구(Mutual Friend): 1명당 +3점 (가산점)
    4. 점수 높은 순 정렬 후 반환
    """

    # ---------------------------------------------------------
    # 1. 제외할 대상들 조회 (SubQuery)
    # ---------------------------------------------------------
    
    # 내 친구들 ID 조회
    friend_subquery = select(UserFriendship.friend_user_id).where(UserFriendship.user_id == user.id)
    
    # 내가 차단한 사람들 ID 조회
    blocked_subquery = select(UserBlock.blocked_user_id).where(UserBlock.user_id == user.id)
    
    # 내가 신고한 사람들 ID 조회 (처리 대기중인 건만)
    reported_subquery = select(UserReport.reported_user_id).where(
        UserReport.reporter_id == user.id, UserReport.status == "pending"
    )

    # ---------------------------------------------------------
    # 2. 후보군 조회 (1차 필터링)
    # ---------------------------------------------------------
    # 전체 유저를 다 검사하면 너무 느리므로, 최소한의 연관성(학교, 지역 등)이 있는 사람만 가져옵니다.
    candidate_stmt = (
        select(User)
        .where(User.id != user.id)            # 나 자신 제외
        .where(User.name.isnot(None))         # 이름 없는 유령 회원 제외
        .where(User.id.notin_(friend_subquery))   # ❌ 이미 친구인 사람 제외
        .where(User.id.notin_(blocked_subquery))  # ❌ 차단한 사람 제외
        .where(User.id.notin_(reported_subquery)) # ❌ 신고한 사람 제외
        .where(
            (User.school_name == user.school_name) | 
            (User.admission_year == user.admission_year) | 
            (User.region == user.region)
        )
    )
    candidates = session.exec(candidate_stmt).all()

    # ---------------------------------------------------------
    # 3. 점수 계산 (함께 아는 친구 포함)
    # ---------------------------------------------------------
    
    # 내 친구 목록을 DB에서 가져와서 집합(Set)으로 만듭니다. (교집합 계산용)
    my_friends_list = session.exec(friend_subquery).all()
    my_friend_ids = set(my_friends_list)

    scored_users = []
    
    for candidate in candidates:
        score = 0
        
        # [A] 기본 점수 계산 (학교/학년/지역)
        if candidate.school_name == user.school_name: score += 1
        if candidate.admission_year == user.admission_year: score += 1
        if candidate.region == user.region: score += 1
        
        # [B] 함께 아는 친구 점수 계산 (Mutual Friends)
        # 후보자의 친구 목록을 DB에서 조회합니다.
        candidate_friends_stmt = select(UserFriendship.friend_user_id).where(
            UserFriendship.user_id == candidate.id
        )
        candidate_friends_list = session.exec(candidate_friends_stmt).all()
        candidate_friend_ids = set(candidate_friends_list)
        
        # 💡 교집합(&) 연산으로 겹치는 친구가 몇 명인지 계산
        mutual_count = len(my_friend_ids & candidate_friend_ids)
        
        if mutual_count > 0:
            # 함께 아는 친구 1명당 1점씩 보너스 부여
            score += (mutual_count * 1)
            
        # 점수가 0보다 큰 사람만 추천 목록에 추가
        if score > 0:
            scored_users.append((candidate, score))

    # ---------------------------------------------------------
    # 4. 정렬 및 반환
    # ---------------------------------------------------------
    
    # 점수가 높은 순서대로 내림차순 정렬
    scored_users.sort(key=lambda x: x[1], reverse=True)
    
    # 상위 N명만 잘라서 유저 객체만 반환 (기본 20명)
    recommended_users = [u[0] for u in scored_users[:limit]]
    
    return recommended_users