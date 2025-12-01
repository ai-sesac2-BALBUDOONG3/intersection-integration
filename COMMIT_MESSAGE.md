refactor: 채팅 신고/차단 상태 필드 세분화 및 로직 개선

## 주요 변경사항

### 백엔드 (FastAPI)
- 신고/차단 상태 필드 세분화
  - 기존 `i_was_reported` 필드를 두 개의 필드로 분리
  - `i_reported_them`: 내가 상대방을 신고/차단했는지 여부 (신고 또는 차단 중 하나라도 True)
  - `they_blocked_me`: 상대방이 나를 신고/차단했는지 여부 (신고 또는 차단 중 하나라도 True)
  - create_or_get_chat_room, get_my_chat_rooms 엔드포인트 모두 업데이트

- 신고/차단 상태 확인 로직 개선
  - 신고와 차단을 통합하여 확인 (OR 조건)
  - 양방향 상태를 명확히 구분하여 반환

### 프론트엔드 (Flutter)
- ChatRoom 모델 업데이트
  - `iWasReported` 필드를 `iReportedThem`, `theyBlockedMe`로 분리
  - JSON 직렬화/역직렬화 로직 업데이트

- ChatScreen 개선
  - 신고/차단 상태 필드명 변경 (`iWasReported` → `iReportedThem`, `theyBlockedMe`)
  - 메시지 전송 제한 로직 개선 (widget 속성 직접 사용)
  - 차단 다이얼로그 메시지 개선 (신고/차단 통합 메시지)
  - 팝업 메뉴 표시 조건 개선 (신고당한 경우 나가기만 가능)

- ChatListScreen
  - ChatScreen으로 전달하는 파라미터 업데이트

### 스키마 업데이트
- ChatRoomRead 스키마 필드 변경
  - `i_was_reported: bool` → `i_reported_them: bool`, `they_blocked_me: bool`

## 기술적 세부사항
- 백엔드: FastAPI, SQLModel
- 프론트엔드: Flutter
- 신고/차단 상태: 신고 또는 차단 중 하나라도 있으면 True로 통합

## 개선 효과
- 신고/차단 상태를 더 명확하게 구분하여 사용자 경험 개선
- 양방향 상태를 독립적으로 관리하여 로직 단순화
- 에러 메시지 및 UI 표시 개선

## 관련 파일
- intersection-backend/app/routers/chat.py
- intersection-backend/app/schemas.py
- intersection-frontend/lib/models/chat_room.dart
- intersection-frontend/lib/screens/chat/chat_list_screen.dart
- intersection-frontend/lib/screens/chat/chat_screen.dart
