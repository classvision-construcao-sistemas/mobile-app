import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../admin/data/admin_repository.dart';
import 'coordinators_page.dart';

class InstitutionSettingsPage extends StatefulWidget {
  const InstitutionSettingsPage({
    super.key,
    required this.onManageUsers,
    this.onEditInstitution,
  });

  final VoidCallback onManageUsers;
  final VoidCallback? onEditInstitution;

  @override
  State<InstitutionSettingsPage> createState() =>
      _InstitutionSettingsPageState();
}

class _InstitutionSettingsPageState extends State<InstitutionSettingsPage> {
  static const _tabs = ['Instituição', 'Equipe de coordenação', 'Integrações'];

  int _selected = 1;

  Widget _content(BuildContext context) {
    final institution = context.watch<AuthRepository>().institution;
    final admin = context.watch<AdminRepository>();
    return switch (_selected) {
      0 => _SettingsSection(
        title: 'Dados da instituição',
        subtitle: 'Cadastro no serviço de autenticação.',
        children: institution == null
            ? const [_SettingLine(label: 'Instituição', value: 'Carregando...')]
            : [
                _SettingLine(label: 'Nome', value: institution.name),
                _SettingLine(label: 'CNPJ', value: institution.formattedCnpj),
                _SettingLine(
                  label: 'Telefone',
                  value: institution.formattedPhone,
                ),
                _SettingLine(
                  label: 'Situação',
                  value: institution.active ? 'Ativa' : 'Inativa',
                ),
                if (institution.createdAt != null)
                  _SettingLine(
                    label: 'Cadastro',
                    value: formatBrDate(institution.createdAt!),
                  ),
              ],
      ),
      2 => _SettingsSection(
        title: 'Integrações',
        subtitle: 'Microsserviços usados pelo ClassVision.',
        children: [
          for (final service in admin.services)
            _SettingLine(label: service.name, value: service.healthLabel),
        ],
      ),
      _ => const CoordinatorsPage(),
    };
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(40, 30, 40, 36),
    children: [
      const Text(
        'Instituição / Administração',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Gerencie a instituição, a equipe e as integrações do ClassVision.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: widget.onManageUsers,
            icon: const Icon(Icons.manage_accounts_outlined, size: 18),
            label: const Text('Usuários e acessos'),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: widget.onEditInstitution,
            icon: const Icon(Icons.apartment_outlined, size: 18),
            label: const Text('Editar instituição'),
          ),
        ],
      ),
      const SizedBox(height: 26),
      AdminSurface(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            for (var index = 0; index < _tabs.length; index++)
              _SettingsTab(
                label: _tabs[index],
                selected: _selected == index,
                onTap: () {
                  setState(() => _selected = index);
                  if (index == 2) {
                    context.read<AdminRepository>().checkServices();
                  }
                },
              ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      AdminSurface(child: _content(context)),
    ],
  );
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
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
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 20),
      ...children,
    ],
  );
}

class _SettingLine extends StatelessWidget {
  const _SettingLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(value, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    ),
  );
}
