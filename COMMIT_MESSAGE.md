# 커밋 메시지

```
feat: 채팅 고정 메시지 기능 및 UI 개선

## 주요 변경사항

### 백엔드
- 채팅방 및 메시지 고정 기능 추가
  - ChatRoom, ChatMessage 모델에 is_pinned 필드 추가
  - 고정/고정 해제 API 엔드포인트 추가
  - 고정된 메시지는 원래 위치에 유지 (최상단으로 이동하지 않음)
- 데이터베이스 마이그레이션 스크립트 추가

### 프론트엔드
- 채팅 고정 메시지 기능 구현
  - 채팅방 고정: 채팅 목록에서 고정 버튼으로 고정/해제
  - 메시지 고정: 메시지 길게 누르기로 고정/해제
  - 고정된 메시지가 상단에 한 줄로 표시 (카카오톡 스타일)
  - 고정 메시지 클릭 시 해당 메시지로 이동 및 순환
- 채팅 UI 개선
  - 채팅 목록 검색 기능 추가 (사용자 이름, 메시지 내용 검색)
  - 채팅방 검색 기능 추가
  - 검색 결과 없을 때 "검색 결과가 없어요" 메시지 표시
  - 프로필 클릭 시 사용자 프로필로 이동
  - 상단 헤더 디자인 개선
- 메시지 복사 기능 추가
  - 메시지 길게 누르기 메뉴에 복사 옵션 추가
  - 복사하고 고정하기 옵션 추가
- 자동 스크롤 개선
  - 사용자가 스크롤을 올려서 보고 있을 때 자동으로 맨 밑으로 이동하지 않도록 수정
  - 맨 밑 근처에 있을 때만 새 메시지 수신 시 자동 스크롤

## 수정된 파일

### 백엔드
- app/models.py: ChatRoom, ChatMessage에 is_pinned 필드 추가
- app/schemas.py: ChatRoomRead, ChatMessageRead에 is_pinned 필드 추가
- app/routers/chat.py: 고정/고정 해제 API 엔드포인트 추가, 정렬 로직 수정
- migration_add_is_pinned.sql: 데이터베이스 마이그레이션 스크립트

### 프론트엔드
- lib/models/chat_room.dart: isPinned 필드 추가
- lib/models/chat_message.dart: isPinned 필드 추가
- lib/services/api_service.dart: 고정 관련 API 메서드 추가
- lib/screens/chat/chat_list_screen.dart: 고정 기능, 검색 기능 추가
- lib/screens/chat/chat_screen.dart: 고정 메시지 표시, 검색 기능, 복사 기능 추가
- lib/screens/main_tab_screen.dart: 채팅 탭 AppBar 중복 제거

## 데이터베이스 마이그레이션 필요

다음 SQL을 실행하여 데이터베이스 스키마를 업데이트하세요:

```sql
ALTER TABLE chatroom ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE chatmessage ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
```

또는 migration_add_is_pinned.sql 파일을 실행하세요.
```
