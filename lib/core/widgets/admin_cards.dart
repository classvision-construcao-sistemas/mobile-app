import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.supportingText,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final String? supportingText;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        if (supportingText != null) ...[
          const SizedBox(height: 8),
          Text(
            supportingText!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    ),
  );
}
