/// 학교 정보 모델
class SchoolInfo {
  final String name;
  final String? schoolType;
  final int? admissionYear;

  SchoolInfo({
    required this.name,
    this.schoolType,
    this.admissionYear,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (schoolType != null) 'school_type': schoolType,
      if (admissionYear != null) 'admission_year': admissionYear,
    };
  }

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      name: json['name'] ?? '',
      schoolType: json['school_type'],
      admissionYear: json['admission_year'],
    );
  }

  SchoolInfo copyWith({
    String? name,
    String? schoolType,
    int? admissionYear,
  }) {
    return SchoolInfo(
      name: name ?? this.name,
      schoolType: schoolType ?? this.schoolType,
      admissionYear: admissionYear ?? this.admissionYear,
    );
  }
}

