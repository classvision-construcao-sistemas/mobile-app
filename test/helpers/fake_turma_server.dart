import 'dart:convert';

import 'package:class_vision/data/models/turma_models.dart';
import 'package:class_vision/data/services/turma_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_auth_server.dart';

const courseJson = {
  'id': 1,
  'codigo': 'INF-2026',
  'nome': 'Técnico em Informática',
  'situacao': 'ATIVO',
  'instituicaoId': 1,
};

/// Turma no formato `TurmaResposta` do turma-service.
Map<String, Object?> classJson({
  int id = 1,
  String nome = '2º Ano A',
  String turno = 'MATUTINO',
  String? sala = 'Sala 204',
  int ano = 2026,
  int cursoId = 1,
  String? inicioAula = '2026-02-09',
  String? fimAula = '2026-12-11',
  List<int> alunos = const [],
}) => {
  'id': id,
  'ano': ano,
  'nome': nome,
  'turno': turno,
  'sala': sala,
  'inicioAula': inicioAula,
  'fimAula': fimAula,
  'cursoId': cursoId,
  'alunos': [
    for (final aluno in alunos) {'alunoId': aluno, 'situacao': 'MATRICULADO'},
  ],
};

CourseClass courseClass({
  int id = 1,
  String nome = '2º Ano A',
  String turno = 'MATUTINO',
  String? sala = 'Sala 204',
  List<int> alunos = const [],
}) => CourseClass.fromJson(
  classJson(id: id, nome: nome, turno: turno, sala: sala, alunos: alunos),
);

final course = Course.fromJson(courseJson);

/// Turmas usadas pelos testes que sobem o app inteiro.
List<Map<String, Object?>> defaultClasses() => [
  classJson(id: 1, nome: '2º Ano A', alunos: [20260001, 20260002]),
  classJson(id: 2, nome: '1º Ano C', sala: 'Sala 118'),
  classJson(id: 3, nome: '2º Ano D', turno: 'VESPERTINO', sala: 'Sala 207'),
];

/// turma-service falso em memória: lista, cria, edita e exclui turmas e
/// vínculos. [requests] registra as chamadas recebidas.
TurmaApi fakeTurmaApi({
  List<Map<String, Object?>>? classes,
  List<Map<String, Object?>>? courses,
  List<http.Request>? requests,
  Future<http.Response?> Function(http.Request request)? extra,
}) {
  final turmas = [
    for (final item in classes ?? defaultClasses()) {...item},
  ];
  final cursos = [
    for (final item in courses ?? [courseJson]) {...item},
  ];
  var nextId = 100;

  http.Response erro(int status, String mensagem) => jsonResponse({
    'dataHora': '2026-11-23T10:00:00Z',
    'status': status,
    'mensagem': mensagem,
    'caminho': '/turmas',
    'campos': <String, String>{},
  }, status);

  Map<String, Object?>? turma(String id) {
    for (final item in turmas) {
      if ('${item['id']}' == id) return item;
    }
    return null;
  }

  return TurmaApi(
    baseUrl: 'http://turma.test',
    client: MockClient((request) async {
      requests?.add(request);
      final handled = await extra?.call(request);
      if (handled != null) return handled;
      if (!(request.headers['Authorization']?.startsWith('Bearer ') ?? false)) {
        return erro(401, 'Token ausente');
      }

      final segments = request.url.pathSegments;
      final body = request.body.isEmpty ? null : jsonDecode(request.body);
      switch ((request.method, segments)) {
        case ('GET', ['cursos']):
          return jsonResponse(cursos, 200);
        case ('POST', ['cursos']):
          final created = {...(body as Map<String, dynamic>), 'id': nextId++};
          cursos.add(created);
          return jsonResponse(created, 201);
        case ('GET', ['turmas']):
          return jsonResponse(turmas, 200);
        case ('POST', ['turmas']):
          final created = {
            ...(body as Map<String, dynamic>),
            'id': nextId++,
            'alunos': <Object>[],
          };
          turmas.add(created);
          return jsonResponse(created, 201);
        case ('GET', ['turmas', final id]):
          final found = turma(id);
          return found == null
              ? erro(404, 'Turma não encontrada: $id')
              : jsonResponse(found, 200);
        case ('PUT', ['turmas', final id]):
          final found = turma(id);
          if (found == null) return erro(404, 'Turma não encontrada: $id');
          found.addAll(body as Map<String, dynamic>);
          return jsonResponse(found, 200);
        case ('DELETE', ['turmas', final id]):
          turmas.removeWhere((item) => '${item['id']}' == id);
          return http.Response('', 204);
        case ('POST', ['turmas', final id, 'alunos']):
          final found = turma(id);
          if (found == null) return erro(404, 'Turma não encontrada: $id');
          final alunos = (found['alunos'] as List).toList();
          final alunoId = (body as Map<String, dynamic>)['alunoId'];
          if (alunos.any((item) => (item as Map)['alunoId'] == alunoId)) {
            return erro(409, 'Aluno já vinculado à turma');
          }
          found['alunos'] = [...alunos, body];
          return jsonResponse(found, 201);
        case ('DELETE', ['turmas', final id, 'alunos', final alunoId]):
          final found = turma(id);
          if (found == null) return erro(404, 'Turma não encontrada: $id');
          found['alunos'] = (found['alunos'] as List)
              .where((item) => '${(item as Map)['alunoId']}' != alunoId)
              .toList();
          return http.Response('', 204);
      }
      return erro(404, 'Rota não encontrada');
    }),
  );
}
