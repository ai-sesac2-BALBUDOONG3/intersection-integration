# 커밋 메시지

```
feat: 채팅창에서 내 전화번호 전송 기능 추가

## 주요 변경사항

### 백엔드
- UserRead 스키마에 phone 필드 추가
  - 사용자 정보 조회 API 응답에 전화번호 포함
  - get_my_info, get_user_by_id_api에서 phone 필드 반환

### 프론트엔드
- User 모델에 phone 필드 추가
  - fromJson/toJson에 phone 필드 처리 추가
- API 서비스에 phone 필드 처리 추가
  - getMyInfo(), getUserById()에서 phone 필드 파싱
- 채팅창 첨부 옵션에 전화번호 전송 기능 추가
  - 더보기 버튼에 "내 번호 보내기" 옵션 추가
  - 전화번호 확인 다이얼로그 표시 (이름과 전화번호 미리보기)
  - 확인 시 이름과 전화번호를 포함한 메시지 전송
  - 전화번호가 없을 경우 안내 메시지 표시

## 수정된 파일

### 백엔드
- app/schemas.py: UserRead에 phone 필드 추가
- app/routers/users.py: get_my_info, get_user_by_id_api에서 phone 반환

### 프론트엔드
- lib/models/user.dart: phone 필드 추가 및 JSON 처리
- lib/services/api_service.dart: getMyInfo(), getUserById()에 phone 필드 파싱 추가
- lib/screens/chat/chat_screen.dart:
  - _showAttachmentOptions()에 "내 번호 보내기" 옵션 추가
  - _sendPhoneNumber() 메서드 추가 (전화번호 전송 로직)
```
