import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/institution_admin/views/institution_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester,
    Size size, {
    int initialIndex = 6,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AdminRepository()),
          ChangeNotifierProvider(
            create: (_) => SchoolRepository()..seedClasses([courseClass()]),
          ),
          ChangeNotifierProvider(
            create: (_) => AuthRepository(api: roleAwareFakeAuthApi()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: InstitutionAdminShell(initialIndex: initialIndex),
        ),
      ),
    );
  }

  testWidgets('matches the institutional settings desktop reference', (
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
    expect(find.text('Coordenadores'), findsOneWidget);
    expect(find.text('Lucas Ferreira'), findsOneWidget);
    expect(find.text('Juliana Prado'), findsOneWidget);
    expect(find.text('Fernanda Alves'), findsOneWidget);
    expect(find.text('Permissões do coordenador'), findsOneWidget);
    expect(find.text('Marina Costa'), findsWidgets);
    expect(find.text('Salvar alterações'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches the mobile coordinator management reference', (
    tester,
  ) async {
    await pumpShell(tester, const Size(390, 844));

    expect(find.text('Coordenadores'), findsWidgets);
    expect(find.text('Administrador da instituição'), findsOneWidget);
    expect(find.text('Buscar coordenador'), findsOneWidget);
    expect(find.text('+ Convidar coordenador'), findsOneWidget);
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

  testWidgets('settings tabs expose integration state and save changes', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1440, 1024));

    await tester.tap(find.text('Integração de IA'));
    await tester.pumpAndSettle();
    expect(find.text('Reconhecimento facial'), findsOneWidget);
    expect(find.text('Conectada'), findsOneWidget);

    await tester.tap(find.text('Salvar alterações'));
    await tester.pump();
    expect(find.text('Alterações salvas.'), findsOneWidget);
  });

  testWidgets('overview notification button opens the notifications page', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1440, 1024), initialIndex: 0);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('3 notificações não lidas'), findsOneWidget);
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
