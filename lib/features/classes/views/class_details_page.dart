import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/mock_school_repository.dart';

class ClassDetailsPage extends StatelessWidget {
  const ClassDetailsPage({super.key, required this.classId});

  final String? classId;

  @override
  Widget build(BuildContext context) {
    final classroom = context.watch<MockSchoolRepository>().classById(classId);
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                  Icon(Icons.check_circle_rounded, color: AppColors.success),
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
  }
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
