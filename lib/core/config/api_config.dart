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

  /// Endereço publicado do `cv-authentication-service` no Railway.
  static const defaultAuthBaseUrl =
      'https://cv-authentication-service-production.up.railway.app';

  /// Microsserviço de autenticação (`cv-authentication-service`).
  ///
  /// Usa a API publicada por padrão. Para apontar para um backend local, rode
  /// com `--dart-define=AUTH_API_BASE_URL=http://localhost:8080`.
  static String get authBaseUrl => (_configuredAuthBaseUrl.isNotEmpty
          ? _configuredAuthBaseUrl
          : defaultAuthBaseUrl)
      .replaceFirst(RegExp(r'/+$'), '');

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
