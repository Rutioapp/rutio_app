import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_monthly_activity_grid.dart';

void main() {
  group('HabitStatsMonthlyActivityGrid', () {
    testWidgets('renders status markers with expected keys and circle shape',
        (tester) async {
      final month = DateTime(2026, 5, 1);
      final days = _daysForMonth(month, overrides: {
        1: HabitStatsMonthDayStatus.completed,
        2: HabitStatsMonthDayStatus.skipped,
        3: HabitStatsMonthDayStatus.missed,
        4: HabitStatsMonthDayStatus.future,
        5: HabitStatsMonthDayStatus.notScheduled,
      });

      await tester.pumpWidget(
        _app(
          HabitStatsMonthlyActivityGrid(
            monthlyData: _monthlyData(days),
            month: month,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final completedKey = find.byKey(
          const Key('habitStatsMonthDay_completed_2026-05-01'));
      final skippedKey =
          find.byKey(const Key('habitStatsMonthDay_skipped_2026-05-02'));
      final missedKey =
          find.byKey(const Key('habitStatsMonthDay_missed_2026-05-03'));
      final futureKey =
          find.byKey(const Key('habitStatsMonthDay_future_2026-05-04'));
      final notScheduledKey = find.byKey(
          const Key('habitStatsMonthDay_notScheduled_2026-05-05'));

      expect(completedKey, findsOneWidget);
      expect(skippedKey, findsOneWidget);
      expect(missedKey, findsOneWidget);
      expect(futureKey, findsOneWidget);
      expect(notScheduledKey, findsOneWidget);

      final completedContainer = tester.widget<Container>(completedKey);
      final missedContainer = tester.widget<Container>(missedKey);
      final notScheduledContainer = tester.widget<Container>(notScheduledKey);

      final completedDecoration =
          completedContainer.decoration! as BoxDecoration;
      final missedDecoration = missedContainer.decoration! as BoxDecoration;
      final notScheduledDecoration =
          notScheduledContainer.decoration! as BoxDecoration;

      expect(completedDecoration.shape, BoxShape.circle);
      expect(missedDecoration.shape, BoxShape.circle);
      expect(notScheduledDecoration.shape, BoxShape.circle);

      final missedBorder = missedDecoration.border! as Border;
      final notScheduledBorder = notScheduledDecoration.border! as Border;
      expect(notScheduledBorder.top.width, lessThan(missedBorder.top.width));
    });

    testWidgets('month starting on Wednesday has two leading empty cells',
        (tester) async {
      final month = DateTime(2025, 1, 1); // Wednesday
      await tester.pumpWidget(
        _app(
          HabitStatsMonthlyActivityGrid(
            monthlyData: _monthlyData(_daysForMonth(month)),
            month: month,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habitStatsMonthLeadingCell_0')),
          findsOneWidget);
      expect(find.byKey(const Key('habitStatsMonthLeadingCell_1')),
          findsOneWidget);
      expect(find.byKey(const Key('habitStatsMonthLeadingCell_2')),
          findsNothing);
    });

    testWidgets('month starting on Monday has no leading empty cells',
        (tester) async {
      final month = DateTime(2024, 1, 1); // Monday
      await tester.pumpWidget(
        _app(
          HabitStatsMonthlyActivityGrid(
            monthlyData: _monthlyData(_daysForMonth(month)),
            month: month,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habitStatsMonthLeadingCell_0')),
          findsNothing);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

HabitStatsMonthlyData _monthlyData(List<HabitStatsMonthDayState> days) {
  return HabitStatsMonthlyData(
    monthlyObjective: days.length,
    elapsedTrackableDays: days.length,
    expectedToDate: days.length,
    futureScheduledDays: 0,
    objectiveUnit: HabitStatsMonthlyObjectiveUnit.days,
    completedDays: 0,
    skippedDays: 0,
    missedDays: 0,
    totalTrackableDays: days.length,
    consistency: 0,
    bestStreak: 0,
    totalDone: 0,
    bestMoment: null,
    days: days,
  );
}

List<HabitStatsMonthDayState> _daysForMonth(
  DateTime month, {
  Map<int, HabitStatsMonthDayStatus> overrides = const {},
}) {
  final totalDays = DateUtils.getDaysInMonth(month.year, month.month);
  return List<HabitStatsMonthDayState>.generate(
    totalDays,
    (index) {
      final day = index + 1;
      return HabitStatsMonthDayState(
        date: DateTime(month.year, month.month, day),
        status: overrides[day] ?? HabitStatsMonthDayStatus.missed,
      );
    },
    growable: false,
  );
}
