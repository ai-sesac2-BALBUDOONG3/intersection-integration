import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/common/image_viewer.dart';
import 'package:intersection/services/api_service.dart';

class FriendProfileScreen extends StatefulWidget {
  final User user;

  const FriendProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final hasProfileImage = widget.user.profileImageUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog();
              } else if (value == 'report') {
                _showReportDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('차단하기'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, size: 20, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('신고하기'),
                  ],
                ),
              ),
            ],
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
                    if (widget.user.backgroundImageUrl != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ImageViewer(imageUrl: widget.user.backgroundImageUrl!),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: widget.user.backgroundImageUrl != null
                          ? DecorationImage(
                              image: _imageProvider(widget.user.backgroundImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: widget.user.backgroundImageUrl == null
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
                    onTap: hasProfileImage
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewer(
                                  imageUrl: widget.user.profileImageUrl!,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Hero(
                      tag: "friend-profile-${widget.user.id}",
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            hasProfileImage ? _imageProvider(widget.user.profileImageUrl!) : null,
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

            // ==========================
            // 3) 이름 + 설명
            // ==========================
            Text(
              widget.user.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "${widget.user.birthYear}년생 · ${widget.user.school} · ${widget.user.region}",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 30),

            // ==========================
            // 4) 친구 피드
            // ==========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "피드",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (widget.user.feedImages.isEmpty)
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
                itemCount: widget.user.feedImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final img = widget.user.feedImages[index];

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
                  Text("학교: ${widget.user.school}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text("지역: ${widget.user.region}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text("${widget.user.birthYear}년생",
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
  // 이미지 자동 구분 로더
  // ==========================
  ImageProvider _imageProvider(String path) {
    if (path.startsWith("http")) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  /// 차단 확인 다이얼로그
  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '사용자 차단',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${widget.user.name}님을 차단하시겠습니까?\n\n'
            '차단하면:\n'
            '• 메시지를 주고받을 수 없습니다\n'
            '• 친구 목록에서 제거됩니다\n'
            '• 게시글이 보이지 않습니다',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                final success = await ApiService.blockUser(widget.user.id);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.user.name}님을 차단했습니다')),
                  );
                  Navigator.pop(context); // 프로필 화면 닫기
                }
              },
              child: const Text(
                '차단',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 신고 다이얼로그
  void _showReportDialog() {
    String selectedReason = '스팸/광고';
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '사용자 신고',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.user.name}님을 신고합니다',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '신고 사유:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '스팸/광고',
                          child: Text('스팸/광고'),
                        ),
                        DropdownMenuItem(
                          value: '욕설/비방',
                          child: Text('욕설/비방'),
                        ),
                        DropdownMenuItem(
                          value: '허위정보',
                          child: Text('허위정보'),
                        ),
                        DropdownMenuItem(
                          value: '불법정보',
                          child: Text('불법정보'),
                        ),
                        DropdownMenuItem(
                          value: '기타',
                          child: Text('기타'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedReason = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '상세 내용 (선택):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        hintText: '신고 사유를 자세히 적어주세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    
                    final success = await ApiService.reportUser(
                      userId: widget.user.id,
                      reason: selectedReason,
                      content: contentController.text.trim().isEmpty
                          ? null
                          : contentController.text.trim(),
                    );
                    
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    '신고',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
