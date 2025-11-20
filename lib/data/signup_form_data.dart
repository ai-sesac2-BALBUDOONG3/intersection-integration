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

  @override
  String toString() {
    return 'SignupFormData('
        'loginId: $loginId, '
        'phoneNumber: $phoneNumber, '
        'name: $name, '
        'gender: $gender, '
        'baseRegion: $baseRegion, '
        'schoolName: $schoolName'
        ')';
  }
}
