import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_api.dart';

/// Professores da instituição, lidos do cv-authentication-service.
class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final _search = TextEditingController();
  List<AppUser> _teachers = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthRepository?>();
    if (auth == null || !(auth.role?.canViewUsers ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await auth.listUsers();
      if (!mounted) return;
      setState(() {
        _teachers =
            users.where((user) => user.role == UserRole.professor).toList()
              ..sort((a, b) {
                if (a.active != b.active) return a.active ? -1 : 1;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });
      });
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    await Navigator.pushNamed(context, AppRoutes.userRegistration);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository?>();
    final canManage = auth?.role?.canManageUsers ?? false;
    final canView = auth?.role?.canViewUsers ?? false;
    final query = _search.text.trim().toLowerCase();
    final visible = [
      for (final teacher in _teachers)
        if (query.isEmpty ||
            teacher.name.toLowerCase().contains(query) ||
            teacher.email.toLowerCase().contains(query))
          teacher,
    ];
    final active = _teachers.where((it) => it.active).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão acadêmica / Pessoas',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 9),
                  Text(
                    'Professores',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Acompanhe os docentes cadastrados na instituição.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (canManage)
              FilledButton.icon(
                onPressed: _register,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Cadastrar professor'),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: MetricCard(label: 'ATIVOS', value: '$active'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                label: 'INATIVOS',
                value: '${_teachers.length - active}',
                valueColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(label: 'TOTAL', value: '${_teachers.length}'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppSearchField(
          controller: _search,
          hint: 'Buscar professor',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        AdminSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (!canView)
                const _Message('O seu perfil não pode consultar usuários.')
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error case final error?)
                _Message(error, onRetry: _load)
              else if (visible.isEmpty)
                const _Message('Nenhum professor cadastrado.'),
              if (canView && !_loading && _error == null)
                for (final teacher in visible)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          child: Text(teacher.initials),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Text(
                            teacher.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(flex: 2, child: Text(teacher.email)),
                        Expanded(child: Text(teacher.institutionName)),
                        Text(
                          teacher.active ? 'Ativo' : 'Inativo',
                          style: TextStyle(
                            color: teacher.active
                                ? const Color(0xFF15803D)
                                : AppColors.warning,
                            fontWeight: FontWeight.w700,
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
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
      ],
    ),
  );
}
