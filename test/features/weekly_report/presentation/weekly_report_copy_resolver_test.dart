import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';
import 'package:rutio/features/weekly_report/presentation/weekly_report_copy_resolver.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/l10n/gen/app_localizations_es.dart';

WeeklyReport _report(
        {String? key, bool provisional = false, int scheduled = 4}) =>
    WeeklyReport(
      id: 'r',
      userId: 'u',
      week: WeeklyReportWeek.fromDate(DateTime(2026, 8, 31)),
      timezoneId: 'Europe/Madrid',
      status: provisional
          ? WeeklyReportStatus.provisional
          : WeeklyReportStatus.finalized,
      firstPartialWeek: false,
      summary: WeeklyReportSummary(
          scheduledCount: scheduled,
          completedCount: 3,
          completionRate: scheduled == 0 ? null : .75),
      days: const [],
      habits: const [],
      trend: const WeeklyReportTrend(
          kind: WeeklyReportTrendKind.unavailable,
          delta: 0,
          comparable: false,
          reason: ''),
      schemaVersion: 1,
      metricsPolicyVersion: 1,
      contentVersion: 1,
      summaryMessageKey: key,
    );

void main() {
  test('same key resolves to the active language', () {
    final report = _report(key: 'weekly_report_summary_strong_01');
    expect(WeeklyReportCopyResolver.summary(AppLocalizationsEs(), report),
        contains('sólido'));
    expect(WeeklyReportCopyResolver.summary(AppLocalizationsEn(), report),
        contains('solid'));
  });

  test('unknown and legacy keys use a safe neutral fallback', () {
    expect(WeeklyReportCopyResolver.summary(AppLocalizationsEs(), _report()),
        contains('buena'));
    expect(
        WeeklyReportCopyResolver.summary(
            AppLocalizationsEn(), _report(key: 'future_key')),
        contains('good'));
    expect(
        WeeklyReportCopyResolver.summary(
            AppLocalizationsEs(), _report(provisional: true)),
        contains('Por ahora'));
  });
}
