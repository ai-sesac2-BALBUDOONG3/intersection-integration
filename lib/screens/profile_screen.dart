import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/screens/edit_profile_screen.dart';
import 'package:intersection/screens/image_viewer.dart';
import 'package:file_picker/file_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    final file = result.files.first;
    setState(() {
      AppState.currentUser!.backgroundImageUrl = file.path;
    });
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    final file = result.files.first;
    setState(() {
      AppState.currentUser!.profileImageUrl = file.path;
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
            // =====================================================
            // 🔥 1) 상단 - 배경 이미지 + 프로필 이미지 (새 기능)
            // =====================================================
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    if (user.backgroundImageUrl != null) {
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
                              image: user.backgroundImageUrl!.startsWith("http")
                                  ? NetworkImage(user.backgroundImageUrl!)
                                  : FileImage(
                                      File(user.backgroundImageUrl!),
                                    ) as ImageProvider,
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
                    onPressed: _pickBackgroundImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black45,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("배경 변경"),
                  ),
                ),

                // 프로필 사진
                Positioned(
                  bottom: -50,
                  left: width / 2 - 50,
                  child: GestureDetector(
                    onTap: () {
                      if (user.profileImageUrl != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ImageViewer(imageUrl: user.profileImageUrl!),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: user.profileImageUrl != null
                          ? (user.profileImageUrl!.startsWith("http")
                              ? NetworkImage(user.profileImageUrl!)
                              : FileImage(File(user.profileImageUrl!))
                                  as ImageProvider)
                          : null,
                      child: user.profileImageUrl == null
                          ? const Icon(Icons.person, size: 48)
                          : null,
                    ),
                  ),
                ),

                // 프로필 변경
                Positioned(
                  bottom: -60,
                  right: width / 2 - 50,
                  child: IconButton(
                    onPressed: _pickProfileImage,
                    icon: const Icon(Icons.camera_alt),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70),

            // =====================================================
            // 🔥 2) 이름/기본정보 (기존 유지 but 위로 올림)
            // =====================================================
            Text(
              user.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Text(
              "${user.birthYear}년생 · ${user.school} · ${user.region}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 32),

            // =====================================================
            // 🔥 3) 내 피드 (grid) - 새 기능
            // =====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "내 피드",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),

            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: user.feedImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemBuilder: (context, index) {
                final img = user.feedImages[index];

                final imageWidget = img.startsWith("http")
                    ? Image.network(img, fit: BoxFit.cover)
                    : Image.file(File(img), fit: BoxFit.cover);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewer(imageUrl: img),
                      ),
                    );
                  },
                  child: Hero(tag: img, child: imageWidget),
                );
              },
            ),

            const SizedBox(height: 40),

            // =====================================================
            // 🔥 4) 기존 “내 정보” UI 완전 유지 (그대로)
            // =====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(thickness: 0.7),
                  const SizedBox(height: 20),

                  Text("학교: ${user.school}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),

                  Text("지역: ${user.region}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),

                  Text("출생연도: ${user.birthYear}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),

                  // 프로필 수정 버튼 (기존 그대로)
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
                      child: const Text(
                        "프로필 수정",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 로그아웃 (기존 그대로)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await AppState.logout();
                        Navigator.pop(context);
                      },
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
}
