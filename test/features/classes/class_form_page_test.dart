import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/classes/views/class_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<SchoolRepository> pumpForm(
    WidgetTester tester, {
    String? classId,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = AuthRepository(
      api: fakeAuthApi(claims: professorClaims(role: 'COORDENADOR')),
    );
    await auth.login(email: 'lucas@ifgoiano.edu.br', password: 'senha123');
    final repository = SchoolRepository(api: fakeTurmaApi(), auth: auth);
    await repository.loadClasses();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: repository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ClassFormPage(classId: classId),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('creates a class in the turma-service', (tester) async {
    final repository = await pumpForm(tester);

    expect(find.text('Nova turma'), findsOneWidget);
    await tester.tap(find.text('Cadastrar turma'));
    await tester.pumpAndSettle();
    expect(find.text('Selecione o curso'), findsOneWidget);
    expect(find.text('Informe o nome da turma'), findsOneWidget);
    expect(find.text('Selecione o turno'), findsOneWidget);

    await tester.tap(find.text('Curso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INF-2026 · Técnico em Informática').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da turma'),
      '3º Ano B',
    );
    await tester.tap(find.text('Turno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noturno').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Início das aulas'),
      '09022026',
    );
    await tester.tap(find.text('Cadastrar turma'));
    await tester.pumpAndSettle();

    expect(find.text('Nova turma'), findsNothing);
    final created = repository.classes.firstWhere(
      (it) => it.name == '3º Ano B',
    );
    expect(created.time, 'Noturno');
    expect(created.remote!.startDate, DateTime(2026, 2, 9));
    expect(created.courseName, 'Técnico em Informática');
  });

  testWidgets('edits an existing class', (tester) async {
    final repository = await pumpForm(tester, classId: '1');

    expect(find.text('Editar turma'), findsOneWidget);
    expect(find.text('2º Ano A'), findsOneWidget);
    expect(find.text('09/02/2026'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da turma'),
      '2º Ano A — Atualizada',
    );
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(repository.classById('1').name, '2º Ano A — Atualizada');
    // Os vínculos de alunos continuam após a edição.
    expect(repository.classById('1').students, hasLength(2));
  });
}
