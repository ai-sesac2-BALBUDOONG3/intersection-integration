import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // CupertinoPicker 사용을 위해 추가
import 'package:intersection/data/signup_form_data.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/data/user_storage.dart';
import 'package:intersection/screens/main_tab_screen.dart';

class SignupStep4Screen extends StatefulWidget {
  final SignupFormData data;

  const SignupStep4Screen({super.key, required this.data});

  @override
  State<SignupStep4Screen> createState() => _SignupStep4ScreenState();
}

class _SignupStep4ScreenState extends State<SignupStep4Screen> {
  late TextEditingController schoolNameController;
  late TextEditingController entryYearController;
  String? selectedSchoolLevel;

  late TextEditingController nicknamesController;
  late TextEditingController memoryKeywordsController;
  late TextEditingController interestsController;

  bool hasTransferInfo = false;
  late TextEditingController transferInfoController;

  final List<String> schoolLevels = ['초등학교', '중학교', '고등학교'];

  @override
  void initState() {
    super.initState();
    schoolNameController = TextEditingController(text: widget.data.schoolName);
    entryYearController = TextEditingController(text: widget.data.entryYear);
    selectedSchoolLevel =
        widget.data.schoolLevel.isNotEmpty ? widget.data.schoolLevel : null;

    nicknamesController =
        TextEditingController(text: widget.data.nicknames ?? '');
    memoryKeywordsController =
        TextEditingController(text: widget.data.memoryKeywords ?? '');
    interestsController =
        TextEditingController(text: (widget.data.interests ?? []).join(', '));

    hasTransferInfo = widget.data.transferInfo?.isNotEmpty == true;
    transferInfoController =
        TextEditingController(text: widget.data.transferInfo ?? '');
  }

  @override
  void dispose() {
    schoolNameController.dispose();
    entryYearController.dispose();
    nicknamesController.dispose();
    memoryKeywordsController.dispose();
    interestsController.dispose();
    transferInfoController.dispose();
    super.dispose();
  }

  // 🎡 입학년도 선택 다이얼로그
  void _showEntryYearPicker() {
    final currentYear = DateTime.now().year;
    // 1980년 ~ 현재 연도까지 리스트 생성
    final years = List<String>.generate(
      currentYear - 1980 + 1,
      (index) => (1980 + index).toString(),
    ).reversed.toList(); // 최신 연도가 위로 오게

    // 초기 선택값 인덱스 찾기
    int initialIndex = 0;
    if (entryYearController.text.isNotEmpty) {
      initialIndex = years.indexOf(entryYearController.text);
      if (initialIndex == -1) initialIndex = 0;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              // 상단 완료 버튼
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "완료",
                    style: TextStyle(
                      color: Colors.blue, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16
                    ),
                  ),
                ),
              ),
              // 휠 피커
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      entryYearController.text = years[index];
                    });
                  },
                  children: years.map((year) => Center(child: Text(year))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _canProceed() {
    return selectedSchoolLevel != null &&
        schoolNameController.text.isNotEmpty &&
        entryYearController.text.isNotEmpty;
  }

  Future<void> _submitSignup() async {
    final form = widget.data;

    final birthYear = int.tryParse(form.birthYear);
    final currentYear = DateTime.now().year;

    if (birthYear == null || birthYear < 1900 || birthYear > currentYear) {
      _showError('출생년도를 올바르게 입력해주세요.');
      return;
    }

    final admissionYear = int.tryParse(entryYearController.text);
    if (admissionYear == null) {
      _showError('입학년도를 올바르게 입력해주세요.');
      return;
    }

    final payload = {
      'login_id': form.loginId,
      'email': form.loginId,
      'password': form.password,
      'name': form.name,
      'birth_year': birthYear,
      'gender': form.gender.isNotEmpty ? form.gender : null,
      'region': form.baseRegion,
      'school_name': schoolNameController.text,
      'school_type': selectedSchoolLevel,
      'admission_year': admissionYear,
    };

    try {
      await ApiService.signup(payload);

      if (!mounted) return;

      // 신규 사용자 플래그 ON
      AppState.isNewUser = true;

      // 자동 로그인
      try {
        final token = await ApiService.login(form.loginId, form.password);
        AppState.token = token;

        final user = await ApiService.getMyInfo();
        await AppState.login(token, user);
      } catch (e) {
        debugPrint("자동 로그인 실패: $e");
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('회원가입 완료'),
          content: const Text('intersection에 오신 것을 환영합니다!'),
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainTabScreen(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입 - 4단계')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('학교 정보 입력',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const Text('학교급',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSchoolLevel,
                    hint: const Text('초/중/고'),
                    items: schoolLevels
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedSchoolLevel = v),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 학교명 (자동완성)
                  const Text('학교명',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          return await ApiService.searchSchools(textEditingValue.text);
                        },
                        onSelected: (String selection) {
                          schoolNameController.text = selection;
                          setState(() {}); 
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          if (schoolNameController.text.isNotEmpty && 
                              controller.text.isEmpty) {
                            controller.text = schoolNameController.text;
                          }
                          controller.addListener(() {
                            schoolNameController.text = controller.text;
                            setState(() {}); 
                          });

                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            decoration: InputDecoration(
                              hintText: '예: OO초등학교',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.location_city_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: constraints.maxWidth,
                                color: Colors.white,
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(option),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),

                  // 🔥 [수정] 입학년도 (휠 피커 적용)
                  const Text('입학년도',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showEntryYearPicker, // 탭하면 휠 피커 열기
                    child: AbsorbPointer(
                      child: TextField(
                        controller: entryYearController,
                        decoration: InputDecoration(
                          hintText: '연도 선택',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.calendar_month_outlined),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(height: 32),

                  const Text('추가 정보 (선택사항)',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const Text('별명들 (선택사항)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nicknamesController,
                    decoration: InputDecoration(
                      hintText: '예: 철수, 공대로봇',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon:
                          const Icon(Icons.person_pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('기억 키워드 (선택사항)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: memoryKeywordsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '예: 운동회, 소풍, 학교축제',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.favorite_border),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('관심사 (선택사항)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: interestsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '예: 만화, 야구, 힙합',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.star_border),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canProceed() ? _submitSignup : null,
                child: const Text('회원가입 완료'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}