// lib/data/app_state.dart

import 'package:intersection/models/user.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/data/user_storage.dart';

class AppState {
  /// 현재 로그인한 유저
  static User? currentUser;

  /// JWT 토큰
  static String? token;

  /// 🔥 DB에서 불러온 친구 목록
  static List<User> friends = [];

  /// 🔥 커뮤니티 포스트 (추후 API로 대체)
  static List<Post> communityPosts = [];

  /// 🔥 모든 사용자(샘플/로컬 저장용)
  static List<User> allUsers = [];

  /// 🔥 신규 가입자인지 여부
  static bool isNewUser = false;

  /// 내가 참여해본 채팅방 목록
  static List<int> chatList = [];

  // ------------------------------------------------------------
  // 🔥 상태 변화 리스너 등록 기능 추가
  // ------------------------------------------------------------
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  static void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  static void notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  /// ----------------------------------------------------
  /// 친구 추가 (로컬 반영)
  /// ----------------------------------------------------
  static void follow(User user) {
    if (!friends.any((f) => f.id == user.id)) {
      friends.add(user);
      notifyListeners();
    }
  }

  /// ----------------------------------------------------
  /// 친구 제거
  /// ----------------------------------------------------
  static void unfollow(User user) {
    friends.removeWhere((f) => f.id == user.id);
    notifyListeners();
  }

  /// ----------------------------------------------------
  /// 로그인
  /// ----------------------------------------------------
  static Future<void> login(String newToken, User user) async {
    token = newToken;
    currentUser = user;

    // 로그인한 사용자는 신규 X
    isNewUser = false;

    await UserStorage.saveLoginSession(newToken, user);
    notifyListeners();
  }

  /// ----------------------------------------------------
  /// 🔥 프로필 변경 시 반드시 호출해야 하는 함수
  /// ----------------------------------------------------
  static void updateProfile() {
    notifyListeners();
  }

  /// ----------------------------------------------------
  /// 로그아웃
  /// ----------------------------------------------------
  static Future<void> logout() async {
    token = null;
    currentUser = null;
    friends = [];
    communityPosts = [];

    await UserStorage.clear();
    notifyListeners();
  }
}

typedef VoidCallback = void Function();
