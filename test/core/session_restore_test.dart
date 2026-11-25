import 'dart:convert';

import 'package:class_vision/app.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/data/services/session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_server.dart';
import '../helpers/fake_turma_server.dart';

void main() {
  test('keeps the session in the store until logout', () async {
    final store = MemorySessionStore();
    final first = AuthRepository(api: fakeAuthApi(), store: store);
    await first.login(email: 'maria@classvision.com', password: 'senha123');
    expect(store.read(), isNotNull);

    final reloaded = AuthRepository(api: fakeAuthApi(), store: store);
    expect(reloaded.isAuthenticated, isTrue);
    expect(reloaded.session!.token, first.session!.token);
    expect(reloaded.session!.name, 'Maria Souza');

    reloaded.logout();
    expect(store.read(), isNull);
    expect(AuthRepository(api: fakeAuthApi(), store: store).session, isNull);
  });

  test('drops an expired or broken stored session', () {
    final expired = MemorySessionStore()
      ..write(
        jsonEncode({
          'token': fakeJwt(professorClaims()),
          'tipo': 'Bearer',
          'expiraEm': DateTime.now()
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
        }),
      );
    expect(AuthRepository(api: fakeAuthApi(), store: expired).session, isNull);
    expect(expired.read(), isNull);

    final broken = MemorySessionStore()..write('{nao-e-json');
    expect(AuthRepository(api: fakeAuthApi(), store: broken).session, isNull);
    expect(broken.read(), isNull);
  });

  testWidgets('reopens the same tab after a page reload', (tester) async {
    final store = MemorySessionStore()
      ..write(
        jsonEncode({
          'token': fakeJwt(professorClaims(role: 'COORDENADOR')),
          'tipo': 'Bearer',
          'expiraEm': DateTime.now()
              .add(const Duration(minutes: 30))
              .toIso8601String(),
        }),
      );
    tester.platformDispatcher.defaultRouteNameTestValue = '/home?aba=turmas';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ClassVisionApp(
        authApi: fakeAuthApi(),
        turmaApi: fakeTurmaApi(),
        sessionStore: store,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coordinator-shell')), findsOneWidget);
    expect(find.text('Acessar plataforma'), findsNothing);
    expect(find.text('Buscar turma'), findsOneWidget);
  });
}
