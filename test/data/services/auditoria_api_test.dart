import 'dart:convert';
import 'dart:io';

import 'package:class_vision/data/models/auditoria_models.dart';
import 'package:class_vision/data/models/auth_models.dart';
import 'package:class_vision/data/services/auditoria_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fake_auth_server.dart';

void main() {
  late File image;
  final session = AuthSession.fromToken(fakeJwt(professorClaims()));

  setUp(() async {
    image = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'classvision-auditoria-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await image.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
  });

  tearDown(() async {
    if (await image.exists()) await image.delete();
  });

  test('sends the room photo to the preview with the session token', () async {
    final api = AuditoriaApi(
      baseUrl: 'http://auditoria.test/',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://auditoria.test/auditorias/previa',
        );
        expect(request.headers['Authorization'], session.authorizationHeader);
        final body = utf8.decode(request.bodyBytes, allowMalformed: true);
        expect(body, contains('name="turmaId"'));
        expect(body, contains('name="foto"'));
        return jsonResponse({
          'turmaId': 3,
          'alunos': [
            {
              'alunoId': 2026001,
              'situacaoPresenca': 'PRESENTE',
              'situacaoFace': 'RECONHECIDA',
              'confianca': .93,
            },
            {'alunoId': 2026002, 'situacaoPresenca': 'POSSIVEL_FALTA'},
          ],
          'facesNaoIdentificadas': 1,
          'facesForaDaTurma': 2,
          'totalFaces': 4,
        }, 200);
      }),
    );

    final preview = await api.preview(
      session,
      classId: 3,
      imagePath: image.path,
    );

    expect(preview.classId, 3);
    expect(preview.students.map((it) => it.present), [true, false]);
    expect(preview.students.first.confidence, .93);
    expect(preview.facesOutsideClass, 2);
    expect(preview.totalFaces, 4);
  });

  test('confirms the reviewed attendance and parses the record', () async {
    final api = AuditoriaApi(
      baseUrl: 'http://auditoria.test',
      client: MockClient((request) async {
        expect(request.url.path, '/auditorias');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['turmaId'], 3);
        expect(body['resultados'], [
          {
            'alunoId': 2026001,
            'situacaoPresenca': 'PRESENTE',
            'situacaoFace': 'RECONHECIDA',
          },
        ]);
        return jsonResponse({
          'id': 9,
          'turmaId': 3,
          'usuarioId': 1,
          'data': '2026-11-24',
          'horario': '08:05:42',
          'situacao': 'CONFIRMADA',
          'resultados': body['resultados'],
        }, 201);
      }),
    );

    final record = await api.confirm(
      session,
      classId: 3,
      results: const [
        AuditResultItem(
          studentId: 2026001,
          presence: AuditPresence.present,
          face: AuditFace.recognized,
        ),
      ],
    );

    expect(record.id, 9);
    expect(record.date, DateTime(2026, 11, 24, 8, 5, 42));
    expect(record.present, 1);
    expect(record.absent, 0);
  });

  test('shows the message returned by the service', () async {
    final api = AuditoriaApi(
      baseUrl: 'http://auditoria.test',
      client: MockClient(
        (_) async => jsonResponse({
          'status': 502,
          'mensagem': 'Serviço de turmas indisponível. Tente novamente.',
        }, 502),
      ),
    );

    expect(
      () => api.list(session),
      throwsA(
        isA<AuditoriaApiException>()
            .having((it) => it.statusCode, 'statusCode', 502)
            .having(
              (it) => it.message,
              'message',
              'Serviço de turmas indisponível. Tente novamente.',
            ),
      ),
    );
  });

  test('explains when the profile cannot record attendance', () async {
    final api = AuditoriaApi(
      baseUrl: 'http://auditoria.test',
      client: MockClient((_) async => http.Response('', 403)),
    );

    expect(
      () => api.list(session),
      throwsA(
        isA<AuditoriaApiException>().having(
          (it) => it.message,
          'message',
          contains('coordenadores'),
        ),
      ),
    );
  });
}
