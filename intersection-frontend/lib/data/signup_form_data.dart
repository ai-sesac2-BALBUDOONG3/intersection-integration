class SignupFormData {
  String loginId = '';
  String password = '';

  String phoneNumber = '';
  bool isPhoneVerified = false;

  String name = '';
  String birthYear = '';
  String gender = '';
  String baseRegion = '';

  String schoolLevel = '';
  String schoolName = '';
  String entryYear = '';

  String? className;
  String? transferInfo;
  String? clubs;
  String? nicknames;
  String? memoryKeywords;

  // Additional fields commonly used elsewhere
  List<String>? interests;
  String? email;

  // Convenience getters for older/alternate property names
  String get phone => phoneNumber;
  String get userId => loginId;
  String get region => baseRegion;

  SignupFormData();

  SignupFormData copyWith({
    String? loginId,
    String? password,
    String? phoneNumber,
    bool? isPhoneVerified,
    String? name,
    String? birthYear,
    String? gender,
    String? baseRegion,
    String? schoolLevel,
    String? schoolName,
    String? entryYear,
    String? className,
    String? transferInfo,
    String? clubs,
    String? nicknames,
    String? memoryKeywords,
    List<String>? interests,
    String? email,
  }) {
    final copy = SignupFormData();
    copy.loginId = loginId ?? this.loginId;
    copy.password = password ?? this.password;
    copy.phoneNumber = phoneNumber ?? this.phoneNumber;
    copy.isPhoneVerified = isPhoneVerified ?? this.isPhoneVerified;
    copy.name = name ?? this.name;
    copy.birthYear = birthYear ?? this.birthYear;
    copy.gender = gender ?? this.gender;
    copy.baseRegion = baseRegion ?? this.baseRegion;
    copy.schoolLevel = schoolLevel ?? this.schoolLevel;
    copy.schoolName = schoolName ?? this.schoolName;
    copy.entryYear = entryYear ?? this.entryYear;
    copy.className = className ?? this.className;
    copy.transferInfo = transferInfo ?? this.transferInfo;
    copy.clubs = clubs ?? this.clubs;
    copy.nicknames = nicknames ?? this.nicknames;
    copy.memoryKeywords = memoryKeywords ?? this.memoryKeywords;
    copy.interests = interests ?? this.interests;
    copy.email = email ?? this.email ?? (this.loginId.isNotEmpty ? this.loginId : null);
    return copy;
  }

  @override
  String toString() {
    return 'SignupFormData('
        'loginId: $loginId, '
        'phoneNumber: $phoneNumber, '
        'name: $name, '
        'gender: $gender, '
        'baseRegion: $baseRegion, '
        'schoolName: $schoolName, '
        'interests: ${interests ?? []}'
        ')';
  }
}
