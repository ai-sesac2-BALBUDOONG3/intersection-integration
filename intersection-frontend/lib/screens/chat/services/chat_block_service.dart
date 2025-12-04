import '../../../services/api_service.dart';

/// 채팅 차단/신고 상태 관리 서비스
class ChatBlockService {
  /// 차단 상태 확인
  static Future<bool> checkBlockStatus(int friendId) async {
    try {
      return await ApiService.checkIfBlocked(friendId);
    } catch (e) {
      return false;
    }
  }

  /// 신고 상태 확인
  static Future<Map<String, dynamic>> checkReportStatus(int friendId) async {
    try {
      final report = await ApiService.checkMyReport(friendId);
      return {
        'isReported': report != null,
        'reportId': report?.id,
      };
    } catch (e) {
      return {
        'isReported': false,
        'reportId': null,
      };
    }
  }
}

