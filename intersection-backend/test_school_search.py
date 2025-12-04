"""학교 검색 API 직접 테스트"""
import asyncio
import httpx
import os
from dotenv import load_dotenv
import json

load_dotenv()

async def test_search(keyword: str):
    """학교 검색 테스트"""
    api_key = os.getenv("NEIS_API_KEY")
    if not api_key:
        print("❌ NEIS_API_KEY가 없습니다")
        return
    
    base_url = "https://open.neis.go.kr/hub/schoolInfo"
    params = {
        "KEY": api_key,
        "Type": "json",
        "pIndex": 1,
        "pSize": 10,
        "SCHUL_NM": keyword,
    }
    
    print(f"\n🔍 검색: '{keyword}'")
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(base_url, params=params)
            
            if response.status_code == 200:
                data = response.json()
                
                # 응답 구조 확인
                print(f"📦 응답 키: {list(data.keys())}")
                
                school_info = data.get("schoolInfo", [])
                print(f"📊 schoolInfo 타입: {type(school_info)}, 길이: {len(school_info) if isinstance(school_info, list) else 'N/A'}")
                
                if school_info and len(school_info) > 0:
                    print(f"\n📋 schoolInfo 구조:")
                    for i, item in enumerate(school_info):
                        print(f"  [{i}] 타입: {type(item)}, 키: {list(item.keys()) if isinstance(item, dict) else 'N/A'}")
                        if isinstance(item, dict) and "row" in item:
                            rows = item.get("row", [])
                            print(f"      row 개수: {len(rows)}")
                            if rows:
                                print(f"      첫 번째 학교: {rows[0].get('SCHUL_NM', 'N/A')}")
                
                # 실제 파싱 테스트
                results = []
                if school_info and len(school_info) > 0:
                    for item in school_info:
                        if isinstance(item, dict) and "row" in item:
                            rows = item.get("row", [])
                            for row in rows:
                                if isinstance(row, dict):
                                    school_name = row.get("SCHUL_NM", "")
                                    school_kind = row.get("SCHUL_KND_SC_NM", "")
                                    
                                    if school_name and "대학교" not in school_name:
                                        if (school_name.endswith(("초등학교", "중학교", "고등학교")) or
                                            (school_kind and any(x in school_kind for x in ["초등", "중", "고등"]))):
                                            results.append(school_name)
                
                print(f"\n✅ 파싱된 결과: {len(results)}개")
                for i, name in enumerate(results[:5], 1):
                    print(f"  {i}. {name}")
            else:
                print(f"❌ HTTP {response.status_code}: {response.text[:200]}")
    except Exception as e:
        print(f"❌ 오류: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_search("수리"))
    asyncio.run(test_search("서울"))

