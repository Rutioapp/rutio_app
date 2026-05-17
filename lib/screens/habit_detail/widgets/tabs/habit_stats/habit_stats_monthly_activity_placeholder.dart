import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_section_card.dart';

class HabitStatsMonthlyActivityPlaceholder extends StatelessWidget {
  const HabitStatsMonthlyActivityPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return HabitStatsSectionCard(
      key: const Key('habit_stats_monthly_activity_placeholder'),
      title: l10n.habitStatsMonthlyActivityTitle,
      child: Text(
        l10n.habitStatsMonthlyActivityPlaceholderBody,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.35,
              color: const Color(0xFF746A60),
            ),
      ),
    );
  }
}
