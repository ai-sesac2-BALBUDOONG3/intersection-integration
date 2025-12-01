feat: 채팅방 나가기 상태 추가 및 추천 친구 필터링 개선

## 주요 변경사항

### 백엔드 (FastAPI)
- 채팅방 나가기 상태 추가
  - ChatRoomRead 스키마에 `they_left` 필드 추가 (상대방이 채팅방을 나갔는지 여부)
  - create_or_get_chat_room, get_my_chat_rooms 엔드포인트에서 나가기 상태 확인 및 반환
  - 상대방이 채팅방을 나간 경우를 감지하여 반환

- 채팅방 목록 필터링 개선
  - get_my_chat_rooms에서 메시지가 없는 채팅방은 목록에서 제외
  - 빈 채팅방이 목록에 표시되지 않도록 개선

- 추천 친구 필터링 개선
  - recommended 엔드포인트에서 차단/신고한 사용자 제외 로직 추가
  - UserBlock, UserReport 모델 import 추가
  - 차단한 사용자와 신고한 사용자(pending 상태)를 추천 목록에서 제외

- 스키마 필드명 수정
  - CommentRead의 `likes_count` → `like_count`로 변경
  - CommentRead의 `liked` → `is_liked`로 변경 (일관성 개선)

### 프론트엔드 (Flutter)
- ChatRoom 모델 확장
  - `theyLeft` 필드 추가 (상대방이 채팅방을 나갔는지 여부)
  - JSON 직렬화/역직렬화 로직 업데이트

- ChatScreen 개선
  - `theyLeft` 파라미터 추가
  - 메시지 전송 제한 로직에 나가기 상태 추가
  - 상대방이 채팅방을 나간 경우 안내 배너 표시
  - 차단 다이얼로그 메시지에 나가기 상태 안내 추가

- ChatListScreen
  - ChatScreen으로 전달하는 파라미터에 `theyLeft` 추가

## 기술적 세부사항
- 백엔드: FastAPI, SQLModel
- 프론트엔드: Flutter
- 채팅방 나가기 상태: `left_user_id` 필드를 활용하여 확인

## 개선 효과
- 상대방이 채팅방을 나간 경우를 명확히 표시하여 사용자 경험 개선
- 빈 채팅방이 목록에 표시되지 않아 UI 정리
- 추천 친구 목록에서 차단/신고한 사용자 제외로 더 정확한 추천 제공
- 스키마 필드명 일관성 개선

## 관련 파일
- intersection-backend/app/routers/chat.py
- intersection-backend/app/routers/users.py
- intersection-backend/app/schemas.py
- intersection-frontend/lib/models/chat_room.dart
- intersection-frontend/lib/screens/chat/chat_list_screen.dart
- intersection-frontend/lib/screens/chat/chat_screen.dart
