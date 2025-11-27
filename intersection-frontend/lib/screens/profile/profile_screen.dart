import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/screens/profile/edit_profile_screen.dart';
import 'package:intersection/screens/common/image_viewer.dart';
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
                          builder: (_) => ImageViewer(imageUrl: user.backgroundImageUrl!),
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

                // ==========================
                // 프로필 이미지 중앙
                // ==========================
                Positioned(
                  bottom: -50,
                  left: (width / 2) - 50,
                  child: GestureDetector(
                    onTap: () {
                      if (user.profileImageUrl != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageViewer(imageUrl: user.profileImageUrl!),
                          ),
                        );
                      }
                    },
                    child: Hero(
                      tag: "my-profile-${user.id}",
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: user.profileImageUrl != null
                            ? (user.profileImageUrl!.startsWith("http")
                                ? NetworkImage(user.profileImageUrl!)
                                : FileImage(File(user.profileImageUrl!)) as ImageProvider)
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

            // ==========================
            // 3) 이름 + 설명
            // ==========================
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

            // ==========================
            // 4) 친구 피드 (인스타 그리드)
            // ==========================
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

            // ==========================
            // 5) 상세 정보
            // ==========================
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
                  Text("${user.birthYear}년생", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================
  // 로컬 이미지/네트워크 자동 구분 로더
  // ==========================
  ImageProvider _imageProvider(String path) {
    if (path.startsWith("http")) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }
}
