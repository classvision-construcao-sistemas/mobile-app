import 'package:flutter/material.dart';

import '../auth/user_role.dart';
import '../theme/app_colors.dart';
import 'admin_page_scaffold.dart';
import 'classvision_logo.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.role,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final UserRole role;
  final List<AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final global = role == UserRole.systemAdmin;
    final foreground = global
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;
    final background = global ? AppColors.globalSidebar : Colors.white;

    return Container(
      key: const Key('admin-sidebar'),
      width: 252,
      color: background,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClassVisionLogo(onDark: global),
          ),
          const SizedBox(height: 27),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              global ? 'ADMINISTRAÇÃO GLOBAL' : 'PAINEL INSTITUCIONAL',
              style: TextStyle(
                color: global
                    ? const Color(0xFF94A3B8)
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < destinations.length; index++) ...[
            _SidebarItem(
              destination: destinations[index],
              selected: selectedIndex == index,
              global: global,
              foreground: foreground,
              onTap: () => onSelected(index),
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.global,
    required this.foreground,
    required this.onTap,
  });

  final AdminDestination destination;
  final bool selected;
  final bool global;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? (global ? const Color(0xFF28479D) : AppColors.primarySoft)
        : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            const SizedBox(width: 15),
            Icon(
              destination.icon,
              size: 19,
              color: selected
                  ? (global ? Colors.white : AppColors.primary)
                  : foreground,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                destination.label,
                style: TextStyle(
                  color: selected
                      ? (global ? Colors.white : AppColors.primary)
                      : foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
