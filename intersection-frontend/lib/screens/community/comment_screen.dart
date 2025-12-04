import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/models/comment.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/config/api_config.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/screens/common/report_screen.dart'; // ReportScreen 사용

// =============================================================
// 🔥 시간 포맷 함수 (임시 구현)
// =============================================================
String formatDuration(DateTime? date) {
  if (date == null) return '';
  final duration = DateTime.now().difference(date);
  if (duration.inMinutes < 1) return '방금 전';
  if (duration.inHours < 1) return '${duration.inMinutes}분 전';
  if (duration.inDays < 1) return '${duration.inHours}시간 전';
  if (duration.inDays < 7) return '${duration.inDays}일 전';
  return '${date.month}/${date.day}';
}

/// =============================================================
/// 🔥 인스타그램 스타일 댓글 BottomSheet (Future로 변경됨)
/// =============================================================
Future<void> openCommentSheet(BuildContext context, Post post) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CommentScreen(
            post: post,
            scrollController: controller,
          ),
        );
      },
    ),
  );
}

/// =============================================================
/// 🔥 CommentScreen – BottomSheet 내부
/// =============================================================
class CommentScreen extends StatefulWidget {
  final Post post;
  final ScrollController? scrollController;

  const CommentScreen({
    super.key,
    required this.post,
    this.scrollController,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Comment> comments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final rows = await ApiService.listComments(widget.post.id);

      if (mounted) {
        setState(() {
          comments = rows.map((json) => Comment.fromJson(json)).toList();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
      print("댓글 로드 실패: $e");
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final resp = await ApiService.createComment(widget.post.id, text);
      final newComment = Comment.fromJson(resp);

      setState(() {
        comments.add(newComment);
      });

      _controller.clear();
      FocusScope.of(context).unfocus();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("댓글 작성 실패: $e")),
      );
    }
  }

  // 🔥 댓글 좋아요 토글
  Future<void> _toggleLike(Comment c) async {
    final wasLiked = c.liked;
    final originalCount = c.likesCount;

    setState(() {
      c.liked = !wasLiked;
      c.likesCount += c.liked ? 1 : -1;
    });

    try {
      final result = await ApiService.toggleCommentLike(c.id);
      
      setState(() {
        c.liked = result['is_liked'];
        c.likesCount = result['like_count'];
      });
    } catch (e) {
      setState(() {
        c.liked = wasLiked;
        c.likesCount = originalCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("좋아요 오류: $e")),
      );
    }
  }

  // 🔥 댓글 삭제
  Future<void> _deleteComment(Comment c) async {
    try {
      final success = await ApiService.deleteComment(c.postId, c.id); 
      if (success) {
        if (mounted) {
          setState(() {
            comments.remove(c);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("댓글이 삭제되었습니다.")),
          );
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
    return Column(
      children: [
        // 드래그 핸들
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.only(top: 10, bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: const [
              Text(
                "댓글",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
            ],
          ),
        ),

        // 원본 게시물 텍스트 (간략히)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            widget.post.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ),

        // 댓글 리스트
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : comments.isEmpty
                  ? const Center(
                      child: Text(
                        "아직 댓글이 없어요.\n첫 댓글을 남겨보세요!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return CommentItem(
                          comment: c,
                          onToggleLike: () => _toggleLike(c),
                          onDelete: () => _deleteComment(c),
                        );
                      },
                    ),
        ),

        // 입력창
        _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 30), 
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "댓글을 입력하세요",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.black87,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
              onPressed: _sendComment,
            ),
          ),
        ],
      ),
    );
  }
}

/// =============================================================
/// 🔥 프로필 이미지 Provider
/// =============================================================
ImageProvider commentProfileProvider(String? url) {
  if (url != null && url.isNotEmpty) {
    if (url.startsWith("http")) return NetworkImage(url);
    if (url.startsWith("/")) return NetworkImage("${ApiConfig.baseUrl}$url");
  }
  return const AssetImage("assets/images/default_profile.png");
}

/// =============================================================
/// 🔥 단일 댓글 UI (CommentItem)
/// =============================================================
class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback onToggleLike;
  final VoidCallback onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onToggleLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMyComment = comment.userId == AppState.currentUser?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: commentProfileProvider(comment.authorProfileImage),
          ),
          const SizedBox(width: 12),

          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      // 🔥 작성자 이름 표시 (실명)
                      comment.authorName ?? "익명",


                      // comment.authorName ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      // 🔥 [수정 완료] 시간 표시 (timeAgo 대신 임시 함수 사용)
                      formatDuration(comment.createdAt), 
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14, height: 1.35),
                ),
                const SizedBox(height: 6),
                
                // 답글달기 / 신고 / 삭제 버튼 영역
                Row(
                  children: [
                    Text(
                      "답글달기",
                      style: TextStyle(
                        color: Colors.grey.shade500, 
                        fontSize: 12, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    if (isMyComment)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("댓글 삭제"),
                              content: const Text("정말 삭제하시겠습니까?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("취소"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    onDelete();
                                  },
                                  child: const Text("삭제", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          "삭제",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          // 🔥 [수정 완료] ReportScreen 호출 (Post 인자가 아닌 targetId/Type 사용)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(
                                // ReportScreen의 생성자가 targetId와 targetType을 받는다고 가정합니다.
                                targetId: comment.id,
                                targetType: ReportTargetType.comment,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "신고",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 좋아요 하트 + 개수
          GestureDetector(
            onTap: onToggleLike,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Column(
                children: [
                  Icon(
                    comment.liked ? Icons.favorite : Icons.favorite_border,
                    color: comment.liked ? Colors.red : Colors.grey,
                    size: 18,
                  ),
                  if (comment.likesCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      "${comment.likesCount}",
                      style: TextStyle(
                        fontSize: 11,
                        color: comment.liked ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}