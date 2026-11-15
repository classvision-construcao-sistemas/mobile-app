import 'dart:convert';

import 'package:class_vision/data/models/auth_models.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/data/services/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_server.dart';

AppUser _user({
  required int id,
  required String role,
  int institutionId = 1,
}) => AppUser(
  id: id,
  name: 'Usuário $id',
  email: 'usuario$id@escola.edu.br',
  cpf: '52998224725',
  roleName: role,
  institutionId: institutionId,
);

void main() {
  test('logs in, exposes the session and loads the institution', () async {
    final auth = AuthRepository(api: fakeAuthApi());
    addTearDown(auth.dispose);
    var notifications = 0;
    auth.addListener(() => notifications++);

    await auth.login(email: 'maria@classvision.com', password: 'senha123');
    await pumpEventQueue();

    expect(auth.isAuthenticated, isTrue);
    expect(auth.session?.name, 'Maria Souza');
    expect(auth.role, UserRole.professor);
    expect(
      auth.institution?.name,
      'Instituto Federal Goiano - Campus Urutaí',
    );
    expect(notifications, greaterThanOrEqualTo(2));
  });

  test('keeps the user logged out when the credentials are wrong', () async {
    final auth = AuthRepository(api: fakeAuthApi());
    addTearDown(auth.dispose);

    await expectLater(
      auth.login(email: 'maria@classvision.com', password: 'errada'),
      throwsA(isA<AuthApiException>()),
    );
    expect(auth.isAuthenticated, isFalse);
  });

  test('ends the session when a protected route answers 401', () async {
    final auth = AuthRepository(
      api: fakeAuthApi(
        claims: professorClaims(role: 'COORDENADOR'),
        extra: (request) async =>
            request.url.path == '/api/usuarios/listar-usuarios'
            ? apiError(401, 'Acesso nao autorizado.')
            : null,
      ),
    );
    addTearDown(auth.dispose);
    await auth.login(email: 'coord@classvision.com', password: 'senha123');

    await expectLater(auth.listUsers(), throwsA(isA<AuthApiException>()));

    expect(auth.isAuthenticated, isFalse);
    expect(auth.consumeLogoutReason(), contains('sessão'));
    expect(auth.consumeLogoutReason(), isNull);
  });

  test('logs in again after the user edits the own profile', () async {
    var logins = 0;
    final auth = AuthRepository(
      api: fakeAuthApi(
        claims: professorClaims(id: 7, role: 'ADMIN_INSTITUICAO'),
        extra: (request) async {
          if (request.url.path == '/api/auth/login') logins++;
          if (request.url.path == '/api/usuarios/atualizar-usuario/7') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body.containsKey('role'), isFalse);
            return jsonResponse({
              'id': 7,
              'nome': body['nome'],
              'email': body['email'],
              'role': 'ADMIN_INSTITUICAO',
              'ativo': true,
            }, 200);
          }
          return null;
        },
      ),
    );
    addTearDown(auth.dispose);
    await auth.login(email: 'admin@escola.edu.br', password: 'senha123');

    await auth.updateUser(
      7,
      const UserPayload(
        name: 'Ana Admin',
        cpf: '52998224725',
        email: 'ana@escola.edu.br',
        password: 'senha123',
      ),
    );

    expect(logins, 2);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.session?.email, 'ana@escola.edu.br');
  });

  test('mirrors the API rules to decide who can be managed', () async {
    final auth = AuthRepository(
      api: fakeAuthApi(
        claims: professorClaims(id: 7, role: 'ADMIN_INSTITUICAO'),
      ),
    );
    addTearDown(auth.dispose);
    await auth.login(email: 'admin@escola.edu.br', password: 'senha123');

    expect(auth.canManageUser(_user(id: 8, role: 'PROFESSOR')), isTrue);
    expect(auth.canManageUser(_user(id: 9, role: 'ADMIN_INSTITUICAO')), isTrue);
    expect(auth.canManageUser(_user(id: 1, role: 'ADMINISTRADOR')), isFalse);
    expect(
      auth.canManageUser(_user(id: 10, role: 'PROFESSOR', institutionId: 2)),
      isFalse,
    );
    expect(auth.isCurrentUser(_user(id: 7, role: 'ADMIN_INSTITUICAO')), isTrue);
    expect(
      UserRole.adminInstituicao.assignableRoles,
      isNot(contains(UserRole.administrador)),
    );
    expect(UserRole.coordenador.assignableRoles, isEmpty);
  });

  test('logout clears the session and the institution', () async {
    final auth = AuthRepository(api: fakeAuthApi());
    addTearDown(auth.dispose);
    await auth.login(email: 'maria@classvision.com', password: 'senha123');
    await pumpEventQueue();

    auth.logout();

    expect(auth.session, isNull);
    expect(auth.institution, isNull);
    expect(auth.consumeLogoutReason(), isNull);
  });
}
