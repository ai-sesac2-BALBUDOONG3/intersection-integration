import 'package:flutter/material.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/data/app_state.dart';

class CommentScreen extends StatefulWidget {
  final Post post;

  const CommentScreen({super.key, required this.post});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _controller = TextEditingController();

  /// 실제 댓글 데이터가 들어오면 여기에 맵핑
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    // load comments from server
    ApiService.listComments(widget.post.id).then((rows) {
      setState(() {
        comments = rows.map((r) {
          final userId = r['user_id'];
          String name = '익명';
          try {
            if (AppState.currentUser != null && AppState.currentUser!.id == userId) name = AppState.currentUser!.name ?? '나';
            else {
              final u = AppState.friends.firstWhere((f) => f.id == userId, orElse: () => AppState.friends.isNotEmpty ? AppState.friends.first : AppState.currentUser!);
              name = u.name ?? '익명';
            }
          } catch (_) {}

          return {
            'name': name,
            'content': r['content'] ?? '',
            'date': r['created_at'] ?? '',
          };
        }).toList();
      });
    }).catchError((_) {
      // ignore errors for now
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("댓글"),
      ),

      body: Column(
        children: [
          // ============================
          // 상단: 원본 게시물 보여주는 부분
          // ============================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ============================
          // 리스트 영역
          // ============================
          Expanded(
            child: comments.isEmpty
                ? const Center(
                    child: Text(
                      "아직 댓글이 없어요.\n첫 댓글을 남겨보세요!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return _CommentItem(
                        name: c["name"],
                        content: c["content"],
                        date: c["date"],
                      );
                    },
                  ),
          ),

          // ============================
          // 댓글 입력창
          // ============================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
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
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.send, color: Colors.black87),
                    onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;

                    try {
                      final resp = await ApiService.createComment(widget.post.id, text);
                      // optimistic UI: append comment
                      setState(() {
                        comments.add({
                          'name': AppState.currentUser?.name ?? '나',
                          'content': resp['content'] ?? text,
                          'date': resp['created_at'] ?? '방금 전',
                        });
                      });
                      _controller.clear();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 작성 실패: $e')));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 개별 댓글 UI 컴포넌트
class _CommentItem extends StatelessWidget {
  final String name;
  final String content;
  final String date;

  const _CommentItem({
    required this.name,
    required this.content,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필
          const CircleAvatar(
            radius: 16,
            child: Icon(Icons.person, size: 18),
          ),
          const SizedBox(width: 12),

          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // 옵션 버튼
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.report),
                        title: const Text("댓글 신고"),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.close),
                        title: const Text("닫기"),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
