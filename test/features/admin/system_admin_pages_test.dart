import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/admin/views/system_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpSystemAdmin(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AdminRepository(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SystemAdminShell(),
        ),
      ),
    );
  }

  void expectNoAcademicDestinations() {
    expect(find.text('Turmas'), findsNothing);
    expect(find.text('Alunos'), findsNothing);
    expect(find.text('Chamadas'), findsNothing);
    expect(find.text('Presença'), findsNothing);
  }

  testWidgets('renders the global dashboard from reference 17', (tester) async {
    await pumpSystemAdmin(tester);

    expect(find.text('Visão geral da plataforma'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text('Atividade recente'), findsOneWidget);
    expect(find.text('Status dos serviços'), findsOneWidget);
    expect(find.text('+ Nova instituição'), findsOneWidget);
    expectNoAcademicDestinations();
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigates through all global administration destinations', (
    tester,
  ) async {
    await pumpSystemAdmin(tester);

    await tester.tap(find.text('Instituições'));
    await tester.pumpAndSettle();
    expect(find.text('Gestão de instituições'), findsOneWidget);
    expect(find.text('Colégio Horizonte'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Administradores'));
    await tester.pumpAndSettle();
    expect(find.text('Administradores institucionais'), findsOneWidget);
    expect(find.text('ÚLTIMO ACESSO'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Atividade'));
    await tester.pumpAndSettle();
    expect(find.text('Atividade da plataforma'), findsOneWidget);
    expect(find.text('Todos os usuários'), findsOneWidget);
    expect(find.text('Auditoria'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Configurações da plataforma'), findsOneWidget);
    expect(find.text('Política de convites'), findsOneWidget);
    expect(find.text('Notificações administrativas'), findsOneWidget);
    expectNoAcademicDestinations();
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the institution detail as a read-only global summary', (
    tester,
  ) async {
    await pumpSystemAdmin(tester);
    await tester.tap(find.text('Instituições'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('IF Goiano'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da instituição'), findsOneWidget);
    expect(find.text('Somente leitura'), findsOneWidget);
    expect(find.text('Atividade institucional'), findsOneWidget);
    expect(find.text('Lucas Ferreira'), findsOneWidget);
    expect(find.text('Juliana Prado'), findsOneWidget);
    expect(find.text('Fernanda Alves'), findsOneWidget);
    expectNoAcademicDestinations();
    expect(tester.takeException(), isNull);
  });
}
