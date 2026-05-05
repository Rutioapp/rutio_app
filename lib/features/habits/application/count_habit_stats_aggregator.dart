import '../../statistics/domain/statistics_models.dart';
import '../../statistics/domain/statistics_range.dart';

class CountHabitStatsAggregator {
  const CountHabitStatsAggregator();

  CountHabitProgressSnapshot aggregate({
    required int target,
    required StatisticsRange range,
    required Map<DateTime, int> rawValuesByDay,
  }) {
    final safeTarget = target <= 0 ? 1 : target;

    var goalCompletedDays = 0;
    var partialProgressDays = 0;
    var totalAccumulated = 0;
    var activeDays = 0;
    var bestDay = 0;
    var complianceAccumulated = 0.0;

    for (final day in range.days) {
      final raw = rawValuesByDay[_dateOnly(day)] ?? 0;
      totalAccumulated += raw;
      if (raw > 0) {
        activeDays++;
      }
      if (raw > bestDay) {
        bestDay = raw;
      }
      if (raw >= safeTarget) {
        goalCompletedDays++;
      } else if (raw > 0) {
        partialProgressDays++;
      }

      complianceAccumulated += (raw / safeTarget).clamp(0.0, 1.0);
    }

    final days = range.lengthInDays;
    final dailyAverage = days == 0 ? 0.0 : totalAccumulated / days;
    final activeDayAverage =
        activeDays == 0 ? 0.0 : totalAccumulated / activeDays;
    final compliancePct = days == 0 ? 0.0 : (complianceAccumulated / days) * 100;

    final currentGoalStreak = _currentGoalStreak(
      rawValuesByDay: rawValuesByDay,
      target: safeTarget,
      anchor: range.end,
    );

    return CountHabitProgressSnapshot(
      target: safeTarget,
      goalCompletedDays: goalCompletedDays,
      partialProgressDays: partialProgressDays,
      totalAccumulated: totalAccumulated,
      activeDays: activeDays,
      bestDay: bestDay,
      dailyAverage: dailyAverage,
      activeDayAverage: activeDayAverage,
      compliancePct: compliancePct,
      currentGoalStreak: currentGoalStreak,
    );
  }

  int _currentGoalStreak({
    required Map<DateTime, int> rawValuesByDay,
    required int target,
    required DateTime anchor,
  }) {
    var streak = 0;
    var cursor = _dateOnly(anchor);

    while (true) {
      final value = rawValuesByDay[cursor] ?? 0;
      if (value < target) {
        break;
      }
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
