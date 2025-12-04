// lib/models/comment.dart
import 'dart:typed_data';

class Comment {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final DateTime createdAt;

  final String? authorName;

  // 작성자 프로필 이미지 정보
  final String? authorProfileImage;   // URL or 경로
  final Uint8List? authorProfileBytes; // 직접 받은 이미지 바이트

  int likesCount;
  bool liked;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorProfileImage,
    this.authorProfileBytes,
    this.likesCount = 0,
    this.liked = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      postId: json['post_id'] is int
          ? json['post_id']
          : int.parse(json['post_id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),

      authorName: json['author_name'],

      // 서버에서 내려오면 사용, 없으면 null
      authorProfileImage: json['author_profile_image'],
      authorProfileBytes: json['author_profile_bytes'],

      likesCount: json['like_count'] ?? json['likes_count'] ?? 0,  // 백엔드 필드명 통일
      liked: json['is_liked'] ?? json['liked'] ?? false,  // 백엔드 필드명 통일
    );
  }

  // copyWith 메서드 추가 - 불변성을 위한 복사
  Comment copyWith({
    int? id,
    int? postId,
    int? userId,
    String? content,
    DateTime? createdAt,
    String? authorName,
    String? authorProfileImage,
    Uint8List? authorProfileBytes,
    int? likesCount,
    bool? liked,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorProfileImage: authorProfileImage ?? this.authorProfileImage,
      authorProfileBytes: authorProfileBytes ?? this.authorProfileBytes,
      likesCount: likesCount ?? this.likesCount,
      liked: liked ?? this.liked,
    );
  }

  get userName => null;
}
