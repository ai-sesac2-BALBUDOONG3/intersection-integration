import 'package:flutter/material.dart';
import '../data/signup_form_data.dart';

class SignupStep2Screen extends StatefulWidget {
  final SignupFormData data;

  const SignupStep2Screen({
    super.key,
    required this.data,
  });

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  late TextEditingController phoneController;
  bool isPhoneVerified = false;
  String? verificationCode;
  bool showVerificationInput = false;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: widget.data.phoneNumber);
    isPhoneVerified = widget.data.isPhoneVerified;
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll('-', '');
    return cleaned.length >= 10 && cleaned.length <= 11;
  }

  void _formatPhoneNumber(String value) {
    final cleaned = value.replaceAll('-', '');
    String formatted = '';

    if (cleaned.length <= 3) {
      formatted = cleaned;
    } else if (cleaned.length <= 7) {
      formatted = '${cleaned.substring(0, 3)}-${cleaned.substring(3)}';
    } else {
      formatted = '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }

    phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      ),
    );
  }

  void _requestVerification() {
    if (!_isValidPhone(phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 전화번호를 입력해주세요')),
      );
      return;
    }
    setState(() => showVerificationInput = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증번호가 발송되었습니다')),
    );
  }

  bool _canProceed() {
    return _isValidPhone(phoneController.text) && isPhoneVerified;
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
                    const Text(
                      '진행도',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '단계 2/4',
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
                    tween: Tween(begin: 0.25, end: 0.5),
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
                    '휴대폰 번호 인증',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '휴대폰 번호를 입력하고 인증해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  // 휴대폰 번호 입력
                  const Text(
                    '휴대폰 번호',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !isPhoneVerified,
                          decoration: InputDecoration(
                            hintText: '010-1234-5678',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.phone_outlined),
                            errorText: phoneController.text.isNotEmpty &&
                                    !_isValidPhone(phoneController.text)
                                ? '올바른 전화번호를 입력해주세요'
                                : null,
                          ),
                          onChanged: _formatPhoneNumber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isPhoneVerified ? null : _requestVerification,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(isPhoneVerified ? '인증됨' : '인증'),
                      ),
                    ],
                  ),
                  if (showVerificationInput) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '인증번호',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              hintText: '인증번호 6자리',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              counterText: '',
                            ),
                            onChanged: (value) => verificationCode = value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (verificationCode?.length == 6) {
                              setState(() => isPhoneVerified = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('휴대폰 인증이 완료되었습니다')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('인증번호를 정확히 입력해주세요')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  ],
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
                          onPressed: _canProceed()
                              ? () {
                                  widget.data.phoneNumber =
                                      phoneController.text;
                                  widget.data.isPhoneVerified =
                                      isPhoneVerified;
                                  Navigator.pushNamed(
                                    context,
                                    '/signup/step3',
                                    arguments: widget.data,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
