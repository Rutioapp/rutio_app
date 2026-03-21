import 'package:flutter/material.dart';

import 'package:rutio/constants/color_palette.dart';
import 'package:rutio/utils/app_theme.dart';

@immutable
class AvatarRingPalette {
  final Color trackColor;
  final Color startColor;
  final Color midColor;
  final Color endColor;
  final Color glowColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color fallbackStartColor;
  final Color fallbackEndColor;
  final Color fallbackForegroundColor;

  const AvatarRingPalette({
    required this.trackColor,
    required this.startColor,
    required this.midColor,
    required this.endColor,
    required this.glowColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.fallbackStartColor,
    required this.fallbackEndColor,
    required this.fallbackForegroundColor,
  });

  factory AvatarRingPalette.resolve(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return AvatarRingPalette(
        trackColor: ColorPalette.textPrimaryDark.withValues(alpha: 0.16),
        startColor: const Color(0xFFE8C98E),
        midColor: Color.lerp(AppColors.flowerYellow, AppColors.earth, 0.45)!,
        endColor: AppColors.earth,
        glowColor: const Color(0x40E8C98E),
        surfaceColor: const Color(0xFF4A2B17),
        borderColor: const Color(0x80B8895A),
        fallbackStartColor: const Color(0xFF6B4020),
        fallbackEndColor: const Color(0xFF4A2B17),
        fallbackForegroundColor: const Color(0xFFF7EBDD),
      );
    }

    return AvatarRingPalette(
      trackColor: AppColors.earth.withValues(alpha: 0.18),
      startColor: const Color(0xFFE6D2A6),
      midColor: Color.lerp(AppColors.flowerYellow, AppColors.earth, 0.55)!,
      endColor: AppColors.earth,
      glowColor: AppColors.flowerYellow.withValues(alpha: 0.18),
      surfaceColor: Colors.white.withValues(alpha: 0.18),
      borderColor: AppColors.earth.withValues(alpha: 0.28),
      fallbackStartColor: AppColors.earth.withValues(alpha: 0.78),
      fallbackEndColor: AppColors.ink.withValues(alpha: 0.88),
      fallbackForegroundColor: AppColors.cream,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AvatarRingPalette &&
        other.trackColor == trackColor &&
        other.startColor == startColor &&
        other.midColor == midColor &&
        other.endColor == endColor &&
        other.glowColor == glowColor &&
        other.surfaceColor == surfaceColor &&
        other.borderColor == borderColor &&
        other.fallbackStartColor == fallbackStartColor &&
        other.fallbackEndColor == fallbackEndColor &&
        other.fallbackForegroundColor == fallbackForegroundColor;
  }

  @override
  int get hashCode => Object.hash(
        trackColor,
        startColor,
        midColor,
        endColor,
        glowColor,
        surfaceColor,
        borderColor,
        fallbackStartColor,
        fallbackEndColor,
        fallbackForegroundColor,
      );
}
