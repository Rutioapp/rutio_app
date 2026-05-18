import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';
import 'habit_stats_year_activity_section.dart';
import 'habit_stats_year_month_grid.dart';
import 'habit_stats_section_card.dart';

class HabitStatsYearSection extends StatelessWidget {
  final List<HabitStatsYearMonthSummary> monthSummaries;
  final bool isCounter;
  final String countUnitLabel;
  final Color accentColor;

  const HabitStatsYearSection({
    super.key,
    required this.monthSummaries,
    required this.isCounter,
    required this.accentColor,
    this.countUnitLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        HabitStatsSectionCard(
          key: const Key('habit_stats_year_months_card'),
          title: l10n.habitStatsYearMonthsTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.habitStatsYearMonthsBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.35,
                      color: const Color(0xFF746A60),
                    ),
              ),
              const SizedBox(height: 10),
              HabitStatsYearMonthGrid(
                summaries: monthSummaries,
                isCounter: isCounter,
                accentColor: accentColor,
                countUnitLabel: countUnitLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        HabitStatsYearActivitySection(monthSummaries: monthSummaries),
      ],
    );
  }
}
