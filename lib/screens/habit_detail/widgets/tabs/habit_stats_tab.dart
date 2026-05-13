import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../stores/user_state_store.dart';
import '../../../../utils/app_theme.dart';
import '../../../../utils/family_theme.dart';

part 'habit_stats/habit_stats_comparison.dart';
part 'habit_stats/habit_stats_header.dart';
part 'habit_stats/habit_stats_helpers.dart';
part 'habit_stats/habit_stats_hero_card.dart';
part 'habit_stats/habit_stats_insight_card.dart';
part 'habit_stats/habit_stats_last_7_days.dart';
part 'habit_stats/habit_stats_metric_grid.dart';
part 'habit_stats/habit_stats_models.dart';
part 'habit_stats/habit_stats_period_selector.dart';

enum _HabitStatsPeriod { week, month, year }

class HabitStatsTab extends StatefulWidget {
  const HabitStatsTab({
    super.key,
    required this.habit,
    required this.familyColor,
    this.scrollable = true,
    this.showHeader = true,
    this.onMorePressed,
  });

  final dynamic habit;
  final Color familyColor;
  final bool scrollable;
  final bool showHeader;
  final VoidCallback? onMorePressed;

  @override
  State<HabitStatsTab> createState() => _HabitStatsTabState();
}

class _HabitStatsTabState extends State<HabitStatsTab> {
  _HabitStatsPeriod _period = _HabitStatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<UserStateStore>();
    final habit = _habitMap(widget.habit);
    final history = _historyRoot(store.state);
    final familyId = _familyId(habit);
    final familyColor = FamilyTheme.colorOf(familyId);
    final habitId = _habitId(habit);
    final weekStartsOn = _weekStartsOn(habit);
    final today = _dateOnly(DateTime.now());

    final periodRange = _rangeForPeriod(
      _period,
      today: today,
      weekStartsOn: weekStartsOn,
    );
    final last7Days = List<DateTime>.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );
    final last7Rows = last7Days
        .map(
          (date) => _DayRow(
            date: date,
            skipped: _isSkippedOnDay(
              history: history,
              habitId: habitId,
              day: date,
            ),
            checkCompleted: _isCheckCompletedOnDay(
              history: history,
              habitId: habitId,
              day: date,
            ),
            countValue: _countValueOnDay(
              history: history,
              habitId: habitId,
              day: date,
            ),
          ),
        )
        .toList(growable: false);

    final isCount = _isCountHabit(habit);
    final countTarget = _countTarget(habit);

    final currentStreak = _currentStreak(
      store: store,
      history: history,
      habit: habit,
      habitId: habitId,
      today: today,
      countTarget: countTarget,
    );

    final headline = _headline(
      l10n: l10n,
      habit: habit,
      familyId: familyId,
      isCount: isCount,
      countTarget: countTarget,
    );

    final bestMoment = _bestMoment(
      history: history,
      habitId: habitId,
      start: periodRange.start,
      end: periodRange.end,
      l10n: l10n,
    );

    final weeklyRange = _DateRange(
      _weekStartForDate(today, weekStartsOn: weekStartsOn),
      today,
    );
    final previousWeeklyRange = _DateRange(
      weeklyRange.start.subtract(const Duration(days: 7)),
      weeklyRange.start.subtract(const Duration(days: 1)),
    );

    final checkPeriodStats = isCount
        ? null
        : _computeCheckStats(
            habit: habit,
            history: history,
            habitId: habitId,
            range: periodRange,
            weekStartsOn: weekStartsOn,
            countTarget: countTarget,
          );
    final checkWeekStats = isCount
        ? null
        : _computeCheckStats(
            habit: habit,
            history: history,
            habitId: habitId,
            range: weeklyRange,
            weekStartsOn: weekStartsOn,
            countTarget: countTarget,
          );
    final checkPreviousWeekStats = isCount
        ? null
        : _computeCheckStats(
            habit: habit,
            history: history,
            habitId: habitId,
            range: previousWeeklyRange,
            weekStartsOn: weekStartsOn,
            countTarget: countTarget,
          );

    final countPeriodStats = isCount
        ? _computeCountStats(
            history: history,
            habitId: habitId,
            range: periodRange,
            target: countTarget,
          )
        : null;
    final countWeekStats = isCount
        ? _computeCountStats(
            history: history,
            habitId: habitId,
            range: weeklyRange,
            target: countTarget,
          )
        : null;
    final countPreviousWeekStats = isCount
        ? _computeCountStats(
            history: history,
            habitId: habitId,
            range: previousWeeklyRange,
            target: countTarget,
          )
        : null;

    final completionScore = isCount
        ? (countPeriodStats?.completionPct ?? 0)
        : (checkPeriodStats?.consistencyPct ?? 0);
    final insight = _insightText(
      l10n: l10n,
      isCount: isCount,
      score: completionScore,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          _TopHeader(
            title: _title(habit, l10n),
            subtitle: headline,
            familyColor: familyColor,
            onBack: () => Navigator.of(context).maybePop(),
            onMorePressed: widget.onMorePressed,
          ),
          const SizedBox(height: 18),
        ],
        _PeriodSelector(
          selected: _period,
          onChanged: (value) => setState(() => _period = value),
          weekText: l10n.habitStatsPeriodWeek,
          monthText: l10n.habitStatsPeriodMonth,
          yearText: l10n.habitStatsPeriodYear,
        ),
        const SizedBox(height: 18),
        _HeroCard(
          title: l10n.habitStatsTabCurrentStreakTitle,
          streakDays: currentStreak,
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.habitStatsTabLastDaysTitle(7),
          child: isCount
              ? _CountLast7Chart(
                  key: const ValueKey('habit-stats-last7-count'),
                  rows: last7Rows,
                  unit: _localizedUnit(l10n, _unit(habit)),
                  target: countTarget,
                  l10n: l10n,
                )
              : _CheckLast7Indicators(
                  key: const ValueKey('habit-stats-last7-check'),
                  rows: last7Rows,
                  l10n: l10n,
                ),
        ),
        const SizedBox(height: 14),
        isCount
            ? _CountMetricsGrid(
                l10n: l10n,
                target: countTarget,
                unit: _localizedUnit(l10n, _unit(habit)),
                periodStats: countPeriodStats ?? const _CountStats.empty(),
              )
            : _CheckMetricsGrid(
                l10n: l10n,
                habit: habit,
                periodStats: checkPeriodStats ?? const _CheckStats.empty(),
                weekStats: checkWeekStats ?? const _CheckStats.empty(),
                bestMoment: bestMoment,
              ),
        const SizedBox(height: 14),
        isCount
            ? _CountComparisonCard(
                l10n: l10n,
                last7Rows: last7Rows,
                unit: _localizedUnit(l10n, _unit(habit)),
                thisWeek: countWeekStats ?? const _CountStats.empty(),
                previousWeek:
                    countPreviousWeekStats ?? const _CountStats.empty(),
              )
            : _CheckComparisonCard(
                l10n: l10n,
                thisWeek: checkWeekStats ?? const _CheckStats.empty(),
                previousWeek:
                    checkPreviousWeekStats ?? const _CheckStats.empty(),
              ),
        const SizedBox(height: 12),
        _InsightCard(
          title: l10n.habitStatsIndividualInsightTitle,
          text: insight,
        ),
      ],
    );

    return Container(
      color: AppColors.cream,
      child: SafeArea(
        top: widget.showHeader,
        bottom: !widget.scrollable,
        child: widget.scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: content,
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: content,
              ),
      ),
    );
  }
}
