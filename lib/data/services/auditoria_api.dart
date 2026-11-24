import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/utils/photo.dart';
import '../models/auditoria_models.dart';
import '../models/auth_models.dart';

/// Erro devolvido pelo auditoria-service (ou de comunicação com ele).
class AuditoriaApiException implements Exception {
  const AuditoriaApiException(this.message, {this.statusCode});

  /// Texto pronto para exibir (campo `mensagem` da API).
  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

/// Cliente HTTP do auditoria-service (`/auditorias`).
///
/// A prévia envia a foto da sala; o serviço consulta o turma-service (alunos
/// ativos da turma) e o reconhecimento facial, repassando o mesmo JWT.
class AuditoriaApi {
  AuditoriaApi({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
    this.uploadTimeout = const Duration(minutes: 5),
  }) : _client = client ?? http.Client(),
       baseUrl = (baseUrl ?? ApiConfig.auditoriaBaseUrl).replaceFirst(
         RegExp(r'/+$'),
         '',
       );

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  /// O reconhecimento facial de uma foto grande pode levar mais tempo.
  final Duration uploadTimeout;

  void close() => _client.close();

  /// `POST /auditorias/previa`: reconhece a foto e monta a lista para revisão.
  Future<AuditPreview> preview(
    AuthSession session, {
    required int classId,
    required String imagePath,
  }) async {
    final http.MultipartFile photo;
    try {
      photo = await photoMultipart('foto', imagePath);
    } on StateError {
      throw const AuditoriaApiException(
        'A foto não está mais disponível. Tire uma nova foto.',
      );
    }
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/auditorias/previa'))
          ..fields['turmaId'] = '$classId'
          ..files.add(photo);
    return AuditPreview.fromJson(
      _asMap(await _dispatch(request, session, uploadTimeout)),
    );
  }

  /// `POST /auditorias`: grava a chamada revisada.
  Future<AuditRecord> confirm(
    AuthSession session, {
    required int classId,
    required List<AuditResultItem> results,
  }) async => AuditRecord.fromJson(
    _asMap(
      await _json('POST', '/auditorias', session, {
        'turmaId': classId,
        'resultados': [for (final item in results) item.toJson()],
      }),
    ),
  );

  /// `POST /auditorias/{id}/correcoes`: altera a presença de alunos de uma
  /// chamada já confirmada; a justificativa é obrigatória.
  Future<AuditRecord> correct(
    AuthSession session, {
    required int auditId,
    required String justification,
    required List<AuditResultItem> results,
  }) async => AuditRecord.fromJson(
    _asMap(
      await _json('POST', '/auditorias/$auditId/correcoes', session, {
        'justificativa': justification,
        'resultados': [for (final item in results) item.toJson()],
      }),
    ),
  );

  /// `GET /auditorias`: histórico, com filtro opcional por turma.
  Future<List<AuditRecord>> list(AuthSession session, {int? classId}) async {
    final query = classId == null ? '' : '?turmaId=$classId';
    final json = await _json('GET', '/auditorias$query', session, null);
    if (json is! List) {
      throw const AuditoriaApiException(
        'O serviço de auditoria retornou uma resposta inválida.',
      );
    }
    return json
        .whereType<Map<String, dynamic>>()
        .map(AuditRecord.fromJson)
        .toList();
  }

  // -------------------------------------------------------------- Interno

  Future<Object?> _json(
    String method,
    String path,
    AuthSession session,
    Map<String, dynamic>? body,
  ) {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    return _dispatch(request, session, timeout);
  }

  Future<Object?> _dispatch(
    http.BaseRequest request,
    AuthSession session,
    Duration limit,
  ) async {
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = session.authorizationHeader;
    try {
      final streamed = await _client.send(request).timeout(limit);
      final response = await http.Response.fromStream(streamed).timeout(limit);
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _errorFrom(text, response.statusCode);
      }
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } on AuditoriaApiException {
      rethrow;
    } on TimeoutException {
      throw const AuditoriaApiException(
        'O serviço de auditoria demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw AuditoriaApiException(
        'Não foi possível conectar ao serviço de auditoria em $baseUrl. '
        'Confira se a API está rodando e se o endereço está correto.',
      );
    } on http.ClientException catch (error) {
      throw AuditoriaApiException(
        'Falha na comunicação com o serviço de auditoria: ${error.message}',
      );
    } on FormatException {
      throw const AuditoriaApiException(
        'O serviço de auditoria retornou uma resposta que não pôde ser lida.',
      );
    }
  }

  static AuditoriaApiException _errorFrom(String body, int statusCode) {
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) message = decoded['mensagem']?.toString();
    } on FormatException {
      // Sem corpo JSON: usa a mensagem padrão do status abaixo.
    }
    return AuditoriaApiException(
      message == null || message.trim().isEmpty
          ? _defaultMessage(statusCode)
          : message.trim(),
      statusCode: statusCode,
    );
  }

  static String _defaultMessage(int statusCode) => switch (statusCode) {
    400 => 'Dados inválidos.',
    401 => 'Sessão inválida ou expirada. Entre novamente.',
    403 => 'Só coordenadores podem registrar e corrigir chamadas.',
    404 => 'Registro não encontrado.',
    409 => 'A chamada conflita com os dados da turma.',
    413 => 'A foto é grande demais. Tente outra com menor resolução.',
    502 =>
      'Um serviço de apoio (turmas ou reconhecimento) está indisponível. '
          'Tente novamente.',
    >= 500 => 'O serviço de auditoria está indisponível no momento.',
    _ => 'O serviço de auditoria retornou um erro (HTTP $statusCode).',
  };

  static Map<String, dynamic> _asMap(Object? json) {
    if (json is Map<String, dynamic>) return json;
    throw const AuditoriaApiException(
      'O serviço de auditoria retornou uma resposta inválida.',
    );
  }
}
