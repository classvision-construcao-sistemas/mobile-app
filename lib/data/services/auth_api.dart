import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/utils/formatters.dart';
import '../models/auth_models.dart';

/// Erro devolvido pelo cv-authentication-service (ou de comunicação com ele).
class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode, this.solution});

  /// Texto pronto para exibir (campo `descricao` da API).
  final String message;
  final int? statusCode;

  /// Sugestão de correção (campo `solucao` da API).
  final String? solution;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

/// Cliente HTTP das rotas do cv-authentication-service.
class AuthApi {
  AuthApi({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       baseUrl = (baseUrl ?? ApiConfig.authBaseUrl).replaceFirst(
         RegExp(r'/+$'),
         '',
       );

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  void close() => _client.close();

  // ---------------------------------------------------------------- Login

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = _asMap(
      await _send(
        'POST',
        '/api/auth/login',
        body: {'email': email.trim(), 'senha': password},
      ),
    );
    final token = json['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const AuthApiException(
        'O serviço de autenticação não retornou um token.',
      );
    }
    try {
      return AuthSession.fromToken(
        token,
        tokenType: json['tipo']?.toString() ?? 'Bearer',
        expiresInMs: asInt(json['expiresIn']),
      );
    } on FormatException {
      throw const AuthApiException(
        'O token recebido do serviço de autenticação é inválido.',
      );
    }
  }

  // ------------------------------------------------------------- Usuários

  Future<List<AppUser>> listUsers(AuthSession session) async => _asList(
    await _send('GET', '/api/usuarios/listar-usuarios', session: session),
  ).map(AppUser.fromJson).toList();

  Future<AppUser> getUser(AuthSession session, int id) async =>
      AppUser.fromJson(
        _asMap(
          await _send('GET', '/api/usuarios/buscar-usuario/$id', session: session),
        ),
      );

  Future<AppUser> getUserByEmail(AuthSession session, String email) async =>
      AppUser.fromJson(
        _asMap(
          await _send(
            'GET',
            '/api/usuarios/buscar-usuario-por-email/'
                '${Uri.encodeComponent(email.trim())}',
            session: session,
          ),
        ),
      );

  Future<AppUser> createUser(AuthSession session, UserPayload payload) async =>
      AppUser.fromJson(
        _asMap(
          await _send(
            'POST',
            '/api/usuarios/cadastrar-usuario',
            session: session,
            body: payload.toJson(),
          ),
        ),
      );

  Future<AppUser> updateUser(
    AuthSession session,
    int id,
    UserPayload payload,
  ) async => AppUser.fromJson(
    _asMap(
      await _send(
        'PUT',
        '/api/usuarios/atualizar-usuario/$id',
        session: session,
        body: payload.toJson(),
      ),
    ),
  );

  Future<AppUser> activateUser(AuthSession session, int id) async =>
      AppUser.fromJson(
        _asMap(
          await _send(
            'PATCH',
            '/api/usuarios/ativar-usuario/$id',
            session: session,
          ),
        ),
      );

  Future<AppUser> deactivateUser(AuthSession session, int id) async =>
      AppUser.fromJson(
        _asMap(
          await _send(
            'PATCH',
            '/api/usuarios/desativar-usuario/$id',
            session: session,
          ),
        ),
      );

  Future<void> deleteUser(AuthSession session, int id) async {
    await _send('DELETE', '/api/usuarios/excluir-usuario/$id', session: session);
  }

  // --------------------------------------------------------- Instituições

  Future<List<Institution>> listInstitutions(AuthSession session) async =>
      _asList(
        await _send(
          'GET',
          '/api/instituicoes/listar-instituicoes',
          session: session,
        ),
      ).map(Institution.fromJson).toList();

  Future<Institution> getInstitution(AuthSession session, int id) async =>
      Institution.fromJson(
        _asMap(
          await _send(
            'GET',
            '/api/instituicoes/buscar-instituicao/$id',
            session: session,
          ),
        ),
      );

  Future<Institution> createInstitution(
    AuthSession session,
    InstitutionPayload payload,
  ) async => Institution.fromJson(
    _asMap(
      await _send(
        'POST',
        '/api/instituicoes/cadastrar-instituicao',
        session: session,
        body: payload.toJson(),
      ),
    ),
  );

  Future<Institution> updateInstitution(
    AuthSession session,
    int id,
    InstitutionPayload payload,
  ) async => Institution.fromJson(
    _asMap(
      await _send(
        'PUT',
        '/api/instituicoes/atualizar-instituicao/$id',
        session: session,
        body: payload.toJson(),
      ),
    ),
  );

  Future<Institution> activateInstitution(AuthSession session, int id) async =>
      Institution.fromJson(
        _asMap(
          await _send(
            'PATCH',
            '/api/instituicoes/ativar-instituicao/$id',
            session: session,
          ),
        ),
      );

  Future<Institution> deactivateInstitution(
    AuthSession session,
    int id,
  ) async => Institution.fromJson(
    _asMap(
      await _send(
        'PATCH',
        '/api/instituicoes/desativar-instituicao/$id',
        session: session,
      ),
    ),
  );

  // -------------------------------------------------------------- Interno

  Future<Object?> _send(
    String method,
    String path, {
    AuthSession? session,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (session != null) {
      request.headers['Authorization'] = session.authorizationHeader;
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout);
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _errorFrom(text, response.statusCode);
      }
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } on AuthApiException {
      rethrow;
    } on TimeoutException {
      throw const AuthApiException(
        'O serviço de autenticação demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw AuthApiException(
        'Não foi possível conectar ao serviço de autenticação em $baseUrl. '
        'Confira se a API está rodando e se o endereço está correto.',
      );
    } on http.ClientException catch (error) {
      throw AuthApiException(
        'Falha na comunicação com o serviço de autenticação: ${error.message}',
      );
    } on FormatException {
      throw const AuthApiException(
        'O serviço de autenticação retornou uma resposta que não pôde ser lida.',
      );
    }
  }

  static AuthApiException _errorFrom(String body, int statusCode) {
    String? message;
    String? solution;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        message = decoded['descricao']?.toString();
        solution = decoded['solucao']?.toString();
      }
    } on FormatException {
      // Sem corpo JSON: usa a mensagem padrão do status abaixo.
    }
    return AuthApiException(
      message == null || message.trim().isEmpty
          ? _defaultMessage(statusCode)
          : message.trim(),
      statusCode: statusCode,
      solution: solution,
    );
  }

  static String _defaultMessage(int statusCode) => switch (statusCode) {
    401 => 'Sessão inválida ou expirada. Entre novamente.',
    403 => 'Você não tem permissão para realizar esta ação.',
    404 => 'Registro não encontrado.',
    409 => 'Já existe um registro com esses dados.',
    >= 500 => 'O serviço de autenticação está indisponível no momento.',
    _ => 'O serviço de autenticação retornou um erro (HTTP $statusCode).',
  };

  static Map<String, dynamic> _asMap(Object? json) {
    if (json is Map<String, dynamic>) return json;
    throw const AuthApiException(
      'O serviço de autenticação retornou uma resposta inválida.',
    );
  }

  static List<Map<String, dynamic>> _asList(Object? json) {
    if (json is List) return json.whereType<Map<String, dynamic>>().toList();
    throw const AuthApiException(
      'O serviço de autenticação retornou uma resposta inválida.',
    );
  }
}
