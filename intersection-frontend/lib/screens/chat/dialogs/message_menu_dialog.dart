import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/chat_message.dart';
import '../../../services/api_service.dart';

/// 메시지 메뉴 다이얼로그
class MessageMenuDialog {
  /// 메시지 메뉴 표시 (복사, 고정)
  static void showPinMenu(
    BuildContext context,
    ChatMessage message,
    int roomId,
    VoidCallback onMessageReload,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 복사하기
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.blue),
              title: const Text('복사하기'),
              onTap: () async {
                Navigator.pop(context);
                await copyMessage(context, message);
              },
            ),
            // 복사하고 고정하기
            ListTile(
              leading: const Icon(Icons.copy_all, color: Colors.green),
              title: const Text('복사하고 고정하기'),
              onTap: () async {
                Navigator.pop(context);
                await copyAndPinMessage(context, message, roomId, onMessageReload);
              },
            ),
            const Divider(),
            // 고정하기/고정 해제
            ListTile(
              leading: Icon(
                message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: Colors.blue.shade600,
              ),
              title: Text(message.isPinned ? '고정 해제' : '고정하기'),
              onTap: () async {
                Navigator.pop(context);
                final success = await ApiService.togglePinMessage(roomId, message.id);
                if (success) {
                  onMessageReload();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 메시지 복사
  static Future<void> copyMessage(BuildContext context, ChatMessage message) async {
    String textToCopy = message.content;

    // 이미지나 파일인 경우 메시지 타입 표시
    if (message.isImage) {
      textToCopy = '[이미지] ${message.content != "[이미지]" ? message.content : ""}';
    } else if (message.fileName != null) {
      textToCopy = '[파일] ${message.fileName}\n${message.content}';
    }

    await Clipboard.setData(ClipboardData(text: textToCopy));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메시지가 복사되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 메시지 복사하고 고정하기
  static Future<void> copyAndPinMessage(
    BuildContext context,
    ChatMessage message,
    int roomId,
    VoidCallback onMessageReload,
  ) async {
    // 먼저 복사
    await copyMessage(context, message);

    // 고정되지 않은 경우에만 고정
    if (!message.isPinned) {
      final success = await ApiService.togglePinMessage(roomId, message.id);
      if (success) {
        onMessageReload();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('메시지가 복사되었고 고정되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메시지가 복사되었습니다 (이미 고정된 메시지입니다)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

