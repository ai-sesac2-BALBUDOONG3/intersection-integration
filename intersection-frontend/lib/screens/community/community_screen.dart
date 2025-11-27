import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/models/user.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {

  @override
  Widget build(BuildContext context) {
    final me = AppState.currentUser;
    final posts = AppState.communityPosts;

    if (me == null) {
      return const Center(
        child: Text('로그인이 필요해요.'),
      );
    }

    return Stack(
      children: [
        posts.isEmpty
            ? const Center(
                child: Text(
                  '아직 커뮤니티에 글이 없어요.\n글쓰기 버튼을 눌러 첫 글을 작성해보세요!',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final post = posts[index];

                  User? author;
                  final knownUsers = [
                    me,
                    ...AppState.friends,
                  ];

                  try {
                    author = knownUsers.firstWhere(
                      (u) => u.id.toString() == post.authorId,
                    );
                  } catch (_) {
                    author = null;
                  }

                  return _ThreadPost(
                    post: post,
                    author: author,
                  );
                },
              ),

        // 글쓰기 버튼
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            shape: const CircleBorder(),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/write');
              if (result == true) {
                setState(() {});
              }
            },
            child: const Icon(Icons.edit, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // load posts from server
    ApiService.listPosts().then((rows) {
      final posts = rows.map((r) => Post.fromJson(r)).toList();
      AppState.communityPosts = posts;
      setState(() {});
    }).catchError((e) {
      // keep local state if request fails
    });
  }
}

class _ThreadPost extends StatelessWidget {
  final Post post;
  final User? author;

  const _ThreadPost({
    required this.post,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 22,
          child: Icon(Icons.person),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    author?.name ?? "알 수 없음",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    author != null
                        ? "${author!.school} · ${author!.region}"
                        : "",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.favorite_border,
                      size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/comments',
                        arguments: post,
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 18, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '댓글 보기',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
