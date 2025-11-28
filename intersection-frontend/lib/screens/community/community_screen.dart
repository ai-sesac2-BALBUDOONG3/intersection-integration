import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/profile/profile_screen.dart';
import 'package:intersection/screens/friends/friend_profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    final me = AppState.currentUser;
    final posts = AppState.communityPosts;

    if (me == null) {
      return const Center(child: Text('로그인이 필요해요.'));
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
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final post = posts[index];

                  User? author;
                  final knownUsers = [me, ...AppState.friends];
                  try {
                    author = knownUsers.firstWhere(
                      (u) => u.id == post.authorId,
                    );
                  } catch (_) {
                    author = null;
                  }

                  return _ThreadPost(post: post, author: author);
                },
              ),

        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            shape: const CircleBorder(),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/write');
              if (result == true) {
                _refreshPosts();
              }
            },
            child: const Icon(Icons.edit, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _refreshPosts() {
    ApiService.listPosts().then((rows) {
      final posts = rows.map((r) => Post.fromJson(r)).toList();
      AppState.communityPosts = posts;
      if (mounted) setState(() {});
    }).catchError((e) {
      print('게시글 불러오기 실패: $e');
    });
  }
}

class _ThreadPost extends StatelessWidget {
  final Post post;
  final User? author;

  const _ThreadPost({required this.post, required this.author});

  bool get isMyPost => author?.id == AppState.currentUser?.id;

  // ---------------------------------------------------------
  // 🔥 프로필 이미지 로더
  // ---------------------------------------------------------
  ImageProvider _profileProvider(User? u) {
    if (u == null) {
      return const AssetImage("assets/images/logo.png");
    }

    // 웹: bytes 우선
    if (u.profileImageBytes != null) {
      return MemoryImage(u.profileImageBytes!);
    }

    // 앱: 로컬 파일 우선
    if (u.profileImageUrl != null) {
      final file = File(u.profileImageUrl!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    return const AssetImage("assets/images/logo.png");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 프로필 클릭 + 이미지 반영
          GestureDetector(
            onTap: () {
              if (isMyPost) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (author != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendProfileScreen(user: author!),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 22,
              backgroundImage: _profileProvider(author),
              child: (author?.profileImageUrl == null &&
                      author?.profileImageBytes == null)
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildContent(),
                const SizedBox(height: 12),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔥 헤더
  // ---------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName ?? author?.name ?? "알 수 없음",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                (post.authorSchool != null && post.authorRegion != null)
                    ? "${post.authorSchool} · ${post.authorRegion}"
                    : (author != null
                        ? "${author!.school} · ${author!.region}"
                        : ""),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, size: 20),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 🔥 본문 텍스트 (간격 좁힘)
  // ---------------------------------------------------------
  Widget _buildContent() {
    return Text(
      post.content,
      style: const TextStyle(
        fontSize: 15,
        height: 1.35, // ✔ 간격 조정됨
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔥 Footer (댓글/좋아요)
  // ---------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/comments', arguments: post);
          },
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                '댓글 보기',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
