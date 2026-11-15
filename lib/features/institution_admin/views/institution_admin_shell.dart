import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/admin_page_scaffold.dart';
import '../../classes/views/classes_page.dart';
import '../../history/views/history_page.dart';
import '../../home/view/home_page.dart';
import '../../reports/views/reports_page.dart';
import '../../students/views/students_page.dart';
import '../../teachers/views/teachers_page.dart';
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
      void openCamera() => Navigator.pushNamed(context, AppRoutes.camera);
      final body = switch (_selectedIndex) {
        0 => HomePage(onOpenCamera: openCamera, userName: 'Marina'),
        1 => const ClassesPage(),
        2 => const StudentsPage(),
        3 => const TeachersPage(),
        4 => HistoryPage(onOpenReview: openCamera),
        5 => const ReportsPage(),
        _ => const InstitutionSettingsPage(),
      };
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
        body: body,
      );
    },
  );
}
