class Post {
  final int id;
  final int authorId;
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;

  // 작성자 정보
  final String? authorName;
  final String? authorSchool;
  final String? authorRegion;
  final String? authorProfileImage;

  // 좋아요 정보
  int likesCount;
  bool liked;

  // 댓글 개수
  int commentsCount;

  Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.mediaUrls = const [],
    required this.createdAt,

    this.authorName,
    this.authorSchool,
    this.authorRegion,
    this.authorProfileImage,

    this.likesCount = 0,
    this.liked = false,
    this.commentsCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // media_urls 또는 image_url 대응
    List<String> parsedMediaUrls = [];

    // 1) media_urls = ["a.png", "b.jpg"]
    if (json['media_urls'] != null) {
      parsedMediaUrls = List<String>.from(json['media_urls']);
    }
    // 2) image_url = "a.png"
    else if (json['image_url'] != null) {
      parsedMediaUrls = [json['image_url']];
    }

    return Post(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      authorId: json['author_id'] is int
          ? json['author_id']
          : int.parse(json['author_id'].toString()),
      content: json['content'] ?? '',
      mediaUrls: parsedMediaUrls,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),

      authorName: json['author_name'],
      authorSchool: json['author_school'],
      authorRegion: json['author_region'],
      authorProfileImage: json['author_profile_image'],

      // 🔥 백엔드 키와 정확히 일치하도록 수정
      likesCount: json['like_count'] ?? 0,
      liked: json['is_liked'] ?? false,
      commentsCount: json['comment_count'] ?? 0,
    );
  }

  // 대표 이미지
  String? get imageUrl {
    if (mediaUrls.isEmpty) return null;
    return mediaUrls.first;
  }
}
