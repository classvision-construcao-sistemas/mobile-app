import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_data_status.dart';
import 'widgets/admin_page_header.dart';

class SystemDashboardPage extends StatelessWidget {
  const SystemDashboardPage({
    super.key,
    required this.onCreateInstitution,
    required this.onManageInstitutions,
  });

  final VoidCallback onCreateInstitution;
  final VoidCallback onManageInstitutions;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final metrics = repository.metrics;
    final institutions = repository.institutions;
    final now = DateTime.now();
    final newThisMonth = institutions
        .where(
          (it) =>
              it.createdAt.year == now.year && it.createdAt.month == now.month,
        )
        .length;
    final activeShare = metrics.totalInstitutions == 0
        ? '—'
        : '${(metrics.activeInstitutions * 100 / metrics.totalInstitutions).toStringAsFixed(1).replaceAll('.', ',')}% da base';

    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      children: [
        AdminPageHeader(
          title: 'Visão geral da plataforma',
          subtitle: 'Acompanhe instituições, acessos e disponibilidade do ClassVision.',
          action: Row(
            children: [
              OutlinedButton.icon(
                onPressed: onManageInstitutions,
                icon: const Icon(Icons.apartment_outlined, size: 18),
                label: const Text('Ver instituições'),
              ),
              const SizedBox(width: 10),
              AdminPrimaryButton(
                label: 'Nova instituição',
                icon: Icons.add_rounded,
                onPressed: onCreateInstitution,
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        const AdminDataStatus(bottom: 24),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'INSTITUIÇÕES',
                value: '${metrics.totalInstitutions}',
                supportingText: '+$newThisMonth neste mês',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MetricCard(
                label: 'ATIVAS',
                value: '${metrics.activeInstitutions}',
                valueColor: const Color(0xFF15803D),
                supportingText: activeShare,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MetricCard(
                label: 'ADMINISTRADORES',
                value: '${metrics.institutionAdmins}',
                valueColor: AppColors.primary,
                supportingText: 'administradores de instituição',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MetricCard(
                label: 'USUÁRIOS DA PLATAFORMA',
                value: _formatNumber(metrics.platformUsers),
                supportingText: 'usuários cadastrados',
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 326,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: _GrowthCard(institutions: institutions)),
              const SizedBox(width: 24),
              Expanded(
                child: _ServiceStatusCard(services: repository.services),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _RecentActivityCard(activities: repository.activities.take(3).toList()),
      ],
    );
  }

  static String _formatNumber(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

/// Instituições cadastradas por mês nos últimos seis meses.
class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.institutions});
  final List<Institution> institutions;

  static const _months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      for (var back = 5; back >= 0; back--)
        DateTime(now.year, now.month - back),
    ];
    final counts = [
      for (final month in months)
        institutions
            .where(
              (it) =>
                  it.createdAt.year == month.year &&
                  it.createdAt.month == month.month,
            )
            .length,
    ];
    final highest = counts.fold<int>(0, (a, b) => a > b ? a : b);
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crescimento de instituições',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Novas instituições por mês',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < counts.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${counts[index]}', style: _axisStyle),
                          const SizedBox(height: 4),
                          FractionallySizedBox(
                            widthFactor: 1,
                            child: Container(
                              height: highest == 0
                                  ? 4
                                  : 4 + 150 * counts[index] / highest,
                              decoration: BoxDecoration(
                                color: index == counts.length - 1
                                    ? AppColors.primary
                                    : AppColors.primarySoft,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                for (final month in months)
                  Expanded(
                    child: Text(
                      _months[month.month - 1],
                      textAlign: TextAlign.center,
                      style: _axisStyle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _axisStyle = TextStyle(color: Color(0xFF98A2B3), fontSize: 12);

class _ServiceStatusCard extends StatelessWidget {
  const _ServiceStatusCard({required this.services});

  final List<PlatformService> services;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status dos serviços',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final service in services)
          Expanded(
            child: Row(
              children: [
                Expanded(child: Text(service.name)),
                Text(
                  service.healthLabel,
                  style: TextStyle(
                    color: service.health == ServiceHealth.operational
                        ? const Color(0xFF15803D)
                        : const Color(0xFFC2410C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activities});

  final List<PlatformActivity> activities;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade recente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final activity in activities)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 230,
                  child: Text(
                    activity.action,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    activity.institution,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  activity.whenLabel,
                  style: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
