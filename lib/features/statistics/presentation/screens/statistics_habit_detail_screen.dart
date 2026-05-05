import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/stats/helpers/stats_card_surface.dart';
import 'package:rutio/widgets/stats/helpers/stats_number_formatter.dart';
import 'package:rutio/widgets/stats/stats_count_cards.dart';
import 'package:rutio/widgets/stats/stats_motivational_tip_card.dart';
import 'package:rutio/widgets/stats/stats_weekly_bar_chart_card.dart';
import 'package:rutio/widgets/stats/streak_hero_card.dart';
import 'package:rutio/widgets/stats/weekly_comparison_card.dart';

import '../../application/adapters/statistics_data_adapter.dart';
import '../../domain/statistics_models.dart';
import '../../domain/statistics_period.dart';
import '../widgets/detail/statistics_detail_best_moment_card.dart';
import '../widgets/detail/statistics_detail_check_metrics_card.dart';
import '../widgets/detail/statistics_detail_empty_state.dart';
import '../widgets/detail/statistics_detail_header_card.dart';
import '../widgets/statistics_period_selector.dart';
import '../widgets/statistics_v2_tokens.dart';

class StatisticsHabitDetailScreen extends StatefulWidget {
  const StatisticsHabitDetailScreen({
    super.key,
    required this.habitId,
    this.initialPeriod = StatisticsPeriod.week,
  });

  final String habitId;
  final StatisticsPeriod initialPeriod;

  @override
  State<StatisticsHabitDetailScreen> createState() =>
      _StatisticsHabitDetailScreenState();
}

class _StatisticsHabitDetailScreenState extends State<StatisticsHabitDetailScreen> {
  final StatisticsDataAdapter _adapter = const StatisticsDataAdapter();
  late StatisticsPeriod _period;

  @override
  void initState() {
    super.initState();
    _period = _normalizeDetailPeriod(widget.initialPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<UserStateStore>();
    final detail = _adapter.buildHabitDetail(
      store: store,
      habitId: widget.habitId,
      period: _period,
    );

    if (detail == null) {
      return Scaffold(
        backgroundColor: StatisticsV2Tokens.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.statisticsV2DetailTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: StatisticsDetailEmptyState(
            title: l10n.statisticsV2DetailNotFoundTitle,
            subtitle: l10n.statisticsV2DetailNotFoundSubtitle,
          ),
        ),
      );
    }

    final habit = detail.habit;
    final familyColor = FamilyTheme.colorOf(habit.familyId);

    return Scaffold(
      backgroundColor: StatisticsV2Tokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.statisticsV2DetailTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          StatisticsPeriodSelector(
            value: _period,
            periods: const [
              StatisticsPeriod.week,
              StatisticsPeriod.month,
              StatisticsPeriod.year,
            ],
            onChanged: (period) {
              setState(() {
                _period = period;
              });
            },
          ),
          const SizedBox(height: 12),
          StatisticsDetailHeaderCard(habit: habit),
          const SizedBox(height: 12),
          StreakHeroCard(
            streakDays: habit.currentStreak,
            nextMilestoneDays: _nextMilestone(habit.currentStreak),
          ),
          if (!detail.hasRangeData) ...[
            const SizedBox(height: 12),
            StatisticsDetailEmptyState(
              title: l10n.statisticsV2DetailNoDataTitle,
              subtitle: l10n.statisticsV2DetailNoDataSubtitle,
            ),
          ],
          const SizedBox(height: 12),
          StatsWeeklyBarChartCard(
            title: l10n.statisticsV2DetailChartTitle,
            subtitle: _chartSubtitle(context, _period),
            points: _buildChartPoints(context, detail),
            accent: familyColor,
            valueFormatter: (value) {
              if (habit.type == StatisticsHabitType.check) {
                return value.round().toString();
              }
              return StatsNumberFormatter.compact1(value);
            },
          ),
          const SizedBox(height: 12),
          if (habit.type == StatisticsHabitType.check)
            StatisticsDetailCheckMetricsCard(
              completedDays: detail.completedDays,
              scheduledDays: detail.scheduledDays,
              completionPct: detail.completionPct,
              bestStreak: habit.bestStreak,
              daysWithActivity: detail.daysWithActivity,
            )
          else ...[
            StatsCountVolumeCard(
              totalAccumulated: habit.countProgress?.totalAccumulated ?? 0,
              dailyAverage: habit.countProgress?.dailyAverage ?? 0,
              activeDayAverage: habit.countProgress?.activeDayAverage ?? 0,
              bestDay: habit.countProgress?.bestDay ?? 0,
              activeDays: habit.countProgress?.activeDays ?? 0,
            ),
            const SizedBox(height: 12),
            StatsCountObjectiveCard(
              goalCompletedDays: habit.countProgress?.goalCompletedDays ?? 0,
              partialProgressDays: habit.countProgress?.partialProgressDays ?? 0,
              compliancePct: habit.countProgress?.compliancePct ?? 0,
              target: habit.target,
              accent: familyColor,
            ),
          ],
          const SizedBox(height: 12),
          if (detail.thisWeekDoneDays + detail.lastWeekDoneDays <= 0)
            StatisticsDetailEmptyState(
              title: l10n.habitStatsWeeklyComparisonTitle,
              subtitle: l10n.statisticsV2DetailNoComparisonData,
            )
          else
            WeeklyComparisonCard(
              thisWeekDays: detail.thisWeekDoneDays,
              lastWeekDays: detail.lastWeekDoneDays,
              accentColor: familyColor,
              asCard: true,
            ),
          const SizedBox(height: 12),
          StatisticsDetailBestMomentCard(
            accent: familyColor,
            hasData: detail.hasBestMomentData,
            percents: detail.bestMomentPercents,
          ),
          const SizedBox(height: 12),
          StatsMotivationalTipCard(
            habitTitle: habit.title,
            streakDays: habit.currentStreak,
            thisWeekDoneDays: detail.thisWeekDoneDays,
            lastWeekDoneDays: detail.lastWeekDoneDays,
            bestTimeLabel: detail.bestMomentKey == null
                ? null
                : l10n.habitStatsTimeSlot(detail.bestMomentKey!),
            compliancePct: habit.countProgress?.compliancePct.round(),
          ),
          const SizedBox(height: 12),
          _InsightCard(insight: detail.insight),
        ],
      ),
    );
  }

  List<StatsBarPoint> _buildChartPoints(
    BuildContext context,
    StatisticsHabitDetailSummary detail,
  ) {
    switch (_period) {
      case StatisticsPeriod.week:
        return _weeklyPoints(context, detail);
      case StatisticsPeriod.month:
        return _chunkedPoints(detail, chunkSize: 5);
      case StatisticsPeriod.year:
        return _monthlyPoints(context, detail);
      case StatisticsPeriod.day:
        return _weeklyPoints(context, detail);
    }
  }

  List<StatsBarPoint> _weeklyPoints(
    BuildContext context,
    StatisticsHabitDetailSummary detail,
  ) {
    final l10n = context.l10n;
    final days = detail.range.days;
    final values = detail.dailyValues;
    return List<StatsBarPoint>.generate(values.length, (index) {
      final day = days[index];
      return StatsBarPoint(
        label: l10n.weekdayLetter(day.weekday),
        value: values[index].toDouble(),
        isActive: index == values.length - 1,
      );
    });
  }

  List<StatsBarPoint> _chunkedPoints(
    StatisticsHabitDetailSummary detail, {
    required int chunkSize,
  }) {
    final points = <StatsBarPoint>[];
    final days = detail.range.days;
    final values = detail.dailyValues;

    for (var start = 0; start < values.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, values.length).toInt();
      final chunkValues = values.sublist(start, end);
      final chunkDays = days.sublist(start, end);
      final total = chunkValues.fold<int>(0, (sum, v) => sum + v);
      final label = '${chunkDays.first.day}-${chunkDays.last.day}';
      points.add(
        StatsBarPoint(
          label: label,
          value: total.toDouble(),
          isActive: end == values.length,
        ),
      );
    }

    return points;
  }

  List<StatsBarPoint> _monthlyPoints(
    BuildContext context,
    StatisticsHabitDetailSummary detail,
  ) {
    final l10n = context.l10n;
    final totals = <int, int>{};
    final days = detail.range.days;

    for (var index = 0; index < days.length; index++) {
      final month = days[index].month;
      totals[month] = (totals[month] ?? 0) + detail.dailyValues[index];
    }

    final orderedMonths = totals.keys.toList(growable: false);
    return List<StatsBarPoint>.generate(orderedMonths.length, (index) {
      final month = orderedMonths[index];
      return StatsBarPoint(
        label: l10n.monthShort(month),
        value: (totals[month] ?? 0).toDouble(),
        isActive: index == orderedMonths.length - 1,
      );
    });
  }

  String _chartSubtitle(BuildContext context, StatisticsPeriod period) {
    final l10n = context.l10n;
    switch (period) {
      case StatisticsPeriod.week:
        return l10n.statisticsV2DetailChartSubtitleWeek;
      case StatisticsPeriod.month:
        return l10n.statisticsV2DetailChartSubtitleMonth;
      case StatisticsPeriod.year:
        return l10n.statisticsV2DetailChartSubtitleYear;
      case StatisticsPeriod.day:
        return l10n.statisticsV2DetailChartSubtitleWeek;
    }
  }

  StatisticsPeriod _normalizeDetailPeriod(StatisticsPeriod period) {
    if (period == StatisticsPeriod.day) {
      return StatisticsPeriod.week;
    }
    return period;
  }

  int _nextMilestone(int streak) {
    const milestones = [3, 7, 14, 21, 30, 60, 90, 120, 180, 365];
    for (final milestone in milestones) {
      if (streak < milestone) {
        return milestone;
      }
    }
    return streak + 30;
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final String insight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: StatsCardSurface.decoration(context),
      padding: StatsCardSurface.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsV2DetailInsightTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'DMSerifDisplay',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
