import 'package:class_vision/core/auth/user_role.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/core/widgets/admin_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const destinations = [
    AdminDestination(label: 'Visão geral', icon: Icons.dashboard_outlined),
    AdminDestination(label: 'Instituições', icon: Icons.apartment_outlined),
  ];

  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    required UserRole role,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AdminPageScaffold(
          role: role,
          selectedIndex: 0,
          destinations: destinations,
          onDestinationSelected: (_) {},
          body: const Text('Conteúdo'),
        ),
      ),
    );
  }

  testWidgets('uses the fixed sidebar at the desktop reference size', (
    tester,
  ) async {
    await pumpShell(
      tester,
      size: const Size(1440, 1024),
      role: UserRole.systemAdmin,
    );

    expect(find.byKey(const Key('admin-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('admin-mobile-navigation')), findsNothing);
    expect(find.text('Conteúdo'), findsOneWidget);
  });

  testWidgets('uses bottom navigation for institutional mobile roles', (
    tester,
  ) async {
    await pumpShell(
      tester,
      size: const Size(390, 844),
      role: UserRole.coordinator,
    );

    expect(find.byKey(const Key('admin-sidebar')), findsNothing);
    expect(find.byKey(const Key('admin-mobile-navigation')), findsOneWidget);
    expect(find.text('Conteúdo'), findsOneWidget);
  });

  testWidgets('blocks system administrators on mobile widths', (tester) async {
    await pumpShell(
      tester,
      size: const Size(390, 844),
      role: UserRole.systemAdmin,
    );

    expect(find.text('Acesse pelo computador'), findsOneWidget);
    expect(find.byKey(const Key('admin-sidebar')), findsNothing);
    expect(find.byKey(const Key('admin-mobile-navigation')), findsNothing);
    expect(find.text('Conteúdo'), findsNothing);
  });
}
