import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_page_header.dart';

typedef InstitutionCreatedCallback = void Function(
  Institution institution,
  String adminName,
  String adminEmail,
);

class CreateInstitutionPage extends StatefulWidget {
  const CreateInstitutionPage({
    super.key,
    required this.onCancel,
    required this.onCreated,
  });
  final VoidCallback onCancel;
  final InstitutionCreatedCallback onCreated;

  @override
  State<CreateInstitutionPage> createState() => _CreateInstitutionPageState();
}

class _CreateInstitutionPageState extends State<CreateInstitutionPage> {
  final _controllers = <TextEditingController>[
    TextEditingController(text: 'Colégio Horizonte'),
    TextEditingController(text: 'CNPJ 12.345.678/0001-90'),
    TextEditingController(text: 'contato@horizonte.edu.br'),
    TextEditingController(text: '(62) 3251-4200'),
    TextEditingController(text: 'Goiânia — GO'),
    TextEditingController(text: 'Paulo Nunes'),
    TextEditingController(text: 'paulo@horizonte.edu.br'),
    TextEditingController(text: '(62) 99814-2330'),
  ];
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    try {
      final input = CreateInstitutionInput(
        name: _controllers[0].text,
        document: _controllers[1].text,
        institutionalEmail: _controllers[2].text,
        phone: _controllers[3].text,
        address: _controllers[4].text,
        adminName: _controllers[5].text,
        adminEmail: _controllers[6].text,
        adminPhone: _controllers[7].text,
      );
      final institution = context.read<AdminRepository>().createInstitution(
        input,
      );
      widget.onCreated(
        institution,
        input.adminName.trim(),
        input.adminEmail.trim(),
      );
    } on ArgumentError {
      setState(() => _error = 'Preencha todos os campos obrigatórios.');
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
    children: [
      AdminPageHeader(
        title: 'Cadastrar instituição',
        subtitle: 'Crie a conta institucional e envie o primeiro acesso administrativo.',
        breadcrumb: 'Instituições  /  Nova instituição',
        action: TextButton(
          onPressed: widget.onCancel,
          child: const Text('Fechar'),
        ),
      ),
      const SizedBox(height: 28),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AdminSurface(
              child: _FormSection(
                title: 'Dados da instituição',
                subtitle: 'Informações oficiais usadas para identificar a instituição.',
                children: [
                  _Field(
                    label: 'Nome da instituição',
                    controller: _controllers[0],
                  ),
                  _Field(
                    label: 'CNPJ ou código INEP',
                    controller: _controllers[1],
                  ),
                  _Field(
                    label: 'E-mail institucional',
                    controller: _controllers[2],
                  ),
                  _Field(label: 'Telefone', controller: _controllers[3]),
                  _Field(label: 'Cidade e estado', controller: _controllers[4]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: AdminSurface(
              child: _FormSection(
                title: 'Primeiro administrador',
                subtitle:
                    'Este responsável receberá o convite inicial por e-mail.',
                children: [
                  _Field(
                    label: 'Nome do administrador',
                    controller: _controllers[5],
                  ),
                  _Field(
                    label: 'E-mail do administrador',
                    controller: _controllers[6],
                  ),
                  _Field(
                    label: 'Telefone do administrador',
                    controller: _controllers[7],
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
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
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'O convite ficará disponível por 7 dias e poderá ser reenviado.',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(
          _error!,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: widget.onCancel,
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Criar instituição e enviar convite'),
          ),
        ],
      ),
    ],
  );
}

class _FormSection extends StatelessWidget {
  const _FormSection({
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
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 22),
      for (var index = 0; index < children.length; index++) ...[
        children[index],
        if (index < children.length - 1) const SizedBox(height: 16),
      ],
    ],
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      TextFormField(controller: controller),
    ],
  );
}
