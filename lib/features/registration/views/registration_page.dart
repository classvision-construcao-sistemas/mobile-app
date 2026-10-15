import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/mock_school_repository.dart';
import '../../../data/services/facial_recognition_api.dart';
import '../../camera/views/camera_page.dart';

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
  String? _faceImagePath;

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
    if (widget.type == RegistrationType.student && _faceImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tire a foto facial do aluno.')),
      );
      return;
    }

    setState(() => _saving = true);
    final repository = context.read<MockSchoolRepository>();
    try {
      switch (widget.type) {
        case RegistrationType.user:
          repository.updateProfile(
            CoordinatorProfile(
              name: _controllers[0].text.trim(),
              email: _controllers[1].text.trim(),
              school: _controllers[2].text.trim(),
              phone: _controllers[3].text.trim(),
            ),
          );
        case RegistrationType.classroom:
          repository.addClass(
            name: _controllers[0].text.trim(),
            room: _controllers[1].text.trim(),
            time: _controllers[2].text.trim(),
          );
        case RegistrationType.student:
          final registration = _controllers[1].text.trim();
          await context.read<FacialRecognitionApi>().enrollStudent(
            studentId: registration,
            imagePath: _faceImagePath!,
          );
          if (!mounted) return;
          repository.addStudent(
            widget.classId ?? repository.classes.first.id,
            Student(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: _controllers[0].text.trim(),
              registration: registration,
              guardian: _controllers[2].text.trim(),
              phone: _controllers[3].text.trim(),
            ),
          );
      }
      if (mounted) Navigator.pop(context);
    } on FacialRecognitionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o cadastro.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _captureFace() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const CameraPage(returnCapturedImage: true),
      ),
    );
    if (path != null && mounted) setState(() => _faceImagePath = path);
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
                'Cadastre o aluno, o responsável e a biometria facial.',
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
            if (widget.type == RegistrationType.student) ...[
              const SizedBox(height: 4),
              _FaceCaptureCard(
                imagePath: _faceImagePath,
                onPressed: _saving ? null : _captureFace,
              ),
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

class _FaceCaptureCard extends StatelessWidget {
  const _FaceCaptureCard({required this.imagePath, required this.onPressed});

  final String? imagePath;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 68,
            child: imagePath == null
                ? const ColoredBox(
                    color: Colors.white,
                    child: Icon(
                      Icons.face_retouching_natural_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  )
                : Image.file(File(imagePath!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                imagePath == null ? 'Biometria facial' : 'Foto facial pronta',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                imagePath == null
                    ? 'Obrigatória para reconhecer o aluno na chamada.'
                    : 'Você pode tirar outra foto antes de salvar.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                onPressed: onPressed,
                icon: Icon(
                  imagePath == null
                      ? Icons.camera_alt_rounded
                      : Icons.refresh_rounded,
                  size: 18,
                ),
                label: Text(imagePath == null ? 'Tirar foto' : 'Refazer foto'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
