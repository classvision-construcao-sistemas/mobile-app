import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
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
    expect(find.text('Nenhuma turma encontrada'), findsOneWidget);
  });

  testWidgets('shows session students and editable attendance statuses', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = SchoolRepository()
      ..addClass(name: 'Turma A', room: 'Sala 1', time: '08:00');
    final classId = repository.classes.single.id;
    repository.addStudent(
      classId,
      const Student(
        id: 'student-1',
        name: 'Aluno Teste',
        registration: 'student-1',
        guardian: '',
        phone: '',
        status: AttendanceStatus.review,
        confidence: .63,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => repository,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AttendanceReviewPage(classId: classId),
        ),
      ),
    );

    expect(find.text('Conferir chamada'), findsOneWidget);
    expect(find.text('Aluno Teste'), findsOneWidget);
    expect(find.text('Tirar nova foto'), findsOneWidget);
    expect(find.text('Confirmar chamada'), findsOneWidget);
    expect(find.text('Revisar'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
