import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/image_viewer.dart';

class FriendProfileScreen extends StatelessWidget {
  final User user;

  const FriendProfileScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================
            // 1) 배경 이미지
            // ==========================
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

                // ==========================
                // 2) 프로필 이미지 중앙
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
                            builder: (_) =>
                                ImageViewer(imageUrl: user.profileImageUrl!),
                          ),
                        );
                      }
                    },
                    child: Hero(
                      tag: "friend-profile-${user.id}",
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
                  Text("${user.birthYear}년생",
                      style: const TextStyle(fontSize: 16)),
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
