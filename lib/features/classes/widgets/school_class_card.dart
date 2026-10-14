import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';

class SchoolClassCard extends StatelessWidget {
  const SchoolClassCard({
    super.key,
    required this.classroom,
    required this.onTap,
  });

  final SchoolClass classroom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.groups_2_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                classroom.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${classroom.students.length} alunos • ${classroom.room}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: classroom.attendanceCompleted
                    ? AppColors.successLight
                    : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                classroom.attendanceCompleted ? 'Realizada' : classroom.time,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: classroom.attendanceCompleted
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.navInactive,
            ),
          ],
        ),
      ],
    ),
  );
}
