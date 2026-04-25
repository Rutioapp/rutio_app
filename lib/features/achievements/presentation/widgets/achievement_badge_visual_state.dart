import 'package:flutter/material.dart';

import '../../domain/models/achievement.dart';

class AchievementBadgeVisualState {
  const AchievementBadgeVisualState({
    required this.background,
    required this.borderColor,
    required this.artOpacity,
    required this.grayscale,
    required this.showProgressRing,
    required this.glow,
    required this.shadow,
  });

  final Gradient background;
  final Color borderColor;
  final double artOpacity;
  final bool grayscale;
  final bool showProgressRing;
  final Color glow;
  final List<BoxShadow> shadow;
}

class AchievementBadgeVisualResolver {
  const AchievementBadgeVisualResolver._();

  static AchievementBadgeVisualState resolve(AchievementStatus status) {
    switch (status) {
      case AchievementStatus.locked:
        return const AchievementBadgeVisualState(
          background: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6F4EF),
              Color(0xFFE7E3DB),
            ],
          ),
          borderColor: Color(0xFFD8D2C6),
          artOpacity: 0.34,
          grayscale: true,
          showProgressRing: false,
          glow: Color(0x00000000),
          shadow: [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        );
      case AchievementStatus.inProgress:
        return const AchievementBadgeVisualState(
          background: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF7F0),
              Color(0xFFF1EADD),
            ],
          ),
          borderColor: Color(0xFFE2D3B5),
          artOpacity: 0.82,
          grayscale: false,
          showProgressRing: true,
          glow: Color(0x14B69159),
          shadow: [
            BoxShadow(
              color: Color(0x13000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        );
      case AchievementStatus.unlocked:
        return const AchievementBadgeVisualState(
          background: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFCF5),
              Color(0xFFF3EBDD),
            ],
          ),
          borderColor: Color(0xFFE4D6B8),
          artOpacity: 1,
          grayscale: false,
          showProgressRing: false,
          glow: Color(0x22D9B36A),
          shadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        );
    }
  }
}
