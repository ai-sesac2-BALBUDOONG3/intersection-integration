import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  void _unfollow(User user) {
    setState(() {
      AppState.unfollow(user);
    });
  }

  void _openChat(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(friend: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = AppState.friends;

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 목록'),
      ),
      body: friends.isEmpty
          ? const Center(
              child: Text(
                '아직 친구가 없어요.\n추천친구에서 먼저 친구를 추가해봐.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final user = friends[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.school} · ${user.region}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _openChat(user),
                          child: const Text('채팅'),
                        ),
                        IconButton(
                          onPressed: () => _unfollow(user),
                          icon: const Icon(Icons.close),
                          tooltip: '친구 삭제',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
