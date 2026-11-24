import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';

class AttendanceSavedPage extends StatelessWidget {
  const AttendanceSavedPage({super.key, required this.classId});

  final String? classId;

  /// Se a última chamada desta turma ficou só nesta sessão (sem auditoria).
  bool _savedLocally(BuildContext context) {
    final history = context.watch<SchoolRepository?>()?.history ?? const [];
    final latest = history.where((it) => it.classId == classId).firstOrNull;
    return latest?.status == AttendanceRecord.local;
  }

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
            Text(
              _savedLocally(context)
                  ? 'A chamada ficou registrada só nesta sessão. Apenas '
                        'coordenadores gravam chamadas no histórico da turma.'
                  : 'Os dados foram adicionados ao histórico da turma.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Voltar para a turma',
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
                if (classId != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigator.pushNamed(
                      AppRoutes.classDetails,
                      arguments: classId,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Ir para o início',
              outlined: true,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (_) => false,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
