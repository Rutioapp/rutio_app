import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_year_insight_resolver.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('resolveHabitStatsYearComparison', () {
    test('no valid activity returns noData', () {
      final comparison = resolveHabitStatsYearComparison(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _month(month: 1, status: HabitStatsYearMonthStatus.unavailable),
          _month(month: 2, status: HabitStatsYearMonthStatus.future),
          _month(month: 3, status: HabitStatsYearMonthStatus.empty, pct: 0),
        ],
      );

      expect(comparison.state, HabitStatsYearComparisonState.noData);
    });

    test('one active month returns starting', () {
      final comparison = resolveHabitStatsYearComparison(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _month(month: 1, status: HabitStatsYearMonthStatus.low, pct: 24),
          _month(month: 2, status: HabitStatsYearMonthStatus.empty, pct: 0),
        ],
      );

      expect(comparison.state, HabitStatsYearComparisonState.starting);
    });

    test('later active months better returns improving', () {
      final comparison = resolveHabitStatsYearComparison(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _month(month: 1, status: HabitStatsYearMonthStatus.low, pct: 20),
          _month(month: 2, status: HabitStatsYearMonthStatus.low, pct: 25),
          _month(month: 9, status: HabitStatsYearMonthStatus.high, pct: 76),
          _month(month: 10, status: HabitStatsYearMonthStatus.high, pct: 82),
        ],
      );

      expect(comparison.state, HabitStatsYearComparisonState.improving);
    });

    test('later active months worse returns declining', () {
      final comparison = resolveHabitStatsYearComparison(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _month(month: 1, status: HabitStatsYearMonthStatus.high, pct: 85),
          _month(month: 2, status: HabitStatsYearMonthStatus.high, pct: 76),
          _month(month: 8, status: HabitStatsYearMonthStatus.low, pct: 28),
          _month(month: 9, status: HabitStatsYearMonthStatus.low, pct: 20),
        ],
      );

      expect(comparison.state, HabitStatsYearComparisonState.declining);
    });

    test('future and unavailable months are ignored', () {
      final comparison = resolveHabitStatsYearComparison(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _month(month: 1, status: HabitStatsYearMonthStatus.unavailable),
          _month(month: 2, status: HabitStatsYearMonthStatus.low, pct: 28),
          _month(month: 3, status: HabitStatsYearMonthStatus.future),
          _month(month: 4, status: HabitStatsYearMonthStatus.high, pct: 80),
        ],
      );

      expect(comparison.state, HabitStatsYearComparisonState.improving);
    });

    test('zero-trackable and unavailable months do not crash', () {
      expect(
        () => resolveHabitStatsYearComparison(
          monthSummaries: <HabitStatsYearMonthSummary>[
            const HabitStatsYearMonthSummary(
              month: 1,
              completedDays: 0,
              accumulatedValue: 0,
              trackableDays: 0,
              status: HabitStatsYearMonthStatus.unavailable,
            ),
          ],
        ),
        returnsNormally,
      );
    });
  });

  group('resolveHabitStatsYearInsight', () {
    test('one active month returns startingYear', () {
      final comparison = resolveHabitStatsYearComparison(
        monthSummaries: <HabitStatsYearMonthSummary>[
          _month(month: 5, status: HabitStatsYearMonthStatus.medium, pct: 60),
        ],
      );
      final insight = resolveHabitStatsYearInsight(
        l10n,
        monthSummaries: <HabitStatsYearMonthSummary>[
          _month(month: 5, status: HabitStatsYearMonthStatus.medium, pct: 60),
        ],
        comparison: comparison,
      );

      expect(insight.state, HabitStatsYearInsightState.startingYear);
    });

    test('strong performance across valid months returns strongYear', () {
      final months = <HabitStatsYearMonthSummary>[
        _month(month: 1, status: HabitStatsYearMonthStatus.high, pct: 86),
        _month(month: 2, status: HabitStatsYearMonthStatus.high, pct: 88),
        _month(month: 3, status: HabitStatsYearMonthStatus.high, pct: 82),
        _month(month: 4, status: HabitStatsYearMonthStatus.medium, pct: 74),
      ];
      final comparison =
          resolveHabitStatsYearComparison(monthSummaries: months);
      final insight = resolveHabitStatsYearInsight(
        l10n,
        monthSummaries: months,
        comparison: comparison,
      );

      expect(insight.state, HabitStatsYearInsightState.strongYear);
    });

    test('later months improving returns improvingYear', () {
      final months = <HabitStatsYearMonthSummary>[
        _month(month: 2, status: HabitStatsYearMonthStatus.low, pct: 20),
        _month(month: 3, status: HabitStatsYearMonthStatus.low, pct: 32),
        _month(month: 9, status: HabitStatsYearMonthStatus.medium, pct: 60),
        _month(month: 10, status: HabitStatsYearMonthStatus.high, pct: 78),
      ];
      final comparison =
          resolveHabitStatsYearComparison(monthSummaries: months);
      final insight = resolveHabitStatsYearInsight(
        l10n,
        monthSummaries: months,
        comparison: comparison,
      );

      expect(comparison.state, HabitStatsYearComparisonState.improving);
      expect(insight.state, HabitStatsYearInsightState.improvingYear);
    });

    test('later months worsening can return irregularYear', () {
      final months = <HabitStatsYearMonthSummary>[
        _month(month: 1, status: HabitStatsYearMonthStatus.high, pct: 84),
        _month(month: 2, status: HabitStatsYearMonthStatus.high, pct: 80),
        _month(month: 8, status: HabitStatsYearMonthStatus.low, pct: 24),
        _month(month: 9, status: HabitStatsYearMonthStatus.low, pct: 18),
      ];
      final comparison =
          resolveHabitStatsYearComparison(monthSummaries: months);
      final insight = resolveHabitStatsYearInsight(
        l10n,
        monthSummaries: months,
        comparison: comparison,
      );

      expect(comparison.state, HabitStatsYearComparisonState.declining);
      expect(insight.state, HabitStatsYearInsightState.irregularYear);
    });

    test('months before creation represented as unavailable are ignored', () {
      final months = <HabitStatsYearMonthSummary>[
        _month(month: 1, status: HabitStatsYearMonthStatus.unavailable),
        _month(month: 2, status: HabitStatsYearMonthStatus.unavailable),
        _month(month: 3, status: HabitStatsYearMonthStatus.low, pct: 22),
        _month(month: 4, status: HabitStatsYearMonthStatus.medium, pct: 55),
      ];
      final comparison =
          resolveHabitStatsYearComparison(monthSummaries: months);
      final insight = resolveHabitStatsYearInsight(
        l10n,
        monthSummaries: months,
        comparison: comparison,
      );

      expect(comparison.state, isNot(HabitStatsYearComparisonState.noData));
      expect(insight.state, isNot(HabitStatsYearInsightState.noData));
    });

    test('resolved message is never empty and stays compact', () {
      final months = <HabitStatsYearMonthSummary>[
        _month(month: 1, status: HabitStatsYearMonthStatus.medium, pct: 55),
        _month(month: 2, status: HabitStatsYearMonthStatus.medium, pct: 57),
      ];
      final comparison =
          resolveHabitStatsYearComparison(monthSummaries: months);
      final insight = resolveHabitStatsYearInsight(
        l10n,
        monthSummaries: months,
        comparison: comparison,
      );

      expect(insight.insight.title.trim(), isNotEmpty);
      expect(insight.insight.body.trim(), isNotEmpty);
      expect(insight.insight.body.length, lessThan(220));
    });
  });
}

HabitStatsYearMonthSummary _month({
  required int month,
  required HabitStatsYearMonthStatus status,
  int? pct,
}) {
  return HabitStatsYearMonthSummary(
    month: month,
    completedDays: status.hasActivity ? 1 : 0,
    accumulatedValue: status.hasActivity ? 1 : 0,
    trackableDays: status == HabitStatsYearMonthStatus.unavailable ? 0 : 30,
    status: status,
    performancePct: pct,
  );
}
