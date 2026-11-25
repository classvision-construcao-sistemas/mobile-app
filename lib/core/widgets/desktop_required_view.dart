import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'classvision_logo.dart';

class DesktopRequiredView extends StatelessWidget {
  const DesktopRequiredView({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: ClassVisionLogo(compact: true),
            ),
            const Spacer(),
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.desktop_windows_outlined,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Acesse pelo computador',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'O painel do Administrador do Sistema foi projetado para telas desktop.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            if (onSignOut != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sair'),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}
