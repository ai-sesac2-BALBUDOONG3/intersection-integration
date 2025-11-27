import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../data/app_state.dart';

class ApiService {
  // ----------------------------------------------------
  // 공통 헤더
  // ----------------------------------------------------
  static Map<String, String> _headers({bool json = true}) {
    final token = AppState.token;
    return {
      if (json) "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ----------------------------------------------------
  // 1) 회원가입
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception("회원가입 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 2) 로그인 (JSON 방식)
  // ----------------------------------------------------
  static Future<String> login(String email, String password) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/token");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["access_token"];
    } else {
      throw Exception("로그인 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 3) 내 정보 가져오기
  // ----------------------------------------------------
  static Future<User> getMyInfo() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me");
    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("내 정보 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 7) 내 정보 업데이트
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> updateMyInfo(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users/me');

    final response = await http.put(url, headers: _headers(), body: jsonEncode(data));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('내 정보 업데이트 실패: ${response.body}');
  }

  // ----------------------------------------------------
  // 🔥 [복구됨] Kakao dev login (개발용 로그인)
  // ----------------------------------------------------
  static Future<String> kakaoDevLogin() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/auth/kakao/dev_token");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["access_token"];
    }

    throw Exception("Kakao dev login failed: ${response.body}");
  }

  // ----------------------------------------------------
  // 4) 추천 친구 목록 (Null 에러 해결 버전)
  // ----------------------------------------------------
  static Future<List<User>> getRecommendedFriends() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me/recommended");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      // User.fromJson을 사용하여 안전하게 변환
      return list.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("추천 친구 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 5) 친구 추가
  // ----------------------------------------------------
  static Future<bool> addFriend(int targetUserId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/friends/$targetUserId");

    final response = await http.post(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  // ----------------------------------------------------
  // 6) 친구 목록 가져오기
  // ----------------------------------------------------
  static Future<List<User>> getFriends() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/friends/me");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("친구 목록 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // Posts / Comments
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> createPost(String content) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me/posts/");
    final response = await http.post(url, headers: _headers(), body: jsonEncode({"content": content}));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception("게시글 작성 실패: ${response.body}");
  }

  static Future<List<Map<String, dynamic>>> listPosts() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/posts/");
    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return List<Map<String, dynamic>>.from(list);
    }

    throw Exception("게시물 목록 불러오기 실패: ${response.body}");
  }

  static Future<Map<String, dynamic>> createComment(int postId, String content) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/posts/$postId/comments");
    final response = await http.post(url, headers: _headers(), body: jsonEncode({"content": content}));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception("댓글 작성 실패: ${response.body}");
  }

  static Future<List<Map<String, dynamic>>> listComments(int postId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/posts/$postId/comments");
    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return List<Map<String, dynamic>>.from(list);
    }

    throw Exception("댓글 목록 불러오기 실패: ${response.body}");
  }
}