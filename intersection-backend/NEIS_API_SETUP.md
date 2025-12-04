# NEIS OpenAPI 설정 가이드

## 필요한 정보

NEIS OpenAPI를 사용하기 위해 다음 정보가 필요합니다:

### 1. 인증키 (API Key)
- **발급 사이트**: https://open.neis.go.kr
- **발급 방법**:
  1. https://open.neis.go.kr 접속
  2. 회원가입 및 로그인
  3. 마이페이지 > 인증키 관리에서 인증키 확인
  4. 인증키 복사

### 2. 환경변수 설정
`intersection-backend/.env` 파일에 다음 내용 추가:
```env
NEIS_API_KEY=발급받은_인증키
```

## API 정보

- **제공기관**: 교육부
- **데이터포맷**: JSON, XML
- **API 유형**: LINK
- **비용**: 무료
- **업데이트**: 실시간 반영

## 사용되는 API 엔드포인트

- **URL**: `https://open.neis.go.kr/hub/schoolInfo`
- **파라미터**:
  - `KEY`: 인증키 (필수)
  - `Type`: 응답 형식 (json 또는 xml)
  - `SCHUL_KND_SC_NM`: 학교종류명 (1=초등, 2=중, 3=고)
  - `SCHUL_NM`: 학교명 검색어
  - `pIndex`: 페이지 번호
  - `pSize`: 페이지 크기

## 검색 방식

- 초등학교, 중학교, 고등학교를 각각 검색하여 결과를 합칩니다.
- 대학교는 자동으로 제외됩니다.
- 최대 10개의 결과를 반환합니다.

## 문제 해결

### 인증키가 설정되지 않은 경우
- 백엔드 콘솔에 경고 메시지가 표시됩니다.
- `.env` 파일에 `NEIS_API_KEY`를 추가하세요.

### API 호출 실패 시
- 네트워크 연결을 확인하세요.
- 인증키가 올바른지 확인하세요.
- https://open.neis.go.kr 에서 API 사용 상태를 확인하세요.

