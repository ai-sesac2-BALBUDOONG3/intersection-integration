import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

/// 이모지 피커 위젯
class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final bool isVisible;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          onEmojiSelected(emoji.emoji);
        },
        config: const Config(
          height: 256,
          checkPlatformCompatibility: true,
        ),
      ),
    );
  }
}

