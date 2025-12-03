import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sqlmodel import Session, select
from .models import User, UserFriendship, UserBlock, UserReport

# 기존 커뮤니티 배정 함수 (유지)
def assign_community(session: Session, user: User) -> User:
    """
    유저의 학교/입학년도/지역 정보를 바탕으로 커뮤니티를 자동 배정합니다.
    """
    if not (user.school_name and user.admission_year and user.region):
        return user

    from .models import Community  # 순환 참조 방지
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


# ==========================================
# 🧠 AI 추천 알고리즘 (Content-Based Only)
# ==========================================

def get_content_based_scores(users: list[User], target_user: User) -> dict:
    """
    [Scikit-Learn] 콘텐츠 기반 필터링 (Content-Based Filtering)
    - 사용자의 프로필(지역, 학교, 가입연도)을 텍스트로 변환하여 벡터화
    - 코사인 유사도(Cosine Similarity)를 계산하여 유사도 점수 반환
    
    🔥 [개선됨] '글자(char)' 단위 분석 적용 (예: '남정' <-> '남정초등학교' 매칭)
    """
    if not users:
        return {}

    # 1. 사용자 프로필을 '문서'로 변환 (공백 제거하여 매칭 확률 높임)
    # None 값 처리 및 문자열 변환
    user_docs = [
        f"{str(u.school_name or '').replace(' ', '')} {str(u.region or '').replace(' ', '')} {u.admission_year or ''}" 
        for u in users
    ]
    
    # 타겟 유저의 프로필
    target_doc = f"{str(target_user.school_name or '').replace(' ', '')} {str(target_user.region or '').replace(' ', '')} {target_user.admission_year or ''}"
    
    # 2. TF-IDF 벡터화 (단어의 중요도 반영)
    # analyzer='char': 단어 대신 '글자' 단위로 분석
    # ngram_range=(2, 3): 2~3글자씩 쪼개서 비교
    vectorizer = TfidfVectorizer(analyzer='char', ngram_range=(2, 3))
    
    try:
        # 데이터가 너무 적거나(1명 이하) 단어가 하나도 없으면 에러 날 수 있음
        tfidf_matrix = vectorizer.fit_transform(user_docs + [target_doc])
    except ValueError:
        # 벡터화 실패 시(데이터 부족 등) 빈 딕셔너리 반환
        return {}
    
    # 3. 코사인 유사도 계산
    # 마지막 행(타겟 유저)과 나머지 모든 행(후보 유저들) 간의 유사도 계산
    cosine_sim = cosine_similarity(tfidf_matrix[-1], tfidf_matrix[:-1])
    
    # {user_id: similarity_score} 형태로 변환
    scores = {users[i].id: cosine_sim[0][i] for i in range(len(users))}
    return scores


def get_recommended_friends(session: Session, user: User, limit: int = 20) -> list[User]:
    """
    🚀 AI 추천 친구 알고리즘 (콘텐츠 기반 + 교집합 가산점)
    
    [로직 순서]
    1. 필터링: 친구/차단/신고 유저 제외
    2. AI 분석: 프로필(학교/지역) 유사도 계산 (scikit-learn)
    3. 소셜 분석: 함께 아는 친구 가산점
    4. 최종 정렬 후 반환
    """

    # 1. 제외 대상 필터링 (기존 로직)
    friend_subquery = select(UserFriendship.friend_user_id).where(UserFriendship.user_id == user.id)
    blocked_subquery = select(UserBlock.blocked_user_id).where(UserBlock.user_id == user.id)
    reported_subquery = select(UserReport.reported_user_id).where(
        UserReport.reporter_id == user.id, UserReport.status == "pending"
    )

    # 2. 후보군 전체 조회
    # (AI 분석을 위해 일단 최대한 가져옵니다. 너무 많으면 limit으로 조절 가능)
    candidate_stmt = (
        select(User)
        .where(User.id != user.id)
        .where(User.name.isnot(None))
        .where(User.id.notin_(friend_subquery))
        .where(User.id.notin_(blocked_subquery))
        .where(User.id.notin_(reported_subquery))
    )
    candidates = session.exec(candidate_stmt).all()
    
    if not candidates:
        return []

    # 3. AI 유사도 점수 계산 (0.0 ~ 1.0)
    ai_scores = get_content_based_scores(candidates, user)
    
    # 함께 아는 친구 계산을 위한 내 친구 목록 Set
    my_friends_list = session.exec(friend_subquery).all()
    my_friend_ids = set(my_friends_list)

    final_results = []
    
    for candidate in candidates:
        # [A] AI 프로필 유사도 점수 (기본 점수)
        # 예: 0.8 * 5점 = 4점 만점 기준 환산
        profile_score = ai_scores.get(candidate.id, 0.0) * 5.0
        
        # [B] 함께 아는 친구 점수 (가산점)
        candidate_friends = session.exec(
            select(UserFriendship.friend_user_id).where(UserFriendship.user_id == candidate.id)
        ).all()
        mutual_count = len(my_friend_ids & set(candidate_friends))
        mutual_score = mutual_count * 1.5  # 친구 1명당 1.5점
        
        # 최종 점수
        total_score = profile_score + mutual_score
        
        if total_score > 0:
            final_results.append((candidate, total_score))
            
    # 4. 점수 높은 순 정렬
    final_results.sort(key=lambda x: x[1], reverse=True)
    
    # 유저 객체만 추출하여 반환
    return [item[0] for item in final_results[:limit]]