import '../domain/weekly_report.dart';

/// Selects the metric representation that is safe to show in the report UI.
///
/// Legacy snapshots keep using their existing fields. Policy 2 snapshots use
/// raw counts for text and capped ratios for visual progress. Partial data is
/// only shown when the canonical field is present; unverifiable data never
/// falls back to a legacy count that may describe another quota.
abstract final class WeeklyReportMetricDisplay {
  static int? summaryCompleted(WeeklyReportSummary summary) =>
      _int(summary.dataQuality, summary.completedRaw, summary.completedCount);

  static int? summaryQuota(WeeklyReportSummary summary) =>
      _int(summary.dataQuality, summary.scheduledQuota, summary.scheduledCount);

  static double? summaryProgress(WeeklyReportSummary summary) =>
      _ratio(summary.dataQuality, summary.cappedRatio, summary.completionRate);

  static int? habitCompleted(WeeklyReportHabit habit) =>
      _int(habit.dataQuality, habit.completedRaw, habit.completedCount);

  static int? habitQuota(WeeklyReportHabit habit) =>
      _int(habit.dataQuality, habit.scheduledQuota, habit.scheduledCount);

  static double? habitProgress(WeeklyReportHabit habit) =>
      _ratio(habit.dataQuality, habit.cappedRatio, habit.completionRate);

  static int? historyCompleted(WeeklyReportHistoryItem item) =>
      _int(item.dataQuality, item.completedRaw, item.completedCount);

  static int? historyQuota(WeeklyReportHistoryItem item) =>
      _int(item.dataQuality, item.scheduledQuota, item.scheduledCount);

  static double? historyProgress(WeeklyReportHistoryItem item) =>
      _ratio(item.dataQuality, item.cappedRatio, item.completionRate);

  static bool hasQuota(int? quota) => quota != null && quota > 0;

  static int remaining(int? completed, int? quota) {
    if (completed == null || !hasQuota(quota)) return 0;
    return (quota! - completed).clamp(0, quota);
  }

  static bool achieved(int? completed, int? quota) =>
      hasQuota(quota) && completed != null && completed >= quota!;

  static int? _int(
      WeeklyReportDataQuality quality, int? canonical, int legacy) {
    if (quality == WeeklyReportDataQuality.unverifiable) return null;
    return quality == WeeklyReportDataQuality.legacy ? legacy : canonical;
  }

  static double? _ratio(
      WeeklyReportDataQuality quality, double? canonical, double? legacy) {
    final value =
        quality == WeeklyReportDataQuality.legacy ? legacy : canonical;
    if (value == null || !value.isFinite) return null;
    return value.clamp(0.0, 1.0);
  }
}
