// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/screens/profile/edit_profile_screen.dart';
import 'package:intersection/screens/common/image_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intersection/screens/auth/landing_screen.dart';
import 'package:intersection/config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================
  // 프로필/배경 이미지 서버에 저장
  // ============================
  Future<void> _saveProfileImages() async {
    final user = AppState.currentUser!;

    try {
      await ApiService.uploadProfileImages(
        profileBytes: user.profileImageBytes,
        backgroundBytes: user.backgroundImageBytes,
        profilePath: user.profileImageUrl,
        backgroundPath: user.backgroundImageUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("프로필 저장 완료")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 실패: $e")),
      );
    }
  }

  // ============================
  // 이미지 선택 (프로필/배경 공통)
  // ============================
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
        // 웹은 bytes로
        if (isProfile) {
          user.profileImageBytes = file.bytes;
        } else {
          user.backgroundImageBytes = file.bytes;
        }
      } else {
        // 앱은 로컬 파일 경로로
        if (isProfile) {
          user.profileImageUrl = file.path;
        } else {
          user.backgroundImageUrl = file.path;
        }
      }
    });

    AppState.updateProfile();
  }

  // ============================
  // 피드용 이미지 선택
  // ============================
  Future<void> _pickFeedImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final file = result.files.first;
    final user = AppState.currentUser!;

    if (kIsWeb) {
      // 웹은 data-url 형식으로 저장
      if (file.bytes != null) {
        final base64Str = base64Encode(file.bytes!);
        final dataUrl = "data:image/png;base64,$base64Str";
        user.profileFeedImages.add(dataUrl);
      }
    } else {
      // 앱은 경로 그대로
      if (file.path != null) {
        user.profileFeedImages.add(file.path!);
      }
    }

    setState(() {});
    AppState.updateProfile();
  }

  // ============================
  // 공통 ImageProvider
  //   - 웹: Network / Memory / Asset
  //   - 앱: File / Network / Memory / Asset
  // ============================
  ImageProvider _provider(String? url, Uint8List? bytes) {
    // 1) 메모리(웹/앱 공통)
    if (bytes != null) return MemoryImage(bytes);

    // 2) url 없으면 기본 이미지
    if (url == null || url.isEmpty) {
      return const AssetImage("assets/images/logo.png");
    }

    // 3) 이미 절대 URL 인 경우
    if (url.startsWith("http")) {
      return NetworkImage(url);
    }

    // 4) /uploads/... 같이 상대 경로인 경우 → 서버 절대 경로로
    if (url.startsWith("/")) {
      final absolute = "${ApiConfig.baseUrl}$url";
      return NetworkImage(absolute);
    }

    // 5) 로컬 파일은 앱에서만
    if (!kIsWeb) {
      final f = File(url);
      if (f.existsSync()) {
        return FileImage(f);
      }
    }

    // 6) 그래도 안 되면 기본 이미지
    return const AssetImage("assets/images/logo.png");
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.currentUser!;
    final width = MediaQuery.of(context).size.width;

    final bgProvider =
        _provider(user.backgroundImageUrl, user.backgroundImageBytes);
    final profileProvider =
        _provider(user.profileImageUrl, user.profileImageBytes);

    final hasProfileImage =
        user.profileImageUrl != null || user.profileImageBytes != null;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // =======================
            // 헤더 + 배경 이미지
            // =======================
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
                      image: (user.backgroundImageUrl != null ||
                              user.backgroundImageBytes != null)
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

                // 배경 변경 버튼
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

                // 프로필 사진
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
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70),

            // 프로필 사진 변경
            TextButton.icon(
              onPressed: () => _pickImage(isProfile: true),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text("프로필 사진 변경"),
            ),

            const SizedBox(height: 20),

            // 이름/정보
            Text(
              user.name,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "${user.birthYear}년생 · ${user.school} · ${user.region}",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 30),

            // 피드 헤더
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
                  TextButton(
                    onPressed: _pickFeedImage,
                    child: const Text("사진 추가"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 피드 영역
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
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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

            // 정보 + 버튼들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 20),
                  Text(
                    "학교: ${user.school}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "지역: ${user.region}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${user.birthYear}년생",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saveProfileImages,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "저장",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 프로필 수정
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

                  // 로그아웃
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _showLogoutConfirmDialog(context),
                      child: const Text(
                        "로그아웃",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(24, 30, 24, 20),
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
                onPressed: () =>
                    Navigator.of(dialogContext).pop(),
                child: const Text("취소"),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await AppState.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LandingScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text("로그아웃"),
              ),
            ),
          ],
        );
      },
    );
  }
}
