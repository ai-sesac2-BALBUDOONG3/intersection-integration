// lib/models/user.dart
import 'dart:typed_data';

class User {
  final int id;
  final String name;
  final int birthYear;
  final String region;
  final String school;

  // 기존 URL 방식
  String? profileImageUrl;
  String? backgroundImageUrl;

  // 웹용 bytes 방식 추가
  Uint8List? profileImageBytes;
  Uint8List? backgroundImageBytes;

  // 기존 feedImages → 프로필 피드 전용으로 이름 변경
  List<String> profileFeedImages;

  User({
    required this.id,
    required this.name,
    required this.birthYear,
    required this.region,
    required this.school,
    this.profileImageUrl,
    this.backgroundImageUrl,
    this.profileImageBytes,
    this.backgroundImageBytes,
    List<String>? profileFeedImages,
  }) : profileFeedImages = profileFeedImages ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      name: json["name"],
      birthYear: json["birth_year"] ?? json["birthYear"] ?? 0,
      region: json["region"] ?? "",
      school: json["school_name"] ?? json["school"] ?? "",
      profileImageUrl: json["profile_image"],
      backgroundImageUrl: json["background_image"],
      profileFeedImages: (json["profile_feed_images"] != null)
          ? List<String>.from(json["profile_feed_images"])
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

      // 저장 시에도 필드 이름 변경
      "profile_feed_images": profileFeedImages,
    };
  }
}
