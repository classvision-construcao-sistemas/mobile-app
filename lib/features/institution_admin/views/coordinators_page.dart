import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../core/widgets/status_badge.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/domain/admin_models.dart';

class CoordinatorsPage extends StatefulWidget {
  const CoordinatorsPage({super.key, this.mobile = false, this.onBack});
  final bool mobile;
  final VoidCallback? onBack;

  @override
  State<CoordinatorsPage> createState() => _CoordinatorsPageState();
}

class _CoordinatorsPageState extends State<CoordinatorsPage> {
  final _inviteController = TextEditingController();
  final _searchController = TextEditingController();
  bool _showInvite = false;
  String? _inviteError;

  @override
  void dispose() {
    _inviteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _invite() {
    try {
      context.read<AdminRepository>().inviteCoordinator(_inviteController.text);
      setState(() {
        _inviteController.clear();
        _inviteError = null;
        _showInvite = false;
      });
      _message('Convite enviado.');
    } on ArgumentError {
      setState(() => _inviteError = 'Informe um e-mail válido.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _deactivate(CoordinatorAccount coordinator) async {
    final confirmed = await _confirm(
      title: 'Desativar coordenador?',
      message: '${coordinator.name} perderá o acesso às turmas da instituição.',
    );
    if (!mounted || !confirmed) return;
    context.read<AdminRepository>().setCoordinatorStatus(
      coordinator.id,
      AccountStatus.inactive,
    );
  }

  Future<void> _cancelInvite(CoordinatorAccount coordinator) async {
    final confirmed = await _confirm(
      title: 'Cancelar convite?',
      message:
          'O convite enviado para ${coordinator.email} deixará de funcionar.',
    );
    if (!mounted || !confirmed) return;
    context.read<AdminRepository>().cancelCoordinatorInvite(coordinator.id);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final query = _searchController.text.trim().toLowerCase();
    final coordinators = repository.coordinators
        .where(
          (item) =>
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.email.toLowerCase().contains(query),
        )
        .toList(growable: false);
    return widget.mobile ? _mobile(coordinators) : _desktop(coordinators);
  }

  Widget _mobile(List<CoordinatorAccount> coordinators) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Sair',
                onPressed: widget.onBack,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              const Expanded(
                child: Text(
                  'Coordenadores',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'MC',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 28, top: 2),
            child: Text(
              'Administrador da instituição',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Buscar coordenador',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: () => setState(() => _showInvite = !_showInvite),
              icon: const Icon(Icons.add_rounded),
              label: const Text('+ Convidar coordenador'),
            ),
          ),
          if (_showInvite) ...[
            const SizedBox(height: 12),
            _InviteBox(
              controller: _inviteController,
              error: _inviteError,
              onSubmit: _invite,
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Equipe da instituição',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final coordinator in coordinators) ...[
            _CoordinatorCard(
              coordinator: coordinator,
              onActivate: () => context
                  .read<AdminRepository>()
                  .setCoordinatorStatus(coordinator.id, AccountStatus.active),
              onDeactivate: () => _deactivate(coordinator),
              onResend: () {
                context.read<AdminRepository>().resendCoordinatorInvite(
                  coordinator.id,
                );
                _message('Convite reenviado.');
              },
              onCancel: () => _cancelInvite(coordinator),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Somente administradores da instituição podem',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'convidar, ativar ou desativar coordenadores.',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _desktop(List<CoordinatorAccount> coordinators) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coordenadores',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'Convide e gerencie quem acompanha as turmas desta instituição.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => setState(() => _showInvite = !_showInvite),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ Convidar coordenador'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (_showInvite || !widget.mobile) ...[
        _InviteBox(
          controller: _inviteController,
          error: _inviteError,
          onSubmit: _invite,
        ),
        const SizedBox(height: 20),
      ],
      Text(
        'EQUIPE ATUAL · ${coordinators.length} COORDENADORES',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
      ),
      const SizedBox(height: 10),
      for (final coordinator in coordinators)
        _CoordinatorRow(
          coordinator: coordinator,
          onActivate: () => context
              .read<AdminRepository>()
              .setCoordinatorStatus(coordinator.id, AccountStatus.active),
          onDeactivate: () => _deactivate(coordinator),
          onResend: () {
            context.read<AdminRepository>().resendCoordinatorInvite(
              coordinator.id,
            );
            _message('Convite reenviado.');
          },
          onCancel: () => _cancelInvite(coordinator),
        ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 19,
            ),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permissões do coordenador',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pode gerenciar turmas, alunos, professores, chamadas e relatórios. Configurações, integrações e equipe ficam restritas ao administrador.',
                    style: TextStyle(color: AppColors.primary, fontSize: 11),
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

class _InviteBox extends StatelessWidget {
  const _InviteBox({
    required this.controller,
    required this.error,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOVO CONVITE',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'coordenador@instituicao.edu.br',
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onSubmit,
              child: const Text('Enviar convite'),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 7),
          Text(
            error!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}

class _CoordinatorCard extends StatelessWidget {
  const _CoordinatorCard({
    required this.coordinator,
    required this.onActivate,
    required this.onDeactivate,
    required this.onResend,
    required this.onCancel,
  });
  final CoordinatorAccount coordinator;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onResend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: const EdgeInsets.all(15),
    child: Column(
      children: [
        Row(
          children: [
            _Avatar(name: coordinator.name),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coordinator.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
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
            _AccountBadge(status: coordinator.status),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _Actions(
            coordinator: coordinator,
            onActivate: onActivate,
            onDeactivate: onDeactivate,
            onResend: onResend,
            onCancel: onCancel,
          ),
        ),
      ],
    ),
  );
}

class _CoordinatorRow extends StatelessWidget {
  const _CoordinatorRow({
    required this.coordinator,
    required this.onActivate,
    required this.onDeactivate,
    required this.onResend,
    required this.onCancel,
  });
  final CoordinatorAccount coordinator;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onResend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        _Avatar(name: coordinator.name),
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
                '${coordinator.email} · ${coordinator.status == AccountStatus.pending ? 'convite enviado hoje' : '${coordinator.classCount} turmas'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        _AccountBadge(status: coordinator.status),
        const SizedBox(width: 14),
        _Actions(
          coordinator: coordinator,
          onActivate: onActivate,
          onDeactivate: onDeactivate,
          onResend: onResend,
          onCancel: onCancel,
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 19,
    backgroundColor: AppColors.primarySoft,
    foregroundColor: AppColors.primary,
    child: Text(
      name.split(' ').map((part) => part[0]).take(2).join(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({required this.status});
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

class _Actions extends StatelessWidget {
  const _Actions({
    required this.coordinator,
    required this.onActivate,
    required this.onDeactivate,
    required this.onResend,
    required this.onCancel,
  });
  final CoordinatorAccount coordinator;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onResend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => switch (coordinator.status) {
    AccountStatus.active => TextButton(
      onPressed: onDeactivate,
      child: const Text('Desativar'),
    ),
    AccountStatus.inactive => TextButton(
      onPressed: onActivate,
      child: const Text('Ativar'),
    ),
    AccountStatus.pending => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: onResend, child: const Text('Reenviar')),
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
      ],
    ),
  };
}
