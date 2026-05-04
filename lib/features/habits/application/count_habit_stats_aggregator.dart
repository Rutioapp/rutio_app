import 'package:rutio/features/habits/domain/count_habit_progress.dart';

class CountHabitStatsPoint {
  const CountHabitStatsPoint({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final double value;
}

class CountHabitStatsSummary {
  const CountHabitStatsSummary({
    required this.totalAccumulated,
    required this.dailyAverage,
    required this.activeDayAverage,
    required this.bestDayValue,
    required this.bestDayDate,
    required this.completedDays,
    required this.partialProgressDays,
    required this.activityDays,
    required this.skippedDays,
    required this.scheduledDays,
    required this.averageCompletionRatio,
    required this.averageCompletionPercent,
    required this.seriesActualValues,
    required this.targetReferenceSeries,
  });

  factory CountHabitStatsSummary.empty() => const CountHabitStatsSummary(
        totalAccumulated: 0,
        dailyAverage: 0,
        activeDayAverage: 0,
        bestDayValue: 0,
        bestDayDate: null,
        completedDays: 0,
        partialProgressDays: 0,
        activityDays: 0,
        skippedDays: 0,
        scheduledDays: 0,
        averageCompletionRatio: 0,
        averageCompletionPercent: 0,
        seriesActualValues: <CountHabitStatsPoint>[],
        targetReferenceSeries: <CountHabitStatsPoint>[],
      );

  final double totalAccumulated;
  final double dailyAverage;
  final double activeDayAverage;
  final double bestDayValue;
  final DateTime? bestDayDate;
  final int completedDays;
  final int partialProgressDays;
  final int activityDays;
  final int skippedDays;
  final int scheduledDays;
  final double averageCompletionRatio;
  final double averageCompletionPercent;
  final List<CountHabitStatsPoint> seriesActualValues;
  final List<CountHabitStatsPoint> targetReferenceSeries;
}

class CountHabitStatsAggregator {
  const CountHabitStatsAggregator._();

  static CountHabitStatsSummary aggregate({
    required Map<String, dynamic> habit,
    required DateTime startDate,
    required DateTime endDate,
    Iterable<DateTime>? scheduledDates,
    bool Function(DateTime date)? isScheduledForDate,
    Map<String, dynamic> countValuesByDate = const <String, dynamic>{},
    Map<String, dynamic> skipsByDate = const <String, dynamic>{},
    Map<String, dynamic> completionsByDate = const <String, dynamic>{},
    bool useCompletionFallbackWithoutValue = false,
  }) {
    final normalizedStart = _dateOnly(startDate);
    final normalizedEnd = _dateOnly(endDate);
    final rangeStart = normalizedStart.isBefore(normalizedEnd)
        ? normalizedStart
        : normalizedEnd;
    final rangeEnd =
        normalizedStart.isAfter(normalizedEnd) ? normalizedStart : normalizedEnd;

    final selectedDates = _resolveScheduledDates(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      scheduledDates: scheduledDates,
      isScheduledForDate: isScheduledForDate,
    );
    if (selectedDates.isEmpty) {
      return CountHabitStatsSummary.empty();
    }

    final values = _normalizeByDateKey(countValuesByDate);
    final skips = _normalizeByDateKey(skipsByDate);
    final completions = _normalizeByDateKey(completionsByDate);

    var totalAccumulated = 0.0;
    var bestDayValue = 0.0;
    DateTime? bestDayDate;
    var completedDays = 0;
    var partialProgressDays = 0;
    var activityDays = 0;
    var skippedDays = 0;

    var ratioSum = 0.0;
    var ratioDays = 0;

    final seriesActualValues = <CountHabitStatsPoint>[];
    final targetReferenceSeries = <CountHabitStatsPoint>[];

    for (final day in selectedDates) {
      final dayKey = _dateKey(day);
      final hasExplicitValue = values.containsKey(dayKey);
      final rawValue = hasExplicitValue ? values[dayKey] : 0;
      final skipped = _asBool(skips[dayKey]);

      var progress = CountHabitProgress.fromHabitMap(
        habit,
        currentValue: rawValue,
        skipped: skipped,
      );

      if (useCompletionFallbackWithoutValue &&
          !hasExplicitValue &&
          !skipped &&
          _asBool(completions[dayKey])) {
        progress = CountHabitProgress.fromHabitMap(
          habit,
          currentValue: progress.effectiveTarget,
          skipped: false,
        );
      }

      seriesActualValues.add(
        CountHabitStatsPoint(date: day, value: progress.currentValue),
      );
      targetReferenceSeries.add(
        CountHabitStatsPoint(date: day, value: progress.effectiveTarget),
      );

      if (progress.isSkipped) {
        skippedDays++;
        continue;
      }

      totalAccumulated += progress.currentValue;

      if (progress.currentValue > bestDayValue) {
        bestDayValue = progress.currentValue;
        bestDayDate = day;
      }
      if (progress.isCompleted) {
        completedDays++;
      }
      if (progress.hasPartialProgress) {
        partialProgressDays++;
      }
      if (progress.currentValue > 0) {
        activityDays++;
      }

      ratioSum += progress.completionRatio;
      ratioDays++;
    }

    final scheduledDays = selectedDates.length;
    final averageCompletionRatio =
        (ratioDays == 0 ? 0.0 : (ratioSum / ratioDays)).clamp(0.0, 1.0);
    final averageCompletionPercent =
        (averageCompletionRatio * 100.0).clamp(0.0, 100.0);

    return CountHabitStatsSummary(
      totalAccumulated: totalAccumulated,
      dailyAverage:
          scheduledDays == 0 ? 0.0 : (totalAccumulated / scheduledDays),
      activeDayAverage: activityDays == 0 ? 0.0 : (totalAccumulated / activityDays),
      bestDayValue: bestDayValue,
      bestDayDate: bestDayDate,
      completedDays: completedDays,
      partialProgressDays: partialProgressDays,
      activityDays: activityDays,
      skippedDays: skippedDays,
      scheduledDays: scheduledDays,
      averageCompletionRatio: averageCompletionRatio,
      averageCompletionPercent: averageCompletionPercent,
      seriesActualValues: seriesActualValues,
      targetReferenceSeries: targetReferenceSeries,
    );
  }

  static List<DateTime> _resolveScheduledDates({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Iterable<DateTime>? scheduledDates,
    required bool Function(DateTime date)? isScheduledForDate,
  }) {
    if (scheduledDates != null) {
      final dedup = <String, DateTime>{};
      for (final date in scheduledDates) {
        final normalized = _dateOnly(date);
        if (normalized.isBefore(rangeStart) || normalized.isAfter(rangeEnd)) {
          continue;
        }
        dedup[_dateKey(normalized)] = normalized;
      }
      final out = dedup.values.toList()..sort((a, b) => a.compareTo(b));
      return out;
    }

    final out = <DateTime>[];
    DateTime cursor = rangeStart;
    while (!cursor.isAfter(rangeEnd)) {
      if (isScheduledForDate?.call(cursor) ?? true) {
        out.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  static Map<String, dynamic> _normalizeByDateKey(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    for (final entry in raw.entries) {
      final key = _normalizeKey(entry.key);
      if (key == null) continue;
      out[key] = entry.value;
    }
    return out;
  }

  static String? _normalizeKey(dynamic rawKey) {
    if (rawKey is DateTime) return _dateKey(rawKey);

    final asText = rawKey.toString().trim();
    if (asText.isEmpty) return null;
    final parsed = DateTime.tryParse(asText);
    if (parsed != null) return _dateKey(parsed);
    return null;
  }

  static bool _asBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw > 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return false;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dateKey(DateTime d) {
    final normalized = _dateOnly(d);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
