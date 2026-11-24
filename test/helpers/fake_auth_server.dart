import 'dart:convert';

import 'package:class_vision/data/services/auth_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Monta um JWT com o payload informado (a assinatura não é verificada no app).
String fakeJwt(Map<String, Object?> claims) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS512'})}.${encode(claims)}.assinatura';
}

http.Response jsonResponse(Object? body, int statusCode) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response apiError(int statusCode, String descricao) => jsonResponse({
  'descricao': descricao,
  'statusCode': statusCode,
  'solucao': 'Revise os dados enviados e tente novamente.',
  'dataHora': '2026-11-12T10:14:11.7330021',
}, statusCode);

Map<String, Object?> professorClaims({
  int id = 7,
  String nome = 'Maria Souza',
  String email = 'maria@classvision.com',
  String role = 'PROFESSOR',
  int instituicaoId = 1,
}) => {
  'id': id,
  'nome': nome,
  'email': email,
  'role': role,
  'instituicaoId': instituicaoId,
  'roles': ['ROLE_$role'],
  'sub': email,
  'iat': 1794488290,
  'exp': 1794491890,
};

const institutionJson = {
  'id': 1,
  'nome': 'Instituto Federal Goiano - Campus Urutaí',
  'cnpj': '10651417000500',
  'telefone': '6434651900',
  'situacao': 'ATIVA',
  'criadoEm': '12/11/2026 09:30:00',
  'atualizadoEm': '12/11/2026 09:30:00',
};

/// Serviço de autenticação falso: aceita a senha `senha123` e responde a
/// consulta da instituição 1. Rotas extras podem ser tratadas em [extra].
AuthApi fakeAuthApi({
  Map<String, Object?>? claims,
  Future<http.Response?> Function(http.Request request)? extra,
}) => AuthApi(
  baseUrl: 'http://auth.test',
  client: MockClient((request) async {
    final handled = await extra?.call(request);
    if (handled != null) return handled;

    if (request.method == 'POST' && request.url.path == '/api/auth/login') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['senha'] != 'senha123') {
        return apiError(401, 'Email ou senha inválidos.');
      }
      final email = body['email'] as String;
      return jsonResponse({
        'token': fakeJwt({
          ...(claims ?? professorClaims()),
          'email': email,
          'sub': email,
        }),
        'tipo': 'Bearer',
        'expiresIn': 3600000,
      }, 200);
    }
    if (request.url.path == '/api/instituicoes/buscar-instituicao/1') {
      return jsonResponse(institutionJson, 200);
    }
    return apiError(404, 'Recurso nao encontrado.');
  }),
);

/// Login falso que devolve o perfil correspondente aos e-mails usados nas
/// referências dos painéis administrativo e acadêmico.
AuthApi roleAwareFakeAuthApi() => AuthApi(
  baseUrl: 'http://auth.test',
  client: MockClient((request) async {
    if (request.method == 'POST' && request.url.path == '/api/auth/login') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['senha'] != 'senha123') {
        return apiError(401, 'Email ou senha inválidos.');
      }
      final email = (body['email'] as String).toLowerCase();
      final (name, role, institutionId) = switch (email) {
        'arthur@classvision.app' => ('Arthur Silva', 'ADMINISTRADOR', null),
        'marina.costa@ifgoiano.edu.br' => (
          'Marina Costa',
          'ADMIN_INSTITUICAO',
          1,
        ),
        _ => ('Lucas Ferreira', 'COORDENADOR', 1),
      };
      return jsonResponse({
        'token': fakeJwt(
          professorClaims(
            nome: name,
            email: email,
            role: role,
            instituicaoId: institutionId ?? 0,
          )..['instituicaoId'] = institutionId,
        ),
        'tipo': 'Bearer',
        'expiresIn': 3600000,
      }, 200);
    }
    if (request.url.path == '/api/instituicoes/buscar-instituicao/1') {
      return jsonResponse(institutionJson, 200);
    }
    switch ((request.method, request.url.path)) {
      case ('GET', '/api/instituicoes/listar-instituicoes'):
        return jsonResponse([institutionJson], 200);
      case ('GET', '/api/usuarios/listar-usuarios'):
        return jsonResponse(teamJson, 200);
      case ('POST', '/api/instituicoes/cadastrar-instituicao'):
        return jsonResponse({
          ...(jsonDecode(request.body) as Map<String, dynamic>),
          'id': 2,
          'situacao': 'ATIVA',
          'criadoEm': '24/11/2026 18:00:00',
        }, 201);
    }
    return apiError(404, 'Recurso nao encontrado.');
  }),
);

/// Equipe da instituição 1 usada por [roleAwareFakeAuthApi].
const teamJson = [
  {
    'id': 10,
    'nome': 'Marina Costa',
    'email': 'marina.costa@ifgoiano.edu.br',
    'role': 'ADMIN_INSTITUICAO',
    'instituicaoId': 1,
    'ativo': true,
    'criadoEm': '12/11/2026 10:00:00',
  },
  {
    'id': 11,
    'nome': 'Lucas Ferreira',
    'email': 'lucas.ferreira@ifgoiano.edu.br',
    'role': 'COORDENADOR',
    'instituicaoId': 1,
    'ativo': true,
    'criadoEm': '12/11/2026 11:00:00',
  },
];
