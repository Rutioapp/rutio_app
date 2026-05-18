import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_insight_card.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';

void main() {
  group('HabitStatsInsightCard adaptiveLayout', () {
    testWidgets('short insight renders on compact width without overflow',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: HabitStatsInsightCard(
            shellData: _shellData(),
            adaptiveLayout: true,
            insight: const HabitStatsInsight(
              title: 'Month not started yet',
              body: 'One first check is enough to start rhythm.',
              tone: HabitStatsInsightTone.neutral,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsInsightCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HabitStatsInsightCard),
          matching: find.byType(Expanded),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('long insight uses vertical fallback without overflow',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: HabitStatsInsightCard(
            shellData: _shellData(),
            adaptiveLayout: true,
            insight: const HabitStatsInsight(
              title: 'Solid monthly rhythm',
              body:
                  'You are doing very well this month: 8/10 completed. Your strongest time is still morning. '
                  'You are also ahead of last month. Keep this pace softly and keep each check simple and sustainable.',
              tone: HabitStatsInsightTone.positive,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsInsightCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HabitStatsInsightCard),
          matching: find.byType(Expanded),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(320, 568)),
      child: Scaffold(body: Padding(padding: const EdgeInsets.all(12), child: child)),
    ),
  );
}

HabitStatsShellData _shellData() {
  final now = DateTime.now();
  return HabitStatsShellData(
    habitId: 'habit-1',
    title: 'Habit',
    familyName: 'Mind',
    objectiveSummary: '',
    typeLabel: 'Check',
    isCounter: false,
    currentStreak: 0,
    bestStreak: 0,
    weeklyTarget: 0,
    weeklyCompleted: 0,
    previousWeekCompleted: 0,
    currentWeekCompleted: 0,
    weeklyConsistencyPct: 0,
    weeklyComparisonDeltaPct: 0,
    bestMomentLabel: '',
    bestMomentSlot: HabitStatsBestMomentSlot.unknown,
    hasBestMomentData: false,
    last7Days: List<HabitStatsLast7DayItem>.generate(
      7,
      (index) => HabitStatsLast7DayItem(
        date: now.subtract(Duration(days: index)),
        weekdayLabel: '',
        state: HabitStatsDayState.pending,
      ),
      growable: false,
    ),
    countLast7Days: const <HabitStatsCountLast7DayItem>[],
    countDailyTarget: 0,
    countUnitLabel: '',
    countsByDay: const <DateTime, int>{},
    countValuesByDay: const <DateTime, num>{},
    skipsByDay: const <DateTime, bool>{},
    completionTimesByDay: const <DateTime, int>{},
  );
}
