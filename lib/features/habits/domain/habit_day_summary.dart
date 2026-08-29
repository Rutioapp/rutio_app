import 'dart:collection';

import 'package:flutter/foundation.dart';

@immutable
class HabitDaySummary {
  HabitDaySummary({
    required List<Map<String, dynamic>> visibleHabits,
    required List<Map<String, dynamic>> expectedHabits,
    required List<Map<String, dynamic>> viewHabits,
    required List<Map<String, dynamic>> pendingHabits,
    required List<Map<String, dynamic>> completedHabits,
    required List<Map<String, dynamic>> skippedHabits,
  })  : visibleHabits = UnmodifiableListView<Map<String, dynamic>>(
          visibleHabits
              .map((habit) => Map<String, dynamic>.unmodifiable(habit))
              .toList(growable: false),
        ),
        expectedHabits = UnmodifiableListView<Map<String, dynamic>>(
          expectedHabits
              .map((habit) => Map<String, dynamic>.unmodifiable(habit))
              .toList(growable: false),
        ),
        viewHabits = UnmodifiableListView<Map<String, dynamic>>(
          viewHabits
              .map((habit) => Map<String, dynamic>.unmodifiable(habit))
              .toList(growable: false),
        ),
        pendingHabits = UnmodifiableListView<Map<String, dynamic>>(
          pendingHabits
              .map((habit) => Map<String, dynamic>.unmodifiable(habit))
              .toList(growable: false),
        ),
        completedHabits = UnmodifiableListView<Map<String, dynamic>>(
          completedHabits
              .map((habit) => Map<String, dynamic>.unmodifiable(habit))
              .toList(growable: false),
        ),
        skippedHabits = UnmodifiableListView<Map<String, dynamic>>(
          skippedHabits
              .map((habit) => Map<String, dynamic>.unmodifiable(habit))
              .toList(growable: false),
        );

  final List<Map<String, dynamic>> visibleHabits;
  final List<Map<String, dynamic>> expectedHabits;
  final List<Map<String, dynamic>> viewHabits;
  final List<Map<String, dynamic>> pendingHabits;
  final List<Map<String, dynamic>> completedHabits;
  final List<Map<String, dynamic>> skippedHabits;

  int get totalCount => viewHabits.length;
  int get completedCount => completedHabits.length;
  int get pendingCount => pendingHabits.length;
  int get skippedCount => skippedHabits.length;

  double? get progressRatio {
    if (totalCount <= 0) {
      return null;
    }
    return completedCount / totalCount;
  }
}

HabitDaySummary buildHabitDaySummary({
  required List<Map<String, dynamic>> activeHabits,
  required Map<String, dynamic> history,
  required DateTime selectedDay,
  required DateTime today,
}) {
  final normalizedSelectedDay = _onlyDate(selectedDay);
  final normalizedToday = _onlyDate(today);
  final visibleHabits = activeHabits
      .where((habit) => !_isArchived(habit))
      .map((habit) => Map<String, dynamic>.from(habit))
      .toList(growable: false);
  final expectedHabits = visibleHabits
      .where(
        (habit) => isHabitExpectedForDateSummary(habit, normalizedSelectedDay),
      )
      .toList(growable: false);

  final selectedKey = _dateKey(normalizedSelectedDay);
  final todayKey = _dateKey(normalizedToday);
  final habitCompletions = _map(history['habitCompletions']);
  final habitCountValues = _map(history['habitCountValues']);
  final habitSkips = _map(history['habitSkips']);
  final selectedDoneMap = _map(habitCompletions[selectedKey]);
  final selectedCountMap = _map(habitCountValues[selectedKey]);
  final selectedSkipsMap = _map(habitSkips[selectedKey]);

  final viewHabits = expectedHabits.map((habit) {
    final out = Map<String, dynamic>.from(habit);
    final habitId = (out['id'] ?? '').toString();
    final type = (out['type'] ?? 'check').toString();
    final isTimesPerWeekCheck = _isTimesPerWeekCheckHabit(out);
    out['isTimesPerWeekCheck'] = isTimesPerWeekCheck;

    final useSelectedDaySnapshot = selectedKey != todayKey ||
        selectedSkipsMap.containsKey(habitId) ||
        selectedDoneMap.containsKey(habitId) ||
        selectedCountMap.containsKey(habitId);

    if (useSelectedDaySnapshot) {
      final skipped = selectedSkipsMap[habitId] == true;
      final doneFromSelectedDay = selectedDoneMap[habitId] == true;
      out['skippedToday'] = skipped;
      if (type == 'check') {
        out['doneToday'] = isTimesPerWeekCheck
            ? doneFromSelectedDay
            : !skipped && doneFromSelectedDay;
      } else {
        final target = _readNum(out['target'], fallback: 1);
        final value = skipped ? 0 : _readNum(selectedCountMap[habitId]);
        out['progress'] = value;
        out['doneToday'] = !skipped && (doneFromSelectedDay || value >= target);
      }
    } else if (type == 'check' &&
        !isTimesPerWeekCheck &&
        out['skippedToday'] == true) {
      out['doneToday'] = false;
    }

    if (isTimesPerWeekCheck) {
      final weeklyTarget = _timesPerWeekTarget(out);
      final weekStartsOn = _timesPerWeekWeekStartsOn(out);
      final completedThisWeek = _completedTimesInWeek(
        habit: out,
        habitId: habitId,
        selectedDay: normalizedSelectedDay,
        weekStartsOn: weekStartsOn,
        habitCompletions: habitCompletions,
      );
      out['weeklyCompletedCount'] = completedThisWeek;
      out['weeklyTargetCount'] = weeklyTarget;
      out['isWeeklyTargetMet'] = completedThisWeek >= weeklyTarget;
    }

    return out;
  }).toList(growable: false);

  final pendingHabits = viewHabits.where((habit) {
    if (_isTimesPerWeekCheckHabit(habit)) {
      final doneToday = habit['doneToday'] == true;
      final weeklyTargetMet = habit['isWeeklyTargetMet'] == true;
      final skipped = habit['skippedToday'] == true;
      return !skipped && !doneToday && !weeklyTargetMet;
    }
    return habit['doneToday'] != true && habit['skippedToday'] != true;
  }).toList(growable: false);

  final completedHabits = viewHabits.where((habit) {
    if (_isTimesPerWeekCheckHabit(habit)) {
      return habit['doneToday'] == true || habit['isWeeklyTargetMet'] == true;
    }
    return habit['doneToday'] == true;
  }).toList(growable: false);

  final skippedHabits = viewHabits.where((habit) {
    if (_isTimesPerWeekCheckHabit(habit)) {
      final doneToday = habit['doneToday'] == true;
      final weeklyTargetMet = habit['isWeeklyTargetMet'] == true;
      return habit['skippedToday'] == true && !doneToday && !weeklyTargetMet;
    }
    return habit['skippedToday'] == true;
  }).toList(growable: false);

  return HabitDaySummary(
    visibleHabits: visibleHabits,
    expectedHabits: expectedHabits,
    viewHabits: viewHabits,
    pendingHabits: pendingHabits,
    completedHabits: completedHabits,
    skippedHabits: skippedHabits,
  );
}

bool isHabitExpectedForDateSummary(Map<String, dynamic> habit, DateTime date) {
  if (_isArchived(habit)) return false;
  if (!_wasHabitCreatedByDay(habit, date)) return false;
  return _isHabitScheduledForDate(habit, date);
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

bool _isArchived(Map<String, dynamic> habit) =>
    habit['archived'] == true || habit['isArchived'] == true;

bool _wasHabitCreatedByDay(Map<String, dynamic> habit, DateTime day) {
  final createdAt = _parseHabitDate(
    habit['createdAt'] ??
        habit['created_at'] ??
        habit['createdDate'] ??
        habit['dateCreated'],
  );
  if (createdAt == null) return true;
  return !_onlyDate(createdAt.toLocal()).isAfter(_onlyDate(day));
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

  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (match == null) return null;

  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

bool _isHabitScheduledForDate(Map<String, dynamic> habit, DateTime date) {
  final schedule = _map(habit['schedule']);
  final type = (schedule['type'] ?? 'daily').toString().trim().toLowerCase();

  if (type == 'timesperweek') return true;
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
  return true;
}

bool _isTimesPerWeekCheckHabit(Map<String, dynamic> habit) {
  final type = (habit['type'] ?? 'check').toString().trim().toLowerCase();
  if (type != 'check') return false;
  final schedule = _map(habit['schedule']);
  final scheduleType = (schedule['type'] ?? '').toString().trim().toLowerCase();
  return scheduleType == 'timesperweek';
}

int _timesPerWeekTarget(Map<String, dynamic> habit) {
  final schedule = _map(habit['schedule']);
  final target = _readNum(
    schedule['timesPerWeek'] ?? schedule['timesPerWeekTarget'],
    fallback: 1,
  ).toInt();
  return target < 1 ? 1 : target;
}

int _timesPerWeekWeekStartsOn(Map<String, dynamic> habit) {
  final schedule = _map(habit['schedule']);
  final raw = _readNum(schedule['weekStartsOn'], fallback: 1).toInt();
  if (raw < 1 || raw > 7) return 1;
  return raw;
}

int _completedTimesInWeek({
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime selectedDay,
  required int weekStartsOn,
  required Map<String, dynamic> habitCompletions,
}) {
  final weekStart = _weekStartForDate(selectedDay, weekStartsOn: weekStartsOn);
  var completed = 0;
  for (var offset = 0; offset < 7; offset += 1) {
    final day = weekStart.add(Duration(days: offset));
    if (!_wasHabitCreatedByDay(habit, day)) continue;
    final dayDoneMap = _map(habitCompletions[_dateKey(day)]);
    if (_isTruthyDone(dayDoneMap[habitId])) {
      completed += 1;
    }
  }
  return completed;
}

DateTime _weekStartForDate(DateTime day, {required int weekStartsOn}) {
  final normalized = _onlyDate(day);
  final start = weekStartsOn >= 1 && weekStartsOn <= 7 ? weekStartsOn : 1;
  final delta = (normalized.weekday - start + 7) % 7;
  return normalized.subtract(Duration(days: delta));
}

bool _isTruthyDone(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value > 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

num _readNum(dynamic value, {num fallback = 0}) {
  if (value is num) return value;
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return fallback;
  return num.tryParse(raw.replaceAll(',', '.')) ?? fallback;
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
