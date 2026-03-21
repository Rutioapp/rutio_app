import 'package:flutter/material.dart';

/// 🎨 Color Palette – Rutio / Habit City
/// Fuente única de verdad para colores de la app
///
/// USO ACTUAL:
///   ColorPalette.bg
///   ColorPalette.primary
///
/// USO FUTURO (Theme):
///   context.colors.bg
class ColorPalette {
  ColorPalette._();

  // ─────────────────────────────────────────────
  // BASE COLORS (brand)
  // ─────────────────────────────────────────────

  static const Color primary = Color(0xFFB9A7E8);
  static const Color primaryDark = Color(0xFF9B86DD);
  static const Color accent = Color(0xFF7C6AE6);

  // ─────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────

  static const Color bg = Color(0xFFCBB8E9);
  static const Color surface = Color(0xFFF4F1FB);
  static const Color cardBg = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF6B6B6B);

  static const Color divider = Color(0xFFE0D9F3);

  // ─────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────

  static const Color bgDark = Color(0xFF1E1B2E);
  static const Color surfaceDark = Color(0xFF2A2540);
  static const Color cardBgDark = Color(0xFF332E4F);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFBDB7E3);

  static const Color dividerDark = Color(0xFF3E3860);
}