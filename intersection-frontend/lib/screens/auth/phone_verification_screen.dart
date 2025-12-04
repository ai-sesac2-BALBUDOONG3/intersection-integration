import 'package:flutter/material.dart';
import 'package:intersection/data/signup_form_data.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  // '010-'을 초기값으로 설정 (이것만 있으면 됩니다)
  final _phoneController = TextEditingController(text: '010-');
  final _codeController = TextEditingController();

  bool _codeSent = false;
  bool _isVerifying = false;

  // '010-' 접두사 길이
  static const int _fixedPrefixLength = 4;

  @override
  void initState() {
    super.initState();
    // 커서를 '010-' 뒤로 이동
    _phoneController.selection = const TextSelection.collapsed(offset: _fixedPrefixLength);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll('-', '').replaceAll(' ', '');
    return cleaned.startsWith('010') && cleaned.length == 11 && int.tryParse(cleaned) != null;
  }

  void _formatPhoneNumber(String value) {
    // 1. 숫자만 남기기
    String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. '010'이 없으면 강제로 붙이기
    if (!cleaned.startsWith('010')) {
      if (cleaned.length >= 3) {
        cleaned = '010${cleaned.substring(3)}';
      } else {
        cleaned = '010';
      }
    }

    // 3. 010 뒤의 숫자만 추출
    String body = cleaned.substring(3);
    if (body.length > 8) {
      body = body.substring(0, 8);
    }

    // 4. 포맷팅
    String formatted = '010-';
    if (body.length <= 4) {
      formatted += body;
    } else {
      formatted += '${body.substring(0, 4)}-${body.substring(4)}';
    }

    // 5. 커서 위치 계산
    final currentSelectionOffset = _phoneController.selection.end;
    final int newOffset;

    // 사용자가 '010-'을 지우려 하거나 커서를 앞으로 옮기려 할 때 방지
    if (value.length < _fixedPrefixLength || currentSelectionOffset < _fixedPrefixLength) {
      newOffset = _fixedPrefixLength;
    } else {
      // 텍스트 끝으로 커서 이동 (입력 편의상)
      newOffset = formatted.length;
    }

    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.fromPosition(
        TextPosition(offset: newOffset),
      ),
    );

    setState(() {});
  }

  void _sendCode() {
    final phone = _phoneController.text.trim();

    if (!_isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 휴대폰 번호(010-XXXX-XXXX)를 입력해주세요.')),
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

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (code == '123456') {
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
          // 진행도 표시 등 상단 UI 생략 없이 그대로 유지
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
                  child: LinearProgressIndicator(
                    value: 0.0,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
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
                          onChanged: _formatPhoneNumber, // 입력 시 포맷팅 로직 실행
                          decoration: InputDecoration(
                            // 💡 수정됨: prefixText 삭제 (중복 원인 제거)
                            hintText: '1234-5678', // 010- 뒤에 올 숫자 예시
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.phone_outlined),
                            errorText: _phoneController.text.isNotEmpty &&
                                    !_isValidPhone(_phoneController.text)
                                ? '올바른 전화번호(010-XXXX-XXXX)를 입력해주세요'
                                : null,
                          ),
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
                        child: Text(_codeSent ? '발송됨' : '인증'),
                      ),
                    ],
                  ),

                  // 인증번호 입력 UI (애니메이션 등 유지)
                  if (_codeSent)
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '인증번호',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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
                            child: _isVerifying
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    '인증 완료하고 계속하기',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
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