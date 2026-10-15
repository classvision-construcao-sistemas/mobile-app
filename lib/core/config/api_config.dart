import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment('FACE_API_BASE_URL');

  static String get facialRecognitionBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    // O emulador Android acessa a máquina host por 10.0.2.2. Nos demais
    // ambientes de desenvolvimento, localhost é o comportamento esperado.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }
}
