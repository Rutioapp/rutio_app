import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/screens/habit_monthly/utils/month_utils.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_calendar_grid.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_day_cell.dart';
import 'package:rutio/screens/profile/utils/profile_levels_from_history.dart';
import 'package:rutio/screens/weekly/widgets/helpers/weekly_habit_day_state_resolver.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Count completion regression - weekly resolver', () {
    const dayKey = '2026-05-01';
    const habitId = 'run';
    final habit = <String, dynamic>{
      'id': habitId,
      'type': 'count',
      'target': 8,
    };

    test('does not mark 6/8 as done even if completion map is true', () {
      const resolver = WeeklyHabitDayStateResolver(
        habitCompletions: {
          dayKey: {habitId: true},
        },
        habitSkips: {},
        habitCountValues: {
          dayKey: {habitId: 6},
        },
      );

      final state = resolver.buildDayState(habit, habitId, dayKey);
      expect(state.hasValue, isTrue);
      expect(state.isAchieved, isFalse);
      expect(state.isDone, isFalse);
    });

    test('marks 8/8 as achieved', () {
      const resolver = WeeklyHabitDayStateResolver(
        habitCompletions: {},
        habitSkips: {},
        habitCountValues: {
          dayKey: {habitId: 8},
        },
      );

      final state = resolver.buildDayState(habit, habitId, dayKey);
      expect(state.hasValue, isTrue);
      expect(state.isAchieved, isTrue);
      expect(state.isDone, isFalse);
    });

    test('returns empty when value is 0', () {
      const resolver = WeeklyHabitDayStateResolver(
        habitCompletions: {},
        habitSkips: {},
        habitCountValues: {
          dayKey: {habitId: 0},
        },
      );

      final state = resolver.buildDayState(habit, habitId, dayKey);
      expect(state.hasValue, isFalse);
      expect(state.isDone, isFalse);
      expect(state.isSkipped, isFalse);
    });

    test('skipped day is always skip for count', () {
      const resolver = WeeklyHabitDayStateResolver(
        habitCompletions: {
          dayKey: {habitId: true},
        },
        habitSkips: {
          dayKey: {habitId: true},
        },
        habitCountValues: {
          dayKey: {habitId: 6},
        },
      );

      final state = resolver.buildDayState(habit, habitId, dayKey);
      expect(state.isSkipped, isTrue);
      expect(state.isDone, isFalse);
      expect(state.hasValue, isFalse);
    });
  });

  group('Count completion regression - monthly resolver', () {
    final monthCursor = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
    final day1Key = MonthUtils.dateKey(monthCursor);
    const habitId = 'run';
    final habit = <String, dynamic>{
      'id': habitId,
      'type': 'count',
      'target': 8,
      'schedule': <String, dynamic>{'type': 'daily'},
    };

    Finder dayCellFinder(int day) {
      return find.byWidgetPredicate(
        (widget) => widget is MonthlyDayCell && widget.day == day,
      );
    }

    testWidgets('6/8 is not marked done in monthly grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarGrid(
              monthCursor: monthCursor,
              habit: habit,
              accentColor: Colors.blue,
              habitCompletions: {
                day1Key: {habitId: true},
              },
              habitCountValues: {
                day1Key: {habitId: 6},
              },
              habitSkips: const {},
            ),
          ),
        ),
      );

      final finder = dayCellFinder(1);
      expect(finder, findsOneWidget);
      final cell = tester.widget<MonthlyDayCell>(finder);
      expect(cell.status, MonthlyDayStatus.missed);
    });

    testWidgets('8/8 is marked done in monthly grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarGrid(
              monthCursor: monthCursor,
              habit: habit,
              accentColor: Colors.blue,
              habitCompletions: const {},
              habitCountValues: {
                day1Key: {habitId: 8},
              },
              habitSkips: const {},
            ),
          ),
        ),
      );

      final finder = dayCellFinder(1);
      expect(finder, findsOneWidget);
      final cell = tester.widget<MonthlyDayCell>(finder);
      expect(cell.status, MonthlyDayStatus.done);
    });

    testWidgets('skipped day with partial value is not done', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarGrid(
              monthCursor: monthCursor,
              habit: habit,
              accentColor: Colors.blue,
              habitCompletions: {
                day1Key: {habitId: true},
              },
              habitCountValues: {
                day1Key: {habitId: 6},
              },
              habitSkips: {
                day1Key: {habitId: true},
              },
            ),
          ),
        ),
      );

      final finder = dayCellFinder(1);
      expect(finder, findsOneWidget);
      final cell = tester.widget<MonthlyDayCell>(finder);
      expect(cell.status, MonthlyDayStatus.skip);
    });
  });

  group('Count completion regression - profile/achievements', () {
    test('profile family levels do not count 6/8 as completion', () {
      final levels = buildFamilyLevelsFromHistory(
        userState: {
          'history': {
            'habitCompletions': {
              '2026-05-01': {'run': true},
            },
            'habitCountValues': {
              '2026-05-01': {'run': 6},
            },
            'habitSkips': {
              '2026-05-01': {'run': false},
            },
          },
        },
        activeHabits: const [
          {
            'id': 'run',
            'familyId': 'body',
            'type': 'count',
            'target': 8,
          },
        ],
        familyTitleResolver: (familyId) => familyId,
      );

      final body = levels.firstWhere((entry) => entry.id == 'body');
      expect(body.xp, 0);
    });

    test(
      'achievement streak snapshots do not count 6/8 as completed day',
      () async {
        final store = await _buildStoreWithState(
          _baseStateForCountRegression(
            dayKey: '2026-05-01',
            value: 6,
            target: 8,
            skipped: false,
            completionFlag: true,
          ),
        );
        await store.load();

        final snapshot = store.habitStreakSnapshotForHabitId('run');
        expect(snapshot.totalCompletedDays, 0);
        expect(snapshot.bestStreak, 0);
      },
    );
  });
}

Future<UserStateStore> _buildStoreWithState(Map<String, dynamic> state) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user_123');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(state);
  return store;
}

Map<String, dynamic> _baseStateForCountRegression({
  required String dayKey,
  required num value,
  required num target,
  required bool skipped,
  required bool completionFlag,
}) {
  return {
    'userState': {
      'userId': 'user_123',
      'meta': {
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
      },
      'progression': {'level': 1, 'xp': 0, 'prestige': 0},
      'wallet': {'coins': 0},
      'profile': {
        'achievements': {
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
        },
      },
      'daily': {
        'lastResetDate': dayKey,
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': {
        'habitCompletions': {
          dayKey: {'run': completionFlag},
        },
        'habitCountValues': {
          dayKey: {'run': value},
        },
        'habitSkips': {
          dayKey: {'run': skipped},
        },
        'habitCompletionTimes': <String, dynamic>{},
      },
      'activeHabits': [
        {
          'id': 'run',
          'name': 'Run',
          'familyId': 'body',
          'type': 'count',
          'target': target,
          'schedule': {'type': 'daily'},
          'doneToday': false,
          'skippedToday': false,
          'progress': 0,
        },
      ],
    },
  };
}
