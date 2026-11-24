import 'dart:convert';

import 'package:class_vision/data/models/auth_models.dart';
import 'package:class_vision/data/models/turma_models.dart';
import 'package:class_vision/data/services/turma_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  final session = AuthSession.fromToken(fakeJwt(professorClaims()));

  test('sends the session token and parses classes', () async {
    late http.Request sent;
    final api = TurmaApi(
      baseUrl: 'http://turma.test/',
      client: MockClient((request) async {
        sent = request;
        return jsonResponse([
          classJson(alunos: [101]),
        ], 200);
      }),
    );

    final classes = await api.listClasses(session);

    expect(sent.url.toString(), 'http://turma.test/turmas');
    expect(sent.headers['Authorization'], session.authorizationHeader);
    expect(classes.single.name, '2º Ano A');
    expect(classes.single.startDate, DateTime(2026, 2, 9));
    expect(classes.single.enrollments.single.studentId, 101);
  });

  test('serializes the class payload in the API format', () async {
    late Map<String, dynamic> body;
    final api = TurmaApi(
      baseUrl: 'http://turma.test',
      client: MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse({...body, 'id': 9, 'alunos': []}, 201);
      }),
    );

    await api.createClass(
      session,
      ClassPayload(
        year: 2027,
        name: ' ADS - 1º Período A ',
        shift: 'NOTURNO',
        room: '  ',
        startDate: DateTime(2027, 2, 8),
        endDate: DateTime(2027, 6, 30),
        courseId: 1,
      ),
    );

    expect(body, {
      'ano': 2027,
      'nome': 'ADS - 1º Período A',
      'turno': 'NOTURNO',
      'sala': null,
      'inicioAula': '2027-02-08',
      'fimAula': '2027-06-30',
      'cursoId': 1,
    });
  });

  test('exposes API error messages and field errors', () async {
    final api = TurmaApi(
      baseUrl: 'http://turma.test',
      client: MockClient(
        (_) async => jsonResponse({
          'status': 400,
          'mensagem': 'Dados inválidos',
          'caminho': '/turmas',
          'campos': {'nome': 'não deve estar em branco'},
        }, 400),
      ),
    );

    await expectLater(
      api.createClass(
        session,
        const ClassPayload(year: 2027, name: '', shift: 'NOTURNO', courseId: 1),
      ),
      throwsA(
        isA<TurmaApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.fieldErrors['nome'], 'campo', isNotNull)
            .having((e) => e.message, 'message', startsWith('Dados inválidos')),
      ),
    );
  });

  test('uses a default message for errors without body', () async {
    final api = TurmaApi(
      baseUrl: 'http://turma.test',
      client: MockClient((_) async => http.Response('', 403)),
    );

    await expectLater(
      api.deleteClass(session, 1),
      throwsA(
        isA<TurmaApiException>()
            .having((e) => e.isForbidden, 'isForbidden', isTrue)
            .having(
              (e) => e.message,
              'message',
              'Você não tem permissão para realizar esta ação.',
            ),
      ),
    );
  });
}
