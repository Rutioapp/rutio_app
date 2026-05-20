import 'demo_seed_dates.dart';
import 'demo_seed_habits.dart';

class DemoSeedHistoryPayload {
  const DemoSeedHistoryPayload({
    required this.completions,
    required this.countValues,
    required this.skips,
    required this.completionTimes,
  });

  final Map<String, Map<String, dynamic>> completions;
  final Map<String, Map<String, dynamic>> countValues;
  final Map<String, Map<String, dynamic>> skips;
  final Map<String, Map<String, dynamic>> completionTimes;
}

class DemoSeedHistory {
  const DemoSeedHistory._();

  static DemoSeedHistoryPayload build({
    required DateTime now,
    required List<DemoSeedHabit> habits,
  }) {
    final today = DemoSeedDates.dateOnly(now.toLocal());
    final rangeStart = DemoSeedDates.firstDayOfMonthMonthsBack(
      now: today,
      monthsBack: 5,
    );
    final completions = <String, Map<String, dynamic>>{};
    final countValues = <String, Map<String, dynamic>>{};
    final skips = <String, Map<String, dynamic>>{};
    final completionTimes = <String, Map<String, dynamic>>{};

    for (final day in DemoSeedDates.eachDayInclusive(start: rangeStart, end: today)) {
      final dayKey = DemoSeedDates.dateKey(day);
      final monthIndex = _monthIndex(rangeStart, day);

      for (final habit in habits) {
        if (!_isActiveForDay(habit, day)) continue;
        if (!_isScheduledForDay(habit, day)) continue;

        if (_shouldSkip(habit, day, today)) {
          _setDayValue(skips, dayKey, habit.id, true);
          _setDayValue(completions, dayKey, habit.id, false);
          if (habit.isCount) {
            _setDayValue(countValues, dayKey, habit.id, 0);
          }
          continue;
        }

        if (habit.isCount) {
          final value = _countValueForDay(
            habit: habit,
            day: day,
            monthIndex: monthIndex,
            today: today,
          );
          if (value <= 0) continue;

          _setDayValue(countValues, dayKey, habit.id, value);
          _setDayValue(completions, dayKey, habit.id, value >= habit.target);
          if (value >= habit.target) {
            _setDayValue(
              completionTimes,
              dayKey,
              habit.id,
              _completionEpochMillis(day, habit.preferredHour),
            );
          }
          continue;
        }

        if (_checkCompletedForDay(
          habit: habit,
          day: day,
          monthIndex: monthIndex,
          today: today,
        )) {
          _setDayValue(completions, dayKey, habit.id, true);
          _setDayValue(
            completionTimes,
            dayKey,
            habit.id,
            _completionEpochMillis(day, habit.preferredHour),
          );
        }
      }
    }

    return DemoSeedHistoryPayload(
      completions: completions,
      countValues: countValues,
      skips: skips,
      completionTimes: completionTimes,
    );
  }

  static bool _isActiveForDay(DemoSeedHabit habit, DateTime day) {
    if (DemoSeedDates.dateOnly(day).isBefore(DemoSeedDates.dateOnly(habit.createdAt))) {
      return false;
    }
    final archivedOn = habit.archivedOn;
    if (archivedOn != null &&
        DemoSeedDates.dateOnly(day).isAfter(DemoSeedDates.dateOnly(archivedOn))) {
      return false;
    }
    return true;
  }

  static bool _isScheduledForDay(DemoSeedHabit habit, DateTime day) {
    final schedule = habit.schedule;
    final type = (schedule['type'] ?? 'daily').toString().toLowerCase();
    if (type == 'weekly') {
      final weekdays = (schedule['weekdays'] is List)
          ? (schedule['weekdays'] as List)
              .whereType<num>()
              .map((value) => value.toInt())
              .toSet()
          : <int>{};
      return weekdays.contains(day.weekday);
    }
    if (type == 'once') {
      return (schedule['date'] ?? '').toString() == DemoSeedDates.dateKey(day);
    }
    return true;
  }

  static bool _shouldSkip(DemoSeedHabit habit, DateTime day, DateTime today) {
    if (habit.id == 'demo_habit_journal' &&
        DemoSeedDates.dateOnly(day) ==
            DemoSeedDates.dateOnly(today.subtract(const Duration(days: 1)))) {
      return true;
    }

    if (habit.id == 'demo_habit_walk_focus' && day.day % 19 == 0) {
      return true;
    }

    if (habit.id == 'demo_habit_sleep_early' &&
        day.weekday == DateTime.saturday &&
        day.day % 2 == 0) {
      return true;
    }

    return false;
  }

  static bool _checkCompletedForDay({
    required DemoSeedHabit habit,
    required DateTime day,
    required int monthIndex,
    required DateTime today,
  }) {
    if (habit.id == 'demo_habit_gym') {
      if (![DateTime.monday, DateTime.wednesday, DateTime.friday]
          .contains(day.weekday)) {
        return false;
      }
      if (monthIndex <= 1 && day.day % 5 == 0) return false;
      if (monthIndex == 5 && day.weekday == DateTime.friday && day.day % 4 == 0) {
        return false;
      }
      return true;
    }

    if (habit.id == 'demo_habit_call_someone') {
      final weekStart = DemoSeedDates.startOfWeek(today);
      if (!day.isBefore(weekStart)) return false;
    }

    if (habit.id == 'demo_habit_stretch_archived') {
      return day.day % 3 != 0;
    }

    final score = _dayScore(habit.id, day, monthIndex);
    final targetRate = _completionRateForPhase(habit.id, monthIndex);

    if (habit.id == 'demo_habit_walk_focus' && day.day % 11 == 0) {
      return false;
    }
    if (habit.id == 'demo_habit_plan_next_day' && day.day % 7 == 0) {
      return false;
    }

    return score < targetRate;
  }

  static num _countValueForDay({
    required DemoSeedHabit habit,
    required DateTime day,
    required int monthIndex,
    required DateTime today,
  }) {
    if (habit.id == 'demo_habit_water' &&
        DemoSeedDates.dateOnly(day) ==
            DemoSeedDates.dateOnly(today.subtract(const Duration(days: 1)))) {
      return 10;
    }

    final score = _dayScore(habit.id, day, monthIndex);
    final targetRate = _completionRateForPhase(habit.id, monthIndex);
    final shouldLog = score < (targetRate + 18);

    if (!shouldLog) return 0;

    if (habit.id == 'demo_habit_read' && day.day % 7 == 0) {
      return 35;
    }

    if (habit.id == 'demo_habit_water') {
      if (day.day % 9 == 0) return 10;
      if (day.day % 5 == 0) return 6;
      return 7 + ((score + day.weekday) % 3);
    }

    if (habit.id == 'demo_habit_steps') {
      final base = 5200 + ((score * 190) % 5200);
      if (day.weekday == DateTime.sunday) return base - 900;
      return base;
    }

    if (habit.id == 'demo_habit_deep_study') {
      if (day.day % 10 == 0) return 80;
      final value = 35 + ((score * 7 + day.day) % 55);
      return value;
    }

    return 0;
  }

  static int _completionRateForPhase(String habitId, int monthIndex) {
    final phaseBase = <int>[45, 56, 66, 78, 86, 73];
    final boundedMonth = monthIndex.clamp(0, phaseBase.length - 1);
    var rate = phaseBase[boundedMonth];

    if (habitId == 'demo_habit_meditation') rate += 7;
    if (habitId == 'demo_habit_journal') rate += 4;
    if (habitId == 'demo_habit_sleep_early') rate -= 2;
    if (habitId == 'demo_habit_call_someone') rate -= 12;
    if (habitId == 'demo_habit_plan_next_day') rate += 3;
    if (habitId == 'demo_habit_walk_focus') rate -= 5;
    if (habitId == 'demo_habit_read') rate += 3;
    if (habitId == 'demo_habit_steps') rate += 2;

    if (rate < 10) return 10;
    if (rate > 96) return 96;
    return rate;
  }

  static int _completionEpochMillis(DateTime day, int preferredHour) {
    final normalizedHour = preferredHour.clamp(0, 23);
    final stamp = DateTime(
      day.year,
      day.month,
      day.day,
      normalizedHour,
      12,
    );
    return stamp.millisecondsSinceEpoch;
  }

  static int _dayScore(String habitId, DateTime day, int monthIndex) {
    final hash = _stableHash(habitId);
    return (hash +
            day.day * 17 +
            day.weekday * 29 +
            monthIndex * 37 +
            day.month * 11) %
        100;
  }

  static int _stableHash(String text) {
    var hash = 0;
    for (final codeUnit in text.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  static int _monthIndex(DateTime start, DateTime day) =>
      (day.year - start.year) * 12 + (day.month - start.month);

  static void _setDayValue(
    Map<String, Map<String, dynamic>> root,
    String dayKey,
    String habitId,
    dynamic value,
  ) {
    final dayMap = root.putIfAbsent(dayKey, () => <String, dynamic>{});
    dayMap[habitId] = value;
  }
}
