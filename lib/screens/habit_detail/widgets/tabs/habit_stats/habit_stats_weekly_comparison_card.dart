import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';

class HabitStatsWeeklyComparisonCard extends StatelessWidget {
  final int? deltaPct;

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
    final valueColor = hasComparison
        ? (isPositive ? const Color(0xFF4E8A4A) : const Color(0xFF9D4E4E))
        : const Color(0xFF7B6E61);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE4D8)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF5EFE6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasComparison ? Icons.trending_up_rounded : Icons.show_chart_rounded,
              color: hasComparison && delta < 0
                  ? const Color(0xFF9D4E4E)
                  : const Color(0xFF5B975A),
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
                        color: const Color(0xFF221A14),
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
                        color: const Color(0xFF5A4E42),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.trending_up_rounded,
            color: hasComparison && delta < 0
                ? const Color(0xFF9D4E4E).withValues(alpha: 0.5)
                : const Color(0xFF5B975A).withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}
