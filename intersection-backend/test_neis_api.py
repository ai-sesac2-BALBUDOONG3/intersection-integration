"""NEIS API 테스트 스크립트"""
import asyncio
import httpx
import os
from dotenv import load_dotenv

load_dotenv()

async def test_neis_api(keyword: str):
    """NEIS API 테스트"""
    api_key = os.getenv("NEIS_API_KEY")
    if not api_key:
        print("❌ NEIS_API_KEY가 설정되지 않았습니다.")
        return
    
    base_url = "https://open.neis.go.kr/hub/schoolInfo"
    params = {
        "KEY": api_key,
        "Type": "json",
        "pIndex": 1,
        "pSize": 30,
        "SCHUL_NM": keyword,
    }
    
    print(f"\n🔍 검색 키워드: '{keyword}'")
    print(f"📡 API 호출 중...")
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(base_url, params=params)
            
            print(f"✅ HTTP 상태 코드: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"📦 응답 키: {list(data.keys())}")
                
                school_info = data.get("schoolInfo", [])
                
                if school_info and len(school_info) > 0:
                    rows = school_info[0].get("row", [])
                    print(f"📊 결과 개수: {len(rows)}")
                    
                    print("\n📋 전체 결과:")
                    for i, row in enumerate(rows[:10], 1):
                        school_name = row.get("SCHUL_NM", "")
                        school_kind = row.get("SCHUL_KND_SC_NM", "")
                        print(f"  {i}. {school_name} (종류: {school_kind})")
                    
                    # 필터링 테스트
                    print("\n✅ 필터링된 결과 (초중고만):")
                    filtered = []
                    for row in rows:
                        school_name = row.get("SCHUL_NM", "")
                        school_kind = row.get("SCHUL_KND_SC_NM", "")
                        
                        if not school_name:
                            continue
                        
                        # 대학교 제외
                        if "대학교" in school_name or ("대학" in school_kind and "고등학교" not in school_name):
                            continue
                        
                        # 초중고 확인
                        is_valid = False
                        if school_name.endswith(("초등학교", "중학교", "고등학교")):
                            is_valid = True
                        elif school_kind and any(x in school_kind.lower() for x in ["초등", "중학교", "고등"]):
                            is_valid = True
                        elif any(x in school_name for x in ["초등학교", "중학교", "고등학교"]):
                            is_valid = True
                        
                        if is_valid:
                            filtered.append(school_name)
                    
                    print(f"  총 {len(filtered)}개")
                    for i, name in enumerate(filtered[:10], 1):
                        print(f"  {i}. {name}")
                else:
                    result_info = data.get("RESULT", {})
                    if result_info:
                        code = result_info.get("CODE", "")
                        message = result_info.get("MESSAGE", "")
                        print(f"⚠️  CODE: {code}, MESSAGE: {message}")
                    else:
                        print("⚠️  schoolInfo가 비어있음")
                    print(f"\n📄 전체 응답:\n{response.text}")
            else:
                print(f"❌ HTTP 오류: {response.status_code}")
                print(f"응답: {response.text[:500]}")
    except Exception as e:
        print(f"❌ 오류: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # 테스트 키워드들
    test_keywords = ["수리", "산본", "둔전", "서울"]
    
    for keyword in test_keywords:
        asyncio.run(test_neis_api(keyword))
        print("\n" + "="*50 + "\n")

