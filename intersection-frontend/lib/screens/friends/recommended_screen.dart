import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class RecommendedFriendsScreen extends StatefulWidget {
  const RecommendedFriendsScreen({super.key});

  @override
  State<RecommendedFriendsScreen> createState() => _RecommendedFriendsScreenState();
}

class _RecommendedFriendsScreenState extends State<RecommendedFriendsScreen> {
  // 친구 목록을 담을 변수 (로딩이 끝나면 채워짐)
  List<User>? _recommendedFriends;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  // 서버에서 데이터 불러오기
  Future<void> _loadFriends() async {
    try {
      final friends = await ApiService.getRecommendedFriends();
      setState(() {
        _recommendedFriends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("추천 친구"),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. 로딩 중
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
   
    // 2. 에러 발생
    if (_errorMessage != null) {
      return Center(child: Text("오류: $_errorMessage"));
    }

    // 3. 데이터 없음 (모두 친구 추가했거나 추천 대상이 없는 경우)
    if (_recommendedFriends == null || _recommendedFriends!.isEmpty) {
      return const Center(
        child: Text(
          "새로운 추천 친구가 없어요 🎉\n모든 친구를 찾으셨나요?",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // 4. 리스트 보여주기
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendedFriends!.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _recommendedFriends![index];
        return _buildFriendCard(user);
      },
    );
  }

  // 친구 카드 디자인 위젯
  Widget _buildFriendCard(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 프로필 아이콘
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 16),
         
          // 이름 및 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${user.school ?? '학교 정보 없음'} · ${user.region ?? '지역 정보 없음'}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 친구 추가 버튼
          ElevatedButton(
            onPressed: () async {
              // 1. API 호출
              bool success = await ApiService.addFriend(user.id);
             
              if (success) {
                // 2. 성공 시, 화면 목록에서 즉시 제거 (UX 향상) 🔥
                setState(() {
                  _recommendedFriends?.removeWhere((u) => u.id == user.id);
                });

                // 3. 안내 메시지
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${user.name}님과 친구가 되었습니다!"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text(
              "친구 추가",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
