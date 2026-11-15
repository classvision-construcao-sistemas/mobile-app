import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_page_header.dart';

class PlatformSettingsPage extends StatelessWidget {
  const PlatformSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final settings = repository.settings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      children: [
        const AdminPageHeader(
          title: 'Configurações da plataforma',
          subtitle:
              'Defina políticas globais e acompanhe a operação dos serviços.',
        ),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  AdminSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.mark_email_read_outlined,
                          title: 'Política de convites',
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Validade do convite',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${settings.inviteValidityDays} dias'),
                        ),
                        const SizedBox(height: 12),
                        _SettingSwitch(
                          title: 'Lembrete automático',
                          subtitle:
                              'Reenviar lembrete antes do convite expirar.',
                          value: settings.automaticInviteReminder,
                          onChanged: repository.setAutomaticInviteReminder,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  AdminSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notificações administrativas',
                        ),
                        const SizedBox(height: 12),
                        _SettingSwitch(
                          title: 'Alertas de indisponibilidade',
                          subtitle: 'Receber aviso quando algum serviço apresentar instabilidade.',
                          value: settings.outageAlerts,
                          onChanged: repository.setOutageAlerts,
                        ),
                        const Divider(height: 26),
                        _SettingSwitch(
                          title: 'Resumo semanal',
                          subtitle: 'Receber indicadores consolidados toda segunda-feira.',
                          value: settings.weeklySummary,
                          onChanged: repository.setWeeklySummary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: _ServicesCard(services: repository.services)),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

class _ServicesCard extends StatelessWidget {
  const _ServicesCard({required this.services});
  final List<PlatformService> services;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.monitor_heart_outlined,
          title: 'Status dos serviços',
        ),
        const SizedBox(height: 18),
        for (final service in services)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: service.health == ServiceHealth.operational
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  service.health == ServiceHealth.operational
                      ? 'Operacional'
                      : 'Instável',
                  style: TextStyle(
                    fontSize: 12,
                    color: service.health == ServiceHealth.operational
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
