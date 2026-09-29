import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/ai_processing_state.dart';

class ProcessingStatusCard extends StatelessWidget {
  const ProcessingStatusCard({required this.steps, super.key});

  final List<ProcessingStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 299,
      height: 114,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [for (final step in steps) _ProcessingStepRow(step: step)],
      ),
    );
  }
}

class _ProcessingStepRow extends StatelessWidget {
  const _ProcessingStepRow({required this.step});

  final ProcessingStep step;

  @override
  Widget build(BuildContext context) {
    final color = switch (step.status) {
      ProcessingStepStatus.completed => AppColors.success,
      ProcessingStepStatus.active => AppColors.primary,
      ProcessingStepStatus.pending => AppColors.textSecondary,
    };

    return SizedBox(
      height: 24,
      child: Row(
        children: [
          SizedBox(
            width: 13,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StepIndicator(status: step.status),
            ),
          ),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1,
                fontWeight: step.status == ProcessingStepStatus.active
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              child: Text(step.label, maxLines: 1, overflow: TextOverflow.clip),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.status});

  final ProcessingStepStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ProcessingStepStatus.completed => const Icon(
        Icons.check_rounded,
        size: 11,
        color: AppColors.success,
      ),
      ProcessingStepStatus.active => const _PulsingDot(),
      ProcessingStepStatus.pending => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textSecondary, width: 1.2),
        ),
      ),
    };
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> {
  bool _dimmed = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _dimmed ? .45 : 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) setState(() => _dimmed = !_dimmed);
      },
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(dimension: 8),
      ),
    );
  }
}
