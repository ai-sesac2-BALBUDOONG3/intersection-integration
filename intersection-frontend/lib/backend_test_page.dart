import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BackendTestPage extends StatelessWidget {
  const BackendTestPage({super.key});

  Future<void> callBackend(BuildContext context) async {
    // ✅ Flutter 웹에서 백엔드 호출할 때는 이 주소(PC 기준 localhost)
    final url = Uri.parse('http://127.0.0.1:8000/');

    // 호출 시작했을 때도 일단 표시
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('백엔드 호출 중...')),
    );

    try {
      final res = await http.get(url);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '성공! 상태코드: ${res.statusCode}\n본문: ${res.body}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      // 에러 나면 에러도 표시
      messenger.showSnackBar(
        SnackBar(
          content: Text('에러 발생: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('백엔드 테스트')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            callBackend(context);
          },
          child: const Text('백엔드 호출'),
        ),
      ),
    );
  }
}
