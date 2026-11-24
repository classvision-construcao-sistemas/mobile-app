import 'dart:io';

import 'package:flutter/foundation.dart';

/// Endereços dos microsserviços do ClassVision.
///
/// Com `--dart-define=API_GATEWAY_URL=http://localhost:8000` todos os serviços
/// passam pelo gateway do `docker compose` (pasta `infra/`), que roteia cada
/// caminho para o serviço certo. Sem o gateway, cada serviço usa a própria
/// variável (`AUTH_API_BASE_URL`, `TURMA_API_BASE_URL`,
/// `AUDITORIA_API_BASE_URL`, `FACE_API_BASE_URL`) ou o padrão abaixo.
///
/// Todos precisam compartilhar o mesmo `JWT_SECRET`: o token emitido pelo
/// serviço de autenticação é validado por todos os outros.
abstract final class ApiConfig {
  static const _configuredGatewayUrl = String.fromEnvironment(
    'API_GATEWAY_URL',
  );
  static const _configuredFacialBaseUrl = String.fromEnvironment(
    'FACE_API_BASE_URL',
  );
  static const _configuredAuthBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
  );
  static const _configuredTurmaBaseUrl = String.fromEnvironment(
    'TURMA_API_BASE_URL',
  );
  static const _configuredAuditoriaBaseUrl = String.fromEnvironment(
    'AUDITORIA_API_BASE_URL',
  );

  /// Gateway único (`infra/`), quando configurado.
  static String? get gatewayUrl => _configuredGatewayUrl.isEmpty
      ? null
      : _resolve(_configuredGatewayUrl, port: 8000);

  /// Serviço de reconhecimento facial (`reconhecimento-facial-service`).
  static String get facialRecognitionBaseUrl =>
      _serviceUrl(_configuredFacialBaseUrl, port: 5000);

  /// Endereço publicado do `cv-authentication-service` no Railway.
  static const defaultAuthBaseUrl =
      'https://cv-authentication-service-production.up.railway.app';

  /// Microsserviço de autenticação (`cv-authentication-service`).
  ///
  /// Sem gateway, usa a API publicada por padrão. Para um backend local, rode
  /// com `--dart-define=API_GATEWAY_URL=http://localhost:8000` (todos os
  /// serviços) ou `--dart-define=AUTH_API_BASE_URL=http://localhost:8080`.
  static String get authBaseUrl {
    if (_configuredAuthBaseUrl.isNotEmpty) return _trim(_configuredAuthBaseUrl);
    return gatewayUrl ?? defaultAuthBaseUrl;
  }

  /// Microsserviço de cursos e turmas (`turma-service`).
  ///
  /// Localmente o serviço sobe na porta definida por `PORT`; como o
  /// serviço de autenticação já usa a 8080, o padrão do app é a 8081
  /// (`PORT=8081 ./mvnw spring-boot:run`).
  static String get turmaBaseUrl =>
      _serviceUrl(_configuredTurmaBaseUrl, port: 8081);

  /// Microsserviço de auditoria de presença (`auditoria-service`): prévia da
  /// chamada pela foto, confirmação e histórico. Padrão local na porta 8082.
  static String get auditoriaBaseUrl =>
      _serviceUrl(_configuredAuditoriaBaseUrl, port: 8082);

  static String _serviceUrl(String configured, {required int port}) {
    if (configured.isNotEmpty) return _trim(configured);
    return gatewayUrl ?? _resolve('', port: port);
  }

  static String _trim(String url) => url.replaceFirst(RegExp(r'/+$'), '');

  static String _resolve(String configured, {required int port}) {
    if (configured.isNotEmpty) return _trim(configured);

    // O emulador Android acessa a máquina host por 10.0.2.2. Nos demais
    // ambientes de desenvolvimento, localhost é o comportamento esperado.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$port';
    return 'http://localhost:$port';
  }
}
