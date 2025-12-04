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
  List<ChatRoom> _filteredRooms = [];
  bool _isLoading = true;
  bool _isSearchMode = false;
  Timer? _pollingTimer;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  void _filterRooms(String query) {
    if (query.trim().isEmpty) {
      _filteredRooms = _chatRooms;
    } else {
      final searchQuery = query.trim().toLowerCase();
      final filtered = _chatRooms.where((room) {
        final friendName = (room.friendName ?? "").toLowerCase();
        final lastMessage = (room.lastMessage ?? "").toLowerCase();
        
        // 사용자 이름 또는 마지막 메시지 내용에서만 검색
        return friendName.contains(searchQuery) || lastMessage.contains(searchQuery);
      }).toList();
      
      // 검색 결과도 고정된 것이 먼저 오도록 정렬
      filtered.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return b.isPinned ? 1 : -1;
        }
        return 0;
      });
      
      _filteredRooms = filtered;
    }
  }


  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _filteredRooms = _chatRooms;
      }
    });
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
        // 고정된 채팅방을 최상단에 정렬
        _chatRooms = List.from(rooms);
        _chatRooms.sort((a, b) {
          // 고정된 것이 먼저
          if (a.isPinned != b.isPinned) {
            return b.isPinned ? 1 : -1;
          }
          // 같은 고정 상태면 시간 역순 (최신이 먼저)
          final aTime = a.lastMessageTime ?? "";
          final bTime = b.lastMessageTime ?? "";
          return bTime.compareTo(aTime);
        });
        
        // 검색 모드이고 검색어가 있으면 필터링 적용, 아니면 전체 목록 표시
        if (_isSearchMode && _searchController.text.trim().isNotEmpty) {
          _filterRooms(_searchController.text);
        } else {
          _filteredRooms = _chatRooms;
        }
        setState(() {
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
    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '채팅방 검색',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) {
                  _filterRooms(value);
                  setState(() {});
                },
              )
            : const Text(
                '채팅',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearchMode ? Icons.close : Icons.search),
            onPressed: _toggleSearchMode,
            tooltip: _isSearchMode ? '검색 닫기' : '검색',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty && !_isSearchMode
              ? Center(
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
                )
              : _isSearchMode && _searchController.text.trim().isNotEmpty && _filteredRooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "검색 결과가 없어요",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "다른 검색어를 입력해보세요",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredRooms.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 80,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final room = _filteredRooms[index];
                      return _buildChatRoomTile(room);
                    },
                  ),
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
          if (room.isPinned)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.push_pin,
                size: 16,
                color: Colors.blue.shade600,
              ),
            ),
          Expanded(
            child: Text(
              room.friendName ?? "Unknown",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: room.isPinned ? Colors.blue.shade700 : Colors.black87,
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
      trailing: IconButton(
        icon: Icon(
          room.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          color: room.isPinned ? Colors.blue.shade600 : Colors.grey.shade400,
          size: 20,
        ),
        onPressed: () async {
          final success = await ApiService.togglePinChatRoom(room.id);
          if (success) {
            _loadChatRooms(showLoading: false);
          }
        },
        tooltip: room.isPinned ? '고정 해제' : '고정하기',
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
              iReportedThem: room.iReportedThem,
              theyBlockedMe: room.theyBlockedMe,
              theyLeft: room.theyLeft,  // ✅ 추가
            ),
          ),
        ).then((_) => _loadChatRooms());
      },
    );
  }
}