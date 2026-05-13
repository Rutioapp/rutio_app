part of '../habit_stats_tab.dart';

class _CheckComparisonCard extends StatelessWidget {
  const _CheckComparisonCard({
    required this.l10n,
    required this.thisWeek,
    required this.previousWeek,
  });

  final AppLocalizations l10n;
  final _CheckStats thisWeek;
  final _CheckStats previousWeek;

  @override
  Widget build(BuildContext context) {
    final hasComparison = previousWeek.expected > 0;
    final delta =
        hasComparison ? thisWeek.consistencyPct - previousWeek.consistencyPct : 0;
    final isPositive = delta >= 0;
    final deltaText = hasComparison
        ? '${delta > 0 ? '+' : ''}$delta%'
        : l10n.habitStatsIndividualNoComparisonYet;

    return Container(
      width: double.infinity,
      decoration: _plainCardDecoration(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF6F1E8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.arrow_up_right,
              color: isPositive
                  ? const Color(0xFF4E8D55)
                  : const Color(0xFF987E66),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.habitStatsWeeklyComparisonTitle,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deltaText,
                  style: TextStyle(
                    fontFamily: AppTextStyles.serifFamily,
                    fontSize: 42,
                    height: 0.9,
                    color: hasComparison
                        ? const Color(0xFF4E8D55)
                        : const Color(0xFF7C7368),
                  ),
                ),
                if (hasComparison)
                  Text(
                    l10n.statisticsV3WeeklyImprovementVsLastWeek,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 16,
                      color: Color(0xFF635E56),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chart_bar_alt_fill,
            color:
                isPositive ? const Color(0xFF4E8D55) : const Color(0xFF987E66),
            size: 30,
          ),
        ],
      ),
    );
  }
}

class _CountComparisonCard extends StatelessWidget {
  const _CountComparisonCard({
    required this.l10n,
    required this.last7Rows,
    required this.unit,
    required this.thisWeek,
    required this.previousWeek,
  });

  final AppLocalizations l10n;
  final List<_DayRow> last7Rows;
  final String unit;
  final _CountStats thisWeek;
  final _CountStats previousWeek;

  @override
  Widget build(BuildContext context) {
    _DayRow? bestDay;
    for (final row in last7Rows) {
      if (bestDay == null || row.countValue > bestDay.countValue) {
        bestDay = row;
      }
    }
    final safeBestDay = bestDay ?? _DayRow.empty(DateTime.now());

    final hasComparison = previousWeek.total > 0;
    final delta = hasComparison
        ? (((thisWeek.total - previousWeek.total) / previousWeek.total) * 100)
            .round()
        : 0;

    return Container(
      width: double.infinity,
      decoration: _plainCardDecoration(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF6F1E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.star_fill,
              color: Color(0xFFC08A2F),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.habitStatsIndividualBestDay,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.weekdayShort(safeBestDay.date.weekday)} - ${_valueWithUnit(safeBestDay.countValue, unit)}',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.serifFamily,
                    fontSize: 38,
                    height: 0.92,
                    color: Color(0xFF1E1812),
                  ),
                ),
              ],
            ),
          ),
          if (hasComparison)
            Text(
              '${delta > 0 ? '+' : ''}$delta%',
              style: const TextStyle(
                fontFamily: AppTextStyles.serifFamily,
                fontSize: 36,
                color: Color(0xFF4E8D55),
              ),
            ),
        ],
      ),
    );
  }
}
