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

  List<String> feedImages;

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
    List<String>? feedImages,
  }) : feedImages = feedImages ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      name: json["name"],
      birthYear: json["birth_year"] ?? json["birthYear"] ?? 0,
      region: json["region"] ?? "",
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
