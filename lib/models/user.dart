class User {
  final String id;
  final String name;
  final int birthYear;
  final String region; // 예: "서울 강서구"
  final String school; // 예: "A초등학교"
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.name,
    required this.birthYear,
    required this.region,
    required this.school,
    this.profileImageUrl,
  });
}
