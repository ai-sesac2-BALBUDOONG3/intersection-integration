import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/main_tab_screen.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/data/user_storage.dart';

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

    final payload = {
      'name': name,
      'birth_year': birthYear,
      'region': region,
      'school_name': school,
    };

    // If we have an auth token, update the server-side profile. Otherwise
    // fall back to local-only behavior for quick demo/testing.
    if (AppState.token != null) {
      ApiService.updateMyInfo(payload).then((resp) async {
        // resp contains updated user info — map to User and store
        final user = User.fromJson(resp);
        AppState.currentUser = user;
        // optional: save to local storage
        await UserStorage.save(user);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainTabScreen()),
          (route) => false,
        );
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 업데이트 실패: $e')),
        );
      });
    } else {
      final me = User(
        id: AppState.allUsers.length + 1,
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
