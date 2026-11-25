import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_api.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Cadastro e edição de usuários no cv-authentication-service.
///
/// Sem [user] nem [userId], cadastra um novo usuário. Com [userId], carrega o
/// usuário antes de editar (usado em "Editar perfil").
/// Perfil e instituição já escolhidos ao abrir o cadastro de um usuário
/// novo (ex.: "Cadastrar coordenador", "Cadastrar administrador").
class UserFormPreset {
  const UserFormPreset({this.role, this.institutionId});

  final UserRole? role;
  final int? institutionId;
}

class UserFormPage extends StatefulWidget {
  const UserFormPage({
    super.key,
    this.user,
    this.userId,
    this.editingSelf = false,
    this.preset,
  });

  final AppUser? user;
  final int? userId;
  final bool editingSelf;
  final UserFormPreset? preset;

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cpf = TextEditingController();
  final _email = TextEditingController();
  final _birthDate = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  AppUser? _user;
  UserRole? _role;
  int? _institutionId;
  List<Institution> _institutions = const [];

  bool _loadingUser = false;
  bool _loadingInstitutions = false;
  bool _saving = false;
  bool _obscurePassword = true;
  String? _loadError;
  String? _saveError;

  bool get _editing => _user != null || widget.userId != null;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthRepository>();
    final user = widget.user;
    if (user != null) {
      _fill(user);
    } else if (widget.userId != null) {
      _loadingUser = true;
      _loadUser();
    } else {
      final assignable = auth.role?.assignableRoles ?? const <UserRole>[];
      final preset = widget.preset;
      _role = preset?.role != null && assignable.contains(preset!.role)
          ? preset.role
          : assignable.contains(UserRole.professor)
          ? UserRole.professor
          : (assignable.isEmpty ? null : assignable.last);
      _institutionId = preset?.institutionId;
    }
    if (auth.role?.isGeneralAdmin ?? false) {
      _loadingInstitutions = true;
      _loadInstitutions();
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _cpf,
      _email,
      _birthDate,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fill(AppUser user) {
    _user = user;
    _name.text = user.name;
    _cpf.text = formatCpf(user.cpf);
    _email.text = user.email;
    final birthDate = user.birthDate;
    _birthDate.text = birthDate == null ? '' : formatBrDate(birthDate);
    _role = user.role;
    _institutionId = user.institutionId;
  }

  void _retryLoadUser() {
    setState(() {
      _loadingUser = true;
      _loadError = null;
    });
    _loadUser();
  }

  /// Chamado no initState (sem setState antes do primeiro await).
  Future<void> _loadUser() async {
    final id = widget.userId;
    if (id == null) return;
    try {
      final user = await context.read<AuthRepository>().getUser(id);
      if (!mounted) return;
      setState(() => _fill(user));
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadInstitutions() async {
    try {
      final institutions = await context
          .read<AuthRepository>()
          .listInstitutions();
      if (!mounted) return;
      setState(() => _institutions = institutions);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _saveError = error.message);
    } finally {
      if (mounted) setState(() => _loadingInstitutions = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saveError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthRepository>();
    final isGeneralAdmin = auth.role?.isGeneralAdmin ?? false;
    final current = _user;
    final payload = UserPayload(
      name: _name.text,
      cpf: _cpf.text,
      email: _email.text,
      password: _password.text,
      birthDate: parseBrDate(_birthDate.text),
      // Ninguém altera a própria role: omitir mantém a atual.
      roleName: widget.editingSelf ? null : _role?.apiName,
      // Só o administrador geral escolhe ou transfere a instituição.
      institutionId: isGeneralAdmin ? _institutionId : null,
    );

    setState(() => _saving = true);
    try {
      if (current == null) {
        await auth.createUser(payload);
      } else {
        await auth.updateUser(current.id, payload);
      }
      if (!mounted) return;
      showAppMessage(
        context,
        current == null
            ? 'Usuário ${payload.name.trim()} cadastrado.'
            : widget.editingSelf
            ? 'Perfil atualizado.'
            : 'Usuário ${payload.name.trim()} atualizado.',
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
    final title = widget.editingSelf
        ? 'Editar perfil'
        : _editing
        ? 'Editar usuário'
        : 'Novo usuário';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: _loadingUser
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AppErrorBanner(_loadError!, onRetry: _retryLoadUser),
                  ],
                ),
              )
            : _buildForm(context, context.watch<AuthRepository>().role),
      ),
    );
  }

  Widget _buildForm(BuildContext context, UserRole? myRole) {
    final isGeneralAdmin = myRole?.isGeneralAdmin ?? false;
    final assignable = myRole?.assignableRoles ?? const <UserRole>[];
    final currentRole = _role;
    final roleOptions = [
      ...assignable,
      if (currentRole != null && !assignable.contains(currentRole)) currentRole,
    ];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
        children: [
          Text(
            widget.editingSelf
                ? 'Atualize os seus dados de acesso.'
                : _editing
                ? 'Atualize os dados de acesso do usuário.'
                : 'Cadastre o acesso de um novo usuário. Ele entra com o '
                      'e-mail e a senha definidos aqui.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          AppTextField(
            label: 'Nome completo',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            controller: _name,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'CPF',
            hint: '000.000.000-00',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            controller: _cpf,
            inputFormatters: [DigitMaskInputFormatter('###.###.###-##')],
            validator: (value) =>
                isValidCpf(value ?? '') ? null : 'Informe um CPF válido',
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'E-mail institucional',
            hint: 'seunome@escola.edu.br',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            controller: _email,
            helperText: widget.editingSelf
                ? 'Se trocar o e-mail, ele passa a ser o seu login.'
                : null,
            validator: (value) => _emailPattern.hasMatch(value?.trim() ?? '')
                ? null
                : 'Informe um e-mail válido',
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Data de nascimento (opcional)',
            hint: 'dd/mm/aaaa',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            controller: _birthDate,
            inputFormatters: [DigitMaskInputFormatter('##/##/####')],
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final date = parseBrDate(value);
              if (date == null) return 'Use o formato dd/mm/aaaa';
              if (date.isAfter(DateTime.now())) return 'Data no futuro';
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<UserRole>(
            key: ValueKey('role-$currentRole'),
            initialValue: currentRole,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Perfil de acesso',
              prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
              helperText: widget.editingSelf
                  ? 'Ninguém altera o próprio perfil de acesso.'
                  : null,
            ),
            items: [
              for (final role in roleOptions)
                DropdownMenuItem(value: role, child: Text(role.label)),
            ],
            onChanged: widget.editingSelf || _saving
                ? null
                : (role) => setState(() => _role = role),
            validator: (role) => !widget.editingSelf && role == null
                ? 'Selecione o perfil'
                : null,
          ),
          if (isGeneralAdmin) ...[
            const SizedBox(height: 14),
            _buildInstitutionField(),
          ],
          const SizedBox(height: 14),
          AppTextField(
            label: _editing ? 'Senha (nova ou atual)' : 'Senha',
            icon: Icons.lock_outline_rounded,
            controller: _password,
            obscureText: _obscurePassword,
            helperText: _editing
                ? 'O serviço de autenticação sempre substitui a senha ao '
                      'salvar. Para mantê-la, digite a senha atual.'
                : null,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (value) =>
                (value?.isEmpty ?? true) ? 'Informe a senha' : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Confirmar senha',
            icon: Icons.lock_outline_rounded,
            controller: _confirmPassword,
            obscureText: _obscurePassword,
            onFieldSubmitted: (_) => _save(),
            validator: (value) =>
                value == _password.text ? null : 'As senhas não conferem',
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 16),
            AppErrorBanner(_saveError!),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: _editing ? 'Salvar alterações' : 'Cadastrar usuário',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionField() {
    if (_loadingInstitutions) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Instituição',
          prefixIcon: Icon(Icons.school_outlined, size: 20),
        ),
        child: LinearProgressIndicator(),
      );
    }

    // Só instituições ativas recebem usuários; a atual aparece mesmo inativa.
    final options = _institutions
        .where(
          (institution) =>
              institution.active || institution.id == _user?.institutionId,
        )
        .toList();
    final selected = options.any((item) => item.id == _institutionId)
        ? _institutionId
        : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('institution-$selected-${options.length}'),
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Instituição',
        prefixIcon: Icon(Icons.school_outlined, size: 20),
      ),
      items: [
        for (final institution in options)
          DropdownMenuItem(
            value: institution.id,
            child: Text(
              institution.active
                  ? institution.name
                  : '${institution.name} (inativa)',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: _saving ? null : (id) => setState(() => _institutionId = id),
      validator: (id) => id == null ? 'Selecione a instituição' : null,
    );
  }
}
