// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert'; // 🔵 base64 인코딩 위해 필요
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/screens/profile/edit_profile_screen.dart';
import 'package:intersection/screens/common/image_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intersection/screens/auth/landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickImage({required bool isProfile}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;
    final file = result.files.first;
    final user = AppState.currentUser!;

    setState(() {
      if (kIsWeb) {
        if (isProfile) {
          user.profileImageBytes = file.bytes;
        } else {
          user.backgroundImageBytes = file.bytes;
        }
      } else {
        if (isProfile) {
          user.profileImageUrl = file.path;
        } else {
          user.backgroundImageUrl = file.path;
        }
      }
    });
  }

  // 🔵 프로필 피드용 이미지 선택 함수 추가
  Future<void> _pickFeedImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final file = result.files.first;
    final user = AppState.currentUser!;

    // 웹 처리
    if (kIsWeb) {
      if (file.bytes != null) {
        final base64Str = base64Encode(file.bytes!);
        final dataUrl = "data:image/png;base64,$base64Str";
        user.profileFeedImages.add(dataUrl);
      }
    }
    // 앱 처리
    else {
      if (file.path != null) {
        user.profileFeedImages.add(file.path!);
      }
    }

    setState(() {});
  }

  ImageProvider _provider(String? url, Uint8List? bytes) {
    if (bytes != null) return MemoryImage(bytes);
    if (url != null && url.startsWith("http")) return NetworkImage(url);
    if (url != null && !kIsWeb && File(url).existsSync()) {
      return FileImage(File(url));
    }
    return const AssetImage("assets/images/logo.png");
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.currentUser!;
    final width = MediaQuery.of(context).size.width;

    final bgProvider = _provider(
      user.backgroundImageUrl,
      user.backgroundImageBytes,
    );
    final profileProvider = _provider(
      user.profileImageUrl,
      user.profileImageBytes,
    );

    final hasProfileImage =
        user.profileImageUrl != null || user.profileImageBytes != null;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    if (user.backgroundImageUrl != null ||
                        user.backgroundImageBytes != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewer(
                            imageUrl: user.backgroundImageUrl,
                            bytes: user.backgroundImageBytes,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: user.backgroundImageUrl != null ||
                              user.backgroundImageBytes != null
                          ? DecorationImage(
                              image: bgProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: (user.backgroundImageUrl == null &&
                              user.backgroundImageBytes == null)
                          ? const LinearGradient(
                              colors: [Color(0xFF1a1a1a), Color(0xFF444444)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: ElevatedButton(
                    onPressed: () => _pickImage(isProfile: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black45,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text("배경 변경"),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: (width / 2) - 50,
                  child: GestureDetector(
                    onTap: hasProfileImage
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewer(
                                  imageUrl: user.profileImageUrl,
                                  bytes: user.profileImageBytes,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Hero(
                      tag: "my-profile-${user.id}",
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            hasProfileImage ? profileProvider : null,
                        backgroundColor: Colors.black,
                        child: hasProfileImage
                            ? null
                            : const Icon(Icons.person,
                                size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70),

            TextButton.icon(
              onPressed: () => _pickImage(isProfile: true),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text(
                "프로필 사진 변경",
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              user.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "${user.birthYear}년생 · ${user.school} · ${user.region}",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 30),

            // 🔵 피드 + 사진 추가 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "피드",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),

                  // 🔵 사진 추가 버튼
                  TextButton(
                    onPressed: _pickFeedImage,
                    child: const Text("사진 추가"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 🔵 profileFeedImages로 교체
            if (user.profileFeedImages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "게시물 없음",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: user.profileFeedImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final img = user.profileFeedImages[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewer(imageUrl: img),
                        ),
                      );
                    },
                    child: Hero(
                      tag: img,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image(
                          image: _provider(img, null),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 20),

                  Text("학교: ${user.school}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),

                  Text("지역: ${user.region}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),

                  Text("${user.birthYear}년생",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                      child: const Text("프로필 수정"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showLogoutConfirmDialog(context),
                      child: const Text(
                        "로그아웃",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 로그아웃 확인 다이얼로그
  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '정말 로그아웃 하시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  await AppState.logout();

                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        );
      },
    );
  }
}
