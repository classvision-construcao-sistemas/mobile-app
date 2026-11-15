import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import 'coordinators_page.dart';

class InstitutionSettingsPage extends StatefulWidget {
  const InstitutionSettingsPage({super.key});

  @override
  State<InstitutionSettingsPage> createState() =>
      _InstitutionSettingsPageState();
}

class _InstitutionSettingsPageState extends State<InstitutionSettingsPage> {
  static const _tabs = [
    'Instituição',
    'Regras de presença',
    'Integração de IA',
    'Equipe de coordenação',
    'Notificações',
    'Segurança',
  ];

  int _selected = 3;
  bool _lateNotifications = true;
  bool _weeklySummary = true;

  Widget _content() => switch (_selected) {
    0 => const _SettingsSection(
      title: 'Dados da instituição',
      subtitle: 'Informações usadas nos relatórios e convites.',
      children: [
        _SettingLine(label: 'Instituição', value: 'IF Goiano — Câmpus Urutaí'),
        _SettingLine(label: 'E-mail', value: 'contato.urutai@ifgoiano.edu.br'),
        _SettingLine(label: 'Localização', value: 'Urutaí — GO'),
      ],
    ),
    1 => const _SettingsSection(
      title: 'Regras de presença',
      subtitle: 'Critérios aplicados às chamadas da instituição.',
      children: [
        _SettingLine(label: 'Presença mínima', value: '75%'),
        _SettingLine(label: 'Tolerância para atraso', value: '10 minutos'),
        _SettingLine(
          label: 'Revisão manual',
          value: 'Obrigatória em divergências',
        ),
      ],
    ),
    2 => const _SettingsSection(
      title: 'Integração de IA',
      subtitle: 'Conexão usada na conferência automática das chamadas.',
      children: [
        _SettingLine(label: 'Reconhecimento facial', value: 'Conectada'),
        _SettingLine(label: 'Última sincronização', value: 'Hoje, 09:38'),
        _SettingLine(label: 'Qualidade mínima', value: 'Alta'),
      ],
    ),
    3 => const CoordinatorsPage(),
    4 => _SettingsSection(
      title: 'Notificações',
      subtitle: 'Escolha quais avisos a administração deve receber.',
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Alertas de chamadas atrasadas'),
          value: _lateNotifications,
          onChanged: (value) => setState(() => _lateNotifications = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Resumo semanal'),
          value: _weeklySummary,
          onChanged: (value) => setState(() => _weeklySummary = value),
        ),
      ],
    ),
    _ => const _SettingsSection(
      title: 'Segurança',
      subtitle: 'Políticas de acesso da equipe administrativa.',
      children: [
        _SettingLine(label: 'Autenticação em duas etapas', value: 'Ativada'),
        _SettingLine(label: 'Tempo de sessão', value: '8 horas'),
        _SettingLine(label: 'Última revisão', value: '14 nov. 2026'),
      ],
    ),
  };

  void _save() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Alterações salvas.')));
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
        child: Row(
          children: [
            for (var index = 0; index < _tabs.length; index++)
              _SettingsTab(
                label: _tabs[index],
                selected: _selected == index,
                onTap: () => setState(() => _selected = index),
              ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      AdminSurface(child: _content()),
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
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 17),
            label: const Text('Salvar alterações'),
          ),
        ],
      ),
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
            fontSize: 11,
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
