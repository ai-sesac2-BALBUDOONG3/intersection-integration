import 'package:flutter/material.dart';
import 'package:intersection/data/signup_form_data.dart';

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
    // 마지막의 '\$'를 '$'로 수정했습니다.
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
          // 진행도 표시 (이제 1/3 로 변경)
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
                      '단계 1/3',
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
                    tween: Tween(begin: 0.0, end: 0.33),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    builder: (_, value, __) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.black),
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

                  // 이메일
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
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),

                  // 비밀번호
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
                    onChanged: (_) => setState(() {}),
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
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // 약관
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: agreedToTerms,
                          onChanged: (v) => setState(() => agreedToTerms = v ?? false),
                          title: Row(
                            children: [
                              const Expanded(
                                child: Text('서비스 이용약관 동의'),
                              ),
                              TextButton(
                                onPressed: () => _showTermsDialog(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 30),
                                ),
                                child: Text(
                                  '보기',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        Divider(height: 1, color: Colors.grey.shade300),
                        CheckboxListTile(
                          value: agreedToPrivacy,
                          onChanged: (v) => setState(() => agreedToPrivacy = v ?? false),
                          title: Row(
                            children: [
                              const Expanded(
                                child: Text('개인정보 처리방침 동의'),
                              ),
                              TextButton(
                                onPressed: () => _showPrivacyDialog(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 30),
                                ),
                                child: Text(
                                  '보기',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ⭐ Step2 삭제 → Step3로 바로 이동
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProceed()
                          ? () {
                              final formData = (widget.initialData ??
                                      SignupFormData())
                                  .copyWith(
                                loginId: loginIdController.text,
                                password: passwordController.text,
                              );

                              Navigator.pushNamed(
                                context,
                                '/signup/step3',
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

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      '서비스 이용약관',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        '제1장 서비스 개요',
                        'intersection(이하 "인터섹션")은 학교, 지역, 나이 등 공통의 추억을 공유하는 사람들을 연결하는 소셜 네트워크 플랫폼입니다. 본 약관은 서비스 이용에 관한 이용자와 서비스 제공자 간의 권리와 의무를 규정합니다.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제2장 서비스 이용',
                        '• 본 서비스는 만 14세 이상의 회원에게 제공됩니다.\n• 회원은 본인의 실명과 정확한 정보를 입력해야 합니다.\n• 회원은 타인의 개인정보를 무단으로 수집, 사용할 수 없습니다.\n• 회원은 서비스를 불법적인 목적으로 사용할 수 없습니다.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제3장 계정 관리',
                        '• 회원은 계정의 보안을 유지할 책임이 있습니다.\n• 계정 정보가 누출되었을 경우 즉시 비밀번호를 변경해야 합니다.\n• 회원 탈퇴 시 모든 게시글과 댓글은 삭제됩니다.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제4장 커뮤니티 규칙',
                        '• 폭력적, 협오적, 음란적 콘텐츠 게시 금지\n• 타인을 모욕, 비방, 험담하는 행위 금지\n• 상업적 광고 및 스팸 게시 금지\n• 위 규칙 위반 시 경고 없이 게시글 삭제 및 계정 정지 가능',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제5장 저작권 및 책임',
                        '• 회원이 게시한 콘텐츠의 저작권은 회원에게 있습니다.\n• 회원은 게시한 콘텐츠에 대한 법적 책임을 집니다.\n• 서비스는 회원의 콘텐츠를 서비스 홍보 목적으로 사용할 수 있습니다.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제6장 서비스 변경 및 중단',
                        '• 서비스는 기술적, 운영상 필요에 따라 변경될 수 있습니다.\n• 중대한 변경 사항은 사전에 공지합니다.\n• 서비스는 불가피한 사유로 중단될 수 있으며, 이로 인한 손해에 대해 책임지지 않습니다.',
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      '개인정보 처리방침',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        '제1조 개인정보의 수집 및 이용 목적',
                        'intersection은 다음과 같은 목적으로 회원들의 개인정보를 수집합니다:\n\n• 회원 가입 및 신원 확인\n• 서비스 제공 및 개인화된 추천\n• 학교, 지역, 나이 기반 친구 매칭\n• 커뮤니티 게시글 및 댓글 관리\n• 부정 이용 방지 및 공지사항 전달',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제2조 수집하는 개인정보 항목',
                        '• 필수 정보: 이름, 이메일, 비밀번호, 휴대전화번호, 성별, 출생년도\n• 부가 정보: 닉네임, 지역, 학교명, 학교 종류, 입학년도\n• 프로필 정보: 프로필 사진, 배경 사진, 피드 이미지\n• 서비스 이용 기록: IP 주소, 접속 로그, 기기 정보',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제3조 개인정보의 보유 및 이용 기간',
                        '• 회원 탈퇴 시까지 보유\n• 관계 법령에 따른 보존 의무가 있는 경우 해당 기간까지 보유\n• 회원 탈퇴 후에도 부정 이용 방지를 위해 최소 30일간 보관',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제4조 개인정보의 제3자 제공',
                        '원칙적으로 회원의 개인정보를 제3자에게 제공하지 않습니다. 다만, 다음의 경우에는 예외로 합니다:\n\n• 회원의 동의가 있는 경우\n• 법률에 특별한 규정이 있는 경우\n• 수사 기관의 요청이 있는 경우',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제5조 개인정보의 파기 및 삭제',
                        '• 회원은 서비스 내에서 언제든 개인정보를 조회, 수정할 수 있습니다.\n• 회원 탈퇴는 마이페이지에서 가능합니다.\n• 탈퇴 시 모든 개인정보는 즉시 파기되며, 법령에 따라 보존해야 하는 정보는 별도로 분리 보관됩니다.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제6조 개인정보 보호 조치',
                        '• 비밀번호는 암호화되어 저장됩니다.\n• 개인정보는 안전한 서버에 저장되며, 접근 권한이 제한됩니다.\n• 정기적인 보안 점검을 실시합니다.\n• 개인정보 침해 사고 발생 시 즉시 통지합니다.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        '제7조 문의',
                        '개인정보 처리에 관한 문의는 서비스 내 문의하기를 통해 주시기 바랍니다.\n\n본 방침은 2024년 1월 1일부터 시행됩니다.',
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
