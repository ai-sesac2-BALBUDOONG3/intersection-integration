import 'package:flutter/material.dart';

class FireLikeButton extends StatefulWidget {
  final bool initialLiked;
  final Function(bool) onChanged;

  const FireLikeButton({
    super.key,
    required this.initialLiked,
    required this.onChanged,
  });

  @override
  State<FireLikeButton> createState() => _FireLikeButtonState();
}

class _FireLikeButtonState extends State<FireLikeButton>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 현재 좋아요 여부 받아오기
    isLiked = widget.initialLiked;

    // 애니메이션 컨트롤러
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // 🔥 커졌다가 줄어드는 효과
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.6), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });

    // 팡! 하고 커지는 애니메이션 시작
    _controller.forward(from: 0);

    // 외부에 변경된 상태 알려주기
    widget.onChanged(isLiked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleLike,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Text(
          "🔥",
          style: TextStyle(
            fontSize: 26,
            color: isLiked ? Colors.orange : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
