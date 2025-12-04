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
import 'package:intersection/screens/common/report_screen.dart'; // 신고 화면

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  Set<String> _selectedFilters = {}; // 중복 선택 가능

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    ApiService.listPosts().then((rows) {
      final posts = rows.map((r) => Post.fromJson(r)).toList();
      AppState.communityPosts = posts;
      if (mounted) setState(() {});
    }).catchError((e) {
      debugPrint('게시글 불러오기 실패: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = AppState.currentUser;
    final posts = AppState.communityPosts;

    if (me == null) {
      return const Center(child: Text('로그인이 필요해요.'));
    }

    // 필터링 로직 (중복 선택 지원)
    List<Post> filteredPosts = posts;
    
    if (_selectedFilters.isNotEmpty) {
      filteredPosts = posts.where((post) {
        final knownUsers = [me, ...AppState.friends];
        User? author;
        try {
          author = knownUsers.firstWhere((u) => u.id == post.authorId);
        } catch (_) {
          return false;
        }

        // 모든 선택된 필터 조건을 AND로 결합
        bool matchesAllFilters = true;
        
        if (_selectedFilters.contains('동창')) {
          matchesAllFilters = matchesAllFilters && (author.school == me.school);
        }
        if (_selectedFilters.contains('동갑')) {
          matchesAllFilters = matchesAllFilters && (author.birthYear == me.birthYear);
        }
        if (_selectedFilters.contains('같은지역')) {
          matchesAllFilters = matchesAllFilters && (author.region == me.region);
        }
        
        return matchesAllFilters;
      }).toList();
    }

    return Stack(
      children: [
        Column(
          children: [
            // 📍 필터 탭
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('동창'),
                    const SizedBox(width: 20),
                    _buildFilterChip('동갑'),
                    const SizedBox(width: 20),
                    _buildFilterChip('같은지역'),
                  ],
                ),
              ),
            ),

            // 게시글 목록
            Expanded(
              child: filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilters.isEmpty
                                ? '아직 커뮤니티에 글이 없어요.\n글쓰기 버튼을 눌러 첫 글을 작성해보세요!'
                                : '해당 필터에 맞는 게시글이 없어요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: filteredPosts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];

                        User? author;
                        final knownUsers = [me, ...AppState.friends];
                        try {
                          author = knownUsers.firstWhere(
                            (u) => u.id == post.authorId,
                          );
                        } catch (_) {
                          author = null;
                        }

                        return ThreadPost(
                          key: ValueKey('post_${post.id}_${post.likesCount}_${post.commentsCount}'),
                          post: post, 
                          author: author,
                          onPostDeleted: _refreshPosts, // 🔥 삭제 시 목록 갱신 콜백
                          onPostUpdated: () {
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
            ),
          ],
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilters.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFilters.remove(label);
          } else {
            _selectedFilters.add(label);
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2.5,
            width: label.length * 15.0,
            decoration: BoxDecoration(
              color: isSelected ? Colors.black87 : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
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
// 🔥 ThreadPost — 프로필/본문/이미지/삭제기능 통합
// ==========================================================
class ThreadPost extends StatefulWidget {
  final Post post;
  final User? author;
  final VoidCallback? onPostDeleted; // 🔥 삭제 콜백
  final VoidCallback? onPostUpdated; // 🔥 업데이트 콜백

  const ThreadPost({
    super.key, 
    required this.post, 
    required this.author,
    this.onPostDeleted,
    this.onPostUpdated,
  });

  @override
  State<ThreadPost> createState() => _ThreadPostState();
}

class _ThreadPostState extends State<ThreadPost> {
  bool get isMyPost => widget.post.authorId == AppState.currentUser?.id;

  ImageProvider _profileProvider(User? u) {
    if (u == null) return const AssetImage("assets/images/logo.png");
    return resolveImage(u.profileImageUrl, u.profileImageBytes);
  }

  // Post 객체의 작성자 정보로 User 객체 생성 (프로필 화면 연동용)
  User _buildAuthorUser() {
    return User(
      id: widget.post.authorId,
      name: widget.post.authorName ?? "알 수 없음",
      birthYear: 0,
      region: widget.post.authorRegion ?? "",
      school: widget.post.authorSchool ?? "",
      profileImageUrl: widget.post.authorProfileImage,
      backgroundImageUrl: null,
      profileFeedImages: [],
    );
  }

  // 🔥 게시글 삭제 함수
  Future<void> _deletePost() async {
    try {
      final success = await ApiService.deletePost(widget.post.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("게시글이 삭제되었습니다.")),
          );
          // 목록 갱신 요청
          widget.onPostDeleted?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("삭제 실패: $e")),
        );
      }
    }
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
              } else {
                // 친구 목록에 없는 경우: Post 정보로 프로필 생성
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendProfileScreen(user: _buildAuthorUser()),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 22,
              backgroundImage: widget.author != null
                  ? _profileProvider(widget.author)
                  : resolveImage(widget.post.authorProfileImage, null),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들바
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Text(
                      "게시물 관리",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, color: Colors.grey.shade200),
              
              // 타인의 글: 신고하기
              if (!isMyPost)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _openReportSheet(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.flag_rounded,
                            color: Colors.red.shade600,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "게시물 신고하기",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "부적절한 콘텐츠 신고",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // 내 글: 삭제하기
              if (isMyPost)
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // BottomSheet 닫기
                    // 삭제 확인 다이얼로그
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("게시글 삭제"),
                        content: const Text("정말 삭제하시겠습니까?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("취소"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx); // 팝업 닫기
                              _deletePost(); // 실제 삭제 요청
                            },
                            child: const Text("삭제", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade600,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "게시물 삭제",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "게시물 복구는 불가능합니다",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _openReportSheet(BuildContext context) {
    final reasons = [
      {"title": "스팸/광고", "icon": Icons.campaign_outlined},
      {"title": "욕설/비방", "icon": Icons.chat_bubble_outline},
      {"title": "혐오 발언", "icon": Icons.warning_amber_rounded},
      {"title": "사칭", "icon": Icons.person_off_outlined},
      {"title": "음란물", "icon": Icons.no_adult_content},
      {"title": "불쾌한 콘텐츠", "icon": Icons.block_outlined},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들바
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "신고 사유 선택",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "해당하는 신고 사유를 선택해주세요",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, color: Colors.grey.shade200),
              
              const SizedBox(height: 8),

              ...reasons.map(
                (item) => InkWell(
                  onTap: () async {
                    Navigator.pop(context);

                    final ok = await ApiService.reportPost(widget.post.id); // 🔥 게시글 신고 API

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? "신고가 접수되었어요." : "신고 실패"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item["icon"] as IconData,
                          color: Colors.grey.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item["title"] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
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
            final wasLiked = widget.post.liked;
            final wasCount = widget.post.likesCount;

            // 1) UI 먼저 업데이트
            setState(() {
              widget.post.liked = !widget.post.liked;
              widget.post.likesCount += widget.post.liked ? 1 : -1;
            });

            try {
              // 2) 서버로 좋아요 처리 요청 (toggle 방식)
              final res = await ApiService.toggleLike(widget.post.id);

              // 3) 서버 값으로 다시 동기화
              setState(() {
                widget.post.liked = res["liked"];
                widget.post.likesCount = res["likes_count"];
              });
              
              // 4) AppState 업데이트
              final postIndex = AppState.communityPosts.indexWhere((p) => p.id == widget.post.id);
              if (postIndex != -1) {
                AppState.communityPosts[postIndex].liked = res["liked"];
                AppState.communityPosts[postIndex].likesCount = res["likes_count"];
              }
              
              // 5) 부모 위젯 갱신
              widget.onPostUpdated?.call();
            } catch (e) {
              // 실패 시 원래 상태로 복구
              setState(() {
                widget.post.liked = wasLiked;
                widget.post.likesCount = wasCount;
              });
            }
          },
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 22,
                color: widget.post.liked ? Colors.orange : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                "${widget.post.likesCount}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.post.liked ? Colors.orange : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 18),

        GestureDetector(
          onTap: () async {
            await Navigator.pushNamed(context, '/comments', arguments: widget.post);
            // 댓글 화면에서 돌아왔을 때 무조건 갱신
            if (mounted) {
              setState(() {});
              widget.onPostUpdated?.call();
            }
          },
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                '${widget.post.commentsCount ?? 0}',
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