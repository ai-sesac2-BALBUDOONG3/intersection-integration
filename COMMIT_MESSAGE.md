feat: 채팅 차단/신고 기능 구현 및 에러 처리 개선

## 주요 변경사항

### 백엔드 (FastAPI)
- 채팅방 생성 시 차단/신고 확인 로직 추가
  - create_or_get_chat_room 엔드포인트에 차단/신고 체크 추가
  - 양방향 차단 확인 (현재 사용자가 상대방을 차단했거나, 상대방이 현재 사용자를 차단한 경우)
  - 양방향 신고 확인 (현재 사용자가 상대방을 신고했거나, 상대방이 현재 사용자를 신고한 경우)
  - 차단/신고된 사용자와의 채팅방 생성 시 403 에러 반환

- 채팅방 조회 시 신고 상태 정보 추가
  - get_my_chat_rooms, create_or_get_chat_room에서 i_was_reported 필드 추가
  - 상대방이 나를 신고했는지 여부를 확인하여 반환

- 스키마 업데이트
  - ChatRoomRead에 i_was_reported 필드 추가 (Optional[bool])

### 프론트엔드 (Flutter)
- ChatRoom 모델 확장
  - iWasReported 필드 추가 (상대방이 나를 신고했는지 여부)

- ChatScreen 개선
  - iWasReported 파라미터 추가
  - 신고/차단 에러 메시지 처리 개선
    - 이미지 전송 실패 시 차단/신고 에러 감지
    - 사용자 친화적인 에러 메시지 표시
    - 에러 메시지 배경색을 빨간색으로 설정하여 강조

- 채팅방 목록 화면
  - 불필요한 주석 제거 및 코드 정리

### 코드 품질 개선
- friends.py 파일 마지막 줄 개행 문자 수정

## 기술적 세부사항
- 백엔드: FastAPI, SQLModel, SQLAlchemy or_ 조건 사용
- 프론트엔드: Flutter
- 차단/신고 확인: 양방향 체크로 안전성 강화

## 관련 파일
- intersection-backend/app/routers/chat.py
- intersection-backend/app/routers/friends.py
- intersection-backend/app/schemas.py
- intersection-frontend/lib/models/chat_room.dart
- intersection-frontend/lib/screens/chat/chat_list_screen.dart
- intersection-frontend/lib/screens/chat/chat_screen.dart
