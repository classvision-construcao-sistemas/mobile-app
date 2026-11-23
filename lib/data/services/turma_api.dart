import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/auth_models.dart';
import '../models/turma_models.dart';

/// Erro devolvido pelo turma-service (ou de comunicação com ele).
class TurmaApiException implements Exception {
  const TurmaApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Texto pronto para exibir (campo `mensagem` da API).
  final String message;
  final int? statusCode;

  /// Erros de validação por campo (campo `campos` da API).
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

/// Cliente HTTP das rotas do turma-service (`/cursos` e `/turmas`).
///
/// O serviço valida o mesmo JWT emitido pelo cv-authentication-service, então
/// todas as chamadas usam o token da sessão atual.
class TurmaApi {
  TurmaApi({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       baseUrl = (baseUrl ?? ApiConfig.turmaBaseUrl).replaceFirst(
         RegExp(r'/+$'),
         '',
       );

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  void close() => _client.close();

  // ---------------------------------------------------------------- Cursos

  Future<List<Course>> listCourses(AuthSession session) async =>
      _asList(await _send('GET', '/cursos', session: session))
          .map(Course.fromJson)
          .toList();

  Future<Course> createCourse(
    AuthSession session,
    CoursePayload payload,
  ) async => Course.fromJson(
    _asMap(
      await _send('POST', '/cursos', session: session, body: payload.toJson()),
    ),
  );

  // ---------------------------------------------------------------- Turmas

  Future<List<CourseClass>> listClasses(AuthSession session) async =>
      _asList(await _send('GET', '/turmas', session: session))
          .map(CourseClass.fromJson)
          .toList();

  Future<CourseClass> getClass(AuthSession session, int id) async =>
      CourseClass.fromJson(
        _asMap(await _send('GET', '/turmas/$id', session: session)),
      );

  Future<List<CourseClass>> listClassesByCourse(
    AuthSession session,
    int courseId,
  ) async =>
      _asList(await _send('GET', '/turmas/curso/$courseId', session: session))
          .map(CourseClass.fromJson)
          .toList();

  Future<CourseClass> createClass(
    AuthSession session,
    ClassPayload payload,
  ) async => CourseClass.fromJson(
    _asMap(
      await _send('POST', '/turmas', session: session, body: payload.toJson()),
    ),
  );

  Future<CourseClass> updateClass(
    AuthSession session,
    int id,
    ClassPayload payload,
  ) async => CourseClass.fromJson(
    _asMap(
      await _send(
        'PUT',
        '/turmas/$id',
        session: session,
        body: payload.toJson(),
      ),
    ),
  );

  Future<void> deleteClass(AuthSession session, int id) async {
    await _send('DELETE', '/turmas/$id', session: session);
  }

  // ------------------------------------------------------- Vínculo de alunos

  Future<CourseClass> enrollStudent(
    AuthSession session,
    int classId, {
    required int studentId,
    String status = 'MATRICULADO',
  }) async => CourseClass.fromJson(
    _asMap(
      await _send(
        'POST',
        '/turmas/$classId/alunos',
        session: session,
        body: {'alunoId': studentId, 'situacao': status},
      ),
    ),
  );

  Future<CourseClass> updateEnrollment(
    AuthSession session,
    int classId,
    int studentId, {
    required String status,
  }) async => CourseClass.fromJson(
    _asMap(
      await _send(
        'PUT',
        '/turmas/$classId/alunos/$studentId',
        session: session,
        body: {'situacao': status},
      ),
    ),
  );

  Future<void> unenrollStudent(
    AuthSession session,
    int classId,
    int studentId,
  ) async {
    await _send(
      'DELETE',
      '/turmas/$classId/alunos/$studentId',
      session: session,
    );
  }

  // -------------------------------------------------------------- Interno

  Future<Object?> _send(
    String method,
    String path, {
    required AuthSession session,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = session.authorizationHeader;
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(timeout);
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _errorFrom(text, response.statusCode);
      }
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } on TurmaApiException {
      rethrow;
    } on TimeoutException {
      throw const TurmaApiException(
        'O serviço de turmas demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw TurmaApiException(
        'Não foi possível conectar ao serviço de turmas em $baseUrl. '
        'Confira se a API está rodando e se o endereço está correto.',
      );
    } on http.ClientException catch (error) {
      throw TurmaApiException(
        'Falha na comunicação com o serviço de turmas: ${error.message}',
      );
    } on FormatException {
      throw const TurmaApiException(
        'O serviço de turmas retornou uma resposta que não pôde ser lida.',
      );
    }
  }

  static TurmaApiException _errorFrom(String body, int statusCode) {
    String? message;
    var fields = const <String, String>{};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        message = decoded['mensagem']?.toString();
        final campos = decoded['campos'];
        if (campos is Map && campos.isNotEmpty) {
          fields = {
            for (final entry in campos.entries)
              entry.key.toString(): entry.value.toString(),
          };
        }
      }
    } on FormatException {
      // Sem corpo JSON: usa a mensagem padrão do status abaixo.
    }
    var text = message == null || message.trim().isEmpty
        ? _defaultMessage(statusCode)
        : message.trim();
    if (fields.isNotEmpty) {
      text =
          '$text: ${fields.entries.map((e) => '${e.key} ${e.value}').join('; ')}';
    }
    return TurmaApiException(text, statusCode: statusCode, fieldErrors: fields);
  }

  static String _defaultMessage(int statusCode) => switch (statusCode) {
    400 => 'Dados inválidos.',
    401 => 'Sessão inválida ou expirada. Entre novamente.',
    403 => 'Você não tem permissão para realizar esta ação.',
    404 => 'Registro não encontrado.',
    409 => 'A operação conflita com os dados já cadastrados.',
    >= 500 => 'O serviço de turmas está indisponível no momento.',
    _ => 'O serviço de turmas retornou um erro (HTTP $statusCode).',
  };

  static Map<String, dynamic> _asMap(Object? json) {
    if (json is Map<String, dynamic>) return json;
    throw const TurmaApiException(
      'O serviço de turmas retornou uma resposta inválida.',
    );
  }

  static List<Map<String, dynamic>> _asList(Object? json) {
    if (json is List) return json.whereType<Map<String, dynamic>>().toList();
    throw const TurmaApiException(
      'O serviço de turmas retornou uma resposta inválida.',
    );
  }
}
