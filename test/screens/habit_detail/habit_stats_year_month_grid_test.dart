import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_year_month_grid.dart';

void main() {
  group('HabitStatsYearMonthGrid', () {
    testWidgets('renders 12 month cells with localized labels', (tester) async {
      await tester.pumpWidget(
        _app(
          child: HabitStatsYearMonthGrid(
            summaries: _summaries(),
            isCounter: false,
            accentColor: const Color(0xFF6A8C6B),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habit_stats_year_month_grid')), findsOneWidget);
      for (var month = 1; month <= 12; month++) {
        expect(find.byKey(Key('habit_stats_year_month_label_$month')), findsOneWidget);
      }
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('applies month states and subtle current-month emphasis',
        (tester) async {
      await tester.pumpWidget(
        _app(
          size: const Size(320, 568),
          child: HabitStatsYearMonthGrid(
            summaries: _summaries(),
            isCounter: true,
            accentColor: const Color(0xFF6A8C6B),
            countUnitLabel: 'L',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habit_stats_year_month_cell_1_unavailable')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_month_cell_2_future')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_month_cell_3_empty')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_month_cell_4_low')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_month_cell_5_medium')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_month_cell_6_high')),
          findsOneWidget);
      expect(find.text('40 L'), findsOneWidget);

      final currentMonthCell = tester.widget<Container>(
        find.byKey(const Key('habit_stats_year_month_cell_4_low')),
      );
      final decoration = currentMonthCell.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.width, greaterThan(1));
      expect(find.byKey(const Key('habit_stats_year_month_value_2')), findsNothing);
      expect(find.byKey(const Key('habit_stats_year_month_value_1')), findsNothing);

      final lowCell = tester.widget<Container>(
        find.byKey(const Key('habit_stats_year_month_cell_4_low')),
      );
      final mediumCell = tester.widget<Container>(
        find.byKey(const Key('habit_stats_year_month_cell_5_medium')),
      );
      final highCell = tester.widget<Container>(
        find.byKey(const Key('habit_stats_year_month_cell_6_high')),
      );
      final lowDecoration = lowCell.decoration! as BoxDecoration;
      final mediumDecoration = mediumCell.decoration! as BoxDecoration;
      final highDecoration = highCell.decoration! as BoxDecoration;
      expect(highDecoration.color!.a, greaterThan(mediumDecoration.color!.a));
      expect(mediumDecoration.color!.a, greaterThan(lowDecoration.color!.a));
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app({
  required Widget child,
  Size size = const Size(430, 932),
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: child),
    ),
  );
}

List<HabitStatsYearMonthSummary> _summaries() {
  return <HabitStatsYearMonthSummary>[
    const HabitStatsYearMonthSummary(
      month: 1,
      completedDays: 0,
      accumulatedValue: 0,
      trackableDays: 0,
      status: HabitStatsYearMonthStatus.unavailable,
    ),
    const HabitStatsYearMonthSummary(
      month: 2,
      completedDays: 0,
      accumulatedValue: 0,
      trackableDays: 0,
      status: HabitStatsYearMonthStatus.future,
    ),
    const HabitStatsYearMonthSummary(
      month: 3,
      completedDays: 0,
      accumulatedValue: 0,
      trackableDays: 31,
      status: HabitStatsYearMonthStatus.empty,
      performancePct: 0,
    ),
    const HabitStatsYearMonthSummary(
      month: 4,
      completedDays: 4,
      accumulatedValue: 12,
      trackableDays: 31,
      status: HabitStatsYearMonthStatus.low,
      performancePct: 20,
      isCurrentMonth: true,
    ),
    const HabitStatsYearMonthSummary(
      month: 5,
      completedDays: 12,
      accumulatedValue: 20,
      trackableDays: 31,
      status: HabitStatsYearMonthStatus.medium,
      performancePct: 52,
    ),
    const HabitStatsYearMonthSummary(
      month: 6,
      completedDays: 22,
      accumulatedValue: 40,
      trackableDays: 30,
      status: HabitStatsYearMonthStatus.high,
      performancePct: 82,
    ),
    for (var month = 7; month <= 12; month++)
      HabitStatsYearMonthSummary(
        month: month,
        completedDays: 0,
        accumulatedValue: 0,
        trackableDays: 0,
        status: HabitStatsYearMonthStatus.future,
      ),
  ];
}
