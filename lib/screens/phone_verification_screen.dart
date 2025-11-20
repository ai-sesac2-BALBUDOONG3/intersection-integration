import 'package:flutter/material.dart';
import 'package:intersection/data/signup_form_data.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _codeSent = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll('-', '').replaceAll(' ', '');
    return cleaned.length >= 10 && cleaned.length <= 11 && int.tryParse(cleaned) != null;
  }

  void _formatPhoneNumber(String value) {
    final cleaned = value.replaceAll('-', '').replaceAll(' ', '');
    String formatted = '';

    if (cleaned.length <= 3) {
      formatted = cleaned;
    } else if (cleaned.length <= 7) {
      formatted = '${cleaned.substring(0, 3)}-${cleaned.substring(3)}';
    } else {
      formatted = '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7, 11)}';
    }

    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      ),
    );
  }

  void _sendCode() {
    final phone = _phoneController.text.trim();

    if (!_isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 휴대폰 번호를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _codeSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('인증번호가 발송되었습니다. (테스트: 123456)'),
      ),
    );
  }

  Future<void> _verifyAndNext() async {
    if (!_codeSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 인증번호를 받아주세요.')),
      );
      return;
    }

    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // 인증번호 검증 (실제로는 서버에서)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (code == '123456') {
      // 인증 성공 → 회원가입 step1로 이동
      final formData = SignupFormData();
      formData.phoneNumber = _phoneController.text;
      formData.isPhoneVerified = true;

      Navigator.pushReplacementNamed(
        context,
        '/signup/step1',
        arguments: formData,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호가 올바르지 않습니다.')),
      );
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('휴대폰 인증'),
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
                      '단계 0/5',
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
                    tween: Tween(begin: 0.0, end: 0.0),
                    duration: const Duration(milliseconds: 400),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '휴대폰 번호로 인증하세요',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '가입 시 입력하신 휴대폰 번호로 인증번호가 발송됩니다',
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
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !_codeSent,
                          decoration: InputDecoration(
                            hintText: '010-1234-5678',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.phone_outlined),
                            errorText: _phoneController.text.isNotEmpty &&
                                    !_isValidPhone(_phoneController.text)
                                ? '올바른 전화번호를 입력해주세요'
                                : null,
                          ),
                          onChanged: _formatPhoneNumber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _codeSent ? null : _sendCode,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Text(
                            _codeSent ? '발송됨' : '인증',
                            key: ValueKey<bool>(_codeSent),
                          ),
                        ),
                      ),
                    ],
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offsetAnimation, child: child),
                      );
                    },
                    child: _codeSent
                        ? Column(
                            key: const ValueKey('code_sent'),
                            children: [
                              const SizedBox(height: 20),
                              // 인증번호 입력
                              const Text(
                                '인증번호',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  hintText: '6자리 숫자',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.security_outlined),
                                  counterText: '',
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                              const SizedBox(height: 32),
                              // 다음 버튼
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _codeController.text.length == 6 && !_isVerifying
                                      ? _verifyAndNext
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                                    child: _isVerifying
                                        ? const SizedBox(
                                            key: ValueKey('verifying'),
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            '인증 완료하고 계속하기',
                                            key: ValueKey('verify_text'),
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
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
