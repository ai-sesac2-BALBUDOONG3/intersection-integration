class Post {
  final String id;
  final String authorId;
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
}
