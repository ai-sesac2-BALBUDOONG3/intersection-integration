import 'package:flutter/material.dart';
import 'package:intersection/data/signup_form_data.dart';

class SignupStep3Screen extends StatefulWidget {
  final SignupFormData data;

  const SignupStep3Screen({
    super.key,
    required this.data,
  });

  @override
  State<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends State<SignupStep3Screen> {
  late TextEditingController nameController;
  late TextEditingController birthYearController;
  String? selectedGender;
  String? selectedRegion;

  final List<String> genders = ['남성', '여성'];
  final List<String> regions = [
    '서울', '부산', '대구', '인천', '광주', '대전', '울산',
    '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data.name);
    birthYearController = TextEditingController(text: widget.data.birthYear);
    selectedGender = widget.data.gender.isNotEmpty ? widget.data.gender : null;
    selectedRegion =
        widget.data.baseRegion.isNotEmpty ? widget.data.baseRegion : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    birthYearController.dispose();
    super.dispose();
  }

  bool _isValidBirthYear(String year) {
    if (year.isEmpty) return false;
    final parsed = int.tryParse(year);
    if (parsed == null) return false;
    final now = DateTime.now().year;
    return parsed >= 1900 && parsed <= now - 14; // 최소 만 14세
  }

  bool _canProceed() {
    return nameController.text.isNotEmpty &&
        _isValidBirthYear(birthYearController.text) &&
        selectedGender != null &&
        selectedRegion != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입 - 2단계'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 진행도 표시
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('진행도', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '단계 2/3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.33, end: 0.66),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    builder: (_, value, __) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Colors.black),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '기본 정보 입력',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이름, 생년도, 성별, 기본 지역을 입력해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // 이름
                  const Text('이름', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: '예: 김철수',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // 생년
                  const Text('생년도', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: birthYearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '1990',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      errorText: birthYearController.text.isNotEmpty &&
                              !_isValidBirthYear(birthYearController.text)
                          ? '1900~${DateTime.now().year - 14}년 사이의 연도를 입력해주세요'
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // 성별
                  const Text('성별', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    hint: const Text('성별을 선택해주세요'),
                    items: genders
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedGender = v),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.wc_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 지역
                  const Text('기본 지역', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRegion,
                    hint: const Text('지역을 선택해주세요'),
                    items: regions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedRegion = v),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 다음 버튼
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('이전'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canProceed()
                              ? () {
                                  widget.data.name = nameController.text;
                                  widget.data.birthYear =
                                      birthYearController.text;
                                  widget.data.gender = selectedGender!;
                                  widget.data.baseRegion = selectedRegion!;

                                  Navigator.pushNamed(
                                    context,
                                    '/signup/step4',
                                    arguments: widget.data,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('다음'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
