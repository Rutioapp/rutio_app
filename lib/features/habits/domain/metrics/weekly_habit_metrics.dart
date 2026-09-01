import 'habit_occurrence_result.dart';
import 'habit_snapshot.dart';
import 'times_per_week_quota_policy.dart';
import 'weekly_report_week.dart';

class WeeklyHabitMetrics {
  const WeeklyHabitMetrics({
    required this.scheduledCount,
    required this.completedCount,
    required this.skippedCount,
    required this.partialCount,
    required this.totalProgress,
    required this.totalTarget,
    required this.occurrences,
    this.completionRate,
    this.progressRate,
  });

  final int scheduledCount;
  final int completedCount;
  final int skippedCount;
  final int partialCount;
  final num totalProgress;
  final num totalTarget;
  final double? completionRate;
  final double? progressRate;
  final List<HabitOccurrenceResult> occurrences;

  bool get isComparable => scheduledCount > 0;
  bool get hasCountProgress => totalTarget > 0;

  WeeklyHabitMetrics copyWith({
    int? scheduledCount,
    int? completedCount,
    int? skippedCount,
    int? partialCount,
    num? totalProgress,
    num? totalTarget,
    bool clearCompletionRate = false,
    double? completionRate,
    bool clearProgressRate = false,
    double? progressRate,
    List<HabitOccurrenceResult>? occurrences,
  }) {
    return WeeklyHabitMetrics(
      scheduledCount: scheduledCount ?? this.scheduledCount,
      completedCount: completedCount ?? this.completedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      partialCount: partialCount ?? this.partialCount,
      totalProgress: totalProgress ?? this.totalProgress,
      totalTarget: totalTarget ?? this.totalTarget,
      completionRate:
          clearCompletionRate ? null : completionRate ?? this.completionRate,
      progressRate:
          clearProgressRate ? null : progressRate ?? this.progressRate,
      occurrences: occurrences ?? this.occurrences,
    );
  }

  factory WeeklyHabitMetrics.fromOccurrences({
    required HabitSnapshot habit,
    required WeeklyReportWeek week,
    required List<HabitOccurrenceResult> occurrences,
    DateTime? activeFrom,
    DateTime? activeUntil,
    TimesPerWeekQuotaPolicy quotaPolicy =
        const TimesPerWeekQuotaPolicy.proratedCeil(),
  }) {
    final weekOccurrences = occurrences
        .where((occurrence) => week.contains(occurrence.date))
        .toList(growable: false);

    if (habit.schedule.isTimesPerWeek) {
      final configured = habit.schedule.timesPerWeek ?? 1;
      final quota = calculateEffectiveScheduledQuota(
        configuredTimesPerWeek: configured,
        week: week,
        activeFrom: activeFrom ?? habit.createdAt,
        activeUntil: activeUntil,
        policy: quotaPolicy,
      );
      final rawCompletedCount = weekOccurrences
          .where((occurrence) => occurrence.completed && !occurrence.skipped)
          .length;
      final skippedCount =
          weekOccurrences.where((occurrence) => occurrence.skipped).length;
      final partialCount = weekOccurrences
          .where((occurrence) => occurrence.isPartialProgress)
          .length;
      return WeeklyHabitMetrics(
        scheduledCount: quota.scheduledCount,
        completedCount: rawCompletedCount.clamp(0, quota.scheduledCount),
        skippedCount: skippedCount,
        partialCount: partialCount,
        totalProgress: _sumProgress(weekOccurrences),
        totalTarget: _sumTarget(weekOccurrences),
        completionRate: quota.scheduledCount <= 0
            ? null
            : (rawCompletedCount.clamp(0, quota.scheduledCount) /
                quota.scheduledCount),
        progressRate: _progressRate(weekOccurrences),
        occurrences: List<HabitOccurrenceResult>.unmodifiable(weekOccurrences),
      );
    }

    final scheduledOccurrences = weekOccurrences
        .where((occurrence) => occurrence.scheduled)
        .toList(growable: false);
    final completedCount = scheduledOccurrences
        .where((occurrence) => occurrence.completed && !occurrence.skipped)
        .length;
    final skippedCount =
        scheduledOccurrences.where((occurrence) => occurrence.skipped).length;
    final partialCount = scheduledOccurrences
        .where((occurrence) => occurrence.isPartialProgress)
        .length;
    final scheduledCount = scheduledOccurrences.length;
    return WeeklyHabitMetrics(
      scheduledCount: scheduledCount,
      completedCount: completedCount.clamp(0, scheduledCount),
      skippedCount: skippedCount,
      partialCount: partialCount,
      totalProgress: _sumProgress(scheduledOccurrences),
      totalTarget: _sumTarget(scheduledOccurrences),
      completionRate: scheduledCount <= 0
          ? null
          : completedCount.clamp(0, scheduledCount) / scheduledCount,
      progressRate: _progressRate(scheduledOccurrences),
      occurrences: List<HabitOccurrenceResult>.unmodifiable(weekOccurrences),
    );
  }
}

num _sumProgress(Iterable<HabitOccurrenceResult> occurrences) {
  var total = 0.0;
  for (final occurrence in occurrences) {
    total += (occurrence.progress ?? 0).toDouble();
  }
  return total;
}

num _sumTarget(Iterable<HabitOccurrenceResult> occurrences) {
  var total = 0.0;
  for (final occurrence in occurrences) {
    total += (occurrence.target ?? 0).toDouble();
  }
  return total;
}

double? _progressRate(Iterable<HabitOccurrenceResult> occurrences) {
  final totalTarget = _sumTarget(occurrences).toDouble();
  if (totalTarget <= 0) return null;
  return _sumProgress(occurrences).toDouble() / totalTarget;
}
