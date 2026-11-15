import 'package:class_vision/core/navigation/app_routes.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/features/attendance/views/attendance_saved_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
