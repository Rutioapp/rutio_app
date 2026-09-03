import '../../domain/weekly_report.dart';
import '../../../achievements/domain/models/habit_streak_snapshot.dart';
import '../../../habits/domain/metrics/habit_occurrence_result.dart';
import '../../../habits/domain/metrics/habit_snapshot.dart';
import '../../../habits/domain/metrics/weekly_report_week.dart';
import 'remote_weekly_report.dart';

WeeklyReport mapRemoteWeeklyReport(RemoteWeeklyReport remote) {
  final h = remote.report;
  return WeeklyReport(
    id: h.id,
    userId: h.userId,
    week: WeeklyReportWeek(
        weekStartDate: _date(h.weekStartDate),
        weekEndDate: _date(h.weekEndDate)),
    timezoneId: h.timezoneId,
    status: _status(h.status),
    firstPartialWeek: h.firstPartialWeek,
    summary: WeeklyReportSummary(
        scheduledCount: h.scheduledCount,
        completedCount: h.completedCount,
        completionRate: h.completionRate),
    days: remote.days
        .map((d) => WeeklyReportDay(
            date: _date(d.date),
            scheduledCount: d.scheduledCount,
            completedCount: d.completedCount,
            skippedCount: d.skippedCount,
            completionRate: d.completionRate,
            state: _dayState(d.state)))
        .toList(growable: false),
    habits: remote.habits.map(_habit).toList(growable: false),
    trend: WeeklyReportTrend(
        kind: _trend(h.trendKind),
        delta: h.trendDelta ?? 0,
        comparable: h.trendKind != 'unavailable' && h.trendDelta != null,
        reason: h.comparabilityReason ?? ''),
    schemaVersion: remote.schemaVersion,
    metricsPolicyVersion: remote.metricsPolicyVersion,
    contentVersion: remote.contentVersion,
    generatedAt: h.generatedAt,
    refreshedAt: h.refreshedAt,
    finalizedAt: h.finalizedAt,
    recommendations: remote.recommendations
        .map((r) => WeeklyReportRecommendation(
            type: _recommendation(r.type),
            reason: r.reason,
            habitId: r.habitId,
            habitName: r.habitName,
            emoji: r.emoji,
            currentConfig: r.currentConfig,
            proposedPatch: r.proposedPatch,
            policyVersion: r.policyVersion))
        .toList(growable: false),
  );
}

WeeklyReportHabit _habit(RemoteWeeklyReportHabit h) => WeeklyReportHabit(
      habitId: h.habitId,
      name: h.name,
      emoji: h.emoji,
      familyId: h.familyId,
      type: HabitKindX.fromString(h.type),
      target: h.target,
      schedule: _schedule(h.schedule),
      scheduledCount: h.scheduledCount,
      completedCount: h.completedCount,
      skippedCount: h.skippedCount,
      completionRate: h.completionRate,
      classification: _classification(h.classification),
      occurrences: h.occurrences.map(_occurrence).toList(growable: false),
      streakSnapshot:
          h.streakSnapshot == null ? null : _streakSnapshot(h.streakSnapshot!),
    );

HabitStreakSnapshot _streakSnapshot(Map<String, dynamic> value) =>
    HabitStreakSnapshot(
      habitId: _streakString(value, 'habitId'),
      currentStreak: _streakInt(value, 'currentStreak'),
      bestStreak: _streakInt(value, 'bestStreak'),
      totalCompletedDays: _streakInt(value, 'totalCompletedDays'),
    );

String _streakString(Map<String, dynamic> value, String camelKey) =>
    (value[camelKey] ?? value[_snake(camelKey)]) as String;

int _streakInt(Map<String, dynamic> value, String camelKey) =>
    ((value[camelKey] ?? value[_snake(camelKey)]) as num).toInt();

String _snake(String value) => value.replaceAllMapped(
    RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');

WeeklyReportHabitClassification _classification(String? value) =>
    switch (value) {
      'highlighted' => WeeklyReportHabitClassification.highlighted,
      'stable' => WeeklyReportHabitClassification.stable,
      'needs_attention' => WeeklyReportHabitClassification.needsAttention,
      'unavailable' => WeeklyReportHabitClassification.unavailable,
      _ => WeeklyReportHabitClassification.unavailable,
    };

HabitOccurrenceResult _occurrence(Map<String, dynamic> o) =>
    HabitOccurrenceResult(
      date: _date(o['date'] as String),
      scope: o['scope'] == 'weeklyQuota'
          ? HabitOccurrenceScope.weeklyQuota
          : HabitOccurrenceScope.dateBound,
      scheduleType: HabitScheduleTypeX.fromString(o['scheduleType'] as String),
      scheduled: o['scheduled'] as bool,
      completed: o['completed'] as bool,
      skipped: o['skipped'] as bool,
      progress: o['progress'] as num?,
      target: o['target'] as num?,
      weeklyQuotaMet: o['weeklyQuotaMet'] as bool? ?? false,
      weeklyScheduledCount: (o['weeklyScheduledCount'] as num?)?.toInt(),
      weeklyCompletedCount: (o['weeklyCompletedCount'] as num?)?.toInt(),
    );

HabitSchedule _schedule(Map<String, dynamic> s) {
  final type = HabitScheduleTypeX.fromString(s['type'] as String?);
  switch (type) {
    case HabitScheduleType.daily:
      return HabitSchedule.daily();
    case HabitScheduleType.weekly:
      return HabitSchedule.weekly(
          weekdays: (s['weekdays'] as List? ?? const [])
              .whereType<num>()
              .map((e) => e.toInt())
              .toList());
    case HabitScheduleType.once:
      return HabitSchedule.once(
          date: _date(s['date'] as String? ?? '1970-01-01'));
    case HabitScheduleType.timesPerWeek:
      return HabitSchedule.timesPerWeek(
          timesPerWeek: (s['timesPerWeek'] as num?)?.toInt() ?? 1,
          weekStartsOn:
              (s['weekStartsOn'] as num?)?.toInt() ?? DateTime.monday);
  }
}

DateTime _date(String value) => DateTime.parse(value).toLocal();
WeeklyReportStatus _status(String v) => v == 'final'
    ? WeeklyReportStatus.finalized
    : WeeklyReportStatus.provisional;
WeeklyReportDayState _dayState(String v) =>
    WeeklyReportDayState.values.firstWhere((e) => e.name == v);
WeeklyReportTrendKind _trend(String v) =>
    WeeklyReportTrendKind.values.firstWhere((e) => e.name == v);
WeeklyReportRecommendationType _recommendation(String v) =>
    WeeklyReportRecommendationType.values.firstWhere((e) => e.name == v);
