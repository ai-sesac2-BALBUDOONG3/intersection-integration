// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/screens/profile/edit_profile_screen.dart';
import 'package:intersection/screens/common/image_viewer.dart';
import 'package:intersection/screens/auth/landing_screen.dart';
import 'package:file_picker/file_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ==============================
  // 이미지 선택 (프로필/배경)
  // ==============================
  Future<void> _pickImage({required bool isProfile}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;
    final file = result.files.first;

    setState(() {
      if (isProfile) {
        AppState.currentUser!.profileImageUrl = file.path;
      } else {
        AppState.currentUser!.backgroundImageUrl = file.path;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.currentUser!;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("내 프로필"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // =======================================
            // 🔥 배경 + 프로필 이미지 섹션
            // =======================================
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    if (user.backgroundImageUrl != null &&
                        user.backgroundImageUrl!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ImageViewer(imageUrl: user.backgroundImageUrl!),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: user.backgroundImageUrl != null
                          ? DecorationImage(
                              image: _imageProvider(user.backgroundImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: user.backgroundImageUrl == null
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
                      backgroundColor: Colors.black54,
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
                    onTap: () {
                      if (user.profileImageUrl != null &&
                          user.profileImageUrl!.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ImageViewer(imageUrl: user.profileImageUrl!),
                          ),
                        );
                      }
                    },
                    child: Hero(
                      tag: "my-profile-${user.id}",
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: user.profileImageUrl != null
                            ? _imageProvider(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70),

            // =======================================
            // 🔥 기본 정보
            // =======================================
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

            // =======================================
            // 🔥 피드 이미지 그리드
            // =======================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "최근 활동",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: user.feedImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final img = user.feedImages[index];

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
                        image: _imageProvider(img),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // =======================================
            // 🔥 상세 정보 + 프로필 수정 + 로그아웃
            // =======================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(thickness: 0.6),
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

                  // 프로필 수정 버튼
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

                  // ===============================
                  // 🔥 로그아웃 버튼
                  // ===============================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await AppState.logout();

                        if (!mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LandingScreen(),
                          ),
                          (route) => false,
                        );
                      },
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
            )
          ],
        ),
      ),
    );
  }

  // =======================================
  // 이미지 로더
  // =======================================
  ImageProvider _imageProvider(String path) {
    if (path.startsWith("http")) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }
}
