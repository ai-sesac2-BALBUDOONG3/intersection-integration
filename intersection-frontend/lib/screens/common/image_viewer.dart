// lib/screens/common/image_viewer.dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageViewer extends StatelessWidget {
  final String? imageUrl;      // URL or local path
  final Uint8List? bytes;      // Web / bytes mode

  const ImageViewer({
    super.key,
    this.imageUrl,
    this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider provider;

    if (bytes != null) {
      provider = MemoryImage(bytes!);
    } else if (imageUrl != null) {
      if (imageUrl!.startsWith("http")) {
        provider = NetworkImage(imageUrl!);
      } else if (!kIsWeb && File(imageUrl!).existsSync()) {
        provider = FileImage(File(imageUrl!));
      } else {
        provider = const AssetImage("assets/default_profile.png");
      }
    } else {
      provider = const AssetImage("assets/default_profile.png");
    }

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
