import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/habit_detail/habit_detail_screen.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats_tab.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;

  group('HabitStatsTab S9.1', () {
    testWidgets('statsOnly renders check last 7 indicators', (tester) async {
      final now = DateTime.now();
      final store = _FakeStore(
        _rootState(
          habits: [_checkHabit(id: 'h-check')],
          completions: {
            _dateKey(now.subtract(const Duration(days: 1))): {'h-check': true},
            _dateKey(now.subtract(const Duration(days: 2))): {'h-check': true},
          },
          skips: const {},
          counts: const {},
          completionTimes: const {},
        ),
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _checkHabit(id: 'h-check'),
            familyColor: Colors.green,
            mode: HabitDetailScreenMode.statsOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.habitStatsTabLastDaysTitle(7)), findsOneWidget);
      expect(find.byKey(const ValueKey('habit-stats-last7-check')),
          findsOneWidget);
      expect(find.byType(HabitStatsTab), findsOneWidget);
    });

    testWidgets(
        'count habit renders weekly bar section and count metric labels',
        (tester) async {
      final now = DateTime.now();
      final store = _FakeStore(
        _rootState(
          habits: [_countHabit(id: 'h-count', target: 2, unit: 'l')],
          completions: const {},
          skips: const {},
          counts: {
            _dateKey(now.subtract(const Duration(days: 6))): {'h-count': 2.0},
            _dateKey(now.subtract(const Duration(days: 5))): {'h-count': 2.1},
            _dateKey(now.subtract(const Duration(days: 4))): {'h-count': 1.9},
          },
          completionTimes: const {},
        ),
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _countHabit(id: 'h-count', target: 2, unit: 'l'),
            familyColor: Colors.green,
            mode: HabitDetailScreenMode.statsOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.byKey(const ValueKey('habit-stats-last7-count')),
          findsOneWidget);
      expect(find.text(l10n.habitStatsIndividualVolume), findsOneWidget);
      expect(find.text(l10n.habitStatsIndividualDailyAverage), findsOneWidget);
    });

    testWidgets('timesPerWeek check shows weekly completed over target',
        (tester) async {
      final now = DateTime.now();
      final store = _FakeStore(
        _rootState(
          habits: [_timesPerWeekHabit(id: 'h-tpw', target: 3)],
          completions: {
            _dateKey(now.subtract(const Duration(days: 1))): {'h-tpw': true},
            _dateKey(now.subtract(const Duration(days: 3))): {'h-tpw': true},
          },
          skips: const {},
          counts: const {},
          completionTimes: const {},
        ),
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _timesPerWeekHabit(id: 'h-tpw', target: 3),
            familyColor: Colors.green,
            mode: HabitDetailScreenMode.statsOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ratioFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'^\d+/3$').hasMatch(widget.data!),
      );
      expect(ratioFinder, findsWidgets);
    });

    testWidgets('does not crash with missing optional data', (tester) async {
      final store = _FakeStore(
        _rootState(
          habits: const [
            <String, dynamic>{
              'id': 'h-min',
              'title': 'Minimal',
              'type': 'check'
            }
          ],
          completions: const {},
          skips: const {},
          counts: const {},
          completionTimes: const {},
        ),
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: const HabitStatsTab(
            habit: {'id': 'h-min', 'title': 'Minimal', 'type': 'check'},
            familyColor: Colors.blue,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimal'), findsOneWidget);
    });

    testWidgets('editOnly mode remains unaffected', (tester) async {
      final store = _FakeStore(
        _rootState(
          habits: [_checkHabit(id: 'h-edit')],
          completions: const {},
          skips: const {},
          counts: const {},
          completionTimes: const {},
        ),
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _checkHabit(id: 'h-edit'),
            familyColor: Colors.green,
            mode: HabitDetailScreenMode.editOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsTab), findsNothing);
    });
  });
}

Widget _app({
  required UserStateStore store,
  required Widget child,
}) {
  return Provider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(430, 932),
          textScaler: TextScaler.linear(0.45),
        ),
        child: child,
      ),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  final context = tester.element(find.byType(HabitDetailScreen).first);
  return context.l10n;
}

Map<String, dynamic> _rootState({
  required List<Map<String, dynamic>> habits,
  required Map<String, dynamic> completions,
  required Map<String, dynamic> skips,
  required Map<String, dynamic> counts,
  required Map<String, dynamic> completionTimes,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'meta': <String, dynamic>{
        'activeViewDateKey': _dateKey(DateTime.now()),
      },
      'daily': <String, dynamic>{},
      'history': <String, dynamic>{
        'habitCompletions': completions,
        'habitCompletionTimes': completionTimes,
        'habitSkips': skips,
        'habitCountValues': counts,
      },
      'activeHabits': habits,
    },
  };
}

Map<String, dynamic> _checkHabit({required String id}) {
  return <String, dynamic>{
    'id': id,
    'title': 'Meditar',
    'familyId': 'spirit',
    'type': 'check',
    'target': 1,
    'schedule': <String, dynamic>{'type': 'daily'},
  };
}

Map<String, dynamic> _timesPerWeekHabit({
  required String id,
  required int target,
}) {
  return <String, dynamic>{
    'id': id,
    'title': 'Rutina',
    'familyId': 'discipline',
    'type': 'check',
    'target': 1,
    'schedule': <String, dynamic>{
      'type': 'timesPerWeek',
      'timesPerWeek': target,
      'weekStartsOn': DateTime.monday,
    },
  };
}

Map<String, dynamic> _countHabit({
  required String id,
  required num target,
  required String unit,
}) {
  return <String, dynamic>{
    'id': id,
    'title': 'Agua',
    'familyId': 'body',
    'type': 'count',
    'target': target,
    'unit': unit,
    'schedule': <String, dynamic>{'type': 'daily'},
  };
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _FakeStore implements UserStateStore {
  _FakeStore(this.state);

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
      final habitId = (habit['id'] ?? habit['habitId'] ?? '').toString();
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
