import '../../habits/domain/metrics/habit_occurrence_result.dart';
import '../../habits/domain/metrics/habit_snapshot.dart';
import '../../habits/domain/metrics/weekly_habit_metrics.dart';
import '../../habits/domain/metrics/weekly_report_week.dart';
import '../../achievements/domain/models/habit_streak_snapshot.dart';

enum WeeklyReportStatus {
  provisional,
  finalized,
}

class WeeklyReportSummary {
  const WeeklyReportSummary({
    required this.scheduledCount,
    required this.completedCount,
    required this.completionRate,
    this.bestDay,
  });

  final int scheduledCount;
  final int completedCount;
  final double? completionRate;
  final WeeklyReportDay? bestDay;

  bool get hasScheduledCount => scheduledCount > 0;
}

enum WeeklyReportDayState {
  noPlan,
  scheduledIncomplete,
  partial,
  completed,
  skipped,
}

enum WeeklyReportHabitClassification {
  highlighted,
  stable,
  needsAttention,
  unavailable,
}

class WeeklyReportDay {
  const WeeklyReportDay({
    required this.date,
    required this.scheduledCount,
    required this.completedCount,
    required this.skippedCount,
    required this.completionRate,
    required this.state,
  });

  final DateTime date;
  final int scheduledCount;
  final int completedCount;
  final int skippedCount;
  final double? completionRate;
  final WeeklyReportDayState state;

  bool get isComparable => scheduledCount > 0;
}

class WeeklyReportHabit {
  const WeeklyReportHabit({
    required this.habitId,
    required this.name,
    required this.type,
    required this.schedule,
    required this.scheduledCount,
    required this.completedCount,
    required this.skippedCount,
    required this.completionRate,
    required this.occurrences,
    required this.classification,
    this.emoji,
    this.target,
    this.familyId,
    this.streakSnapshot,
    this.observationKey,
  });

  final String habitId;
  final String name;
  final String? emoji;
  final HabitKind type;
  final num? target;
  final String? familyId;
  final HabitSchedule schedule;
  final int scheduledCount;
  final int completedCount;
  final int skippedCount;
  final double? completionRate;
  final WeeklyReportHabitClassification classification;
  final List<HabitOccurrenceResult> occurrences;
  final HabitStreakSnapshot? streakSnapshot;
  final String? observationKey;

  bool get isComparable => scheduledCount > 0;
}

enum WeeklyReportTrendKind {
  improved,
  stable,
  declined,
  unavailable,
}

class WeeklyReportTrend {
  const WeeklyReportTrend({
    required this.kind,
    required this.delta,
    required this.comparable,
    required this.reason,
  });

  final WeeklyReportTrendKind kind;
  final double delta;
  final bool comparable;
  final String reason;
}

enum WeeklyReportRecommendationType {
  reduceFrequency,
  changeDays,
  simplifyTarget,
  changeMoment,
  keepStable,
}

class WeeklyReportRecommendation {
  const WeeklyReportRecommendation({
    required this.type,
    required this.reason,
    this.habitId,
    this.habitName,
    this.emoji,
    this.currentConfig = const <String, dynamic>{},
    this.proposedPatch = const <String, dynamic>{},
    this.policyVersion = 1,
  });

  final WeeklyReportRecommendationType type;
  final String reason;
  final String? habitId;
  final String? habitName;
  final String? emoji;
  final Map<String, dynamic> currentConfig;
  final Map<String, dynamic> proposedPatch;
  final int policyVersion;
}

class WeeklyReport {
  const WeeklyReport({
    required this.id,
    required this.userId,
    required this.week,
    required this.timezoneId,
    required this.status,
    required this.firstPartialWeek,
    required this.summary,
    required this.days,
    required this.habits,
    required this.trend,
    required this.schemaVersion,
    required this.metricsPolicyVersion,
    required this.contentVersion,
    this.generatedAt,
    this.refreshedAt,
    this.finalizedAt,
    this.recommendations = const <WeeklyReportRecommendation>[],
    this.summaryMessageKey,
  });

  final String id;
  final String userId;
  final WeeklyReportWeek week;
  final String timezoneId;
  final WeeklyReportStatus status;
  final bool firstPartialWeek;
  final WeeklyReportSummary summary;
  final List<WeeklyReportDay> days;
  final List<WeeklyReportHabit> habits;
  final WeeklyReportTrend trend;
  final int schemaVersion;
  final int metricsPolicyVersion;
  final int contentVersion;
  final DateTime? generatedAt;
  final DateTime? refreshedAt;
  final DateTime? finalizedAt;
  final List<WeeklyReportRecommendation> recommendations;
  final String? summaryMessageKey;

  bool get isFinal => status == WeeklyReportStatus.finalized;
  bool get isProvisional => status == WeeklyReportStatus.provisional;
}

class WeeklyReportHistoryItem {
  const WeeklyReportHistoryItem({
    required this.reportId,
    required this.week,
    required this.status,
    required this.completionRate,
    required this.completedCount,
    required this.scheduledCount,
    required this.firstPartialWeek,
    this.refreshedAt,
    this.finalizedAt,
  });

  final String reportId;
  final WeeklyReportWeek week;
  final WeeklyReportStatus status;
  final double? completionRate;
  final int completedCount;
  final int scheduledCount;
  final bool firstPartialWeek;
  final DateTime? refreshedAt;
  final DateTime? finalizedAt;
}

class WeeklyReportHistoryPage {
  const WeeklyReportHistoryPage(
      {required this.items, this.nextBeforeWeekStart});

  final List<WeeklyReportHistoryItem> items;
  final DateTime? nextBeforeWeekStart;
  bool get hasMore => nextBeforeWeekStart != null;
}

enum WeeklyReportDataSource { remoteFresh, cachedFinal, cachedProvisional }

class WeeklyReportSnapshot {
  const WeeklyReportSnapshot({
    required this.report,
    required this.source,
    required this.cachedAt,
    required this.isStale,
  });

  final WeeklyReport report;
  final WeeklyReportDataSource source;
  final DateTime? cachedAt;
  final bool isStale;
}

abstract interface class WeeklyReportRepository {
  Future<WeeklyReportSnapshot?> getLatest();
  Future<WeeklyReportSnapshot> getById(String reportId);
  Future<WeeklyReportSnapshot?> getByWeekStart(DateTime weekStartDate);
  Future<WeeklyReportHistoryPage> getHistory(
      {DateTime? beforeWeekStart, int limit = 20});
  Future<WeeklyReportSnapshot> refreshProvisional(DateTime weekStartDate);
  Future<void> activate({
    required DateTime activationLocalDate,
    required String timezoneName,
  });
}

WeeklyReportHabit weeklyReportHabitFromMetrics({
  required HabitSnapshot habit,
  required WeeklyHabitMetrics metrics,
  WeeklyReportHabitClassification classification =
      WeeklyReportHabitClassification.unavailable,
  HabitStreakSnapshot? streakSnapshot,
}) {
  return WeeklyReportHabit(
    habitId: habit.habitId,
    name: habit.name,
    emoji: habit.emoji,
    type: habit.kind,
    target: habit.target,
    familyId: habit.familyId,
    schedule: habit.schedule,
    scheduledCount: metrics.scheduledCount,
    completedCount: metrics.completedCount,
    skippedCount: metrics.skippedCount,
    completionRate: metrics.completionRate,
    classification: classification,
    occurrences: metrics.occurrences,
    streakSnapshot: streakSnapshot,
  );
}
