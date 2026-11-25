import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_data_status.dart';
import 'widgets/admin_page_header.dart';

class PlatformActivityPage extends StatefulWidget {
  const PlatformActivityPage({super.key});

  @override
  State<PlatformActivityPage> createState() => _PlatformActivityPageState();
}

class _PlatformActivityPageState extends State<PlatformActivityPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final activities = [
      for (final activity in context.watch<AdminRepository>().activities)
        if (query.isEmpty ||
            activity.action.toLowerCase().contains(query) ||
            activity.institution.toLowerCase().contains(query) ||
            activity.user.toLowerCase().contains(query))
          activity,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      children: [
        const AdminPageHeader(
          title: 'Atividade da plataforma',
          subtitle: 'Cadastros recentes de instituições e usuários.',
        ),
        const SizedBox(height: 30),
        const AdminDataStatus(),
        AdminSurface(
          child: Row(
            children: [
              const Icon(
                Icons.manage_search_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por ação, instituição ou usuário',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AdminSurface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 22, 24, 16),
                child: Text(
                  'Auditoria',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (activities.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Text(
                    adminEmptyText(context, 'Nenhuma atividade encontrada.'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              for (final activity in activities)
                _ActivityRow(activity: activity),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final PlatformActivity activity;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.history_rounded,
            color: AppColors.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.action,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                activity.institution,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: Text(activity.user)),
        Text(
          activity.whenLabel,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}
