import 'flexible_weekly_quota.dart';
import 'habit_date_utils.dart';
import 'weekly_report_week.dart';

class FlexibleWeeklyQuotaPeriodResult {
  const FlexibleWeeklyQuotaPeriodResult({
    required this.startDate,
    required this.endDate,
    required this.weeklyResults,
    required this.completedCount,
    required this.scheduledCount,
    required this.dataQuality,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<FlexibleWeeklyQuotaResult> weeklyResults;
  final int completedCount;
  final int scheduledCount;
  final FlexibleWeeklyDataQuality dataQuality;

  bool get isUnverifiable =>
      dataQuality == FlexibleWeeklyDataQuality.unverifiable;
  double get rawRatio =>
      scheduledCount <= 0 ? 0 : completedCount / scheduledCount;
  double get cappedRatio => rawRatio.clamp(0.0, 1.0);
}

/// Aggregates flexible CHECK quotas over local date ranges.
///
/// A date belongs to at most one weekly result. Range slices use one quota
/// calculation for their intersected week, so crossing a month/year boundary
/// cannot duplicate a full weekly quota.
class FlexibleWeeklyQuotaPeriodAggregator {
  const FlexibleWeeklyQuotaPeriodAggregator({
    this.evaluator = const FlexibleWeeklyQuotaEvaluator(),
  });

  final FlexibleWeeklyQuotaEvaluator evaluator;

  FlexibleWeeklyQuotaPeriodResult aggregate({
    required FlexibleWeeklyQuotaHabit habit,
    required Map<String, dynamic> history,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? currentWeekDate,
  }) {
    final from = dateOnly(startDate);
    final to = dateOnly(endDate);
    if (to.isBefore(from)) {
      return FlexibleWeeklyQuotaPeriodResult(
        startDate: from,
        endDate: to,
        weeklyResults: const <FlexibleWeeklyQuotaResult>[],
        completedCount: 0,
        scheduledCount: 0,
        dataQuality: FlexibleWeeklyDataQuality.verified,
      );
    }

    final results = <FlexibleWeeklyQuotaResult>[];
    var weekStart = _weekStartForDate(from, habit.weekStartsOn);
    while (!weekStart.isAfter(to)) {
      final week = _weekForDate(weekStart, habit.weekStartsOn);
      final result = evaluator.evaluate(
        habit: habit,
        week: week,
        history: history,
        rangeStart: from,
        rangeEnd: to,
        currentWeek: currentWeekDate != null && week.contains(currentWeekDate),
      );
      if (result.eligibleDays > 0 || result.scheduledQuota > 0) {
        results.add(result);
      }
      weekStart = week.weekEndDate.add(const Duration(days: 1));
    }

    var completed = 0;
    var scheduled = 0;
    var quality = FlexibleWeeklyDataQuality.verified;
    for (final result in results) {
      completed += result.completedDays;
      scheduled += result.scheduledQuota;
      quality = _mergeQuality(quality, result.dataQuality);
    }

    return FlexibleWeeklyQuotaPeriodResult(
      startDate: from,
      endDate: to,
      weeklyResults: List<FlexibleWeeklyQuotaResult>.unmodifiable(results),
      completedCount: completed,
      scheduledCount: scheduled,
      dataQuality: quality,
    );
  }
}

WeeklyReportWeek _weekForDate(DateTime date, int weekStartsOn) {
  final start = _weekStartForDate(date, weekStartsOn);
  return WeeklyReportWeek(
    weekStartDate: start,
    weekEndDate: start.add(const Duration(days: 6)),
  );
}

DateTime _weekStartForDate(DateTime date, int weekStartsOn) {
  final normalized = dateOnly(date);
  final delta = (normalized.weekday - weekStartsOn + DateTime.daysPerWeek) %
      DateTime.daysPerWeek;
  return normalized.subtract(Duration(days: delta));
}

FlexibleWeeklyDataQuality _mergeQuality(
  FlexibleWeeklyDataQuality current,
  FlexibleWeeklyDataQuality next,
) {
  if (current == FlexibleWeeklyDataQuality.unverifiable ||
      next == FlexibleWeeklyDataQuality.unverifiable) {
    return FlexibleWeeklyDataQuality.unverifiable;
  }
  if (current == FlexibleWeeklyDataQuality.currentConfigFallback ||
      next == FlexibleWeeklyDataQuality.currentConfigFallback) {
    return FlexibleWeeklyDataQuality.currentConfigFallback;
  }
  return FlexibleWeeklyDataQuality.verified;
}
