import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/services/auth_api.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_page_header.dart';

typedef InstitutionCreatedCallback = void Function(Institution institution);

/// Cadastro de instituição no cv-authentication-service (nome, CNPJ e
/// telefone). O administrador da instituição é cadastrado em seguida, como
/// usuário com o perfil "Administrador da instituição".
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
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cnpj = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _cnpj.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final institution = await context
          .read<AdminRepository>()
          .createInstitution(
            CreateInstitutionInput(
              name: _name.text.trim(),
              document: _cnpj.text,
              institutionalEmail: '',
              phone: _phone.text,
              address: '',
              adminName: '',
              adminEmail: '',
              adminPhone: '',
            ),
          );
      if (mounted) widget.onCreated(institution);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
      children: [
        AdminPageHeader(
          title: 'Cadastrar instituição',
          subtitle: 'Crie a instituição e, em seguida, cadastre o administrador dela.',
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
                      controller: _name,
                      hint: 'Instituto Federal Goiano — Câmpus Urutaí',
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Informe o nome'
                          : null,
                    ),
                    _Field(
                      label: 'CNPJ',
                      controller: _cnpj,
                      hint: '00.000.000/0000-00',
                      inputFormatters: [CnpjInputFormatter()],
                      validator: (value) => isValidCnpjFormat(value ?? '')
                          ? null
                          : 'Informe um CNPJ com 14 caracteres',
                    ),
                    _Field(
                      label: 'Telefone',
                      controller: _phone,
                      hint: '(64) 3465-1900',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneInputFormatter()],
                      validator: (value) => isValidPhone(value ?? '')
                          ? null
                          : 'Informe DDD + número',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: AdminSurface(
                child: _FormSection(
                  title: 'Administrador da instituição',
                  subtitle: 'Cadastrado logo depois, na próxima tela.',
                  children: [
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
                              'Depois de criar a instituição você cadastra o '
                              'administrador dela com nome, CPF, e-mail e '
                              'senha. Ele entra no app e cadastra '
                              'coordenadores, professores e secretários.',
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
              onPressed: _saving ? null : widget.onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Criar instituição'),
            ),
          ],
        ),
      ],
    ),
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
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}
