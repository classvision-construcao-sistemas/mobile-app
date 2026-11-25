import 'dart:convert';

import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/admin/views/system_admin_shell.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../helpers/fake_admin_backend.dart';

void main() {
  Future<void> pumpSystemAdmin(
    WidgetTester tester, {
    List<http.Request>? requests,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (auth, admin) = (await tester.runAsync(
      () => loadedAdmin(requests: requests),
    ))!;
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

  testWidgets('validates, masks and creates an institution', (tester) async {
    final requests = <http.Request>[];
    await pumpSystemAdmin(tester, requests: requests);
    await tester.tap(find.text('Nova instituição'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar instituição'), findsOneWidget);
    expect(find.text('Dados da instituição'), findsOneWidget);
    expect(find.text('Administrador da instituição'), findsOneWidget);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.tap(find.text('Criar instituição'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome'), findsOneWidget);
    expect(find.text('Informe um CNPJ com 14 caracteres'), findsOneWidget);
    expect(find.text('Informe DDD + número'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Colégio Horizonte');
    await tester.enterText(fields.at(1), '12345678000190');
    await tester.enterText(fields.at(2), '62988887777');
    await tester.pump();
    expect(find.text('12.345.678/0001-90'), findsOneWidget);
    expect(find.text('(62) 98888-7777'), findsOneWidget);

    await tester.tap(find.text('Criar instituição'));
    await tester.pumpAndSettle();

    expect(find.text('Instituição cadastrada!'), findsOneWidget);
    expect(find.text('Cadastrar administrador'), findsOneWidget);
    final post = requests.lastWhere((it) => it.method == 'POST');
    expect(jsonDecode(post.body), {
      'nome': 'Colégio Horizonte',
      'cnpj': '12345678000190',
      'telefone': '62988887777',
    });

    await tester.tap(find.text('Ver instituição'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes da instituição'), findsOneWidget);
    expect(find.text('Colégio Horizonte'), findsWidgets);
  });

  testWidgets('cancels onboarding back to the institution list', (
    tester,
  ) async {
    await pumpSystemAdmin(tester);
    await tester.tap(find.text('Nova instituição'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Gestão de instituições'), findsOneWidget);
    expect(find.text('Cadastrar instituição'), findsNothing);
  });
}
