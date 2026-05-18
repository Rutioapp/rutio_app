import 'package:flutter/material.dart';

import 'habit_stats_models.dart';
import 'habit_stats_monthly_comparison_resolver.dart';

class HabitStatsMonthlyComparisonCard extends StatelessWidget {
  final HabitStatsMonthlyComparisonData comparison;
  final HabitStatsMonthlyComparisonCopy copy;

  static const _cardBorder = Color(0xFFE9E3D9);
  static const _cardText = Color(0xFF2F251C);
  static const _cardMuted = Color(0xFF746A60);
  static const _positive = Color(0xFF4E8A4A);
  static const _negative = Color(0xFF9D4E4E);

  const HabitStatsMonthlyComparisonCard({
    super.key,
    required this.comparison,
    required this.copy,
  });

  @override
  Widget build(BuildContext context) {
    final trend = comparison.trend;
    final accentColor = switch (trend) {
      HabitStatsComparisonTrend.better => _positive,
      HabitStatsComparisonTrend.worse => _negative,
      HabitStatsComparisonTrend.same => _cardMuted,
      HabitStatsComparisonTrend.unavailable => _cardMuted,
    };
    final icon = switch (trend) {
      HabitStatsComparisonTrend.better => Icons.trending_up_rounded,
      HabitStatsComparisonTrend.worse => Icons.trending_down_rounded,
      HabitStatsComparisonTrend.same => Icons.show_chart_rounded,
      HabitStatsComparisonTrend.unavailable => Icons.show_chart_rounded,
    };

    return Container(
      key: const Key('habit_stats_monthly_comparison_card'),
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
                const SizedBox(height: 1),
                Text(
                  copy.mainText,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 18,
                        color: accentColor,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  copy.secondaryText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: _cardMuted,
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
