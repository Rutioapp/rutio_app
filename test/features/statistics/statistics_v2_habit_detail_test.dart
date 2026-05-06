import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/statistics/application/adapters/statistics_data_adapter.dart';
import 'package:rutio/features/statistics/domain/statistics_period.dart';
import 'package:rutio/features/statistics/presentation/screens/statistics_habit_detail_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final todayKey = _dateKey(DateTime.now());

  testWidgets('Detail renders check habit', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Read', emoji: '📚'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();

    await _pumpDetail(tester, store: store, habitId: 'check_1');
    final l10n = _l10nOf(tester);

    expect(find.text(l10n.statisticsV2DetailTitle), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('📚'), findsOneWidget);
  });

  testWidgets('Detail renders count habit', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _countHabit('count_1', name: 'Run', target: 8, emoji: '🏃'),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 8},
      },
    );
    await store.load();
    final detail = const StatisticsDataAdapter().buildHabitDetail(
      store: store,
      habitId: 'count_1',
      period: StatisticsPeriod.week,
    );
    expect(detail, isNotNull);
    expect(detail!.habit.type.name, 'count');
    expect(detail.habit.countProgress, isNotNull);

    await _pumpDetail(tester, store: store, habitId: 'count_1');
    final l10n = _l10nOf(tester);
    expect(find.text(l10n.statisticsV2DetailTitle), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('🏃'), findsOneWidget);
    expect(find.text(l10n.statisticsV2HabitsTypeCount), findsOneWidget);
  });

  testWidgets('Detail header falls back to family emoji when habit emoji is missing', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Read', emoji: '', familyId: 'mind'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();

    await _pumpDetail(tester, store: store, habitId: 'check_1');
    expect(find.text('🧠'), findsWidgets);
  });

  test('Count 6/8 is partial progress and not goal completed', () async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _countHabit('count_1', name: 'Run', target: 8),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 6},
      },
    );
    await store.load();
    final adapter = const StatisticsDataAdapter();

    final detail = adapter.buildHabitDetail(
      store: store,
      habitId: 'count_1',
      period: StatisticsPeriod.week,
    );

    expect(detail, isNotNull);
    expect(detail!.habit.countProgress!.partialProgressDays, 1);
    expect(detail.habit.countProgress!.goalCompletedDays, 0);
  });

  test('Count 8/8 is goal completed', () async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _countHabit('count_1', name: 'Run', target: 8),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 8},
      },
    );
    await store.load();
    final adapter = const StatisticsDataAdapter();

    final detail = adapter.buildHabitDetail(
      store: store,
      habitId: 'count_1',
      period: StatisticsPeriod.week,
    );

    expect(detail, isNotNull);
    expect(detail!.habit.countProgress!.goalCompletedDays, 1);
    expect(detail.habit.countProgress!.partialProgressDays, 0);
  });

  testWidgets('Detail selector Week/Month/Year updates chart subtitle', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Read'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();

    await _pumpDetail(tester, store: store, habitId: 'check_1');
    final l10n = _l10nOf(tester);
    expect(find.text(l10n.statisticsV2DetailChartSubtitleWeek), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.statisticsV2DetailChartSubtitleMonth), findsOneWidget);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.statisticsV2DetailChartSubtitleYear), findsOneWidget);
  });

  testWidgets('Detail with no data does not crash and shows empty state', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Read'),
      ],
    );
    await store.load();

    await _pumpDetail(tester, store: store, habitId: 'check_1');
    final l10n = _l10nOf(tester);

    expect(find.text(l10n.statisticsV2DetailNoDataTitle), findsOneWidget);
  });

  testWidgets('Check habits keep check completion semantics', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1', name: 'Read'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': false},
      },
    );
    await store.load();
    final detail = const StatisticsDataAdapter().buildHabitDetail(
      store: store,
      habitId: 'check_1',
      period: StatisticsPeriod.week,
    );
    expect(detail, isNotNull);
    expect(detail!.habit.type.name, 'check');
    expect(detail.completedDays, 0);
    expect(detail.scheduledDays, 7);
    expect(detail.completionPct, 0);

    await _pumpDetail(tester, store: store, habitId: 'check_1');
    expect(find.byType(StatisticsHabitDetailScreen), findsOneWidget);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required UserStateStore store,
  required String habitId,
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
        home: StatisticsHabitDetailScreen(habitId: habitId),
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
    ..setActiveUserScope('stats_detail_user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );

  final state = <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'stats_detail_user',
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

AppLocalizations _l10nOf(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return AppLocalizations.of(context);
}
