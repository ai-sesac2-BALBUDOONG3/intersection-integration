import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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

  // 웹/앱 모두 지원
  Uint8List? selectedBytes;
  File? selectedFile;
  String? previewName;

  // -------------------------------------------------------
  // 🔥 이미지 선택 (웹/앱 완전 분리)
  // -------------------------------------------------------
  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          selectedBytes = result.files.first.bytes!;
          previewName = result.files.first.name;
        });
      }

    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          selectedFile = File(picked.path);
          previewName = picked.name;
        });
      }
    }
  }

  // -------------------------------------------------------
  // 🔥 게시물 업로드
  // -------------------------------------------------------
  Future<void> _submitPost() async {
    final content = _contentController.text.trim();

    // 최소한 글 또는 이미지 둘 중 하나 필요
    if (content.isEmpty && selectedBytes == null && selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("내용 또는 이미지를 입력해줘.")),
      );
      return;
    }

    if (AppState.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인이 필요해요.")),
      );
      return;
    }

    setState(() => _isPosting = true);

    String? uploadedUrl;

    // -------------------------------------------------------
    // 1) 이미지 업로드
    // -------------------------------------------------------
    try {
      if (!kIsWeb && selectedFile != null) {
        // 앱: File upload
        final resp = await ApiService.uploadFile(selectedFile!);
        uploadedUrl = resp["file_url"];
      } else if (kIsWeb && selectedBytes != null) {
        // 웹: Bytes upload
        final resp = await ApiService.uploadBytes(
          selectedBytes!,
          previewName ?? "image.png",
        );
        uploadedUrl = resp["file_url"];
      }
    } catch (e) {
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("이미지 업로드 실패: $e")));
      return;
    }

    // -------------------------------------------------------
    // 2) 게시물 생성 요청 (image_url 하나만)
    // -------------------------------------------------------
    try {
      final response = await ApiService.createPostWithMedia(
        content: content,
        mediaUrls: uploadedUrl != null ? [uploadedUrl] : [],
      );

      final newPost = Post.fromJson(response);
      AppState.communityPosts.insert(0, newPost);

      setState(() => _isPosting = false);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("게시글 작성 실패: $e")));
    }
  }

  // -------------------------------------------------------
  // 🔥 UI
  // -------------------------------------------------------
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

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          //-----------------------------------------------------
          // ✏ 글 입력
          //-----------------------------------------------------
          TextField(
            controller: _contentController,
            minLines: 5,
            maxLines: null,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "무슨 생각을 하고 있나요?",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          //-----------------------------------------------------
          // 📷 이미지 미리보기
          //-----------------------------------------------------
          if (selectedBytes != null || selectedFile != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: kIsWeb
                  ? Image.memory(
                      selectedBytes!,
                      height: 180,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      selectedFile!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
            ),

          const SizedBox(height: 12),

          //-----------------------------------------------------
          // 📸 이미지 추가 버튼
          //-----------------------------------------------------
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo),
            label: const Text("이미지 첨부하기"),
          ),
        ],
      ),
    );
  }
}
