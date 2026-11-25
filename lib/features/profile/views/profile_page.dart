import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/repositories/auth_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.onStudents,
    this.onTeachers,
    this.onNotifications,
    this.onSignOut,
    this.onReports,
    this.onUsers,
    this.onEditInstitution,
  });

  final VoidCallback? onStudents;
  final VoidCallback? onTeachers;
  final VoidCallback? onNotifications;
  final VoidCallback? onSignOut;

  /// Itens extras do administrador da instituição (ocultos quando nulos).
  final VoidCallback? onReports;
  final VoidCallback? onUsers;
  final VoidCallback? onEditInstitution;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final session = auth.session;
    final institution = auth.institution;
    final name = session?.name.isNotEmpty == true ? session!.name : 'Usuário';
    final initials = session?.initials.isNotEmpty == true
        ? session!.initials
        : '?';
    final role = session?.roleLabel ?? '';

    return ListView(
      key: const PageStorageKey('more'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Mais',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        AdminSurface(
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (role.isNotEmpty)
                      Text(
                        role,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    if (institution != null)
                      Text(
                        institution.name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'GESTÃO',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
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
              if (onReports != null) ...[
                const Divider(height: 1),
                _MoreTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Relatórios',
                  onTap: onReports,
                ),
              ],
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notificações',
                onTap: onNotifications,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'CONTA',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        AdminSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (onUsers != null) ...[
                _MoreTile(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Usuários e acessos',
                  onTap: onUsers,
                ),
                const Divider(height: 1),
              ],
              if (onEditInstitution != null) ...[
                _MoreTile(
                  icon: Icons.apartment_outlined,
                  label: 'Dados da instituição',
                  onTap: onEditInstitution,
                ),
                const Divider(height: 1),
              ],
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
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
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
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.navInactive,
      ),
    ),
  );
}
