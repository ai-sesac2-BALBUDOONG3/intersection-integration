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
  // 피드용 이미지 선택 및 업로드 - 수정완료
  // ============================
  Future<void> _pickFeedImage() async {
    // 1. 파일 선택
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;
    final file = result.files.first;
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("사진을 업로드 중입니다...")),
    );

    try {
      Map<String, dynamic> response;

      // 2. 서버로 전송 (게시글 생성)
      if (kIsWeb) {
        response = await ApiService.createPostWithMedia(
          content: "프로필 피드 사진",
          imageBytes: file.bytes,
          fileName: file.name,
        );
      } else {
        response = await ApiService.createPostWithMedia(
          content: "프로필 피드 사진",
          imageFile: File(file.path!),
        );
      }

      // 3. [핵심] 서버가 돌려준 "진짜 이미지 주소"를 내 목록에 즉시 추가
      // (이렇게 해야 새로고침 없이 바로 보입니다)
      if (response['image_url'] != null) {
        final newImageUrl = response['image_url'];
        final user = AppState.currentUser!;
        
        // 리스트 맨 앞에 추가 (최신순)
        user.profileFeedImages.insert(0, newImageUrl);
        
        setState(() {}); // 화면 갱신
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("피드에 사진이 추가되었습니다!")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("업로드 실패: $e")),
      );
    }
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

  // ============================
  // 학교 종류에 따른 아이콘 반환
  // ============================
  IconData _getSchoolIcon(String schoolType) {
    switch (schoolType) {
      case '초등학교':
        return Icons.child_care_rounded;
      case '중학교':
        return Icons.school_rounded;
      case '고등학교':
        return Icons.menu_book_rounded;
      case '대학교':
      case '대학원':
        return Icons.account_balance_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  // ============================
  // 학교 종류 라벨 반환
  // ============================
  String _getSchoolTypeLabel(String schoolType) {
    switch (schoolType) {
      case '초등학교':
        return '초등';
      case '중학교':
        return '중등';
      case '고등학교':
        return '고등';
      case '대학교':
        return '대학';
      case '대학원':
        return '대학원';
      default:
        return '학교';
    }
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
                  
                  // 학교 정보 - 세련된 카드 형태
                  if (user.schools != null && user.schools!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.school_rounded, size: 20, color: Color(0xFF4A90E2)),
                            SizedBox(width: 8),
                            Text(
                              "학력",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...user.schools!.map((school) {
                          final schoolName = school['name'] ?? school['school_name'] ?? '';
                          final schoolType = school['school_type'] ?? '';
                          final admissionYear = school['admission_year'];
                          
                          // 학교 타입에 따른 색상
                          Color getSchoolColor() {
                            switch (schoolType) {
                              case '초등학교':
                                return Colors.orange;
                              case '중학교':
                                return Colors.blue;
                              case '고등학교':
                                return Colors.purple;
                              default:
                                return const Color(0xFF4A90E2);
                            }
                          }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  getSchoolColor().withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: getSchoolColor().withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: getSchoolColor().withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: getSchoolColor().withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  topRight: Radius.circular(14),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: getSchoolColor().withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getSchoolIcon(schoolType),
                                      size: 24,
                                      color: getSchoolColor(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          schoolName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: getSchoolColor(),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$schoolType${admissionYear != null ? ' · $admissionYear년 입학' : ''}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: getSchoolColor(),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getSchoolTypeLabel(schoolType),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 10),
                      ],
                    )
                  else if (user.school.isNotEmpty)
                    // 하위 호환성: 기존 단일 학교 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.school_rounded, size: 20, color: Color(0xFF4A90E2)),
                            SizedBox(width: 8),
                            Text(
                              "학교",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4A90E2).withOpacity(0.08),
                                const Color(0xFF4A90E2).withOpacity(0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4A90E2).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A90E2).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getSchoolIcon(user.schoolType ?? ''),
                                  size: 20,
                                  color: const Color(0xFF4A90E2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user.school,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  
                  // 지역 정보 - 세련된 디자인
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFE74C3C)),
                      const SizedBox(width: 8),
                      const Text(
                        "지역",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE74C3C).withOpacity(0.08),
                          const Color(0xFFE74C3C).withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE74C3C).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.place_rounded,
                            size: 20,
                            color: Color(0xFFE74C3C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          user.region,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 출생년도 - 세련된 디자인
                  Row(
                    children: [
                      const Icon(Icons.cake_rounded, size: 20, color: Color(0xFF9B59B6)),
                      const SizedBox(width: 8),
                      const Text(
                        "출생년도",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF9B59B6).withOpacity(0.08),
                          const Color(0xFF9B59B6).withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9B59B6).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B59B6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Color(0xFF9B59B6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${user.birthYear}년생",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saveProfileImages,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.black87),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                        elevation: MaterialStateProperty.all(6),
                        shadowColor:
                            MaterialStateProperty.all(Colors.black54),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 14)),
                        textStyle: MaterialStateProperty.all(
                          const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      child: const Text("저장"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 프로필 수정
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                        // 프로필 수정 후 돌아왔을 때 화면 갱신
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.black87),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                        elevation: MaterialStateProperty.all(6),
                        shadowColor:
                            MaterialStateProperty.all(Colors.black54),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 14)),
                        textStyle: MaterialStateProperty.all(
                          const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      child: const Text("프로필 수정"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 로그아웃
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.redAccent),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                        elevation: MaterialStateProperty.all(6),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 14)),
                        textStyle: MaterialStateProperty.all(
                            const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      onPressed: () => _showLogoutConfirmDialog(context),
                      child: const Text("로그아웃"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 회원탈퇴 버튼
                  Center(
                    child: TextButton(
                      onPressed: () => _showDeleteAccountDialog(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        "회원탈퇴",
                        style: TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          color: Colors.grey.shade500,
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
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
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
                    size: 40,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '정말 로그아웃 하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "취소",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
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
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "로그아웃",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '추억 공유를 멈추시겠어요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '탈퇴 이후에는 복구가 불가능하고\n모든 채팅 기록이 삭제됩니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "취소",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        // 🔥 수정된 부분 시작
                        onPressed: () async {
                          Navigator.of(dialogContext).pop(); // 팝업 닫기

                          try {
                            // 1. 서버에 탈퇴 요청 (여기가 빠져 있었습니다)
                            final success = await ApiService.withdrawAccount();

                            if (success) {
                              // 2. 성공 시 로컬 로그아웃 처리
                              await AppState.logout();
                              
                              if (!context.mounted) return;

                              // 3. 로그인 화면으로 이동
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LandingScreen(),
                                ),
                                (route) => false,
                              );
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                              );
                            } else {
                               throw Exception("서버 응답 오류");
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('탈퇴 실패: $e')),
                            );
                          }
                        },
                        // 🔥 수정된 부분 끝
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "탈퇴하기",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}