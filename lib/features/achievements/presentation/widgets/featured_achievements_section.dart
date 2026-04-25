import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/models/achievement_progress.dart';
import 'achievement_badge_art.dart';

class FeaturedAchievementsSection extends StatelessWidget {
  const FeaturedAchievementsSection({
    super.key,
    required this.featuredAchievements,
    required this.onTap,
  });

  final List<AchievementProgress> featuredAchievements;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileFeaturedAchievementsTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    offset: Offset(0, 10),
                    color: Color(0x11000000),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featuredAchievements.isEmpty
                              ? l10n.profileFeaturedAchievementsEmptyTitle
                              : l10n.profileFeaturedAchievementsSubtitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF211A14),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          featuredAchievements.isEmpty
                              ? l10n.profileFeaturedAchievementsEmptySubtitle
                              : l10n.profileFeaturedAchievementsHint,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF736A61),
                            height: 1.28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final item = index < featuredAchievements.length
                          ? featuredAchievements[index]
                          : null;

                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                        child: item == null
                            ? _PlaceholderBadge(index: index)
                            : AchievementBadgeArt(
                                assetPath: item.achievement.assetPath,
                                status: item.status,
                                progress: item.progress,
                                size: 56,
                              ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: Color(0xFFB1A99E),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderBadge extends StatelessWidget {
  const _PlaceholderBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DED0)),
      ),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB1A697),
        ),
      ),
    );
  }
}
