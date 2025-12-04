import 'package:flutter/material.dart';

/// 채팅 스크롤 관리 서비스
/// 스크롤 제어 및 메시지로 이동 기능을 제공합니다.
class ChatScrollService {
  /// 맨 아래로 스크롤
  static void scrollToBottom(ScrollController scrollController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 특정 메시지로 스크롤 이동
  static void scrollToMessage(
    int messageId,
    List<dynamic> messages,
    Map<int, GlobalKey> messageKeys,
    ScrollController scrollController,
    Function(int) findMessageIndex,
  ) {
    // 메시지 찾기
    final messageIndex = findMessageIndex(messageId);
    if (messageIndex == -1) {
      return;
    }

    // GlobalKey로 스크롤 이동
    final key = messageKeys[messageId];
    if (key?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.15, // 화면 상단 15% 위치에 표시
        );
      });
    } else {
      // GlobalKey가 없으면 인덱스로 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          // 대략적인 위치 계산 (메시지당 평균 높이 80px 가정)
          final estimatedOffset = messageIndex * 80.0;
          scrollController.animateTo(
            estimatedOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// 스크롤 리스너로 사용자 스크롤 상태 확인
  static bool checkUserScrolling(
    ScrollController scrollController,
    double threshold,
  ) {
    if (!scrollController.hasClients) return false;

    final currentPosition = scrollController.position.pixels;
    final maxScroll = scrollController.position.maxScrollExtent;

    // 사용자가 스크롤을 올렸는지 확인 (threshold 이상 위로 올렸으면 사용자가 스크롤 중)
    return currentPosition < maxScroll - threshold;
  }

  /// 맨 밑 근처에 있는지 확인
  static bool isNearBottom(ScrollController scrollController, double threshold) {
    if (!scrollController.hasClients) return false;

    final currentPosition = scrollController.position.pixels;
    final maxScroll = scrollController.position.maxScrollExtent;

    return currentPosition >= maxScroll - threshold;
  }
}

