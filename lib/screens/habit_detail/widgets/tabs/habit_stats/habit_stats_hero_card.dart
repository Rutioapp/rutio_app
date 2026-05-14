import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsHeroCard extends StatelessWidget {
  final HabitStatsShellData shellData;
  final HabitStatsPeriod selectedPeriod;
  final Color familyColor;

  const HabitStatsHeroCard({
    super.key,
    required this.shellData,
    required this.selectedPeriod,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final caption = switch (selectedPeriod) {
      HabitStatsPeriod.week => l10n.habitStatsThisWeek,
      HabitStatsPeriod.month => l10n.habitStatsPeriodMonth,
      HabitStatsPeriod.year => l10n.habitStatsPeriodYear,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF7EA),
            familyColor.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9DAC3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.habitStatsTabCurrentStreakTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 0.2,
                  color: const Color(0xFF6D5B45),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${shellData.currentStreak}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: const Color(0xFF2B241D),
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l10n.habitStatsTabDayUnit(shellData.currentStreak),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF6D5B45),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7B6853),
                ),
          ),
        ],
      ),
    );
  }
}
