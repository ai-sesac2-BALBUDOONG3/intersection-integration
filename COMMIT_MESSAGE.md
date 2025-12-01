feat: 채팅방 목록 UI 개선 - 프로필 이미지 및 마지막 메시지 미리보기

## 주요 변경사항

### 백엔드 (FastAPI)
- 채팅방 조회 API에 추가 정보 포함
  - 마지막 메시지 타입 (last_message_type): "normal", "image", "file"
  - 마지막 메시지 파일 정보 (last_file_url, last_file_name)
  - 상대방 프로필 이미지 (friend_profile_image)
  - create_or_get_chat_room, get_my_chat_rooms 엔드포인트 모두 업데이트

### 프론트엔드 (Flutter)
- ChatRoom 모델 확장
  - 마지막 메시지 상세 정보 필드 추가
  - 상대방 프로필 이미지 필드 추가
  - isLastMessageImage getter 추가 (이미지 타입 자동 감지)

- 채팅방 목록 화면 개선
  - 프로필 이미지 표시 (이미지가 있으면 CircleAvatar로 표시, 없으면 이니셜)
  - 마지막 메시지가 이미지인 경우 미리보기 표시
  - API 설정 import 추가 (이미지 URL 구성용)

### 스키마 업데이트
- ChatRoomRead 스키마에 선택적 필드 추가
  - last_message_type: Optional[str]
  - last_file_url: Optional[str]
  - last_file_name: Optional[str]
  - friend_profile_image: Optional[str]

## 기술적 세부사항
- 백엔드: FastAPI, SQLModel
- 프론트엔드: Flutter
- 이미지 URL: ApiConfig.baseUrl을 사용하여 전체 URL 구성

## 관련 파일
- intersection-backend/app/routers/chat.py
- intersection-backend/app/schemas.py
- intersection-frontend/lib/models/chat_room.dart
- intersection-frontend/lib/screens/chat/chat_list_screen.dart

