import 'package:class_vision/app.dart';
import 'package:class_vision/core/navigation/app_routes.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/features/attendance/views/attendance_saved_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Widget app() => MaterialApp(
    theme: AppTheme.lightTheme,
    home: const AttendanceSavedPage(classId: 'class-1'),
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => switch (settings.name) {
        AppRoutes.classDetails => const Scaffold(
          key: Key('class-detail-marker'),
          body: Text('Detalhe'),
        ),
        _ => const Scaffold(key: Key('home-marker'), body: Text('Início')),
      },
    ),
  );

  testWidgets('returns to the role home', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Ir para o início'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-marker')), findsOneWidget);
  });

  testWidgets('keeps role home below class detail', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Voltar para a turma'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('class-detail-marker')), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-marker')), findsOneWidget);
  });

  testWidgets('institution administrator returns to overview after saving', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ClassVisionApp(authApi: roleAwareFakeAuthApi(), turmaApi: fakeTurmaApi()),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'marina.costa@ifgoiano.edu.br',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Acessar plataforma'));
    await tester.pumpAndSettle();

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.saved, arguments: 'class-2a');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir para o início'));
    await tester.pumpAndSettle();

    expect(find.text('Bom dia, Marina'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(
      find.text(
        'Gerencie a instituição, a equipe e as integrações do ClassVision.',
      ),
      findsNothing,
    );
  });
}
