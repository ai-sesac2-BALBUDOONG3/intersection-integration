import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../config/api_config.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../data/app_state.dart';
import 'dart:typed_data';

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
      final data = jsonDecode(response.body);
      return User(
        id: data["id"],
        name: data["name"] ?? "",           // null이면 빈 문자열
        birthYear: data["birth_year"] ?? 0, // null이면 0
        region: data["region"] ?? "",       // null이면 빈 문자열
        school: data["school_name"] ?? "",  // null이면 빈 문자열
      );
    } else {
      throw Exception("내 정보 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 7) Update my info (authenticated)
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
  // Kakao dev login (dev-only helper)
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
  // 4) 추천 친구 목록
  // ----------------------------------------------------
  static Future<List<User>> getRecommendedFriends() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me/recommended");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;

      return list.map((data) {
        return User(
          id: data["id"],
          name: data["name"],
          birthYear: data["birth_year"],
          region: data["region"],
          school: data["school_name"],
        );
      }).toList();
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
      final list = jsonDecode(response.body) as List;

      return list.map((data) {
        return User(
          id: data["id"],
          name: data["name"],
          birthYear: data["birth_year"],
          region: data["region"],
          school: data["school_name"],
        );
      }).toList();
    } else {
      throw Exception("친구 목록 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 💬 채팅 API
  // ----------------------------------------------------
  
  /// 채팅방 생성 또는 가져오기
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

  /// 내 채팅방 목록 가져오기
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

  /// 채팅방의 메시지 목록 가져오기
  static Future<List<ChatMessage>> getChatMessages(int roomId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId/messages");

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

  // ========================================
  // ✅ 파일 업로드 관련 메서드 추가 (여기부터)
  // ========================================
  
  /// 파일 업로드
  static Future<Map<String, dynamic>> uploadFile(File file) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/upload");
    
    var request = http.MultipartRequest('POST', url);
    
    // JWT 토큰 추가
    if (AppState.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppState.token}';
    }
    
    // 파일 추가
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

  /// 메시지 전송 (파일 포함 가능) - 기존 sendChatMessage 교체
  static Future<ChatMessage> sendChatMessage(
    int roomId,
    String content, {
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId/messages");

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

  /// 이미지 메시지 전송
  static Future<ChatMessage> sendImageMessage(int roomId, File imageFile) async {
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

  /// 파일 메시지 전송
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
  
  // ========================================
  // ✅ 파일 업로드 관련 메서드 추가 (여기까지)
  // ========================================

  // ----------------------------------------------------
  // 🚫 차단 & 신고 API
  // ----------------------------------------------------
  
  /// 사용자 차단
  static Future<bool> blockUser(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/block");

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({"blocked_user_id": userId}),
    );

    return response.statusCode == 200;
  }

  /// 사용자 차단 해제
  static Future<bool> unblockUser(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/block/$userId");

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  /// 차단 목록 조회
  static Future<List<int>> getBlockedUserIds() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/blocked");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((item) => item['blocked_user_id'] as int).toList();
    }
    return [];
  }

  /// 차단 여부 확인 (양방향)
  static Future<Map<String, dynamic>> checkIfBlocked(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/is-blocked/$userId");

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

  /// 사용자 신고
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

  /// 채팅방 삭제 (나가기)
  static Future<bool> deleteChatRoom(int roomId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId");

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  /// 내가 특정 사용자를 신고했는지 확인
  static Future<Map<String, dynamic>> checkMyReport(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/my-reports/$userId");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {"has_reported": false};
  }

  /// 신고 취소
  static Future<bool> cancelReport(int reportId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/moderation/report/$reportId");

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  static Future<ChatMessage> sendImageMessageWeb(int roomId, Uint8List bytes, String fileName) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/upload");
    var request = http.MultipartRequest('POST', url);
    if (AppState.token != null) request.headers['Authorization'] = 'Bearer ${AppState.token}';
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) throw Exception("업로드 실패");
    final uploadResult = jsonDecode(responseBody) as Map<String, dynamic>;
    return await sendChatMessage(roomId, "[이미지]",
      fileUrl: uploadResult['file_url'], fileName: uploadResult['filename'],
      fileSize: uploadResult['size'], fileType: uploadResult['type']);
  }

  static Future<ChatMessage> sendFileMessageWeb(int roomId, Uint8List bytes, String fileName) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/upload");
    var request = http.MultipartRequest('POST', url);
    if (AppState.token != null) request.headers['Authorization'] = 'Bearer ${AppState.token}';
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) throw Exception("업로드 실패");
    final uploadResult = jsonDecode(responseBody) as Map<String, dynamic>;
    return await sendChatMessage(roomId, "[파일] $fileName",
      fileUrl: uploadResult['file_url'], fileName: fileName,
      fileSize: uploadResult['size'], fileType: uploadResult['type']);
  }
}
