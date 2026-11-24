import 'dart:convert';

import 'package:class_vision/data/services/auditoria_api.dart';
import 'package:class_vision/data/services/facial_recognition_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_auth_server.dart';

/// auditoria-service falso: a prévia reconhece [recognized] entre os
/// [activeStudents] da turma; confirmações ficam guardadas em [saved].
AuditoriaApi fakeAuditoriaApi({
  List<int> activeStudents = const [20260001, 20260002],
  Map<int, double> recognized = const {20260001: .97},
  List<Map<String, dynamic>>? saved,
  List<http.BaseRequest>? requests,
  int? failWith,
}) {
  final store = saved ?? <Map<String, dynamic>>[];
  var nextId = 1;
  http.Response erro(int status, String mensagem) =>
      jsonResponse({'status': status, 'mensagem': mensagem}, status);
  return AuditoriaApi(
    baseUrl: 'http://auditoria.test',
    client: MockClient((request) async {
      requests?.add(request);
      if (!(request.headers['Authorization']?.startsWith('Bearer ') ?? false)) {
        return erro(401, 'Token ausente');
      }
      if (failWith != null) return erro(failWith, 'Falha simulada');
      final segments = request.url.pathSegments;
      switch ((request.method, segments)) {
        case ('POST', ['auditorias', 'previa']):
          final body = utf8.decode(request.bodyBytes, allowMalformed: true);
          final turma = RegExp(r'name="turmaId"\r\n\r\n(\d+)')
              .firstMatch(body)
              ?.group(1);
          return jsonResponse({
            'turmaId': int.parse(turma!),
            'data': '2026-11-24',
            'horario': '08:05:00',
            'alunos': [
              for (final id in activeStudents)
                recognized.containsKey(id)
                    ? {
                        'alunoId': id,
                        'situacaoPresenca': 'PRESENTE',
                        'situacaoFace': 'RECONHECIDA',
                        'confianca': recognized[id],
                      }
                    : {
                        'alunoId': id,
                        'situacaoPresenca': 'POSSIVEL_FALTA',
                        'situacaoFace': 'NAO_RECONHECIDA',
                        'confianca': null,
                      },
            ],
            'facesNaoIdentificadas': 1,
            'facesForaDaTurma': 1,
            'totalFaces': recognized.length + 2,
          }, 200);
        case ('POST', ['auditorias']):
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final record = {
            'id': nextId++,
            'turmaId': body['turmaId'],
            'usuarioId': 7,
            'data': '2026-11-24',
            'horario': '08:06:10',
            'situacao': 'CONFIRMADA',
            'resultados': body['resultados'],
            'correcoes': <Object>[],
          };
          store.add(record);
          return jsonResponse(record, 201);
        case ('GET', ['auditorias']):
          return jsonResponse(store.reversed.toList(), 200);
        case ('POST', ['auditorias', final id, 'correcoes']):
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final record = store.firstWhere((it) => '${it['id']}' == id);
          final changes = {
            for (final item in body['resultados'] as List)
              (item as Map)['alunoId']: item['situacaoPresenca'],
          };
          record['resultados'] = [
            for (final item in record['resultados'] as List)
              {
                ...(item as Map<String, dynamic>),
                if (changes.containsKey(item['alunoId']))
                  'situacaoPresenca': changes[item['alunoId']],
              },
          ];
          record['situacao'] = 'CORRIGIDA';
          record['correcoes'] = [
            ...record['correcoes'] as List,
            {
              'usuarioId': 7,
              'dtCorrecao': '2026-11-24T09:00:00',
              'justificativa': body['justificativa'],
            },
          ];
          return jsonResponse(record, 200);
      }
      return erro(404, 'Rota não encontrada');
    }),
  );
}

/// Serviço facial falso que responde os dados cadastrados por matrícula.
FacialRecognitionApi fakeFacialApi({
  Map<String, String> names = const {},
  List<http.BaseRequest>? requests,
  String? Function()? authorization,
}) => FacialRecognitionApi(
  baseUrl: 'http://face.test',
  authorization: authorization ?? () => 'Bearer token-de-teste',
  client: MockClient((request) async {
    requests?.add(request);
    final segments = request.url.pathSegments;
    if (request.method == 'GET' &&
        segments.length == 4 &&
        segments[2] == 'alunos') {
      final name = names[segments[3]];
      return name == null
          ? jsonResponse({'error': 'não encontrado'}, 404)
          : jsonResponse({
              'matricula': segments[3],
              'nome': name,
              'responsavel': 'Responsável de $name',
              'telefone': '64999990000',
              'status': '',
            }, 200);
    }
    return jsonResponse({'error': 'rota'}, 404);
  }),
);
