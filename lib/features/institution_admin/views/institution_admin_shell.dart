import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_page_scaffold.dart';
import 'coordinators_page.dart';
import 'institution_settings_page.dart';

class InstitutionAdminShell extends StatefulWidget {
  const InstitutionAdminShell({super.key});

  @override
  State<InstitutionAdminShell> createState() => _InstitutionAdminShellState();
}

class _InstitutionAdminShellState extends State<InstitutionAdminShell> {
  static const _destinations = [
    AdminDestination(label: 'Visão geral', icon: Icons.dashboard_outlined),
    AdminDestination(label: 'Turmas', icon: Icons.meeting_room_outlined),
    AdminDestination(label: 'Alunos', icon: Icons.school_outlined),
    AdminDestination(label: 'Professores', icon: Icons.people_outline_rounded),
    AdminDestination(label: 'Chamadas', icon: Icons.fact_check_outlined),
    AdminDestination(label: 'Relatórios', icon: Icons.bar_chart_rounded),
    AdminDestination(label: 'Configurações', icon: Icons.settings_outlined),
  ];

  int _selectedIndex = 6;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!AppBreakpoints.isDesktop(constraints.maxWidth)) {
        return const KeyedSubtree(
          key: Key('institution-admin-shell'),
          child: CoordinatorsPage(mobile: true),
        );
      }
      return AdminPageScaffold(
        key: const Key('institution-admin-shell'),
        role: UserRole.institutionAdmin,
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        profileName: 'Marina Costa',
        profileRole: 'Administrador da instituição',
        onSignOut: () {
          context.read<AppSession>().signOut();
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        },
        body: _selectedIndex == 6
            ? const InstitutionSettingsPage()
            : _OperationalPlaceholder(
                destination: _destinations[_selectedIndex],
              ),
      );
    },
  );
}

class _OperationalPlaceholder extends StatelessWidget {
  const _OperationalPlaceholder({required this.destination});
  final AdminDestination destination;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.background,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(destination.icon, color: AppColors.primary, size: 34),
          const SizedBox(height: 12),
          Text(
            destination.label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'A operação acadêmica responsiva será exibida aqui.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
