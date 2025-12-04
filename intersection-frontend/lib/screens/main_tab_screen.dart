import 'package:flutter/material.dart';
import 'package:intersection/screens/friends/recommended_friends_screen.dart';
import 'package:intersection/screens/friends/friends_screen.dart';
import 'package:intersection/screens/community/community_screen.dart';
import 'package:intersection/screens/profile/profile_screen.dart';
import 'package:intersection/screens/chat/chat_list_screen.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/data/app_state.dart';
import 'dart:async';

class MainTabScreen extends StatefulWidget {
  final int initialIndex;

  // 기본은 친구목록 = 0
  const MainTabScreen({super.key, this.initialIndex = 0});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _currentIndex = widget.initialIndex;
  int _totalUnreadCount = 0;
  Timer? _unreadCountTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // 3초마다 읽지 않은 메시지 수 업데이트
    _unreadCountTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _unreadCountTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    if (AppState.token == null) {
      if (mounted) {
        setState(() => _totalUnreadCount = 0);
      }
      return;
    }

    try {
      final rooms = await ApiService.getMyChatRooms();
      if (mounted) {
        final total = rooms.fold<int>(
          0,
          (sum, room) => sum + room.unreadCount,
        );
        setState(() => _totalUnreadCount = total);
      }
    } catch (e) {
      // 에러 발생 시 무시 (조용히 실패)
      debugPrint("읽지 않은 메시지 수 불러오기 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const FriendsScreen(),            // 0
      const RecommendedFriendsScreen(), // 1
      const CommunityScreen(),          // 2
      const ChatListScreen(),           // 3
      const ProfileScreen(),            // 4
    ];

    // 🔥 AppBar 전체 간격 조절 버전
    final appBars = [
      AppBar(
        title: const Text("친구 목록"),
        toolbarHeight: 64,      // 상단 여백 증가
        titleSpacing: 16,
      ),
      AppBar(
        title: const Text("추천 친구"),
        toolbarHeight: 64,
        titleSpacing: 16,
      ),
      AppBar(
        title: const Text("커뮤니티"),
        toolbarHeight: 64,
        titleSpacing: 16,
      ),
      null, // 채팅 화면은 자체 AppBar 사용
      AppBar(
        title: const Text("내 정보"),
        toolbarHeight: 64,
        titleSpacing: 16,
      ),
    ];

    return Scaffold(
      appBar: appBars[_currentIndex],
      body: screens[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          // 채팅 탭으로 이동할 때 읽지 않은 메시지 수 즉시 업데이트
          if (index == 3) {
            _loadUnreadCount();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '친구목록',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search),
            label: '추천친구',
          ),
          const NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: '커뮤니티',
          ),
          NavigationDestination(
            icon: _buildChatIcon(Icons.chat_bubble_outline),
            selectedIcon: _buildChatIcon(Icons.chat_bubble),
            label: '채팅',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }

  Widget _buildChatIcon(IconData icon) {
    if (_totalUnreadCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _totalUnreadCount > 99 ? '99+' : '$_totalUnreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Icon(icon);
  }
}
