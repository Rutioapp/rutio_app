import 'package:rutio/features/habits/application/count_habit_stats_aggregator.dart';

class CountHabitStatsAdapter {
  const CountHabitStatsAdapter._();

  static CountHabitStatsSummary fromDayBuckets({
    required Map<String, dynamic> habit,
    required String habitId,
    required Iterable<DateTime> scheduledDates,
    required Map<String, dynamic> historyCountValuesByDay,
    required Map<String, dynamic> historySkipsByDay,
    Map<String, dynamic> historyCompletionsByDay = const <String, dynamic>{},
    bool useCompletionFallbackWithoutValue = true,
  }) {
    final normalizedDates = scheduledDates.map(_dateOnly).toList()
      ..sort((a, b) => a.compareTo(b));
    if (normalizedDates.isEmpty) {
      return CountHabitStatsSummary.empty();
    }

    final valuesByDate = <String, dynamic>{};
    final skipsByDate = <String, dynamic>{};
    final completionsByDate = <String, dynamic>{};

    for (final day in normalizedDates) {
      final key = _dateKey(day);

      final valueMap = _asMap(historyCountValuesByDay[key]);
      final skipMap = _asMap(historySkipsByDay[key]);
      final completionMap = _asMap(historyCompletionsByDay[key]);

      if (valueMap.containsKey(habitId)) {
        valuesByDate[key] = valueMap[habitId];
      } else if (valueMap.containsKey(habitId.toString())) {
        valuesByDate[key] = valueMap[habitId.toString()];
      }

      if (skipMap.containsKey(habitId)) {
        skipsByDate[key] = skipMap[habitId];
      } else if (skipMap.containsKey(habitId.toString())) {
        skipsByDate[key] = skipMap[habitId.toString()];
      }

      if (completionMap.containsKey(habitId)) {
        completionsByDate[key] = completionMap[habitId];
      } else if (completionMap.containsKey(habitId.toString())) {
        completionsByDate[key] = completionMap[habitId.toString()];
      }
    }

    return CountHabitStatsAggregator.aggregate(
      habit: habit,
      startDate: normalizedDates.first,
      endDate: normalizedDates.last,
      scheduledDates: normalizedDates,
      countValuesByDate: valuesByDate,
      skipsByDate: skipsByDate,
      completionsByDate: completionsByDate,
      useCompletionFallbackWithoutValue: useCompletionFallbackWithoutValue,
    );
  }

  static String formatValueWithUnit(
    num value, {
    String? unit,
  }) {
    final normalizedValue = _formatNumber(value);
    final normalizedUnit = (unit ?? '').trim();
    if (normalizedUnit.isEmpty) return normalizedValue;
    return '$normalizedValue $normalizedUnit';
  }

  static String formatNumber(num value) => _formatNumber(value);

  static String _formatNumber(num value) {
    final asDouble = value.toDouble();
    if (asDouble.isNaN || asDouble.isInfinite) return '0';
    if (asDouble % 1 == 0) return asDouble.toInt().toString();
    return asDouble
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dateKey(DateTime d) {
    final normalized = _dateOnly(d);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is! Map) return const <String, dynamic>{};
    return Map<String, dynamic>.from(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
