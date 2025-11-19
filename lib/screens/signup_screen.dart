import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/main_tab_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _schoolController = TextEditingController();
  final _birthYearController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _schoolController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final name = _nameController.text.trim();
    final region = _regionController.text.trim();
    final school = _schoolController.text.trim();
    final birthYearText = _birthYearController.text.trim();

    if (name.isEmpty ||
        region.isEmpty ||
        school.isEmpty ||
        birthYearText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 정보를 입력해줘.')),
      );
      return;
    }

    final birthYear = int.tryParse(birthYearText);
    if (birthYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출생연도는 숫자로 입력해줘.')),
      );
      return;
    }

    final me = User(
      id: 'me',
      name: name,
      birthYear: birthYear,
      region: region,
      school: school,
    );

    AppState.currentUser = me;
    AppState.allUsers.add(me);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보 입력',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'intersection 추천친구 / 커뮤니티 기준이 될 정보를 입력해줘.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름 (실명)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _regionController,
              decoration: const InputDecoration(
                labelText: '지역 (예: 서울 강서구)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _schoolController,
              decoration: const InputDecoration(
                labelText: '학교 (예: A초등학교)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _birthYearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '출생연도 (예: 1998)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onSubmit,
                child: const Text('완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
