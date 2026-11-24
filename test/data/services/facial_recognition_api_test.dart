import 'dart:convert';
import 'dart:io';

import 'package:class_vision/data/services/facial_recognition_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late File image;

  setUp(() async {
    image = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'classvision-api-test-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await image.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
  });

  tearDown(() async {
    if (await image.exists()) await image.delete();
  });

  test('enrolls a student with the API multipart contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/cadastrar-aluno');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      final body = utf8.decode(request.bodyBytes, allowMalformed: true);
      expect(body, contains('name="student_id"'));
      expect(body, contains('2026001'));
      expect(body, contains('name="image"'));
      return http.Response(
        jsonEncode({'message': 'Aluno cadastrado.', 'student_id': '2026001'}),
        201,
      );
    });
    final api = FacialRecognitionApi(
      client: client,
      baseUrl: 'http://api.test',
    );

    final result = await api.enrollStudent(
      studentId: '2026001',
      imagePath: image.path,
    );

    expect(result.studentId, '2026001');
  });

  test('parses recognized students from a room audit', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/auditar-sala');
      return http.Response(
        jsonEncode({
          'message': 'ok',
          'recognized_students': [
            {
              'student_id': '2026001',
              'confidence_score': 0.93,
              'facial_area': {'x': 1, 'y': 2, 'w': 3, 'h': 4},
            },
          ],
          'unrecognized_count': 1,
          'total_faces_detected': 2,
        }),
        200,
      );
    });
    final api = FacialRecognitionApi(
      client: client,
      baseUrl: 'http://api.test',
    );

    final result = await api.auditRoom(image.path);

    expect(result.totalFacesDetected, 2);
    expect(result.unrecognizedCount, 1);
    expect(result.recognizedStudents.single.studentId, '2026001');
    expect(result.recognizedStudents.single.confidenceScore, .93);
  });

  test('surfaces the error message returned by the API', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'error': 'Nenhum rosto.'}), 400),
    );
    final api = FacialRecognitionApi(
      client: client,
      baseUrl: 'http://api.test',
    );

    expect(
      () => api.auditRoom(image.path),
      throwsA(
        isA<FacialRecognitionException>().having(
          (error) => error.message,
          'message',
          'Nenhum rosto.',
        ),
      ),
    );
  });

  test('sends the session token and the student data when enrolling', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer abc.def.ghi');
      final body = utf8.decode(request.bodyBytes, allowMalformed: true);
      expect(body, contains('name="nome"'));
      expect(body, contains('Ana Clara'));
      expect(body, contains('name="responsavel"'));
      expect(body, contains('name="telefone"'));
      return http.Response(
        jsonEncode({'message': 'ok', 'student_id': '2026001'}),
        201,
      );
    });
    final api = FacialRecognitionApi(
      client: client,
      baseUrl: 'http://api.test',
      authorization: () => 'Bearer abc.def.ghi',
    );

    await api.enrollStudent(
      studentId: '2026001',
      imagePath: image.path,
      name: ' Ana Clara ',
      guardian: 'Rita',
      phone: '64999990000',
    );
  });

  test('keeps the conflict status when the student already exists', () async {
    final api = FacialRecognitionApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'Aluno 2026001 já cadastrado.'}),
          409,
        ),
      ),
      baseUrl: 'http://api.test',
    );

    await expectLater(
      api.enrollStudent(studentId: '2026001', imagePath: image.path),
      throwsA(
        isA<FacialRecognitionException>().having(
          (error) => error.statusCode,
          'statusCode',
          409,
        ),
      ),
    );
  });

  test('looks up the student profile and returns null when missing', () async {
    final api = FacialRecognitionApi(
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer t');
        return request.url.path.endsWith('/2026001')
            ? http.Response(
                jsonEncode({
                  'matricula': '2026001',
                  'nome': 'Ana Clara',
                  'responsavel': 'Rita',
                  'telefone': '64999990000',
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              )
            : http.Response(jsonEncode({'error': 'não encontrado'}), 404);
      }),
      baseUrl: 'http://api.test',
      authorization: () => 'Bearer t',
    );

    final found = await api.getStudent('2026001');
    expect(found?.name, 'Ana Clara');
    expect(found?.guardian, 'Rita');
    expect(await api.getStudent('9999'), isNull);
  });
}
