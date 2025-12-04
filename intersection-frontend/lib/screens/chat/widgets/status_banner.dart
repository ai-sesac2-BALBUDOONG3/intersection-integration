import 'package:flutter/material.dart';

/// 채팅방 상태 배너 위젯
/// 차단/신고/나감 상태를 표시합니다.
class StatusBanner extends StatelessWidget {
  final bool iReportedThem;
  final bool iBlockedThem;
  final bool theyBlockedMe;
  final bool theyLeft;

  const StatusBanner({
    super.key,
    required this.iReportedThem,
    required this.iBlockedThem,
    required this.theyBlockedMe,
    required this.theyLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 내가 신고/차단했을 때 배너
        if (iReportedThem || iBlockedThem)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "신고 또는 차단한 사용자입니다. 메시지를 보낼 수 없습니다.",
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 신고/차단 당했을 때 배너
        if (theyBlockedMe)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "상대방이 회원님을 신고 또는 차단하여 메시지를 보낼 수 없습니다. 채팅방을 나가주세요.",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 상대방이 채팅방을 나간 경우 배너
        if (theyLeft && !(iReportedThem || iBlockedThem) && !theyBlockedMe)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Icon(
                  Icons.exit_to_app,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "상대방이 채팅방을 나갔습니다. 메시지를 보낼 수 없습니다.",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

