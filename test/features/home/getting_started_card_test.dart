import 'package:class_vision/core/navigation/app_routes.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/home/view/getting_started_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<SchoolRepository> coordinator(
    List<Map<String, Object?>> classes,
  ) async {
    final auth = AuthRepository(
      api: fakeAuthApi(claims: professorClaims(role: 'COORDENADOR')),
    );
    await auth.login(email: 'lucas@ifgoiano.edu.br', password: 'senha123');
    final repository = SchoolRepository(
      api: fakeTurmaApi(classes: classes),
      auth: auth,
    );
    await repository.loadClasses();
    return repository;
  }

  Future<List<RouteSettings>> pump(
    WidgetTester tester,
    SchoolRepository repository, {
    ValueChanged<String>? onStart,
  }) async {
    final routes = <RouteSettings>[];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: GettingStartedCard(onStartAttendance: onStart ?? (_) {}),
          ),
          onGenerateRoute: (settings) {
            routes.add(settings);
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Aberto')),
            );
          },
        ),
      ),
    );
    return routes;
  }

  testWidgets('guides a new coordinator to create the first class', (
    tester,
  ) async {
    final repository = (await tester.runAsync(() => coordinator([])))!;
    final routes = await pump(tester, repository);

    expect(find.text('Primeiros passos'), findsOneWidget);
    expect(find.text('0 de 3 concluídos'), findsOneWidget);
    await tester.tap(find.text('Criar turma'));
    await tester.pumpAndSettle();
    expect(routes.single.name, AppRoutes.classRegistration);
  });

  testWidgets('asks for students and then for the first attendance', (
    tester,
  ) async {
    final empty = (await tester.runAsync(() => coordinator([classJson()])))!;
    final routes = await pump(tester, empty);
    expect(find.text('1 de 3 concluídos'), findsOneWidget);
    await tester.tap(find.text('Cadastrar aluno'));
    await tester.pumpAndSettle();
    expect(routes.single.name, AppRoutes.studentRegistration);
    expect(routes.single.arguments, '1');

    final withStudents = (await tester.runAsync(
      () => coordinator([
        classJson(alunos: [20260001]),
      ]),
    ))!;
    String? started;
    await pump(tester, withStudents, onStart: (id) => started = id);
    expect(find.text('2 de 3 concluídos'), findsOneWidget);
    await tester.tap(find.text('Fazer chamada'));
    expect(started, '1');
  });
}
