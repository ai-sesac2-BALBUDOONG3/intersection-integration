import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/chat/chat_screen.dart';
import 'package:intersection/screens/friends/friend_profile_screen.dart';
import 'package:intersection/screens/profile/profile_screen.dart';
import 'package:intersection/services/api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _isLoading = true;
  bool _friendsExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    if (AppState.token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final friends = await ApiService.getFriends();

      setState(() {
        AppState.friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("친구 목록 불러오기 오류: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = AppState.friends;
    final currentUser = AppState.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        children: [
          _buildMyProfile(currentUser),
          const SizedBox(height: 28),

          // ---------------------------------------
          // 친구 목록 헤더
          // ---------------------------------------
          GestureDetector(
            onTap: () {
              setState(() {
                _friendsExpanded = !_friendsExpanded;
              });
            },
            child: Row(
              children: [
                Text(
                  '친구 ${friends.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(
                  _friendsExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 26,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (_friendsExpanded)
            ...friends.map((user) => _buildFriendTile(user)).toList(),
        ],
      ),
    );
  }

  // ============================================================
  // 🔥 내 프로필 카드 (Threads 스타일 리팩토링)
  // ============================================================
  Widget _buildMyProfile(User? user) {
    if (user == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            child: Icon(Icons.person, size: 34),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${user.school} · ${user.region}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // 🔥 편집 아이콘 → 내 프로필로 이동
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          )
        ],
      ),
    );
  }

  // ============================================================
  // 🔥 친구 카드 (전체 리팩토링)
  // ============================================================
  Widget _buildFriendTile(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            child: Icon(Icons.person, size: 30),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendProfileScreen(user: user),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${user.school} · ${user.region}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔥 채팅 버튼 Pill 형태
          ElevatedButton(
            onPressed: () => _startChat(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              "채팅",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 채팅 시작하기
  Future<void> _startChat(User friend) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final chatRoom = await ApiService.createOrGetChatRoom(friend.id);

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            roomId: chatRoom.id,
            friendId: friend.id,
            friendName: friend.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("채팅방 생성 실패: $e")),
      );
    }
  }
}
