import 'dart:io';

import 'package:flutter/foundation.dart';

/// Endereços dos microsserviços do ClassVision.
///
/// Sem nenhum `--dart-define`, o app usa os serviços publicados no Railway
/// (produção). Para desenvolver com tudo local, suba o `docker compose` da
/// pasta `infra/` e rode com
/// `--dart-define=API_GATEWAY_URL=http://localhost:8000` (emulador Android:
/// `http://10.0.2.2:8000`): o gateway roteia cada caminho para o serviço
/// certo. Cada serviço também pode ser trocado individualmente com
/// `AUTH_API_BASE_URL`, `TURMA_API_BASE_URL`, `AUDITORIA_API_BASE_URL` e
/// `FACE_API_BASE_URL`.
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

  // Serviços publicados no Railway (projeto ClassVision, ambiente production).
  static const defaultAuthBaseUrl =
      'https://cv-authentication-service-production.up.railway.app';
  static const defaultTurmaBaseUrl =
      'https://ingenious-presence-production-e4d3f7af.up.railway.app';
  static const defaultAuditoriaBaseUrl =
      'https://auditoria-service-production.up.railway.app';
  static const defaultFacialBaseUrl =
      'https://reconhecimento-facial-service-production.up.railway.app';

  /// Gateway único (`infra/`), quando configurado.
  static String? get gatewayUrl =>
      _configuredGatewayUrl.isEmpty ? null : _local(_configuredGatewayUrl);

  /// Microsserviço de autenticação (`cv-authentication-service`).
  static String get authBaseUrl =>
      _serviceUrl(_configuredAuthBaseUrl, defaultAuthBaseUrl);

  /// Microsserviço de cursos e turmas (`turma-service`).
  static String get turmaBaseUrl =>
      _serviceUrl(_configuredTurmaBaseUrl, defaultTurmaBaseUrl);

  /// Microsserviço de auditoria de presença (`auditoria-service`): prévia da
  /// chamada pela foto, confirmação e histórico.
  static String get auditoriaBaseUrl =>
      _serviceUrl(_configuredAuditoriaBaseUrl, defaultAuditoriaBaseUrl);

  /// Serviço de reconhecimento facial (`reconhecimento-facial-service`).
  static String get facialRecognitionBaseUrl =>
      _serviceUrl(_configuredFacialBaseUrl, defaultFacialBaseUrl);

  static String _serviceUrl(String configured, String published) {
    if (configured.isNotEmpty) return _local(configured);
    return gatewayUrl ?? published;
  }

  static String _trim(String url) => url.replaceFirst(RegExp(r'/+$'), '');

  /// No emulador Android, `localhost` é o próprio emulador: a máquina host
  /// fica em 10.0.2.2.
  static String _local(String url) {
    final trimmed = _trim(url);
    if (!kIsWeb && Platform.isAndroid) {
      return trimmed.replaceFirstMapped(
        RegExp(r'^(https?://)(localhost|127\.0\.0\.1)(?=[:/]|$)'),
        (match) => '${match[1]}10.0.2.2',
      );
    }
    return trimmed;
  }
}
