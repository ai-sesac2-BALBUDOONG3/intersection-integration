import 'package:flutter/material.dart';
import '../data/signup_form_data.dart';

class SignupStep1Screen extends StatefulWidget {
  final SignupFormData? initialData;

  const SignupStep1Screen({super.key, this.initialData});

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  late TextEditingController loginIdController;
  late TextEditingController passwordController;
  late TextEditingController passwordConfirmController;
  bool agreedToTerms = false;
  bool agreedToPrivacy = false;
  bool showPassword = false;
  bool showPasswordConfirm = false;

  @override
  void initState() {
    super.initState();
    loginIdController =
        TextEditingController(text: widget.initialData?.loginId ?? '');
    passwordController =
        TextEditingController(text: widget.initialData?.password ?? '');
    passwordConfirmController = TextEditingController();
  }

  @override
  void dispose() {
    loginIdController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8;
  }

  bool _canProceed() {
    return loginIdController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        passwordConfirmController.text.isNotEmpty &&
        agreedToTerms &&
        agreedToPrivacy &&
        _isValidEmail(loginIdController.text) &&
        _isValidPassword(passwordController.text) &&
        passwordController.text == passwordConfirmController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입 - 1단계'),
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
                      '단계 1/4',
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
                    tween: Tween(begin: 0.0, end: 0.25),
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
                    '계정 정보를 입력해주세요',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이메일과 비밀번호로 계정을 생성합니다',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  // 이메일 입력
                  const Text(
                    '이메일 (로그인 ID)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: loginIdController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: loginIdController.text.isNotEmpty &&
                              !_isValidEmail(loginIdController.text)
                          ? '올바른 이메일 형식을 입력해주세요'
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  // 비밀번호 입력
                  const Text(
                    '비밀번호',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      hintText: '8자 이상의 비밀번호',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(showPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                      ),
                      errorText: passwordController.text.isNotEmpty &&
                              !_isValidPassword(passwordController.text)
                          ? '비밀번호는 8자 이상이어야 합니다'
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  // 비밀번호 확인
                  const Text(
                    '비밀번호 확인',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordConfirmController,
                    obscureText: !showPasswordConfirm,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 다시 입력해주세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(showPasswordConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => showPasswordConfirm = !showPasswordConfirm),
                      ),
                      errorText: passwordConfirmController.text.isNotEmpty &&
                              passwordController.text !=
                                  passwordConfirmController.text
                          ? '비밀번호가 일치하지 않습니다'
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  // 약관 동의
                  CheckboxListTile(
                    value: agreedToTerms,
                    onChanged: (value) =>
                        setState(() => agreedToTerms = value ?? false),
                    title: const Text('서비스 이용약관 동의'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: agreedToPrivacy,
                    onChanged: (value) =>
                        setState(() => agreedToPrivacy = value ?? false),
                    title: const Text('개인정보 처리방침 동의'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 32),
                  // 다음 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProceed()
                          ? () {
                              final formData =
                                  widget.initialData ?? SignupFormData();
                              formData.loginId = loginIdController.text;
                              formData.password = passwordController.text;
                              Navigator.pushNamed(
                                context,
                                '/signup/step2',
                                arguments: formData,
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '다음 단계로',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
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
