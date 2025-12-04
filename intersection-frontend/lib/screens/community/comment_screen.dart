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
  final VoidCallback? onCommentChanged; // 댓글 변경 시 호출

  const CommentScreen({
    super.key,
    required this.post,
    this.scrollController,
    this.onCommentChanged,
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
    setState(() => loading = true);
    try {
      final rows = await ApiService.listComments(widget.post.id);

      if (mounted) {
        setState(() {
          // 기존 댓글 ID를 맵으로 저장 (로컬 좋아요 상태 보존)
          final existingMap = {for (var c in comments) c.id: c};
          
          comments = rows.map((json) {
            final newComment = Comment.fromJson(json);
            final existing = existingMap[newComment.id];
            
            // 기존 댓글이 있고 로컬에서 좋아요를 눌렀던 상태라면 그대로 유지
            if (existing != null) {
              return newComment.copyWith(
                liked: existing.liked,
                likesCount: existing.likesCount,
              );
            }
            return newComment;
          }).toList();
          
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
        widget.post.commentsCount++; // 댓글 수 증가
      });
      
      // AppState의 게시글 목록도 업데이트
      final postIndex = AppState.communityPosts.indexWhere((p) => p.id == widget.post.id);
      if (postIndex != -1) {
        AppState.communityPosts[postIndex].commentsCount = widget.post.commentsCount;
      }
      
      // 부모 위젯 갱신
      widget.onCommentChanged?.call();

      _controller.clear();
      FocusScope.of(context).unfocus();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("댓글 작성 실패: $e")),
      );
    }
  }

  // 🔥 댓글 좋아요 토글 - 불변성 보장
  Future<void> _toggleLike(Comment c) async {
    final index = comments.indexWhere((comment) => comment.id == c.id);
    if (index == -1) return;

    // 낙관적 업데이트 (즉시 UI 반영)
    final optimisticLiked = !c.liked;
    final optimisticCount = c.likesCount + (optimisticLiked ? 1 : -1);
    
    setState(() {
      comments = [
        ...comments.sublist(0, index),
        c.copyWith(liked: optimisticLiked, likesCount: optimisticCount),
        ...comments.sublist(index + 1),
      ];
    });

    try {
      // 서버에 요청
      final result = await ApiService.toggleCommentLike(c.id);
      
      // 서버 응답으로 최종 확정
      if (mounted) {
        final serverLiked = result['is_liked'] as bool;
        final serverCount = result['like_count'] as int;
        
        setState(() {
          final currentIndex = comments.indexWhere((comment) => comment.id == c.id);
          if (currentIndex != -1) {
            comments = [
              ...comments.sublist(0, currentIndex),
              comments[currentIndex].copyWith(liked: serverLiked, likesCount: serverCount),
              ...comments.sublist(currentIndex + 1),
            ];
          }
        });
      }
    } catch (e) {
      // 오류 발생 시 롤백
      if (mounted) {
        setState(() {
          final rollbackIndex = comments.indexWhere((comment) => comment.id == c.id);
          if (rollbackIndex != -1) {
            comments = [
              ...comments.sublist(0, rollbackIndex),
              c, // 원래 상태로 복원
              ...comments.sublist(rollbackIndex + 1),
            ];
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("좋아요 오류: $e")),
        );
      }
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
            widget.post.commentsCount--; // 댓글 수 감소
          });
          
          // AppState의 게시글 목록도 업데이트
          final postIndex = AppState.communityPosts.indexWhere((p) => p.id == c.postId);
          if (postIndex != -1) {
            AppState.communityPosts[postIndex].commentsCount = widget.post.commentsCount;
          }
          
          // 부모 위젯 갱신
          widget.onCommentChanged?.call();
          
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

  // 🔥 댓글 수정
  Future<void> _editComment(Comment c, String newContent) async {
    final index = comments.indexWhere((comment) => comment.id == c.id);
    if (index == -1) return;

    try {
      final result = await ApiService.updateComment(c.postId, c.id, newContent);
      
      if (mounted) {
        setState(() {
          comments[index] = Comment(
            id: c.id,
            postId: c.postId,
            userId: c.userId,
            content: newContent,
            createdAt: c.createdAt,
            authorName: c.authorName,
            authorProfileImage: c.authorProfileImage,
            authorProfileBytes: c.authorProfileBytes,
            likesCount: result['like_count'] ?? c.likesCount,
            liked: result['is_liked'] ?? c.liked,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("댓글이 수정되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("수정 실패: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 화면을 닫을 때 업데이트된 댓글 수를 반환
        Navigator.of(context).pop(widget.post.commentsCount);
        return false;
      },
      child: Column(
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
                          onEdit: (newContent) => _editComment(c, newContent),
                        );
                      },
                    ),
        ),

        // 입력창
        _buildInputBar(),
      ],
      ),
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
class CommentItem extends StatefulWidget {
  final Comment comment;
  final VoidCallback onToggleLike;
  final VoidCallback onDelete;
  final Function(String) onEdit;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onToggleLike,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      isEditing = true;
      _editController.text = widget.comment.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      isEditing = false;
      _editController.text = widget.comment.content;
    });
  }

  void _saveEdit() {
    final newContent = _editController.text.trim();
    if (newContent.isNotEmpty && newContent != widget.comment.content) {
      widget.onEdit(newContent);
    }
    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMyComment = widget.comment.userId == AppState.currentUser?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: commentProfileProvider(widget.comment.authorProfileImage),
            ),
          ),
          const SizedBox(width: 12),

          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자명과 시간
                Row(
                  children: [
                    Text(
                      widget.comment.authorName ?? "익명",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        formatDuration(widget.comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 댓글 내용 또는 수정 필드
                if (isEditing)
                  TextField(
                    controller: _editController,
                    maxLines: null,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  )
                else
                  Text(
                    widget.comment.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 12),
                
                // 액션 버튼 영역
                Row(
                  children: [
                    // 좋아요 버튼
                    GestureDetector(
                      onTap: isEditing ? null : widget.onToggleLike,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.comment.liked ? Colors.red.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.comment.liked ? Icons.favorite : Icons.favorite_border,
                              color: widget.comment.liked ? Colors.red : Colors.grey.shade600,
                              size: 16,
                            ),
                            if (widget.comment.likesCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                "${widget.comment.likesCount}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: widget.comment.liked ? Colors.red : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // 수정 모드일 때: 저장/취소 버튼
                    if (isEditing) ...[
                      _buildActionButton(
                        context,
                        "저장",
                        Icons.check,
                        Colors.blue,
                        _saveEdit,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        context,
                        "취소",
                        Icons.close,
                        Colors.grey,
                        _cancelEdit,
                      ),
                    ]
                    // 일반 모드일 때: 수정/삭제/신고 버튼
                    else if (isMyComment) ...[
                      _buildActionButton(
                        context,
                        "수정",
                        Icons.edit_outlined,
                        Colors.blue,
                        _startEdit,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        context,
                        "삭제",
                        Icons.delete_outline,
                        Colors.red,
                        () {
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
                                    widget.onDelete();
                                  },
                                  child: const Text("삭제", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ] else
                      _buildActionButton(
                        context,
                        "신고",
                        Icons.report_outlined,
                        Colors.orange,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(
                                targetId: widget.comment.id,
                                targetType: ReportTargetType.comment,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}