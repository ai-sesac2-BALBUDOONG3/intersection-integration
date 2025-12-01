import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intersection/config/api_config.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/screens/main_tab_screen.dart';
import 'package:intersection/screens/signup/signup_screen.dart';
import 'package:intersection/services/api_service.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이메일과 비밀번호를 입력해주세요")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // -----------------------------------------
      // 1) 로그인 → 토큰 획득
      // -----------------------------------------
      final token = await ApiService.login(email, password);
      AppState.token = token;

      // -----------------------------------------
      // 2) 로그인 후 내 정보 불러오기
      // -----------------------------------------
      final user = await ApiService.getMyInfo();

      // -----------------------------------------
      // 3) AppState에 로그인 정보 적용
      // -----------------------------------------
      await AppState.login(token, user);   // ⭐ await 추가됨 ⭐

      if (!mounted) return;

      setState(() => _isLoading = false);

      // -----------------------------------------
      // 4) 메인 화면 이동
      // -----------------------------------------
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainTabScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("로그인 실패: $e")),
      );
    }
  }
  // ----------------------------------------------------
  // Kakao OAuth flow (flutter_web_auth)
  // ----------------------------------------------------
  Future<void> _kakaoLoginReal() async {
    setState(() => _isLoading = true);

    try {
      final url = kIsWeb
          ? Uri.parse('${ApiConfig.baseUrl}/auth/kakao/login')
          : Uri.parse(
              '${ApiConfig.baseUrl}/auth/kakao/login?client_redirect=${Uri.encodeComponent('intersection://oauth')}',
            );

      final result = await FlutterWebAuth.authenticate(
          url: url.toString(),
          callbackUrlScheme: kIsWeb ? 'http' : 'intersection');

      final uri = Uri.parse(result);
      String token = '';

      if (uri.fragment.isNotEmpty) {
        final params = Uri.splitQueryString(uri.fragment);
        token = params['access_token'] ?? '';
      } else if (uri.queryParameters.containsKey('access_token')) {
        token = uri.queryParameters['access_token']!;
      }

      if (token.isEmpty) throw Exception('토큰을 받지 못했습니다');

      AppState.token = token;

      try {
        final user = await ApiService.getMyInfo();

        // ⭐ await 추가
        await AppState.login(token, user);

        if (!mounted) return;
        setState(() => _isLoading = false);

        final needsProfile =
            user.birthYear == 0 || user.region.isEmpty || user.school.isEmpty;

        if (needsProfile) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SignupScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const MainTabScreen(initialIndex: 1),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('카카오 로그인 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "이메일",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "비밀번호",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("로그인"),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _isLoading ? null : _kakaoLoginReal,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("카카오로 로그인"),
              ),
            ),
            
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SignupScreen(),
                  ),
                );
              },
              child: const Text(
                "아직 계정이 없나요? 회원가입",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
