import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayKey = _dateKey(today);

  testWidgets('Statistics habits tab renders empty list', (tester) async {
    final store = await _seedStore(habits: const <Map<String, dynamic>>[]);
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    expect(find.text('You still have no active habits'), findsOneWidget);
  });

  testWidgets('Statistics habits tab renders check habits', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Morning walk', emoji: '🚶'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.text('Morning walk'), findsOneWidget);
    expect(find.text('🚶'), findsOneWidget);
    expect(_metricByKey(tester, 'statistics_habit_secondary_metric'), '1/1 days');
    expect(_metricByKey(tester, 'statistics_habit_primary_metric'), '100% completed');
  });

  testWidgets('Habit list card uses habit emoji when available', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Run', emoji: '🏃'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.text('🏃'), findsOneWidget);
  });

  testWidgets('Habit emoji falls back to family emoji when missing', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit(
          'check_1',
          name: 'Read',
          emoji: '',
          familyId: 'mind',
        ),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.text('🧠'), findsWidgets);
  });

  testWidgets('Habit card shows family as secondary chip', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit(
          'check_1',
          name: 'Journal',
          emoji: '✍️',
          familyId: 'mind',
        ),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.text('🧠 Mente'), findsOneWidget);
  });

  testWidgets('Statistics habits tab renders count habits', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _countHabit('count_1', name: 'Read pages', target: 8),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 8},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.text('Read pages'), findsOneWidget);
    expect(
      _metricByKey(tester, 'statistics_habit_secondary_metric'),
      '1 goals completed',
    );
    expect(_metricByKey(tester, 'statistics_habit_tertiary_metric'), '0 partial days');
  });

  testWidgets('Count 6/8 shows partial progress and not completed goal', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _countHabit('count_1', name: 'Run', target: 8),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 6},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(
      _metricByKey(tester, 'statistics_habit_tertiary_metric'),
      '1 partial days',
    );
    expect(
      _metricByKey(tester, 'statistics_habit_secondary_metric'),
      '0 goals completed',
    );
  });

  testWidgets('Count 8/8 shows goal completed', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _countHabit('count_1', name: 'Run', target: 8),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 8},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(
      _metricByKey(tester, 'statistics_habit_secondary_metric'),
      '1 goals completed',
    );
    expect(_metricByKey(tester, 'statistics_habit_tertiary_metric'), '0 partial days');
  });

  testWidgets('Habits search filters by name', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Morning walk'),
        _checkHabit('check_2', name: 'Read'),
      ],
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.enterText(
      find.byKey(const Key('statistics_habits_search_field')),
      'read',
    );
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Morning walk'), findsNothing);
  });

  testWidgets('Habits filter All/Check/Count works', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Check habit'),
        _countHabit('count_1', name: 'Count habit', target: 8),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 2},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    expect(find.text('Check habit'), findsOneWidget);
    expect(find.text('Count habit'), findsOneWidget);

    await tester.tap(find.text('Check').first);
    await tester.pumpAndSettle();
    expect(find.text('Check habit'), findsOneWidget);
    expect(find.text('Count habit'), findsNothing);

    await tester.tap(find.text('Count').first);
    await tester.pumpAndSettle();
    expect(find.text('Check habit'), findsNothing);
    expect(find.text('Count habit'), findsOneWidget);

    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    expect(find.text('Check habit'), findsOneWidget);
    expect(find.text('Count habit'), findsOneWidget);
  });

  testWidgets('Tap on habit card opens real statistics detail', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Morning walk'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Morning walk').first);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.statisticsV2DetailTitle), findsOneWidget);
  });

  testWidgets('Changing period updates visible metrics in habits tab', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Reading'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(_metricByKey(tester, 'statistics_habit_secondary_metric'), '1/1 days');

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(_metricByKey(tester, 'statistics_habit_secondary_metric'), '1/7 days');
  });

  testWidgets('Check habits keep completion semantics', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Stretch'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': false},
      },
    );
    await store.load();
    await _pumpScreen(tester, store: store);

    await _openHabitsTab(tester);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(_metricByKey(tester, 'statistics_habit_secondary_metric'), '0/1 days');
    expect(_metricByKey(tester, 'statistics_habit_primary_metric'), '0% completed');
  });
}

Future<void> _openHabitsTab(WidgetTester tester) async {
  await tester.tap(find.text('Habits'));
  await tester.pumpAndSettle();
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required UserStateStore store,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<UserStateStore>.value(
      value: store,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StatisticsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<UserStateStore> _seedStore({
  required List<Map<String, dynamic>> habits,
  Map<String, dynamic>? habitCompletions,
  Map<String, dynamic>? habitCountValues,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('stats_habits_user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );

  final state = <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'stats_habits_user',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
      },
      'history': <String, dynamic>{
        'habitCompletions': habitCompletions ?? <String, dynamic>{},
        'habitCountValues': habitCountValues ?? <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
      },
      'activeHabits': habits,
      'familyXp': <String, dynamic>{
        'mind': 0,
        'spirit': 0,
        'body': 0,
        'emotional': 0,
        'social': 0,
        'discipline': 0,
        'professional': 0,
      },
      'daily': <String, dynamic>{
        'lastResetDate': _dateKey(DateTime.now()),
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'progression': <String, dynamic>{
        'level': 1,
        'xp': 0,
        'prestige': 0,
      },
      'wallet': <String, dynamic>{'coins': 0},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{
          'avatar_skin': null,
          'aura': null,
          'badge': null,
          'title': null,
          'animation': null,
        },
      },
      'claims': <String, dynamic>{
        'milestonesClaimed': <dynamic>[],
        'achievementRewardsClaimed': <dynamic>[],
        'prestigeClaimed': <dynamic>[],
      },
    },
  };

  await store.save(state);
  return store;
}

Map<String, dynamic> _checkHabit(
  String id, {
  required String name,
  String familyId = 'mind',
  String emoji = '✅',
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'familyId': familyId,
    'emoji': emoji,
    'type': 'check',
    'target': 1,
    'schedule': <String, dynamic>{'type': 'daily'},
    'isCustom': true,
  };
}

Map<String, dynamic> _countHabit(
  String id, {
  required String name,
  required int target,
  String familyId = 'body',
  String emoji = '🔢',
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'familyId': familyId,
    'emoji': emoji,
    'type': 'count',
    'target': target,
    'schedule': <String, dynamic>{'type': 'daily'},
    'isCustom': true,
  };
}

String _dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _metricByKey(WidgetTester tester, String keyName) {
  final target = find.byKey(Key(keyName));
  final text = tester.widgetList<Text>(target).first;
  return text.data ?? text.textSpan?.toPlainText() ?? '';
}
