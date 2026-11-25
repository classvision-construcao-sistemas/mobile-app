import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/admin_repository.dart';

/// Faixa entre o cabeçalho e o conteúdo dos painéis de administração:
/// mostra que os dados estão carregando ou o erro, com "Tentar novamente".
/// Some quando os dados estão em dia.
class AdminDataStatus extends StatelessWidget {
  const AdminDataStatus({super.key, this.bottom = 20});

  final double bottom;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final Widget? child = switch (repository) {
      AdminRepository(error: final error?) => AppErrorBanner(
        error,
        onRetry: repository.load,
      ),
      AdminRepository(loading: true) => const Row(
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Carregando dados...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      _ => null,
    };
    if (child == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: child,
    );
  }
}

/// Texto para lista vazia: enquanto a primeira carga não termina, diz que
/// está carregando em vez de "nenhum item".
String adminEmptyText(BuildContext context, String empty) {
  final repository = context.watch<AdminRepository>();
  if (!repository.loaded && repository.error == null) {
    return 'Carregando...';
  }
  return empty;
}
