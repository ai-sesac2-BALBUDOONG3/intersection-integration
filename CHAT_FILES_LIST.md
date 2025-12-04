# 채팅 관련 파일 목록

## 📱 프론트엔드 (Flutter)

### 화면 (Screens)
1. **intersection-frontend/lib/screens/chat/chat_screen.dart**
   - 개별 채팅방 화면
   - 메시지 전송/수신, 파일 업로드, 이미지 표시, 다운로드 기능
   - 신고/차단 기능 및 UI 상태 관리

2. **intersection-frontend/lib/screens/chat/chat_list_screen.dart**
   - 채팅방 목록 화면
   - 채팅방 목록 표시 및 선택 기능

### 모델 (Models)
3. **intersection-frontend/lib/models/chat_message.dart**
   - 채팅 메시지 데이터 모델
   - 파일 관련 필드 (fileUrl, fileName, fileSize, fileType)
   - 헬퍼 메서드 (isFile, isImage, fileSizeFormatted 등)

4. **intersection-frontend/lib/models/chat_room.dart**
   - 채팅방 데이터 모델
   - 채팅방 정보 및 마지막 메시지 정보 포함

### 서비스 (Services)
5. **intersection-frontend/lib/services/api_service.dart**
   - 채팅 관련 API 호출 메서드들
   - `getMyChatRooms()`: 채팅방 목록 조회
   - `getChatMessages()`: 메시지 목록 조회
   - `sendChatMessage()`: 메시지 전송
   - `sendImageMessage()`: 이미지 메시지 전송 (모바일)
   - `sendImageMessageWeb()`: 이미지 메시지 전송 (웹)
   - `sendFileMessage()`: 파일 메시지 전송 (모바일)
   - `sendFileMessageWeb()`: 파일 메시지 전송 (웹)
   - `uploadFile()`: 파일 업로드
   - `deleteChatRoom()`: 채팅방 나가기
   - `checkIfBlocked()`: 차단 상태 확인
   - `checkMyReport()`: 신고 상태 확인

---

## 🔧 백엔드 (FastAPI)

### 라우터 (Routers)
6. **intersection-backend/app/routers/chat.py**
   - 채팅 관련 API 엔드포인트
   - WebSocket 연결 관리
   - 채팅방 생성/조회, 메시지 전송/조회
   - 파일 메시지 처리

### 모델 (Models)
7. **intersection-backend/app/models.py**
   - `ChatRoom`: 채팅방 모델
   - `ChatMessage`: 채팅 메시지 모델
     - 파일 관련 필드: file_url, file_name, file_size, file_type
     - 메시지 타입: normal, system, file, image

### 스키마 (Schemas)
8. **intersection-backend/app/schemas.py**
   - `ChatRoomCreate`: 채팅방 생성 스키마
   - `ChatRoomRead`: 채팅방 조회 스키마
   - `ChatMessageCreate`: 메시지 생성 스키마
   - `ChatMessageRead`: 메시지 조회 스키마
   - 파일 관련 필드 포함

### 공통 (Common)
9. **intersection-backend/app/routers/common.py**
   - 파일 업로드 엔드포인트 (`/upload`)
   - 파일 저장 및 URL 반환

---

## 📊 파일 구조 요약

```
프론트엔드 (Flutter)
├── lib/
│   ├── screens/chat/
│   │   ├── chat_screen.dart          # 개별 채팅방 화면
│   │   └── chat_list_screen.dart     # 채팅방 목록 화면
│   ├── models/
│   │   ├── chat_message.dart         # 메시지 모델
│   │   └── chat_room.dart            # 채팅방 모델
│   └── services/
│       └── api_service.dart          # API 호출 서비스

백엔드 (FastAPI)
├── app/
│   ├── routers/
│   │   ├── chat.py                   # 채팅 라우터
│   │   └── common.py                 # 파일 업로드 라우터
│   ├── models.py                     # 데이터베이스 모델
│   └── schemas.py                    # Pydantic 스키마
```

---

## 🔗 주요 기능별 파일 매핑

### 채팅방 목록
- **프론트**: `chat_list_screen.dart` → `api_service.dart` → `getMyChatRooms()`
- **백엔드**: `chat.py` → `GET /chat/rooms`

### 메시지 전송
- **프론트**: `chat_screen.dart` → `api_service.dart` → `sendChatMessage()`
- **백엔드**: `chat.py` → `POST /chat/messages`

### 파일/이미지 업로드
- **프론트**: `chat_screen.dart` → `api_service.dart` → `uploadFile()` → `sendFileMessage()`
- **백엔드**: `common.py` → `POST /upload` → `chat.py` → `POST /chat/messages`

### WebSocket 실시간 통신
- **프론트**: `chat_screen.dart` (폴링 방식으로 구현)
- **백엔드**: `chat.py` → `WebSocket /chat/ws/{room_id}`

### 신고/차단 기능
- **프론트**: `chat_screen.dart` → `api_service.dart` → `checkIfBlocked()`, `checkMyReport()`
- **백엔드**: `chat.py` → 차단/신고 상태 확인 로직

---

## 📝 총 파일 개수

- **프론트엔드**: 5개 파일
- **백엔드**: 4개 파일
- **총계**: 9개 파일

