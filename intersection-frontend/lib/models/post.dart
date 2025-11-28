class Post {
  final int id;
  final int authorId;
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;
 
  // 👇 [추가됨] 작성자 정보 (서버에서 보내줄 경우 사용)
  final String? authorName;
  final String? authorSchool;
  final String? authorRegion;
 
  const Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.mediaUrls = const [],
    required this.createdAt,
    // 👇 생성자에 추가
    this.authorName,
    this.authorSchool,
    this.authorRegion,
  });
 
  factory Post.fromJson(Map<String, dynamic> json) {
    // 이미지 URL 처리: media_urls 리스트가 없으면 image_url 단일 필드를 리스트로 변환하여 사용
    List<String> parsedMediaUrls = [];
    if (json['media_urls'] != null) {
      parsedMediaUrls = List<String>.from(json['media_urls']);
    } else if (json['image_url'] != null) {
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
 
      // 👇 [추가됨] JSON에서 작성자 정보 추출
      authorName: json['author_name'],
      authorSchool: json['author_school'],
      authorRegion: json['author_region'],
    );
  }
}