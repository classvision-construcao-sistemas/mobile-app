import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/navigation/app_routes.dart';

class RoleLandingPage extends StatelessWidget {
  const RoleLandingPage({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final title = switch (role) {
      UserRole.systemAdmin => 'Visão geral da plataforma',
      UserRole.institutionAdmin => 'Administração da instituição',
      UserRole.coordinator => 'Painel do coordenador',
    };
    final shellKey = switch (role) {
      UserRole.systemAdmin => const Key('system-admin-shell'),
      UserRole.institutionAdmin => const Key('institution-admin-shell'),
      UserRole.coordinator => const Key('coordinator-shell'),
    };

    return Scaffold(
      key: shellKey,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                context.read<AppSession>().signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}
