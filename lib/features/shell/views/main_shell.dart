import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/viewmodels/main_shell_view_model.dart';
import '../../../core/widgets/admin_page_scaffold.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/repositories/school_repository.dart';
import '../../classes/views/classes_page.dart';
import '../../history/views/history_page.dart';
import '../../home/view/home_page.dart';
import '../../notifications/views/notifications_page.dart';
import '../../profile/views/profile_page.dart';
import '../../reports/views/reports_page.dart';
import '../../students/views/students_page.dart';
import '../../teachers/views/teachers_page.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => MainShellViewModel(),
    child: const _MainShellContent(),
  );
}

class _MainShellContent extends StatelessWidget {
  const _MainShellContent();

  static const _desktopDestinations = [
    AdminDestination(label: 'Visão geral', icon: Icons.dashboard_outlined),
    AdminDestination(label: 'Turmas', icon: Icons.meeting_room_outlined),
    AdminDestination(label: 'Alunos', icon: Icons.school_outlined),
    AdminDestination(label: 'Professores', icon: Icons.people_outline_rounded),
    AdminDestination(label: 'Chamadas', icon: Icons.fact_check_outlined),
    AdminDestination(label: 'Relatórios', icon: Icons.bar_chart_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MainShellViewModel>();
    final repository = context.watch<SchoolRepository>();
    final firstClassId = repository.classes.firstOrNull?.id;
    void openCamera([String? id]) => Navigator.pushNamed(
      context,
      AppRoutes.camera,
      arguments: id ?? firstClassId,
    );
    void openReview(String id) =>
        Navigator.pushNamed(context, AppRoutes.review, arguments: id);
    void openClass(String id) =>
        Navigator.pushNamed(context, AppRoutes.classDetails, arguments: id);
    void signOut() {
      context.read<AppSession>().signOut();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }

    final pages = <Widget>[
      HomePage(
        onOpenCamera: openCamera,
        onOpenReview: firstClassId == null
            ? null
            : () => openReview(firstClassId),
        onOpenNotifications: () => viewModel.select(7),
        onViewAllPending: () => viewModel.select(4),
      ),
      ClassesPage(onOpenClass: openClass),
      const StudentsPage(),
      const TeachersPage(),
      HistoryPage(onOpenReview: openReview),
      const ReportsPage(),
      ProfilePage(
        onStudents: () => viewModel.select(2),
        onTeachers: () => viewModel.select(3),
        onNotifications: () => viewModel.select(7),
        onSignOut: signOut,
      ),
      NotificationsPage(onBack: () => viewModel.select(6)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (desktop) {
          final desktopIndex = viewModel.index.clamp(0, 5);
          return AdminPageScaffold(
            key: const Key('coordinator-shell'),
            role: UserRole.coordinator,
            selectedIndex: desktopIndex,
            destinations: _desktopDestinations,
            onDestinationSelected: viewModel.select,
            profileName: 'Lucas Ferreira',
            profileRole: 'Coordenador',
            onSignOut: signOut,
            body: viewModel.index == 7 ? pages[7] : pages[desktopIndex],
          );
        }
        return Scaffold(
          key: const Key('coordinator-shell'),
          body: SafeArea(bottom: false, child: pages[viewModel.index]),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: viewModel.mobileIndex,
            onSelected: viewModel.selectMobile,
          ),
        );
      },
    );
  }
}
