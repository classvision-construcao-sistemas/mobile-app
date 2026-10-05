import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AttendanceReviewPage extends StatefulWidget {
  const AttendanceReviewPage({super.key});

  @override
  State<AttendanceReviewPage> createState() => _AttendanceReviewPageState();
}

class _AttendanceReviewPageState extends State<AttendanceReviewPage> {
  bool _isConfirmed = false;

  static const _students = [
    _Student('AB', 'Ana Beatriz', '98% de confiança', _Attendance.present),
    _Student('BM', 'Bruno Martins', '94% de confiança', _Attendance.present),
    _Student('CS', 'Carla Souza', '61% de confiança', _Attendance.review),
    _Student('DO', 'Daniel Oliveira', 'Não detectado', _Attendance.absent),
    _Student(
      'EL',
      'Eduarda Lima',
      'Rosto parcialmente oculto',
      _Attendance.review,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, _) => Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 390,
              height: 844,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ColoredBox(
                  color: AppColors.background,
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 24,
                        top: 28,
                        child: Text(
                          'Conferir chamada',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.65,
                            height: 1,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 24,
                        top: 75,
                        child: Text(
                          'Revise os resultados antes de confirmar. A IA não salva sozinha.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 24,
                        top: 102,
                        child: _SummaryCard.present(),
                      ),
                      const Positioned(
                        left: 143,
                        top: 102,
                        child: _SummaryCard.review(),
                      ),
                      const Positioned(
                        left: 262,
                        top: 102,
                        child: _SummaryCard.absent(),
                      ),
                      for (var index = 0; index < _students.length; index++)
                        Positioned(
                          left: 24,
                          top: 185 + (index * 73),
                          child: _StudentCard(student: _students[index]),
                        ),
                      Positioned(
                        left: 24,
                        top: 550,
                        child: _ActionButton(
                          label: _isConfirmed
                              ? 'Chamada confirmada'
                              : 'Confirmar chamada',
                          filled: true,
                          onTap: () => setState(() => _isConfirmed = true),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        top: 617,
                        child: _ActionButton(
                          label: 'Tirar nova foto',
                          onTap: () => setState(() => _isConfirmed = false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Attendance { present, review, absent }

class _Student {
  const _Student(this.initials, this.name, this.detail, this.attendance);
  final String initials;
  final String name;
  final String detail;
  final _Attendance attendance;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard._(
    this.total,
    this.label,
    this.background,
    this.foreground,
  );
  const _SummaryCard.present()
    : this._('27', 'Presentes', const Color(0xFFE6FAED), AppColors.success);
  const _SummaryCard.review()
    : this._('3', 'Revisar', const Color(0xFFFFF5DB), const Color(0xFFE38F14));
  const _SummaryCard.absent()
    : this._('2', 'Ausentes', const Color(0xFFFFEBED), const Color(0xFFC72933));

  final String total;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    height: 68,
    padding: const EdgeInsets.fromLTRB(10, 11, 10, 10),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          total,
          style: TextStyle(
            color: foreground,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const Spacer(),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            height: 1,
          ),
        ),
      ],
    ),
  );
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final _Student student;

  @override
  Widget build(BuildContext context) {
    final status = switch (student.attendance) {
      _Attendance.present => _Status(
        'Presente',
        const Color(0xFFE6FAED),
        AppColors.success,
      ),
      _Attendance.review => _Status(
        'Revisar',
        const Color(0xFFFFF5DB),
        const Color(0xFFE38F14),
      ),
      _Attendance.absent => _Status(
        'Ausente',
        const Color(0xFFFFEBED),
        const Color(0xFFC72933),
      ),
    };
    return Container(
      width: 342,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              student.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  student.detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 76,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                color: status.foreground,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Status {
  const _Status(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 342,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surface,
          border: filled ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    ),
  );
}
