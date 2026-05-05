import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../stores/user_state_store.dart';
import '../../../../utils/family_theme.dart';
import '../../../../widgets/stats/helpers/stats_card_surface.dart';
import '../../../../widgets/stats/helpers/stats_number_formatter.dart';
import '../../../../widgets/stats/stats_count_cards.dart';
import '../../../../widgets/stats/stats_motivational_tip_card.dart';
import '../../../../widgets/stats/stats_weekly_bar_chart_card.dart';
import '../../../../widgets/stats/streak_hero_card.dart';
import '../../../../widgets/stats/weekly_comparison_card.dart';
import '../../application/adapters/statistics_data_adapter.dart';
import '../../domain/statistics_models.dart';
import '../../domain/statistics_period.dart';
import '../widgets/statistics_period_selector.dart';

class StatisticsHabitDetailPage extends StatefulWidget {
  const StatisticsHabitDetailPage({
    super.key,
    required this.habitId,
    this.initialPeriod = StatisticsPeriod.week,
  });

  final String habitId;
  final StatisticsPeriod initialPeriod;

  @override
  State<StatisticsHabitDetailPage> createState() =>
      _StatisticsHabitDetailPageState();
}

class _StatisticsHabitDetailPageState extends State<StatisticsHabitDetailPage> {
  StatisticsPeriod _period = StatisticsPeriod.week;
  final StatisticsDataAdapter _adapter = const StatisticsDataAdapter();

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final detail = _adapter.buildHabitDetail(
      store: store,
      habitId: widget.habitId,
      period: _period,
    );

    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de habito')),
        body: const Center(child: Text('No se encontro el habito.')),
      );
    }

    final habit = detail.habit;
    final familyColor = FamilyTheme.colorOf(habit.familyId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        title: Text(habit.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
          _headerCard(habit),
          const SizedBox(height: 12),
          StreakHeroCard(
            streakDays: habit.currentStreak,
            nextMilestoneDays: _nextMilestone(habit.currentStreak),
          ),
          const SizedBox(height: 12),
          StatsWeeklyBarChartCard(
            title: 'Ultimos 7 dias',
            subtitle: 'Tendencia de ejecucion',
            points: _last7ChartPoints(habit),
            accent: familyColor,
            valueFormatter: (value) => StatsNumberFormatter.compact1(value),
          ),
          const SizedBox(height: 12),
          WeeklyComparisonCard(
            thisWeekDays: detail.thisWeekDoneDays,
            lastWeekDays: detail.lastWeekDoneDays,
            accentColor: familyColor,
            asCard: true,
          ),
          if (habit.type == StatisticsHabitType.count &&
              habit.countProgress != null) ...[
            const SizedBox(height: 12),
            StatsCountObjectiveCard(
              goalCompletedDays: habit.countProgress!.goalCompletedDays,
              partialProgressDays: habit.countProgress!.partialProgressDays,
              compliancePct: habit.countProgress!.compliancePct,
              target: habit.target,
              accent: familyColor,
            ),
            const SizedBox(height: 12),
            StatsCountVolumeCard(
              totalAccumulated: habit.countProgress!.totalAccumulated,
              dailyAverage: habit.countProgress!.dailyAverage,
              activeDayAverage: habit.countProgress!.activeDayAverage,
              bestDay: habit.countProgress!.bestDay,
              activeDays: habit.countProgress!.activeDays,
            ),
          ],
          const SizedBox(height: 12),
          StatsMotivationalTipCard(
            habitTitle: habit.title,
            streakDays: habit.currentStreak,
            thisWeekDoneDays: detail.thisWeekDoneDays,
            lastWeekDoneDays: detail.lastWeekDoneDays,
            compliancePct: habit.countProgress?.compliancePct.round(),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: StatsCardSurface.decoration(context),
            padding: StatsCardSurface.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight dinamico',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  detail.insight,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard(StatisticsHabitSummary habit) {
    final familyColor = FamilyTheme.colorOf(habit.familyId);

    return Builder(
      builder: (context) => Container(
        decoration: StatsCardSurface.decoration(context),
        padding: StatsCardSurface.padding,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: familyColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                FamilyTheme.emojiOf(habit.familyId),
                style: const TextStyle(fontSize: 20),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${FamilyTheme.nameOf(habit.familyId)} · ${habit.type == StatisticsHabitType.count ? 'Count' : 'Check'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<StatsBarPoint> _last7ChartPoints(StatisticsHabitSummary habit) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final values = habit.last7Values;

    return List<StatsBarPoint>.generate(values.length, (index) {
      final chartIndex = values.length - 7 + index;
      final safeLabel = labels[chartIndex % 7];
      return StatsBarPoint(
        label: safeLabel,
        value: values[index].toDouble(),
        isActive: index == values.length - 1,
      );
    });
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
