import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_page_header.dart';

class PlatformActivityPage extends StatelessWidget {
  const PlatformActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = context.watch<AdminRepository>().activities;
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      children: [
        const AdminPageHeader(
          title: 'Atividade da plataforma',
          subtitle: 'Consulte ações administrativas e eventos de segurança.',
        ),
        const SizedBox(height: 30),
        AdminSurface(
          child: Row(
            children: [
              const Icon(
                Icons.manage_search_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Buscar por ação, instituição ou usuário'),
              ),
              _FilterChip(label: 'Todos os usuários'),
              const SizedBox(width: 10),
              _FilterChip(label: 'Últimos 30 dias'),
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
              for (final activity in activities)
                _ActivityRow(activity: activity),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 7),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
      ],
    ),
  );
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
