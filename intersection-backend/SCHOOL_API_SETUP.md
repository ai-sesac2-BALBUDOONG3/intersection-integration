# 학교 검색 API 설정 가이드

## 로컬 JSON 파일 사용 방식

현재 구현은 로컬 JSON 파일에서 학교 목록을 읽어서 검색합니다.

### 1. 학교 데이터 파일 위치
**중요**: 다음 경로에 `schools.json` 파일을 생성하세요.
```
intersection-backend/data/schools.json
```

### 2. 데이터 준비 방법

#### Step 1: 공공데이터포털에서 데이터 다운로드
1. https://www.data.go.kr 접속
2. 회원가입 및 로그인
3. 검색창에 **"학교 기본정보"** 또는 **"NEIS 학교정보"** 검색
4. 데이터셋 선택 후 **"파일데이터"** 또는 **"원문파일"** 다운로드
5. CSV 또는 Excel 형식으로 다운로드

#### Step 2: CSV 파일을 JSON으로 변환
다운로드한 CSV 파일을 다음 명령어로 변환:

```bash
# 방법 1: 스크립트에 파일 경로 지정
python scripts/download_schools_data.py "다운로드한파일.csv"

# 방법 2: CSV 파일을 intersection-backend/ 디렉토리에 두고 실행
# (파일명: 학교기본정보.csv, schools.csv, 학교정보.csv 중 하나)
python scripts/download_schools_data.py
```

#### Step 3: 결과 확인
변환된 파일이 `intersection-backend/data/schools.json`에 생성됩니다.

### 3. 데이터 파일 형식
JSON 배열 형식 (학교명만):
```json
[
  "둔전초등학교",
  "수리초등학교",
  "산본중학교",
  "산본고등학교",
  ...
]
```

### 4. 주의사항
- **대학교는 자동으로 제외됩니다** (초등학교, 중학교, 고등학교만 포함)
- 파일이 없으면 빈 리스트를 반환합니다 (자동완성은 계속 작동)
- 백엔드 서버 재시작 후 적용됩니다

### 5. 데이터 업데이트
- 정기적으로 공공데이터포털에서 최신 데이터를 다운로드하여 업데이트하세요.
- 새 학교가 추가되거나 폐교된 학교가 있을 수 있습니다.
- 업데이트 시 기존 `data/schools.json` 파일을 새 파일로 교체하세요.

