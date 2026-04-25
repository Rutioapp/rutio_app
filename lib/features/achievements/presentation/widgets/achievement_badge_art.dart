import 'package:flutter/material.dart';

import '../../domain/models/achievement.dart';
import 'achievement_asset_image.dart';
import 'achievement_badge_visual_state.dart';

class AchievementBadgeArt extends StatelessWidget {
  const AchievementBadgeArt({
    super.key,
    required this.assetPath,
    required this.status,
    required this.progress,
    this.size = 74,
  });

  final String assetPath;
  final AchievementStatus status;
  final double progress;
  final double size;
  static const Color _silhouetteColor = Color(0xFF9C958A);

  @override
  Widget build(BuildContext context) {
    final visuals = AchievementBadgeVisualResolver.resolve(status);
    final badge = _buildBadgeImage();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: visuals.background,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: visuals.borderColor),
        boxShadow: [
          ...visuals.shadow,
          if (status == AchievementStatus.unlocked)
            BoxShadow(
              color: visuals.glow,
              blurRadius: 26,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: visuals.artOpacity,
            child: status == AchievementStatus.unlocked
                ? badge
                : _buildBadgeImage(tintColor: _silhouetteColor),
          ),
          if (visuals.showProgressRing)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: progress.clamp(0, 1).toDouble(),
                  ),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: size * 0.045,
                      backgroundColor: const Color(0xFFF0E8DA),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFB89154),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeImage({Color? tintColor}) {
    final artPadding = size * 0.12;

    return Padding(
      padding: EdgeInsets.all(artPadding),
      child: AchievementAssetImage(
        assetPath: assetPath,
        fit: BoxFit.contain,
        tintColor: tintColor,
      ),
    );
  }
}
