import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/repositories/school_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SchoolRepository>().profile;
    final hasProfile = profile.name.trim().isNotEmpty;
    return ListView(
      key: const PageStorageKey('profile'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      children: [
        const AppPageTitle('Perfil', subtitle: 'Sua conta de coordenação.'),
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primarySoft,
            child: hasProfile
                ? Text(
                    profile.name
                        .split(RegExp(r'\s+'))
                        .take(2)
                        .map((part) => part[0])
                        .join(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 38,
                  ),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          hasProfile ? profile.name : 'Perfil não cadastrado',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(
          hasProfile ? profile.email : 'Complete seus dados de coordenação',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileTile(
                icon: Icons.school_outlined,
                title: profile.school.isEmpty
                    ? 'Instituição não informada'
                    : profile.school,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.phone_outlined,
                title: profile.phone.isEmpty
                    ? 'Telefone não informado'
                    : profile.phone,
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
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
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Editar perfil',
          icon: Icons.edit_outlined,
          outlined: true,
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.userRegistration,
            arguments: true,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (_) => false,
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sair da conta'),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
