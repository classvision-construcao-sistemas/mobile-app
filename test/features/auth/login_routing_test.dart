import 'package:class_vision/app.dart';
import 'package:class_vision/core/navigation/app_routes.dart';
import 'package:class_vision/features/home/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ClassVisionApp(authApi: roleAwareFakeAuthApi(), turmaApi: fakeTurmaApi()),
    );
  }

  Future<void> signIn(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Acessar plataforma'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a neutral login before the role is known', (tester) async {
    await pumpApp(tester);

    expect(find.text('Acesso ao ClassVision'), findsOneWidget);
    expect(find.text('Administrador do Sistema'), findsNothing);
  });

  testWidgets('routes system administrators to their protected shell', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1440, 1024));
    await signIn(tester, 'arthur@classvision.app');

    expect(find.byKey(const Key('system-admin-shell')), findsOneWidget);
    expect(find.byKey(const Key('coordinator-shell')), findsNothing);
  });

  testWidgets('routes institution administrators to their protected shell', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester, 'marina.costa@ifgoiano.edu.br');

    expect(find.byKey(const Key('institution-admin-shell')), findsOneWidget);
  });

  testWidgets('routes other institutional users to the coordinator shell', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester, 'coordenacao@escola.edu.br');

    expect(find.byKey(const Key('coordinator-shell')), findsOneWidget);
  });

  testWidgets('blocks a coordinator from opening the system admin route', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester, 'coordenacao@escola.edu.br');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.systemAdmin);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coordinator-shell')), findsOneWidget);
    expect(find.byKey(const Key('system-admin-shell')), findsNothing);
  });

  testWidgets('blocks system administrators from every academic route', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1440, 1024));
    await signIn(tester, 'arthur@classvision.app');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (final route in [
      AppRoutes.home,
      AppRoutes.classes,
      AppRoutes.camera,
      AppRoutes.review,
      AppRoutes.classRegistration,
    ]) {
      navigator.pushNamed(route);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('system-admin-shell')),
        findsOneWidget,
        reason: route,
      );
      expect(
        find.byKey(const Key('coordinator-shell')),
        findsNothing,
        reason: route,
      );
    }
  });

  testWidgets('keeps institution administrators in their role-aware shell', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1440, 1024));
    await signIn(tester, 'marina.costa@ifgoiano.edu.br');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('institution-admin-shell')), findsOneWidget);
    expect(find.byKey(const Key('coordinator-shell')), findsNothing);
    expect(find.text(homeGreeting('Marina')), findsOneWidget);
  });

  testWidgets('signing out returns to the neutral login', (tester) async {
    await pumpApp(tester, size: const Size(1440, 1024));
    await signIn(tester, 'arthur@classvision.app');

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Acesso ao ClassVision'), findsOneWidget);
  });

  testWidgets('system administrator can sign out from the mobile blocker', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester, 'arthur@classvision.app');

    expect(find.text('Acesse pelo computador'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Acesso ao ClassVision'), findsOneWidget);
  });

  testWidgets('institution administrator can sign out from mobile management', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester, 'marina.costa@ifgoiano.edu.br');

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Acesso ao ClassVision'), findsOneWidget);
  });

  testWidgets('unknown JWT role cannot open academic routes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ClassVisionApp(
        authApi: fakeAuthApi(claims: professorClaims(role: 'DESCONHECIDO')),
        turmaApi: fakeTurmaApi(),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'desconhecido@escola.edu.br',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Acessar plataforma'));
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.classDetails, arguments: 'class-2a');
    await tester.pumpAndSettle();

    expect(find.text('Acesso ao ClassVision'), findsOneWidget);
    expect(find.textContaining('Detalhes da turma'), findsNothing);
  });

  testWidgets('system administrator can reach connected institution CRUD', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1440, 1024));
    await signIn(tester, 'arthur@classvision.app');

    await tester.tap(find.text('Gerenciar instituições'));
    await tester.pumpAndSettle();

    expect(find.text('Nova instituição'), findsOneWidget);
  });

  testWidgets('institution administrator can reach connected user CRUD', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1440, 1024));
    await signIn(tester, 'marina.costa@ifgoiano.edu.br');

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuários e acessos'));
    await tester.pumpAndSettle();

    expect(find.text('Novo usuário'), findsOneWidget);
  });
}
