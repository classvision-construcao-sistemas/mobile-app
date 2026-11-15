import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/institution_admin/views/institution_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpMobile(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
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

  Future<void> openInvite(WidgetTester tester) async {
    await tester.tap(find.text('+ Convidar coordenador'));
    await tester.pumpAndSettle();
  }

  testWidgets('rejects invalid email and invites a valid coordinator', (
    tester,
  ) async {
    await pumpMobile(tester);
    await openInvite(tester);

    await tester.enterText(find.byType(TextField).last, 'email-invalido');
    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'ana.souza@ifgoiano.edu.br',
    );
    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Pendente'), findsWidgets);
  });

  testWidgets('activates and deactivates coordinators with confirmation', (
    tester,
  ) async {
    await pumpMobile(tester);

    await tester.tap(find.text('Ativar'));
    await tester.pumpAndSettle();
    expect(find.text('Juliana Prado'), findsOneWidget);
    expect(find.text('Ativo'), findsNWidgets(2));

    await tester.tap(find.text('Desativar').first);
    await tester.pumpAndSettle();
    expect(find.text('Desativar coordenador?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Inativo'), findsWidgets);
  });

  testWidgets('resends and cancels a pending invitation', (tester) async {
    await pumpMobile(tester);

    await tester.tap(find.text('Reenviar'));
    await tester.pumpAndSettle();
    expect(find.text('Convite reenviado.'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar convite?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Fernanda Alves'), findsNothing);
  });
}
