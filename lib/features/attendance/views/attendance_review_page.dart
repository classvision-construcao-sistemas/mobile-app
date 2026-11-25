import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/facial_recognition_models.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';
import '../../../data/services/auditoria_api.dart';

/// Confirma a chamada. Em turmas registradas no auditoria-service a gravação
/// é remota: mostra um indicador e mantém a tela aberta se falhar.
Future<void> confirmAttendance(
  BuildContext context,
  SchoolRepository repository,
  String classId,
) async {
  final navigator = Navigator.of(context);
  final remote = repository.recordsAuditFor(classId);
  if (remote) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
  try {
    await repository.completeAttendance(classId);
    if (remote) navigator.pop();
    navigator.pushReplacementNamed(AppRoutes.saved, arguments: classId);
  } on AuditoriaApiException catch (error) {
    if (remote) navigator.pop();
    if (context.mounted) {
      showAppMessage(
        context,
        'A chamada não foi salva: ${error.message}',
        error: true,
      );
    }
  }
}

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
    final repository = context.watch<SchoolRepository>();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _DesktopAttendanceReview(
            classroom: classroom,
            present: present,
            review: review,
            repository: repository,
          );
        }

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
                                  fontSize: 12,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  itemCount: classroom.students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final student = classroom.students[index];
                    return _StudentReview(
                      student: student,
                      onStatusChanged: (status) =>
                          repository.updateStudentStatus(
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
                        onPressed: () => confirmAttendance(
                          context,
                          repository,
                          classroom.id,
                        ),
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
      },
    );
  }
}

class _DesktopAttendanceReview extends StatelessWidget {
  const _DesktopAttendanceReview({
    required this.classroom,
    required this.present,
    required this.review,
    required this.repository,
  });

  final SchoolClass classroom;
  final int present;
  final int review;
  final SchoolRepository repository;

  void _confirm(BuildContext context) =>
      confirmAttendance(context, repository, classroom.id);

  String get _initials {
    final initials = classroom.name
        .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ ]'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return initials.isEmpty ? 'T' : initials;
  }

  /// Confiança média dos alunos reconhecidos pela IA.
  String get _averageConfidence {
    final scores = [
      for (final student in classroom.students)
        if (student.confidence > 0) student.confidence,
    ];
    if (scores.isEmpty) return '—';
    final average = scores.reduce((a, b) => a + b) / scores.length;
    return '${(average * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final subtitle = [
      formatBrDateTime(now),
      if (classroom.room.isNotEmpty) classroom.room,
    ].join(' · ');
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
        children: [
          Text(
            'Chamadas / ${classroom.name} / ${formatBrDate(now)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revisar chamada',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Ajuste presenças individuais antes de confirmar em nome do professor.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _confirm(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Confirmar chamada'),
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
                  foregroundColor: AppColors.primary,
                  child: Text(
                    _initials,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.courseName.isEmpty
                            ? classroom.name
                            : '${classroom.name} · ${classroom.courseName}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        'Reconhecimento facial SCRFD + TopoFR',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _DesktopSummary(
                  label: 'PRESENÇA DETECTADA',
                  value: '$present / ${classroom.students.length}',
                ),
                const SizedBox(width: 34),
                _DesktopSummary(
                  label: 'CONFIANÇA MÉDIA',
                  value: _averageConfidence,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lista de presença',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Edite os estados divergentes. As alterações serão registradas no histórico.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (review > 0) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$review alunos precisam de revisão manual por baixa confiança.',
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      for (final student in classroom.students) ...[
                        _StudentReview(
                          student: student,
                          onStatusChanged: (status) =>
                              repository.updateStudentStatus(
                                classroom.id,
                                student.id,
                                status,
                              ),
                        ),
                        const SizedBox(height: 9),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Auditoria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'CAPTURA',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(formatBrDateTime(now)),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _confirm(context),
                          child: const Text('Confirmar chamada'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Voltar e trocar a foto'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopSummary extends StatelessWidget {
  const _DesktopSummary({required this.label, required this.value});
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
              fontSize: 12,
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
              style: const TextStyle(color: AppColors.primary, fontSize: 12),
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
                    fontSize: 12,
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
                      fontSize: 12,
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
