import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/chat/chat_screen.dart';
import 'package:intersection/screens/friends/friend_profile_screen.dart';
import 'package:intersection/screens/profile/profile_screen.dart';
import 'package:intersection/screens/common/image_viewer.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/config/api_config.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
    AppState.addListener(_refreshOnProfileUpdate);
  }

  @override
  void dispose() {
    AppState.removeListener(_refreshOnProfileUpdate);
    super.dispose();
  }

  void _refreshOnProfileUpdate() {
    if (mounted) setState(() {});
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

  // ============================================================
  // 🔥 통합 이미지 Provider (웹/앱/상대경로/bytes 모두 처리)
  // ============================================================
  ImageProvider buildImageProvider(String? url, Uint8List? bytes) {
    try {
      // 1) bytes 우선
      if (bytes != null) {
        return MemoryImage(bytes);
      }

      // 2) url 없으면 기본 아이콘
      if (url == null || url.isEmpty) {
        return const AssetImage("assets/images/logo.png");
      }

      // 3) 이미 절대 URL
      if (url.startsWith("http")) {
        return NetworkImage(url);
      }

      // 4) /uploads/... → 서버 주소 붙이기
      if (url.startsWith("/")) {
        return NetworkImage("${ApiConfig.baseUrl}$url");
      }

      // 5) 앱이면 FileImage
      if (!kIsWeb && File(url).existsSync()) {
        return FileImage(File(url));
      }

      // 6) 그래도 안 되면 server 경로로 시도
      return NetworkImage("${ApiConfig.baseUrl}/$url");
    } catch (_) {
      return const AssetImage("assets/images/logo.png");
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
                  _friendsExpanded ? Icons.expand_less : Icons.expand_more,
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
  // 🔥 내 프로필 카드
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewer(
                    imageUrl: user.profileImageUrl,
                    bytes: user.profileImageBytes,
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 32,
              backgroundImage:
                  buildImageProvider(user.profileImageUrl, user.profileImageBytes),
              child: (user.profileImageUrl == null &&
                      user.profileImageBytes == null)
                  ? const Icon(Icons.person, size: 34)
                  : null,
            ),
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
  // 🔥 친구 카드
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewer(
                    imageUrl: user.profileImageUrl,
                    bytes: user.profileImageBytes,
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 30,
              backgroundImage:
                  buildImageProvider(user.profileImageUrl, user.profileImageBytes),
              child: (user.profileImageUrl == null &&
                      user.profileImageBytes == null)
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
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

          ElevatedButton(
            onPressed: () => _startChat(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
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
