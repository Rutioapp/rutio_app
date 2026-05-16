import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';

class HabitStatsWeeklyComparisonCard extends StatelessWidget {
  final int? deltaPct;
  static const _cardBorder = Color(0xFFE9E3D9);
  static const _cardText = Color(0xFF2F251C);
  static const _cardMuted = Color(0xFF746A60);
  static const _positive = Color(0xFF4E8A4A);
  static const _negative = Color(0xFF9D4E4E);

  const HabitStatsWeeklyComparisonCard({
    super.key,
    required this.deltaPct,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasComparison = deltaPct != null;
    final delta = deltaPct ?? 0;
    final isPositive = delta >= 0;
    final valueText = hasComparison ? '${isPositive ? '+' : ''}$delta%' : '-';
    final valueColor = hasComparison ? (isPositive ? _positive : _negative) : _cardMuted;
    final accentColor = hasComparison ? (isPositive ? _positive : _negative) : _cardMuted;

    return Container(
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
            child: Icon(
              hasComparison ? Icons.trending_up_rounded : Icons.show_chart_rounded,
              color: hasComparison && delta < 0 ? _negative : _positive,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.habitStatsWeeklyComparisonTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        color: _cardText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  valueText,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                        color: valueColor,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  hasComparison
                      ? l10n.statisticsV3WeeklyImprovementVsLastWeek
                      : l10n.statisticsV3WeeklyImprovementNoComparison,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: _cardMuted,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.trending_up_rounded,
            color: accentColor.withValues(alpha: 0.42),
            size: 20,
          ),
        ],
      ),
    );
  }
}
