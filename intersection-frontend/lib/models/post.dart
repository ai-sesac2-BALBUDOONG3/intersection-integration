class Post {
  final int id;
  final int authorId;
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.mediaUrls = const [],
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      authorId: json['author_id'] is int ? json['author_id'] : int.parse(json['author_id'].toString()),
      content: json['content'] ?? '',
      mediaUrls: json['media_urls'] != null ? List<String>.from(json['media_urls']) : [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
