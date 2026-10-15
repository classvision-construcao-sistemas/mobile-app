import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/facial_recognition_models.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/mock_school_repository.dart';

class AttendanceReviewArgs {
  const AttendanceReviewArgs({required this.classId, this.auditResult});

  final String classId;
  final RoomAuditResult? auditResult;
}

class AttendanceReviewPage extends StatelessWidget {
  const AttendanceReviewPage({super.key, this.classId, this.auditResult});

  final String? classId;
  final RoomAuditResult? auditResult;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<MockSchoolRepository>();
    final classroom = repository.classById(classId);
    final present = classroom.students
        .where((student) => student.status == AttendanceStatus.present)
        .length;
    final review = classroom.students
        .where((student) => student.status == AttendanceStatus.review)
        .length;
    final absent = classroom.students
        .where((student) => student.status == AttendanceStatus.absent)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Conferir chamada')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
            child: Column(
              children: [
                if (auditResult case final audit?) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.face_retouching_natural_rounded,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${audit.totalFacesDetected} rosto(s) detectado(s) • '
                            '${audit.recognizedStudents.length} reconhecido(s) • '
                            '${audit.unrecognizedCount} não reconhecido(s)',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Revise os resultados antes de confirmar. Toque no status para corrigir.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Summary(
                      value: present,
                      label: 'Presentes',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _Summary(
                      value: review,
                      label: 'Revisar',
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    _Summary(
                      value: absent,
                      label: 'Ausentes',
                      color: const Color(0xFFC72933),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              itemCount: classroom.students.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final student = classroom.students[index];
                return _StudentReview(
                  student: student,
                  onStatusChanged: (status) => repository.updateStudentStatus(
                    classroom.id,
                    student.id,
                    status,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Confirmar chamada',
                    onPressed: () {
                      repository.completeAttendance(classroom.id);
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.saved,
                        arguments: classroom.id,
                      );
                    },
                  ),
                  const SizedBox(height: 9),
                  PrimaryButton(
                    label: 'Tirar nova foto',
                    outlined: true,
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.camera,
                      arguments: classroom.id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.value,
    required this.label,
    required this.color,
  });
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StudentReview extends StatelessWidget {
  const _StudentReview({required this.student, required this.onStatusChanged});
  final Student student;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (student.status) {
      AttendanceStatus.present => ('Presente', AppColors.success),
      AttendanceStatus.review => ('Revisar', AppColors.warning),
      AttendanceStatus.absent => ('Ausente', const Color(0xFFC72933)),
    };
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Text(
              student.initials,
              style: const TextStyle(color: AppColors.primary, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  student.confidence == 0
                      ? 'Não detectado'
                      : '${(student.confidence * 100).round()}% de confiança',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<AttendanceStatus>(
            onSelected: onStatusChanged,
            itemBuilder: (_) => AttendanceStatus.values
                .map(
                  (status) => PopupMenuItem(
                    value: status,
                    child: Text(switch (status) {
                      AttendanceStatus.present => 'Presente',
                      AttendanceStatus.review => 'Revisar',
                      AttendanceStatus.absent => 'Ausente',
                    }),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.expand_more_rounded, color: color, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
