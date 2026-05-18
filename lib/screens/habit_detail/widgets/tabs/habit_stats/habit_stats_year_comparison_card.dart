import 'package:flutter/material.dart';

import 'habit_stats_models.dart';
import 'habit_stats_year_insight_resolver.dart';

class HabitStatsYearComparisonCard extends StatelessWidget {
  final HabitStatsYearComparison comparison;
  final HabitStatsYearComparisonCopy copy;

  static const _cardBorder = Color(0xFFE9E3D9);
  static const _cardText = Color(0xFF2F251C);
  static const _cardMuted = Color(0xFF746A60);
  static const _positive = Color(0xFF4E8A4A);
  static const _negative = Color(0xFF9D4E4E);

  const HabitStatsYearComparisonCard({
    super.key,
    required this.comparison,
    required this.copy,
  });

  @override
  Widget build(BuildContext context) {
    final state = comparison.state;
    final accentColor = switch (state) {
      HabitStatsYearComparisonState.improving => _positive,
      HabitStatsYearComparisonState.aboveAverage => _positive,
      HabitStatsYearComparisonState.declining => _negative,
      HabitStatsYearComparisonState.belowAverage => _negative,
      HabitStatsYearComparisonState.stable => _cardMuted,
      HabitStatsYearComparisonState.starting => _cardMuted,
      HabitStatsYearComparisonState.noData => _cardMuted,
    };
    final icon = switch (state) {
      HabitStatsYearComparisonState.improving => Icons.trending_up_rounded,
      HabitStatsYearComparisonState.aboveAverage => Icons.north_east_rounded,
      HabitStatsYearComparisonState.declining => Icons.trending_down_rounded,
      HabitStatsYearComparisonState.belowAverage => Icons.south_east_rounded,
      HabitStatsYearComparisonState.stable => Icons.show_chart_rounded,
      HabitStatsYearComparisonState.starting => Icons.timeline_rounded,
      HabitStatsYearComparisonState.noData => Icons.show_chart_rounded,
    };

    return Container(
      key: const Key('habit_stats_year_comparison_card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        color: _cardText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  copy.mainText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: _cardMuted,
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: accentColor.withValues(alpha: 0.42),
            size: 20,
          ),
        ],
      ),
    );
  }
}
