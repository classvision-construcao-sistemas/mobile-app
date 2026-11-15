import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/institution_admin/views/institution_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AdminRepository(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const InstitutionAdminShell(),
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
    expect(
      find.text('Somente administradores da instituição podem'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('coordinator login never exposes institution administration', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ClassVisionApp());
    await tester.enterText(
      find.byType(TextFormField).first,
      'coordenacao@escola.edu.br',
    );
    await tester.tap(find.text('Acessar plataforma'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coordinator-shell')), findsOneWidget);
    expect(find.text('Coordenadores'), findsNothing);
    expect(find.text('Configurações'), findsNothing);
  });
}
