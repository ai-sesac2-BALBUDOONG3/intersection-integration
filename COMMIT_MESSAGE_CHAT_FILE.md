# 커밋 메시지

```
feat: 채팅 파일/이미지 업로드 및 다운로드 기능 구현

## 주요 변경사항

### 백엔드 (FastAPI)
- 채팅 메시지 전송 API에 파일 정보 필드 지원 추가
  - file_url, file_name, file_size, file_type 필드 처리
  - message_type 자동 설정 로직 개선 (file_type > file_name > file_url 순서로 확인)
  - 이미지/파일 타입 자동 구분

### 프론트엔드 (Flutter)
- 파일 업로드 API 연동
  - ApiService.uploadFile() 메서드 추가
  - 웹/모바일 모두 지원 (multipart/form-data)
  - JWT 토큰 인증 포함

- 채팅 메시지 전송에 파일 정보 포함
  - sendChatMessage() 메서드에 파일 정보 파라미터 추가
  - 파일 업로드 후 메시지 전송 연동

- 채팅 화면 파일/이미지 표시 개선
  - 이미지: 화면 너비의 50% 크기로 표시
  - 이미지 클릭 시 확대 보기 (InteractiveViewer로 줌/팬 지원)
  - 파일: 파일 아이콘, 파일명, 크기 표시
  - 로딩 인디케이터 추가

- 파일 다운로드 기능
  - 이미지/파일 메시지에 다운로드 버튼 추가
  - 웹: Blob을 사용한 브라우저 다운로드
  - 모바일: FilePicker로 저장 경로 선택 후 저장
  - 인증 토큰 포함하여 파일 다운로드

### 모델 및 스키마
- ChatMessage 모델에 파일 관련 필드 추가
  - fileUrl, fileName, fileSize, fileType
  - 헬퍼 메서드 추가 (isFile, isImage, fileSizeFormatted 등)

### 플랫폼 지원
- 웹/모바일 모두 파일 업로드 및 다운로드 지원
- 플랫폼별 최적화된 파일 처리

## 기술적 세부사항
- 백엔드: FastAPI, SQLModel
- 프론트엔드: Flutter, http 패키지, file_picker 패키지
- 파일 업로드: multipart/form-data
- 파일 다운로드: 웹(Blob), 모바일(File I/O)

## 관련 파일
- intersection-backend/app/routers/chat.py
- intersection-frontend/lib/services/api_service.dart
- intersection-frontend/lib/screens/chat/chat_screen.dart
- intersection-frontend/lib/models/chat_message.dart
```

