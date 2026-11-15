import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_page_header.dart';

class InstitutionDetailPage extends StatelessWidget {
  const InstitutionDetailPage({
    super.key,
    required this.institutionId,
    required this.onBack,
  });
  final String institutionId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final institution = repository.findInstitution(institutionId);
    if (institution == null) {
      return Center(
        child: TextButton(
          onPressed: onBack,
          child: const Text('Voltar para instituições'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Instituições'),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 12),
        AdminPageHeader(
          title: 'Detalhes da instituição',
          subtitle: institution.name,
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 17,
                  color: AppColors.primary,
                ),
                SizedBox(width: 7),
                Text(
                  'Somente leitura',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Usuários cadastrados',
                value: '${institution.users}',
                supportingText: 'Perfis vinculados à instituição',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MetricCard(
                label: 'Coordenadores',
                value: '${repository.coordinators.length}',
                supportingText: '2 ativos e 1 convite pendente',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MetricCard(
                label: 'Status da conta',
                value: institution.status == InstitutionStatus.active
                    ? 'Ativa'
                    : 'Pausada',
                valueColor: institution.status == InstitutionStatus.active
                    ? const Color(0xFF15803D)
                    : AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  AdminSurface(
                    child: _InstitutionData(institution: institution),
                  ),
                  const SizedBox(height: 22),
                  AdminSurface(
                    padding: EdgeInsets.zero,
                    child: _CoordinatorsTable(
                      coordinators: repository.coordinators,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: AdminSurface(
                child: _InstitutionActivity(activities: repository.activities),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InstitutionData extends StatelessWidget {
  const _InstitutionData({required this.institution});
  final Institution institution;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Dados institucionais',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: _Info(label: 'Nome', value: institution.name),
          ),
          Expanded(
            child: _Info(label: 'Documento', value: institution.document),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: _Info(
              label: 'E-mail',
              value: institution.institutionalEmail,
            ),
          ),
          Expanded(
            child: _Info(label: 'Telefone', value: institution.phone),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _Info(label: 'Localização', value: institution.address),
    ],
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _CoordinatorsTable extends StatelessWidget {
  const _CoordinatorsTable({required this.coordinators});
  final List<CoordinatorAccount> coordinators;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 22, 24, 12),
        child: Text(
          'Coordenadores',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      for (final coordinator in coordinators)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: Text(coordinator.name[0]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coordinator.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      coordinator.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _CoordinatorStatus(status: coordinator.status),
            ],
          ),
        ),
    ],
  );
}

class _CoordinatorStatus extends StatelessWidget {
  const _CoordinatorStatus({required this.status});
  final AccountStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    AccountStatus.active => const StatusBadge(
      label: 'Ativo',
      foreground: Color(0xFF15803D),
      background: Color(0xFFDCFCE7),
    ),
    AccountStatus.inactive => const StatusBadge(
      label: 'Inativo',
      foreground: AppColors.textSecondary,
      background: Color(0xFFF1F5F9),
    ),
    AccountStatus.pending => const StatusBadge(
      label: 'Pendente',
      foreground: Color(0xFFB45309),
      background: Color(0xFFFEF3C7),
    ),
  };
}

class _InstitutionActivity extends StatelessWidget {
  const _InstitutionActivity({required this.activities});
  final List<PlatformActivity> activities;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Atividade institucional',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      for (final activity in activities.take(3))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Icon(Icons.circle, size: 8, color: AppColors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.action,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.whenLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
