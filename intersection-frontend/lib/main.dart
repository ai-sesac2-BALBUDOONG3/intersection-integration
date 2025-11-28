import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/data/signup_form_data.dart';
import 'package:intersection/data/user_storage.dart';

// Screens
import 'package:intersection/screens/auth/landing_screen.dart';
import 'package:intersection/screens/main_tab_screen.dart';
import 'package:intersection/screens/auth/phone_verification_screen.dart';
import 'package:intersection/screens/signup/signup_step1_screen.dart';
import 'package:intersection/screens/signup/signup_step3_screen.dart';
import 'package:intersection/screens/signup/signup_step4_screen.dart';
import 'package:intersection/screens/friends/recommended_screen.dart';
import 'package:intersection/screens/auth/login_screen.dart';
import 'package:intersection/screens/friends/friends_screen.dart';
import 'package:intersection/screens/community/comment_screen.dart';
import 'package:intersection/screens/community/community_write_screen.dart';
import 'package:intersection/screens/common/report_screen.dart';

import 'package:intersection/models/post.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 자동 로그인 복원
  AppState.currentUser = await UserStorage.load();

  runApp(const IntersectionApp());
}

class IntersectionApp extends StatelessWidget {
  const IntersectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'intersection',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.black87,
          onSecondary: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          background: Color(0xFFF7F7F7),
          onBackground: Colors.black,
        ),

        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.black87),
          titleSmall: TextStyle(color: Colors.black54),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black, width: 1.0),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
          hintStyle: const TextStyle(color: Colors.black26),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.black.withOpacity(0.1),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(color: Colors.black87, fontSize: 12),
          ),
          iconTheme: MaterialStateProperty.all(
            const IconThemeData(color: Colors.black87),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
        ),
      ),

      // --------------------------------------------------------
      // 🔥 최초 화면 결정 (로그인 + 신규회원 여부)
      // --------------------------------------------------------
      home: _initialScreen(),

      // --------------------------------------------------------
      // 🔥 라우터
      // --------------------------------------------------------
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/signup/phone':
            return MaterialPageRoute(
              builder: (_) => const PhoneVerificationScreen(),
            );

          case '/signup/step1':
            return MaterialPageRoute(
              builder: (_) => const SignupStep1Screen(),
            );

          case '/signup/step3':
            if (args is SignupFormData) {
              return MaterialPageRoute(
                builder: (_) => SignupStep3Screen(data: args),
              );
            }
            return _error("회원가입 데이터가 누락되었습니다.");

          case '/signup/step4':
            if (args is SignupFormData) {
              return MaterialPageRoute(
                builder: (_) => SignupStep4Screen(data: args),
              );
            }
            return _error("회원가입 데이터가 누락되었습니다.");

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case '/recommended':
            return MaterialPageRoute(
              builder: (_) => const RecommendedFriendsScreen(),
            );

          case '/friends':
            return MaterialPageRoute(
              builder: (_) => const FriendsScreen(),
            );

          case '/comments':
            if (args is Post) {
              return MaterialPageRoute(
                builder: (_) => CommentScreen(post: args),
              );
            }
            return _error("게시물 정보가 누락되었습니다.");

          case '/write':
            return MaterialPageRoute(
              builder: (_) => const CommunityWriteScreen(),
            );

          case '/report':
            if (args is Post) {
              return MaterialPageRoute(
                builder: (_) => ReportScreen(post: args),
              );
            }
            return _error("게시물 정보가 누락되었습니다.");

          default:
            return _error("존재하지 않는 페이지입니다.");
        }
      },
    );
  }

  /// --------------------------------------------------------------------
  /// 🔥 최초 진입 화면 분기
  /// --------------------------------------------------------------------
  Widget _initialScreen() {
    // 1) 로그인 안됨 → 랜딩
    if (AppState.currentUser == null) {
      return const LandingScreen();
    }

    // 2) 회원가입 직후 → 추천 친구
    if (AppState.isNewUser == true) {
      return const RecommendedFriendsScreen();
    }

    // 3) 기존 로그인 사용자 → 메인탭(친구목록 포함)
    return const MainTabScreen();
  }

  Route<dynamic> _error(String msg) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("오류")),
        body: Center(
          child: Text(msg),
        ),
      ),
    );
  }
}
