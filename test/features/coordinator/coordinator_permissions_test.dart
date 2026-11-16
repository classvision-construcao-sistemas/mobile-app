import 'package:class_vision/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_server.dart';

void main() {
  Future<void> login(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Acessar plataforma'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'coordinator has operational destinations but no admin settings',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ClassVisionApp(authApi: roleAwareFakeAuthApi()));
      await login(tester, 'lucas.ferreira@ifgoiano.edu.br');

      expect(find.text('Visão geral'), findsOneWidget);
      expect(find.text('Alunos'), findsOneWidget);
      expect(find.text('Professores'), findsOneWidget);
      expect(find.text('Configurações'), findsNothing);
      expect(find.text('Coordenadores'), findsNothing);
    },
  );

  testWidgets(
    'institution administrator can return from operations to settings',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ClassVisionApp(authApi: roleAwareFakeAuthApi()));
      await login(tester, 'marina.costa@ifgoiano.edu.br');

      await tester.tap(find.text('Visão geral'));
      await tester.pumpAndSettle();
      expect(find.text('Resumo de hoje'), findsOneWidget);
      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();
      expect(find.text('Equipe de coordenação'), findsOneWidget);
    },
  );
}
