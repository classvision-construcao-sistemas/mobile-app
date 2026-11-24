import 'package:class_vision/core/navigation/app_routes.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/auth_models.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/institution_admin/views/institution_admin_shell.dart';
import 'package:class_vision/features/users/views/user_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../helpers/fake_admin_backend.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<List<RouteSettings>> pumpMobile(
    WidgetTester tester, {
    List<http.Request>? requests,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (auth, admin) = (await tester.runAsync(
      () => loadedAdmin(
        role: 'ADMIN_INSTITUICAO',
        name: 'Marina Costa',
        requests: requests,
      ),
    ))!;
    final routes = <RouteSettings>[];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthRepository>.value(value: auth),
          ChangeNotifierProvider<AdminRepository>.value(value: admin),
          ChangeNotifierProvider(
            create: (_) => SchoolRepository()..seedClasses([courseClass()]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const InstitutionAdminShell(),
          onGenerateRoute: (settings) {
            routes.add(settings);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Formulário aberto')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return routes;
  }

  testWidgets('lists the real coordinators of the institution', (tester) async {
    await pumpMobile(tester);

    expect(find.text('Coordenadores'), findsWidgets);
    expect(find.text('Lucas Ferreira'), findsOneWidget);
    expect(find.text('lucas@ifgoiano.edu.br'), findsOneWidget);
    expect(find.text('Ativo'), findsOneWidget);
    expect(find.text('MC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the user form preset as coordinator', (tester) async {
    final routes = await pumpMobile(tester);

    await tester.tap(find.text('Cadastrar coordenador').first);
    await tester.pumpAndSettle();

    expect(find.text('Formulário aberto'), findsOneWidget);
    expect(routes.single.name, AppRoutes.userRegistration);
    final preset = routes.single.arguments! as UserFormPreset;
    expect(preset.role, UserRole.coordenador);
    expect(preset.institutionId, 1);
  });

  testWidgets('deactivates and reactivates a coordinator through the API', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await pumpMobile(tester, requests: requests);

    await tester.tap(find.text('Desativar'));
    await tester.pumpAndSettle();
    expect(find.text('Desativar coordenador?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Inativo'), findsOneWidget);
    expect(requests.last.url.path, '/api/usuarios/desativar-usuario/11');

    await tester.tap(find.text('Ativar'));
    await tester.pumpAndSettle();
    expect(find.text('Ativo'), findsOneWidget);
    expect(requests.last.url.path, '/api/usuarios/ativar-usuario/11');
  });
}
