import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/features/statistics/presentation/v3/screens/statistics_v3_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;

  group('StatisticsV3 reward breakdown sheet', () {
    testWidgets('long press on XP metric opens breakdown sheet',
        (tester) async {
      final now = DateTime.now();
      final store = _FakeStatisticsV3Store(
        _rootState(
          now: now,
          activeHabits: [_habit(id: 'habit-xp', title: 'Habit XP')],
          history: _historyWithCheckCompletion(now, 'habit-xp'),
        ),
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester
          .longPress(find.byKey(const Key('statisticsV3SummaryMetricXp')));
      await tester.pumpAndSettle();

      expect(find.text('Reward breakdown'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('+10 XP · +5 Amber'), findsAtLeastNWidgets(1));
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('long press on Amber metric opens breakdown sheet',
        (tester) async {
      final now = DateTime.now();
      final store = _FakeStatisticsV3Store(
        _rootState(
          now: now,
          activeHabits: [_habit(id: 'habit-amber', title: 'Habit Amber')],
          history: _historyWithCheckCompletion(now, 'habit-amber'),
        ),
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester
          .longPress(find.byKey(const Key('statisticsV3SummaryMetricAmber')));
      await tester.pumpAndSettle();

      expect(find.text('Reward breakdown'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('+10 XP · +5 Amber'), findsAtLeastNWidgets(1));
    });

    testWidgets('empty period shows calm empty state', (tester) async {
      final store = _FakeStatisticsV3Store(
        _rootState(
          now: DateTime.now(),
          activeHabits: [_habit(id: 'habit-empty', title: 'Habit Empty')],
          history: <String, dynamic>{
            'habitCompletions': <String, dynamic>{},
            'habitCompletionTimes': <String, dynamic>{},
            'habitSkips': <String, dynamic>{},
            'habitCountValues': <String, dynamic>{},
          },
        ),
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester
          .longPress(find.byKey(const Key('statisticsV3SummaryMetricXp')));
      await tester.pumpAndSettle();

      expect(find.text('No rewards recorded in this period.'), findsOneWidget);
      expect(find.text('+0 XP · +0 Amber'), findsAtLeastNWidgets(1));
    });

    testWidgets('sheet remains stable on compact width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final store = _FakeStatisticsV3Store(
        _rootState(
          now: now,
          activeHabits: [_habit(id: 'habit-mini', title: 'Habit Mini')],
          history: _historyWithCheckCompletion(now, 'habit-mini'),
        ),
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester
          .longPress(find.byKey(const Key('statisticsV3SummaryMetricXp')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reward breakdown'), findsOneWidget);
    });

    testWidgets(
      'global footer shows fallback insight and removes legacy footer phrase',
      (tester) async {
        final store = _FakeStatisticsV3Store(
          _rootState(
            now: DateTime.now(),
            activeHabits: [_habit(id: 'habit-empty', title: 'Habit Empty')],
            history: <String, dynamic>{
              'habitCompletions': <String, dynamic>{},
              'habitCompletionTimes': <String, dynamic>{},
              'habitSkips': <String, dynamic>{},
              'habitCountValues': <String, dynamic>{},
            },
          ),
        );

        await tester.pumpWidget(_app(store));
        await tester.pumpAndSettle();
        await _scrollToGlobalInsightFooter(tester);

        expect(
          find.byKey(const Key('statisticsV3GlobalInsightFooter')),
          findsOneWidget,
        );
        expect(
          find.textContaining("you'll see a useful reading"),
          findsOneWidget,
        );
        expect(find.byKey(const Key('statisticsV3GlobalInsightEmoji')),
            findsOneWidget);
        expect(find.text('🌱'), findsOneWidget);
        expect(find.text('There is still time to begin'), findsNothing);
      },
    );

    testWidgets('global footer shows high consistency insight', (tester) async {
      final now = DateTime.now();
      final completions = List<_CompletionSeed>.generate(
        7,
        (index) => _CompletionSeed(
          day: now.subtract(Duration(days: index)),
          habitId: 'habit-consistent',
        ),
      );
      final store = _FakeStatisticsV3Store(
        _rootState(
          now: now,
          activeHabits: [
            _habit(id: 'habit-consistent', title: 'Habit Consistent'),
          ],
          history: _historyWithCompletions(completions),
        ),
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();
      await _scrollToGlobalInsightFooter(tester);

      expect(
        find.textContaining('keeping a solid rhythm'),
        findsOneWidget,
      );
      expect(find.text('✨'), findsOneWidget);
    });

    testWidgets('global footer can show featured family insight',
        (tester) async {
      final now = DateTime.now();
      final completions = List<_CompletionSeed>.generate(
        7,
        (index) => _CompletionSeed(
          day: now.subtract(Duration(days: index)),
          habitId: 'habit-body',
        ),
      );
      final store = _FakeStatisticsV3Store(
        _rootState(
          now: now,
          activeHabits: [
            _habit(id: 'habit-body', title: 'Habit Body', familyId: 'body'),
            _habit(id: 'habit-mind', title: 'Habit Mind', familyId: 'mind'),
          ],
          history: _historyWithCompletions(completions),
        ),
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();
      await _scrollToGlobalInsightFooter(tester);

      expect(
        find.textContaining('is leading this period'),
        findsOneWidget,
      );
      expect(find.text('🧩'), findsOneWidget);
    });
  });
}

Widget _app(UserStateStore store) {
  return Provider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StatisticsV3Screen(),
    ),
  );
}

Map<String, dynamic> _rootState({
  required DateTime now,
  required List<Map<String, dynamic>> activeHabits,
  required Map<String, dynamic> history,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'meta': <String, dynamic>{'activeViewDateKey': _dateKey(now)},
      'daily': <String, dynamic>{},
      'history': history,
      'profile': <String, dynamic>{'achievements': <String, dynamic>{}},
      'activeHabits': activeHabits,
    },
  };
}

Map<String, dynamic> _historyWithCheckCompletion(DateTime now, String habitId) {
  final dayKey = _dateKey(now);
  return <String, dynamic>{
    'habitCompletions': <String, dynamic>{
      dayKey: <String, dynamic>{habitId: true},
    },
    'habitCompletionTimes': <String, dynamic>{},
    'habitSkips': <String, dynamic>{},
    'habitCountValues': <String, dynamic>{},
  };
}

Map<String, dynamic> _habit({
  required String id,
  required String title,
  String familyId = 'mind',
}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'name': title,
    'familyId': familyId,
    'type': 'check',
    'doneToday': false,
    'skippedToday': false,
    'progress': 0,
    'target': 1,
    'emoji': '*',
    'schedule': <String, dynamic>{'type': 'daily'},
  };
}

Map<String, dynamic> _historyWithCompletions(List<_CompletionSeed> seeds) {
  final completions = <String, Map<String, dynamic>>{};

  for (final seed in seeds) {
    final dayKey = _dateKey(seed.day);
    final dayCompletions =
        completions.putIfAbsent(dayKey, () => <String, dynamic>{});
    dayCompletions[seed.habitId] = true;
  }

  return <String, dynamic>{
    'habitCompletions': completions,
    'habitCompletionTimes': <String, dynamic>{},
    'habitSkips': <String, dynamic>{},
    'habitCountValues': <String, dynamic>{},
  };
}

class _CompletionSeed {
  _CompletionSeed({
    required this.day,
    required this.habitId,
  });

  final DateTime day;
  final String habitId;
}

Future<void> _scrollToGlobalInsightFooter(WidgetTester tester) async {
  final list = find.byType(ListView).first;
  for (var i = 0; i < 6; i++) {
    await tester.drag(list, const Offset(0, -420));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

String _dateKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

class _FakeStatisticsV3Store implements UserStateStore {
  _FakeStatisticsV3Store(this.state);

  @override
  final Map<String, dynamic>? state;

  @override
  List<Map<String, dynamic>> get activeHabits {
    final userState = state?['userState'];
    if (userState is! Map) return const <Map<String, dynamic>>[];
    final habits = userState['activeHabits'];
    if (habits is! List) return const <Map<String, dynamic>>[];
    return habits
        .whereType<Map>()
        .map(
          (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  @override
  Map<String, HabitStreakSnapshot> get achievementMetricSnapshots =>
      const <String, HabitStreakSnapshot>{};

  @override
  dynamic getActiveHabitById(String id) {
    for (final habit in activeHabits) {
      final habitId = (habit['id'] ?? habit['habitId'] ?? '').toString().trim();
      if (habitId == id) return Map<String, dynamic>.from(habit);
    }
    return null;
  }

  @override
  HabitStreakSnapshot habitStreakSnapshotForHabitId(
    String habitId, {
    DateTime? today,
  }) {
    return HabitStreakSnapshot(
      habitId: habitId,
      currentStreak: 0,
      bestStreak: 0,
      totalCompletedDays: 0,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
