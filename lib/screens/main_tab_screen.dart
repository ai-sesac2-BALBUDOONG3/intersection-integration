import 'package:flutter/material.dart';
import 'package:intersection/screens/recommended_friends_screen.dart';
import 'package:intersection/screens/friends_screen.dart';
import 'package:intersection/screens/community_screen.dart';
import 'package:intersection/screens/profile_screen.dart';
import 'package:intersection/screens/chat_list_screen.dart'; // 🔥 추가 필요

class MainTabScreen extends StatefulWidget {
  final int initialIndex;
  const MainTabScreen({super.key, this.initialIndex = 1});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _currentIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    // 각 탭 화면
    final screens = [
      const FriendsScreen(),            // 0
      const RecommendedFriendsScreen(), // 1
      const CommunityScreen(),          // 2
      const ChatListScreen(),           // 3 🔥 새 탭
      const ProfileScreen(),            // 4
    ];

    // 각 탭의 AppBar
    final appBars = [
      AppBar(title: const Text("친구 목록")),
      AppBar(title: const Text("추천 친구")),
      AppBar(title: const Text("커뮤니티")),
      AppBar(title: const Text("채팅")),        // 🔥 새 AppBar
      AppBar(title: const Text("내 정보")),
    ];

    return Scaffold(
      appBar: appBars[_currentIndex],
      body: screens[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
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
            label: '채팅',        // 🔥 추가된 탭
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
