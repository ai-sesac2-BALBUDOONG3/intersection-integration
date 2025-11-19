import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';

class RecommendedFriendsScreen extends StatefulWidget {
  const RecommendedFriendsScreen({super.key});

  @override
  State<RecommendedFriendsScreen> createState() =>
      _RecommendedFriendsScreenState();
}

class _RecommendedFriendsScreenState extends State<RecommendedFriendsScreen> {
  void _follow(User user) {
    setState(() {
      AppState.follow(user);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name}님을 친구로 추가했어.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = AppState.currentUser;
    final recommended = AppState.recommendedFriends;

    return Scaffold(
      appBar: AppBar(
        title: const Text('추천친구'),
      ),
      body: me == null
          ? const Center(child: Text('로그인 정보가 없어요. 앱을 다시 시작해줘.'))
          : recommended.isEmpty
              ? const Center(
                  child: Text(
                    '지금 조건에 맞는 추천 친구가 없어요.\n조금 더 기다려보자.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: recommended.length,
                  itemBuilder: (context, index) {
                    final user = recommended[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${user.school} · ${user.region}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    '${user.birthYear}년생',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _follow(user),
                              child: const Text('친구 추가'),
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
