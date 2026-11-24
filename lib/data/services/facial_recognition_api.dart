import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/facial_recognition_models.dart';

class FacialRecognitionException implements Exception {
  const FacialRecognitionException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cabeçalho `Authorization` da sessão atual (ex.: `Bearer eyJ...`), ou nulo.
typedef AuthorizationProvider = String? Function();

/// Cliente do `reconhecimento-facial-service`.
///
/// O serviço exige o JWT do cv-authentication-service em todas as rotas
/// `/api/v1`, então cada requisição leva o cabeçalho de [authorization].
class FacialRecognitionApi {
  FacialRecognitionApi({
    http.Client? client,
    String? baseUrl,
    this.authorization,
    this.timeout = const Duration(minutes: 5),
    this.lookupTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       baseUrl = (baseUrl ?? ApiConfig.facialRecognitionBaseUrl).replaceFirst(
         RegExp(r'/+$'),
         '',
       );

  final http.Client _client;
  final String baseUrl;
  final AuthorizationProvider? authorization;
  final Duration timeout;
  final Duration lookupTimeout;

  void close() => _client.close();

  void _authorize(http.BaseRequest request) {
    final header = authorization?.call();
    if (header != null && header.isNotEmpty) {
      request.headers['Authorization'] = header;
    }
  }

  /// Dados do aluno cadastrado (`GET /api/v1/alunos/{matricula}`), sem a
  /// biometria. Devolve nulo quando a matrícula não tem cadastro.
  Future<StudentProfile?> getStudent(String registration) async {
    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/api/v1/alunos/${Uri.encodeComponent(registration)}'),
    )..headers['Accept'] = 'application/json';
    _authorize(request);
    try {
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(lookupTimeout),
      ).timeout(lookupTimeout);
      if (response.statusCode == 404) return null;
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FacialRecognitionException(
          _errorMessage(body, response.statusCode),
          statusCode: response.statusCode,
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FacialRecognitionException(
          'O serviço facial retornou uma resposta inválida.',
        );
      }
      return StudentProfile.fromJson(decoded);
    } on FacialRecognitionException {
      rethrow;
    } on TimeoutException {
      throw const FacialRecognitionException(
        'O serviço facial demorou para responder.',
      );
    } on SocketException {
      throw FacialRecognitionException(
        'Não foi possível conectar ao serviço facial em $baseUrl.',
      );
    } on http.ClientException catch (error) {
      throw FacialRecognitionException(
        'Falha na comunicação com o serviço facial: ${error.message}',
      );
    } on FormatException {
      throw const FacialRecognitionException(
        'O serviço facial retornou uma resposta que não pôde ser lida.',
      );
    }
  }

  Future<RoomAuditResult> auditRoom(String imagePath) async {
    final response = await _sendMultipart(
      path: '/api/v1/auditar-sala',
      imagePath: imagePath,
    );
    return RoomAuditResult.fromJson(response);
  }

  Future<StudentEnrollmentResult> enrollStudent({
    required String studentId,
    required String imagePath,
    String? name,
    String? guardian,
    String? phone,
  }) async {
    final response = await _sendMultipart(
      path: '/api/v1/cadastrar-aluno',
      imagePath: imagePath,
      fields: {
        'student_id': studentId,
        if (name != null && name.trim().isNotEmpty) 'nome': name.trim(),
        if (guardian != null && guardian.trim().isNotEmpty)
          'responsavel': guardian.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'telefone': phone.trim(),
      },
    );
    return StudentEnrollmentResult.fromJson(response);
  }

  Future<Map<String, dynamic>> _sendMultipart({
    required String path,
    required String imagePath,
    Map<String, String> fields = const {},
  }) async {
    final image = File(imagePath);
    if (!await image.exists()) {
      throw const FacialRecognitionException(
        'A foto não está mais disponível. Tire uma nova foto.',
      );
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));
      _authorize(request);
      final response = await _client.send(request).timeout(timeout);
      final body = utf8.decode(
        await response.stream.toBytes(),
        allowMalformed: true,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FacialRecognitionException(
          _errorMessage(body, response.statusCode),
          statusCode: response.statusCode,
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FacialRecognitionException(
          'O serviço facial retornou uma resposta inválida.',
        );
      }
      return decoded;
    } on FacialRecognitionException {
      rethrow;
    } on TimeoutException {
      throw const FacialRecognitionException(
        'O reconhecimento demorou mais que o esperado. Tente novamente.',
      );
    } on SocketException {
      throw FacialRecognitionException(
        'Não foi possível conectar ao serviço facial em $baseUrl. '
        'Confira se a API está rodando e se o endereço está correto.',
      );
    } on http.ClientException catch (error) {
      throw FacialRecognitionException(
        'Falha ao enviar a foto para o serviço facial: ${error.message}',
      );
    } on FormatException {
      throw const FacialRecognitionException(
        'O serviço facial retornou uma resposta que não pôde ser lida.',
      );
    }
  }

  static String _errorMessage(String body, int statusCode) {
    if (statusCode == 401) {
      return 'Sessão inválida ou expirada para o serviço facial. Entre novamente.';
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } on FormatException {
      // Cai na mensagem HTTP genérica abaixo.
    }
    return 'O serviço facial retornou um erro (HTTP $statusCode).';
  }
}
