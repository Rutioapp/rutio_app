import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';
import 'package:rutio/features/weekly_report/presentation/screens/weekly_report_screen.dart';

void main() {
  test('rotates compatible recommendations between report weeks', () {
    final first = _report(DateTime(2026, 10, 12));
    final second = _report(DateTime(2026, 10, 19));

    final firstHabit = selectWeeklyReportRecommendation(first)?.habitId;
    final secondHabit = selectWeeklyReportRecommendation(second)?.habitId;

    expect(firstHabit, isNotNull);
    expect(secondHabit, isNotNull);
    expect(firstHabit, isNot(secondHabit));
  });

  test(
      'falls back to a different eligible habit instead of always using the first',
      () {
    final report = _report(
      DateTime(2026, 10, 12),
      recommendations: const <WeeklyReportRecommendation>[],
    );

    final selected = selectWeeklyReportRecommendation(report);

    expect(selected?.reason, 'local_fallback');
    expect(<String>{'habit-a', 'habit-b'}, contains(selected?.habitId));
  });
}

WeeklyReport _report(
  DateTime weekStart, {
  List<WeeklyReportRecommendation>? recommendations,
}) {
  final week = WeeklyReportWeek(
    weekStartDate: weekStart,
    weekEndDate: weekStart.add(const Duration(days: 6)),
  );
  final defaultRecommendations = <WeeklyReportRecommendation>[
    _recommendation('habit-a', 'Leer'),
    _recommendation('habit-b', 'Caminar'),
  ];
  return WeeklyReport(
    id: 'report-${weekStart.toIso8601String()}',
    userId: 'user-1',
    week: week,
    timezoneId: 'Europe/Madrid',
    status: WeeklyReportStatus.finalized,
    firstPartialWeek: false,
    summary: const WeeklyReportSummary(
      scheduledCount: 1,
      completedCount: 1,
      completionRate: 1,
    ),
    days: const <WeeklyReportDay>[],
    habits: <WeeklyReportHabit>[
      _habit('habit-a', 'Leer'),
      _habit('habit-b', 'Caminar'),
    ],
    trend: const WeeklyReportTrend(
      kind: WeeklyReportTrendKind.stable,
      delta: 0,
      comparable: true,
      reason: 'test',
    ),
    schemaVersion: 1,
    metricsPolicyVersion: 1,
    contentVersion: 1,
    recommendations: recommendations ?? defaultRecommendations,
  );
}

WeeklyReportRecommendation _recommendation(String id, String name) =>
    WeeklyReportRecommendation(
      type: WeeklyReportRecommendationType.reduceFrequency,
      reason: 'test',
      habitId: id,
      habitName: name,
      currentConfig: const {
        'schedule': {'timesPerWeek': 4},
      },
      proposedPatch: const {
        'proposed': {
          'schedule': {'timesPerWeek': 3},
        },
      },
    );

WeeklyReportHabit _habit(String id, String name) => WeeklyReportHabit(
      habitId: id,
      name: name,
      type: HabitKind.check,
      schedule: HabitSchedule.timesPerWeek(timesPerWeek: 4),
      scheduledCount: 4,
      completedCount: 1,
      skippedCount: 0,
      completionRate: .25,
      occurrences: const [],
      classification: WeeklyReportHabitClassification.needsAttention,
    );
