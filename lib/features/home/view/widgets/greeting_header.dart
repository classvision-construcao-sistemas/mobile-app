import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Seção de saudação no topo da tela inicial
///
/// Exibe a saudação personalizada e a data atual.
class GreetingHeader extends StatelessWidget {
  /// Texto de saudação — ex: "Bom dia, Marina"
  final String greetingText;

  /// Data formatada — ex: "Terça-feira, 1 de setembro"
  final String dateText;

  const GreetingHeader({
    super.key,
    required this.greetingText,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greetingText,
          style: AppTextStyles.greeting,
        ),
        const SizedBox(height: 4),
        Text(
          dateText,
          style: AppTextStyles.dateSubtitle,
        ),
      ],
    );
  }
}
