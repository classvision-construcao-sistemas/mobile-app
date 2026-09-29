import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF8F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1A52CC);
  static const primarySoft = Color(0xFFE6F0FF);
  static const textPrimary = Color(0xFF13171F);
  static const textSecondary = Color(0xFF636B7D);
  static const border = Color(0xFFE0E6ED);
  static const success = Color(0xFF1F8C4F);
}

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Inter',
    );
  }
}
