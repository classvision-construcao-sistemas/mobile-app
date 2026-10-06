import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Card principal com chamada para ação de IA
///
/// Exibe o card azul com gradiente que convida o professor
/// a fazer a chamada com IA usando a câmera.
class AiCallCard extends StatelessWidget {
  /// Callback ao pressionar "Abrir câmera"
  final VoidCallback onOpenCamera;

  const AiCallCard({
    super.key,
    required this.onOpenCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fazer chamada com IA',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Fotografe a sala e confira os reconhecidos antes de salvar',
            style: AppTextStyles.cardDescription,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Abrir câmera',
                style: AppTextStyles.cardButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
