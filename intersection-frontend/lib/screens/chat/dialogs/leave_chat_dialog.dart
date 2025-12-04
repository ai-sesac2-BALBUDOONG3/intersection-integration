import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

/// 채팅방 나가기 다이얼로그
class LeaveChatDialog {
  /// 채팅방 나가기 확인 다이얼로그
  static void showLeaveChatDialog(
    BuildContext context,
    int roomId,
    VoidCallback onLeaveSuccess,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('채팅방 나가기'),
            ],
          ),
          content: const Text(
            '채팅방을 나가시겠습니까?\n\n나가면:\n• 채팅방 목록에서 사라집니다\n• 상대방에게 나간 사실이 알려집니다\n• 다시 들어올 수 없습니다',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await ApiService.deleteChatRoom(roomId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('채팅방을 나갔습니다')),
                  );
                  onLeaveSuccess();
                }
              },
              child: const Text('나가기', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

