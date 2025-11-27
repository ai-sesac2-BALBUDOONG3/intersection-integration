// lib/config/api_config.dart

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // 플랫폼에 따라 자동으로 URL 선택
  static String get baseUrl {
    if (kIsWeb) {
      // 웹에서 실행할 때
      return 'http://127.0.0.1:8000';
    } else {
      // 모바일 에뮬레이터에서 실행할 때
      return 'http://10.0.2.2:8000';
    }
  }
}
