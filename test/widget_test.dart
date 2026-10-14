import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/repositories/mock_school_repository.dart';
import 'package:class_vision/features/attendance/views/attendance_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('starts on the interactive coordinator login', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ClassVisionApp());

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('navigates from login to classes and preserves the shell', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ClassVisionApp());
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bom dia'), findsOneWidget);

    await tester.tap(find.text('Turmas'));
    await tester.pumpAndSettle();
    expect(find.text('Nova turma'), findsOneWidget);
    expect(find.text('2º Ano A'), findsOneWidget);
  });

  testWidgets('shows mock students and editable attendance statuses', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MockSchoolRepository(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AttendanceReviewPage(classId: '2a'),
        ),
      ),
    );

    expect(find.text('Conferir chamada'), findsOneWidget);
    expect(find.text('Ana Beatriz'), findsOneWidget);
    expect(find.text('Tirar nova foto'), findsOneWidget);
    expect(find.text('Confirmar chamada'), findsOneWidget);
    expect(find.text('Revisar'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
