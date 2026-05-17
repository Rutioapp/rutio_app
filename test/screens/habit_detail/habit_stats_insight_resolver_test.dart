import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_insight_resolver.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('resolveHabitStatsInsight', () {
    test('todaySkipped still wins over all other cases', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.skipped,
          currentStreak: 6,
          isCounter: true,
          todayCount: 3,
          countDailyTarget: 5,
          weeklyTarget: 4,
          weeklyCompleted: 4,
          weeklyConsistencyPct: 90,
          weeklyComparisonDeltaPct: 20,
          currentWeekCompleted: 5,
          previousWeekCompleted: 3,
          hasBestMomentData: true,
          bestMomentSlot: HabitStatsBestMomentSlot.night,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightTodaySkippedTitle);
      expect(insight.body, l10n.habitStatsInsightTodaySkippedBody);
      expect(insight.tone, HabitStatsInsightTone.paused);
    });

    test('todayCompleted still wins over milestone and trend', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.completed,
          currentStreak: 6,
          weeklyComparisonDeltaPct: 15,
          currentWeekCompleted: 4,
          previousWeekCompleted: 2,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightTodayCompletedTitle);
      expect(insight.body, l10n.habitStatsInsightTodayCompletedBody);
      expect(insight.tone, HabitStatsInsightTone.positive);
    });

    test('near milestone returns milestone insight with 2 days remaining', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          currentStreak: 5,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightNearMilestoneTitle);
      expect(insight.body, l10n.habitStatsInsightNearMilestoneBody(2, 7));
      expect(insight.body, isNot(contains('#')));
      expect(insight.tone, HabitStatsInsightTone.amber);
    });

    test('near milestone returns milestone insight with 1 day remaining', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          currentStreak: 6,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightNearMilestoneTitle);
      expect(insight.body, l10n.habitStatsInsightNearMilestoneBody(1, 7));
      expect(insight.body, isNot(contains('#')));
      expect(insight.tone, HabitStatsInsightTone.amber);
    });

    test('active streak pending still works when not near milestone', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          currentStreak: 4,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightPendingStreakTitle);
      expect(insight.body, l10n.habitStatsInsightPendingStreakBody(5));
      expect(insight.body, contains('5'));
      expect(insight.body, isNot(contains('#')));
      expect(insight.tone, HabitStatsInsightTone.neutral);
    });

    test('all resolved insight titles and bodies avoid # placeholders', () {
      final scenarios = <HabitStatsShellData>[
        _shell(todayState: HabitStatsDayState.skipped),
        _shell(todayState: HabitStatsDayState.completed),
        _shell(todayState: HabitStatsDayState.pending, currentStreak: 5),
        _shell(todayState: HabitStatsDayState.pending, currentStreak: 4),
        _shell(
          todayState: HabitStatsDayState.pending,
          isCounter: true,
          countDailyTarget: 5,
          todayCount: 2,
        ),
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyTarget: 4,
          weeklyCompleted: 4,
        ),
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyComparisonDeltaPct: 20,
          currentWeekCompleted: 5,
          previousWeekCompleted: 3,
        ),
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyComparisonDeltaPct: -20,
          currentWeekCompleted: 2,
          previousWeekCompleted: 4,
        ),
        _shell(todayState: HabitStatsDayState.pending, weeklyConsistencyPct: 80),
        _shell(
          todayState: HabitStatsDayState.pending,
          hasBestMomentData: true,
          bestMomentSlot: HabitStatsBestMomentSlot.morning,
        ),
        _shell(todayState: HabitStatsDayState.pending, weeklyConsistencyPct: 20),
        _shell(
          todayState: HabitStatsDayState.pending,
          hasHistory: true,
          last7States: const <HabitStatsDayState>[
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
          ],
        ),
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyTarget: 7,
          weeklyCompleted: 2,
          weeklyConsistencyPct: 40,
        ),
      ];

      for (final shell in scenarios) {
        final insight = resolveHabitStatsInsight(l10n, shell);
        expect(insight.title, isNot(contains('#')));
        expect(insight.body, isNot(contains('#')));
      }
    });

    test('insight ARB messages avoid # placeholders in en/es', () {
      for (final path in <String>[
        'lib/l10n/app_en.arb',
        'lib/l10n/app_es.arb',
      ]) {
        final content = File(path).readAsStringSync();
        final insightLineMatches = RegExp(
          r'"habitStatsInsight[^"]*"\s*:\s*"([^"]*)"',
        ).allMatches(content);

        for (final match in insightLineMatches) {
          final message = match.group(1) ?? '';
          expect(message, isNot(contains('#')), reason: '$path -> $message');
        }
      }
    });

    test('count habit partial progress returns partial progress insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          isCounter: true,
          countDailyTarget: 5,
          todayCount: 2,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightCountPartialTitle);
      expect(insight.body, l10n.habitStatsInsightCountPartialBody);
      expect(insight.tone, HabitStatsInsightTone.amber);
    });

    test('weekly target achieved returns weekly goal insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyTarget: 4,
          weeklyCompleted: 4,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightWeeklyGoalTitle);
      expect(insight.body, l10n.habitStatsInsightWeeklyGoalBody);
      expect(insight.tone, HabitStatsInsightTone.positive);
    });

    test('positive weekly comparison returns positive trend insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyComparisonDeltaPct: 20,
          currentWeekCompleted: 5,
          previousWeekCompleted: 3,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightWeeklyTrendPositiveTitle);
      expect(insight.body, l10n.habitStatsInsightWeeklyTrendPositiveBody);
      expect(insight.tone, HabitStatsInsightTone.positive);
    });

    test('negative weekly comparison returns soft negative trend insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyComparisonDeltaPct: -20,
          currentWeekCompleted: 2,
          previousWeekCompleted: 4,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightWeeklyTrendNegativeTitle);
      expect(insight.body, l10n.habitStatsInsightWeeklyTrendNegativeBody);
      expect(insight.tone, HabitStatsInsightTone.recovery);
    });

    test('strong consistency returns solid rhythm insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyConsistencyPct: 80,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightStrongConsistencyTitle);
      expect(insight.body, l10n.habitStatsInsightStrongConsistencyBody);
      expect(insight.tone, HabitStatsInsightTone.positive);
    });

    test('best moment returns best moment insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          hasBestMomentData: true,
          bestMomentSlot: HabitStatsBestMomentSlot.morning,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightBestMomentTitle);
      expect(
        insight.body,
        l10n.habitStatsInsightBestMomentBody(
          l10n.statisticsV3MomentMorning.toLowerCase(),
        ),
      );
      expect(insight.tone, HabitStatsInsightTone.neutral);
    });

    test('low consistency still returns recovery/simple insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyConsistencyPct: 20,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightLowConsistencyTitle);
      expect(insight.body, l10n.habitStatsInsightLowConsistencyBody);
      expect(insight.tone, HabitStatsInsightTone.recovery);
    });

    test('recent inactivity returns recovery insight when data exists', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          hasHistory: true,
          last7States: const <HabitStatsDayState>[
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
            HabitStatsDayState.pending,
          ],
        ),
      );

      expect(insight.title, l10n.habitStatsInsightRecoveryTitle);
      expect(insight.body, l10n.habitStatsInsightRecoveryBody);
      expect(insight.tone, HabitStatsInsightTone.recovery);
    });

    test('fallback returns default insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyTarget: 7,
          weeklyCompleted: 2,
          weeklyConsistencyPct: 40,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightFallbackTitle);
      expect(insight.body, l10n.habitStatsInsightFallbackBody);
      expect(insight.tone, HabitStatsInsightTone.neutral);
    });
  });
}

HabitStatsShellData _shell({
  required HabitStatsDayState todayState,
  List<HabitStatsDayState>? last7States,
  int currentStreak = 0,
  bool isCounter = false,
  num todayCount = 0,
  num countDailyTarget = 0,
  int weeklyTarget = 0,
  int weeklyCompleted = 0,
  int weeklyConsistencyPct = 60,
  int? weeklyComparisonDeltaPct,
  int? currentWeekCompleted,
  int? previousWeekCompleted,
  bool hasBestMomentData = false,
  HabitStatsBestMomentSlot bestMomentSlot = HabitStatsBestMomentSlot.unknown,
  bool hasHistory = false,
}) {
  final today = DateTime.now();
  final states = last7States ??
      List<HabitStatsDayState>.generate(
        7,
        (index) => index == 6 ? todayState : HabitStatsDayState.pending,
        growable: false,
      );
  final recent = List<HabitStatsLast7DayItem>.generate(
    7,
    (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return HabitStatsLast7DayItem(
        date: date,
        weekdayLabel: '',
        state: states[index],
      );
    },
    growable: false,
  );

  final todayKey = DateTime(today.year, today.month, today.day);
  final countsByDay = <DateTime, int>{};
  if (hasHistory) {
    final historyKey = todayKey.subtract(const Duration(days: 10));
    countsByDay[historyKey] = 1;
  }

  final countValuesByDay = <DateTime, num>{};
  if (todayCount > 0) {
    countValuesByDay[todayKey] = todayCount;
  }

  return HabitStatsShellData(
    habitId: 'habit-1',
    title: 'Habit',
    familyName: 'Mind',
    objectiveSummary: '',
    typeLabel: isCounter ? 'Count' : 'Check',
    isCounter: isCounter,
    currentStreak: currentStreak,
    bestStreak: currentStreak,
    weeklyTarget: weeklyTarget,
    weeklyCompleted: weeklyCompleted,
    previousWeekCompleted: previousWeekCompleted,
    currentWeekCompleted: currentWeekCompleted,
    weeklyConsistencyPct: weeklyConsistencyPct,
    weeklyComparisonDeltaPct: weeklyComparisonDeltaPct,
    bestMomentLabel: '',
    bestMomentSlot: bestMomentSlot,
    hasBestMomentData: hasBestMomentData,
    last7Days: recent,
    countLast7Days: const <HabitStatsCountLast7DayItem>[],
    countDailyTarget: countDailyTarget,
    countUnitLabel: '',
    countsByDay: countsByDay,
    countValuesByDay: countValuesByDay,
    skipsByDay: const <DateTime, bool>{},
    completionTimesByDay: const <DateTime, int>{},
  );
}
