import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';
import '../../../data/services/auditoria_api.dart';

/// Correção de uma chamada já confirmada (UC-HIS-02): troca a presença dos
/// alunos e exige uma justificativa, que fica registrada na auditoria.
class AttendanceCorrectionPage extends StatefulWidget {
  const AttendanceCorrectionPage({super.key, required this.record});

  final AttendanceRecord record;

  @override
  State<AttendanceCorrectionPage> createState() =>
      _AttendanceCorrectionPageState();
}

class _AttendanceCorrectionPageState extends State<AttendanceCorrectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _justification = TextEditingController();
  late final Map<String, bool> _presence = Map.of(widget.record.attendance);
  bool _saving = false;

  Map<String, bool> get _changes => {
    for (final entry in _presence.entries)
      if (widget.record.attendance[entry.key] != entry.value)
        entry.key: entry.value,
  };

  @override
  void dispose() {
    _justification.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_changes.isEmpty) {
      showAppMessage(context, 'Altere a presença de algum aluno.', error: true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<SchoolRepository>().correctAttendance(
        widget.record,
        changes: _changes,
        justification: _justification.text,
      );
      if (!mounted) return;
      showAppMessage(context, 'Chamada corrigida.');
      Navigator.pop(context, true);
    } on AuditoriaApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, error.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository>();
    final record = widget.record;
    final registrations = _presence.keys.toList()
      ..sort((a, b) {
        final nameA = repository.studentName(record.classId, a) ?? a;
        final nameB = repository.studentName(record.classId, b) ?? b;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });
    final present = _presence.values.where((value) => value).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Corrigir chamada')),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Text(
                  record.className,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatBrDateTime(record.date)} · '
                  '$present de ${_presence.length} presentes',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                if (registrations.isEmpty)
                  const Text('Esta chamada não tem alunos registrados.')
                else
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final registration in registrations)
                          SwitchListTile(
                            key: ValueKey('presence-$registration'),
                            title: Text(
                              repository.studentName(
                                    record.classId,
                                    registration,
                                  ) ??
                                  'Aluno $registration',
                            ),
                            subtitle: Text(
                              'Matrícula $registration · '
                              '${_presence[registration]! ? 'Presente' : 'Falta'}'
                              '${record.attendance[registration] != _presence[registration] ? ' (alterado)' : ''}',
                            ),
                            value: _presence[registration]!,
                            onChanged: _saving
                                ? null
                                : (value) => setState(
                                    () => _presence[registration] = value,
                                  ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _justification,
                  enabled: !_saving,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Justificativa',
                    hintText: 'Ex.: aluno chegou depois da foto da sala',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Informe a justificativa da correção'
                      : null,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar correção'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
