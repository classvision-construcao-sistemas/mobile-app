import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import 'coordinators_page.dart';

class InstitutionSettingsPage extends StatelessWidget {
  const InstitutionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(40, 30, 40, 36),
    children: [
      const Text(
        'Instituição / Administração',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 10),
      const Text(
        'Configurações',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Gerencie a instituição, a equipe e as integrações do ClassVision.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 26),
      AdminSurface(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: const Row(
          children: [
            _SettingsTab(label: 'Instituição'),
            _SettingsTab(label: 'Regras de presença'),
            _SettingsTab(label: 'Integração de IA'),
            _SettingsTab(label: 'Equipe de coordenação', selected: true),
            _SettingsTab(label: 'Notificações'),
            _SettingsTab(label: 'Segurança'),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const AdminSurface(child: CoordinatorsPage()),
      const SizedBox(height: 18),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Última atualização por Marina Costa · hoje, 09:42',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          FilledButton.icon(
            onPressed: null,
            icon: Icon(Icons.check_rounded, size: 17),
            label: Text('Salvar alterações'),
          ),
        ],
      ),
    ],
  );
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 38,
      alignment: Alignment.center,
      decoration: selected
          ? BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(9),
            )
          : null,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ),
  );
}
