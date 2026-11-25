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
    this.onSignOut,
    this.profileName,
    this.profileRole,
  });

  final UserRole role;
  final List<AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onSignOut;
  final String? profileName;
  final String? profileRole;

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
                fontSize: 12,
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
          if (profileName != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: global
                        ? const Color(0xFF28479D)
                        : AppColors.primarySoft,
                    foregroundColor: global ? Colors.white : AppColors.primary,
                    child: Text(
                      profileName!
                          .split(' ')
                          .map((part) => part[0])
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileName!,
                          style: TextStyle(
                            color: global
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (profileRole != null)
                          Text(
                            profileRole!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: foreground, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (onSignOut != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onSignOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 19, color: foreground),
                      const SizedBox(width: 13),
                      Text(
                        'Sair',
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
