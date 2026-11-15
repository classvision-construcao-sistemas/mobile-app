import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.onStudents,
    this.onTeachers,
    this.onNotifications,
    this.onSignOut,
  });
  final VoidCallback? onStudents;
  final VoidCallback? onTeachers;
  final VoidCallback? onNotifications;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('more'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      const Text(
        'Mais',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 20),
      const AdminSurface(
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              child: Text('LF', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lucas Ferreira',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Coordenador · IF Goiano',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.navInactive),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'GESTÃO',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      AdminSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _MoreTile(
              icon: Icons.school_outlined,
              label: 'Alunos',
              onTap: onStudents,
            ),
            const Divider(height: 1),
            _MoreTile(
              icon: Icons.people_outline_rounded,
              label: 'Professores',
              onTap: onTeachers,
            ),
            const Divider(height: 1),
            _MoreTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notificações',
              badge: '3',
              onTap: onNotifications,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'PREFERÊNCIAS',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      AdminSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const _MoreTile(
              icon: Icons.help_outline_rounded,
              label: 'Ajuda e suporte',
            ),
            const Divider(height: 1),
            _MoreTile(
              icon: Icons.logout_rounded,
              label: 'Sair da conta',
              onTap: onSignOut,
              danger: true,
            ),
          ],
        ),
      ),
    ],
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    this.badge,
    this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? AppColors.error : AppColors.primary),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? AppColors.error : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: badge == null
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.navInactive,
            )
          : CircleAvatar(
              radius: 11,
              backgroundColor: AppColors.error,
              child: Text(
                badge!,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
    ),
  );
}
