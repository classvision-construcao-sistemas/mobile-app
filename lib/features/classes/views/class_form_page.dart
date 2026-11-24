import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/turma_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/school_repository.dart';
import '../../../data/services/turma_api.dart';

/// Cadastro e edição de turmas no turma-service.
///
/// Sem [classId], cadastra uma nova turma. Com [classId], edita a turma
/// carregada no [SchoolRepository].
class ClassFormPage extends StatefulWidget {
  const ClassFormPage({super.key, this.classId});

  final String? classId;

  @override
  State<ClassFormPage> createState() => _ClassFormPageState();
}

class _ClassFormPageState extends State<ClassFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _room = TextEditingController();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();

  CourseClass? _editing;
  ClassShift? _shift;
  String? _unknownShift;
  int? _courseId;

  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final repository = context.read<SchoolRepository>();
    final remote = repository.findClassById(widget.classId)?.remote;
    if (remote != null) _fill(remote);
    if (repository.courses.isEmpty && !repository.loading) {
      repository.loadClasses();
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _year, _room, _startDate, _endDate]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fill(CourseClass remote) {
    _editing = remote;
    _name.text = remote.name;
    _year.text = remote.year == 0 ? '' : '${remote.year}';
    _room.text = remote.room;
    _shift = ClassShift.fromApi(remote.shift);
    // Turno fora da lista conhecida: mantém o valor salvo na API.
    if (_shift == null && remote.shift.isNotEmpty) _unknownShift = remote.shift;
    _courseId = remote.courseId;
    final start = remote.startDate;
    final end = remote.endDate;
    _startDate.text = start == null ? '' : formatBrDate(start);
    _endDate.text = end == null ? '' : formatBrDate(end);
  }

  String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return parseBrDate(value) == null ? 'Use o formato dd/mm/aaaa' : null;
  }

  Future<void> _save() async {
    setState(() => _saveError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final repository = context.read<SchoolRepository>();
    final payload = ClassPayload(
      year: int.parse(_year.text.trim()),
      name: _name.text,
      shift: _shift?.apiName ?? _unknownShift!,
      room: _room.text,
      startDate: parseBrDate(_startDate.text),
      endDate: parseBrDate(_endDate.text),
      courseId: _courseId!,
    );

    setState(() => _saving = true);
    try {
      final editingId = widget.classId;
      if (_editing == null || editingId == null) {
        await repository.createClass(payload);
      } else {
        await repository.updateClass(editingId, payload);
      }
      if (!mounted) return;
      showAppMessage(
        context,
        _editing == null
            ? 'Turma ${payload.name.trim()} cadastrada.'
            : 'Turma ${payload.name.trim()} atualizada.',
      );
      Navigator.pop(context);
    } on TurmaApiException catch (error) {
      if (!mounted) return;
      setState(() => _saveError = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createCourse() async {
    final course = await showDialog<Course>(
      context: context,
      builder: (_) => const _CourseDialog(),
    );
    if (course == null || !mounted) return;
    setState(() => _courseId = course.id);
    showAppMessage(context, 'Curso ${course.name} cadastrado.');
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository>();
    final editing = _editing != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar turma' : 'Nova turma')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            children: [
              Text(
                editing
                    ? 'Atualize os dados da turma.'
                    : 'Cadastre a turma em um curso da sua instituição.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              _buildCourseField(repository),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Nome da turma',
                hint: 'ADS - 1º Período A',
                icon: Icons.groups_2_outlined,
                controller: _name,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Informe o nome da turma';
                  if (text.length > 255) return 'Use até 255 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Ano letivo',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      controller: _year,
                      inputFormatters: [DigitMaskInputFormatter('####')],
                      validator: (value) {
                        final year = int.tryParse(value?.trim() ?? '');
                        return year == null || year < 1900 || year > 9999
                            ? 'Ano inválido'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShiftField()),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Sala (opcional)',
                hint: 'Bloco B - Sala 12',
                icon: Icons.meeting_room_outlined,
                controller: _room,
                validator: (value) => (value?.trim().length ?? 0) > 50
                    ? 'Use até 50 caracteres'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Início das aulas',
                      hint: 'dd/mm/aaaa',
                      icon: Icons.event_outlined,
                      keyboardType: TextInputType.number,
                      controller: _startDate,
                      inputFormatters: [DigitMaskInputFormatter('##/##/####')],
                      validator: _validateDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Fim das aulas',
                      hint: 'dd/mm/aaaa',
                      icon: Icons.event_available_outlined,
                      keyboardType: TextInputType.number,
                      controller: _endDate,
                      inputFormatters: [DigitMaskInputFormatter('##/##/####')],
                      validator: (value) {
                        final error = _validateDate(value);
                        if (error != null) return error;
                        final start = parseBrDate(_startDate.text);
                        final end = parseBrDate(value);
                        if (start != null &&
                            end != null &&
                            end.isBefore(start)) {
                          return 'Antes do início';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 16),
                AppErrorBanner(_saveError!),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: editing ? 'Salvar alterações' : 'Cadastrar turma',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftField() {
    final unknown = _unknownShift;
    return DropdownButtonFormField<String>(
      initialValue: _shift?.apiName ?? unknown,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Turno',
        prefixIcon: Icon(Icons.schedule_rounded, size: 20),
      ),
      items: [
        for (final shift in ClassShift.values)
          DropdownMenuItem(value: shift.apiName, child: Text(shift.label)),
        if (unknown != null)
          DropdownMenuItem(value: unknown, child: Text(unknown)),
      ],
      onChanged: _saving
          ? null
          : (value) => setState(() {
              _shift = ClassShift.fromApi(value);
              _unknownShift = _shift == null ? value : null;
            }),
      validator: (value) => value == null ? 'Selecione o turno' : null,
    );
  }

  Widget _buildCourseField(SchoolRepository repository) {
    if (repository.loading && repository.courses.isEmpty) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Curso',
          prefixIcon: Icon(Icons.school_outlined, size: 20),
        ),
        child: LinearProgressIndicator(),
      );
    }

    // Só cursos ativos recebem turmas; o atual aparece mesmo inativo.
    final options = repository.courses
        .where((course) => course.active || course.id == _editing?.courseId)
        .toList();
    final selected = options.any((item) => item.id == _courseId)
        ? _courseId
        : null;
    final canCreate =
        context.read<AuthRepository>().session?.institutionId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('course-$selected-${options.length}'),
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Curso',
            prefixIcon: const Icon(Icons.school_outlined, size: 20),
            helperText: options.isEmpty
                ? 'Nenhum curso ativo. Cadastre um curso para continuar.'
                : editing
                ? 'A turma só pode mudar para um curso da mesma instituição.'
                : null,
            helperMaxLines: 2,
          ),
          items: [
            for (final course in options)
              DropdownMenuItem(
                value: course.id,
                child: Text(
                  course.active
                      ? '${course.code} · ${course.name}'
                      : '${course.code} · ${course.name} (inativo)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _saving ? null : (id) => setState(() => _courseId = id),
          validator: (id) => id == null ? 'Selecione o curso' : null,
        ),
        if (canCreate)
          TextButton.icon(
            onPressed: _saving ? null : _createCourse,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Novo curso'),
          ),
      ],
    );
  }

  bool get editing => _editing != null;
}

/// Cadastro rápido de curso na instituição do usuário logado.
class _CourseDialog extends StatefulWidget {
  const _CourseDialog();

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final institutionId = context.read<AuthRepository>().session?.institutionId;
    if (institutionId == null) {
      setState(() => _error = 'Instituição não identificada na sessão.');
      return;
    }
    setState(() => _saving = true);
    try {
      final course = await context.read<SchoolRepository>().createCourse(
        CoursePayload(
          code: _code.text,
          name: _name.text,
          institutionId: institutionId,
        ),
      );
      if (mounted) Navigator.pop(context, course);
    } on TurmaApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Novo curso'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Código',
              hint: 'ADS-2027',
              icon: Icons.tag_rounded,
              controller: _code,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Informe o código';
                if (text.length > 50) return 'Use até 50 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Nome do curso',
              icon: Icons.school_outlined,
              controller: _name,
              onFieldSubmitted: (_) => _save(),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? 'Informe o nome' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AppErrorBanner(_error!),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Salvando...' : 'Cadastrar'),
      ),
    ],
  );
}
