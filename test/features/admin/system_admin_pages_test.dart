import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/admin/views/system_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_admin_backend.dart';

void main() {
  Future<void> pumpSystemAdmin(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (auth, admin) = (await tester.runAsync(loadedAdmin))!;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthRepository>.value(value: auth),
          ChangeNotifierProvider<AdminRepository>.value(value: admin),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SystemAdminShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectNoAcademicDestinations() {
    expect(find.text('Turmas'), findsNothing);
    expect(find.text('Alunos'), findsNothing);
    expect(find.text('Chamadas'), findsNothing);
    expect(find.text('Presença'), findsNothing);
  }

  testWidgets('renders the global dashboard with real platform data', (
    tester,
  ) async {
    await pumpSystemAdmin(tester);

    expect(find.text('Visão geral da plataforma'), findsOneWidget);
    expect(find.text('INSTITUIÇÕES'), findsOneWidget);
    expect(find.text('Atividade recente'), findsOneWidget);
    expect(find.text('Coordenador de curso cadastrado'), findsOneWidget);
    expect(find.text('Status dos serviços'), findsOneWidget);
    expect(find.text('Operacional'), findsNWidgets(4));
    expect(find.text('Nova instituição'), findsOneWidget);
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
    expect(find.text('IF Goiano'), findsOneWidget);
    expect(find.text('Escola Caminhos'), findsOneWidget);

    await tester.tap(find.text('Todos os status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suspensas').last);
    await tester.pumpAndSettle();
    expect(find.text('IF Goiano'), findsNothing);
    expect(find.text('Escola Caminhos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Administradores'));
    await tester.pumpAndSettle();
    expect(find.text('Administradores institucionais'), findsOneWidget);
    expect(find.text('CADASTRO'), findsOneWidget);
    expect(find.text('Marina Costa'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'inexistente');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum administrador encontrado.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Atividade'));
    await tester.pumpAndSettle();
    expect(find.text('Atividade da plataforma'), findsOneWidget);
    expect(find.text('Instituição cadastrada'), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'lucas');
    await tester.pumpAndSettle();
    expect(find.text('Instituição cadastrada'), findsNothing);
    expect(find.text('Coordenador de curso cadastrado'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Configurações da plataforma'), findsOneWidget);
    expect(find.text('Endereços dos serviços'), findsOneWidget);
    expect(find.text('Verificar serviços'), findsOneWidget);
    expectNoAcademicDestinations();
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the institution detail with its real team', (
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
    expect(find.text('Lucas Ferreira'), findsWidgets);
    expect(find.text('Marina Costa'), findsWidgets);
    expectNoAcademicDestinations();
    expect(tester.takeException(), isNull);
  });

  testWidgets('suspends and reactivates an institution through the API', (
    tester,
  ) async {
    await pumpSystemAdmin(tester);
    await tester.tap(find.text('Instituições'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escola Caminhos'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum coordenador vinculado.'), findsOneWidget);
    expect(find.text('Lucas Ferreira'), findsNothing);

    await tester.tap(find.text('Reativar acesso'));
    await tester.pumpAndSettle();
    expect(find.text('Reativar acesso?'), findsOneWidget);
    await tester.tap(find.text('Reativar').last);
    await tester.pumpAndSettle();
    expect(find.text('Suspender acesso'), findsOneWidget);

    await tester.tap(find.text('Suspender acesso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suspender').last);
    await tester.pumpAndSettle();
    expect(find.text('Reativar acesso'), findsOneWidget);
  });
}
