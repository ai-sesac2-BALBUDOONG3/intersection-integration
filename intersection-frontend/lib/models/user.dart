// lib/models/user.dart
import 'dart:typed_data';

class User {
  final int id;
  final String name;
  final String? nickname;
  final int birthYear;
  final String? gender;
  final String region;
  final String school;  // 하위 호환성
  final String? schoolType;  // 하위 호환성
  final int? admissionYear;  // 하위 호환성
  final List<Map<String, dynamic>>? schools;  // 여러 학교 정보 (JSON 형식)
  final String? phone;  // 전화번호

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
    this.nickname,
    required this.birthYear,
    this.gender,
    required this.region,
    required this.school,  // 하위 호환성
    this.schoolType,  // 하위 호환성
    this.admissionYear,  // 하위 호환성
    this.schools,  // 여러 학교 정보 (JSON 형식)
    this.phone,
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
      nickname: json["nickname"],
      birthYear: json["birth_year"] ?? json["birthYear"] ?? 0,
      gender: json["gender"],
      region: json["region"] ?? "",
      school: json["school_name"] ?? json["school"] ?? "",  // 하위 호환성
      schoolType: json["school_type"],  // 하위 호환성
      admissionYear: json["admission_year"],  // 하위 호환성
      schools: json["schools"] != null 
          ? List<Map<String, dynamic>>.from(json["schools"])
          : null,  // 여러 학교 정보 (JSON 형식)
      phone: json["phone"],
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
      if (nickname != null) "nickname": nickname,
      "birth_year": birthYear,
      if (gender != null) "gender": gender,
      "region": region,
      "school_name": school,  // 하위 호환성
      if (schoolType != null) "school_type": schoolType,  // 하위 호환성
      if (admissionYear != null) "admission_year": admissionYear,  // 하위 호환성
      if (schools != null) "schools": schools,  // 여러 학교 정보 (JSON 형식)
      "profile_image": profileImageUrl,
      "background_image": backgroundImageUrl,

      // 저장 시에도 필드 이름 변경
      "profile_feed_images": profileFeedImages,
    };
  }
}
