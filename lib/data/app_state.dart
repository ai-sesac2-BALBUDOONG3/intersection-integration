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

  /// ----------------------------------------------------
  /// 친구 추가 (로컬 반영)
  /// ----------------------------------------------------
  static void follow(User user) {
    if (!friends.any((f) => f.id == user.id)) {
      friends.add(user);
    }
  }

  /// ----------------------------------------------------
  /// 친구 제거
  /// ----------------------------------------------------
  static void unfollow(User user) {
    friends.removeWhere((f) => f.id == user.id);
  }

  /// ----------------------------------------------------
  /// 로그인 (토큰 + 유저정보 메모리에 저장)
  /// ----------------------------------------------------
  static void login(String newToken, User user) {
    token = newToken;
    currentUser = user;
  }

  /// ----------------------------------------------------
  /// 🔥 로그아웃 (완전한 버전)
  /// ----------------------------------------------------
  static Future<void> logout() async {
    token = null;
    currentUser = null;
    friends = [];
    communityPosts = [];

    // 🔥 SharedPreferences 초기화 → 자동로그인 제거
    await UserStorage.clear();
  }
  /// 내가 참여해본 채팅방 목록 (friendId 기반)
  static List<int> chatList = [];

}
