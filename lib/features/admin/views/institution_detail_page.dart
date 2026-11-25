import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/services/auth_api.dart';
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

  /// Edita nome, CNPJ e telefone no formulário real de instituição.
  Future<void> _edit(BuildContext context, Institution institution) async {
    final repository = context.read<AdminRepository>();
    await Navigator.pushNamed(
      context,
      AppRoutes.institutionRegistration,
      arguments: int.tryParse(institution.id),
    );
    await repository.load();
  }

  Future<void> _toggleStatus(
    BuildContext context,
    Institution institution,
  ) async {
    final suspending = institution.status != InstitutionStatus.suspended;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(suspending ? 'Suspender acesso?' : 'Reativar acesso?'),
        content: Text(
          suspending
              ? 'Os usuários de ${institution.name} perderão o acesso até a reativação.'
              : '${institution.name} voltará a acessar a plataforma.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(suspending ? 'Suspender' : 'Reativar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<AdminRepository>().setInstitutionStatus(
        institution.id,
        suspending ? InstitutionStatus.suspended : InstitutionStatus.active,
      );
    } on AuthApiException catch (error) {
      if (context.mounted) showAppMessage(context, error.message, error: true);
    }
  }

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
    final coordinators = repository.coordinatorsFor(institution.id);
    final activities = repository.activitiesFor(institution.id);
    final activeCoordinators = coordinators
        .where((item) => item.status == AccountStatus.active)
        .length;
    final inactiveCoordinators = coordinators.length - activeCoordinators;
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
          action: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _toggleStatus(context, institution),
                icon: Icon(
                  institution.status == InstitutionStatus.suspended
                      ? Icons.play_arrow_rounded
                      : Icons.pause_circle_outline_rounded,
                  size: 18,
                ),
                label: Text(
                  institution.status == InstitutionStatus.suspended
                      ? 'Reativar acesso'
                      : 'Suspender acesso',
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _edit(context, institution),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ],
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
                value: '${coordinators.length}',
                supportingText:
                    '$activeCoordinators ativo(s) e $inactiveCoordinators inativo(s)',
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
                    child: _CoordinatorsTable(coordinators: coordinators),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: AdminSurface(
                child: _InstitutionActivity(activities: activities),
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
            child: _Info(label: 'Telefone', value: institution.phone),
          ),
          Expanded(
            child: _Info(
              label: 'Cadastro',
              value: formatBrDate(institution.createdAt),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _Info(label: 'Administrador', value: institution.adminName),
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
          fontSize: 12,
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
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Coordenadores',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            StatusBadge(
              label: 'Somente leitura',
              foreground: AppColors.primary,
              background: AppColors.primarySoft,
            ),
          ],
        ),
      ),
      if (coordinators.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Text(
            'Nenhum coordenador vinculado.',
            style: TextStyle(color: AppColors.textSecondary),
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
                        fontSize: 12,
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
      if (activities.isEmpty)
        const Text(
          'Nenhuma atividade registrada.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
                        fontSize: 12,
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
