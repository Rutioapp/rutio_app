import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_progress.dart';
import 'achievement_asset_image.dart';

class AchievementBadgeTile extends StatelessWidget {
  const AchievementBadgeTile({
    super.key,
    required this.progress,
    required this.onTap,
  });

  final AchievementProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isUnlocked = progress.status == AchievementStatus.unlocked;
    final isHidden = progress.isHiddenLocked;
    final isSpecial = progress.achievement.type == AchievementType.special;
    final familyName = isSpecial
        ? l10n.achievementsSpecialLabel
        : l10n.familyName(progress.achievement.familyId);
    final titleColor = isUnlocked
        ? const Color(0xFF2D221A)
        : const Color(0xFFB0A292);
    final subtitleColor = isUnlocked
        ? const Color(0xFFB07B42)
        : const Color(0xFFC8B9A8);

    return Semantics(
      button: true,
      label: progress.achievement.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHidden
                          ? const Color(0xFFEEE5DC)
                          : const Color(0xFFF4ECE1),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFDCCAB7),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: _BadgeIcon(progress: progress),
                          ),
                        ),
                        if (isUnlocked)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB78853),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isHidden
                      ? l10n.achievementsMysteryTitle
                      : isSpecial
                          ? progress.achievement.title
                          : l10n.achievementTierLabel(progress.achievement.tier),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isHidden ? '???' : familyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.6,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.progress});

  final AchievementProgress progress;
  static const Color _silhouetteColor = Color(0xFF9C958A);

  @override
  Widget build(BuildContext context) {
    final icon = AchievementAssetImage(
      assetPath: progress.achievement.assetPath,
      fit: BoxFit.contain,
      tintColor:
          progress.status == AchievementStatus.unlocked ? null : _silhouetteColor,
    );

    switch (progress.status) {
      case AchievementStatus.unlocked:
        return icon;
      case AchievementStatus.locked:
        return Opacity(
          opacity: progress.isHiddenLocked ? 0.18 : 0.34,
          child: icon,
        );
      case AchievementStatus.inProgress:
        return Opacity(opacity: 0.62, child: icon);
    }
  }
}
