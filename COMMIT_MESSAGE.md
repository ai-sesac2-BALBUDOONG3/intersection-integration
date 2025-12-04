# 커밋 메시지

```
feat: 채팅창 프로필 클릭 시 사용자 정보 및 차단/신고 상태 동기화 개선

## 주요 변경사항

### 백엔드
- 사용자 ID로 정보 조회 API 추가
  - GET /users/{user_id} 엔드포인트 추가
  - 프로필 사진, 배경 이미지, 피드 이미지 포함하여 반환
  - 사용자의 게시글 이미지를 최신순으로 조회

### 프론트엔드
- 채팅창 프로필 클릭 시 사용자 정보 가져오기 개선
  - 항상 API를 호출하여 최신 사용자 정보 가져오기
  - 프로필 사진, 배경 이미지, 피드 이미지 포함
  - 친구 목록에도 최신 정보 업데이트
- FriendProfileScreen 이미지 표시 개선
  - 상대 경로(/uploads/...) 이미지 처리 추가
  - ApiConfig.baseUrl을 붙여 네트워크 이미지로 로드
- FriendProfileScreen 차단/신고 상태 동기화
  - 채팅창에서 차단/신고한 상태와 동기화
  - 차단한 경우: 차단 해제 버튼만 표시
  - 신고한 경우: 신고 취소 버튼만 표시
  - 둘 다 안 한 경우: 차단하기, 신고하기 버튼 표시
  - 차단 해제/신고 취소 다이얼로그 추가

## 수정된 파일

### 백엔드
- app/routers/users.py: GET /users/{user_id} 엔드포인트 추가

### 프론트엔드
- lib/services/api_service.dart: getUserById() 메서드 추가
- lib/screens/chat/chat_screen.dart: 프로필 클릭 시 API 호출 로직 개선
- lib/screens/friends/friend_profile_screen.dart:
  - 이미지 표시 로직 개선 (상대 경로 처리)
  - 차단/신고 상태 확인 및 동기화 로직 추가
  - 차단 해제/신고 취소 다이얼로그 추가
```
