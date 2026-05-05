import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/stats/helpers/stats_card_surface.dart';

import '../../../domain/statistics_models.dart';

class StatisticsDetailHeaderCard extends StatelessWidget {
  const StatisticsDetailHeaderCard({
    super.key,
    required this.habit,
  });

  final StatisticsHabitSummary habit;

  @override
  Widget build(BuildContext context) {
    final familyColor = FamilyTheme.colorOf(habit.familyId);
    final l10n = context.l10n;
    final typeLabel = habit.type == StatisticsHabitType.count
        ? l10n.statisticsV2HabitsTypeCount
        : l10n.statisticsV2HabitsTypeCheck;

    return Container(
      decoration: StatsCardSurface.decoration(context),
      padding: StatsCardSurface.padding,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: familyColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              FamilyTheme.emojiOf(habit.familyId),
              style: const TextStyle(fontSize: 21),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FamilyTheme.nameOf(habit.familyId),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: familyColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
