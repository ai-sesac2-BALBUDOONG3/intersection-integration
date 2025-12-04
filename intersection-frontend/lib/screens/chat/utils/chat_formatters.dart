/// 채팅 관련 포맷터 유틸리티
class ChatFormatters {
  /// ISO 8601 형식의 시간 문자열을 "HH:mm" 형식으로 변환
  static String formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "";
    }
  }
}

