import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _configuredFacialBaseUrl = String.fromEnvironment(
    'FACE_API_BASE_URL',
  );
  static const _configuredAuthBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
  );

  /// Serviço de reconhecimento facial (`reconhecimento-facial-service`).
  static String get facialRecognitionBaseUrl =>
      _resolve(_configuredFacialBaseUrl, port: 5000);

  /// Microsserviço de autenticação (`cv-authentication-service`).
  static String get authBaseUrl => _resolve(_configuredAuthBaseUrl, port: 8080);

  static String _resolve(String configured, {required int port}) {
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }

    // O emulador Android acessa a máquina host por 10.0.2.2. Nos demais
    // ambientes de desenvolvimento, localhost é o comportamento esperado.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$port';
    return 'http://localhost:$port';
  }
}
