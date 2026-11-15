import 'package:flutter/material.dart';

import '../auth/user_role.dart';
import '../layout/app_breakpoints.dart';
import 'admin_mobile_navigation.dart';
import 'admin_sidebar.dart';
import 'desktop_required_view.dart';

class AdminDestination {
  const AdminDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class AdminPageScaffold extends StatelessWidget {
  const AdminPageScaffold({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.body,
    this.onSignOut,
    this.profileName,
    this.profileRole,
  });

  final UserRole role;
  final int selectedIndex;
  final List<AdminDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final VoidCallback? onSignOut;
  final String? profileName;
  final String? profileRole;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = AppBreakpoints.isDesktop(constraints.maxWidth);
      if (!desktop && role == UserRole.systemAdmin) {
        return const DesktopRequiredView();
      }
      if (desktop) {
        return Scaffold(
          body: Row(
            children: [
              AdminSidebar(
                role: role,
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelected: onDestinationSelected,
                onSignOut: onSignOut,
                profileName: profileName,
                profileRole: profileRole,
              ),
              Expanded(child: SafeArea(child: body)),
            ],
          ),
        );
      }
      return Scaffold(
        body: SafeArea(bottom: false, child: body),
        bottomNavigationBar: AdminMobileNavigation(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onSelected: onDestinationSelected,
        ),
      );
    },
  );
}
