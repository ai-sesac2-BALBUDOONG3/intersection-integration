import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../services/api_service.dart';
import '../../../data/app_state.dart';
import '../../../config/api_config.dart';
import '../../friends/friend_profile_screen.dart';

/// 채팅방 헤더 위젯 (AppBar)
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final int friendId;
  final String friendName;
  final String? friendProfileImage;
  final bool isSearchMode;
  final TextEditingController searchController;
  final bool theyBlockedMe;
  final bool iBlockedThem;
  final bool iReportedThem;
  final VoidCallback onToggleSearchMode;
  final Function(String) onSearchChanged;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onReport;
  final VoidCallback onUnreport;
  final VoidCallback onLeaveChat;

  const ChatHeader({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendProfileImage,
    required this.isSearchMode,
    required this.searchController,
    required this.theyBlockedMe,
    required this.iBlockedThem,
    required this.iReportedThem,
    required this.onToggleSearchMode,
    required this.onSearchChanged,
    required this.onBlock,
    required this.onUnblock,
    required this.onReport,
    required this.onUnreport,
    required this.onLeaveChat,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: isSearchMode
          ? TextField(
              controller: searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: '메시지 검색',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: onSearchChanged,
            )
          : GestureDetector(
              onTap: () async {
                User? user;

                // 항상 API로 최신 사용자 정보 가져오기 (프로필 사진, 배경 이미지, 피드 이미지 포함)
                try {
                  user = await ApiService.getUserById(friendId);

                  // 친구 목록에도 업데이트
                  final index = AppState.friends.indexWhere((f) => f.id == friendId);
                  if (index != -1) {
                    AppState.friends[index] = user;
                  } else {
                    // 친구 목록에 없으면 추가
                    AppState.friends.add(user);
                  }
                } catch (e) {
                  debugPrint("사용자 정보 가져오기 실패: $e");
                  // API 실패 시 친구 목록에서 찾기
                  try {
                    user = AppState.friends.firstWhere(
                      (friend) => friend.id == friendId,
                    );
                  } catch (e2) {
                    // 친구 목록에도 없으면 기본 정보로 User 객체 생성
                    user = User(
                      id: friendId,
                      name: friendName,
                      nickname: null,
                      birthYear: 0,
                      gender: null,
                      region: "",
                      school: "",
                      schoolType: null,
                      admissionYear: null,
                      profileImageUrl: friendProfileImage,
                      backgroundImageUrl: null,
                      profileFeedImages: [],
                    );
                  }
                }

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FriendProfileScreen(user: user!),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  friendProfileImage != null
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            "${ApiConfig.baseUrl}$friendProfileImage",
                          ),
                          onBackgroundImageError: (_, __) {},
                        )
                      : CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF3C7EFF),
                          child: Text(
                            friendName.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      friendName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(isSearchMode ? Icons.close : Icons.search),
          onPressed: onToggleSearchMode,
          tooltip: isSearchMode ? '검색 닫기' : '검색',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'block') {
              onBlock();
            } else if (value == 'unblock') {
              onUnblock();
            } else if (value == 'report') {
              onReport();
            } else if (value == 'unreport') {
              onUnreport();
            } else if (value == 'leave') {
              onLeaveChat();
            }
          },
          itemBuilder: (context) => [
            // 신고당한 경우: 나가기만 가능
            if (!theyBlockedMe) ...[
              if (!theyBlockedMe && !iBlockedThem && !iReportedThem)
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
              if (iBlockedThem)
                const PopupMenuItem(
                  value: 'unblock',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: Colors.green),
                      SizedBox(width: 12),
                      Text('차단 해제'),
                    ],
                  ),
                ),
              if (!theyBlockedMe && !iReportedThem && !iBlockedThem)
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
              if (iReportedThem)
                const PopupMenuItem(
                  value: 'unreport',
                  child: Row(
                    children: [
                      Icon(Icons.undo, size: 20, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('신고 취소'),
                    ],
                  ),
                ),
            ],
            const PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, size: 20, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('채팅방 나가기'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

