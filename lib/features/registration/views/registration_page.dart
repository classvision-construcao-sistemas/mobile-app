import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/mock_school_repository.dart';

enum RegistrationType { user, classroom, student }

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({
    super.key,
    required this.type,
    this.classId,
    this.editing = false,
  });

  final RegistrationType type;
  final String? classId;
  final bool editing;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.type != RegistrationType.user || !widget.editing) {
        return;
      }
      final profile = context.read<MockSchoolRepository>().profile;
      _controllers[0].text = profile.name;
      _controllers[1].text = profile.email;
      _controllers[2].text = profile.school;
      _controllers[3].text = profile.phone;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _title => switch (widget.type) {
    RegistrationType.user =>
      widget.editing ? 'Editar perfil' : 'Cadastro de usuário',
    RegistrationType.classroom => 'Nova turma',
    RegistrationType.student => 'Novo aluno',
  };

  List<(String, IconData, TextInputType)> get _fields => switch (widget.type) {
    RegistrationType.user => [
      ('Nome completo', Icons.person_outline_rounded, TextInputType.name),
      (
        'E-mail institucional',
        Icons.mail_outline_rounded,
        TextInputType.emailAddress,
      ),
      ('Instituição', Icons.school_outlined, TextInputType.text),
      ('Telefone', Icons.phone_outlined, TextInputType.phone),
    ],
    RegistrationType.classroom => [
      ('Nome da turma', Icons.groups_2_outlined, TextInputType.text),
      ('Sala', Icons.meeting_room_outlined, TextInputType.text),
      ('Horário', Icons.schedule_rounded, TextInputType.datetime),
    ],
    RegistrationType.student => [
      ('Nome do aluno', Icons.person_outline_rounded, TextInputType.name),
      ('Matrícula', Icons.badge_outlined, TextInputType.number),
      (
        'Nome do responsável',
        Icons.supervisor_account_outlined,
        TextInputType.name,
      ),
      ('Telefone do responsável', Icons.phone_outlined, TextInputType.phone),
    ],
  };

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }
    final repository = context.read<MockSchoolRepository>();
    switch (widget.type) {
      case RegistrationType.user:
        repository.updateProfile(
          CoordinatorProfile(
            name: _controllers[0].text,
            email: _controllers[1].text,
            school: _controllers[2].text,
            phone: _controllers[3].text,
          ),
        );
      case RegistrationType.classroom:
        repository.addClass(
          name: _controllers[0].text,
          room: _controllers[1].text,
          time: _controllers[2].text,
        );
      case RegistrationType.student:
        repository.addStudent(
          widget.classId ?? repository.classes.first.id,
          Student(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: _controllers[0].text,
            registration: _controllers[1].text,
            guardian: _controllers[2].text,
            phone: _controllers[3].text,
          ),
        );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          children: [
            Text(switch (widget.type) {
              RegistrationType.user =>
                'Preencha seus dados de acesso e contato.',
              RegistrationType.classroom =>
                'Cadastre os dados básicos da nova turma.',
              RegistrationType.student =>
                'Cadastre o aluno e o contato do responsável.',
            }, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 22),
            for (var index = 0; index < _fields.length; index++) ...[
              AppTextField(
                label: _fields[index].$1,
                icon: _fields[index].$2,
                keyboardType: _fields[index].$3,
                controller: _controllers[index],
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Preencha este campo'
                    : null,
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Salvar cadastro',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
  );
}
