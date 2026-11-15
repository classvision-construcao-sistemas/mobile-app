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

  testWidgets('validates and completes institution onboarding', (tester) async {
    await pumpSystemAdmin(tester);
    await tester.tap(find.text('+ Nova instituição'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar instituição'), findsOneWidget);
    expect(find.text('Dados da instituição'), findsWidgets);
    expect(find.text('Primeiro administrador'), findsWidgets);
    expect(find.text('Nome do administrador'), findsOneWidget);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(8));
    await tester.enterText(fields.at(0), '');
    await tester.tap(find.text('Criar instituição e enviar convite'));
    await tester.pumpAndSettle();
    expect(find.text('Preencha todos os campos obrigatórios.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Colégio Horizonte');
    await tester.tap(find.text('Criar instituição e enviar convite'));
    await tester.pumpAndSettle();

    expect(find.text('Instituição cadastrada!'), findsOneWidget);
    expect(find.text('Paulo Nunes'), findsOneWidget);
    expect(find.textContaining('paulo@horizonte.edu.br'), findsOneWidget);

    await tester.tap(find.text('Ver instituição'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes da instituição'), findsOneWidget);
    expect(find.text('Colégio Horizonte'), findsWidgets);
  });

  testWidgets('cancels onboarding back to the institution list', (tester) async {
    await pumpSystemAdmin(tester);
    await tester.tap(find.text('+ Nova instituição'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Gestão de instituições'), findsOneWidget);
    expect(find.text('Cadastrar instituição'), findsNothing);
  });
}
