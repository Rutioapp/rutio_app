part of '../habit_stats_tab.dart';

BoxDecoration _plainCardDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0x1A2A2118)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0D2A2118),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
  );
}

Map<String, dynamic> _habitMap(dynamic habit) {
  if (habit is Map<String, dynamic>) return habit;
  if (habit is Map) return habit.cast<String, dynamic>();
  return <String, dynamic>{};
}

Map<String, dynamic> _historyRoot(Map<String, dynamic>? state) {
  final root = _map(state);
  final userState = _map(root['userState']);
  return _map(userState['history']);
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

String _habitId(Map<String, dynamic> habit) {
  return (habit['id'] ?? habit['habitId'] ?? habit['uuid'] ?? '')
      .toString()
      .trim();
}

String _title(Map<String, dynamic> habit, AppLocalizations l10n) {
  final value = (habit['title'] ?? habit['name'] ?? habit['label'] ?? '')
      .toString()
      .trim();
  return value.isEmpty ? l10n.habitStatsHabitFallbackTitle : value;
}

String _familyId(Map<String, dynamic> habit) {
  final value = (habit['familyId'] ?? habit['family'] ?? '').toString().trim();
  if (value.isEmpty || !FamilyTheme.colors.containsKey(value)) {
    return FamilyTheme.fallbackId;
  }
  return value;
}

String _headline({
  required AppLocalizations l10n,
  required Map<String, dynamic> habit,
  required String familyId,
  required bool isCount,
  required num countTarget,
}) {
  final familyName = l10n.familyName(familyId);
  final objective = _objectiveSummary(
    l10n: l10n,
    habit: habit,
    isCount: isCount,
    countTarget: countTarget,
  );
  return '$familyName · $objective';
}

String _objectiveSummary({
  required AppLocalizations l10n,
  required Map<String, dynamic> habit,
  required bool isCount,
  required num countTarget,
}) {
  if (isCount) {
    return l10n.habitStatsIndividualObjectiveCountPerDay(
      _valueWithUnit(countTarget, _localizedUnit(l10n, _unit(habit))),
    );
  }

  final schedule = _map(habit['schedule']);
  final type = (schedule['type'] ?? 'daily').toString().trim().toLowerCase();
  if (type == 'timesperweek') {
    final target = _timesPerWeekTarget(habit);
    return l10n.habitStatsIndividualObjectiveTimesPerWeek(target);
  }
  if (type == 'weekly') {
    final weekdays = schedule['weekdays'];
    final count = weekdays is List
        ? weekdays.whereType<num>().map((v) => v.toInt()).toSet().length
        : 7;
    return l10n.habitStatsIndividualObjectiveDaysPerWeek(math.max(1, count));
  }
  return l10n.habitStatsIndividualObjectiveOnePerDay;
}

_DateRange _rangeForPeriod(
  _HabitStatsPeriod period, {
  required DateTime today,
  required int weekStartsOn,
}) {
  switch (period) {
    case _HabitStatsPeriod.week:
      return _DateRange(
        _weekStartForDate(today, weekStartsOn: weekStartsOn),
        today,
      );
    case _HabitStatsPeriod.month:
      return _DateRange(DateTime(today.year, today.month, 1), today);
    case _HabitStatsPeriod.year:
      return _DateRange(DateTime(today.year, 1, 1), today);
  }
}

DateTime _weekStartForDate(DateTime day, {required int weekStartsOn}) {
  final normalized = _dateOnly(day);
  final safeStart =
      weekStartsOn >= DateTime.monday && weekStartsOn <= DateTime.sunday
          ? weekStartsOn
          : DateTime.monday;
  final delta = (normalized.weekday - safeStart + 7) % 7;
  return normalized.subtract(Duration(days: delta));
}

DateTime _dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

int _weekStartsOn(Map<String, dynamic> habit) {
  final schedule = _map(habit['schedule']);
  final raw = _toInt(schedule['weekStartsOn'], fallback: DateTime.monday);
  if (raw < DateTime.monday || raw > DateTime.sunday) return DateTime.monday;
  return raw;
}

bool _isCountHabit(Map<String, dynamic> habit) {
  final type =
      (habit['type'] ?? habit['trackingType'] ?? habit['habitType'] ?? 'check')
          .toString()
          .trim()
          .toLowerCase();
  return type == 'count' || type == 'counter' || type == 'numeric';
}

num _countTarget(Map<String, dynamic> habit) {
  final schedule = _map(habit['schedule']);
  final target = _toNum(
    habit['target'] ??
        habit['goal'] ??
        habit['targetCount'] ??
        schedule['target'] ??
        schedule['goal'] ??
        0,
    fallback: 0,
  );
  return target > 0 ? target : 0;
}

String _unit(Map<String, dynamic> habit) {
  final schedule = _map(habit['schedule']);
  return (habit['unit'] ?? habit['unitLabel'] ?? schedule['unit'] ?? '')
      .toString();
}

String _localizedUnit(AppLocalizations l10n, String unit) {
  final normalized = unit.trim();
  if (normalized.isEmpty) return '';
  return l10n.habitUnitLabel(normalized);
}

bool _isSkippedOnDay({
  required Map<String, dynamic> history,
  required String habitId,
  required DateTime day,
}) {
  final dayMap = _map(_map(history['habitSkips'])[_dateKey(day)]);
  return _isDone(dayMap[habitId]);
}

bool _isCheckCompletedOnDay({
  required Map<String, dynamic> history,
  required String habitId,
  required DateTime day,
}) {
  final dayMap = _map(_map(history['habitCompletions'])[_dateKey(day)]);
  return _isDone(dayMap[habitId]);
}

num _countValueOnDay({
  required Map<String, dynamic> history,
  required String habitId,
  required DateTime day,
}) {
  final dayMap = _map(_map(history['habitCountValues'])[_dateKey(day)]);
  return _toNum(dayMap[habitId], fallback: 0);
}

bool _isDone(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value > 0;
  final text = (value ?? '').toString().trim().toLowerCase();
  return text == 'true' || text == '1';
}

int _timesPerWeekTarget(Map<String, dynamic> habit) {
  final schedule = _map(habit['schedule']);
  final target = _toInt(
    schedule['timesPerWeek'] ??
        schedule['timesPerWeekTarget'] ??
        schedule['goal'] ??
        habit['timesPerWeekTarget'] ??
        habit['goal'] ??
        1,
    fallback: 1,
  );
  return target < 1 ? 1 : target;
}

_CheckStats _computeCheckStats({
  required Map<String, dynamic> habit,
  required Map<String, dynamic> history,
  required String habitId,
  required _DateRange range,
  required int weekStartsOn,
  required num countTarget,
}) {
  final schedule = _map(habit['schedule']);
  final scheduleType =
      (schedule['type'] ?? 'daily').toString().trim().toLowerCase();
  final isTimesPerWeek = scheduleType == 'timesperweek';

  if (isTimesPerWeek) {
    final target = _timesPerWeekTarget(habit);
    var completed = 0;
    for (var i = 0; i < range.dayCount; i++) {
      final day = range.start.add(Duration(days: i));
      if (_isSkippedOnDay(history: history, habitId: habitId, day: day)) {
        continue;
      }
      if (_isCheckCompletedOnDay(
        history: history,
        habitId: habitId,
        day: day,
      )) {
        completed += 1;
      }
    }
    final pct =
        target == 0 ? 0 : ((completed / target) * 100).round().clamp(0, 100);
    return _CheckStats(
      expected: target,
      completed: completed,
      consistencyPct: pct,
    );
  }

  var expected = 0;
  var completed = 0;
  for (var i = 0; i < range.dayCount; i++) {
    final day = range.start.add(Duration(days: i));
    if (!_isScheduledForDate(habit, day, weekStartsOn: weekStartsOn)) continue;
    if (_isSkippedOnDay(history: history, habitId: habitId, day: day)) continue;
    expected += 1;
    if (_isCheckCompletedOnDay(history: history, habitId: habitId, day: day)) {
      completed += 1;
    }
  }
  final pct =
      expected == 0 ? 0 : ((completed / expected) * 100).round().clamp(0, 100);
  return _CheckStats(
    expected: expected,
    completed: completed,
    consistencyPct: pct,
  );
}

bool _isScheduledForDate(
  Map<String, dynamic> habit,
  DateTime day, {
  required int weekStartsOn,
}) {
  final schedule = _map(habit['schedule']);
  final type = (schedule['type'] ?? 'daily').toString().trim().toLowerCase();

  if (type == 'once') {
    final value = (schedule['date'] ?? '').toString().trim();
    return value == _dateKey(day);
  }

  if (type == 'weekly') {
    final weekdays = schedule['weekdays'];
    if (weekdays is! List) return true;
    final set = weekdays.whereType<num>().map((v) => v.toInt()).toSet();
    return set.contains(day.weekday);
  }

  if (type == 'timesperweek') {
    return _isCountHabit(habit);
  }

  return true;
}

_CountStats _computeCountStats({
  required Map<String, dynamic> history,
  required String habitId,
  required _DateRange range,
  required num target,
}) {
  num total = 0;
  for (var i = 0; i < range.dayCount; i++) {
    final day = range.start.add(Duration(days: i));
    if (_isSkippedOnDay(history: history, habitId: habitId, day: day)) continue;
    total += _countValueOnDay(history: history, habitId: habitId, day: day);
  }
  final average = range.dayCount == 0 ? 0 : total / range.dayCount;
  final expectedTotal = target <= 0 ? 0 : target * range.dayCount;
  final completionPct = expectedTotal <= 0
      ? 0
      : ((total / expectedTotal) * 100).round().clamp(0, 100);
  return _CountStats(
    total: total,
    average: average,
    completionPct: completionPct,
  );
}

int _currentStreak({
  required UserStateStore store,
  required Map<String, dynamic> history,
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime today,
  required num countTarget,
}) {
  final snapshot = store.habitStreakSnapshotForHabitId(habitId, today: today);
  if (snapshot.currentStreak > 0) return snapshot.currentStreak;

  final isCount = _isCountHabit(habit);
  var day = today;
  var streak = 0;
  while (true) {
    final skipped =
        _isSkippedOnDay(history: history, habitId: habitId, day: day);
    final done = isCount
        ? _countValueOnDay(history: history, habitId: habitId, day: day) >
            (countTarget > 0 ? 0 : 0)
        : _isCheckCompletedOnDay(history: history, habitId: habitId, day: day);
    if (!skipped && done) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
      continue;
    }
    break;
  }
  return streak;
}

String _bestMoment({
  required Map<String, dynamic> history,
  required String habitId,
  required DateTime start,
  required DateTime end,
  required AppLocalizations l10n,
}) {
  final timesRoot = _map(history['habitCompletionTimes']);
  final buckets = <String, int>{
    'morning': 0,
    'midday': 0,
    'afternoon': 0,
    'night': 0,
  };

  for (var i = 0; i <= end.difference(start).inDays; i++) {
    final day = start.add(Duration(days: i));
    final dayMap = _map(timesRoot[_dateKey(day)]);
    final millis = _toInt(dayMap[habitId], fallback: 0);
    if (millis <= 0) continue;

    final hour = DateTime.fromMillisecondsSinceEpoch(millis).hour;
    if (hour >= 5 && hour <= 11) {
      buckets['morning'] = (buckets['morning'] ?? 0) + 1;
    } else if (hour >= 12 && hour <= 14) {
      buckets['midday'] = (buckets['midday'] ?? 0) + 1;
    } else if (hour >= 15 && hour <= 20) {
      buckets['afternoon'] = (buckets['afternoon'] ?? 0) + 1;
    } else {
      buckets['night'] = (buckets['night'] ?? 0) + 1;
    }
  }

  final best = buckets.entries.reduce((a, b) => b.value > a.value ? b : a);
  if (best.value <= 0) return l10n.habitStatsIndividualNoData;

  switch (best.key) {
    case 'morning':
      return l10n.statisticsV3MomentMorning;
    case 'midday':
      return l10n.habitStatsIndividualMomentMidday;
    case 'afternoon':
      return l10n.statisticsV3MomentAfternoon;
    default:
      return l10n.statisticsV3MomentNight;
  }
}

_ObjectiveMetric _objectiveMetricForCheck(
  AppLocalizations l10n,
  Map<String, dynamic> habit,
) {
  final schedule = _map(habit['schedule']);
  final type = (schedule['type'] ?? 'daily').toString().trim().toLowerCase();

  if (type == 'timesperweek') {
    final target = _timesPerWeekTarget(habit);
    return _ObjectiveMetric(
      value: l10n.habitStatsIndividualTimes(target),
      subtitle: l10n.habitStatsIndividualPerWeek,
    );
  }

  if (type == 'weekly') {
    final weekdays = schedule['weekdays'];
    final weeklyCount = weekdays is List
        ? weekdays.whereType<num>().map((v) => v.toInt()).toSet().length
        : 7;
    return _ObjectiveMetric(
      value: l10n.habitStatsIndividualDays(math.max(1, weeklyCount)),
      subtitle: l10n.habitStatsIndividualPerWeek,
    );
  }

  return _ObjectiveMetric(
    value: l10n.habitStatsIndividualDays(1),
    subtitle: l10n.habitStatsIndividualPerDay,
  );
}

String _insightText({
  required AppLocalizations l10n,
  required bool isCount,
  required int score,
}) {
  if (score >= 80) {
    return isCount
        ? l10n.habitStatsIndividualInsightCountHigh
        : l10n.habitStatsIndividualInsightCheckHigh;
  }
  if (score >= 50) {
    return isCount
        ? l10n.habitStatsIndividualInsightCountMedium
        : l10n.habitStatsIndividualInsightCheckMedium;
  }
  return isCount
      ? l10n.habitStatsIndividualInsightCountLow
      : l10n.habitStatsIndividualInsightCheckLow;
}

String _dateKey(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse((value ?? '').toString().trim());
  return parsed ?? fallback;
}

num _toNum(dynamic value, {num fallback = 0}) {
  if (value is num) return value;
  final parsed =
      num.tryParse((value ?? '').toString().trim().replaceAll(',', '.'));
  return parsed ?? fallback;
}

String _valueWithUnit(num value, String unit) {
  final abs = value.abs();
  final hasDecimals = (abs - abs.truncateToDouble()).abs() > 0.001;
  final text =
      hasDecimals ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
  final safeUnit = unit.trim();
  if (safeUnit.isEmpty) return text;
  return '$text $safeUnit';
}
