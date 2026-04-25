import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../utils/app_theme.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_progress.dart';
import 'achievement_asset_image.dart';

class AchievementsLatestUnlockedCard extends StatelessWidget {
  const AchievementsLatestUnlockedCard({
    super.key,
    required this.progress,
    required this.dateLabel,
    required this.onTap,
  });

  final AchievementProgress progress;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSpecial = progress.achievement.type == AchievementType.special;
    final familyName = isSpecial
        ? l10n.achievementsSpecialLabel
        : l10n.familyName(progress.achievement.familyId);
    final summary = isSpecial
        ? progress.achievement.description
        : l10n.achievementsFamilyConsistencySummary(
            familyName,
            progress.targetValue,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4ECE5),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFDCCAB8)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 74,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AchievementAssetImage(
                  assetPath: progress.achievement.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.achievementsLatestUnlockedEyebrow(familyName),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFAF7A47),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress.achievement.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.serifFamily,
                      fontSize: 22,
                      height: 1.05,
                      color: Color(0xFF432C20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7E7062),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.achievementsUnlockedOnDate(dateLabel),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E907F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFAF7A47),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
