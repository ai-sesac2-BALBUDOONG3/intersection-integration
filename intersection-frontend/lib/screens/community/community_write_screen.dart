import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/services/api_service.dart';

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isPosting = false;

  void _submitPost() {
    final content = _contentController.text.trim();
    final me = AppState.currentUser;

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("내용을 입력해줘.")),
      );
      return;
    }

    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인이 필요해요.")),
      );
      return;
    }

    setState(() => _isPosting = true);

    ApiService.createPost(content).then((data) {
      // convert server response into Post model and add to AppState
      final newPost = Post.fromJson(data);
      AppState.communityPosts.insert(0, newPost);
      setState(() => _isPosting = false);
      Navigator.pop(context, true);
    }).catchError((e) {
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 작성 실패: $e')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("새 글 작성"),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: _isPosting
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Text(
                    "게시",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _contentController,
          minLines: 5,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "무슨 생각을 하고 있나요?",
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
