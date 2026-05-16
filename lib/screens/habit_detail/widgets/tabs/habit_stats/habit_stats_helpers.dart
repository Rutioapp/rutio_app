import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../stores/user_state_store.dart';
import 'habit_stats_models.dart';

HabitStatsShellData buildHabitStatsShellData(
  BuildContext context,
  dynamic habit, {
  required HabitStatsPeriod period,
}) {
  final l10n = context.l10n;
  final habitMap = _habitToMap(habit);
  final habitId = _habitId(habitMap);
  final history = _extractHistoryFromStore(context);
  final countsByDay = _extractCountsByDay(
    habitMap: habitMap,
    habitId: habitId,
    completionsRoot: history.completionsRoot,
  );
  final countValuesByDay = _extractCountValuesByDay(
    habitMap: habitMap,
    habitId: habitId,
    countValuesRoot: history.countValuesRoot,
  );
  final skipsByDay = _extractSkipsByDay(
    habitId: habitId,
    skipsRoot: history.skipsRoot,
  );
  final completionTimesByDay = _extractCompletionTimesByDay(
    habitId: habitId,
    completionTimesRoot: history.completionTimesRoot,
  );

  final isCounter = _isCountHabit(habitMap);
  final familyName = _resolveFamilyName(l10n, habitMap['familyId']?.toString());
  final schedule = _map(habitMap['schedule']);
  final weekStartsOn = _weekStartsOn(schedule);
  final weekRange = _buildWeekRange(DateTime.now(), weekStartsOn);
  final previousWeekRange = _DateRange(
    start: weekRange.start.subtract(const Duration(days: 7)),
    end: weekRange.end.subtract(const Duration(days: 7)),
  );
  final weeklyTarget = _weeklyTarget(habitMap, schedule, isCounter: isCounter);
  final weeklyCompleted = _countCompletedDays(
    countsByDay: countsByDay,
    skipsByDay: skipsByDay,
    range: weekRange,
  );
  final previousWeekCompleted = _countCompletedDays(
    countsByDay: countsByDay,
    skipsByDay: skipsByDay,
    range: previousWeekRange,
  );
  final weeklyConsistencyPct = weeklyTarget <= 0
      ? 0
      : ((weeklyCompleted / weeklyTarget) * 100).round().clamp(0, 100);
  final weeklyComparisonDeltaPct = _weeklyComparisonDelta(
    countsByDay: countsByDay,
    skipsByDay: skipsByDay,
    currentTarget: weeklyTarget,
    previousTarget: weeklyTarget,
    currentRange: weekRange,
    previousRange: previousWeekRange,
  );
  final bestMoment = _bestMomentLabel(
    l10n: l10n,
    completionTimesByDay: completionTimesByDay,
    range: period == HabitStatsPeriod.week ? weekRange : _allTimeRange(),
  );
  final streakSnapshot = _readStreakSnapshot(context, habitId);
  final currentStreak = _currentStreakFromDayStates(
    habitMap: habitMap,
    countsByDay: countsByDay,
    countValuesByDay: countValuesByDay,
    skipsByDay: skipsByDay,
  );
  final bestStreak =
      streakSnapshot.best ?? _bestStreakFromCompletions(countsByDay);
  final objectiveSummary = _objectiveSummary(
    l10n: l10n,
    habitMap: habitMap,
    schedule: schedule,
    isCounter: isCounter,
    weeklyTarget: weeklyTarget,
  );
  final countTarget = _asNum(habitMap['target']) ?? 0;
  final unitLabel = _safeHabitUnitLabel(l10n, _asString(habitMap['unit']));

  return HabitStatsShellData(
    habitId: habitId,
    title: _habitTitle(l10n, habitMap),
    familyName: familyName,
    objectiveSummary: objectiveSummary,
    typeLabel:
        isCounter ? l10n.habitConfigCounterOption : l10n.habitConfigCheckOption,
    isCounter: isCounter,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    weeklyTarget: weeklyTarget,
    weeklyCompleted: weeklyCompleted,
    previousWeekCompleted: previousWeekCompleted,
    currentWeekCompleted: weeklyCompleted,
    weeklyConsistencyPct: weeklyConsistencyPct,
    weeklyComparisonDeltaPct: weeklyComparisonDeltaPct,
    bestMomentLabel: bestMoment.label,
    bestMomentSlot: bestMoment.slot,
    hasBestMomentData: bestMoment.hasData,
    last7Days: _buildLast7Days(
      context,
      habitMap: habitMap,
      countsByDay: countsByDay,
      countValuesByDay: countValuesByDay,
      skipsByDay: skipsByDay,
    ),
    countLast7Days: _buildCountLast7Days(
      context,
      countValuesByDay: countValuesByDay,
      unitLabel: unitLabel,
      target: countTarget,
    ),
    countDailyTarget: countTarget > 0 ? countTarget : 0,
    countUnitLabel: unitLabel,
    countsByDay: countsByDay,
    countValuesByDay: countValuesByDay,
    skipsByDay: skipsByDay,
  );
}

HabitStatsCountMetricSummary buildCountMetricSummary(
  HabitStatsShellData shellData, {
  int expectedDays = 7,
}) {
  final safeExpectedDays = expectedDays < 1 ? 7 : expectedDays;
  final weeklyTotal = shellData.countLast7Days.fold<num>(0, (sum, day) {
    final value = day.value < 0 ? 0 : day.value;
    return sum + value;
  });
  final dailyAverage =
      safeExpectedDays <= 0 ? 0 : weeklyTotal / safeExpectedDays;
  final dailyTarget =
      shellData.countDailyTarget > 0 ? shellData.countDailyTarget : 0;
  final weeklyGoal = dailyTarget * safeExpectedDays;
  final completionPct = weeklyGoal <= 0
      ? 0
      : ((weeklyTotal / weeklyGoal) * 100).round().clamp(0, 100);

  return HabitStatsCountMetricSummary(
    dailyTarget: dailyTarget,
    weeklyTotal: weeklyTotal,
    dailyAverage: dailyAverage,
    completionPct: completionPct,
    expectedDays: safeExpectedDays,
    unitLabel: shellData.countUnitLabel,
  );
}

String formatCountMetricValue(num value, {required String unitLabel}) {
  return _formatCountValueLabel(value, unitLabel: unitLabel);
}

HabitStatsCountBestDaySummary buildCountBestDaySummary(
  BuildContext context,
  HabitStatsShellData shellData,
) {
  HabitStatsCountLast7DayItem? bestDay;
  for (final day in shellData.countLast7Days) {
    if (day.value <= 0) continue;
    if (bestDay == null || day.value > bestDay.value) {
      bestDay = day;
    }
  }

  if (bestDay == null) {
    return const HabitStatsCountBestDaySummary(
      hasData: false,
      weekdayLabel: '',
      value: 0,
      valueLabel: '',
    );
  }

  return HabitStatsCountBestDaySummary(
    hasData: true,
    weekdayLabel:
        _capitalizeFirst(context.l10n.weekdayFull(bestDay.date.weekday)),
    value: bestDay.value,
    valueLabel: _formatCountValueLabel(bestDay.value,
        unitLabel: shellData.countUnitLabel),
  );
}

class _HistoryRoots {
  final Map<String, dynamic> completionsRoot;
  final Map<String, dynamic> countValuesRoot;
  final Map<String, dynamic> completionTimesRoot;
  final Map<String, dynamic> skipsRoot;

  const _HistoryRoots({
    required this.completionsRoot,
    required this.countValuesRoot,
    required this.completionTimesRoot,
    required this.skipsRoot,
  });
}

class _BestMomentResult {
  final bool hasData;
  final String label;
  final HabitStatsBestMomentSlot slot;

  const _BestMomentResult({
    required this.hasData,
    required this.label,
    required this.slot,
  });
}

class _StreakSnapshotResult {
  final int? current;
  final int? best;

  const _StreakSnapshotResult({
    this.current,
    this.best,
  });
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({
    required this.start,
    required this.end,
  });

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

class _MomentBucket {
  final int priority;
  final String label;

  const _MomentBucket({
    required this.priority,
    required this.label,
  });
}

_HistoryRoots _extractHistoryFromStore(BuildContext context) {
  try {
    final store = context.read<UserStateStore>();
    final root = _map(store.state);
    final userState = _map(root['userState']);
    final history = _map(userState['history']);
    return _HistoryRoots(
      completionsRoot: _map(history['habitCompletions']),
      countValuesRoot: _map(history['habitCountValues']),
      completionTimesRoot: _map(history['habitCompletionTimes']),
      skipsRoot: _map(history['habitSkips']),
    );
  } catch (_) {
    return const _HistoryRoots(
      completionsRoot: <String, dynamic>{},
      countValuesRoot: <String, dynamic>{},
      completionTimesRoot: <String, dynamic>{},
      skipsRoot: <String, dynamic>{},
    );
  }
}

Map<String, dynamic> _habitToMap(dynamic habit) {
  if (habit is Map<String, dynamic>) return habit;
  if (habit is Map) return Map<String, dynamic>.from(habit);
  try {
    final dynamic json = (habit as dynamic).toJson?.call();
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
  } catch (_) {}
  return <String, dynamic>{};
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _habitId(Map<String, dynamic> habit) {
  final raw =
      habit['id'] ?? habit['habitId'] ?? habit['uuid'] ?? habit['key'] ?? '';
  return raw.toString().trim();
}

bool _isCountHabit(Map<String, dynamic> habit) {
  final raw = (habit['type'] ?? habit['habitType'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  return raw == 'count' || raw == 'counter';
}

String _habitTitle(dynamic l10n, Map<String, dynamic> habit) {
  final raw = habit['title'] ??
      habit['name'] ??
      habit['habitTitle'] ??
      habit['label'] ??
      '';
  final title = raw.toString().trim();
  return title.isEmpty ? l10n.habitStatsHabitFallbackTitle : title;
}

String _resolveFamilyName(dynamic l10n, String? familyId) {
  switch ((familyId ?? '').trim().toLowerCase()) {
    case 'mind':
      return l10n.familyMindName;
    case 'spirit':
      return l10n.familySpiritName;
    case 'body':
      return l10n.familyBodyName;
    case 'emotional':
      return l10n.familyEmotionalName;
    case 'social':
      return l10n.familySocialName;
    case 'discipline':
      return l10n.familyDisciplineName;
    case 'professional':
      return l10n.familyProfessionalName;
    default:
      return l10n.familyPersonalName;
  }
}

int _weekStartsOn(Map<String, dynamic> schedule) {
  final raw = _asInt(schedule['weekStartsOn']);
  if (raw == null || raw < DateTime.monday || raw > DateTime.sunday) {
    return DateTime.monday;
  }
  return raw;
}

int _weeklyTarget(
  Map<String, dynamic> habit,
  Map<String, dynamic> schedule, {
  required bool isCounter,
}) {
  if (isCounter) {
    return _asInt(habit['target']) ?? 0;
  }
  final scheduleType =
      (schedule['type'] ?? 'daily').toString().trim().toLowerCase();
  if (scheduleType == 'timesperweek') {
    final target = _asInt(
      schedule['timesPerWeek'] ??
          schedule['timesPerWeekTarget'] ??
          habit['timesPerWeekTarget'],
    );
    return target == null || target < 1 ? 1 : target;
  }
  if (scheduleType == 'weekly') {
    final weekdays = (schedule['weekdays'] is List)
        ? (schedule['weekdays'] as List)
            .whereType<num>()
            .map((day) => day.toInt())
            .where((day) => day >= 1 && day <= 7)
            .toSet()
        : <int>{};
    if (weekdays.isNotEmpty) return weekdays.length;
  }
  return 7;
}

String _objectiveSummary({
  required dynamic l10n,
  required Map<String, dynamic> habitMap,
  required Map<String, dynamic> schedule,
  required bool isCounter,
  required int weeklyTarget,
}) {
  final explicit =
      _asString(habitMap['objective']) ?? _asString(habitMap['description']);
  if (explicit != null && explicit.trim().isNotEmpty) {
    return explicit.trim();
  }
  if (isCounter) {
    final target = _asInt(habitMap['target']) ?? 1;
    final unit = (_asString(habitMap['unit']) ?? '').trim();
    return unit.isEmpty
        ? '${l10n.habitConfigGoalSection}: $target'
        : '$target $unit';
  }

  final scheduleType =
      (schedule['type'] ?? 'daily').toString().trim().toLowerCase();
  if (scheduleType == 'timesperweek') {
    return l10n.habitStatsObjectiveWeekly(weeklyTarget < 1 ? 1 : weeklyTarget);
  }

  final perDayTarget = _asInt(habitMap['target']) ?? 1;
  return l10n.habitStatsObjectiveDaily(perDayTarget < 1 ? 1 : perDayTarget);
}

Map<DateTime, int> _extractCountsByDay({
  required Map<String, dynamic> habitMap,
  required String habitId,
  required Map<String, dynamic> completionsRoot,
}) {
  final out = <DateTime, int>{};

  if (habitId.isNotEmpty) {
    final perHabit = completionsRoot[habitId];
    _consumeAnyHistoryValue(perHabit, out);
  }

  for (final entry in completionsRoot.entries) {
    final date = _tryParseDate(entry.key);
    if (date == null) continue;
    final dayBucket = _map(entry.value);
    final value = dayBucket[habitId];
    _addHistoryValueAtDate(out, _dateOnly(date), value);
  }

  for (final key in const [
    'history',
    'completions',
    'checkins',
    'checkIns',
    'doneDates',
    'completedDates',
    'completionDates',
    'records',
  ]) {
    _consumeAnyHistoryValue(habitMap[key], out);
  }

  final lastDone =
      _tryParseDate(habitMap['lastDoneAt'] ?? habitMap['lastCompletedAt']);
  if (lastDone != null) {
    final day = _dateOnly(lastDone);
    out[day] = (out[day] ?? 0) + 1;
  }

  return out;
}

Map<DateTime, num> _extractCountValuesByDay({
  required Map<String, dynamic> habitMap,
  required String habitId,
  required Map<String, dynamic> countValuesRoot,
}) {
  final out = <DateTime, num>{};
  if (habitId.isEmpty) return out;

  final perHabit = _map(countValuesRoot[habitId]);
  for (final entry in perHabit.entries) {
    final date = _tryParseDate(entry.key);
    final value = _asNum(entry.value);
    if (date == null || value == null) continue;
    out[_dateOnly(date)] = value < 0 ? 0 : value;
  }

  for (final entry in countValuesRoot.entries) {
    final date = _tryParseDate(entry.key);
    if (date == null) continue;
    final dayMap = _map(entry.value);
    final value = _asNum(dayMap[habitId]);
    if (value == null) continue;
    out[_dateOnly(date)] = value < 0 ? 0 : value;
  }

  final todayProgress =
      _asNum(habitMap['progress'] ?? habitMap['current'] ?? habitMap['value']);
  if (todayProgress != null && todayProgress >= 0) {
    final today = _dateOnly(DateTime.now());
    final storedToday = _asNum(out[today]);
    if (storedToday == null || todayProgress > storedToday) {
      out[today] = todayProgress;
    }
  }

  return out;
}

Map<DateTime, bool> _extractSkipsByDay({
  required String habitId,
  required Map<String, dynamic> skipsRoot,
}) {
  final out = <DateTime, bool>{};
  if (habitId.isEmpty) return out;

  final perHabit = _map(skipsRoot[habitId]);
  for (final entry in perHabit.entries) {
    final date = _tryParseDate(entry.key);
    if (date == null) continue;
    out[_dateOnly(date)] = _isTrue(entry.value);
  }

  for (final entry in skipsRoot.entries) {
    final date = _tryParseDate(entry.key);
    if (date == null) continue;
    final dayBucket = _map(entry.value);
    if (!_isTrue(dayBucket[habitId])) continue;
    out[_dateOnly(date)] = true;
  }
  return out;
}

Map<DateTime, int> _extractCompletionTimesByDay({
  required String habitId,
  required Map<String, dynamic> completionTimesRoot,
}) {
  final out = <DateTime, int>{};
  if (habitId.isEmpty) return out;

  final perHabit = _map(completionTimesRoot[habitId]);
  for (final entry in perHabit.entries) {
    final date = _tryParseDate(entry.key);
    final epoch = _asInt(entry.value);
    if (date == null || epoch == null || epoch <= 0) continue;
    out[_dateOnly(date)] = epoch;
  }

  for (final entry in completionTimesRoot.entries) {
    final date = _tryParseDate(entry.key);
    if (date == null) continue;
    final dayBucket = _map(entry.value);
    final epoch = _asInt(dayBucket[habitId]);
    if (epoch == null || epoch <= 0) continue;
    out[_dateOnly(date)] = epoch;
  }

  return out;
}

void _consumeAnyHistoryValue(dynamic value, Map<DateTime, int> out) {
  if (value is List) {
    for (final item in value) {
      if (item is Map) {
        final done =
            item['done'] ?? item['completed'] ?? item['isDone'] ?? true;
        if (done == false) continue;
        final date = _tryParseDate(
          item['date'] ??
              item['day'] ??
              item['ts'] ??
              item['time'] ??
              item['completedAt'],
        );
        if (date == null) continue;
        final count = _asInt(item['count']) ?? 1;
        final key = _dateOnly(date);
        out[key] = (out[key] ?? 0) + (count > 0 ? count : 1);
      } else {
        final date = _tryParseDate(item);
        if (date == null) continue;
        final key = _dateOnly(date);
        out[key] = (out[key] ?? 0) + 1;
      }
    }
    return;
  }

  if (value is Map) {
    for (final entry in value.entries) {
      final date = _tryParseDate(entry.key);
      if (date == null) continue;
      _addHistoryValueAtDate(out, _dateOnly(date), entry.value);
    }
  }
}

void _addHistoryValueAtDate(
    Map<DateTime, int> out, DateTime date, dynamic value) {
  if (_isTrue(value)) {
    out[date] = (out[date] ?? 0) + 1;
    return;
  }
  final count = _asInt(value);
  if (count != null && count > 0) {
    out[date] = (out[date] ?? 0) + count;
  }
}

List<HabitStatsLast7DayItem> _buildLast7Days(
  BuildContext context, {
  required Map<String, dynamic> habitMap,
  required Map<DateTime, int> countsByDay,
  required Map<DateTime, num> countValuesByDay,
  required Map<DateTime, bool> skipsByDay,
}) {
  final today = _dateOnly(DateTime.now());
  return List<HabitStatsLast7DayItem>.generate(
    7,
    (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final state = _dayStateForDate(
        date: date,
        today: today,
        habitMap: habitMap,
        countsByDay: countsByDay,
        countValuesByDay: countValuesByDay,
        skipsByDay: skipsByDay,
      );
      return HabitStatsLast7DayItem(
        date: date,
        weekdayLabel: context.l10n.weekdayShort(date.weekday),
        state: state,
      );
    },
    growable: false,
  );
}

List<HabitStatsCountLast7DayItem> _buildCountLast7Days(
  BuildContext context, {
  required Map<DateTime, num> countValuesByDay,
  required String unitLabel,
  required num target,
}) {
  final today = _dateOnly(DateTime.now());
  final safeTarget = target > 0 ? target : 0;
  return List<HabitStatsCountLast7DayItem>.generate(
    7,
    (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final rawValue = _asNum(countValuesByDay[date]) ?? 0;
      final value = rawValue < 0 ? 0 : rawValue;
      final ratio =
          safeTarget <= 0 ? 0.0 : (value / safeTarget).clamp(0, 1).toDouble();
      return HabitStatsCountLast7DayItem(
        date: date,
        weekdayLabel: context.l10n.weekdayShort(date.weekday),
        value: value,
        valueLabel: _formatCountValueLabel(value, unitLabel: unitLabel),
        fillRatio: ratio,
      );
    },
    growable: false,
  );
}

_DateRange _buildWeekRange(DateTime date, int weekStartsOn) {
  final day = _dateOnly(date);
  final delta = (day.weekday - weekStartsOn + 7) % 7;
  final start = day.subtract(Duration(days: delta));
  return _DateRange(start: start, end: start.add(const Duration(days: 6)));
}

_DateRange _allTimeRange() {
  final now = _dateOnly(DateTime.now());
  return _DateRange(start: now.subtract(const Duration(days: 3650)), end: now);
}

int _countCompletedDays({
  required Map<DateTime, int> countsByDay,
  required Map<DateTime, bool> skipsByDay,
  required _DateRange range,
}) {
  var completed = 0;
  for (final day in range.days) {
    if (skipsByDay[day] == true) continue;
    if ((countsByDay[day] ?? 0) > 0) completed += 1;
  }
  return completed;
}

int? _weeklyComparisonDelta({
  required Map<DateTime, int> countsByDay,
  required Map<DateTime, bool> skipsByDay,
  required int currentTarget,
  required int previousTarget,
  required _DateRange currentRange,
  required _DateRange previousRange,
}) {
  if (previousTarget <= 0 || currentTarget <= 0) return null;
  final previousHasAnyData = previousRange.days.any(
    (day) => (countsByDay[day] ?? 0) > 0 || skipsByDay[day] == true,
  );
  if (!previousHasAnyData) return null;

  final currentCompleted = _countCompletedDays(
      countsByDay: countsByDay, skipsByDay: skipsByDay, range: currentRange);
  final previousCompleted = _countCompletedDays(
    countsByDay: countsByDay,
    skipsByDay: skipsByDay,
    range: previousRange,
  );
  final currentPct =
      ((currentCompleted / currentTarget) * 100).round().clamp(0, 100);
  final previousPct =
      ((previousCompleted / previousTarget) * 100).round().clamp(0, 100);
  return currentPct - previousPct;
}

_BestMomentResult _bestMomentLabel({
  required dynamic l10n,
  required Map<DateTime, int> completionTimesByDay,
  required _DateRange range,
}) {
  final buckets = <String, _MomentBucket>{
    'morning':
        _MomentBucket(priority: 0, label: l10n.statisticsV3MomentMorning),
    'noon': _MomentBucket(priority: 1, label: l10n.statisticsV3MomentAfternoon),
    'afternoon':
        _MomentBucket(priority: 2, label: l10n.statisticsV3MomentEvening),
    'night': _MomentBucket(priority: 3, label: l10n.statisticsV3MomentNight),
  };
  final counts = <String, int>{for (final key in buckets.keys) key: 0};

  for (final day in range.days) {
    final epoch = completionTimesByDay[day];
    if (epoch == null || epoch <= 0) continue;
    final local = DateTime.fromMillisecondsSinceEpoch(epoch).toLocal();
    final bucketKey = _bucketForHour(local.hour);
    counts[bucketKey] = (counts[bucketKey] ?? 0) + 1;
  }

  final hasData = counts.values.any((count) => count > 0);
  if (!hasData) {
    return _BestMomentResult(
      hasData: false,
      label: l10n.habitStatsNoData,
      slot: HabitStatsBestMomentSlot.unknown,
    );
  }

  final ordered = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      final pa = buckets[a.key]?.priority ?? 99;
      final pb = buckets[b.key]?.priority ?? 99;
      return pa.compareTo(pb);
    });
  final winner = ordered.first.key;
  return _BestMomentResult(
    hasData: true,
    label: buckets[winner]?.label ?? l10n.habitStatsNoData,
    slot: _slotFromBucketKey(winner),
  );
}

HabitStatsBestMomentSlot _slotFromBucketKey(String key) {
  switch (key) {
    case 'morning':
      return HabitStatsBestMomentSlot.morning;
    case 'noon':
      return HabitStatsBestMomentSlot.noon;
    case 'afternoon':
      return HabitStatsBestMomentSlot.afternoon;
    case 'night':
      return HabitStatsBestMomentSlot.night;
    default:
      return HabitStatsBestMomentSlot.unknown;
  }
}

String _bucketForHour(int hour) {
  if (hour >= 5 && hour <= 11) return 'morning';
  if (hour >= 12 && hour <= 14) return 'noon';
  if (hour >= 15 && hour <= 20) return 'afternoon';
  return 'night';
}

_StreakSnapshotResult _readStreakSnapshot(
    BuildContext context, String habitId) {
  if (habitId.isEmpty) return const _StreakSnapshotResult();
  try {
    final store = context.read<UserStateStore>();
    final dynamic snapshot = store.habitStreakSnapshotForHabitId(habitId);
    final current =
        _asInt(snapshot.currentStreak ?? snapshot.streak ?? snapshot.current);
    final best =
        _asInt(snapshot.bestStreak ?? snapshot.best ?? snapshot.longestStreak);
    return _StreakSnapshotResult(current: current, best: best);
  } catch (_) {
    return const _StreakSnapshotResult();
  }
}

int _currentStreakFromDayStates({
  required Map<String, dynamic> habitMap,
  required Map<DateTime, int> countsByDay,
  required Map<DateTime, num> countValuesByDay,
  required Map<DateTime, bool> skipsByDay,
}) {
  final today = _dateOnly(DateTime.now());
  final todayState = _dayStateForDate(
    date: today,
    today: today,
    habitMap: habitMap,
    countsByDay: countsByDay,
    countValuesByDay: countValuesByDay,
    skipsByDay: skipsByDay,
  );

  // Pending today is neutral for the current streak.
  // We only start from yesterday when today is still pending.
  var cursor = todayState == HabitStatsDayState.pending
      ? today.subtract(const Duration(days: 1))
      : today;
  var streak = 0;

  while (_dayStateForDate(
        date: cursor,
        today: today,
        habitMap: habitMap,
        countsByDay: countsByDay,
        countValuesByDay: countValuesByDay,
        skipsByDay: skipsByDay,
      ) ==
      HabitStatsDayState.completed) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

HabitStatsDayState _dayStateForDate({
  required DateTime date,
  required DateTime today,
  required Map<String, dynamic> habitMap,
  required Map<DateTime, int> countsByDay,
  required Map<DateTime, num> countValuesByDay,
  required Map<DateTime, bool> skipsByDay,
}) {
  final day = _dateOnly(date);
  if (skipsByDay[day] == true) {
    return HabitStatsDayState.skipped;
  }
  if (_isHabitCompletedOnDate(
    date: day,
    habitMap: habitMap,
    countsByDay: countsByDay,
    countValuesByDay: countValuesByDay,
    skipsByDay: skipsByDay,
  )) {
    return HabitStatsDayState.completed;
  }
  return day.isAfter(today)
      ? HabitStatsDayState.future
      : HabitStatsDayState.pending;
}

bool _isHabitCompletedOnDate({
  required DateTime date,
  required Map<String, dynamic> habitMap,
  required Map<DateTime, int> countsByDay,
  required Map<DateTime, num> countValuesByDay,
  required Map<DateTime, bool> skipsByDay,
}) {
  final day = _dateOnly(date);
  if (skipsByDay[day] == true) return false;

  final completedFromHistory = (countsByDay[day] ?? 0) > 0;
  final today = _dateOnly(DateTime.now());
  final completedFromTodayState = _isSameDate(day, today) &&
      habitMap['doneToday'] == true &&
      habitMap['skippedToday'] != true;

  if (!_isCountHabit(habitMap)) {
    return completedFromHistory || completedFromTodayState;
  }

  final targetValue = (_asNum(habitMap['target']) ?? 1).toDouble();
  final safeTarget = targetValue > 0 ? targetValue : 1.0;
  final todayValue = (_asNum(countValuesByDay[day]) ?? 0).toDouble();
  final completedFromCountTarget = todayValue >= safeTarget;
  return completedFromHistory ||
      completedFromTodayState ||
      completedFromCountTarget;
}

int _bestStreakFromCompletions(Map<DateTime, int> countsByDay) {
  final doneDays = countsByDay.keys
      .where((day) => (countsByDay[day] ?? 0) > 0)
      .toList()
    ..sort();
  if (doneDays.isEmpty) return 0;

  var best = 1;
  var current = 1;
  for (var i = 1; i < doneDays.length; i++) {
    if (doneDays[i].difference(doneDays[i - 1]).inDays == 1) {
      current += 1;
    } else {
      current = 1;
    }
    if (current > best) best = current;
  }
  return best;
}

bool _isTrue(dynamic value) {
  if (value == true || value == 1) return true;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
  return false;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    } catch (_) {
      return null;
    }
  }
  if (value is num) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
    } catch (_) {
      return null;
    }
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

num? _asNum(dynamic value) {
  if (value is num) {
    if (value is double && !value.isFinite) return null;
    return value;
  }
  if (value is String) {
    final parsed = num.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed is double && !parsed.isFinite) return null;
    return parsed;
  }
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}

String _safeHabitUnitLabel(dynamic l10n, String? rawUnit) {
  final unit = (rawUnit ?? '').trim();
  if (unit.isEmpty) return '';
  final normalized = unit.toLowerCase();
  try {
    final localized = l10n.habitUnitLabel(normalized).toString().trim();
    return localized.isEmpty ? unit : localized;
  } catch (_) {
    return unit;
  }
}

String _formatCountValueLabel(num value, {required String unitLabel}) {
  final normalizedValue =
      value is double && value.isFinite ? value : value.toDouble();
  final text = normalizedValue % 1 == 0
      ? normalizedValue.toInt().toString()
      : normalizedValue.toStringAsFixed(1);
  final unit = unitLabel.trim();
  return unit.isEmpty ? text : '$text $unit';
}

String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
