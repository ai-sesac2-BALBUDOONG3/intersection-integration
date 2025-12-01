// lib/screens/common/image_viewer.dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intersection/config/api_config.dart';

class ImageViewer extends StatelessWidget {
  final String? imageUrl;      // URL or local path or /uploads/...
  final Uint8List? bytes;      // Web-only or memory

  const ImageViewer({
    super.key,
    this.imageUrl,
    this.bytes,
  });

  ImageProvider _provider() {
    // 1) 메모리 이미지 우선
    if (bytes != null) return MemoryImage(bytes!);

    // 2) URL이 없으면 기본값
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const AssetImage("assets/images/logo.png");
    }

    final url = imageUrl!;

    // 3) 이미 절대 URL이면 그대로
    if (url.startsWith("http")) {
      return NetworkImage(url);
    }

    // 4) /uploads/... → 서버 절대 경로로 변환
    if (url.startsWith("/")) {
      final absolute = "${ApiConfig.baseUrl}$url";
      return NetworkImage(absolute);
    }

    // 5) 앱 환경에서는 로컬 파일도 가능
    if (!kIsWeb) {
      final file = File(url);
      if (file.existsSync()) return FileImage(file);
    }

    // 6) 그래도 안 되면 기본 이미지
    return const AssetImage("assets/images/logo.png");
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image(
            image: provider,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
