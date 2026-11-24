import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_page_header.dart';

class InstitutionsPage extends StatefulWidget {
  const InstitutionsPage({
    super.key,
    required this.onCreateInstitution,
    required this.onOpenInstitution,
  });

  final VoidCallback onCreateInstitution;
  final ValueChanged<String> onOpenInstitution;

  @override
  State<InstitutionsPage> createState() => _InstitutionsPageState();
}

class _InstitutionsPageState extends State<InstitutionsPage> {
  final _search = TextEditingController();
  InstitutionStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final institutions = [
      for (final institution in repository.searchInstitutions(_search.text))
        if (_status == null || institution.status == _status) institution,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      children: [
        AdminPageHeader(
          title: 'Gestão de instituições',
          subtitle:
              'Cadastre, consulte e acompanhe as instituições da plataforma.',
          action: AdminPrimaryButton(
            label: '+ Nova instituição',
            onPressed: widget.onCreateInstitution,
          ),
        ),
        const SizedBox(height: 30),
        AdminSurface(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar instituição ou administrador',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              DropdownButton<InstitutionStatus?>(
                value: _status,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos os status')),
                  DropdownMenuItem(
                    value: InstitutionStatus.active,
                    child: Text('Ativas'),
                  ),
                  DropdownMenuItem(
                    value: InstitutionStatus.suspended,
                    child: Text('Suspensas'),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AdminSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const _InstitutionHeader(),
              if (institutions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(64),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        color: AppColors.textSecondary,
                        size: 36,
                      ),
                      SizedBox(height: 12),
                      Text('Nenhuma instituição encontrada'),
                    ],
                  ),
                )
              else
                for (final institution in institutions)
                  _InstitutionRow(
                    institution: institution,
                    onTap: () => widget.onOpenInstitution(institution.id),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstitutionHeader extends StatelessWidget {
  const _InstitutionHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: const Row(
      children: [
        Expanded(flex: 3, child: _HeaderText('INSTITUIÇÃO')),
        Expanded(flex: 2, child: _HeaderText('ADMINISTRADOR')),
        Expanded(child: _HeaderText('USUÁRIOS')),
        Expanded(flex: 2, child: _HeaderText('CADASTRO')),
        Expanded(child: _HeaderText('STATUS')),
        SizedBox(width: 40),
      ],
    ),
  );
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _InstitutionRow extends StatelessWidget {
  const _InstitutionRow({required this.institution, required this.onTap});

  final Institution institution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  institution.document,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(institution.adminName)),
          Expanded(child: Text('${institution.users}')),
          Expanded(flex: 2, child: Text(_formatDate(institution.createdAt))),
          Expanded(child: _InstitutionStatusBadge(status: institution.status)),
          const SizedBox(
            width: 40,
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime value) {
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}

class _InstitutionStatusBadge extends StatelessWidget {
  const _InstitutionStatusBadge({required this.status});

  final InstitutionStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    InstitutionStatus.active => const StatusBadge(
      label: 'Ativa',
      foreground: Color(0xFF15803D),
      background: Color(0xFFDCFCE7),
    ),
    InstitutionStatus.pending => const StatusBadge(
      label: 'Pendente',
      foreground: Color(0xFFB45309),
      background: Color(0xFFFEF3C7),
    ),
    InstitutionStatus.suspended => const StatusBadge(
      label: 'Suspensa',
      foreground: AppColors.error,
      background: Color(0xFFFEE2E2),
    ),
  };
}
