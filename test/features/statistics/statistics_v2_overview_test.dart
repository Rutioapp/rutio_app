import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/statistics/application/adapters/statistics_data_adapter.dart';
import 'package:rutio/features/statistics/domain/statistics_models.dart';
import 'package:rutio/features/statistics/domain/statistics_period.dart';
import 'package:rutio/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:rutio/features/statistics/presentation/widgets/statistics_overview_tab.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adapter = StatisticsDataAdapter();
  final anchor = DateTime(2026, 5, 5);
  final todayKey = _dateKey(anchor);

  testWidgets('Statistics V2 Overview renders without habits/data', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: const <Map<String, dynamic>>[],
    );
    await store.load();

    final summary = adapter.buildOverview(
      store: store,
      period: StatisticsPeriod.week,
      anchor: anchor,
    );

    await _pumpOverview(tester, summary: summary, locale: const Locale('en'));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.statisticsV2OverviewSummaryTitle), findsOneWidget);
    expect(find.byType(StatisticsOverviewTab), findsOneWidget);
  });

  testWidgets('Statistics V2 Overview renders with check habits', (
    tester,
  ) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _checkHabit('check_1'),
      ],
      habitCompletions: <String, dynamic>{
        todayKey: <String, dynamic>{'check_1': true},
      },
    );
    await store.load();

    final summary = adapter.buildOverview(
      store: store,
      period: StatisticsPeriod.day,
      anchor: anchor,
    );

    expect(summary.completedHabits, 1);
    expect(summary.habitsWithProgress, 1);
    expect(summary.overallConsistencyPct, 100);

    await _pumpOverview(tester, summary: summary, locale: const Locale('en'));
    expect(find.byType(StatisticsOverviewTab), findsOneWidget);
  });

  testWidgets('Count 6/8 counts as progress but not as completed', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _countHabit('count_1', target: 8),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 6},
      },
    );
    await store.load();

    final summary = adapter.buildOverview(
      store: store,
      period: StatisticsPeriod.day,
      anchor: anchor,
    );

    expect(summary.habitsWithProgress, 1);
    expect(summary.completedHabits, 0);
    expect(summary.countPartialProgressDays, 1);
    expect(summary.countGoalCompletedDays, 0);

    await _pumpOverview(tester, summary: summary, locale: const Locale('en'));
    expect(find.byType(StatisticsOverviewTab), findsOneWidget);
  });

  testWidgets('Count 8/8 is counted as goal completed', (tester) async {
    final store = await _seedStore(
      habits: <Map<String, dynamic>>[
        _countHabit('count_1', target: 8),
      ],
      habitCountValues: <String, dynamic>{
        todayKey: <String, dynamic>{'count_1': 8},
      },
    );
    await store.load();

    final summary = adapter.buildOverview(
      store: store,
      period: StatisticsPeriod.day,
      anchor: anchor,
    );

    expect(summary.habitsWithProgress, 1);
    expect(summary.completedHabits, 1);
    expect(summary.countPartialProgressDays, 0);
    expect(summary.countGoalCompletedDays, 1);
  });

  testWidgets('Day/Week/Month selector changes visible period subtitle', (
    tester,
  ) async {
    final store = await _seedStore(habits: const <Map<String, dynamic>>[]);
    await store.load();

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

    expect(find.text('This week'), findsOneWidget);

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('This month'), findsOneWidget);
  });

  testWidgets('Statistics V2 main labels are rendered from l10n', (tester) async {
    final store = await _seedStore(habits: const <Map<String, dynamic>>[]);
    await store.load();

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

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.statisticsV2Title), findsOneWidget);
    expect(find.text(l10n.statisticsV2TabOverview), findsOneWidget);
    expect(find.text(l10n.statisticsV2TabHabits), findsOneWidget);
    expect(find.text(l10n.statisticsV2PeriodDay), findsOneWidget);
    expect(find.text(l10n.statisticsV2PeriodWeek), findsOneWidget);
    expect(find.text(l10n.statisticsV2PeriodMonth), findsOneWidget);
  });
}

Future<void> _pumpOverview(
  WidgetTester tester, {
  required StatisticsOverviewSummary summary,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatisticsOverviewTab(summary: summary),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<UserStateStore> _seedStore({
  required List<Map<String, dynamic>> habits,
  Map<String, dynamic>? habitCompletions,
  Map<String, dynamic>? habitCountValues,
  Map<String, dynamic>? habitCompletionTimes,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('stats_test_user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );

  final state = <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'stats_test_user',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
      },
      'history': <String, dynamic>{
        'habitCompletions': habitCompletions ?? <String, dynamic>{},
        'habitCountValues': habitCountValues ?? <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': habitCompletionTimes ?? <String, dynamic>{},
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

Map<String, dynamic> _checkHabit(String id) {
  return <String, dynamic>{
    'id': id,
    'name': 'Habit $id',
    'familyId': 'mind',
    'type': 'check',
    'target': 1,
    'schedule': <String, dynamic>{'type': 'daily'},
    'isCustom': true,
  };
}

Map<String, dynamic> _countHabit(String id, {required int target}) {
  return <String, dynamic>{
    'id': id,
    'name': 'Habit $id',
    'familyId': 'body',
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
