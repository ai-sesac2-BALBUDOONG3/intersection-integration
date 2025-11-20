import 'package:flutter/material.dart';
import '../data/signup_form_data.dart';

class SignupStep4Screen extends StatefulWidget {
  final SignupFormData data;

  const SignupStep4Screen({
    super.key,
    required this.data,
  });

  @override
  State<SignupStep4Screen> createState() => _SignupStep4ScreenState();
}

class _SignupStep4ScreenState extends State<SignupStep4Screen> {
  late TextEditingController schoolNameController;
  late TextEditingController entryYearController;
  late TextEditingController nicknamesController;
  late TextEditingController memoryKeywordsController;
  String? selectedSchoolLevel;
  String? selectedClassName;
  bool hasTransferInfo = false;
  late TextEditingController transferInfoController;

  final List<String> schoolLevels = ['초등학교', '중학교', '고등학교'];
  final List<String> classNames = ['1학년', '2학년', '3학년', '4학년', '5학년', '6학년'];

  @override
  void initState() {
    super.initState();
    schoolNameController = TextEditingController(text: widget.data.schoolName);
    entryYearController = TextEditingController(text: widget.data.entryYear);
    nicknamesController = TextEditingController(text: widget.data.nicknames);
    memoryKeywordsController =
        TextEditingController(text: widget.data.memoryKeywords);
    selectedSchoolLevel =
        widget.data.schoolLevel.isNotEmpty ? widget.data.schoolLevel : null;
    selectedClassName =
        widget.data.className?.isNotEmpty == true ? widget.data.className : null;
    hasTransferInfo = widget.data.transferInfo?.isNotEmpty == true;
    transferInfoController =
        TextEditingController(text: widget.data.transferInfo);
  }

  @override
  void dispose() {
    schoolNameController.dispose();
    entryYearController.dispose();
    nicknamesController.dispose();
    memoryKeywordsController.dispose();
    transferInfoController.dispose();
    super.dispose();
  }

  bool _isValidYear(String year) {
    if (year.isEmpty) return false;
    final parsed = int.tryParse(year);
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed >= 1980 && parsed <= now.year;
  }

  bool _canProceed() {
    return schoolNameController.text.isNotEmpty &&
        _isValidYear(entryYearController.text) &&
        selectedSchoolLevel != null;
  }

  void _submitSignup() async {
    // 모든 데이터 저장
    widget.data.schoolName = schoolNameController.text;
    widget.data.entryYear = entryYearController.text;
    widget.data.schoolLevel = selectedSchoolLevel!;
    widget.data.className = selectedClassName;
    if (hasTransferInfo) {
      widget.data.transferInfo = transferInfoController.text;
    }
    widget.data.nicknames = nicknamesController.text;
    widget.data.memoryKeywords = memoryKeywordsController.text;

    // 회원가입 완료
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입 완료'),
        content: const Text('회원가입이 완료되었습니다!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입 - 4단계'),
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
                    const Text(
                      '진행도',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '단계 4/4',
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
                    tween: Tween(begin: 0.75, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.black,
                        ),
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
                    '학교 정보 입력',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '다니셨던 학교 정보를 입력해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  // 학교급
                  const Text(
                    '학교급',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSchoolLevel,
                    hint: const Text('학교급을 선택해주세요'),
                    items: schoolLevels
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedSchoolLevel = value),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 학교명
                  const Text(
                    '학교명',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: schoolNameController,
                    decoration: InputDecoration(
                      hintText: '예: OO초등학교',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  // 입학년도
                  const Text(
                    '입학년도',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: entryYearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '2010',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      errorText: entryYearController.text.isNotEmpty &&
                              !_isValidYear(entryYearController.text)
                          ? '올바른 연도를 입력해주세요'
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  // 학년 (선택사항)
                  const Text(
                    '학년 (선택사항)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedClassName,
                    hint: const Text('학년을 선택해주세요'),
                    items: classNames
                        .map(
                          (className) => DropdownMenuItem(
                            value: className,
                            child: Text(className),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedClassName = value),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 전학 여부
                  CheckboxListTile(
                    value: hasTransferInfo,
                    onChanged: (value) =>
                        setState(() => hasTransferInfo = value ?? false),
                    title: const Text('전학을 가신 경험이 있으신가요?'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (hasTransferInfo) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: transferInfoController,
                      decoration: InputDecoration(
                        hintText: '예: OO초등학교에서 OO중학교로 전학',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // 별명들
                  const Text(
                    '별명들 (선택사항)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nicknamesController,
                    decoration: InputDecoration(
                      hintText: '예: 철수, 공대로봇',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person_pin_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  // 기억에 남는 키워드
                  const Text(
                    '기억에 남는 키워드 (선택사항)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: memoryKeywordsController,
                    decoration: InputDecoration(
                      hintText: '예: 운동회, 소풍, 학교축제',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.favorite_border),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  // 네비게이션 버튼
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('이전'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canProceed() ? _submitSignup : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('회원가입 완료'),
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
