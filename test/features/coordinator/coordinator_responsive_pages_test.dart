import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/classes/views/class_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> signIn(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ClassVisionApp());
    await tester.enterText(
      find.byType(TextFormField).first,
      'lucas.ferreira@ifgoiano.edu.br',
    );
    await tester.tap(find.text('Acessar plataforma'));
    await tester.pumpAndSettle();
  }

  testWidgets('matches the coordinator desktop workspace references', (
    tester,
  ) async {
    await signIn(tester, const Size(1440, 1024));

    expect(find.text('Bom dia, Lucas'), findsOneWidget);
    expect(find.text('Presença ao longo da semana'), findsOneWidget);
    expect(find.text('Chamadas para revisar'), findsOneWidget);
    expect(find.text('Lucas Ferreira'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Turmas'));
    await tester.pumpAndSettle();
    expect(
      find.text('Gerencie as turmas, docentes e o acompanhamento de presença.'),
      findsOneWidget,
    );
    expect(find.text('2026/2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Alunos'));
    await tester.pumpAndSettle();
    expect(
      find.text('Consulte registros, presença e informações de matrícula.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Professores'));
    await tester.pumpAndSettle();
    expect(
      find.text('Acompanhe docentes, turmas atribuídas e convites pendentes.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Chamadas'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de chamadas'), findsOneWidget);
    expect(find.text('Em revisão'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Relatórios'));
    await tester.pumpAndSettle();
    expect(find.text('Evolução da presença'), findsOneWidget);
    expect(find.text('Turmas com menor presença'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches all mobile coordinator references', (tester) async {
    await signIn(tester, const Size(390, 844));

    expect(find.text('Olá, Lucas'), findsOneWidget);
    expect(find.text('Sábado, 14 de novembro'), findsOneWidget);
    expect(find.text('Resumo de hoje'), findsOneWidget);

    await tester.tap(find.text('Turmas'));
    await tester.pumpAndSettle();
    expect(find.text('28 turmas no semestre 2026/2'), findsOneWidget);
    expect(find.text('Filtros rápidos'), findsOneWidget);

    await tester.tap(find.text('Chamadas'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de presença e pendências'), findsOneWidget);
    expect(find.text('Requer revisão'), findsOneWidget);

    await tester.tap(find.text('Relatórios'));
    await tester.pumpAndSettle();
    expect(find.text('Indicadores de 01 a 14 de novembro'), findsOneWidget);
    expect(find.text('Evolução semanal'), findsOneWidget);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    expect(find.text('Coordenador · IF Goiano'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);
    await tester.tap(find.text('Notificações'));
    await tester.pumpAndSettle();
    expect(find.text('3 notificações não lidas'), findsOneWidget);
    expect(find.text('Marcar todas como lidas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the desktop class detail and preserves session data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = SchoolRepository()
      ..addClass(name: '2º Ano A', room: 'Sala 204', time: '07:30–12:50');
    final classId = repository.classes.single.id;
    repository.addStudent(
      classId,
      const Student(
        id: 'student-1',
        name: 'Beatriz Nogueira',
        registration: '20260242',
        guardian: '',
        phone: '',
        status: AttendanceStatus.present,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ClassDetailsPage(classId: classId),
        ),
      ),
    );

    expect(find.text('Dados da turma'), findsOneWidget);
    expect(find.text('Presença mensal'), findsOneWidget);
    expect(find.text('Ações rápidas'), findsOneWidget);
    expect(find.text('Beatriz Nogueira'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
