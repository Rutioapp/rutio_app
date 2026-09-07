import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/flexible_weekly_quota.dart';
import 'package:rutio/features/habits/domain/metrics/flexible_weekly_quota_period_aggregator.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';

final _week = WeeklyReportWeek(
  weekStartDate: DateTime(2026, 8, 31),
  weekEndDate: DateTime(2026, 9, 6),
);

Map<String, dynamic> _history({
  List<int> completed = const [],
  List<int> skipped = const [],
}) {
  Map<String, dynamic> days(List<int> weekdays) => {
        for (final weekday in weekdays)
          _dateKey(_week.weekStartDate.add(Duration(days: weekday - 1))): {
            'habit-1': true
          },
      };
  return {
    'habitCompletions': days(completed),
    'habitSkips': days(skipped),
  };
}

FlexibleWeeklyQuotaResult _run({
  required Map<String, dynamic> history,
  DateTime? rangeStart,
  DateTime? rangeEnd,
  bool currentWeek = false,
  DateTime? createdAt,
  DateTime? archivedAt,
  List<FlexibleWeeklyQuotaConfigSegment> segments = const [],
}) {
  return const FlexibleWeeklyQuotaEvaluator().evaluate(
    habit: FlexibleWeeklyQuotaHabit(
      habitId: 'habit-1',
      timesPerWeek: 3,
      createdAt: createdAt,
      archivedAt: archivedAt,
      configurationSegments: segments,
    ),
    week: _week,
    history: history,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
    currentWeek: currentWeek,
  );
}

String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

void main() {
  test('parity A: three completed days produce 3/3', () {
    final result = _run(history: _history(completed: [1, 3, 5]));
    expect(result.completedDays, 3);
    expect(result.scheduledQuota, 3);
    expect(result.rawRatio, 1);
    expect(result.cappedRatio, 1);
  });

  test('parity B: completion after quota remains raw 4/3', () {
    final result = _run(history: _history(completed: [1, 3, 5, 6]));
    expect(result.completedDays, 4);
    expect(result.scheduledQuota, 3);
    expect(result.rawRatio, closeTo(4 / 3, 0.000001));
    expect(result.cappedRatio, 1);
  });

  test('parity C: skip is activity but not completion or quota reduction', () {
    final result = _run(
      history: _history(completed: [1, 3, 5], skipped: [2]),
    );
    expect(result.completedDays, 3);
    expect(result.skippedDays, 1);
    expect(result.scheduledQuota, 3);
  });

  test('parity D: open week keeps full quota for an active Monday habit', () {
    final result = _run(
      history: _history(completed: [1, 3]),
      rangeStart: DateTime(2026, 8, 31),
      rangeEnd: DateTime(2026, 9, 2),
      currentWeek: true,
    );
    expect(result.completedDays, 2);
    expect(result.scheduledQuota, 3);
  });

  test('parity E: mixed denominator is daily 7 + weekday 3 + flexible 3', () {
    final flexible = _run(history: _history(completed: [1, 3, 5]));
    expect(7 + 3 + flexible.scheduledQuota, 13);
  });

  test('parity F: created Wednesday uses the eligible partial quota', () {
    final result = _run(
      history: _history(completed: [3]),
      createdAt: DateTime(2026, 9, 2),
    );
    expect(result.eligibleDays, 5);
    expect(result.scheduledQuota, 3);
    expect(result.completedDays, 1);
  });

  test('parity G: archived Wednesday excludes later dates', () {
    final result = _run(
      history: _history(completed: [1, 2, 3]),
      archivedAt: DateTime(2026, 9, 2),
    );
    expect(result.eligibleDays, 2);
    expect(result.scheduledQuota, 1);
    expect(result.completedDays, 2);
  });

  test('parity H: target change uses effective configuration segments', () {
    final result = _run(
      history: _history(completed: [1, 3, 5]),
      segments: [
        FlexibleWeeklyQuotaConfigSegment(
          timesPerWeek: 3,
          effectiveFrom: DateTime(2026, 8, 31),
          effectiveUntil: DateTime(2026, 9, 1),
        ),
        FlexibleWeeklyQuotaConfigSegment(
          timesPerWeek: 4,
          effectiveFrom: DateTime(2026, 9, 2),
          effectiveUntil: DateTime(2026, 9, 6),
        ),
      ],
    );
    expect(result.scheduledQuota, 4);
  });

  test('parity H3: three effective segments accumulate one quota', () {
    final result = _run(
      history: _history(completed: [1, 2, 3, 4, 5]),
      segments: [
        FlexibleWeeklyQuotaConfigSegment(
          timesPerWeek: 2,
          effectiveFrom: DateTime(2026, 8, 31),
          effectiveUntil: DateTime(2026, 9, 1),
        ),
        FlexibleWeeklyQuotaConfigSegment(
          timesPerWeek: 4,
          effectiveFrom: DateTime(2026, 9, 2),
          effectiveUntil: DateTime(2026, 9, 3),
        ),
        FlexibleWeeklyQuotaConfigSegment(
          timesPerWeek: 3,
          effectiveFrom: DateTime(2026, 9, 4),
          effectiveUntil: DateTime(2026, 9, 6),
        ),
      ],
    );

    expect(result.scheduledQuota, 3);
    expect(result.completedDays, 5);
    expect(result.rawRatio, 5 / 3);
  });

  test('parity I: duplicate logical date is counted once', () {
    final result = _run(history: _history(completed: [1, 1, 1]));
    expect(result.completedDays, 1);
  });

  test('parity J: Monday-Sunday local boundary excludes adjacent dates', () {
    final result = _run(
      history: _history(completed: [1, 7])
        ..['habitCompletions'] = {
          '2026-08-30': {'habit-1': true},
          '2026-08-31': {'habit-1': true},
          '2026-09-06': {'habit-1': true},
          '2026-09-07': {'habit-1': true},
        },
    );
    expect(result.completedDays, 2);
    expect(result.weekStart, DateTime(2026, 8, 31));
    expect(result.weekEnd, DateTime(2026, 9, 6));
  });

  test('pending flexible days are neutral rather than daily misses', () {
    final result = _run(history: _history(completed: [1]));
    expect(result.completedDays, 1);
    expect(result.scheduledQuota, 3);
  });

  test('period aggregator preserves raw over-target total', () {
    final result = const FlexibleWeeklyQuotaPeriodAggregator().aggregate(
      habit: const FlexibleWeeklyQuotaHabit(
        habitId: 'habit-1',
        timesPerWeek: 3,
      ),
      history: _history(completed: [1, 3, 5, 6]),
      startDate: _week.weekStartDate,
      endDate: _week.weekEndDate,
    );
    expect(result.completedCount, 4);
    expect(result.scheduledCount, 3);
    expect(result.rawRatio, closeTo(4 / 3, 0.000001));
    expect(result.cappedRatio, 1);
  });
}
