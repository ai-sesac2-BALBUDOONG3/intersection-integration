import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/screens/landing_screen.dart';
import 'package:intersection/screens/main_tab_screen.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: AppState.currentUser == null
          ? const LandingScreen()
          : const MainTabScreen(),
    );
  }
}
