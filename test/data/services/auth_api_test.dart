import 'dart:convert';

import 'package:class_vision/data/models/auth_models.dart';
import 'package:class_vision/data/services/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fake_auth_server.dart';

void main() {
  AuthSession sessionFor(String role) => AuthSession.fromToken(
    fakeJwt(professorClaims(role: role)),
    expiresInMs: 3600000,
  );

  test('logs in and reads the user data from the JWT', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://auth.test/api/auth/login');
      expect(request.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(request.body), {
        'email': 'joao@classvision.com',
        'senha': 'segredo',
      });
      return jsonResponse({
        'token': fakeJwt(
          professorClaims(
            id: 3,
            nome: 'João Conceição',
            email: 'joao@classvision.com',
            role: 'COORDENADOR',
            instituicaoId: 2,
          ),
        ),
        'tipo': 'Bearer',
        'expiresIn': 3600000,
      }, 200);
    });
    final api = AuthApi(client: client, baseUrl: 'http://auth.test/');

    final before = DateTime.now();
    final session = await api.login(
      email: ' joao@classvision.com ',
      password: 'segredo',
    );

    expect(session.userId, 3);
    expect(session.name, 'João Conceição');
    expect(session.firstName, 'João');
    expect(session.initials, 'JC');
    expect(session.email, 'joao@classvision.com');
    expect(session.role, UserRole.coordenador);
    expect(session.institutionId, 2);
    expect(session.authorizationHeader, startsWith('Bearer ey'));
    expect(
      session.expiresAt.difference(before).inMinutes,
      inInclusiveRange(59, 60),
    );
    expect(session.isExpired, isFalse);
  });

  test('surfaces the descricao returned by the API on errors', () async {
    final api = AuthApi(
      baseUrl: 'http://auth.test',
      client: MockClient((_) async => apiError(401, 'Email ou senha inválidos.')),
    );

    await expectLater(
      api.login(email: 'a@b.com', password: 'errada'),
      throwsA(
        isA<AuthApiException>()
            .having((error) => error.message, 'message', 'Email ou senha inválidos.')
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.isUnauthorized, 'isUnauthorized', isTrue),
      ),
    );
  });

  test('uses a default message when the error has no JSON body', () async {
    final api = AuthApi(
      baseUrl: 'http://auth.test',
      client: MockClient((_) async => http.Response('', 403)),
    );

    await expectLater(
      api.listUsers(sessionFor('PROFESSOR')),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.message,
          'message',
          'Você não tem permissão para realizar esta ação.',
        ),
      ),
    );
  });

  test('reports connection failures with the configured address', () async {
    final api = AuthApi(
      baseUrl: 'http://auth.test',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      api.login(email: 'a@b.com', password: 'x'),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.message,
          'message',
          contains('offline'),
        ),
      ),
    );
  });

  test('sends the bearer token and parses the users list', () async {
    final session = sessionFor('ADMIN_INSTITUICAO');
    final api = AuthApi(
      baseUrl: 'http://auth.test',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/usuarios/listar-usuarios');
        expect(request.headers['authorization'], 'Bearer ${session.token}');
        return jsonResponse([
          {
            'id': 2,
            'nome': 'Maria Souza',
            'email': 'maria.souza@classvision.com',
            'cpf': '52998224725',
            'dataNascimento': '25/03/1990',
            'role': 'COORDENADOR',
            'instituicaoId': 1,
            'instituicaoNome': 'Instituto Federal Goiano - Campus Urutaí',
            'criadoEm': '12/11/2026 10:04:57',
            'atualizadoEm': '12/11/2026 10:04:57',
            'ativo': false,
          },
        ], 200);
      }),
    );

    final users = await api.listUsers(session);

    expect(users, hasLength(1));
    final user = users.single;
    expect(user.id, 2);
    expect(user.role, UserRole.coordenador);
    expect(user.roleLabel, 'Coordenador de curso');
    expect(user.birthDate, DateTime(1990, 3, 25));
    expect(user.createdAt, DateTime(2026, 11, 12, 10, 4, 57));
    expect(user.institutionName, 'Instituto Federal Goiano - Campus Urutaí');
    expect(user.active, isFalse);
  });

  test('creates users with the payload expected by the API', () async {
    final api = AuthApi(
      baseUrl: 'http://auth.test',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/usuarios/cadastrar-usuario');
        expect(jsonDecode(request.body), {
          'nome': 'Maria Souza',
          'cpf': '52998224725',
          'email': 'maria@classvision.com',
          'senha': 'senha123',
          'dataNascimento': '05/03/1990',
          'role': 'COORDENADOR',
          'instituicaoId': 2,
        });
        return jsonResponse({
          'id': 9,
          'nome': 'Maria Souza',
          'email': 'maria@classvision.com',
          'cpf': '52998224725',
          'role': 'COORDENADOR',
          'instituicaoId': 2,
          'ativo': true,
        }, 201);
      }),
    );

    final user = await api.createUser(
      sessionFor('ADMINISTRADOR'),
      UserPayload(
        name: ' Maria Souza ',
        cpf: '529.982.247-25',
        email: 'maria@classvision.com',
        password: 'senha123',
        birthDate: DateTime(1990, 3, 5),
        roleName: 'COORDENADOR',
        institutionId: 2,
      ),
    );

    expect(user.id, 9);
  });

  test('omits optional fields so the API keeps role and institution', () {
    const payload = UserPayload(
      name: 'Maria',
      cpf: '52998224725',
      email: 'maria@classvision.com',
      password: 'senha123',
    );

    expect(payload.toJson().keys, ['nome', 'cpf', 'email', 'senha']);
  });

  test('uses the action routes for users and institutions', () async {
    final calls = <String>[];
    final api = AuthApi(
      baseUrl: 'http://auth.test',
      client: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'DELETE') return http.Response('', 204);
        if (request.url.path.contains('instituic')) {
          return jsonResponse(institutionJson, 200);
        }
        return jsonResponse({'id': 5, 'nome': 'Ana', 'ativo': true}, 200);
      }),
    );
    final session = sessionFor('ADMINISTRADOR');

    await api.getUser(session, 5);
    await api.getUserByEmail(session, 'ana@escola.edu.br');
    await api.activateUser(session, 5);
    await api.deactivateUser(session, 5);
    await api.deleteUser(session, 5);
    await api.getInstitution(session, 1);
    await api.activateInstitution(session, 1);
    await api.deactivateInstitution(session, 1);
    final updated = await api.updateInstitution(
      session,
      1,
      const InstitutionPayload(
        name: 'IF Goiano',
        cnpj: '10.651.417/0005-00',
        phone: '(64) 3465-1900',
      ),
    );

    expect(calls, [
      'GET /api/usuarios/buscar-usuario/5',
      'GET /api/usuarios/buscar-usuario-por-email/ana%40escola.edu.br',
      'PATCH /api/usuarios/ativar-usuario/5',
      'PATCH /api/usuarios/desativar-usuario/5',
      'DELETE /api/usuarios/excluir-usuario/5',
      'GET /api/instituicoes/buscar-instituicao/1',
      'PATCH /api/instituicoes/ativar-instituicao/1',
      'PATCH /api/instituicoes/desativar-instituicao/1',
      'PUT /api/instituicoes/atualizar-instituicao/1',
    ]);
    expect(updated.formattedCnpj, '10.651.417/0005-00');
    expect(updated.formattedPhone, '(64) 3465-1900');
    expect(updated.active, isTrue);
  });
}
