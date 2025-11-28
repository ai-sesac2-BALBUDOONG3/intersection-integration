import 'package:flutter/material.dart';
import 'package:intersection/screens/friends/recommended_friends_screen.dart';
import 'package:intersection/screens/friends/friends_screen.dart';
import 'package:intersection/screens/community/community_screen.dart';
import 'package:intersection/screens/profile/profile_screen.dart';
import 'package:intersection/screens/chat/chat_list_screen.dart';

class MainTabScreen extends StatefulWidget {
  final int initialIndex;

  // 기본은 친구목록 = 0
  const MainTabScreen({super.key, this.initialIndex = 0});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _currentIndex = widget.initialIndex;

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
      AppBar(
        title: const Text("채팅"),
        toolbarHeight: 64,
        titleSpacing: 16,
      ),
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
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '친구목록',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search),
            label: '추천친구',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: '커뮤니티',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}
