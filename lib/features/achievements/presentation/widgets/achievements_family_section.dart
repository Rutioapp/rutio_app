import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../application/achievement_catalog.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_progress.dart';
import 'achievement_badge_tile.dart';

class AchievementsFamilySection extends StatelessWidget {
  const AchievementsFamilySection({
    super.key,
    required this.sectionId,
    required this.sectionColor,
    required this.items,
    required this.onItemTap,
  });

  final String sectionId;
  final Color sectionColor;
  final List<AchievementProgress> items;
  final ValueChanged<AchievementProgress> onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unlockedCount = items
        .where((item) => item.status == AchievementStatus.unlocked)
        .length;
    final title = sectionId == AchievementCatalog.specialSectionId
        ? l10n.achievementsSpecialSectionTitle
        : l10n.familyName(sectionId).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: sectionColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF36291F),
                ),
              ),
            ),
            Text(
              l10n.achievementsSectionUnlockedCount(
                unlockedCount,
                items.length,
              ),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFA39687),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: 0.62,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return AchievementBadgeTile(
              progress: item,
              onTap: () => onItemTap(item),
            );
          },
        ),
      ],
    );
  }
}
