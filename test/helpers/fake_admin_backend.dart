import 'dart:convert';

import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_auth_server.dart';

/// cv-authentication-service falso com instituições e usuários em memória.
///
/// Entra com o papel [role] (ex.: `ADMINISTRADOR`, `ADMIN_INSTITUICAO`) e
/// registra cada requisição em [requests].
Future<AuthRepository> adminSession(
  List<http.Request> requests, {
  String role = 'ADMINISTRADOR',
  String name = 'Arthur Estrela',
  int institutionId = 1,
}) async {
  final institutions = <Map<String, dynamic>>[
    {
      'id': 1,
      'nome': 'IF Goiano',
      'cnpj': '10651417000500',
      'telefone': '6434651900',
      'situacao': 'ATIVA',
      'criadoEm': '12/11/2026 09:30:00',
    },
    {
      'id': 2,
      'nome': 'Escola Caminhos',
      'cnpj': '44522100000108',
      'telefone': '6234401820',
      'situacao': 'INATIVA',
      'criadoEm': '13/11/2026 10:00:00',
    },
  ];
  final users = <Map<String, dynamic>>[
    {
      'id': 10,
      'nome': 'Marina Costa',
      'email': 'marina@ifgoiano.edu.br',
      'role': 'ADMIN_INSTITUICAO',
      'instituicaoId': 1,
      'instituicaoNome': 'IF Goiano',
      'ativo': true,
      'criadoEm': '14/11/2026 08:00:00',
    },
    {
      'id': 11,
      'nome': 'Lucas Ferreira',
      'email': 'lucas@ifgoiano.edu.br',
      'role': 'COORDENADOR',
      'instituicaoId': 1,
      'instituicaoNome': 'IF Goiano',
      'ativo': true,
      'criadoEm': '15/11/2026 08:00:00',
    },
  ];
  var nextId = 100;
  final auth = AuthRepository(
    api: fakeAuthApi(
      claims: professorClaims(
        nome: name,
        role: role,
        instituicaoId: institutionId,
      ),
      extra: (request) async {
        requests.add(request);
        final path = request.url.path;
        final body = request.body.isEmpty ? null : jsonDecode(request.body);
        switch ((request.method, path)) {
          case ('GET', '/api/instituicoes/listar-instituicoes'):
            return jsonResponse(institutions, 200);
          case ('GET', '/api/usuarios/listar-usuarios'):
            return jsonResponse(users, 200);
          case ('POST', '/api/instituicoes/cadastrar-instituicao'):
            final created = {
              ...(body as Map<String, dynamic>),
              'id': nextId++,
              'situacao': 'ATIVA',
              'criadoEm': '24/11/2026 18:00:00',
            };
            institutions.add(created);
            return jsonResponse(created, 201);
        }
        final byId = RegExp(r'^/api/instituicoes/buscar-instituicao/(\d+)$')
            .firstMatch(path);
        if (request.method == 'GET' && byId != null) {
          return jsonResponse(
            institutions.firstWhere((it) => '${it['id']}' == byId[1]),
            200,
          );
        }
        final toggle = RegExp(
          r'^/api/(instituicoes|usuarios)/(ativar|desativar)-(instituicao|usuario)/(\d+)$',
        ).firstMatch(path);
        if (request.method == 'PATCH' && toggle != null) {
          final list = toggle[1] == 'instituicoes' ? institutions : users;
          final item = list.firstWhere((it) => '${it['id']}' == toggle[4]);
          if (toggle[1] == 'instituicoes') {
            item['situacao'] = toggle[2] == 'ativar' ? 'ATIVA' : 'INATIVA';
          } else {
            item['ativo'] = toggle[2] == 'ativar';
          }
          return jsonResponse(item, 200);
        }
        return null;
      },
    ),
  );
  await auth.login(email: 'arthur@classvision.app', password: 'senha123');
  return auth;
}

/// [AdminRepository] já carregado a partir de [adminSession], com todos os
/// serviços respondendo.
Future<(AuthRepository, AdminRepository)> loadedAdmin({
  String role = 'ADMINISTRADOR',
  String name = 'Arthur Estrela',
  List<http.Request>? requests,
}) async {
  final auth = await adminSession(requests ?? [], role: role, name: name);
  final admin = AdminRepository(
    auth: auth,
    healthClient: MockClient((_) async => http.Response('{}', 200)),
  );
  await admin.load();
  await admin.checkServices();
  return (auth, admin);
}
