import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';
import '../../../data/services/turma_api.dart';
import '../../history/views/history_page.dart';

class ClassDetailsPage extends StatelessWidget {
  const ClassDetailsPage({super.key, required this.classId});

  final String? classId;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository>();
    final classroom = repository.findClassById(classId);
    if (classroom == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: repository.loading
                ? const CircularProgressIndicator()
                : const Text(
                    'Turma não encontrada. Ela pode ter sido excluída.',
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      );
    }
    final actions = _ClassActions(context, repository, classroom);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            body: _DesktopClassDetails(classroom: classroom, actions: actions),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(classroom.name),
            actions: [
              if (actions.canEdit)
                IconButton(
                  tooltip: 'Editar turma',
                  onPressed: actions.edit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (actions.canEdit)
                IconButton(
                  tooltip: 'Excluir turma',
                  onPressed: actions.delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: actions.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              children: [
                if (classroom.courseName.isNotEmpty) ...[
                  Text(
                    classroom.courseName,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                ],
                AppCard(
                  child: Row(
                    children: [
                      _Info(
                        icon: Icons.schedule_rounded,
                        label: 'Turno',
                        value: _orDash(classroom.time),
                      ),
                      const _Divider(),
                      _Info(
                        icon: Icons.meeting_room_outlined,
                        label: 'Sala',
                        value: _orDash(classroom.room),
                      ),
                      const _Divider(),
                      _Info(
                        icon: Icons.groups_2_outlined,
                        label: 'Alunos',
                        value: '${classroom.students.length}',
                      ),
                    ],
                  ),
                ),
                if (classroom.isRemote) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Ano letivo ${classroom.remote!.year} · '
                            '${_period(classroom)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Alunos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: actions.addStudent,
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 18,
                      ),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (classroom.students.isEmpty)
                  const AppCard(
                    child: Center(
                      child: Text('Nenhum aluno vinculado a esta turma.'),
                    ),
                  )
                else
                  for (final student in classroom.students) ...[
                    _StudentRow(
                      student: student,
                      onRemove: actions.canUnenroll(student)
                          ? () => actions.unenroll(student)
                          : null,
                    ),
                    const SizedBox(height: 9),
                  ],
                const SizedBox(height: 18),
                if (classroom.attendanceCompleted)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Chamada realizada hoje',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                else
                  PrimaryButton(
                    label: 'Fazer chamada com IA',
                    icon: Icons.camera_alt_rounded,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.camera,
                      arguments: classroom.id,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _orDash(String value) => value.trim().isEmpty ? '—' : value;

String _period(SchoolClass classroom) {
  final start = classroom.remote?.startDate;
  final end = classroom.remote?.endDate;
  if (start == null && end == null) return 'Período não informado';
  if (start == null) return 'Até ${formatBrDate(end!)}';
  if (end == null) return 'Desde ${formatBrDate(start)}';
  return '${formatBrDate(start)} a ${formatBrDate(end)}';
}

/// Ações sobre a turma, conforme as permissões do perfil no turma-service.
class _ClassActions {
  _ClassActions(this.context, this.repository, this.classroom);

  final BuildContext context;
  final SchoolRepository repository;
  final SchoolClass classroom;

  bool get canEdit => classroom.isRemote && repository.canManageClasses;

  bool canUnenroll(Student student) =>
      student.enrollmentStatus == null || repository.canManageEnrollments;

  Future<void> refresh() async {
    if (!classroom.isRemote) return;
    try {
      await repository.refreshClass(classroom.id);
    } on TurmaApiException catch (error) {
      if (context.mounted) showAppMessage(context, error.message, error: true);
    }
  }

  void edit() => Navigator.pushNamed(
    context,
    AppRoutes.classRegistration,
    arguments: classroom.id,
  );

  void addStudent() => Navigator.pushNamed(
    context,
    AppRoutes.studentRegistration,
    arguments: classroom.id,
  );

  Future<void> delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir turma',
      message:
          'A turma ${classroom.name} e os vínculos dos alunos serão '
          'excluídos definitivamente.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context);
    try {
      await repository.deleteClass(classroom.id);
      if (!context.mounted) return;
      showAppMessage(context, 'Turma ${classroom.name} excluída.');
      navigator.pop();
    } on TurmaApiException catch (error) {
      if (context.mounted) showAppMessage(context, error.message, error: true);
    }
  }

  Future<void> unenroll(Student student) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remover aluno',
      message: '${student.name} deixará de fazer parte da turma.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await repository.unenrollStudent(classroom.id, student);
      if (context.mounted) {
        showAppMessage(context, '${student.name} removido da turma.');
      }
    } on TurmaApiException catch (error) {
      if (context.mounted) showAppMessage(context, error.message, error: true);
    }
  }
}

class _DesktopClassDetails extends StatelessWidget {
  const _DesktopClassDetails({required this.classroom, required this.actions});
  final SchoolClass classroom;
  final _ClassActions actions;

  @override
  Widget build(BuildContext context) {
    final remote = classroom.remote;
    final initials = classroom.name.trim().isEmpty
        ? 'T'
        : classroom.name
              .trim()
              .substring(0, classroom.name.trim().length.clamp(1, 2))
              .toUpperCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 6),
            const Text(
              'Turmas  /  Detalhes da turma',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_orDash(classroom.room)} · Turno ${classroom.time.toLowerCase()}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: actions.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            if (actions.canEdit) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: actions.delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Excluir'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: actions.edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar turma'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.primarySoft,
                child: Text(initials),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.courseName.isEmpty
                          ? 'Curso não informado'
                          : classroom.courseName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _period(classroom),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _Summary(
                label: 'ALUNOS VINCULADOS',
                value: '${classroom.students.length}',
              ),
              const SizedBox(width: 30),
              _Summary(
                label: 'ANO LETIVO',
                value: remote == null || remote.year == 0
                    ? '—'
                    : '${remote.year}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dados da turma',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _Field(
                                label: 'Curso',
                                value: classroom.course == null
                                    ? '—'
                                    : classroom.course!.code,
                              ),
                            ),
                            Expanded(
                              child: _Field(
                                label: 'Sala',
                                value: _orDash(classroom.room),
                              ),
                            ),
                            Expanded(
                              child: _Field(
                                label: 'Turno',
                                value: _orDash(classroom.time),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alunos da turma',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (classroom.students.isEmpty)
                          const Text(
                            'Nenhum aluno vinculado a esta turma.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        for (final student in classroom.students)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(student.initials),
                            ),
                            title: Text(student.name),
                            subtitle: Text('Matrícula ${student.registration}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (student.enrollmentStatus != null)
                                  AppStatusChip(
                                    label: _statusLabel(
                                      student.enrollmentStatus!,
                                    ),
                                  ),
                                if (actions.canUnenroll(student))
                                  IconButton(
                                    tooltip: 'Remover da turma',
                                    onPressed: () => actions.unenroll(student),
                                    icon: const Icon(
                                      Icons.person_remove_outlined,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ações rápidas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_add_alt_1_rounded),
                      title: const Text('Adicionar aluno'),
                      onTap: actions.addStudent,
                    ),
                    if (!classroom.attendanceCompleted)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.camera_alt_outlined),
                        title: const Text('Fazer chamada com IA'),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.camera,
                          arguments: classroom.id,
                        ),
                      ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.fact_check_outlined),
                      title: const Text('Ver últimas chamadas'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: Text(classroom.name)),
                            body: HistoryPage(classId: classroom.id),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `MATRICULADO` → `Matriculado`.
String _statusLabel(String status) {
  final text = status.trim().replaceAll('_', ' ').toLowerCase();
  return text.isEmpty ? status : '${text[0].toUpperCase()}${text.substring(1)}';
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: AppColors.border);
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, this.onRemove});
  final Student student;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Text(
            student.initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                student.enrollmentStatus == null
                    ? 'Matrícula ${student.registration}'
                    : 'Matrícula ${student.registration} · '
                          '${_statusLabel(student.enrollmentStatus!)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'Remover da turma',
            onPressed: onRemove,
            icon: const Icon(
              Icons.person_remove_outlined,
              color: AppColors.navInactive,
            ),
          ),
      ],
    ),
  );
}
