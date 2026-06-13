import 'package:flutter/material.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';

Map<String, DailyMood> dailyMoodMapByDate(Iterable<DailyMood> dailyMoods) {
  return {
    for (final dailyMood in dailyMoods) _dateKey(dailyMood.date): dailyMood,
  };
}

int? resolvePreferredMoodForDay({
  required DateTime day,
  required Map<String, DailyMood> dailyMoodsByDate,
  required Iterable<DiaryEntry> fallbackEntries,
}) {
  final mood = dailyMoodsByDate[_dateKey(day)]?.mood;
  if (mood != null) return mood;

  // TODO(v2-diary): DiaryEntry.mood fallback is temporary until daily mood
  // capture is fully integrated.
  for (final entry in fallbackEntries) {
    if (entry.mood != null) return entry.mood;
  }
  return null;
}

List<int> resolvePreferredMonthMoodValues({
  required DateTime month,
  required Map<String, DailyMood> dailyMoodsByDate,
  required List<DiaryEntry> monthEntries,
}) {
  final normalizedMonth = DateUtils.dateOnly(month);
  final entriesByDay = <String, List<DiaryEntry>>{};
  for (final entry in monthEntries) {
    final day = DateUtils.dateOnly(
      DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
    );
    final key = _dateKey(day);
    entriesByDay.putIfAbsent(key, () => <DiaryEntry>[]).add(entry);
  }

  final daysInMonth =
      DateUtils.getDaysInMonth(normalizedMonth.year, normalizedMonth.month);
  final values = <int>[];
  for (var day = 1; day <= daysInMonth; day += 1) {
    final date = DateTime(normalizedMonth.year, normalizedMonth.month, day);
    final mood = resolvePreferredMoodForDay(
      day: date,
      dailyMoodsByDate: dailyMoodsByDate,
      fallbackEntries: entriesByDay[_dateKey(date)] ?? const <DiaryEntry>[],
    );
    if (mood != null) {
      values.add(mood);
    }
  }
  return values;
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
