import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/institution_admin/views/institution_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_admin_backend.dart';
import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester,
    Size size, {
    int initialIndex = 6,
    bool withData = true,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (auth, admin) = withData
        ? (await tester.runAsync(
            () => loadedAdmin(role: 'ADMIN_INSTITUICAO', name: 'Marina Costa'),
          ))!
        : (AuthRepository(api: roleAwareFakeAuthApi()), AdminRepository());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminRepository>.value(value: admin),
          ChangeNotifierProvider(
            create: (_) => SchoolRepository()..seedClasses([courseClass()]),
          ),
          ChangeNotifierProvider<AuthRepository>.value(value: auth),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: InstitutionAdminShell(initialIndex: initialIndex),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the institutional settings with the real team', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1440, 1024));

    expect(find.byKey(const Key('institution-admin-shell')), findsOneWidget);
    expect(find.text('Configurações'), findsWidgets);
    expect(
      find.text(
        'Gerencie a instituição, a equipe e as integrações do ClassVision.',
      ),
      findsOneWidget,
    );
    expect(find.text('Equipe de coordenação'), findsOneWidget);
    expect(find.text('Coordenadores'), findsWidgets);
    expect(find.text('Lucas Ferreira'), findsOneWidget);
    expect(find.text('Permissões do coordenador'), findsOneWidget);
    expect(find.text('Marina Costa'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches the mobile coordinator management layout', (
    tester,
  ) async {
    await pumpShell(tester, const Size(390, 844));

    expect(find.text('Coordenadores'), findsWidgets);
    expect(find.text('Administrador da instituição'), findsOneWidget);
    expect(find.text('Buscar coordenador'), findsOneWidget);
    expect(find.text('Cadastrar coordenador'), findsOneWidget);
    expect(find.text('Equipe da instituição'), findsOneWidget);
    expect(find.text('Lucas Ferreira'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(
      find.text('Somente administradores da instituição podem'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings tabs show institution data and service status', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1440, 1024));

    await tester.tap(find.text('Instituição').first);
    await tester.pumpAndSettle();
    expect(find.text('Dados da instituição'), findsOneWidget);
    expect(find.text('10.651.417/0005-00'), findsOneWidget);
    expect(find.text('Ativa'), findsOneWidget);

    await tester.tap(find.text('Integrações'));
    await tester.pumpAndSettle();
    expect(find.text('Reconhecimento facial'), findsOneWidget);
    expect(find.text('Operacional'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview notification button opens the notifications page', (
    tester,
  ) async {
    await pumpShell(
      tester,
      const Size(1440, 1024),
      initialIndex: 0,
      withData: false,
    );

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Notificações'), findsOneWidget);
    // A turma de teste não tem alunos nem chamadas: nada a notificar.
    expect(find.text('Nenhuma notificação por enquanto.'), findsOneWidget);
  });

  testWidgets('coordinator login never exposes institution administration', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ClassVisionApp(authApi: roleAwareFakeAuthApi(), turmaApi: fakeTurmaApi()),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'coordenacao@escola.edu.br',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Acessar plataforma'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coordinator-shell')), findsOneWidget);
    expect(find.text('Coordenadores'), findsNothing);
    expect(find.text('Configurações'), findsNothing);
  });
}
