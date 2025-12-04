import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

/// 차단 관련 다이얼로그
class BlockDialogs {
  /// 차단 확인 다이얼로그
  static void showBlockDialog(
    BuildContext context,
    String friendName,
    int friendId,
    VoidCallback onBlockSuccess,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('사용자 차단', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            '$friendName님을 차단하시겠습니까?\n\n'
            '차단하면:\n'
            '• 메시지를 주고받을 수 없습니다\n'
            '• 친구 목록에서 제거됩니다\n'
            '• 게시글이 보이지 않습니다',
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
                final success = await ApiService.blockUser(friendId);
                if (success && context.mounted) {
                  onBlockSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$friendName님을 차단했습니다')),
                  );
                }
              },
              child: const Text('차단', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// 차단 해제 확인 다이얼로그
  static void showUnblockDialog(
    BuildContext context,
    String friendName,
    int friendId,
    VoidCallback onUnblockSuccess,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('차단 해제'),
            ],
          ),
          content: Text(
            '$friendName님의 차단을 해제하시겠습니까?\n\n해제하면:\n• 다시 메시지를 주고받을 수 있습니다\n• 친구 목록에 다시 추가할 수 있습니다\n• 게시글을 볼 수 있습니다',
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
                final success = await ApiService.unblockUser(friendId);
                if (success && context.mounted) {
                  onUnblockSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$friendName님의 차단을 해제했습니다')),
                  );
                }
              },
              child: const Text('해제', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// 차단 상태 안내 다이얼로그
  static void showBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('메시지 전송 불가'),
            ],
          ),
          content: const Text(
            '신고 또는 차단한 사용자입니다.\n메시지를 보낼 수 없습니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}

