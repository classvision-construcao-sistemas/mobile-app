import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/attendance/views/attendance_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_auth_server.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ClassVisionApp(authApi: fakeAuthApi()));
  }

  Future<void> signIn(WidgetTester tester, {String password = 'senha123'}) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'maria@classvision.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the login of the authentication service', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('shows the message returned for invalid credentials', (
    tester,
  ) async {
    await pumpApp(tester);

    await signIn(tester, password: 'errada');

    expect(find.text('Email ou senha inválidos.'), findsOneWidget);
    expect(find.textContaining('Bom dia'), findsNothing);
  });

  testWidgets('signs in, navigates to classes and preserves the shell', (
    tester,
  ) async {
    await pumpApp(tester);

    await signIn(tester);
    expect(find.text('Bom dia, Maria'), findsOneWidget);

    await tester.tap(find.text('Turmas'));
    await tester.pumpAndSettle();
    expect(find.text('Nova turma'), findsOneWidget);
    expect(find.text('Nenhuma turma encontrada'), findsOneWidget);
  });

  testWidgets('shows the token data on the profile and logs out', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('Professor'), findsOneWidget);
    expect(
      find.text('Instituto Federal Goiano - Campus Urutaí'),
      findsOneWidget,
    );
    expect(find.text('Usuários'), findsNothing);

    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
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
