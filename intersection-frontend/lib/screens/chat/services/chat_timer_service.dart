import 'dart:async';

/// 채팅 메시지 타이머 관리 서비스
/// 60초 카운트다운 타이머를 관리합니다.
class ChatTimerService {
  /// 카운트다운 시작
  static Timer startCountdown(
    int messageId,
    int durationSeconds,
    Function(int, int) onTick,
    VoidCallback onComplete,
  ) {
    int remaining = durationSeconds;

    return Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      onTick(messageId, remaining);

      if (remaining <= 0) {
        timer.cancel();
        onComplete();
      }
    });
  }

  /// 모든 타이머 취소
  static void cancelAllTimers(Map<int, Timer> timers) {
    for (var timer in timers.values) {
      timer.cancel();
    }
    timers.clear();
  }

  /// 특정 메시지의 타이머 취소
  static void cancelTimer(int messageId, Map<int, Timer> timers) {
    timers[messageId]?.cancel();
    timers.remove(messageId);
  }
}

