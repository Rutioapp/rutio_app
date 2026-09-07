import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/flexible_weekly_quota.dart';
import 'package:rutio/features/habits/domain/metrics/flexible_weekly_quota_period_aggregator.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';

void main() {
  final week = WeeklyReportWeek.fromDate(DateTime(2026, 9, 9));
  const evaluator = FlexibleWeeklyQuotaEvaluator();
  const aggregator = FlexibleWeeklyQuotaPeriodAggregator();

  test('A: target three with Mon/Wed/Fri completes 3/3', () {
    final result = _evaluate(
      evaluator,
      week,
      completions: [
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 9),
        DateTime(2026, 9, 11),
      ],
    );

    expect(result.completedDays, 3);
    expect(result.scheduledQuota, 3);
    expect(result.rawRatio, 1);
    expect(result.cappedRatio, 1);
    expect(result.quotaMet, isTrue);
    expect(result.overTargetCount, 0);
  });

  test('B: over-target preserves 4/3 raw and caps only cappedRatio', () {
    final result = _evaluate(
      evaluator,
      week,
      completions: [
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 9),
        DateTime(2026, 9, 11),
        DateTime(2026, 9, 12),
      ],
    );

    expect(result.completedDays, 4);
    expect(result.scheduledQuota, 3);
    expect(result.rawRatio, closeTo(4 / 3, 0.000001));
    expect(result.cappedRatio, 1);
    expect(result.overTargetCount, 1);
  });

  test('C: skips do not count or reduce quota', () {
    final result = _evaluate(
      evaluator,
      week,
      completions: [
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 9),
        DateTime(2026, 9, 11),
      ],
      skips: [DateTime(2026, 9, 8), DateTime(2026, 9, 10)],
    );

    expect(result.completedDays, 3);
    expect(result.scheduledQuota, 3);
    expect(result.skippedDays, 2);
    expect(result.quotaMet, isTrue);
  });

  test('D: current open week uses full quota, not elapsed target', () {
    final result = _evaluate(
      evaluator,
      week,
      completions: [DateTime(2026, 9, 7), DateTime(2026, 9, 9)],
      rangeStart: DateTime(2026, 9, 7),
      rangeEnd: DateTime(2026, 9, 9),
      currentWeek: true,
    );

    expect(result.completedDays, 2);
    expect(result.scheduledQuota, 3);
    expect(result.rawRatio, closeTo(2 / 3, 0.000001));
  });

  test('E: flexible result contributes three to a mixed weekly denominator',
      () {
    final result = _evaluate(evaluator, week);

    // A daily habit (7) + Mon/Wed/Fri habit (3) + this result (3) = 13.
    expect(7 + 3 + result.scheduledQuota, 13);
  });

  test('F: a month boundary keeps a full week in one bucket', () {
    final result = aggregator.aggregate(
      habit: _habit(target: 3),
      history: _history(),
      startDate: DateTime(2026, 8, 31),
      endDate: DateTime(2026, 9, 6),
    );

    expect(result.weeklyResults, hasLength(1));
    expect(result.scheduledCount, 3);
  });

  test('G: creation midweek uses eligible-day partial quota', () {
    final result = evaluator.evaluate(
      habit: _habit(target: 3, createdAt: DateTime(2026, 9, 9)),
      week: week,
      history: _history(completions: [DateTime(2026, 9, 9)]),
    );

    expect(result.eligibleDays, 5);
    expect(result.scheduledQuota, 3);
    expect(result.completedDays, 1);
  });

  test('H: effective configuration segments split a changed target', () {
    final result = evaluator.evaluate(
      habit: _habit(
        target: 4,
        segments: [
          FlexibleWeeklyQuotaConfigSegment(
            timesPerWeek: 3,
            effectiveFrom: DateTime(2026, 9, 7),
            effectiveUntil: DateTime(2026, 9, 8),
          ),
          FlexibleWeeklyQuotaConfigSegment(
            timesPerWeek: 4,
            effectiveFrom: DateTime(2026, 9, 9),
            effectiveUntil: DateTime(2026, 9, 13),
          ),
        ],
      ),
      week: week,
      history: _history(completions: [DateTime(2026, 9, 7)]),
    );

    expect(result.scheduledQuota, 4);
    expect(result.dataQuality, FlexibleWeeklyDataQuality.verified);
  });

  test('I: archive boundary stops eligibility without inventing later dates',
      () {
    final result = evaluator.evaluate(
      habit: _habit(target: 3, archivedAt: DateTime(2026, 9, 9)),
      week: week,
      history: _history(
        completions: [DateTime(2026, 9, 7), DateTime(2026, 9, 10)],
      ),
    );

    expect(result.eligibleDays, 2);
    expect(result.scheduledQuota, 1);
    expect(result.completedDays, 1);
  });

  test('J: a week crossing the year boundary remains one Monday-Sunday bucket',
      () {
    final result = aggregator.aggregate(
      habit: _habit(target: 3),
      history: _history(
        completions: [DateTime(2026, 12, 28), DateTime(2027, 1, 1)],
      ),
      startDate: DateTime(2026, 12, 28),
      endDate: DateTime(2027, 1, 3),
    );

    expect(result.weeklyResults, hasLength(1));
    expect(result.weeklyResults.single.weekStart, DateTime(2026, 12, 28));
    expect(result.weeklyResults.single.weekEnd, DateTime(2027, 1, 3));
    expect(result.completedCount, 2);
  });

  test('range crossing two weeks never creates seven flexible obligations', () {
    final result = aggregator.aggregate(
      habit: _habit(target: 3),
      history: _history(
        completions: [DateTime(2026, 9, 12), DateTime(2026, 9, 14)],
      ),
      startDate: DateTime(2026, 9, 12),
      endDate: DateTime(2026, 9, 14),
    );

    expect(result.weeklyResults, hasLength(2));
    expect(result.scheduledCount, 2);
    expect(result.completedCount, 2);
  });

  test('duplicate history values on one date count as one completed day', () {
    final result = _evaluate(
      evaluator,
      week,
      completions: [DateTime(2026, 9, 7), DateTime(2026, 9, 7)],
    );

    expect(result.completedDays, 1);
  });

  test('missing configuration history is explicit current-config fallback', () {
    final result = _evaluate(evaluator, week);

    expect(result.dataQuality, FlexibleWeeklyDataQuality.currentConfigFallback);
    expect(result.isUnverifiable, isFalse);
  });

  test('incomplete configuration segments are marked unverifiable', () {
    final result = evaluator.evaluate(
      habit: _habit(
        target: 3,
        segments: [
          FlexibleWeeklyQuotaConfigSegment(
            timesPerWeek: 3,
            effectiveFrom: DateTime(2026, 9, 7),
            effectiveUntil: DateTime(2026, 9, 9),
          ),
        ],
      ),
      week: week,
      history: _history(),
    );

    expect(result.dataQuality, FlexibleWeeklyDataQuality.unverifiable);
    expect(result.isUnverifiable, isTrue);
  });

  test('invalid quota is not silently converted to a daily or unit quota', () {
    final result = evaluator.evaluate(
      habit: _habit(target: 0),
      week: week,
      history: _history(completions: [DateTime(2026, 9, 7)]),
    );

    expect(result.scheduledQuota, 0);
    expect(result.completedDays, 0);
    expect(result.dataQuality, FlexibleWeeklyDataQuality.unverifiable);
  });
}

FlexibleWeeklyQuotaResult _evaluate(
  FlexibleWeeklyQuotaEvaluator evaluator,
  WeeklyReportWeek week, {
  List<DateTime> completions = const [],
  List<DateTime> skips = const [],
  DateTime? rangeStart,
  DateTime? rangeEnd,
  bool currentWeek = false,
}) {
  return evaluator.evaluate(
    habit: _habit(target: 3),
    week: week,
    history: _history(completions: completions, skips: skips),
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
    currentWeek: currentWeek,
  );
}

FlexibleWeeklyQuotaHabit _habit({
  required int target,
  DateTime? createdAt,
  DateTime? archivedAt,
  List<FlexibleWeeklyQuotaConfigSegment> segments = const [],
}) {
  return FlexibleWeeklyQuotaHabit(
    habitId: 'flexible',
    timesPerWeek: target,
    createdAt: createdAt,
    archivedAt: archivedAt,
    configurationSegments: segments,
  );
}

Map<String, dynamic> _history({
  List<DateTime> completions = const [],
  List<DateTime> skips = const [],
}) {
  return <String, dynamic>{
    'habitCompletions': _days(completions),
    'habitSkips': _days(skips),
  };
}

Map<String, dynamic> _days(List<DateTime> dates) {
  final root = <String, dynamic>{};
  for (final date in dates) {
    final key = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final day = root[key] is Map
        ? Map<String, dynamic>.from(root[key] as Map)
        : <String, dynamic>{};
    day['flexible'] = true;
    root[key] = day;
  }
  return root;
}
