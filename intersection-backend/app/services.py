from sqlmodel import Session, select
from .models import Community, User

def assign_community(session: Session, user: User) -> User:
    """
    유저의 학교/입학년도/지역 정보를 바탕으로 커뮤니티를 자동 배정합니다.
    해당하는 커뮤니티가 없으면 새로 생성합니다.
    """
    # 필수 정보(학교, 입학년도, 지역) 중 하나라도 없으면 배정하지 않고 그대로 반환
    if not (user.school_name and user.admission_year and user.region):
        return user

    # 1. 이미 존재하는 커뮤니티가 있는지 찾기 (교집합 조건 검색)
    statement = select(Community).where(
        Community.school_name == user.school_name,
        Community.admission_year == user.admission_year,
        Community.region == user.region
    )
    results = session.exec(statement)
    community = results.first()

    # 2. 해당하는 커뮤니티가 없으면? -> 새로 생성!
    if not community:
        # 커뮤니티 이름 자동 생성 (예: "서울신동초등학교 2010년 입학")
        community_name = f"{user.school_name} {user.admission_year}년 입학"
        
        community = Community(
            name=community_name,
            school_name=user.school_name,
            admission_year=user.admission_year,
            region=user.region
        )
        session.add(community)
        session.commit()       # DB에 저장해서 ID를 발급받음
        session.refresh(community) # 발급받은 ID 등 최신 정보를 변수에 업데이트

    # 3. 유저에게 찾은(혹은 만든) 커뮤니티 ID를 할당
    user.community_id = community.id
    
    return user