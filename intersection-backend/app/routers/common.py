from typing import List, Tuple, Optional
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
import shutil
import os
import uuid
from pathlib import Path
import httpx
from time import time
from collections import OrderedDict

# ✅ JWT 인증 임포트
from ..auth import decode_access_token
from ..config import settings

router = APIRouter(tags=["common"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")

# ✅ 학교 검색 결과 캐시 (메모리 기반, 최대 100개, 1시간 TTL)
_school_search_cache: OrderedDict[str, Tuple[List[str], float]] = OrderedDict()
_cache_max_size = 100
_cache_ttl = 3600  # 1시간

# ✅ httpx 클라이언트 전역 재사용 (연결 풀 최적화)
_http_client: Optional[httpx.AsyncClient] = None

def get_http_client() -> httpx.AsyncClient:
    """전역 httpx 클라이언트 가져오기 (연결 풀 재사용)"""
    global _http_client
    if _http_client is None:
        _http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(2.0, connect=1.0),  # 연결 1초, 전체 2초
            limits=httpx.Limits(max_keepalive_connections=5, max_connections=10),
        )
    return _http_client

def _get_cached_result(keyword: str) -> Optional[List[str]]:
    """캐시에서 결과 가져오기"""
    keyword_lower = keyword.lower().strip()
    if keyword_lower in _school_search_cache:
        results, timestamp = _school_search_cache[keyword_lower]
        # TTL 확인
        if time() - timestamp < _cache_ttl:
            # 최근 사용된 항목을 맨 뒤로 이동 (LRU)
            _school_search_cache.move_to_end(keyword_lower)
            return results
        else:
            # 만료된 항목 제거
            del _school_search_cache[keyword_lower]
    return None

def _set_cached_result(keyword: str, results: List[str]):
    """캐시에 결과 저장"""
    keyword_lower = keyword.lower().strip()
    # 캐시 크기 제한 (LRU)
    if len(_school_search_cache) >= _cache_max_size:
        _school_search_cache.popitem(last=False)  # 가장 오래된 항목 제거
    _school_search_cache[keyword_lower] = (results, time())

UPLOAD_DIR = "uploads"

# ✅ uploads 폴더 자동 생성
Path(UPLOAD_DIR).mkdir(exist_ok=True)

# ✅ 파일 크기 제한 (10MB)
MAX_FILE_SIZE = 10 * 1024 * 1024

# ✅ 허용된 확장자
ALLOWED_EXTENSIONS = {
    "jpg", "jpeg", "png", "gif", "webp", "bmp",  # 이미지
    "pdf", "doc", "docx", "txt", "hwp",  # 문서
    "zip", "rar", "7z"  # 압축
}


def get_current_user_id(token: str = Depends(oauth2_scheme)) -> int:
    """토큰에서 사용자 ID 추출"""
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user_id


@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    current_user_id: int = Depends(get_current_user_id)
):
    """
    이미지/파일을 업로드하면, 접속 가능한 URL을 반환해주는 API
    """
    
    # ✅ 파일 확장자 확인
    file_ext = os.path.splitext(file.filename)[1].lower().replace(".", "")
    if file_ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"허용되지 않은 파일 형식입니다. 허용: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    # ✅ 파일 크기 확인
    file.file.seek(0, 2)
    file_size = file.file.tell()
    file.file.seek(0)
    
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"파일 크기가 너무 큽니다. 최대 {MAX_FILE_SIZE / 1024 / 1024}MB"
        )
    
    # 1. 랜덤 ID 생성
    filename = f"{uuid.uuid4()}.{file_ext}"
    file_location = os.path.join(UPLOAD_DIR, filename)
    
    # 2. 파일 저장
    with open(file_location, "wb") as file_object:
        shutil.copyfileobj(file.file, file_object)
    
    # 3. 반환
    return {
        "success": True,
        "file_url": f"/static/{filename}",
        "filename": file.filename,
        "size": file_size,
        "type": file.content_type
    }


# 🏫 학교 이름 자동완성 검색 API (NEIS OpenAPI 사용 + 캐싱)
@router.get("/common/search/schools", response_model=List[str])
async def search_schools(keyword: str):
    """
    학교 이름 자동완성 검색 API
    NEIS OpenAPI를 사용하여 전국 초중고등학교를 실시간으로 검색합니다.
    메모리 캐싱으로 응답 속도 최적화 (1시간 TTL).
    """
    start_time = time()
    
    print(f"[학교 검색 API 호출] 키워드: '{keyword}'")
    
    if not keyword or not keyword.strip():
        print(f"[학교 검색] 빈 키워드 -> 빈 배열 반환")
        return []

    keyword = keyword.strip()
    
    # ✅ 캐시 확인 (즉시 반환)
    cached_result = _get_cached_result(keyword)
    if cached_result is not None:
        elapsed = (time() - start_time) * 1000
        print(f"[캐시 히트] 키워드: '{keyword}', 응답시간: {elapsed:.0f}ms")
        return cached_result
    
    if not settings.NEIS_API_KEY:
        print(f"[학교 검색 오류] NEIS_API_KEY가 설정되지 않음")
        return []

    try:
        base_url = "https://open.neis.go.kr/hub/schoolInfo"
        params = {
            "KEY": settings.NEIS_API_KEY,
            "Type": "json",
            "pIndex": 1,
            "pSize": 10,  # ✅ 최적화: 20 -> 10 (필요한 만큼만, 더 빠른 응답)
            "SCHUL_NM": keyword,
        }
        
        # ✅ 전역 클라이언트 재사용 (연결 풀 최적화, 타임아웃 2초)
        client = get_http_client()
        response = await client.get(base_url, params=params)
            
        if response.status_code == 200:
            data = response.json()
            school_info = data.get("schoolInfo", [])
            
            results = []
            
            # NEIS API 응답 구조: schoolInfo는 배열
            # [{'head': [...]}, {'row': [실제 데이터...]}]
            if school_info and len(school_info) > 0:
                # 배열의 모든 요소를 순회하며 'row' 키를 가진 요소 찾기
                for item in school_info:
                    if isinstance(item, dict) and "row" in item:
                        rows = item.get("row", [])
                        
                        # 각 학교 데이터 처리 (최적화된 루프)
                        for row in rows:
                            if not isinstance(row, dict):
                                continue
                                
                            school_name = row.get("SCHUL_NM", "")
                            
                            # 빠른 필터링: 대학교 제외
                            if not school_name or "대학교" in school_name:
                                continue
                            
                            # 초중고등학교만 포함 (간단한 체크)
                            if school_name.endswith(("초등학교", "중학교", "고등학교")):
                                if school_name not in results:
                                    results.append(school_name)
                                    if len(results) >= 10:
                                        break
                        
                        if len(results) >= 10:
                            break
            
            # ✅ 캐시에 저장
            _set_cached_result(keyword, results[:10])
            
            elapsed = (time() - start_time) * 1000
            print(f"[학교 검색 완료] 키워드: '{keyword}', 결과: {len(results)}개, 응답시간: {elapsed:.0f}ms")
            return results[:10]
        
        return []

    except httpx.TimeoutException:
        elapsed = (time() - start_time) * 1000
        print(f"[학교 검색 타임아웃] 키워드: '{keyword}', 응답시간: {elapsed:.0f}ms")
        return []
    except Exception as e:
        elapsed = (time() - start_time) * 1000
        print(f"[학교 검색 오류] 키워드: '{keyword}', 오류: {str(e)}, 응답시간: {elapsed:.0f}ms")
        return []
