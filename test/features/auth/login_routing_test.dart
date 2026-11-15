import 'package:class_vision/app.dart';
import 'package:class_vision/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ClassVisionApp());
  }

  Future<void> signIn(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextFormField).first, email);
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

  testWidgets('signing out returns to the neutral login', (tester) async {
    await pumpApp(tester, size: const Size(1440, 1024));
    await signIn(tester, 'arthur@classvision.app');

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Acesso ao ClassVision'), findsOneWidget);
  });
}
