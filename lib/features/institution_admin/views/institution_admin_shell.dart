import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/navigation/shell_url.dart';
import '../../../core/widgets/admin_page_scaffold.dart';
import '../../../data/repositories/school_repository.dart';
import '../../classes/views/classes_page.dart';
import '../../history/views/history_page.dart';
import '../../home/view/home_page.dart';
import '../../notifications/views/notifications_page.dart';
import '../../profile/views/profile_page.dart';
import '../../reports/views/reports_page.dart';
import '../../students/views/students_page.dart';
import '../../teachers/views/teachers_page.dart';
import 'coordinators_page.dart';
import 'institution_settings_page.dart';

class InstitutionAdminShell extends StatefulWidget {
  const InstitutionAdminShell({
    super.key,
    this.initialIndex = 6,
    this.initialTab,
  });

  final int initialIndex;

  /// Aba vinda do endereço (`/home?aba=turmas`); tem prioridade.
  final String? initialTab;

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

  static const _mobileDestinations = [
    AdminDestination(label: 'Início', icon: Icons.home_outlined),
    AdminDestination(label: 'Turmas', icon: Icons.grid_view_outlined),
    AdminDestination(label: 'Chamadas', icon: Icons.fact_check_outlined),
    AdminDestination(label: 'Equipe', icon: Icons.groups_outlined),
    AdminDestination(label: 'Mais', icon: Icons.more_horiz_rounded),
  ];

  late int _selectedIndex;

  /// Aba do celular (Início, Turmas, Chamadas, Equipe, Mais).
  late int _mobileIndex;
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ShellUrl.indexOf(
      ShellUrl.institutionAdmin,
      widget.initialTab,
      widget.initialIndex,
    );
    final mobileTab = ShellUrl.institutionAdminMobile.indexOf(
      widget.initialTab ?? '',
    );
    _mobileIndex = mobileTab >= 0
        ? mobileTab
        : switch (_selectedIndex) {
            1 => 1,
            4 => 2,
            6 => 3,
            2 || 3 || 5 => 4,
            _ => 0,
          };
  }

  void _selectMobile(int index) {
    if (index == _mobileIndex && !_showNotifications) return;
    super.setState(() {
      _mobileIndex = index;
      _showNotifications = false;
    });
    ShellUrl.show(ShellUrl.institutionAdminMobile, index);
  }

  /// Abre uma seção do "Mais" em tela cheia, com voltar.
  void _openSection(String title, Widget page) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: page,
      ),
    ),
  );

  @override
  void setState(VoidCallback fn) {
    final before = _selectedIndex;
    super.setState(fn);
    if (_selectedIndex != before) {
      ShellUrl.show(ShellUrl.institutionAdmin, _selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final repository = context.watch<SchoolRepository>();
      final session = context.watch<AuthRepository>().session;
      final institutionId = session?.institutionId;
      final firstName = session?.firstName ?? '';
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
          onOpenCameraFor: openCamera,
          userName: firstName,
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
        _ => InstitutionSettingsPage(
          onManageUsers: () => Navigator.pushNamed(context, AppRoutes.users),
          onEditInstitution: institutionId == null
              ? null
              : () => Navigator.pushNamed(
                  context,
                  AppRoutes.institutionRegistration,
                  arguments: institutionId,
                ),
        ),
      };
      final body = _showNotifications
          ? NotificationsPage(
              onBack: () => setState(() => _showNotifications = false),
            )
          : sectionBody;
      void signOut() => context.read<AuthRepository>().logout();

      if (!AppBreakpoints.isDesktop(constraints.maxWidth)) {
        // Celular: as mesmas funções do computador, em 5 abas; o que não cabe
        // fica em "Mais".
        final mobileBody = _showNotifications
            ? body
            : switch (_mobileIndex) {
                0 => HomePage(
                  onOpenCamera: openCamera,
                  onOpenReview: firstClassId == null
                      ? null
                      : () => openReview(firstClassId),
                  onViewAllPending: () => _selectMobile(2),
                  onOpenNotifications: () =>
                      setState(() => _showNotifications = true),
                  onOpenCameraFor: openCamera,
                  userName: firstName,
                ),
                1 => ClassesPage(
                  onOpenClass: (id) => Navigator.pushNamed(
                    context,
                    AppRoutes.classDetails,
                    arguments: id,
                  ),
                ),
                2 => HistoryPage(onOpenReview: openReview),
                3 => const CoordinatorsPage(mobile: true),
                _ => ProfilePage(
                  onStudents: () =>
                      _openSection('Alunos', const StudentsPage()),
                  onTeachers: () =>
                      _openSection('Professores', const TeachersPage()),
                  onReports: () =>
                      _openSection('Relatórios', const ReportsPage()),
                  onNotifications: () =>
                      setState(() => _showNotifications = true),
                  onUsers: () => Navigator.pushNamed(context, AppRoutes.users),
                  onEditInstitution: institutionId == null
                      ? null
                      : () => Navigator.pushNamed(
                          context,
                          AppRoutes.institutionRegistration,
                          arguments: institutionId,
                        ),
                  onSignOut: signOut,
                ),
              };
        return AdminPageScaffold(
          key: const Key('institution-admin-shell'),
          role: UserRole.institutionAdmin,
          selectedIndex: _mobileIndex,
          destinations: _mobileDestinations,
          onDestinationSelected: _selectMobile,
          onSignOut: signOut,
          body: mobileBody,
        );
      }
      return AdminPageScaffold(
        key: const Key('institution-admin-shell'),
        role: UserRole.institutionAdmin,
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: (index) => setState(() {
          _showNotifications = false;
          _selectedIndex = index;
        }),
        profileName: session?.name,
        profileRole: session?.roleLabel,
        onSignOut: () {
          context.read<AuthRepository>().logout();
        },
        body: body,
      );
    },
  );
}
