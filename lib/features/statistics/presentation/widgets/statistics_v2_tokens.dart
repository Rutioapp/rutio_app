import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class StatisticsV2Tokens {
  const StatisticsV2Tokens._();

  static const Color background = Color(0xFFF7F2E9);
  static const Color surface = Color(0xFFFFFCF7);
  static const Color surfaceSoft = Color(0xFFF3EEE4);
  static const Color ink = Color(0xFF201B16);
  static const Color inkMuted = Color(0xFF6F665A);
  static const Color accent = Color(0xFF5A341A);
  static const Color accentSoft = Color(0xFFC8924D);

  static TextStyle get title => const TextStyle(
        fontFamily: AppTextStyles.serifFamily,
        fontSize: 22,
        height: 1.05,
        color: ink,
      );

  static TextStyle get subtitle => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: inkMuted,
      );

  static BoxDecoration frostedSurface({
    double radius = 22,
    Color? tint,
  }) {
    return BoxDecoration(
      color: tint ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
