import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../data/app_state.dart';

/// 고정된 메시지 표시 바 위젯
/// 한 번에 하나의 고정 메시지만 표시하고, 클릭 시 순환합니다.
class PinnedMessageBar extends StatelessWidget {
  final List<ChatMessage> pinnedMessages;
  final int currentPinnedIndex;
  final String friendName;
  final VoidCallback onTap;

  const PinnedMessageBar({
    super.key,
    required this.pinnedMessages,
    required this.currentPinnedIndex,
    required this.friendName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    final msg = pinnedMessages[currentPinnedIndex];
    final isMe = msg.senderId == AppState.currentUser?.id;

    // 메시지 내용 텍스트
    String messageText = msg.isImage
        ? '📷 이미지'
        : msg.fileName != null
            ? '📎 ${msg.fileName}'
            : msg.content;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.push_pin,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${isMe ? '나' : friendName}: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      messageText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 여러 개일 때만 화살표 표시
            if (pinnedMessages.length > 1)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }
}

