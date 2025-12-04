import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/data/user_storage.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/auth/landing_screen.dart';
import 'package:intersection/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // 기본 정보
  late TextEditingController nameController;
  late TextEditingController nicknameController;
  late TextEditingController regionController;
  late TextEditingController schoolNameController;
  late TextEditingController schoolTypeController;

  // 연도 관련
  late TextEditingController birthYearController; // 출생년도
  late TextEditingController admissionYearController; // 입학년도

  // 성별 선택
  String? genderValue; // 'male' | 'female' | 'other' | null

  @override
  void initState() {
    super.initState();
    final user = AppState.currentUser!;

    nameController = TextEditingController(text: user.name);
    nicknameController = TextEditingController(text: user.nickname ?? "");
    regionController = TextEditingController(text: user.region);
    schoolNameController = TextEditingController(text: user.school);
    schoolTypeController = TextEditingController(text: user.schoolType ?? "");

    birthYearController = TextEditingController(text: user.birthYear.toString());
    admissionYearController =
      TextEditingController(text: user.admissionYear?.toString() ?? "");

    genderValue = user.gender; // 서버 값 사용
  }

  @override
  void dispose() {
    nameController.dispose();
    nicknameController.dispose();
    regionController.dispose();
    schoolNameController.dispose();
    schoolTypeController.dispose();
    birthYearController.dispose();
    admissionYearController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = AppState.currentUser!;

    // 1) 서버 업데이트 (가능한 필드만 전송)
    final payload = <String, dynamic>{
      "name": nameController.text.trim(),
      if (nicknameController.text.trim().isNotEmpty)
        "nickname": nicknameController.text.trim(),
      if (birthYearController.text.trim().isNotEmpty)
        "birth_year": int.tryParse(birthYearController.text.trim()),
      if (genderValue != null && genderValue!.isNotEmpty) "gender": genderValue,
      if (regionController.text.trim().isNotEmpty)
        "region": regionController.text.trim(),
      if (schoolNameController.text.trim().isNotEmpty)
        "school_name": schoolNameController.text.trim(),
      if (schoolTypeController.text.trim().isNotEmpty)
        "school_type": schoolTypeController.text.trim(),
      if (admissionYearController.text.trim().isNotEmpty)
        "admission_year":
            int.tryParse(admissionYearController.text.trim()),
    };

    try {
      await ApiService.updateMyInfo(payload);

      // 2) 로컬 메모리/스토리지 동기화 (현재 모델이 가진 필드만 반영)
        final updated = User(
        id: user.id,
        name: nameController.text.trim().isEmpty
            ? user.name
            : nameController.text.trim(),
        nickname: nicknameController.text.trim().isEmpty
          ? user.nickname
          : nicknameController.text.trim(),
        birthYear: int.tryParse(birthYearController.text.trim()) ??
            user.birthYear,
        gender: (genderValue == null || genderValue!.isEmpty)
          ? user.gender
          : genderValue,
        region: regionController.text.trim().isEmpty
            ? user.region
            : regionController.text.trim(),
        school: schoolNameController.text.trim().isEmpty
            ? user.school
            : schoolNameController.text.trim(),
        schoolType: schoolTypeController.text.trim().isEmpty
          ? user.schoolType
          : schoolTypeController.text.trim(),
        admissionYear: int.tryParse(admissionYearController.text.trim()) ??
          user.admissionYear,
        profileImageUrl: user.profileImageUrl,
        backgroundImageUrl: user.backgroundImageUrl,
        profileImageBytes: user.profileImageBytes,
        backgroundImageBytes: user.backgroundImageBytes,
        profileFeedImages: user.profileFeedImages,
      );

      AppState.currentUser = updated;
      await UserStorage.save(updated);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "프로필 수정",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // 기본 정보 섹션
          _buildSection(
            title: "기본 정보",
            children: [
              _buildField("이름", nameController),
              const SizedBox(height: 16),
              _buildField("닉네임", nicknameController),
              const SizedBox(height: 16),
              _buildReadOnlyField(
                label: "성별",
                value: _genderDisplay(genderValue),
                helper: "성별은 변경할 수 없어요",
              ),
              const SizedBox(height: 16),
              _buildField("출생년도", birthYearController, number: true),
            ],
          ),
          const SizedBox(height: 20),
          // 학교 정보 섹션
          _buildSection(
            title: "학교 정보",
            children: [
              _buildField("지역", regionController),
              const SizedBox(height: 16),
              _buildField("학교명", schoolNameController),
              const SizedBox(height: 16),
              _buildField("학교구분", schoolTypeController,
                  hint: '예: 고등학교, 대학교 등'),
              const SizedBox(height: 16),
              _buildField("입학년도", admissionYearController, number: true),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveProfile,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black87),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                elevation: MaterialStateProperty.all(6),
                shadowColor: MaterialStateProperty.all(Colors.black54),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                textStyle: MaterialStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              child: const Text("저장"),
            ),
          ),

          const SizedBox(height: 40),
// 🗑️ 회원탈퇴 버튼 추가
          Center(
            child: TextButton(
              onPressed: () => _showWithdrawConfirmDialog(context),
              child: Text(
                "회원탈퇴",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  decoration: TextDecoration.underline, // 밑줄 추가
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool number = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black87, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  String _genderDisplay(String? code) {
    if (code == null || code.isEmpty) {
      return '-';
    }
    switch (code) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      case 'other':
        return '기타';
      default:
        return code; // 회원가입 시 입력한 값 그대로 표시
    }
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                helper,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ]
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: items,
            onChanged: enabled ? onChanged : null,
            hint: const Text('선택'),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '정말 로그아웃 하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "취소",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await AppState.logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LandingScreen()),
                            (route) => false,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "로그아웃",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
// 🗑️ 회원탈퇴 확인 다이얼로그
  void _showWithdrawConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded, // 경고 아이콘
                    size: 40,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '회원탈퇴',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '정말 탈퇴하시겠습니까?\n작성한 게시글, 친구 관계 등\n모든 데이터가 삭제되며 복구할 수 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "취소",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          // 다이얼로그 닫기
                          Navigator.of(dialogContext).pop();
                          
                          try {
                            // 1. 서버에 탈퇴 요청
                            final success = await ApiService.withdrawAccount();
                            
                            if (success) {
                              // 2. 앱 내 데이터 초기화 (로그아웃과 동일)
                              await AppState.logout();
                              
                              if (!context.mounted) return;
                              
                              // 3. 로그인 화면(랜딩 페이지)으로 이동
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LandingScreen()),
                                (route) => false,
                              );
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                              );
                            } else {
                              throw Exception("서버 응답 오류");
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('회원탈퇴 실패: $e')),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade600, // 더 진한 빨강
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "탈퇴하기",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
