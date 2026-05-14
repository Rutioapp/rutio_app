import 'package:flutter/widgets.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

HabitStatsShellData buildHabitStatsShellData(BuildContext context, dynamic habit) {
  final l10n = context.l10n;
  final habitMap = _habitToMap(habit);
  final typeRaw = (habitMap['type'] ?? habitMap['habitType'] ?? '').toString();
  final isCounter = typeRaw.toLowerCase().contains('count') ||
      typeRaw.toLowerCase().contains('counter');

  final title = _stringFromAny(
        habitMap['title'],
        fallback: _stringFromAny(
          habitMap['name'],
          fallback: l10n.habitStatsHabitFallbackTitle,
        ),
      ) ??
      l10n.habitStatsHabitFallbackTitle;
  final familyName = _resolveFamilyName(l10n, habitMap['familyId']?.toString());
  final objective = _objectiveSummary(l10n, habitMap, isCounter);
  final countsByDay = _extractCountsByDay(habitMap);
  final currentStreak = _currentStreak(countsByDay);
  final bestStreak = _bestStreak(countsByDay);
  final completedDays = countsByDay.values.where((value) => value > 0).length;
  final totalCompletions = countsByDay.values.fold(0, (sum, value) => sum + value);
  final targetValue = _asInt(
        habitMap['timesPerWeek'] ??
            habitMap['weeklyTarget'] ??
            habitMap['target'] ??
            habitMap['goal'],
      ) ??
      0;

  final subtitle = objective.isEmpty ? familyName : '$familyName · $objective';

  return HabitStatsShellData(
    title: title,
    subtitle: subtitle,
    typeLabel: isCounter ? l10n.habitConfigCounterOption : l10n.habitConfigCheckOption,
    isCounter: isCounter,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    completedDays: completedDays,
    totalCompletions: totalCompletions,
    targetValue: targetValue,
    countsByDay: countsByDay,
  );
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

String _objectiveSummary(
  dynamic l10n,
  Map<String, dynamic> habitMap,
  bool isCounter,
) {
  final explicit = _stringFromAny(
    habitMap['objective'],
    fallback: _stringFromAny(habitMap['description']),
  );
  if (explicit != null && explicit.trim().isNotEmpty) {
    return explicit.trim();
  }

  final targetValue = _asInt(
    habitMap['timesPerWeek'] ??
        habitMap['weeklyTarget'] ??
        habitMap['target'] ??
        habitMap['goal'],
  );
  if (targetValue == null || targetValue <= 0) return '';

  final unit = _stringFromAny(habitMap['unit'])?.trim();
  if (isCounter && unit != null && unit.isNotEmpty) {
    return '$targetValue $unit';
  }
  return l10n.habitStatsMetricCompletionDescription(targetValue, 7);
}

Map<DateTime, int> _extractCountsByDay(Map<String, dynamic> habitMap) {
  final out = <DateTime, int>{};
  const historyKeys = <String>[
    'history',
    'completions',
    'checkins',
    'checkIns',
    'doneDates',
    'completedDates',
    'completionDates',
    'records',
  ];

  for (final key in historyKeys) {
    final value = habitMap[key];
    if (value == null) continue;
    _consumeHistoryValue(value, out);
  }

  final lastDone = _tryParseDate(habitMap['lastDoneAt'] ?? habitMap['lastCompletedAt']);
  if (lastDone != null) {
    final date = _dateOnly(lastDone);
    out[date] = (out[date] ?? 0) + 1;
  }

  return out;
}

void _consumeHistoryValue(dynamic value, Map<DateTime, int> out) {
  if (value is List) {
    for (final item in value) {
      if (item is Map) {
        final done = item['done'] ?? item['completed'] ?? item['isDone'] ?? true;
        if (done == false) continue;
        final date = _tryParseDate(
          item['date'] ?? item['day'] ?? item['ts'] ?? item['time'] ?? item['completedAt'],
        );
        if (date == null) continue;
        final amount = _asInt(item['count']) ?? 1;
        final key = _dateOnly(date);
        out[key] = (out[key] ?? 0) + (amount > 0 ? amount : 1);
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
      final key = _dateOnly(date);
      final item = entry.value;
      if (item == true) {
        out[key] = (out[key] ?? 0) + 1;
      } else {
        final amount = _asInt(item);
        if (amount != null && amount > 0) {
          out[key] = (out[key] ?? 0) + amount;
        }
      }
    }
  }
}

int _currentStreak(Map<DateTime, int> countsByDay) {
  if (countsByDay.isEmpty) return 0;
  var streak = 0;
  var cursor = _dateOnly(DateTime.now());
  while ((countsByDay[cursor] ?? 0) > 0) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int _bestStreak(Map<DateTime, int> countsByDay) {
  if (countsByDay.isEmpty) return 0;
  final days = countsByDay.keys.toList()..sort();
  var best = 0;
  var current = 0;
  DateTime? prev;
  for (final day in days) {
    if ((countsByDay[day] ?? 0) <= 0) continue;
    if (prev == null) {
      current = 1;
    } else {
      current = day.difference(prev).inDays == 1 ? current + 1 : 1;
    }
    if (current > best) best = current;
    prev = day;
  }
  return best;
}

DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return null;
    }
  }
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _stringFromAny(dynamic value, {String? fallback}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.trim().isEmpty ? fallback : text;
}
