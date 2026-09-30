import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estilos de texto do ClassVision
class AppTextStyles {
  AppTextStyles._();

  /// Título principal de saudação — "Bom dia, Marina"
  static TextStyle greeting = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF1A1A2E),
    height: 1.2,
  );

  /// Subtítulo da data — "Terça-feira, 1 de setembro"
  static TextStyle dateSubtitle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF6B7280),
    height: 1.4,
  );

  /// Título do card de IA — "Fazer chamada com IA"
  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.3,
  );

  /// Descrição do card de IA
  static TextStyle cardDescription = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white.withValues(alpha: 0.85),
    height: 1.4,
  );

  /// Texto do botão do card de IA — "Abrir câmera"
  static TextStyle cardButton = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF2563EB),
    height: 1.2,
  );

  /// Nome da turma — "2º Ano A"
  static TextStyle className = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1A2E),
    height: 1.3,
  );

  /// Info da turma — "08:00 • Sala 201"
  static TextStyle classInfo = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF6B7280),
    height: 1.4,
  );

  /// Badge de status — "Agora"
  static TextStyle badgeText = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Label do bottom nav
  static TextStyle navLabel = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// Label do bottom nav ativo
  static TextStyle navLabelActive = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}
