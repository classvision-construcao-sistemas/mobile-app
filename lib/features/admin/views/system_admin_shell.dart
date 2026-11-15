import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/admin_page_scaffold.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'create_institution_page.dart';
import 'institution_admins_page.dart';
import 'institution_created_page.dart';
import 'institution_detail_page.dart';
import 'institutions_page.dart';
import 'platform_activity_page.dart';
import 'platform_settings_page.dart';
import 'system_dashboard_page.dart';

enum _SystemAdminMode { section, createInstitution, institutionDetail, created }

class SystemAdminShell extends StatefulWidget {
  const SystemAdminShell({super.key});

  @override
  State<SystemAdminShell> createState() => _SystemAdminShellState();
}

class _SystemAdminShellState extends State<SystemAdminShell> {
  static const _destinations = [
    AdminDestination(label: 'Visão geral', icon: Icons.dashboard_outlined),
    AdminDestination(label: 'Instituições', icon: Icons.apartment_outlined),
    AdminDestination(label: 'Administradores', icon: Icons.badge_outlined),
    AdminDestination(label: 'Atividade', icon: Icons.timeline_outlined),
    AdminDestination(label: 'Configurações', icon: Icons.settings_outlined),
  ];

  int _selectedIndex = 0;
  _SystemAdminMode _mode = _SystemAdminMode.section;
  String? _institutionId;
  Institution? _createdInstitution;
  String? _createdAdminName;
  String? _createdAdminEmail;

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
      _mode = _SystemAdminMode.section;
    });
  }

  void _openCreate() =>
      setState(() => _mode = _SystemAdminMode.createInstitution);

  void _openInstitution(String id) => setState(() {
    _institutionId = id;
    _mode = _SystemAdminMode.institutionDetail;
  });

  void _showCreated(
    Institution institution,
    String adminName,
    String adminEmail,
  ) => setState(() {
    _createdInstitution = institution;
    _createdAdminName = adminName;
    _createdAdminEmail = adminEmail;
    _mode = _SystemAdminMode.created;
  });

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final body = switch (_mode) {
      _SystemAdminMode.createInstitution => CreateInstitutionPage(
        onCancel: () => setState(() {
          _selectedIndex = 1;
          _mode = _SystemAdminMode.section;
        }),
        onCreated: _showCreated,
      ),
      _SystemAdminMode.institutionDetail => InstitutionDetailPage(
        institutionId: _institutionId ?? 'if-goiano',
        onBack: () => setState(() {
          _selectedIndex = 1;
          _mode = _SystemAdminMode.section;
        }),
      ),
      _SystemAdminMode.created => InstitutionCreatedPage(
        institution: _createdInstitution!,
        adminName: _createdAdminName!,
        adminEmail: _createdAdminEmail!,
        onViewInstitution: () => _openInstitution(_createdInstitution!.id),
        onBackToList: () => setState(() {
          _selectedIndex = 1;
          _mode = _SystemAdminMode.section;
        }),
      ),
      _SystemAdminMode.section => switch (_selectedIndex) {
        0 => SystemDashboardPage(onCreateInstitution: _openCreate),
        1 => InstitutionsPage(
          onCreateInstitution: _openCreate,
          onOpenInstitution: _openInstitution,
        ),
        2 => const InstitutionAdminsPage(),
        3 => const PlatformActivityPage(),
        4 => const PlatformSettingsPage(),
        _ => SystemDashboardPage(onCreateInstitution: _openCreate),
      },
    };

    return AdminPageScaffold(
      key: const Key('system-admin-shell'),
      role: UserRole.systemAdmin,
      selectedIndex: _selectedIndex,
      destinations: _destinations,
      onDestinationSelected: _selectDestination,
      onSignOut: () {
        context.read<AppSession>().signOut();
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      },
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey(
            '$_selectedIndex-$_mode-${repository.institutions.length}',
          ),
          child: body,
        ),
      ),
    );
  }
}
