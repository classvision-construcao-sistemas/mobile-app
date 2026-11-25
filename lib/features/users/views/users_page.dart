import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/users_view_model.dart';

enum _UserAction { edit, activate, deactivate, delete }

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => UsersViewModel(context.read<AuthRepository>())..load(),
    child: const _UsersContent(),
  );
}

class _UsersContent extends StatelessWidget {
  const _UsersContent();

  Future<void> _openForm(BuildContext context, [AppUser? user]) async {
    final viewModel = context.read<UsersViewModel>();
    await Navigator.pushNamed(
      context,
      AppRoutes.userRegistration,
      arguments: user,
    );
    await viewModel.load();
  }

  Future<void> _handle(
    BuildContext context,
    AppUser user,
    _UserAction action,
  ) async {
    final viewModel = context.read<UsersViewModel>();
    final String? error;
    final String success;
    switch (action) {
      case _UserAction.edit:
        await _openForm(context, user);
        return;
      case _UserAction.activate:
        error = await viewModel.setActive(user, active: true);
        success = '${user.name} foi ativado.';
      case _UserAction.deactivate:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Desativar usuário',
          message:
              '${user.name} perderá o acesso imediatamente. '
              'Você pode ativá-lo de novo depois.',
          confirmLabel: 'Desativar',
          destructive: true,
        );
        if (!confirmed) return;
        error = await viewModel.setActive(user, active: false);
        success = '${user.name} foi desativado.';
      case _UserAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Excluir usuário',
          message:
              'A exclusão de ${user.name} é definitiva. Prefira desativar se '
              'o usuário já tiver turmas ou chamadas registradas.',
          confirmLabel: 'Excluir',
          destructive: true,
        );
        if (!confirmed) return;
        error = await viewModel.delete(user);
        success = '${user.name} foi excluído.';
    }
    if (!context.mounted) return;
    showAppMessage(context, error ?? success, error: error != null);
  }

  void _showDetails(BuildContext context, AppUser user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _UserDetails(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final viewModel = context.watch<UsersViewModel>();
    final role = auth.role;
    final canManage = role?.canManageUsers ?? false;
    final users = viewModel.users;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Novo usuário'),
            )
          : null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 96),
            children: [
              Text(
                role?.isGeneralAdmin ?? false
                    ? 'Usuários de todas as instituições.'
                    : 'Usuários da sua instituição.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              AppSearchField(
                hint: 'Buscar por nome, e-mail ou perfil',
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
              else if (users.isEmpty && viewModel.error == null)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(Icons.person_search_rounded, size: 48),
                      SizedBox(height: 12),
                      Text('Nenhum usuário encontrado'),
                    ],
                  ),
                )
              else
                for (final user in users) ...[
                  _UserCard(
                    user: user,
                    showInstitution: role?.isGeneralAdmin ?? false,
                    isCurrentUser: auth.isCurrentUser(user),
                    busy: viewModel.isBusy(user),
                    actions: _actionsFor(auth, user),
                    onTap: auth.canManageUser(user)
                        ? () => _openForm(context, user)
                        : () => _showDetails(context, user),
                    onAction: (action) => _handle(context, user, action),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  /// Ações permitidas pela API para o usuário logado sobre [user].
  List<_UserAction> _actionsFor(AuthRepository auth, AppUser user) {
    if (!auth.canManageUser(user)) return const [];
    if (auth.isCurrentUser(user)) return const [_UserAction.edit];
    return [
      _UserAction.edit,
      user.active ? _UserAction.deactivate : _UserAction.activate,
      _UserAction.delete,
    ];
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.showInstitution,
    required this.isCurrentUser,
    required this.busy,
    required this.actions,
    required this.onTap,
    required this.onAction,
  });

  final AppUser user;
  final bool showInstitution;
  final bool isCurrentUser;
  final bool busy;
  final List<_UserAction> actions;
  final VoidCallback onTap;
  final ValueChanged<_UserAction> onAction;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: busy ? null : onTap,
    padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: user.active
              ? AppColors.primarySoft
              : AppColors.divider,
          child: Text(
            user.initials,
            style: TextStyle(
              color: user.active ? AppColors.primary : AppColors.navInactive,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrentUser ? '${user.name} (você)' : user.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                showInstitution && user.institutionName.isNotEmpty
                    ? '${user.email} · ${user.institutionName}'
                    : user.email,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AppStatusChip(label: user.roleLabel),
                  if (!user.active)
                    const AppStatusChip(
                      label: 'Inativo',
                      color: AppColors.error,
                    ),
                ],
              ),
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
        else if (actions.isNotEmpty)
          PopupMenuButton<_UserAction>(
            tooltip: 'Ações',
            onSelected: onAction,
            itemBuilder: (_) => [
              for (final action in actions)
                PopupMenuItem(
                  value: action,
                  child: Text(switch (action) {
                    _UserAction.edit => 'Editar',
                    _UserAction.activate => 'Ativar',
                    _UserAction.deactivate => 'Desativar',
                    _UserAction.delete => 'Excluir',
                  }),
                ),
            ],
          )
        else
          const SizedBox(width: 12),
      ],
    ),
  );
}

class _UserDetails extends StatelessWidget {
  const _UserDetails({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final birthDate = user.birthDate;
    final createdAt = user.createdAt;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              user.active ? user.roleLabel : '${user.roleLabel} · Inativo',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            AppInfoTile(label: 'E-mail', value: user.email),
            const SizedBox(height: 10),
            AppInfoTile(label: 'CPF', value: formatCpf(user.cpf)),
            if (birthDate != null) ...[
              const SizedBox(height: 10),
              AppInfoTile(
                label: 'Data de nascimento',
                value: formatBrDate(birthDate),
              ),
            ],
            if (user.institutionName.isNotEmpty) ...[
              const SizedBox(height: 10),
              AppInfoTile(label: 'Instituição', value: user.institutionName),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 10),
              AppInfoTile(
                label: 'Cadastrado em',
                value: formatBrDateTime(createdAt),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
