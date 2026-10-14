import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';

class AttendanceSavedPage extends StatelessWidget {
  const AttendanceSavedPage({super.key, required this.classId});

  final String? classId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 54,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chamada salva!',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Os dados foram adicionados ao histórico da turma.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Voltar para a turma',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.classDetails,
                (route) => route.settings.name == AppRoutes.home,
                arguments: classId,
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Ir para o início',
              outlined: true,
              onPressed: () => Navigator.popUntil(
                context,
                (route) => route.settings.name == AppRoutes.home,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
