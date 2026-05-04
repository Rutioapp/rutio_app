import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_monthly/utils/month_utils.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_calendar_grid.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_day_cell.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats_tab.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/profile/utils/profile_levels_from_history.dart';
import 'package:rutio/screens/weekly/widgets/helpers/weekly_habit_day_state_resolver.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/widgets/stats/stats_metrics_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

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
    final monthCursor =
        DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
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

  group('Count completion regression - home selectors', () {
    test('home does not classify 6/8 as completed', () {
      final selectedDay = DateTime(2026, 5, 1);
      final root = {
        'userState': {
          'activeHabits': [
            {
              'id': 'run',
              'type': 'count',
              'target': 8,
              'doneToday': false,
              'skippedToday': false,
              'progress': 0,
              'schedule': {'type': 'daily'},
            },
          ],
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
          'progression': {'xp': 0},
          'wallet': {'coins': 0},
        },
      };

      final data = buildHomeViewData(root, selectedDay);
      expect(data.completedHabits, isEmpty);
      expect(data.pendingHabits.length, 1);
      expect(data.pendingHabits.first['doneToday'], isFalse);
    });

    test('home keeps check habits completed behavior unchanged', () {
      final selectedDay = DateTime(2026, 5, 1);
      final root = {
        'userState': {
          'activeHabits': [
            {
              'id': 'meditate',
              'type': 'check',
              'doneToday': false,
              'skippedToday': false,
              'progress': 0,
              'schedule': {'type': 'daily'},
            },
          ],
          'history': {
            'habitCompletions': {
              '2026-05-01': {'meditate': true},
            },
            'habitCountValues': <String, dynamic>{},
            'habitSkips': {
              '2026-05-01': {'meditate': false},
            },
          },
          'progression': {'xp': 0},
          'wallet': {'coins': 0},
        },
      };

      final data = buildHomeViewData(root, selectedDay);
      expect(data.completedHabits.length, 1);
      expect(data.completedHabits.first['id'], 'meditate');
    });
  });

  group('Count completion regression - stats overview', () {
    testWidgets('6/8 is not counted as completed in completion metric',
        (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        _baseStateForCountRegression(
          dayKey: dayKey,
          value: 6,
          target: 8,
          skipped: false,
          completionFlag: true,
          schedule: {
            'type': 'once',
            'date': dayKey,
          },
        ),
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HabitStatsOverviewScreen(habits: store.activeHabits),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        _anyGridMetricMatches(
          tester,
          label: 'Total acumulado',
          value: '6',
        ),
        isTrue,
      );
      expect(_findTextIgnoreCase('Objetivo completado'), findsWidgets);
      expect(_findTextIgnoreCase('Progreso parcial'), findsWidgets);
      expect(_findTextIgnoreCase('Cumplimiento medio'), findsWidgets);
      expect(
        _anyGridMetricMatches(tester, label: 'Consistencia'),
        isFalse,
      );
    });

    testWidgets('8/8 is counted as completed in completion metric',
        (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        _baseStateForCountRegression(
          dayKey: dayKey,
          value: 8,
          target: 8,
          skipped: false,
          completionFlag: false,
          schedule: {
            'type': 'once',
            'date': dayKey,
          },
        ),
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HabitStatsOverviewScreen(habits: store.activeHabits),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        _anyGridMetricMatches(
          tester,
          label: 'Total acumulado',
          value: '8',
        ),
        isTrue,
      );
      expect(_findTextIgnoreCase('Objetivo completado'), findsWidgets);
    });

    testWidgets('one 8/8 day in weekly range is not counted as 7/7 completed',
        (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        _baseStateForCountRegression(
          dayKey: dayKey,
          value: 8,
          target: 8,
          skipped: false,
          completionFlag: false,
          schedule: const {
            'type': 'daily',
          },
          habitProgressValue: 8,
          habitCurrentValue: 8,
          habitValue: 8,
        ),
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HabitStatsOverviewScreen(habits: store.activeHabits),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(_findTextIgnoreCase('Objetivo completado'), findsWidgets);
    });

    testWidgets('skipped + 6/8 is neither completed nor progress',
        (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        _baseStateForCountRegression(
          dayKey: dayKey,
          value: 6,
          target: 8,
          skipped: true,
          completionFlag: true,
          schedule: {
            'type': 'once',
            'date': dayKey,
          },
        ),
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HabitStatsOverviewScreen(habits: store.activeHabits),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        _anyGridMetricMatches(
          tester,
          label: 'Total acumulado',
          value: '0',
        ),
        isTrue,
      );
      expect(_findTextIgnoreCase('Objetivo completado'), findsWidgets);
      expect(_findTextIgnoreCase('Progreso parcial'), findsWidgets);
    });

    testWidgets('check habits keep consistency label and do not show count labels',
        (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        {
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
                dayKey: {'meditate': true},
              },
              'habitCountValues': <String, dynamic>{},
              'habitSkips': {
                dayKey: {'meditate': false},
              },
              'habitCompletionTimes': <String, dynamic>{},
            },
            'activeHabits': [
              {
                'id': 'meditate',
                'name': 'Meditate',
                'familyId': 'mind',
                'type': 'check',
                'schedule': {
                  'type': 'once',
                  'date': dayKey,
                },
                'doneToday': false,
                'skippedToday': false,
                'progress': 0,
              },
            ],
          },
        },
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HabitStatsOverviewScreen(habits: store.activeHabits),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        _anyGridMetricMatches(tester, label: 'Consistencia'),
        isTrue,
      );
      expect(
        _anyGridMetricMatches(tester, label: 'Total acumulado'),
        isFalse,
      );
    });
  });

  group('Count completion regression - habit detail tab', () {
    testWidgets('count 6/8 shows partial progress and not completed',
        (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        _baseStateForCountRegression(
          dayKey: dayKey,
          value: 6,
          target: 8,
          skipped: false,
          completionFlag: true,
          schedule: {
            'type': 'once',
            'date': dayKey,
          },
          unit: 'km',
        ),
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: HabitStatsTab(
                habit: store.activeHabits.first,
                familyColor: Colors.blue,
                scrollable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('0/1 dias'), findsWidgets);
      expect(find.text('1 dias'), findsWidgets);
      expect(find.text('6 km'), findsWidgets);
      expect(find.text('Volumen'), findsWidgets);
      expect(find.text('Objetivo'), findsWidgets);
      expect(_findTextIgnoreCase('Total acumulado'), findsWidgets);
      expect(_findTextIgnoreCase('Objetivo completado'), findsWidgets);
      expect(_findTextIgnoreCase('Progreso parcial'), findsWidgets);
      expect(_findTextIgnoreCase('Cumplimiento medio'), findsWidgets);
      expect(_findTextIgnoreCase('Consistencia'), findsNothing);
    });

    testWidgets('count 8/8 appears as completed in detail metrics',
        (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        _baseStateForCountRegression(
          dayKey: dayKey,
          value: 8,
          target: 8,
          skipped: false,
          completionFlag: false,
          schedule: {
            'type': 'once',
            'date': dayKey,
          },
          unit: 'km',
        ),
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: HabitStatsTab(
                habit: store.activeHabits.first,
                familyColor: Colors.blue,
                scrollable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('1/1 dias'), findsWidgets);
    });

    testWidgets('single 6/8 day does not appear as partial on all week days',
        (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        _baseStateForCountRegression(
          dayKey: dayKey,
          value: 6,
          target: 8,
          skipped: false,
          completionFlag: true,
          schedule: const {
            'type': 'daily',
          },
          unit: 'km',
          habitProgressValue: 6,
          habitCurrentValue: 6,
          habitValue: 6,
        ),
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: HabitStatsTab(
                habit: store.activeHabits.first,
                familyColor: Colors.blue,
                scrollable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('0/7 dias'), findsWidgets);
      expect(find.text('1 dias'), findsWidgets);
    });

    testWidgets('check habits keep previous detail behavior', (tester) async {
      final today = DateTime.now();
      final dayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final store = await _buildStoreWithState(
        {
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
                dayKey: {'meditate': true},
              },
              'habitCountValues': <String, dynamic>{},
              'habitSkips': {
                dayKey: {'meditate': false},
              },
              'habitCompletionTimes': <String, dynamic>{},
            },
            'activeHabits': [
              {
                'id': 'meditate',
                'name': 'Meditate',
                'familyId': 'mind',
                'type': 'check',
                'schedule': {
                  'type': 'once',
                  'date': dayKey,
                },
                'doneToday': false,
                'skippedToday': false,
                'progress': 0,
              },
            ],
          },
        },
      );
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: HabitStatsTab(
                habit: store.activeHabits.first,
                familyColor: Colors.blue,
                scrollable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Completado'), findsWidgets);
    });
  });
}

Finder _findTextIgnoreCase(String text) {
  final normalized = text.trim().toLowerCase();
  return find.byWidgetPredicate(
    (widget) {
      if (widget is! Text) return false;
      final data = widget.data;
      return data != null && data.trim().toLowerCase() == normalized;
    },
    skipOffstage: false,
  );
}

bool _anyGridMetricMatches(
  WidgetTester tester, {
  required String label,
  String? value,
}) {
  final normalizedLabel = label.trim().toLowerCase();
  final grids = tester
      .widgetList<StatsMetricsGrid>(
        find.byType(StatsMetricsGrid, skipOffstage: false),
      )
      .toList();
  for (final grid in grids) {
    final match = grid.metrics.any((metric) {
      final labelMatches =
          metric.labelUpper.trim().toLowerCase() == normalizedLabel;
      if (!labelMatches) return false;
      if (value == null) return true;
      return metric.value.trim() == value.trim();
    });
    if (match) return true;
  }
  return false;
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
  Map<String, dynamic>? schedule,
  String? unit,
  num? habitProgressValue,
  num? habitCurrentValue,
  num? habitValue,
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
          if (unit != null) 'unit': unit,
          'schedule': schedule ?? {'type': 'daily'},
          'doneToday': false,
          'skippedToday': false,
          'progress': habitProgressValue ?? 0,
          if (habitCurrentValue != null) 'currentValue': habitCurrentValue,
          if (habitValue != null) 'value': habitValue,
        },
      ],
    },
  };
}
