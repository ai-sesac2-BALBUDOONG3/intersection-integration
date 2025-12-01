import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/models/comment.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/config/api_config.dart';

class CommentScreen extends StatefulWidget {
  final Post post;

  const CommentScreen({super.key, required this.post});

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

      setState(() {
        comments = rows.map((json) => Comment.fromJson(json)).toList();
        loading = false;
      });
    } catch (e) {
      loading = false;
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 작성 실패: $e')),
      );
    }
  }

  void _toggleLike(Comment c) async {
    final old = c.liked;

    if (old) {
      c.liked = false;
      c.likesCount -= 1;
      setState(() {});
      await ApiService.unlikeComment(c.id);
    } else {
      c.liked = true;
      c.likesCount += 1;
      setState(() {});
      await ApiService.likeComment(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("댓글")),

      body: Column(
        children: [
          // ==============================
          // 🔥 원본 게시글
          // ==============================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              widget.post.content,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),

          // ==============================
          // 🔥 댓글 목록
          // ==============================
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return CommentItem(
                            comment: c,
                            onToggleLike: () => _toggleLike(c),
                          );
                        },
                      ),
          ),

          // ==============================
          // 🔥 입력창
          // ==============================
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black87),
            onPressed: _sendComment,
          ),
        ],
      ),
    );
  }
}

/// ===================================================================
/// 🔥 댓글 프로필 이미지 Provider
/// ===================================================================
ImageProvider commentProfileProvider(String? url, Uint8List? bytes) {
  if (bytes != null) return MemoryImage(bytes);

  if (url != null && url.isNotEmpty) {
    if (url.startsWith("http")) return NetworkImage(url);
    if (url.startsWith("/")) return NetworkImage("${ApiConfig.baseUrl}$url");
  }

  return const AssetImage("assets/images/logo.png");
}

/// ===================================================================
/// 🔥 개별 댓글 UI
/// ===================================================================
class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback onToggleLike;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------
          // 🔥 프로필 이미지
          // ------------------------------------
          CircleAvatar(
            radius: 18,
            backgroundImage: commentProfileProvider(
              comment.authorProfileImage,
              comment.authorProfileBytes,
            ),
          ),

          const SizedBox(width: 12),

          // ------------------------------------
          // 🔥 텍스트 영역
          // ------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName ?? "익명",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.createdAt.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------
          // 🔥 좋아요 버튼
          // ------------------------------------
          GestureDetector(
            onTap: onToggleLike,
            child: Column(
              children: [
                Icon(
                  comment.liked ? Icons.favorite : Icons.favorite_border,
                  color: comment.liked ? Colors.red : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  comment.likesCount.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: comment.liked ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------
          // 🔥 메뉴 버튼
          // ------------------------------------
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
