import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_period.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/family_theme.dart';

const String _noFamilyKey = '__no_family__';
const Color _noFamilyColor = Color(0xFF8D847A);
const String _noFamilyEmoji = '•';

StatisticsV3ViewData buildStatisticsV3ViewData({
  required UserStateStore store,
  required StatisticsV3Period period,
  required AppLocalizations l10n,
  DateTime? now,
}) {
  final today = _dateOnly((now ?? DateTime.now()).toLocal());
  final periodRange = _currentPeriodRange(period, today: today);

  final root = _map(store.state);
  final userState = _map(root['userState']);
  final history = _map(userState['history']);
  final daily = _map(userState['daily']);

  final completionsRoot = _map(history['habitCompletions']);
  final completionTimesRoot = _map(history['habitCompletionTimes']);
  final skipsRoot = _map(history['habitSkips']);
  final countValuesRoot = _map(history['habitCountValues']);
  final habits = store.activeHabits;

  final habitsById = <String, Map<String, dynamic>>{};
  for (final habit in habits) {
    final id = _habitId(habit);
    if (id.isEmpty) continue;
    habitsById[id] = habit;
  }

  final completedByFamily = <String, int>{};
  final completedByHabit = <String, int>{};
  final completionsByMoment = <_MomentBucket, int>{
    _MomentBucket.morning: 0,
    _MomentBucket.noon: 0,
    _MomentBucket.afternoon: 0,
    _MomentBucket.night: 0,
  };

  var completedExpectedHabitInstances = 0;
  var timestampedCompletions = 0;

  for (final day in periodRange.days) {
    final dayKey = _dateKey(day);
    final dayCompletionTimes = _map(completionTimesRoot[dayKey]);
    final dayStats = _buildDayCompletionStats(
      day: day,
      today: today,
      dayKey: dayKey,
      userState: userState,
      completionsRoot: completionsRoot,
      skipsRoot: skipsRoot,
      countValuesRoot: countValuesRoot,
      habits: habits,
      habitsById: habitsById,
    );
    for (final habitId in dayStats.completedExpectedHabitIds) {
      completedExpectedHabitInstances += 1;
      completedByHabit[habitId] = (completedByHabit[habitId] ?? 0) + 1;

      final familyKey = _familyGroupKey(habitsById[habitId]);
      completedByFamily[familyKey] = (completedByFamily[familyKey] ?? 0) + 1;

      final epochMillis = _safeInt(dayCompletionTimes[habitId], fallback: 0);
      if (epochMillis <= 0) continue;

      final completedAt =
          DateTime.fromMillisecondsSinceEpoch(epochMillis).toLocal();
      final bucket = _bucketForHour(completedAt.hour);
      completionsByMoment[bucket] = (completionsByMoment[bucket] ?? 0) + 1;
      timestampedCompletions += 1;
    }
  }

  final topFamilies = completedByFamily.entries.toList(growable: false)
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.compareTo(b.key);
    });

  final families = topFamilies.take(4).map((entry) {
    final key = entry.key;
    if (key == _noFamilyKey) {
      return StatisticsV3FamilyItem(
        name: l10n.statisticsV3NoFamily,
        emoji: _noFamilyEmoji,
        color: _noFamilyColor,
        completedCount: entry.value,
      );
    }

    return StatisticsV3FamilyItem(
      name: l10n.familyName(key),
      emoji: FamilyTheme.emojiOf(key),
      color: FamilyTheme.colorOf(key),
      completedCount: entry.value,
    );
  }).toList(growable: false);

  final highlightedHabits = completedByHabit.entries.toList(growable: false)
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      final habitA = habitsById[a.key];
      final habitB = habitsById[b.key];
      final nameA =
          _habitName(habitA, fallback: l10n.habitStatsHabitFallbackTitle)
              .toLowerCase();
      final nameB =
          _habitName(habitB, fallback: l10n.habitStatsHabitFallbackTitle)
              .toLowerCase();
      return nameA.compareTo(nameB);
    });

  final highlightedItems = highlightedHabits.take(3).map((entry) {
    final habit = habitsById[entry.key];
    return StatisticsV3HighlightedHabitItem(
      habitId: entry.key,
      name: _habitName(habit, fallback: l10n.habitStatsHabitFallbackTitle),
      emoji: _habitEmoji(habit),
      completedCount: entry.value,
    );
  }).toList(growable: false);

  final bestMoment = _buildBestMomentInsight(
    l10n: l10n,
    completionsByMoment: completionsByMoment,
    timestampedCompletions: timestampedCompletions,
  );

  final periodStats = _buildPeriodConsistencyStats(
    start: periodRange.start,
    end: periodRange.end,
    today: today,
    userState: userState,
    completionsRoot: completionsRoot,
    skipsRoot: skipsRoot,
    countValuesRoot: countValuesRoot,
    habits: habits,
    habitsById: habitsById,
  );
  final totalExpectedHabitInstances = math.max(periodStats.expectedCount, 0);
  final totalCompletedHabitInstances = math.max(periodStats.completedCount, 0);
  final consistencyPct = totalExpectedHabitInstances == 0
      ? 0
      : ((totalCompletedHabitInstances / totalExpectedHabitInstances) * 100)
          .round();

  final xpGained = period == StatisticsV3Period.day
      ? _safeInt(daily['xpEarnedToday'], fallback: 0).clamp(0, 1 << 30)
      : 0;
  final amberGained = period == StatisticsV3Period.day
      ? _safeInt(daily['coinsEarnedToday'], fallback: 0).clamp(0, 1 << 30)
      : 0;
  final weeklyActivity = period == StatisticsV3Period.week
      ? _buildWeeklyActivityData(
          today: today,
          userState: userState,
          completionsRoot: completionsRoot,
          skipsRoot: skipsRoot,
          countValuesRoot: countValuesRoot,
          habits: habits,
          habitsById: habitsById,
        )
      : const <StatisticsV3WeeklyActivityDay>[];
  final monthlyCalendarDays = _buildMonthlyCalendarData(
    today: today,
    userState: userState,
    completionsRoot: completionsRoot,
    skipsRoot: skipsRoot,
    countValuesRoot: countValuesRoot,
    habits: habits,
    habitsById: habitsById,
  );
  final yearlyConsistencyMonths = period == StatisticsV3Period.year
      ? _buildYearlyConsistencyData(
          today: today,
          userState: userState,
          completionsRoot: completionsRoot,
          skipsRoot: skipsRoot,
          countValuesRoot: countValuesRoot,
          habits: habits,
          habitsById: habitsById,
        )
      : const <StatisticsV3YearlyConsistencyMonth>[];
  final weeklyImprovement = _buildWeeklyImprovementData(
    today: today,
    userState: userState,
    completionsRoot: completionsRoot,
    skipsRoot: skipsRoot,
    countValuesRoot: countValuesRoot,
    habits: habits,
    habitsById: habitsById,
  );

  // TODO: Add reliable per-period XP/Amber history once local data stores it.
  return StatisticsV3ViewData(
    totalDays: totalExpectedHabitInstances,
    completedHabits: totalCompletedHabitInstances,
    xpGained: xpGained,
    amberGained: amberGained,
    activeDays: completedExpectedHabitInstances,
    consistencyPct: consistencyPct.clamp(0, 100),
    families: families,
    bestMoment: bestMoment,
    highlightedHabits: highlightedItems,
    weeklyActivity: weeklyActivity,
    monthlyCalendarDays: monthlyCalendarDays,
    yearlyConsistencyMonths: yearlyConsistencyMonths,
    weeklyImprovement: weeklyImprovement,
  );
}

List<StatisticsV3HabitListItem> buildStatisticsV3HabitListData({
  required UserStateStore store,
  required AppLocalizations l10n,
  DateTime? now,
}) {
  final today = _dateOnly((now ?? DateTime.now()).toLocal());
  final root = _map(store.state);
  final userState = _map(root['userState']);
  final history = _map(userState['history']);
  final completionsRoot = _map(history['habitCompletions']);
  final skipsRoot = _map(history['habitSkips']);
  final countValuesRoot = _map(history['habitCountValues']);
  final habits = store.activeHabits;

  final habitsById = <String, Map<String, dynamic>>{};
  for (final habit in habits) {
    final id = _habitId(habit);
    if (id.isEmpty) continue;
    habitsById[id] = habit;
  }

  final windowStart = today.subtract(const Duration(days: 6));
  final expectedByDay = <String, Set<String>>{};
  final completedByDay = <String, Set<String>>{};
  for (var offset = 0; offset < 7; offset++) {
    final day = windowStart.add(Duration(days: offset));
    final dayKey = _dateKey(day);
    expectedByDay[dayKey] = _expectedHabitIdsForDay(
      day: day,
      today: today,
      dayKey: dayKey,
      userState: userState,
      skipsRoot: skipsRoot,
      habits: habits,
    );
    completedByDay[dayKey] = _completedHabitIdsForDay(
      day: day,
      today: today,
      dayKey: dayKey,
      userState: userState,
      completionsRoot: completionsRoot,
      skipsRoot: skipsRoot,
      countValuesRoot: countValuesRoot,
      habits: habits,
      habitsById: habitsById,
    );
  }

  final items = <StatisticsV3HabitListItem>[];
  for (final habit in habits) {
    if (_isArchivedHabit(habit)) continue;

    final habitId = _habitId(habit);
    if (habitId.isEmpty) continue;
    final title =
        _habitName(habit, fallback: l10n.habitStatsHabitFallbackTitle);
    final familyId = _habitListFamilyId(habit);
    final familyName = familyId == _noFamilyKey
        ? l10n.statisticsV3NoFamily
        : l10n.familyName(familyId);
    final familyColor = familyId == _noFamilyKey
        ? _noFamilyColor
        : FamilyTheme.colorOf(familyId);
    final emoji = _habitListEmoji(habit, familyId: familyId);
    final isCount = _isCountHabit(habit);
    final isTimesPerWeek = _isTimesPerWeekCheckHabit(habit);
    final streak = store.habitStreakSnapshotForHabitId(habitId).currentStreak;

    if (isCount) {
      final weekStart = _startOfWeek(today);
      final total = _sumCountHabitValueInRange(
        habit: habit,
        habitId: habitId,
        from: weekStart,
        to: today,
        today: today,
        userState: userState,
        countValuesRoot: countValuesRoot,
        skipsRoot: skipsRoot,
      );
      final unit = _habitUnitForMetrics(habit, l10n: l10n);
      final mainMetric = l10n.statisticsV3HabitListMainCountWeek(
        _formatHabitMetricValue(total),
        unit,
      );
      final avgPerDay = total / 7;
      final secondaryMetric = l10n.statisticsV3HabitListAvgPerDay(
        _formatHabitMetricValue(avgPerDay, keepTrailingZero: true),
        unit,
      );

      items.add(
        StatisticsV3HabitListItem(
          habitId: habitId,
          habit: habit,
          title: title,
          emoji: emoji,
          familyId: familyId,
          familyName: familyName,
          familyColor: familyColor,
          mainMetric: mainMetric,
          secondaryMetric: secondaryMetric,
          metricKind: StatisticsV3HabitListMetricKind.count,
        ),
      );
      continue;
    }

    if (isTimesPerWeek) {
      final target = _timesPerWeekTargetOf(habit);
      final weekStart = _weekStartForDate(
        today,
        weekStartsOn: _timesPerWeekWeekStartsOn(habit),
      );
      final completed = _completedCountForHabitInWeek(
        habit: habit,
        habitId: habitId,
        weekStart: weekStart,
        today: today,
        userState: userState,
        completionsRoot: completionsRoot,
        skipsRoot: skipsRoot,
      );
      final clampedCompleted = math.min(completed, target);
      final mainMetric =
          l10n.statisticsV3HabitListMainTimesPerWeek(clampedCompleted, target);
      final secondaryMetric = l10n.statisticsV3HabitListStreakDays(streak);

      items.add(
        StatisticsV3HabitListItem(
          habitId: habitId,
          habit: habit,
          title: title,
          emoji: emoji,
          familyId: familyId,
          familyName: familyName,
          familyColor: familyColor,
          mainMetric: mainMetric,
          secondaryMetric: secondaryMetric,
          metricKind: StatisticsV3HabitListMetricKind.timesPerWeekCheck,
        ),
      );
      continue;
    }

    var expected = 0;
    var completed = 0;
    for (var offset = 0; offset < 7; offset++) {
      final day = windowStart.add(Duration(days: offset));
      final dayKey = _dateKey(day);
      if (expectedByDay[dayKey]?.contains(habitId) == true) {
        expected += 1;
      }
      if (completedByDay[dayKey]?.contains(habitId) == true) {
        completed += 1;
      }
    }
    final safeExpected = expected > 0 ? expected : 7;
    final percentage = safeExpected == 0
        ? 0
        : ((completed / safeExpected) * 100).round().clamp(0, 100);

    items.add(
      StatisticsV3HabitListItem(
        habitId: habitId,
        habit: habit,
        title: title,
        emoji: emoji,
        familyId: familyId,
        familyName: familyName,
        familyColor: familyColor,
        mainMetric: l10n.statisticsV3HabitListMainDaysPercent(
          completed,
          safeExpected,
          percentage,
        ),
        secondaryMetric: l10n.statisticsV3HabitListStreakDays(streak),
        metricKind: StatisticsV3HabitListMetricKind.check,
      ),
    );
  }

  items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  return items;
}

StatisticsV3WeeklyImprovementData _buildWeeklyImprovementData({
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
  required Map<String, dynamic> countValuesRoot,
  required List<Map<String, dynamic>> habits,
  required Map<String, Map<String, dynamic>> habitsById,
}) {
  final currentWeekStart = _startOfWeek(today);
  final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
  final previousWeekEnd = currentWeekStart.subtract(const Duration(days: 1));

  final currentWeekStats = _buildPeriodConsistencyStats(
    start: currentWeekStart,
    end: today,
    today: today,
    userState: userState,
    completionsRoot: completionsRoot,
    skipsRoot: skipsRoot,
    countValuesRoot: countValuesRoot,
    habits: habits,
    habitsById: habitsById,
  );
  final previousWeekStats = _buildPeriodConsistencyStats(
    start: previousWeekStart,
    end: previousWeekEnd,
    today: today,
    userState: userState,
    completionsRoot: completionsRoot,
    skipsRoot: skipsRoot,
    countValuesRoot: countValuesRoot,
    habits: habits,
    habitsById: habitsById,
  );

  if (previousWeekStats.expectedCount <= 0) {
    return StatisticsV3WeeklyImprovementData(
      hasComparison: false,
      currentWeekPercentage: currentWeekStats.percentage,
      previousWeekPercentage: previousWeekStats.percentage,
      deltaPercentage: 0,
    );
  }

  return StatisticsV3WeeklyImprovementData(
    hasComparison: true,
    currentWeekPercentage: currentWeekStats.percentage,
    previousWeekPercentage: previousWeekStats.percentage,
    deltaPercentage: currentWeekStats.percentage - previousWeekStats.percentage,
  );
}

_PeriodConsistencyStats _buildPeriodConsistencyStats({
  required DateTime start,
  required DateTime end,
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
  required Map<String, dynamic> countValuesRoot,
  required List<Map<String, dynamic>> habits,
  required Map<String, Map<String, dynamic>> habitsById,
}) {
  final from = _dateOnly(start);
  final to = _dateOnly(end);
  if (to.isBefore(from)) {
    return const _PeriodConsistencyStats(
      expectedCount: 0,
      completedCount: 0,
      percentage: 0,
    );
  }

  var expectedCount = 0;
  var completedCount = 0;
  final days = to.difference(from).inDays + 1;
  for (var index = 0; index < days; index++) {
    final day = from.add(Duration(days: index));
    final dayKey = _dateKey(day);
    final dayStats = _buildDayCompletionStats(
      day: day,
      today: today,
      dayKey: dayKey,
      userState: userState,
      completionsRoot: completionsRoot,
      skipsRoot: skipsRoot,
      countValuesRoot: countValuesRoot,
      habits: habits,
      habitsById: habitsById,
    );
    expectedCount += dayStats.expectedCount;
    completedCount += dayStats.completedCount;
  }
  final timesPerWeekContribution = _buildTimesPerWeekContribution(
    from: from,
    to: to,
    today: today,
    userState: userState,
    completionsRoot: completionsRoot,
    skipsRoot: skipsRoot,
    habits: habits,
  );
  expectedCount += timesPerWeekContribution.expectedCount;
  completedCount += timesPerWeekContribution.completedCount;

  final percentage = expectedCount == 0
      ? 0
      : ((completedCount / expectedCount) * 100).round().clamp(0, 100);
  return _PeriodConsistencyStats(
    expectedCount: expectedCount,
    completedCount: completedCount,
    percentage: percentage,
  );
}

_ExpectedCompletedCounts _buildTimesPerWeekContribution({
  required DateTime from,
  required DateTime to,
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
  required List<Map<String, dynamic>> habits,
}) {
  if (_dateOnly(from) == _dateOnly(to)) {
    return const _ExpectedCompletedCounts(
      expectedCount: 0,
      completedCount: 0,
    );
  }

  var expectedCount = 0;
  var completedCount = 0;
  final isCompactWeekWindow = to.difference(from).inDays < 7;

  for (final habit in habits) {
    if (!_isTimesPerWeekCheckHabit(habit)) continue;
    if (_isArchivedHabit(habit)) continue;

    final habitId = _habitId(habit);
    if (habitId.isEmpty) continue;

    final target = _timesPerWeekTargetOf(habit);
    final weekStartsOn = _timesPerWeekWeekStartsOn(habit);

    if (isCompactWeekWindow) {
      if (!_wasHabitCreatedByDay(habit, to)) continue;

      final weekStart = _weekStartForDate(to, weekStartsOn: weekStartsOn);
      expectedCount += target;
      final completedInWeek = _completedCountForHabitInWeek(
        habit: habit,
        habitId: habitId,
        weekStart: weekStart,
        today: today,
        userState: userState,
        completionsRoot: completionsRoot,
        skipsRoot: skipsRoot,
      );
      completedCount += math.min(completedInWeek, target);
      continue;
    }

    final includedWeekStarts = <String>{};
    final totalDays = to.difference(from).inDays + 1;

    for (var index = 0; index < totalDays; index++) {
      final day = from.add(Duration(days: index));
      if (!_wasHabitCreatedByDay(habit, day)) continue;

      final weekStart = _weekStartForDate(day, weekStartsOn: weekStartsOn);
      final weekKey = _dateKey(weekStart);
      if (!includedWeekStarts.add(weekKey)) continue;

      expectedCount += target;
      final completedInWeek = _completedCountForHabitInWeek(
        habit: habit,
        habitId: habitId,
        weekStart: weekStart,
        today: today,
        userState: userState,
        completionsRoot: completionsRoot,
        skipsRoot: skipsRoot,
      );
      completedCount += math.min(completedInWeek, target);
    }
  }

  return _ExpectedCompletedCounts(
    expectedCount: expectedCount,
    completedCount: completedCount,
  );
}

String _habitListFamilyId(Map<String, dynamic> habit) {
  final familyId = (habit['familyId'] ?? habit['family'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  if (familyId.isEmpty || !FamilyTheme.colors.containsKey(familyId)) {
    return _noFamilyKey;
  }
  return familyId;
}

String _habitListEmoji(
  Map<String, dynamic> habit, {
  required String familyId,
}) {
  final habitEmoji = (habit['emoji'] ?? '').toString().trim();
  if (habitEmoji.isNotEmpty) return habitEmoji;
  if (familyId == _noFamilyKey) return _habitEmoji(habit);
  return FamilyTheme.emojiOf(familyId);
}

String _habitUnitForMetrics(
  Map<String, dynamic> habit, {
  required AppLocalizations l10n,
}) {
  final raw = (habit['unit'] ?? habit['unitLabel'] ?? habit['units'] ?? '')
      .toString()
      .trim();
  if (raw.isEmpty) return l10n.unitTimesShort;
  return l10n.habitUnitLabel(raw);
}

String _formatHabitMetricValue(
  num value, {
  int fractionDigits = 1,
  bool keepTrailingZero = false,
}) {
  if (!value.isFinite) return '0';

  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.0001) {
    if (keepTrailingZero && fractionDigits > 0) {
      return rounded.toStringAsFixed(fractionDigits);
    }
    return rounded.toInt().toString();
  }

  final fixed = value.toStringAsFixed(fractionDigits);
  if (keepTrailingZero) return fixed;
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

num _sumCountHabitValueInRange({
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime from,
  required DateTime to,
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> countValuesRoot,
  required Map<String, dynamic> skipsRoot,
}) {
  final start = _dateOnly(from);
  final end = _dateOnly(to);
  if (end.isBefore(start)) return 0;

  var total = 0.0;
  final dayCount = end.difference(start).inDays + 1;
  for (var index = 0; index < dayCount; index++) {
    final day = start.add(Duration(days: index));
    total += _countHabitValueForDay(
      habit: habit,
      habitId: habitId,
      day: day,
      today: today,
      userState: userState,
      countValuesRoot: countValuesRoot,
      skipsRoot: skipsRoot,
    );
  }
  return total;
}

double _countHabitValueForDay({
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime day,
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> countValuesRoot,
  required Map<String, dynamic> skipsRoot,
}) {
  final dayKey = _dateKey(day);
  final daySkips = _map(skipsRoot[dayKey]);
  if (_isDone(daySkips[habitId])) return 0;

  final dayCountValues = _map(countValuesRoot[dayKey]);
  final historyValue =
      _safeNum(dayCountValues[habitId], fallback: 0).toDouble();
  final useCurrentHabitState = dayKey == _dateKey(today) &&
      _activeViewDateKey(userState, fallbackKey: dayKey) == dayKey;
  if (!useCurrentHabitState) {
    return historyValue < 0 ? 0 : historyValue;
  }

  if (_isDone(habit['skippedToday'])) return 0;
  final current = _safeNum(
    habit['progress'] ?? habit['current'] ?? habit['value'],
    fallback: historyValue,
  ).toDouble();
  return current < 0 ? 0 : current;
}

int _completedCountForHabitInWeek({
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime weekStart,
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
}) {
  var completed = 0;
  for (var offset = 0; offset < 7; offset++) {
    final day = weekStart.add(Duration(days: offset));
    if (!_wasHabitCreatedByDay(habit, day)) continue;
    if (_isTimesPerWeekCompletedOnDay(
      habit: habit,
      habitId: habitId,
      day: day,
      today: today,
      userState: userState,
      completionsRoot: completionsRoot,
      skipsRoot: skipsRoot,
    )) {
      completed += 1;
    }
  }
  return completed;
}

bool _isTimesPerWeekCompletedOnDay({
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime day,
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
}) {
  final dayKey = _dateKey(day);
  final dayCompletions = _map(completionsRoot[dayKey]);
  final daySkips = _map(skipsRoot[dayKey]);
  if (_isDone(daySkips[habitId])) return false;

  var completed = _isDone(dayCompletions[habitId]);
  final useCurrentHabitState = dayKey == _dateKey(today) &&
      _activeViewDateKey(userState, fallbackKey: dayKey) == dayKey;
  if (!useCurrentHabitState) return completed;

  if (_isDone(habit['skippedToday'])) return false;
  completed = _isCurrentHabitDone(habit);
  return completed;
}

List<StatisticsV3WeeklyActivityDay> _buildWeeklyActivityData({
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
  required Map<String, dynamic> countValuesRoot,
  required List<Map<String, dynamic>> habits,
  required Map<String, Map<String, dynamic>> habitsById,
}) {
  final weekStart = _startOfWeek(today);

  return List<StatisticsV3WeeklyActivityDay>.generate(7, (index) {
    final day = weekStart.add(Duration(days: index));
    final dayKey = _dateKey(day);
    final isToday = _dateOnly(day) == _dateOnly(today);
    final isFuture = day.isAfter(today);

    if (isFuture) {
      return StatisticsV3WeeklyActivityDay(
        date: day,
        completedCount: 0,
        expectedCount: 0,
        percentage: 0,
        isToday: isToday,
        isFuture: true,
      );
    }

    final dayStats = _buildDayCompletionStats(
      day: day,
      today: today,
      dayKey: dayKey,
      userState: userState,
      completionsRoot: completionsRoot,
      skipsRoot: skipsRoot,
      countValuesRoot: countValuesRoot,
      habits: habits,
      habitsById: habitsById,
    );

    return StatisticsV3WeeklyActivityDay(
      date: day,
      completedCount: dayStats.completedCount,
      expectedCount: dayStats.expectedCount,
      percentage: dayStats.percentage,
      isToday: isToday,
      isFuture: false,
    );
  }, growable: false);
}

List<StatisticsV3MonthlyCalendarDay> _buildMonthlyCalendarData({
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
  required Map<String, dynamic> countValuesRoot,
  required List<Map<String, dynamic>> habits,
  required Map<String, Map<String, dynamic>> habitsById,
}) {
  final firstDayOfMonth = DateTime(today.year, today.month, 1);
  final daysInMonth = DateUtils.getDaysInMonth(today.year, today.month);

  return List<StatisticsV3MonthlyCalendarDay>.generate(daysInMonth, (index) {
    final day = firstDayOfMonth.add(Duration(days: index));
    final dayKey = _dateKey(day);
    final isToday = _dateOnly(day) == _dateOnly(today);
    final isFuture = day.isAfter(today);
    final isCurrentMonth = day.year == today.year && day.month == today.month;

    if (isFuture) {
      return StatisticsV3MonthlyCalendarDay(
        date: day,
        completedCount: 0,
        expectedCount: 0,
        percentage: 0,
        isToday: isToday,
        isFuture: true,
        isCurrentMonth: isCurrentMonth,
      );
    }

    final dayStats = _buildDayCompletionStats(
      day: day,
      today: today,
      dayKey: dayKey,
      userState: userState,
      completionsRoot: completionsRoot,
      skipsRoot: skipsRoot,
      countValuesRoot: countValuesRoot,
      habits: habits,
      habitsById: habitsById,
    );

    return StatisticsV3MonthlyCalendarDay(
      date: day,
      completedCount: dayStats.completedCount,
      expectedCount: dayStats.expectedCount,
      percentage: dayStats.percentage,
      isToday: isToday,
      isFuture: false,
      isCurrentMonth: isCurrentMonth,
    );
  }, growable: false);
}

List<StatisticsV3YearlyConsistencyMonth> _buildYearlyConsistencyData({
  required DateTime today,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
  required Map<String, dynamic> countValuesRoot,
  required List<Map<String, dynamic>> habits,
  required Map<String, Map<String, dynamic>> habitsById,
}) {
  final year = today.year;

  return List<StatisticsV3YearlyConsistencyMonth>.generate(12, (index) {
    final month = index + 1;
    final monthStart = DateTime(year, month, 1);
    final isCurrentMonth = month == today.month;
    final isFuture = monthStart.isAfter(today);

    if (isFuture) {
      return StatisticsV3YearlyConsistencyMonth(
        month: month,
        year: year,
        completedCount: 0,
        expectedCount: 0,
        percentage: 0,
        isCurrentMonth: false,
        isFuture: true,
      );
    }

    final monthEnd = isCurrentMonth
        ? today
        : DateTime(year, month, DateUtils.getDaysInMonth(year, month));
    final monthStats = _buildPeriodConsistencyStats(
      start: monthStart,
      end: monthEnd,
      today: today,
      userState: userState,
      completionsRoot: completionsRoot,
      skipsRoot: skipsRoot,
      countValuesRoot: countValuesRoot,
      habits: habits,
      habitsById: habitsById,
    );

    return StatisticsV3YearlyConsistencyMonth(
      month: month,
      year: year,
      completedCount: monthStats.completedCount,
      expectedCount: monthStats.expectedCount,
      percentage: monthStats.percentage,
      isCurrentMonth: isCurrentMonth,
      isFuture: false,
    );
  }, growable: false);
}

StatisticsV3BestMomentInsight _buildBestMomentInsight({
  required AppLocalizations l10n,
  required Map<_MomentBucket, int> completionsByMoment,
  required int timestampedCompletions,
}) {
  if (timestampedCompletions <= 0) {
    return const StatisticsV3BestMomentInsight(
      hasData: false,
      slot: StatisticsV3BestMomentSlot.morning,
      label: '',
      count: 0,
    );
  }

  final bestEntry = completionsByMoment.entries.reduce((current, next) {
    final byCount = next.value.compareTo(current.value);
    if (byCount > 0) return next;
    if (byCount < 0) return current;
    return current.key.priority <= next.key.priority ? current : next;
  });

  if (bestEntry.value <= 0) {
    return const StatisticsV3BestMomentInsight(
      hasData: false,
      slot: StatisticsV3BestMomentSlot.morning,
      label: '',
      count: 0,
    );
  }

  return StatisticsV3BestMomentInsight(
    hasData: true,
    slot: bestEntry.key.slot,
    label: bestEntry.key.localizedLabel(l10n),
    count: bestEntry.value,
  );
}

_PeriodRange _currentPeriodRange(
  StatisticsV3Period period, {
  required DateTime today,
}) {
  switch (period) {
    case StatisticsV3Period.day:
      return _PeriodRange(start: today, end: today);
    case StatisticsV3Period.week:
      return _PeriodRange(start: _startOfWeek(today), end: today);
    case StatisticsV3Period.month:
      return _PeriodRange(
          start: DateTime(today.year, today.month, 1), end: today);
    case StatisticsV3Period.year:
      return _PeriodRange(start: DateTime(today.year, 1, 1), end: today);
  }
}

DateTime _startOfWeek(DateTime date) {
  final day = _dateOnly(date);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime _weekStartForDate(DateTime day, {required int weekStartsOn}) {
  final normalizedDay = _dateOnly(day);
  final normalizedWeekStartsOn =
      weekStartsOn >= DateTime.monday && weekStartsOn <= DateTime.sunday
          ? weekStartsOn
          : DateTime.monday;
  final delta = (normalizedDay.weekday - normalizedWeekStartsOn + 7) % 7;
  return normalizedDay.subtract(Duration(days: delta));
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

int _safeInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse((value ?? '').toString().trim());
  return parsed ?? fallback;
}

bool _isDone(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value > 0;
  final normalized = (value ?? '').toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

Set<String> _completedHabitIdsForDay({
  required DateTime day,
  required DateTime today,
  required String dayKey,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
  required Map<String, dynamic> countValuesRoot,
  required List<Map<String, dynamic>> habits,
  required Map<String, Map<String, dynamic>> habitsById,
}) {
  final completedIds = <String>{};
  final dayCompletions = _map(completionsRoot[dayKey]);
  final daySkips = _map(skipsRoot[dayKey]);
  final dayCountValues = _map(countValuesRoot[dayKey]);

  for (final entry in dayCompletions.entries) {
    final habitId = entry.key.toString().trim();
    if (habitId.isEmpty || _isDone(daySkips[habitId])) continue;
    if (_isCountHabit(habitsById[habitId] ?? const <String, dynamic>{})) {
      continue;
    }
    if (_isDone(entry.value)) completedIds.add(habitId);
  }

  for (final entry in dayCountValues.entries) {
    final habitId = entry.key.toString().trim();
    if (habitId.isEmpty || _isDone(daySkips[habitId])) continue;

    final habit = habitsById[habitId];
    if (habit == null || !_isCountHabit(habit)) continue;

    final progress = _safeNum(entry.value, fallback: 0);
    final target = _safePositiveNum(habit['target'], fallback: 1);
    if (progress >= target) completedIds.add(habitId);
  }

  if (dayKey != _dateKey(today) ||
      _activeViewDateKey(userState, fallbackKey: dayKey) != dayKey) {
    return completedIds;
  }

  for (final habit in habits) {
    final habitId = _habitId(habit);
    if (habitId.isEmpty || !_isScheduledForDate(habit, day)) continue;

    if (_isDone(habit['skippedToday'])) {
      completedIds.remove(habitId);
      continue;
    }

    if (_isCurrentHabitDone(habit)) {
      completedIds.add(habitId);
    } else {
      completedIds.remove(habitId);
    }
  }

  return completedIds;
}

_DayCompletionStats _buildDayCompletionStats({
  required DateTime day,
  required DateTime today,
  required String dayKey,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> completionsRoot,
  required Map<String, dynamic> skipsRoot,
  required Map<String, dynamic> countValuesRoot,
  required List<Map<String, dynamic>> habits,
  required Map<String, Map<String, dynamic>> habitsById,
}) {
  final expectedHabitIds = _expectedHabitIdsForDay(
    day: day,
    today: today,
    dayKey: dayKey,
    userState: userState,
    skipsRoot: skipsRoot,
    habits: habits,
  );
  final completedHabitIds = _completedHabitIdsForDay(
    day: day,
    today: today,
    dayKey: dayKey,
    userState: userState,
    completionsRoot: completionsRoot,
    skipsRoot: skipsRoot,
    countValuesRoot: countValuesRoot,
    habits: habits,
    habitsById: habitsById,
  );

  final completedExpectedHabitIds =
      completedHabitIds.where(expectedHabitIds.contains).toSet();
  final expectedCount = expectedHabitIds.length;
  final completedCount = completedExpectedHabitIds.length;
  final percentage = expectedCount == 0
      ? 0
      : ((completedCount / expectedCount) * 100).round().clamp(0, 100);

  return _DayCompletionStats(
    completedExpectedHabitIds: completedExpectedHabitIds,
    expectedCount: expectedCount,
    completedCount: completedCount,
    percentage: percentage,
  );
}

Set<String> _expectedHabitIdsForDay({
  required DateTime day,
  required DateTime today,
  required String dayKey,
  required Map<String, dynamic> userState,
  required Map<String, dynamic> skipsRoot,
  required List<Map<String, dynamic>> habits,
}) {
  final expectedIds = <String>{};
  final daySkips = _map(skipsRoot[dayKey]);
  final useCurrentHabitState = dayKey == _dateKey(today) &&
      _activeViewDateKey(userState, fallbackKey: dayKey) == dayKey;

  for (final habit in habits) {
    final habitId = _habitId(habit);
    if (habitId.isEmpty) continue;
    if (_isArchivedHabit(habit)) continue;
    if (!_wasHabitCreatedByDay(habit, day)) continue;
    if (!_isScheduledForDate(habit, day)) continue;
    if (_isDone(daySkips[habitId])) continue;

    expectedIds.add(habitId);
  }

  if (!useCurrentHabitState) return expectedIds;

  for (final habit in habits) {
    final habitId = _habitId(habit);
    if (habitId.isEmpty) continue;
    if (_isArchivedHabit(habit)) {
      expectedIds.remove(habitId);
      continue;
    }
    if (!_isScheduledForDate(habit, day)) {
      expectedIds.remove(habitId);
      continue;
    }
    if (_isDone(daySkips[habitId])) {
      expectedIds.remove(habitId);
      continue;
    }
    if (_isDone(habit['skippedToday'])) {
      expectedIds.remove(habitId);
      continue;
    }
    if (_wasHabitCreatedByDay(habit, day)) {
      expectedIds.add(habitId);
    }
  }

  return expectedIds;
}

String _activeViewDateKey(
  Map<String, dynamic> userState, {
  required String fallbackKey,
}) {
  final meta = _map(userState['meta']);
  final key = (meta['activeViewDateKey'] ?? '').toString().trim();
  return key.isEmpty ? fallbackKey : key;
}

bool _isCurrentHabitDone(Map<String, dynamic> habit) {
  if (_isDone(habit['doneToday'])) return true;
  if (!_isCountHabit(habit)) return false;

  final progress = _safeNum(habit['progress'], fallback: 0);
  final target = _safePositiveNum(habit['target'], fallback: 1);
  return progress >= target;
}

bool _isArchivedHabit(Map<String, dynamic> habit) =>
    habit['archived'] == true || habit['isArchived'] == true;

bool _isCountHabit(Map<String, dynamic> habit) {
  final type =
      (habit['type'] ?? habit['trackingType'] ?? habit['habitType'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
  return type == 'count' || type == 'counter' || type == 'numeric';
}

bool _isTimesPerWeekCheckHabit(Map<String, dynamic> habit) {
  if (_isCountHabit(habit)) return false;
  final type = (habit['type'] ?? 'check').toString().trim().toLowerCase();
  if (type != 'check') return false;
  final schedule = _map(habit['schedule']);
  final scheduleType = (schedule['type'] ?? '').toString().trim().toLowerCase();
  return scheduleType == 'timesperweek';
}

int _timesPerWeekTargetOf(Map<String, dynamic> habit) {
  final schedule = _map(habit['schedule']);
  final target = _safeInt(
    schedule['timesPerWeek'] ??
        schedule['timesPerWeekTarget'] ??
        schedule['goal'] ??
        schedule['times'] ??
        habit['timesPerWeekTarget'] ??
        habit['goal'] ??
        habit['times'],
    fallback: 1,
  );
  return target < 1 ? 1 : target;
}

int _timesPerWeekWeekStartsOn(Map<String, dynamic> habit) {
  final schedule = _map(habit['schedule']);
  final raw = _safeInt(schedule['weekStartsOn'], fallback: DateTime.monday);
  if (raw < DateTime.monday || raw > DateTime.sunday) {
    return DateTime.monday;
  }
  return raw;
}

num _safeNum(dynamic value, {num fallback = 0}) {
  if (value is num) return value;
  final parsed = num.tryParse((value ?? '').toString().trim());
  return parsed ?? fallback;
}

num _safePositiveNum(dynamic value, {num fallback = 1}) {
  final parsed = _safeNum(value, fallback: fallback);
  return parsed > 0 ? parsed : fallback;
}

bool _wasHabitCreatedByDay(Map<String, dynamic> habit, DateTime day) {
  final createdAt = _parseHabitDate(
    habit['createdAt'] ??
        habit['created_at'] ??
        habit['createdDate'] ??
        habit['dateCreated'],
  );
  if (createdAt == null) return true;
  return !_dateOnly(createdAt.toLocal()).isAfter(_dateOnly(day));
}

DateTime? _parseHabitDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
  }

  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return parsed.toLocal();

  final dateKeyMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (dateKeyMatch == null) return null;

  return DateTime(
    int.parse(dateKeyMatch.group(1)!),
    int.parse(dateKeyMatch.group(2)!),
    int.parse(dateKeyMatch.group(3)!),
  );
}

bool _isScheduledForDate(Map<String, dynamic> habit, DateTime date) {
  final schedule = _map(habit['schedule']);
  final type = (schedule['type'] ?? 'daily').toString().trim().toLowerCase();

  if (type == 'once') {
    return (schedule['date'] ?? '').toString().trim() == _dateKey(date);
  }

  if (type == 'weekly') {
    final weekdays = schedule['weekdays'];
    if (weekdays is! List) return false;
    return weekdays
        .whereType<num>()
        .map((day) => day.toInt())
        .contains(date.weekday);
  }

  if (type == 'timesperweek') {
    return _isCountHabit(habit);
  }

  return true;
}

String _habitId(Map<String, dynamic> habit) {
  return (habit['id'] ??
          habit['habitId'] ??
          habit['uuid'] ??
          habit['key'] ??
          '')
      .toString()
      .trim();
}

String _habitName(
  Map<String, dynamic>? habit, {
  required String fallback,
}) {
  if (habit == null) return fallback;
  final raw = (habit['title'] ??
          habit['name'] ??
          habit['habitName'] ??
          habit['label'] ??
          '')
      .toString()
      .trim();
  return raw.isEmpty ? fallback : raw;
}

String _habitEmoji(Map<String, dynamic>? habit) {
  if (habit == null) return '✨';
  final emoji = (habit['emoji'] ?? '').toString().trim();
  return emoji.isEmpty ? '✨' : emoji;
}

String _familyGroupKey(Map<String, dynamic>? habit) {
  if (habit == null) return _noFamilyKey;
  final raw = (habit['familyId'] ?? habit['family'] ?? '').toString().trim();
  if (raw.isEmpty) return _noFamilyKey;
  if (!FamilyTheme.colors.containsKey(raw)) return _noFamilyKey;
  return raw;
}

_MomentBucket _bucketForHour(int hour) {
  if (hour >= 5 && hour <= 11) return _MomentBucket.morning;
  if (hour >= 12 && hour <= 14) return _MomentBucket.noon;
  if (hour >= 15 && hour <= 20) return _MomentBucket.afternoon;
  return _MomentBucket.night;
}

class _PeriodRange {
  const _PeriodRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  List<DateTime> get days {
    final from = _dateOnly(start);
    final to = _dateOnly(end);
    if (to.isBefore(from)) return const <DateTime>[];

    return List<DateTime>.generate(
      to.difference(from).inDays + 1,
      (index) => from.add(Duration(days: index)),
      growable: false,
    );
  }
}

enum _MomentBucket {
  morning(0),
  noon(1),
  afternoon(2),
  night(3);

  const _MomentBucket(this.priority);

  final int priority;

  StatisticsV3BestMomentSlot get slot {
    switch (this) {
      case _MomentBucket.morning:
        return StatisticsV3BestMomentSlot.morning;
      case _MomentBucket.noon:
        return StatisticsV3BestMomentSlot.noon;
      case _MomentBucket.afternoon:
        return StatisticsV3BestMomentSlot.afternoon;
      case _MomentBucket.night:
        return StatisticsV3BestMomentSlot.night;
    }
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case _MomentBucket.morning:
        return l10n.statisticsV3MomentMorning;
      case _MomentBucket.noon:
        return l10n.statisticsV3MomentAfternoon;
      case _MomentBucket.afternoon:
        return l10n.statisticsV3MomentEvening;
      case _MomentBucket.night:
        return l10n.statisticsV3MomentNight;
    }
  }
}

class _DayCompletionStats {
  const _DayCompletionStats({
    required this.completedExpectedHabitIds,
    required this.expectedCount,
    required this.completedCount,
    required this.percentage,
  });

  final Set<String> completedExpectedHabitIds;
  final int expectedCount;
  final int completedCount;
  final int percentage;
}

class _PeriodConsistencyStats {
  const _PeriodConsistencyStats({
    required this.expectedCount,
    required this.completedCount,
    required this.percentage,
  });

  final int expectedCount;
  final int completedCount;
  final int percentage;
}

class _ExpectedCompletedCounts {
  const _ExpectedCompletedCounts({
    required this.expectedCount,
    required this.completedCount,
  });

  final int expectedCount;
  final int completedCount;
}
