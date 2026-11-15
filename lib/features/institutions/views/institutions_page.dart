import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/institutions_view_model.dart';

enum _InstitutionAction { edit, activate, deactivate }

/// Lista de instituições (somente o administrador geral).
class InstitutionsPage extends StatelessWidget {
  const InstitutionsPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        InstitutionsViewModel(context.read<AuthRepository>())..load(),
    child: const _InstitutionsContent(),
  );
}

class _InstitutionsContent extends StatelessWidget {
  const _InstitutionsContent();

  Future<void> _openForm(
    BuildContext context, [
    Institution? institution,
  ]) async {
    final viewModel = context.read<InstitutionsViewModel>();
    await Navigator.pushNamed(
      context,
      AppRoutes.institutionRegistration,
      arguments: institution,
    );
    await viewModel.load();
  }

  Future<void> _handle(
    BuildContext context,
    Institution institution,
    _InstitutionAction action,
  ) async {
    final viewModel = context.read<InstitutionsViewModel>();
    final String? error;
    final String success;
    switch (action) {
      case _InstitutionAction.edit:
        await _openForm(context, institution);
        return;
      case _InstitutionAction.activate:
        error = await viewModel.setActive(institution, active: true);
        success = '${institution.name} foi ativada.';
      case _InstitutionAction.deactivate:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Desativar instituição',
          message:
              '${institution.name} deixará de receber novos usuários. '
              'Os usuários atuais continuam conseguindo entrar.',
          confirmLabel: 'Desativar',
          destructive: true,
        );
        if (!confirmed) return;
        error = await viewModel.setActive(institution, active: false);
        success = '${institution.name} foi desativada.';
    }
    if (!context.mounted) return;
    showAppMessage(context, error ?? success, error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InstitutionsViewModel>();
    final institutions = viewModel.institutions;

    return Scaffold(
      appBar: AppBar(title: const Text('Instituições')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nova instituição'),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 96),
            children: [
              const Text(
                'Cada usuário pertence a uma instituição. Cadastre a '
                'instituição antes do administrador dela.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Buscar',
                hint: 'Nome ou CNPJ',
                icon: Icons.search_rounded,
                onChanged: viewModel.search,
              ),
              const SizedBox(height: 16),
              if (viewModel.error != null) ...[
                AppErrorBanner(viewModel.error!, onRetry: viewModel.load),
                const SizedBox(height: 16),
              ],
              if (viewModel.loading && viewModel.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (institutions.isEmpty && viewModel.error == null)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(Icons.domain_disabled_outlined, size: 48),
                      SizedBox(height: 12),
                      Text('Nenhuma instituição encontrada'),
                    ],
                  ),
                )
              else
                for (final institution in institutions) ...[
                  _InstitutionCard(
                    institution: institution,
                    busy: viewModel.isBusy(institution),
                    onTap: () => _openForm(context, institution),
                    onAction: (action) => _handle(context, institution, action),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  const _InstitutionCard({
    required this.institution,
    required this.busy,
    required this.onTap,
    required this.onAction,
  });

  final Institution institution;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<_InstitutionAction> onAction;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: busy ? null : onTap,
    padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: institution.active
                ? AppColors.primarySoft
                : AppColors.divider,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.apartment_rounded,
            color: institution.active
                ? AppColors.primary
                : AppColors.navInactive,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                institution.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'CNPJ ${institution.formattedCnpj} · '
                '${institution.formattedPhone}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (!institution.active) ...[
                const SizedBox(height: 7),
                const AppStatusChip(label: 'Inativa', color: AppColors.error),
              ],
            ],
          ),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          PopupMenuButton<_InstitutionAction>(
            tooltip: 'Ações',
            onSelected: onAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _InstitutionAction.edit,
                child: Text('Editar'),
              ),
              PopupMenuItem(
                value: institution.active
                    ? _InstitutionAction.deactivate
                    : _InstitutionAction.activate,
                child: Text(institution.active ? 'Desativar' : 'Ativar'),
              ),
            ],
          ),
      ],
    ),
  );
}
