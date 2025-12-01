feat: 네비게이션바 채팅 버튼에 읽지 않은 메시지 수 배지 표시

## 주요 변경사항

### 프론트엔드 (Flutter)
- 네비게이션바 채팅 버튼에 읽지 않은 메시지 수 배지 추가
  - MainTabScreen에 `_totalUnreadCount` 상태 변수 추가
  - 모든 채팅방의 `unreadCount`를 합산하여 총 읽지 않은 메시지 수 계산
  - 읽지 않은 메시지가 있을 때만 빨간색 배지 표시

- 자동 업데이트 기능
  - 3초마다 채팅방 목록을 가져와 읽지 않은 메시지 수 자동 업데이트
  - 채팅 탭으로 이동할 때 즉시 업데이트
  - Timer를 사용하여 주기적으로 업데이트

- 배지 UI 구현
  - Stack과 Positioned를 사용하여 아이콘 우측 상단에 배지 배치
  - 99개 초과 시 "99+" 표시
  - 빨간색 원형 배지에 흰색 텍스트로 숫자 표시
  - 읽지 않은 메시지가 없을 때는 배지 미표시

## 기술적 세부사항
- 프론트엔드: Flutter
- API: ApiService.getMyChatRooms()를 사용하여 채팅방 목록 조회
- 상태 관리: StatefulWidget의 setState를 사용
- 타이머: Timer.periodic을 사용하여 주기적 업데이트

## 개선 효과
- 사용자가 읽지 않은 메시지 수를 한눈에 확인 가능
- 네비게이션바에서 바로 확인 가능하여 사용자 경험 개선
- 실시간 업데이트로 최신 상태 유지

## 관련 파일
- intersection-frontend/lib/screens/main_tab_screen.dart
