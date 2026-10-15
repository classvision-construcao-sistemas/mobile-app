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

class FacialRecognitionApi {
  FacialRecognitionApi({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(minutes: 5),
  }) : _client = client ?? http.Client(),
       baseUrl = baseUrl ?? ApiConfig.facialRecognitionBaseUrl;

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  void close() => _client.close();

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
  }) async {
    final response = await _sendMultipart(
      path: '/api/v1/cadastrar-aluno',
      imagePath: imagePath,
      fields: {'student_id': studentId},
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
      final response = await _client.send(request).timeout(timeout);
      final body = await response.stream.bytesToString();
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
