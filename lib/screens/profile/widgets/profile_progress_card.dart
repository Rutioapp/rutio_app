import 'package:flutter/material.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';

import '../../../l10n/l10n.dart';
import '../utils/profile_xp.dart';
import 'progress_bar.dart';
import 'section_card.dart';

class ProfileProgressCard extends StatelessWidget {
  final Color accent;
  final LevelProgress progression;

  const ProfileProgressCard({
    super.key,
    required this.accent,
    required this.progression,
  });

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toString();
    final currentLevelXp = formatCompactXp(
      progression.currentLevelXp,
      localeName: localeName,
    );
    final xpForNextLevel = formatCompactXp(
      progression.xpForNextLevel,
      localeName: localeName,
    );
    final xpToNextLevel = formatCompactXp(
      progression.xpToNextLevel,
      localeName: localeName,
    );
    final levelLabel = context.l10n.editProfileStatLevel;
    final xpLabel = context.l10n.editProfileStatXp;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                '$levelLabel ${progression.level}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Semantics(
                label:
                    '$xpToNextLevel $xpLabel remaining to reach the next level',
                child: Text(
                  '$xpToNextLevel $xpLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            value: progression.progress,
            color: accent,
            height: 10,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label:
                      '$currentLevelXp / $xpForNextLevel $xpLabel',
                  child: Text(
                    '$currentLevelXp / $xpForNextLevel $xpLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4E4E4E),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
