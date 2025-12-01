import 'package:flutter/material.dart';
import '../../models/chat_room.dart';
import '../../services/api_service.dart';
import '../../data/app_state.dart';
import '../../config/api_config.dart';
import 'chat_screen.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadChatRooms(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChatRooms({bool showLoading = true}) async {
    if (AppState.token == null) {
      if (showLoading) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final rooms = await ApiService.getMyChatRooms();
      if (mounted) {
        setState(() {
          _chatRooms = rooms;
          if (showLoading) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      debugPrint("채팅방 목록 불러오기 오류: $e");
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "아직 채팅이 없어요",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "친구와 대화를 시작해보세요!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _chatRooms.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 80,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final room = _chatRooms[index];
          return _buildChatRoomTile(room);
        },
      ),
    );
  }

  Widget _buildChatRoomTile(ChatRoom room) {
    String timeText = "";
    if (room.lastMessageTime != null) {
      try {
        final dateTime = DateTime.parse(room.lastMessageTime!);
        final now = DateTime.now();
        final diff = now.difference(dateTime);

        if (diff.inMinutes < 1) {
          timeText = "방금";
        } else if (diff.inHours < 1) {
          timeText = "${diff.inMinutes}분 전";
        } else if (diff.inDays < 1) {
          timeText = "${diff.inHours}시간 전";
        } else if (diff.inDays < 7) {
          timeText = "${diff.inDays}일 전";
        } else {
          timeText = "${dateTime.month}/${dateTime.day}";
        }
      } catch (e) {
        timeText = "";
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: room.friendProfileImage != null
          ? CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                "${ApiConfig.baseUrl}${room.friendProfileImage}",
              ),
              onBackgroundImageError: (_, __) {},
              child: null,
            )
          : CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                room.friendName?.substring(0, 1) ?? "?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              room.friendName ?? "Unknown",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (timeText.isNotEmpty)
            Text(
              timeText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (room.isLastMessageImage && room.lastFileUrl != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  "${ApiConfig.baseUrl}${room.lastFileUrl}",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],
          
          Expanded(
            child: Text(
              room.lastMessage ?? "메시지가 없습니다",
              style: TextStyle(
                fontSize: 14,
                color: room.unreadCount > 0
                    ? Colors.black87
                    : Colors.grey.shade600,
                fontWeight: room.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (room.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                room.unreadCount > 99 ? "99+" : "${room.unreadCount}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: room.id,
              friendId: room.friendId,
              friendName: room.friendName ?? "Unknown",
              friendProfileImage: room.friendProfileImage,
              iReportedThem: room.iReportedThem,  // ✅ 통합
              theyBlockedMe: room.theyBlockedMe,  // ✅ 통합
            ),
          ),
        ).then((_) => _loadChatRooms());
      },
    );
  }
}