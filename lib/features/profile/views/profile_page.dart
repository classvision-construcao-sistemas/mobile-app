import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/repositories/auth_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final session = auth.session;
    if (session == null) return const SizedBox.shrink();

    final role = session.role;
    final institution = auth.institution;
    final institutionId = session.institutionId;

    return ListView(
      key: const PageStorageKey('profile'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      children: [
        const AppPageTitle('Perfil', subtitle: 'Sua conta no ClassVision.'),
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primarySoft,
            child: session.initials.isEmpty
                ? const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 38,
                  )
                : Text(
                    session.initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          session.name.isEmpty ? session.email : session.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(
          session.roleLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 24),
        AppInfoTile(
          icon: Icons.school_outlined,
          label: 'Instituição',
          value:
              institution?.name ??
              (institutionId == null
                  ? 'Instituição não informada'
                  : 'Instituição #$institutionId'),
        ),
        if (institution != null && institution.phone.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppInfoTile(
            icon: Icons.phone_outlined,
            label: 'Telefone da instituição',
            value: institution.formattedPhone,
          ),
        ],
        const SizedBox(height: 12),
        AppInfoTile(
          icon: Icons.mail_outline_rounded,
          label: 'E-mail',
          value: session.email,
        ),
        const SizedBox(height: 12),
        AppInfoTile(
          icon: Icons.verified_user_outlined,
          label: 'Permissões',
          value: role?.permissionsSummary ?? 'Turmas, chamadas e histórico',
        ),
        if (role != null && (role.canViewUsers || role.canEditInstitution)) ...[
          const SizedBox(height: 24),
          const Text(
            'Administração',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (role.canViewUsers) ...[
            AppInfoTile(
              icon: Icons.manage_accounts_outlined,
              label: role.canManageUsers
                  ? 'Cadastrar e gerenciar'
                  : 'Consultar',
              value: 'Usuários',
              onTap: () => Navigator.pushNamed(context, AppRoutes.users),
            ),
            const SizedBox(height: 12),
          ],
          if (role.canManageInstitutions)
            AppInfoTile(
              icon: Icons.apartment_rounded,
              label: 'Cadastrar, editar, ativar e desativar',
              value: 'Instituições',
              onTap: () => Navigator.pushNamed(context, AppRoutes.institutions),
            )
          else if (role.canEditInstitution && institutionId != null)
            AppInfoTile(
              icon: Icons.apartment_rounded,
              label: 'Nome e telefone',
              value: 'Dados da instituição',
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.institutionRegistration,
                arguments: institution ?? institutionId,
              ),
            ),
        ],
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile.adaptive(
            secondary: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
            ),
            title: const Text(
              'Notificações',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
          ),
        ),
        const SizedBox(height: 18),
        if (role != null && role.canManageUsers && session.userId != null) ...[
          PrimaryButton(
            label: 'Editar perfil',
            icon: Icons.edit_outlined,
            outlined: true,
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.userRegistration,
              arguments: session.userId,
            ),
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          label: 'Sair da conta',
          icon: Icons.logout_rounded,
          outlined: true,
          onPressed: auth.logout,
        ),
        const SizedBox(height: 10),
        Text(
          'Sessão válida até ${formatBrDateTime(session.expiresAt)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
