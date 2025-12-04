import '../../../models/chat_message.dart';

/// 채팅 메시지 관리 서비스
/// 메시지 로딩, 필터링, 검색 기능을 제공합니다.
class ChatMessageService {
  /// 메시지 필터링
  static List<ChatMessage> filterMessages(
    List<ChatMessage> messages,
    String query,
  ) {
    if (query.isEmpty) {
      return messages;
    }
    return messages.where((message) {
      return message.content.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// 필터링된 메시지 업데이트
  static List<ChatMessage> updateFilteredMessages(
    List<ChatMessage> messages,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) {
      return messages;
    }
    return filterMessages(messages, searchQuery);
  }

  /// 메시지 목록 정렬 (시간 순서대로)
  static void sortMessagesByTime(List<ChatMessage> messages) {
    messages.sort((a, b) {
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  /// 고정된 메시지 목록 추출 및 정렬 (시간 역순)
  static List<ChatMessage> extractPinnedMessages(List<ChatMessage> messages) {
    final pinned = messages.where((m) => m.isPinned).toList();
    pinned.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pinned;
  }
}

