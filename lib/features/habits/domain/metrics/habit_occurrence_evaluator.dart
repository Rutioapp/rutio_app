import 'habit_date_utils.dart';
import 'habit_occurrence_result.dart';
import 'habit_snapshot.dart';
import 'times_per_week_quota_policy.dart';
import 'weekly_habit_metrics.dart';
import 'weekly_report_week.dart';

class HabitOccurrenceEvaluator {
  const HabitOccurrenceEvaluator({
    this.quotaPolicy = const TimesPerWeekQuotaPolicy.proratedCeil(),
  });

  final TimesPerWeekQuotaPolicy quotaPolicy;

  HabitOccurrenceResult evaluate({
    required HabitSnapshot habit,
    required DateTime date,
    required bool completed,
    required bool skipped,
    num? progress,
    num? target,
  }) {
    final normalizedDate = dateOnly(date);
    final normalizedTarget = target ?? habit.target;
    final isCount = habit.isCount;
    final dateBoundScheduled =
        habit.schedule.scheduledForDate(normalizedDate) &&
            _isHabitActiveOnDate(habit, normalizedDate);

    if (habit.schedule.isTimesPerWeek) {
      return HabitOccurrenceResult(
        date: normalizedDate,
        scope: HabitOccurrenceScope.weeklyQuota,
        scheduleType: habit.schedule.type,
        scheduled: false,
        completed: completed && !skipped,
        skipped: skipped,
        progress: isCount ? (progress ?? 0) : null,
        target: normalizedTarget,
      );
    }

    if (isCount) {
      final actualProgress = progress ?? 0;
      final countCompleted = actualProgress >= (normalizedTarget ?? 1);
      return HabitOccurrenceResult(
        date: normalizedDate,
        scope: HabitOccurrenceScope.dateBound,
        scheduleType: habit.schedule.type,
        scheduled: dateBoundScheduled,
        completed:
            dateBoundScheduled && !skipped && (completed || countCompleted),
        skipped: skipped,
        progress: actualProgress,
        target: normalizedTarget,
      );
    }

    return HabitOccurrenceResult(
      date: normalizedDate,
      scope: HabitOccurrenceScope.dateBound,
      scheduleType: habit.schedule.type,
      scheduled: dateBoundScheduled,
      completed: dateBoundScheduled && !skipped && completed,
      skipped: skipped,
      progress: progress,
      target: normalizedTarget,
    );
  }

  WeeklyHabitMetrics evaluateWeeklyMetrics({
    required HabitSnapshot habit,
    required WeeklyReportWeek week,
    required List<HabitOccurrenceResult> occurrences,
    DateTime? activeFrom,
    DateTime? activeUntil,
  }) {
    return WeeklyHabitMetrics.fromOccurrences(
      habit: habit,
      week: week,
      occurrences: occurrences,
      activeFrom: activeFrom,
      activeUntil: activeUntil,
      quotaPolicy: quotaPolicy,
    );
  }

  TimesPerWeekQuotaResult effectiveScheduledQuota({
    required HabitSnapshot habit,
    required WeeklyReportWeek week,
    DateTime? activeFrom,
    DateTime? activeUntil,
  }) {
    final configured = habit.schedule.timesPerWeek ?? 1;
    return calculateEffectiveScheduledQuota(
      configuredTimesPerWeek: configured,
      week: week,
      activeFrom: activeFrom ?? habit.createdAt,
      activeUntil: activeUntil,
      policy: quotaPolicy,
    );
  }

  bool _isHabitActiveOnDate(HabitSnapshot habit, DateTime date) {
    if (habit.archived) return false;
    final createdAt = habit.createdAt;
    if (createdAt == null) return true;
    return !dateOnly(createdAt).isAfter(dateOnly(date));
  }
}
