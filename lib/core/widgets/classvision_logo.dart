import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ClassVisionLogo extends StatelessWidget {
  const ClassVisionLogo({super.key, this.onDark = false, this.compact = false});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 34 : 38,
        height: compact ? 34 : 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 25),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'ClassVision',
            style: TextStyle(
              color: onDark ? Colors.white : AppColors.textPrimary,
              fontSize: compact ? 19 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
        ),
      ),
    ],
  );
}
