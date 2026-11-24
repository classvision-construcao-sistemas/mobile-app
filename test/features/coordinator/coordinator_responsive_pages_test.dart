import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/classes/views/class_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<void> signIn(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ClassVisionApp(authApi: roleAwareFakeAuthApi(), turmaApi: fakeTurmaApi()),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'lucas.ferreira@ifgoiano.edu.br',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
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
      find.text(
        'Gerencie as turmas, os cursos e o acompanhamento de presença.',
      ),
      findsOneWidget,
    );
    expect(find.text('2º Ano A'), findsOneWidget);
    expect(find.text('Técnico em Informática'), findsWidgets);
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
    // Sem dados fictícios: o histórico começa vazio a cada sessão.
    expect(find.text('Nenhuma chamada registrada.'), findsOneWidget);
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
    // Data de hoje por extenso (ex.: "Terça-feira, 24 de novembro").
    expect(
      find.textContaining(
        RegExp(
          r'^(Segunda|Terça|Quarta|Quinta|Sexta)-feira, \d+ de |^(Sábado|Domingo), \d+ de ',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Resumo de hoje'), findsOneWidget);

    await tester.tap(find.text('Turmas'));
    await tester.pumpAndSettle();
    expect(find.text('3 turmas cadastradas'), findsOneWidget);
    expect(find.text('2º Ano D'), findsOneWidget);
    expect(find.text('Vespertino'), findsOneWidget);

    await tester.tap(find.text('Chamadas'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de presença das turmas'), findsOneWidget);
    expect(find.text('Nenhuma chamada registrada.'), findsOneWidget);

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
    await tester.tap(find.text('Marcar todas como lidas'));
    await tester.pump();
    expect(find.text('Nenhuma notificação não lida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the desktop class detail and preserves session data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = SchoolRepository()..seedClasses([courseClass()]);
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
    expect(find.text('Alunos da turma'), findsOneWidget);
    expect(find.text('Ações rápidas'), findsOneWidget);
    expect(find.text('Beatriz Nogueira'), findsOneWidget);
    expect(find.text('Sala 204 · Turno matutino'), findsOneWidget);
    // Sem sessão com perfil de gestão, a turma não pode ser editada.
    expect(find.text('Editar turma'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
