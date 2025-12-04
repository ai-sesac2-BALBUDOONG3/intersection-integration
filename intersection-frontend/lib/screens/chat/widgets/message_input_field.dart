import 'package:flutter/material.dart';
import 'emoji_picker_widget.dart';

/// 메시지 입력 필드 위젯
class MessageInputField extends StatelessWidget {
  final TextEditingController messageController;
  final bool showEmojiPicker;
  final bool isBlockedForInput;
  final bool isUploading;
  final bool isSending;
  final VoidCallback onToggleEmojiPicker;
  final VoidCallback onShowAttachmentOptions;
  final VoidCallback onSendMessage;
  final Function(String) onEmojiSelected;

  const MessageInputField({
    super.key,
    required this.messageController,
    required this.showEmojiPicker,
    required this.isBlockedForInput,
    required this.isUploading,
    required this.isSending,
    required this.onToggleEmojiPicker,
    required this.onShowAttachmentOptions,
    required this.onSendMessage,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isUploading)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('파일 업로드 중...', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        EmojiPickerWidget(
          isVisible: showEmojiPicker,
          onEmojiSelected: onEmojiSelected,
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (!isBlockedForInput)
                IconButton(
                  icon: Icon(
                    showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: showEmojiPicker ? Colors.blue : Colors.grey,
                  ),
                  onPressed: onToggleEmojiPicker,
                ),
              if (!isBlockedForInput)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  onPressed: isUploading ? null : onShowAttachmentOptions,
                ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  enabled: !isBlockedForInput && !isUploading,
                  decoration: InputDecoration(
                    hintText: isUploading
                        ? "파일 업로드 중..."
                        : isBlockedForInput
                            ? "메시지를 보낼 수 없습니다"
                            : "메시지를 입력하세요...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSendMessage(),
                  onTap: () {
                    if (showEmojiPicker) {
                      onToggleEmojiPicker();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isSending || isBlockedForInput || isUploading ? null : onSendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSending || isBlockedForInput || isUploading ? Colors.grey : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: isSending || isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

