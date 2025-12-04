// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/app_state.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/user.dart';

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
  // 회원가입
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> signup(
      Map<String, dynamic> data) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      
// 1. 에러 응답 본문 해독 (한글 깨짐 방지 utf8.decode 사용)
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      final errorMessage = errorBody['detail'] ?? '';

      // 2. "이미 존재하는 아이디" 에러인지 확인
      if (errorMessage == "login_id already exists") {
        // 팝업창에 띄우고 싶은 문구로 변경하세요 👇
        throw Exception("이미 가입된 이메일입니다.\n로그인하거나 다른 이메일을 사용해주세요.");
      }

      // 3. 그 외 다른 에러인 경우
      throw Exception("회원가입 실패: $errorMessage");
    }
  }

  // ----------------------------------------------------
  // 로그인
  // ----------------------------------------------------
  static Future<String> login(String email, String password) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/token");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["access_token"];
    } else {
      throw Exception("로그인 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 내 정보 가져오기
  // ----------------------------------------------------
  static Future<User> getMyInfo() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me");
    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return User(
        id: data["id"],
        name: data["name"] ?? "",
        nickname: data["nickname"],
        birthYear: data["birth_year"] ?? 0,
        gender: data["gender"],
        region: data["region"] ?? "",
        school: data["school_name"] ?? "",
        schoolType: data["school_type"],
        admissionYear: data["admission_year"],
        phone: data["phone"],
        profileImageUrl: data["profile_image"],
        backgroundImageUrl: data["background_image"],
        profileFeedImages: (data["feed_images"] != null)
        ? List<String>.from(data["feed_images"])
        : [],
      );
    } else {
      throw Exception("내 정보 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 특정 사용자 정보 가져오기 (피드 이미지 포함)
  // ----------------------------------------------------
  static Future<User> getUserById(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/$userId");
    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return User(
        id: data["id"],
        name: data["name"] ?? "",
        nickname: data["nickname"],
        birthYear: data["birth_year"] ?? 0,
        gender: data["gender"],
        region: data["region"] ?? "",
        school: data["school_name"] ?? "",
        schoolType: data["school_type"],
        admissionYear: data["admission_year"],
        phone: data["phone"],
        profileImageUrl: data["profile_image"],
        backgroundImageUrl: data["background_image"],
        profileFeedImages: (data["feed_images"] != null)
            ? List<String>.from(data["feed_images"])
            : [],
      );
    } else {
      throw Exception("사용자 정보 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 내 정보 업데이트
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> updateMyInfo(
      Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users/me');

    final body = <String, dynamic>{
      if (data["name"] != null) "name": data["name"],
      if (data["nickname"] != null) "nickname": data["nickname"],
      if (data["birth_year"] != null) "birth_year": data["birth_year"],
      if (data["gender"] != null) "gender": data["gender"],
      if (data["region"] != null) "region": data["region"],
      if (data["school_name"] != null) "school_name": data["school_name"],
      if (data["school_type"] != null) "school_type": data["school_type"],
      if (data["admission_year"] != null)
        "admission_year": data["admission_year"],
      if (data["profile_image"] != null) "profile_image": data["profile_image"],
      if (data["background_image"] != null)
        "background_image": data["background_image"],
    };

    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('내 정보 업데이트 실패: ${response.body}');
  }

  // ----------------------------------------------------
  // 추천 친구
  // ----------------------------------------------------
  static Future<List<User>> getRecommendedFriends() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me/recommended");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;

      return list
          .map(
            (data) => User(
          id: data["id"],
          name: data["name"],
          birthYear: data["birth_year"],
          region: data["region"],
          school: data["school_name"],
              profileImageUrl: data["profile_image"],
              backgroundImageUrl: data["background_image"],
            ),
          )
          .toList();
    } else {
      throw Exception("추천 친구 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 친구 목록
  // ----------------------------------------------------
  static Future<List<User>> getFriends() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/friends/me");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;

      return list
          .map(
            (data) => User(
              id: data["id"],
              name: data["name"],
              birthYear: data["birth_year"],
              region: data["region"],
              school: data["school_name"],
              profileImageUrl: data["profile_image"],
              backgroundImageUrl: data["background_image"],
            ),
          )
          .toList();
    } else {
      throw Exception("친구 목록 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 친구 추가
  // ----------------------------------------------------
  static Future<bool> addFriend(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/friends/$userId");

    final response = await http.post(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  // ----------------------------------------------------
  // 게시글 / 댓글
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> createPost(String content) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me/posts/");
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({"content": content}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception("게시글 작성 실패: ${response.body}");
  }

  static Future<Map<String, dynamic>> createPostWithMedia({
    required String content,
    List<String> mediaUrls = const [],
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me/posts/");

    final body = <String, dynamic>{
      "content": content,
      if (mediaUrls.isNotEmpty) "image_url": mediaUrls.first,
    };

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception("게시글 작성 실패: ${response.body}");
  }

  static Future<List<Map<String, dynamic>>> listPosts() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/posts/");
    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }

    throw Exception("게시물 목록 불러오기 실패: ${response.body}");
  }

  static Future<Map<String, dynamic>> createComment(
      int postId, String content) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/posts/$postId/comments");
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({"content": content}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception("댓글 작성 실패: ${response.body}");
  }

  static Future<List<Map<String, dynamic>>> listComments(int postId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/posts/$postId/comments");
    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return List<Map<String, dynamic>>.from(list);
    }

    throw Exception("댓글 목록 불러오기 실패: ${response.body}");
  }

  // ----------------------------------------------------
  // 게시물 신고
  // ----------------------------------------------------
  static Future<bool> reportPost(int postId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/report-post");

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        "post_id": postId,
        "reason": "inappropriate",
      }),
    );

    return response.statusCode == 200;
  }

  // ----------------------------------------------------
  // ❤️ 게시물 좋아요 (프론트 전용: 서버 연동 전)
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> togglePostLike(int postId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/posts/$postId/like");
    final response = await http.post(url, headers: _headers(json: false));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception("게시글 좋아요 실패: ${response.body}");
  }

  // ----------------------------------------------------
  // ❤️ 게시물 좋아요 — 서버 토글 방식
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> toggleLike(int postId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/posts/$postId/like");

    final response = await http.post(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "liked": data["is_liked"],
        "likes_count": data["like_count"],
      };
    }

    throw Exception("좋아요 토글 실패: ${response.body}");
  }



  // ----------------------------------------------------
  // ❤️ 댓글 좋아요
  // ----------------------------------------------------
  static Future<bool> likeComment(int commentId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/comments/$commentId/like");
    final response = await http.post(url, headers: _headers(json: false));
    return response.statusCode == 200;
  }

  static Future<bool> unlikeComment(int commentId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/comments/$commentId/like");
    final response = await http.delete(url, headers: _headers(json: false));
    return response.statusCode == 200;
  }

  // ----------------------------------------------------
  // 💬 채팅
  // ----------------------------------------------------
  static Future<ChatRoom> createOrGetChatRoom(int friendId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/chat/rooms");

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({"friend_id": friendId}),
    );

    if (response.statusCode == 200) {
      return ChatRoom.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("채팅방 생성 실패: ${response.body}");
    }
  }

  static Future<List<ChatRoom>> getMyChatRooms() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/chat/rooms");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((json) => ChatRoom.fromJson(json)).toList();
    } else {
      throw Exception("채팅방 목록 불러오기 실패: ${response.body}");
    }
  }

  static Future<List<ChatMessage>> getChatMessages(int roomId) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId/messages");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception("메시지 불러오기 실패: ${response.body}");
    }
  }

  static Future<ChatMessage> sendChatMessage(
    int roomId,
    String content, {
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
  }) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId/messages");

    final body = {
      "content": content,
      if (fileUrl != null) "file_url": fileUrl,
      if (fileName != null) "file_name": fileName,
      if (fileSize != null) "file_size": fileSize,
      if (fileType != null) "file_type": fileType,
    };

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return ChatMessage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("메시지 전송 실패: ${response.body}");
    }
  }

  // ========================================
  // 파일 업로드 (공용)
  // ========================================
  static Future<Map<String, dynamic>> uploadFile(File file) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/upload");

    var request = http.MultipartRequest('POST', url);

    if (AppState.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppState.token}';
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: file.path.split('/').last,
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw Exception("파일 업로드 실패: $responseBody");
    }
  }

  static Future<Map<String, dynamic>> uploadBytes(
      Uint8List bytes, String fileName) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/upload");

    var request = http.MultipartRequest('POST', url);

    if (AppState.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppState.token}';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw Exception("파일 업로드 실패: $responseBody");
    }
  }

  static Future<ChatMessage> sendImageMessage(
      int roomId, File imageFile) async {
    final uploadResult = await uploadFile(imageFile);

    return await sendChatMessage(
      roomId,
      "[이미지]",
      fileUrl: uploadResult['file_url'],
      fileName: uploadResult['filename'],
      fileSize: uploadResult['size'],
      fileType: uploadResult['type'],
    );
  }

  static Future<ChatMessage> sendFileMessage(int roomId, File file) async {
    final uploadResult = await uploadFile(file);

    final fileName = uploadResult['filename'];
    return await sendChatMessage(
      roomId,
      "[파일] $fileName",
      fileUrl: uploadResult['file_url'],
      fileName: fileName,
      fileSize: uploadResult['size'],
      fileType: uploadResult['type'],
    );
  }

  // ----------------------------------------------------
  // 신고/차단
  // ----------------------------------------------------
  static Future<bool> blockUser(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/block");

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({"blocked_user_id": userId}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> unblockUser(int userId) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/moderation/block/$userId");

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> checkIfBlocked(int userId) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/moderation/is-blocked/$userId");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {
      "is_blocked": false,
      "i_blocked_them": false,
      "they_blocked_me": false,
    };
  }

  static Future<bool> reportUser({
    required int userId,
    required String reason,
    String? content,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/report");

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        "reported_user_id": userId,
        "reason": reason,
        "content": content,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteChatRoom(int roomId) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId");

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  // ✅ 채팅방 고정/고정 해제
  static Future<bool> togglePinChatRoom(int roomId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId/pin");

    final response = await http.put(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  // ✅ 메시지 고정/고정 해제
  static Future<bool> togglePinMessage(int roomId, int messageId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId/messages/$messageId/pin");

    final response = await http.put(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> checkMyReport(int userId) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/moderation/my-reports/$userId");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {"has_reported": false};
  }

  static Future<bool> cancelReport(int reportId) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/moderation/report/$reportId");

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  // ----------------------------------------------------
  // Web 업로드
  // ----------------------------------------------------
  static Future<ChatMessage> sendImageMessageWeb(
      int roomId, Uint8List bytes, String fileName) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/upload");

    var request = http.MultipartRequest('POST', url);
    if (AppState.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppState.token}';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("업로드 실패: $body");
    }

    final uploadResult = jsonDecode(body);

    return await sendChatMessage(
      roomId,
      "[이미지]",
      fileUrl: uploadResult['file_url'],
      fileName: uploadResult['filename'],
      fileSize: uploadResult['size'],
      fileType: uploadResult['type'],
    );
  }

  static Future<ChatMessage> sendFileMessageWeb(
      int roomId, Uint8List bytes, String fileName) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/upload");

    var request = http.MultipartRequest('POST', url);
    if (AppState.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppState.token}';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("업로드 실패: $body");
    }

    final uploadResult = jsonDecode(body);

    return await sendChatMessage(
      roomId,
      "[파일] $fileName",
      fileUrl: uploadResult['file_url'],
      fileName: fileName,
      fileSize: uploadResult['size'],
      fileType: uploadResult['type'],
    );
  }

  // ========================================
  // 🔥 프로필/배경 이미지 저장 (웹 안전 버전)
  // ========================================
  static Future<void> uploadProfileImages({
    Uint8List? profileBytes,
    Uint8List? backgroundBytes,
    String? profilePath,
    String? backgroundPath,
  }) async {
    String? profileUrl;
    String? backgroundUrl;

    final isWeb = kIsWeb;

    // 프로필 업로드
    if (profileBytes != null) {
      final res = await uploadBytes(profileBytes, "profile.png");
      profileUrl = res["file_url"];
    } else if (!isWeb && profilePath != null) {
      final f = File(profilePath);
      if (f.existsSync()) {
        final res = await uploadFile(f);
        profileUrl = res["file_url"];
      }
    }

    // 배경 업로드
    if (backgroundBytes != null) {
      final res = await uploadBytes(backgroundBytes, "background.png");
      backgroundUrl = res["file_url"];
    } else if (!isWeb && backgroundPath != null) {
      final f = File(backgroundPath);
      if (f.existsSync()) {
        final res = await uploadFile(f);
        backgroundUrl = res["file_url"];
      }
    }

    // 서버에 URL 저장
    final updateData = <String, dynamic>{};
    if (profileUrl != null) updateData["profile_image"] = profileUrl;
    if (backgroundUrl != null) updateData["background_image"] = backgroundUrl;

    if (updateData.isNotEmpty) {
      await updateMyInfo(updateData);
      AppState.currentUser = await getMyInfo();
    }
  }
}
