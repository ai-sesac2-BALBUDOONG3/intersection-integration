import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/friends/friend_profile_screen.dart';
import 'package:intersection/services/api_service.dart';

class RecommendedFriendsScreen extends StatefulWidget {
  const RecommendedFriendsScreen({super.key});

  @override
  State<RecommendedFriendsScreen> createState() =>
      _RecommendedFriendsScreenState();
}

class _RecommendedFriendsScreenState extends State<RecommendedFriendsScreen> {
  bool _isLoading = true;
  List<User> _recommended = [];

  @override
  void initState() {
    super.initState();
    _loadRecommended();
  }

  Future<void> _loadRecommended() async {
    // 로그인하지 않은 경우 API 호출하지 않음
    if (AppState.token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final users = await ApiService.getRecommendedFriends();

      setState(() {
        _recommended = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("추천친구 불러오기 오류: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFriend(User user) async {
    try {
      final success = await ApiService.addFriend(user.id);

      if (success) {
        setState(() {
          _recommended.removeWhere((u) => u.id == user.id);
        });

        AppState.friends.add(user);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${user.name}님이 친구로 추가되었습니다.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구 추가 실패")),
        );
      }
    } catch (e) {
      debugPrint("친구추가 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("친구추가 오류: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFriends = AppState.friends;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '당신과 지역·학교·나이가 유사한 친구들을 추천해요',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        ..._recommended.map((user) {
          final isFriendAlready =
              currentFriends.any((f) => f.id == user.id);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(user.name),
              subtitle: Text("${user.school} · ${user.region}"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FriendProfileScreen(user: user),
                  ),
                );
              },

              trailing: isFriendAlready
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 22)
                  : FilledButton(
                      onPressed: () => _addFriend(user),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18),
                      ),
                      child: const Text('추가'),
                    ),
            ),
          );
        }),
      ],
    );
  }
}
