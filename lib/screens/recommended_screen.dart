import 'package:flutter/material.dart';

class RecommendedFriend {
  final String name;
  final String schoolInfo; // 예: "서울 A초 08학번"
  final List<String> commonTags; // 공통점 태그
  bool isFollowing; // 친구추가 되었는지 여부

  RecommendedFriend({
    required this.name,
    required this.schoolInfo,
    required this.commonTags,
    this.isFollowing = false,
  });
}

class RecommendedFriendsScreen extends StatefulWidget {
  const RecommendedFriendsScreen({super.key});

  @override
  State<RecommendedFriendsScreen> createState() =>
      _RecommendedFriendsScreenState();
}

class _RecommendedFriendsScreenState extends State<RecommendedFriendsScreen> {
  // TODO: 나중엔 API로 받으면 됨. 지금은 하드코딩
  final List<RecommendedFriend> _friends = [
    RecommendedFriend(
      name: '김민수',
      schoolInfo: '서울 A초 08학번',
      commonTags: ['같은 초등학교', '08학번', '농구부'],
    ),
    RecommendedFriend(
      name: '이수진',
      schoolInfo: '부산 B중 11학번',
      commonTags: ['같은 중학교', '합창단', '추억 키워드: 수련회'],
    ),
    RecommendedFriend(
      name: '박지훈',
      schoolInfo: '인천 C고 14학번',
      commonTags: ['같은 고등학교', '기숙사', '야간자율'],
    ),
  ];

  void _toggleFollow(int index) {
    setState(() {
      _friends[index].isFollowing = !_friends[index].isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 친구'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final f = _friends[index];
          return _FriendCard(
            friend: f,
            onFollowPressed: () => _toggleFollow(index),
          );
        },
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final RecommendedFriend friend;
  final VoidCallback onFollowPressed;

  const _FriendCard({
    required this.friend,
    required this.onFollowPressed,
  });

  @override
  Widget build(BuildContext context) {
    final initials = friend.name.isNotEmpty ? friend.name[0] : '?';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 프로필 동그라미
            CircleAvatar(
              radius: 22,
              child: Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 가운데 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friend.schoolInfo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: -4,
                    children: friend.commonTags
                        .map(
                          (t) => Chip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 오른쪽 친구추가 버튼
            Column(
              children: [
                FilledButton.tonal(
                  onPressed: onFollowPressed,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(80, 36),
                  ),
                  child: Text(
                    friend.isFollowing ? '추가됨' : '친구 추가',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
