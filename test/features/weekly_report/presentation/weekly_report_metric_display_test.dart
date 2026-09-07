import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';
import 'package:rutio/features/weekly_report/presentation/weekly_report_metric_display.dart';

void main() {
  test('policy 2 keeps raw counts and caps visual progress', () {
    const summary = WeeklyReportSummary(
      scheduledCount: 3,
      completedCount: 3,
      completionRate: 1,
      completedRaw: 4,
      scheduledQuota: 3,
      rawRatio: 4 / 3,
      cappedRatio: 1,
      dataQuality: WeeklyReportDataQuality.verified,
    );

    expect(WeeklyReportMetricDisplay.summaryCompleted(summary), 4);
    expect(WeeklyReportMetricDisplay.summaryQuota(summary), 3);
    expect(WeeklyReportMetricDisplay.summaryProgress(summary), 1);
    expect(WeeklyReportMetricDisplay.remaining(4, 3), 0);
    expect(WeeklyReportMetricDisplay.achieved(4, 3), isTrue);
  });

  test('legacy snapshots retain their established fields', () {
    const summary = WeeklyReportSummary(
      scheduledCount: 3,
      completedCount: 2,
      completionRate: 2 / 3,
    );

    expect(WeeklyReportMetricDisplay.summaryCompleted(summary), 2);
    expect(WeeklyReportMetricDisplay.summaryQuota(summary), 3);
    expect(WeeklyReportMetricDisplay.summaryProgress(summary), 2 / 3);
  });

  test('partial and unverifiable data do not invent canonical values', () {
    const partial = WeeklyReportSummary(
      scheduledCount: 3,
      completedCount: 2,
      completionRate: 2 / 3,
      dataQuality: WeeklyReportDataQuality.partial,
    );
    const unverifiable = WeeklyReportSummary(
      scheduledCount: 3,
      completedCount: 2,
      completionRate: 2 / 3,
      dataQuality: WeeklyReportDataQuality.unverifiable,
    );

    expect(WeeklyReportMetricDisplay.summaryCompleted(partial), isNull);
    expect(WeeklyReportMetricDisplay.summaryProgress(partial), isNull);
    expect(WeeklyReportMetricDisplay.summaryQuota(unverifiable), isNull);
    expect(WeeklyReportMetricDisplay.remaining(2, null), 0);
    expect(WeeklyReportMetricDisplay.achieved(2, null), isFalse);
  });

  test('zero quota is unavailable rather than 0/0 at 100 percent', () {
    expect(WeeklyReportMetricDisplay.hasQuota(0), isFalse);
    expect(WeeklyReportMetricDisplay.remaining(0, 0), 0);
    expect(WeeklyReportMetricDisplay.achieved(0, 0), isFalse);
  });
}
