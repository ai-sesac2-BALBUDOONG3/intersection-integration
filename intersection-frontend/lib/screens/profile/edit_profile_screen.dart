import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/data/user_storage.dart';
import 'package:intersection/models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController regionController;
  late TextEditingController schoolController;
  late TextEditingController yearController;

  @override
  void initState() {
    super.initState();
    final user = AppState.currentUser!;

    nameController = TextEditingController(text: user.name);
    regionController = TextEditingController(text: user.region);
    schoolController = TextEditingController(text: user.school);
    yearController = TextEditingController(text: user.birthYear.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    regionController.dispose();
    schoolController.dispose();
    yearController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = AppState.currentUser!;
    final updated = User(
      id: user.id,
      name: nameController.text,
      birthYear: int.tryParse(yearController.text) ?? user.birthYear,
      region: regionController.text,
      school: schoolController.text,
    );

    // 메모리 업데이트
    AppState.currentUser = updated;

    // 로컬 저장
    await UserStorage.save(updated);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("프로필 수정")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildField("이름", nameController),
            const SizedBox(height: 16),
            _buildField("지역", regionController),
            const SizedBox(height: 16),
            _buildField("학교", schoolController),
            const SizedBox(height: 16),
            _buildField("입학년도", yearController, number: true),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveProfile,
                child: const Text("저장"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool number = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
