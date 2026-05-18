import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_section_card.dart';

class HabitStatsYearSection extends StatelessWidget {
  const HabitStatsYearSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return HabitStatsSectionCard(
      key: const Key('habit_stats_year_summary_card'),
      title: l10n.habitStatsYearSummaryTitle,
      child: Text(
        l10n.habitStatsYearSummaryBody,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.35,
              color: const Color(0xFF746A60),
            ),
      ),
    );
  }
}
