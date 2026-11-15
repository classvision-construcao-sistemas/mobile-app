import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/admin_page_scaffold.dart';
import '../../../data/repositories/school_repository.dart';
import '../../classes/views/classes_page.dart';
import '../../history/views/history_page.dart';
import '../../home/view/home_page.dart';
import '../../notifications/views/notifications_page.dart';
import '../../reports/views/reports_page.dart';
import '../../students/views/students_page.dart';
import '../../teachers/views/teachers_page.dart';
import 'coordinators_page.dart';
import 'institution_settings_page.dart';

class InstitutionAdminShell extends StatefulWidget {
  const InstitutionAdminShell({super.key, this.initialIndex = 6});

  final int initialIndex;

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

  late int _selectedIndex;
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!AppBreakpoints.isDesktop(constraints.maxWidth)) {
        return KeyedSubtree(
          key: Key('institution-admin-shell'),
          child: CoordinatorsPage(
            mobile: true,
            onBack: () {
              context.read<AppSession>().signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
          ),
        );
      }
      final repository = context.watch<SchoolRepository>();
      final firstClassId = repository.classes.firstOrNull?.id;
      void openCamera([String? id]) => Navigator.pushNamed(
        context,
        AppRoutes.camera,
        arguments: id ?? firstClassId,
      );
      void openReview(String id) =>
          Navigator.pushNamed(context, AppRoutes.review, arguments: id);
      final sectionBody = switch (_selectedIndex) {
        0 => HomePage(
          onOpenCamera: openCamera,
          onOpenReview: firstClassId == null
              ? null
              : () => openReview(firstClassId),
          onViewAllPending: () => setState(() => _selectedIndex = 4),
          onOpenNotifications: () => setState(() => _showNotifications = true),
          userName: 'Marina',
        ),
        1 => ClassesPage(
          onOpenClass: (id) => Navigator.pushNamed(
            context,
            AppRoutes.classDetails,
            arguments: id,
          ),
        ),
        2 => const StudentsPage(),
        3 => const TeachersPage(),
        4 => HistoryPage(onOpenReview: openReview),
        5 => const ReportsPage(),
        _ => const InstitutionSettingsPage(),
      };
      final body = _showNotifications
          ? NotificationsPage(
              onBack: () => setState(() => _showNotifications = false),
            )
          : sectionBody;
      return AdminPageScaffold(
        key: const Key('institution-admin-shell'),
        role: UserRole.institutionAdmin,
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: (index) => setState(() {
          _showNotifications = false;
          _selectedIndex = index;
        }),
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
