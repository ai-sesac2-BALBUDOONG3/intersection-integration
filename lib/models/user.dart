class User {
  final int id;
  final String name;
  final int birthYear;
  final String region;
  final String school;

  String? profileImageUrl;        // 프로필 사진 (변경 가능)
  String? backgroundImageUrl;     // 배경사진 (변경 가능)
  List<String> feedImages;        // 인스타 피드 이미지 리스트

  User({
    required this.id,
    required this.name,
    required this.birthYear,
    required this.region,
    required this.school,
    this.profileImageUrl,
    this.backgroundImageUrl,
    List<String>? feedImages,
  }) : feedImages = feedImages ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      name: json["name"],
      birthYear: json["birth_year"] ?? json["birthYear"] ?? 0,
      region: json["region"],
      school: json["school_name"] ?? json["school"] ?? "",

      profileImageUrl: json["profile_image"],
      backgroundImageUrl: json["background_image"],

      feedImages: (json["feed_images"] != null)
          ? List<String>.from(json["feed_images"])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "birth_year": birthYear,
      "region": region,
      "school_name": school,

      "profile_image": profileImageUrl,
      "background_image": backgroundImageUrl,
      "feed_images": feedImages,
    };
  }
}
