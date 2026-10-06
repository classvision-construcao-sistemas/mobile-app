import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../model/class_item_model.dart';
import '../../model/class_status.dart';

/// Card de turma exibido na lista da tela inicial
///
/// Mostra o nome da turma, horário, sala e um badge de status.
class ClassCard extends StatelessWidget {
  /// Dados da turma
  final ClassItemModel classItem;

  /// Callback ao pressionar o card
  final VoidCallback? onTap;

  const ClassCard({
    super.key,
    required this.classItem,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                classItem.name,
                style: AppTextStyles.className,
              ),
              const SizedBox(height: 4),
              Text(
                classItem.subtitle,
                style: AppTextStyles.classInfo,
              ),
              const SizedBox(height: 10),
              _StatusBadge(status: classItem.status, label: classItem.statusLabel),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge de status da turma
class _StatusBadge extends StatelessWidget {
  final ClassStatus status;
  final String label;

  const _StatusBadge({
    required this.status,
    required this.label,
  });

  Color get _backgroundColor {
    switch (status) {
      case ClassStatus.now:
        return AppColors.successLight;
      case ClassStatus.scheduled:
        return AppColors.infoLight;
      case ClassStatus.completed:
        return AppColors.divider;
    }
  }

  Color get _textColor {
    switch (status) {
      case ClassStatus.now:
        return AppColors.success;
      case ClassStatus.scheduled:
        return AppColors.primary;
      case ClassStatus.completed:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.badgeText.copyWith(color: _textColor),
      ),
    );
  }
}
