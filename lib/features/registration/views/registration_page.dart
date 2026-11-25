import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/photo.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';
import '../../../data/services/facial_recognition_api.dart';
import '../../../data/services/turma_api.dart';
import '../../camera/views/camera_page.dart';

/// Cadastro de aluno com biometria facial.
///
/// Com [classId] de uma turma do turma-service, o aluno também é vinculado à
/// turma na API (a matrícula numérica é o `alunoId`). O cadastro de turmas fica
/// em `ClassFormPage`.
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, this.classId});

  final String? classId;

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
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  static const _fields = <(String, IconData, TextInputType)>[
    ('Nome do aluno', Icons.person_outline_rounded, TextInputType.name),
    ('Matrícula', Icons.badge_outlined, TextInputType.number),
    (
      'Nome do responsável',
      Icons.supervisor_account_outlined,
      TextInputType.name,
    ),
    ('Telefone do responsável', Icons.phone_outlined, TextInputType.phone),
  ];

  /// Se o aluno também será vinculado à turma no turma-service.
  bool _linksToRemoteClass(SchoolRepository repository) =>
      repository.canManageEnrollments &&
      (repository.findClassById(widget.classId)?.isRemote ?? false);

  String? _validate(int index, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Preencha este campo';
    if (index == 3 && !isValidPhone(text)) return 'Informe DDD + número';
    if (index == 1 &&
        _linksToRemoteClass(context.read<SchoolRepository>()) &&
        (int.tryParse(text) ?? 0) <= 0) {
      return 'Use apenas números para vincular à turma';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_faceImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tire uma foto ou selecione uma imagem do aluno.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final repository = context.read<SchoolRepository>();
    try {
      final registration = _controllers[1].text.trim();
      var alreadyEnrolled = false;
      try {
        await context.read<FacialRecognitionApi>().enrollStudent(
          studentId: registration,
          imagePath: _faceImagePath!,
          name: _controllers[0].text,
          guardian: _controllers[2].text,
          phone: _controllers[3].text,
        );
      } on FacialRecognitionException catch (error) {
        // A matrícula já tem biometria (ex.: aluno de outra turma): basta
        // vinculá-lo a esta turma.
        if (error.statusCode != 409 || widget.classId == null) rethrow;
        alreadyEnrolled = true;
      }
      if (!mounted) return;
      final classId = widget.classId;
      if (classId != null && repository.findClassById(classId) != null) {
        await repository.enrollStudent(
          classId,
          Student(
            id: registration,
            name: _controllers[0].text.trim(),
            registration: registration,
            guardian: _controllers[2].text.trim(),
            phone: _controllers[3].text.trim(),
          ),
        );
      }
      if (!mounted) return;
      if (alreadyEnrolled) {
        showAppMessage(
          context,
          'A matrícula $registration já tinha biometria cadastrada; '
          'o aluno foi vinculado à turma.',
        );
      }
      Navigator.pop(context);
    } on TurmaApiException catch (error) {
      // A biometria já foi salva; só o vínculo com a turma falhou.
      if (!mounted) return;
      showAppMessage(
        context,
        'Biometria salva, mas o aluno não foi vinculado à turma: '
        '${error.message}',
        error: true,
      );
      setState(() => _saving = false);
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

  Future<void> _pickFaceFromGallery() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (image != null && mounted) {
      setState(() => _faceImagePath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo aluno')),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          children: [
            Text(
              _linksToRemoteClass(context.watch<SchoolRepository>())
                  ? 'Cadastre o aluno, o responsável e a biometria facial. '
                        'A matrícula também vincula o aluno à turma.'
                  : 'Cadastre o aluno, o responsável e a biometria facial.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            for (var index = 0; index < _fields.length; index++) ...[
              AppTextField(
                label: _fields[index].$1,
                icon: _fields[index].$2,
                keyboardType: _fields[index].$3,
                controller: _controllers[index],
                inputFormatters: switch (index) {
                  // Matrícula: só números (é o alunoId da turma, um Long).
                  1 => [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  3 => [PhoneInputFormatter()],
                  _ => [LengthLimitingTextInputFormatter(150)],
                },
                validator: (value) => _validate(index, value),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 4),
            _FaceCaptureCard(
              imagePath: _faceImagePath,
              onCamera: _saving ? null : _captureFace,
              onGallery: _saving ? null : _pickFaceFromGallery,
            ),
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
  const _FaceCaptureCard({
    required this.imagePath,
    required this.onCamera,
    required this.onGallery,
  });

  final String? imagePath;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;

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
                : photoPreview(imagePath!),
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
                    ? 'Use a câmera ou escolha uma imagem da galeria.'
                    : 'Você pode trocar a imagem antes de salvar.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: Text(imagePath == null ? 'Câmera' : 'Refazer'),
                  ),
                  TextButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galeria'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
