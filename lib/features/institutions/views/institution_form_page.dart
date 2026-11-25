import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_api.dart';

/// Cadastro e edição de instituições no cv-authentication-service.
///
/// Sem [institution] nem [institutionId], cadastra (somente o administrador
/// geral). O administrador da instituição edita só nome e telefone da própria.
class InstitutionFormPage extends StatefulWidget {
  const InstitutionFormPage({super.key, this.institution, this.institutionId});

  final Institution? institution;
  final int? institutionId;

  @override
  State<InstitutionFormPage> createState() => _InstitutionFormPageState();
}

class _InstitutionFormPageState extends State<InstitutionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cnpj = TextEditingController();
  final _phone = TextEditingController();

  Institution? _institution;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  bool get _editing => _institution != null || widget.institutionId != null;

  @override
  void initState() {
    super.initState();
    final institution = widget.institution;
    if (institution != null) {
      _fill(institution);
    } else if (widget.institutionId != null) {
      _loading = true;
      _load();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _cnpj.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _fill(Institution institution) {
    _institution = institution;
    _name.text = institution.name;
    _cnpj.text = institution.formattedCnpj;
    _phone.text = institution.formattedPhone;
  }

  void _retryLoad() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  /// Chamado no initState (sem setState antes do primeiro await).
  Future<void> _load() async {
    final id = widget.institutionId;
    if (id == null) return;
    try {
      final institution = await context.read<AuthRepository>().getInstitution(
        id,
      );
      if (!mounted) return;
      setState(() => _fill(institution));
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saveError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthRepository>();
    final current = _institution;
    final canChangeCnpj = auth.role?.canManageInstitutions ?? false;
    final payload = InstitutionPayload(
      name: _name.text,
      // O admin da instituição não altera o CNPJ: reenvia o atual.
      cnpj: canChangeCnpj || current == null ? _cnpj.text : current.cnpj,
      phone: _phone.text,
    );

    setState(() => _saving = true);
    try {
      if (current == null) {
        await auth.createInstitution(payload);
      } else {
        await auth.updateInstitution(current.id, payload);
      }
      if (!mounted) return;
      showAppMessage(
        context,
        current == null
            ? 'Instituição ${payload.name.trim()} cadastrada.'
            : 'Instituição ${payload.name.trim()} atualizada.',
      );
      Navigator.pop(context);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _saveError = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canChangeCnpj =
        context.watch<AuthRepository>().role?.canManageInstitutions ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar instituição' : 'Nova instituição'),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [AppErrorBanner(_loadError!, onRetry: _retryLoad)],
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                  children: [
                    Text(
                      _editing
                          ? 'Atualize os dados da instituição.'
                          : 'Toda instituição nasce ativa. Depois de '
                                'cadastrá-la, cadastre o administrador dela '
                                'em Usuários.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    AppTextField(
                      label: 'Nome da instituição',
                      icon: Icons.apartment_rounded,
                      controller: _name,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Informe o nome'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'CNPJ',
                      hint: '00.000.000/0000-00',
                      icon: Icons.badge_outlined,
                      controller: _cnpj,
                      inputFormatters: [CnpjInputFormatter()],
                      enabled: canChangeCnpj || !_editing,
                      helperText: canChangeCnpj || !_editing
                          ? 'Aceita o CNPJ numérico ou alfanumérico.'
                          : 'Somente o administrador geral altera o CNPJ.',
                      validator: (value) => isValidCnpjFormat(value ?? '')
                          ? null
                          : 'Informe um CNPJ com 14 caracteres',
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Telefone',
                      hint: '(64) 3465-1900',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      controller: _phone,
                      inputFormatters: [PhoneInputFormatter()],
                      onFieldSubmitted: (_) => _save(),
                      validator: (value) => isValidPhone(value ?? '')
                          ? null
                          : 'Informe DDD + número',
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: 16),
                      AppErrorBanner(_saveError!),
                    ],
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _editing
                          ? 'Salvar alterações'
                          : 'Cadastrar instituição',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
