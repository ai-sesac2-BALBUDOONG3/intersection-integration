import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/profile/profile_screen.dart';
import 'package:intersection/screens/friends/friend_profile_screen.dart';
import 'package:intersection/config/api_config.dart';

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

                  return ThreadPost(post: post, author: author);
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

// ==========================================================
// 🔥 이미지 Provider — 웹/앱 완벽 대응
// ==========================================================
ImageProvider resolveImage(String? url, Uint8List? bytes) {
  if (bytes != null) return MemoryImage(bytes);

  if (url != null && url.isNotEmpty) {
    if (url.startsWith("http")) return NetworkImage(url);
    if (url.startsWith("/")) return NetworkImage("${ApiConfig.baseUrl}$url");
  }

  return const AssetImage("assets/images/logo.png");
}

// ==========================================================
// 🔥 ThreadPost — 프로필/본문/이미지 안정화 버전
// ==========================================================
class ThreadPost extends StatefulWidget {
  final Post post;
  final User? author;

  const ThreadPost({super.key, required this.post, required this.author});

  @override
  State<ThreadPost> createState() => _ThreadPostState();
}

class _ThreadPostState extends State<ThreadPost> {
  late bool liked;
  late int likesCount;

  @override
  void initState() {
    super.initState();
    liked = widget.post.liked;
    likesCount = widget.post.likesCount;
  }

  @override
  void didUpdateWidget(ThreadPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      liked = widget.post.liked;
      likesCount = widget.post.likesCount;
    }
  }

  bool get isMyPost => widget.author?.id == AppState.currentUser?.id;

  ImageProvider _profileProvider(User? u) {
    if (u == null) return const AssetImage("assets/images/logo.png");
    return resolveImage(u.profileImageUrl, u.profileImageBytes);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

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
          // ------------------------------
          // 🔥 프로필 영역
          // ------------------------------
          GestureDetector(
            onTap: () {
              if (isMyPost) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (widget.author != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendProfileScreen(user: widget.author!),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 22,
              backgroundImage: _profileProvider(widget.author),
            ),
          ),

          const SizedBox(width: 12),

          // ------------------------------
          // 🔥 본문
          // ------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildContent(),

                // ------------------------------------------------------
                // 🔥 게시글 이미지
                // ------------------------------------------------------
                if (widget.post.imageUrl != null &&
                    widget.post.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: resolveImage(widget.post.imageUrl, null),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final post = widget.post;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName ?? widget.author?.name ?? "알 수 없음",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                (post.authorSchool != null && post.authorRegion != null)
                    ? "${post.authorSchool} · ${post.authorRegion}"
                    : (widget.author != null
                        ? "${widget.author!.school} · ${widget.author!.region}"
                        : ""),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          icon: const Icon(Icons.more_horiz, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            _openMenu(context);
          },
        ),
      ],
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMyPost)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.redAccent),
                  title: const Text("게시물 신고하기"),
                  onTap: () {
                    Navigator.pop(context);
                    _openReportSheet(context);
                  },
                ),
              if (isMyPost)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text("게시물 삭제"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _openReportSheet(BuildContext context) {
    final reasons = [
      "스팸/광고",
      "욕설/비방",
      "혐오 발언",
      "사칭",
      "음란물",
      "불쾌한 콘텐츠",
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                "신고 사유 선택",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              ...reasons.map(
                (reason) => ListTile(
                  title: Text(reason),
                  onTap: () async {
                    Navigator.pop(context);

                    final ok = await ApiService.reportUser(
                      userId: widget.post.authorId,
                      reason: reason,
                      content: widget.post.content,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? "신고가 접수되었어요." : "신고 실패"),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Text(
      widget.post.content,
      style: const TextStyle(
        fontSize: 15,
        height: 1.35,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final wasLiked = liked;

            // 1) UI 먼저 업데이트
            setState(() {
              liked = !liked;
              likesCount += liked ? 1 : -1;
            });

            try {
              // 2) 서버로 좋아요 처리 요청 (toggle 방식)
              final res = await ApiService.toggleLike(widget.post.id);

              // 3) 서버 값으로 다시 동기화
              setState(() {
                liked = res["liked"];
                likesCount = res["likes_count"];
              });
            } catch (e) {
              // 실패 시 원래 상태로 복구
              setState(() {
                liked = wasLiked;
                likesCount += wasLiked ? 1 : -1;
              });
            }
          },
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 22,
                color: liked ? Colors.orange : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                "$likesCount",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: liked ? Colors.orange : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 18),

        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/comments', arguments: widget.post);
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
