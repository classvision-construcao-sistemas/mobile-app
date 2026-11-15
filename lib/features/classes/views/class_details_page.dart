import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';

class ClassDetailsPage extends StatelessWidget {
  const ClassDetailsPage({super.key, required this.classId});

  final String? classId;

  @override
  Widget build(BuildContext context) {
    final classroom = context.watch<SchoolRepository>().classById(classId);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(body: _DesktopClassDetails(classroom: classroom));
        }
        return Scaffold(
          appBar: AppBar(title: Text(classroom.name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              AppCard(
                child: Row(
                  children: [
                    _Info(
                      icon: Icons.schedule_rounded,
                      label: 'Horário',
                      value: classroom.time,
                    ),
                    const _Divider(),
                    _Info(
                      icon: Icons.meeting_room_outlined,
                      label: 'Sala',
                      value: classroom.room,
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
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.studentRegistration,
                      arguments: classroom.id,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (classroom.students.isEmpty)
                const AppCard(
                  child: Center(
                    child: Text('Nenhum aluno cadastrado nesta turma.'),
                  ),
                )
              else
                for (final student in classroom.students) ...[
                  _StudentRow(student: student),
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
        );
      },
    );
  }
}

class _DesktopClassDetails extends StatelessWidget {
  const _DesktopClassDetails({required this.classroom});
  final SchoolClass classroom;

  Future<void> _edit(BuildContext context) async {
    final name = TextEditingController(text: classroom.name);
    final room = TextEditingController(text: classroom.room);
    final time = TextEditingController(text: classroom.time);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar turma'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome da turma'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: room,
                decoration: const InputDecoration(labelText: 'Sala'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: time,
                decoration: const InputDecoration(labelText: 'Horário'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved != true || !context.mounted) return;
    context.read<SchoolRepository>().updateClass(
      id: classroom.id,
      name: name.text.trim(),
      room: room.text.trim(),
      time: time.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
    children: [
      const Text(
        'Turmas  /  Detalhes da turma',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
                  '${classroom.room} · Turno matutino',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar turma'),
          ),
        ],
      ),
      const SizedBox(height: 22),
      AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: AppColors.primarySoft,
              child: Text(classroom.name.substring(0, 2).toUpperCase()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informática integrado ao ensino médio',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classroom.time,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Text(
                    'Prof. Rafael Mendes · Matemática',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _Summary(
              label: 'ALUNOS MATRICULADOS',
              value: '${classroom.students.length}',
            ),
            const SizedBox(width: 30),
            const _Summary(label: 'PRESENÇA NO MÊS', value: '96,8%'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Row(
        children: [
          Text(
            'Visão geral',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 30),
          Text('Alunos'),
          SizedBox(width: 30),
          Text('Chamadas'),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dados da turma',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text('Curso\nInformática')),
                          Expanded(child: Text('Sala\n204')),
                          Expanded(child: Text('Turno\nMatutino')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Presença mensal',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Desempenho da turma em novembro',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 22),
                      LinearProgressIndicator(value: .968, minHeight: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alunos com atenção necessária',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final student in classroom.students)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text(student.initials)),
                          title: Text(student.name),
                          subtitle: Text('Matrícula ${student.registration}'),
                          trailing: const Text(
                            '81,5%',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w800,
                            ),
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
                  Text(
                    'Ações rápidas',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.person_add_alt_1_rounded),
                    title: Text('Adicionar aluno'),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.studentRegistration,
                      arguments: classroom.id,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.fact_check_outlined),
                    title: Text('Ver últimas chamadas'),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.home),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.download_outlined),
                    title: Text('Exportar lista de alunos'),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lista preparada para exportação.'),
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
          fontSize: 9,
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
  const _StudentRow({required this.student});
  final Student student;

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
                'Matrícula ${student.registration}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.navInactive),
      ],
    ),
  );
}
