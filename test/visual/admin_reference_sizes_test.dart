import 'package:class_vision/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_server.dart';

void main() {
  Future<void> startApp(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ClassVisionApp(authApi: roleAwareFakeAuthApi()));
  }

  Future<void> login(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Acessar plataforma'));
    await tester.pumpAndSettle();
  }

  Future<void> openDestination(
    WidgetTester tester,
    String label,
    String expected,
  ) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
    expect(find.text(expected), findsWidgets);
    expect(tester.takeException(), isNull);
  }

  testWidgets('references 01–06 and 08 render at 1440 × 1024', (tester) async {
    await startApp(tester, const Size(1440, 1024));
    await login(tester, 'lucas.ferreira@ifgoiano.edu.br');

    expect(find.text('Bom dia, Lucas'), findsOneWidget); // 01
    expect(tester.takeException(), isNull);
    await openDestination(
      tester,
      'Turmas',
      'Gerencie as turmas, docentes e o acompanhamento de presença.',
    ); // 02
    await openDestination(
      tester,
      'Alunos',
      'Consulte registros, presença e informações de matrícula.',
    ); // 04
    await openDestination(
      tester,
      'Professores',
      'Acompanhe docentes, turmas atribuídas e convites pendentes.',
    ); // 05
    await openDestination(tester, 'Chamadas', 'Histórico de chamadas'); // 06
    await openDestination(tester, 'Relatórios', 'Evolução da presença'); // 08
  });

  testWidgets(
    'references 03 and 07 render session-backed desktop detail flows',
    (tester) async {
      await startApp(tester, const Size(1440, 1024));
      await login(tester, 'lucas.ferreira@ifgoiano.edu.br');
      await tester.tap(find.text('Turmas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2º Ano A').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Detalhes da turma'), findsOneWidget); // 03
      expect(find.text('Lista de alunos'), findsNothing);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chamadas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revisar →'));
      await tester.pumpAndSettle();
      expect(find.text('Revisar chamada'), findsOneWidget); // 07
      expect(find.text('Lista de presença'), findsOneWidget);
      expect(find.text('Beatriz Nogueira'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('references 09–15 and 25 render at 390 × 844', (tester) async {
    await startApp(tester, const Size(390, 844));
    await login(tester, 'lucas.ferreira@ifgoiano.edu.br');

    expect(find.text('Olá, Lucas'), findsOneWidget); // 10
    await openDestination(
      tester,
      'Turmas',
      '28 turmas no semestre 2026/2',
    ); // 11
    await openDestination(
      tester,
      'Chamadas',
      'Histórico de presença e pendências',
    ); // 12
    await openDestination(
      tester,
      'Relatórios',
      'Indicadores de 01 a 14 de novembro',
    ); // 13
    await openDestination(tester, 'Mais', 'Coordenador · IF Goiano'); // 14
    await openDestination(
      tester,
      'Notificações',
      '3 notificações não lidas',
    ); // 15

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(ClassVisionApp(authApi: roleAwareFakeAuthApi()));
    await login(tester, 'marina.costa@ifgoiano.edu.br');
    expect(find.text('Equipe da instituição'), findsOneWidget); // 25
    expect(tester.takeException(), isNull);
  });

  testWidgets('references 16–24 render at 1440 × 1024', (tester) async {
    await startApp(tester, const Size(1440, 1024));
    expect(
      find.text('Acesso ao ClassVision'),
      findsOneWidget,
    ); // 16 neutral approved login
    await login(tester, 'arthur@classvision.app');
    expect(find.text('Visão geral da plataforma'), findsOneWidget); // 17
    expect(tester.takeException(), isNull);
    await openDestination(
      tester,
      'Instituições',
      'Gestão de instituições',
    ); // 18
    await tester.tap(find.text('+ Nova instituição'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastrar instituição'), findsOneWidget); // 19
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IF Goiano'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes da instituição'), findsOneWidget); // 20
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Administradores'));
    await tester.pumpAndSettle();
    expect(find.text('Administradores institucionais'), findsOneWidget); // 21
    await openDestination(tester, 'Atividade', 'Auditoria'); // 22
    await openDestination(
      tester,
      'Configurações',
      'Política de convites',
    ); // 23
    await openDestination(tester, 'Instituições', 'Gestão de instituições');
    await tester.tap(find.text('+ Nova instituição'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar instituição e enviar convite'));
    await tester.pumpAndSettle();
    expect(find.text('Instituição cadastrada!'), findsOneWidget); // 24
    expect(tester.takeException(), isNull);
  });

  testWidgets('responsive boundary switches shells exactly at 900 px', (
    tester,
  ) async {
    await startApp(tester, const Size(899, 844));
    await login(tester, 'lucas.ferreira@ifgoiano.edu.br');
    expect(find.text('Olá, Lucas'), findsOneWidget);
    expect(find.text('Mais'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(900, 844));
    await tester.pumpAndSettle();
    expect(find.text('Lucas Ferreira'), findsOneWidget);
    expect(find.text('Mais'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
