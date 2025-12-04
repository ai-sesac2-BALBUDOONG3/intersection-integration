"""
공공데이터포털에서 학교 기본정보 데이터를 다운로드하여 JSON 파일로 변환하는 스크립트

사용 방법:
1. 공공데이터포털(data.go.kr)에서 "학교 기본정보" 데이터셋 다운로드
2. 다운로드한 CSV 또는 Excel 파일을 이 스크립트로 변환
3. intersection-backend/data/schools.json 파일이 자동 생성됩니다
"""

import json
import csv
import sys
from pathlib import Path

# 프로젝트 루트 경로 설정
PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"
OUTPUT_FILE = DATA_DIR / "schools.json"

def convert_csv_to_json(csv_file_path: str):
    """
    CSV 파일을 JSON 형식으로 변환하여 data/schools.json에 저장
    """
    schools = []
    
    print(f"📂 CSV 파일 읽기: {csv_file_path}")
    
    try:
        with open(csv_file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # 학교명 필드명은 데이터에 따라 다를 수 있음
                school_name = (
                    row.get('학교명') or 
                    row.get('SCHUL_NM') or 
                    row.get('학교이름') or
                    row.get('학교명칭') or
                    row.get('SCHUL_NM') or
                    row.get('name')
                )
                
                # 학교급 필드명
                school_type = (
                    row.get('학교급') or 
                    row.get('SCHUL_KND_SC_NM') or 
                    row.get('학교종류') or
                    row.get('학교급구분') or
                    row.get('type')
                )
                
                if school_name and school_name.strip():
                    school_name = school_name.strip()
                    
                    # 초중고등학교만 포함 (대학교 제외)
                    is_valid = False
                    
                    # 학교급 필드로 확인
                    if school_type:
                        school_type_str = str(school_type).strip()
                        if any(keyword in school_type_str for keyword in ['초등', '중', '고등']):
                            is_valid = True
                    
                    # 학교명으로 확인 (초등학교, 중학교, 고등학교로 끝나는 경우)
                    if not is_valid:
                        if school_name.endswith(('초등학교', '중학교', '고등학교')):
                            is_valid = True
                    
                    if is_valid and school_name not in schools:
                        schools.append(school_name)
        
        # 중복 제거 및 정렬
        schools = sorted(list(set(schools)))
        
        # JSON 파일로 저장
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(schools, f, ensure_ascii=False, indent=2)
        
        print(f"✅ {len(schools)}개의 학교 정보를 {OUTPUT_FILE}에 저장했습니다.")
        print(f"📊 샘플: {schools[:5]}")
        return schools
        
    except FileNotFoundError:
        print(f"❌ 파일을 찾을 수 없습니다: {csv_file_path}")
        return []
    except Exception as e:
        print(f"❌ 오류 발생: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return []

if __name__ == "__main__":
    if len(sys.argv) > 1:
        csv_file = sys.argv[1]
    else:
        # 기본 경로들 시도
        possible_paths = [
            "학교기본정보.csv",
            "schools.csv",
            "학교정보.csv",
            str(PROJECT_ROOT / "학교기본정보.csv"),
            str(PROJECT_ROOT / "schools.csv"),
        ]
        
        csv_file = None
        for path in possible_paths:
            if Path(path).exists():
                csv_file = path
                break
        
        if not csv_file:
            print("❌ CSV 파일을 찾을 수 없습니다.")
            print("\n사용 방법:")
            print("  python scripts/download_schools_data.py <CSV파일경로>")
            print("\n또는 CSV 파일을 다음 경로 중 하나에 두세요:")
            for path in possible_paths:
                print(f"  - {path}")
            sys.exit(1)
    
    convert_csv_to_json(csv_file)

