import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_helpers.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';

void main() {
  group('resolveHabitStatsYearMetrics', () {
    test(
        'check yearly consistency uses completed over expected (3 completions of 5 expected = 60%)',
        () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {
            'type': 'weekly',
            'weekdays': [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
            ],
          },
        ),
        year: 2026,
        now: DateTime(2026, 1, 7, 10),
        countsByDay: {
          DateTime(2026, 1, 1): 1,
          DateTime(2026, 1, 2): 1,
          DateTime(2026, 1, 5): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 3);
      expect(metrics.trackableTotal, 5);
      expect(metrics.consistencyPct, 60);
    });

    test(
        'check daily: uses active range, avoids future dates, and resolves best month',
        () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-03-15',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: {
          DateTime(2026, 3, 16): 1,
          DateTime(2026, 4, 1): 1,
          DateTime(2026, 4, 2): 1,
          DateTime(2026, 5, 10): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 4);
      expect(metrics.trackableTotal, 66);
      expect(metrics.consistencyPct, 6);
      expect(metrics.activeMonths, 3);
      expect(metrics.bestMonth?.month, 4);
      expect(metrics.bestMonth?.completedDays, 2);
    });

    test('check weekly schedule: consistency uses scheduled days only', () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {
            'type': 'weekly',
            'weekdays': [DateTime.monday, DateTime.wednesday],
          },
        ),
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
        countsByDay: {
          DateTime(2026, 1, 5): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 1);
      expect(metrics.trackableTotal, 2);
      expect(metrics.consistencyPct, 50);
      expect(metrics.activeMonths, 1);
      expect(metrics.bestMonth?.month, 1);
    });

    test('check times-per-week: consistency uses quota formula', () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'timesPerWeek', 'timesPerWeek': 4},
        ),
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
        countsByDay: {
          DateTime(2026, 1, 3): 1,
          DateTime(2026, 1, 9): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 2);
      expect(metrics.trackableTotal, 6);
      expect(metrics.consistencyPct, 33);
      expect(metrics.activeMonths, 1);
      expect(metrics.bestMonth?.month, 1);
    });

    test('count: uses yearly accumulated value and best month by accumulation',
        () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'count',
          target: 10,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: {
          DateTime(2026, 1, 1): 8,
          DateTime(2026, 1, 2): 4,
          DateTime(2026, 2, 1): 15,
          DateTime(2026, 5, 1): 5,
        },
        skipsByDay: const {},
      );

      expect(metrics.accumulatedTotal, 32);
      expect(metrics.trackableTotal, 139);
      expect(metrics.consistencyPct, 1);
      expect(metrics.activeMonths, 3);
      expect(metrics.bestMonth?.month, 2);
      expect(metrics.bestMonth?.accumulatedValue, 15);
    });

    test(
        'count consistency uses goal-reaching occurrences, not raw accumulation ratio',
        () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'count',
          target: 10,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 1, 2, 10),
        countsByDay: const {},
        countValuesByDay: {
          DateTime(2026, 1, 1): 9,
          DateTime(2026, 1, 2): 11,
        },
        skipsByDay: const {},
      );

      expect(metrics.accumulatedTotal, 20);
      expect(metrics.trackableTotal, 2);
      expect(metrics.consistencyPct, 50);
    });

    test('future-created habit in selected year stays empty and safe', () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2027-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 0);
      expect(metrics.trackableTotal, 0);
      expect(metrics.accumulatedTotal, 0);
      expect(metrics.consistencyPct, 0);
      expect(metrics.activeMonths, 0);
      expect(metrics.bestMonth, isNull);
      expect(metrics.months, hasLength(12));
    });
  });

  group('resolveHabitStatsYearMonthSummaries', () {
    test('resolves high when monthly performance is at least 80%', () {
      final habit = _habit(
        type: 'check',
        target: 1,
        createdAt: '2026-01-01',
        schedule: const {'type': 'daily'},
      );
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: habit,
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
        countsByDay: _completedDaysInMonth(year: 2026, month: 1, total: 8),
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: habit,
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
      );

      expect(summaries[0].performancePct, 80);
      expect(summaries[0].status, HabitStatsYearMonthStatus.high);
    });

    test('resolves medium when monthly performance is between 45% and 80%', () {
      final habit = _habit(
        type: 'check',
        target: 1,
        createdAt: '2026-01-01',
        schedule: const {'type': 'daily'},
      );
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: habit,
        year: 2026,
        now: DateTime(2026, 1, 20, 10),
        countsByDay: _completedDaysInMonth(year: 2026, month: 1, total: 9),
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: habit,
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 1, 20, 10),
      );

      expect(summaries[0].performancePct, 45);
      expect(summaries[0].status, HabitStatsYearMonthStatus.medium);
    });

    test('resolves low when monthly performance is above 0% and below 45%', () {
      final habit = _habit(
        type: 'check',
        target: 1,
        createdAt: '2026-01-01',
        schedule: const {'type': 'daily'},
      );
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: habit,
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
        countsByDay: _completedDaysInMonth(year: 2026, month: 1, total: 4),
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: habit,
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
      );

      expect(summaries[0].performancePct, 40);
      expect(summaries[0].status, HabitStatsYearMonthStatus.low);
    });

    test('resolves empty for valid month with 0% performance', () {
      final habit = _habit(
        type: 'check',
        target: 1,
        createdAt: '2026-01-01',
        schedule: const {'type': 'daily'},
      );
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: habit,
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: habit,
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
      );

      expect(summaries[0].performancePct, 0);
      expect(summaries[0].status, HabitStatsYearMonthStatus.empty);
    });

    test('always returns 12 months and marks future months in current year',
        () {
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: {DateTime(2026, 1, 3): 1},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
      );

      expect(summaries, hasLength(12));
      expect(summaries[5].status, HabitStatsYearMonthStatus.future);
      expect(summaries[11].status, HabitStatsYearMonthStatus.future);
      expect(summaries[4].status, isNot(HabitStatsYearMonthStatus.future));
      expect(summaries[5].status, isNot(HabitStatsYearMonthStatus.empty));
      expect(summaries[5].status, isNot(HabitStatsYearMonthStatus.low));
    });

    test('marks months before habit creation as unavailable', () {
      final habit = _habit(
        type: 'check',
        target: 1,
        createdAt: '2026-03-15',
        schedule: const {'type': 'daily'},
      );
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: habit,
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: habit,
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
      );

      expect(summaries[0].status, HabitStatsYearMonthStatus.unavailable);
      expect(summaries[1].status, HabitStatsYearMonthStatus.unavailable);
      expect(summaries[2].status, isNot(HabitStatsYearMonthStatus.unavailable));
      expect(summaries[0].status, isNot(HabitStatsYearMonthStatus.empty));
      expect(summaries[0].status, isNot(HabitStatsYearMonthStatus.low));
    });

    test('expected zero does not divide by zero and resolves as unavailable',
        () {
      final habit = _habit(
        type: 'check',
        target: 1,
        createdAt: '2026-01-01',
        schedule: const {'type': 'weekly', 'weekdays': <int>[]},
      );
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: habit,
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: habit,
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
      );

      expect(() => summaries[0].performancePct, returnsNormally);
      expect(summaries[0].performancePct, isNull);
      expect(summaries[0].status, HabitStatsYearMonthStatus.unavailable);
    });

    test(
        'check habits classify activity months and keep monthly completed totals',
        () {
      final habit = _habit(
        type: 'check',
        target: 1,
        createdAt: '2026-01-01',
        schedule: const {'type': 'daily'},
      );
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: habit,
        year: 2026,
        now: DateTime(2026, 4, 30, 10),
        countsByDay: {
          ..._completedDaysInMonth(year: 2026, month: 1, total: 5),
          ..._completedDaysInMonth(year: 2026, month: 4, total: 25),
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: habit,
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 4, 30, 10),
      );

      expect(yearMetrics.months[0].completedDays, 5);
      expect(yearMetrics.months[3].completedDays, 25);
      expect(summaries[0].status, HabitStatsYearMonthStatus.low);
      expect(summaries[3].status, HabitStatsYearMonthStatus.high);
      expect(summaries[3].isCurrentMonth, isTrue);
      expect(yearMetrics.bestMonth?.month, 4);
      expect(summaries[3].status.hasActivity, isTrue);
    });

    test('count habits use accumulated values and classify monthly performance',
        () {
      final habit = _habit(
        type: 'count',
        target: 10,
        createdAt: '2026-01-01',
        schedule: const {'type': 'daily'},
      );
      final yearMetrics = resolveHabitStatsYearMetrics(
        habit: habit,
        year: 2026,
        now: DateTime(2026, 3, 31, 10),
        countsByDay: const {},
        countValuesByDay: {
          DateTime(2026, 1, 2): 20,
          DateTime(2026, 2, 4): 40,
        },
        skipsByDay: const {},
      );

      final summaries = resolveHabitStatsYearMonthSummaries(
        habit: habit,
        yearMetrics: yearMetrics,
        year: 2026,
        now: DateTime(2026, 3, 31, 10),
      );

      expect(yearMetrics.bestMonth?.month, 2);
      expect(summaries[1].status, HabitStatsYearMonthStatus.high);
      expect(summaries[0].status, HabitStatsYearMonthStatus.medium);
      expect(summaries[2].status, HabitStatsYearMonthStatus.empty);
      expect(summaries[3].status, HabitStatsYearMonthStatus.future);
    });
  });

  group('resolveHabitStatsYearActivitySummary', () {
    test('best month ignores future and unavailable months', () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 1,
            status: HabitStatsYearMonthStatus.unavailable,
          ),
          _yearMonth(
            month: 2,
            status: HabitStatsYearMonthStatus.high,
            performancePct: 88,
          ),
          _yearMonth(
            month: 3,
            status: HabitStatsYearMonthStatus.future,
          ),
          _yearMonth(
            month: 4,
            status: HabitStatsYearMonthStatus.medium,
            performancePct: 60,
          ),
        ],
      );

      expect(summary.bestMonth?.month, 2);
      expect(summary.bestMonth?.performancePct, 88);
    });

    test('weakest month ignores future and unavailable months', () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 1,
            status: HabitStatsYearMonthStatus.unavailable,
          ),
          _yearMonth(
            month: 2,
            status: HabitStatsYearMonthStatus.low,
            performancePct: 22,
          ),
          _yearMonth(
            month: 3,
            status: HabitStatsYearMonthStatus.future,
          ),
          _yearMonth(
            month: 4,
            status: HabitStatsYearMonthStatus.high,
            performancePct: 84,
          ),
        ],
      );

      expect(summary.weakestMonth?.month, 2);
      expect(summary.weakestMonth?.performancePct, 22);
    });

    test('active months counts only months with activity', () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 1,
            status: HabitStatsYearMonthStatus.high,
            performancePct: 90,
          ),
          _yearMonth(
            month: 2,
            status: HabitStatsYearMonthStatus.low,
            performancePct: 18,
          ),
          _yearMonth(
            month: 3,
            status: HabitStatsYearMonthStatus.empty,
            performancePct: 0,
          ),
          _yearMonth(
            month: 4,
            status: HabitStatsYearMonthStatus.future,
          ),
        ],
      );

      expect(summary.activeMonths, 2);
    });

    test('trend returns noData when there is no valid activity', () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 1,
            status: HabitStatsYearMonthStatus.unavailable,
          ),
          _yearMonth(
            month: 2,
            status: HabitStatsYearMonthStatus.empty,
            performancePct: 0,
          ),
          _yearMonth(
            month: 3,
            status: HabitStatsYearMonthStatus.future,
          ),
        ],
      );

      expect(summary.trend, HabitStatsYearTrend.noData);
    });

    test('trend returns starting when there is only one active month', () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 1,
            status: HabitStatsYearMonthStatus.medium,
            performancePct: 58,
          ),
          _yearMonth(
            month: 2,
            status: HabitStatsYearMonthStatus.empty,
            performancePct: 0,
          ),
        ],
      );

      expect(summary.trend, HabitStatsYearTrend.starting);
    });

    test(
        'trend returns improving when later active months perform meaningfully better',
        () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 2,
            status: HabitStatsYearMonthStatus.low,
            performancePct: 20,
          ),
          _yearMonth(
            month: 4,
            status: HabitStatsYearMonthStatus.medium,
            performancePct: 40,
          ),
          _yearMonth(
            month: 8,
            status: HabitStatsYearMonthStatus.high,
            performancePct: 70,
          ),
          _yearMonth(
            month: 10,
            status: HabitStatsYearMonthStatus.high,
            performancePct: 80,
          ),
        ],
      );

      expect(summary.trend, HabitStatsYearTrend.improving);
    });

    test(
        'trend returns declining when later active months perform meaningfully worse',
        () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 1,
            status: HabitStatsYearMonthStatus.high,
            performancePct: 82,
          ),
          _yearMonth(
            month: 3,
            status: HabitStatsYearMonthStatus.high,
            performancePct: 74,
          ),
          _yearMonth(
            month: 7,
            status: HabitStatsYearMonthStatus.low,
            performancePct: 30,
          ),
          _yearMonth(
            month: 9,
            status: HabitStatsYearMonthStatus.low,
            performancePct: 20,
          ),
        ],
      );

      expect(summary.trend, HabitStatsYearTrend.declining);
    });

    test('trend returns stable when performance difference is small', () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 1,
            status: HabitStatsYearMonthStatus.medium,
            performancePct: 50,
          ),
          _yearMonth(
            month: 2,
            status: HabitStatsYearMonthStatus.medium,
            performancePct: 54,
          ),
          _yearMonth(
            month: 3,
            status: HabitStatsYearMonthStatus.medium,
            performancePct: 56,
          ),
          _yearMonth(
            month: 4,
            status: HabitStatsYearMonthStatus.medium,
            performancePct: 58,
          ),
        ],
      );

      expect(summary.trend, HabitStatsYearTrend.stable);
    });

    test('habit created mid-year does not make previous months weak months',
        () {
      final summary = resolveHabitStatsYearActivitySummary(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _yearMonth(
            month: 1,
            status: HabitStatsYearMonthStatus.unavailable,
          ),
          _yearMonth(
            month: 2,
            status: HabitStatsYearMonthStatus.unavailable,
          ),
          _yearMonth(
            month: 3,
            status: HabitStatsYearMonthStatus.low,
            performancePct: 24,
          ),
          _yearMonth(
            month: 4,
            status: HabitStatsYearMonthStatus.medium,
            performancePct: 52,
          ),
        ],
      );

      expect(summary.weakestMonth?.month, 3);
      expect(summary.weakestMonth?.status,
          isNot(HabitStatsYearMonthStatus.unavailable));
    });
  });

  group('resolveHabitStatsYearCalendarMonths', () {
    test('returns 12 months', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(months, hasLength(12));
    });

    test('month day counts are correct for january, february and april', () {
      final commonArgs = (
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2024-01-01',
          schedule: const {'type': 'daily'},
        ),
        now: DateTime(2026, 5, 20, 10),
        countsByDay: <DateTime, int>{},
        countValuesByDay: <DateTime, num>{},
        skipsByDay: <DateTime, bool>{},
      );
      final months2025 = resolveHabitStatsYearCalendarMonths(
        habit: commonArgs.habit,
        year: 2025,
        now: commonArgs.now,
        countsByDay: commonArgs.countsByDay,
        countValuesByDay: commonArgs.countValuesByDay,
        skipsByDay: commonArgs.skipsByDay,
      );
      final months2024 = resolveHabitStatsYearCalendarMonths(
        habit: commonArgs.habit,
        year: 2024,
        now: commonArgs.now,
        countsByDay: commonArgs.countsByDay,
        countValuesByDay: commonArgs.countValuesByDay,
        skipsByDay: commonArgs.skipsByDay,
      );

      expect(months2025[0].days, hasLength(31));
      expect(months2025[1].days, hasLength(28));
      expect(months2024[1].days, hasLength(29));
      expect(months2025[3].days, hasLength(30));
    });

    test('completed dates resolve to completed', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: {
          DateTime(2026, 4, 2): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(
        _calendarStatus(months, month: 4, day: 2),
        HabitStatsYearCalendarDayStatus.completed,
      );
    });

    test('skipped dates resolve to skipped', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: {
          DateTime(2026, 4, 3): true,
        },
      );

      expect(
        _calendarStatus(months, month: 4, day: 3),
        HabitStatsYearCalendarDayStatus.skipped,
      );
    });

    test('future dates resolve to future', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(
        _calendarStatus(months, month: 10, day: 1),
        HabitStatsYearCalendarDayStatus.future,
      );
    });

    test('dates before habit creation resolve to unavailable', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-03-15',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(
        _calendarStatus(months, month: 2, day: 10),
        HabitStatsYearCalendarDayStatus.unavailable,
      );
    });

    test('valid past scheduled dates with no completion or skip resolve to missed', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(
        _calendarStatus(months, month: 4, day: 8),
        HabitStatsYearCalendarDayStatus.missed,
      );
    });

    test('future dates are not marked as missed', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(
        _calendarStatus(months, month: 9, day: 1),
        isNot(HabitStatsYearCalendarDayStatus.missed),
      );
    });

    test('dates before creation are not marked as missed', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-04-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(
        _calendarStatus(months, month: 1, day: 10),
        isNot(HabitStatsYearCalendarDayStatus.missed),
      );
    });

    test('count habits are safe and represent activity days as completed', () {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(
          type: 'count',
          target: 10,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: {
          DateTime(2026, 1, 5): 3,
        },
        skipsByDay: const {},
      );

      expect(
        _calendarStatus(months, month: 1, day: 5),
        HabitStatsYearCalendarDayStatus.completed,
      );
      expect(
        _calendarStatus(months, month: 1, day: 6),
        HabitStatsYearCalendarDayStatus.missed,
      );
    });
  });
}

HabitStatsYearCalendarDayStatus _calendarStatus(
  List<HabitStatsYearCalendarMonth> months, {
  required int month,
  required int day,
}) {
  final targetMonth = months.firstWhere((item) => item.month == month);
  final targetDay = targetMonth.days.firstWhere((item) => item.date.day == day);
  return targetDay.status;
}

HabitStatsYearMonthSummary _yearMonth({
  required int month,
  required HabitStatsYearMonthStatus status,
  int? performancePct,
}) {
  return HabitStatsYearMonthSummary(
    month: month,
    completedDays: status.hasActivity ? 1 : 0,
    accumulatedValue: status.hasActivity ? 1 : 0,
    trackableDays: status == HabitStatsYearMonthStatus.unavailable ? 0 : 30,
    status: status,
    performancePct: performancePct,
  );
}

Map<String, dynamic> _habit({
  required String type,
  required int target,
  required String createdAt,
  required Map<String, dynamic> schedule,
}) {
  return <String, dynamic>{
    'id': 'habit-1',
    'title': 'Habit',
    'type': type,
    'target': target,
    'createdAt': createdAt,
    'schedule': schedule,
  };
}

Map<DateTime, int> _completedDaysInMonth({
  required int year,
  required int month,
  required int total,
}) {
  return <DateTime, int>{
    for (var day = 1; day <= total; day++) DateTime(year, month, day): 1,
  };
}
