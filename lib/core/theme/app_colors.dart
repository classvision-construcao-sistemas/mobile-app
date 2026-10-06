import 'package:flutter/material.dart';

/// Paleta de cores do ClassVision
class AppColors {
  AppColors._();

  // Cores primárias
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primarySoft = Color(0xFFE6F0FF);

  // Cores de fundo
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Cores de texto
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Cores de status
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Cores do bottom nav
  static const Color navInactive = Color(0xFF9CA3AF);
  static const Color navActive = Color(0xFF2563EB);

  // Bordas e divisores
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
