import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsInsightCard extends StatelessWidget {
  final HabitStatsShellData shellData;
  final HabitStatsPeriod selectedPeriod;
  final Color familyColor;

  const HabitStatsInsightCard({
    super.key,
    required this.shellData,
    required this.selectedPeriod,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = shellData.currentStreak == 0
        ? l10n.habitStatsHeadlineStartToday
        : shellData.currentStreak < 3
            ? l10n.habitStatsHeadlineGoodStart
            : l10n.habitStatsHeadlineOnStreak;
    final periodLabel = switch (selectedPeriod) {
      HabitStatsPeriod.week => l10n.habitStatsPeriodWeek,
      HabitStatsPeriod.month => l10n.habitStatsPeriodMonth,
      HabitStatsPeriod.year => l10n.habitStatsPeriodYear,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFAF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9DDCC)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: familyColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: familyColor.withValues(alpha: 0.92),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF2F261D),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$periodLabel · ${l10n.habitStatsMotivationKeepTail}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6E5E4B),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
