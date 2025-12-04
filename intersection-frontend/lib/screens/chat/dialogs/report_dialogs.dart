import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

/// 신고 관련 다이얼로그
class ReportDialogs {
  /// 신고 확인 다이얼로그
  static void showReportDialog(
    BuildContext context,
    String friendName,
    int friendId,
    VoidCallback onReportSuccess,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.report, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('사용자 신고'),
            ],
          ),
          content: Text(
            '$friendName님을 신고하시겠습니까?\n\n'
            '신고하면:\n'
            '• 메시지를 주고받을 수 없습니다\n'
            '• 관리자가 검토합니다\n'
            '• 부적절한 행동 시 제재를 받을 수 있습니다',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await ApiService.reportUser(
                  userId: friendId,
                  reason: '채팅방에서 신고',
                );
                if (success && context.mounted) {
                  onReportSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$friendName님을 신고했습니다')),
                  );
                }
              },
              child: const Text('신고', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// 신고 취소 확인 다이얼로그
  static void showUnreportDialog(
    BuildContext context,
    int? reportId,
    VoidCallback onUnreportSuccess,
  ) {
    if (reportId == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.undo, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('신고 취소'),
            ],
          ),
          content: const Text(
            '신고를 취소하시겠습니까?\n\n관리자 검토가 진행 중인 경우\n취소할 수 없습니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('닫기'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await ApiService.cancelReport(reportId);
                if (success && context.mounted) {
                  onUnreportSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('신고를 취소했습니다')),
                  );
                }
              },
              child: const Text('취소하기', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

