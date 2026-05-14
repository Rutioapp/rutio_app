import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_count_last7_days_chart.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_last7_days_card.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats_tab.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;

  group('HabitStatsTab', () {
    testWidgets('check habit shows last 7 days, metrics and weekly comparison',
        (tester) async {
      final now = DateTime.now();
      final habit = _habit(type: 'check');
      final store = _FakeStore(
        _rootState(
          habit: habit,
          completions: {
            _dateKey(now.subtract(const Duration(days: 4))): true,
            _dateKey(now.subtract(const Duration(days: 3))): true,
            _dateKey(now.subtract(const Duration(days: 2))): true,
          },
          completionTimes: {
            _dateKey(now.subtract(const Duration(days: 4))): DateTime(
              now.year,
              now.month,
              now.day,
              7,
            ).millisecondsSinceEpoch,
          },
        ),
        streakByHabitId: const {'habit-1': 4},
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitStatsTab(
            habit: habit,
            familyColor: Colors.green,
            showHeaderControls: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.habitStatsTabLastDaysTitle(7)), findsOneWidget);
      expect(find.byType(HabitStatsLast7DaysCard), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_check_last7_days')), findsOneWidget);
      expect(find.byType(HabitStatsCountLast7DaysChart), findsNothing);
      expect(find.text(l10n.habitConfigGoalSection), findsOneWidget);
      expect(find.text(l10n.habitStatsMetricCompleted), findsOneWidget);
      expect(find.text(l10n.habitStatsMetricConsistency), findsOneWidget);
      expect(find.text(l10n.habitStatsWeeklyComparisonTitle), findsOneWidget);
      expect(find.text(l10n.habitStatsInsightLabel), findsOneWidget);
      expect(find.text(l10n.habitStatsInsightEveryRepetition), findsOneWidget);
    });

    testWidgets('timesPerWeek check habit shows weekly completed/target',
        (tester) async {
      final now = DateTime.now();
      final habit = _habit(
        type: 'check',
        schedule: const {'type': 'timesPerWeek', 'timesPerWeek': 3, 'weekStartsOn': 1},
      );
      final store = _FakeStore(
        _rootState(
          habit: habit,
          completions: {
            _dateKey(now.subtract(const Duration(days: 1))): true,
            _dateKey(now): true,
          },
        ),
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitStatsTab(
            habit: habit,
            familyColor: Colors.green,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets('count habit renders last 7 days chart',
        (tester) async {
      final now = DateTime.now();
      final habit = _habit(
        type: 'count',
        schedule: const {'type': 'daily'},
        target: 2,
        unit: 'L',
      );
      final store = _FakeStore(
        _rootState(
          habit: habit,
          countValues: {
            _dateKey(now.subtract(const Duration(days: 2))): 4.1,
            _dateKey(now.subtract(const Duration(days: 1))): 3.7,
            _dateKey(now): 5.0,
          },
        ),
      );
      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitStatsTab(
            habit: habit,
            familyColor: Colors.green,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.habitStatsTabLastDaysTitle(7)), findsOneWidget);
      expect(find.byType(HabitStatsCountLast7DaysChart), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_count_last7_chart')), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_count_metric_grid')), findsOneWidget);
      expect(find.text(l10n.habitStatsCountObjectiveTitle), findsOneWidget);
      expect(find.text(l10n.habitStatsCountVolumeTitle), findsOneWidget);
      expect(find.text(l10n.habitStatsCountDailyAverage), findsOneWidget);
      expect(find.text(l10n.habitStatsMetricCompletion), findsOneWidget);
      expect(find.text(_countPerDayLabel(l10n)), findsOneWidget);
      expect(find.text(_countAverageLabel(l10n)), findsOneWidget);
      expect(find.text(_countOfGoalLabel(l10n)), findsOneWidget);
      expect(find.text('12.8 L'), findsWidgets);
      expect(find.text('91%'), findsOneWidget);
      expect(find.text(l10n.habitStatsWeeklyComparisonTitle), findsNothing);
      expect(find.text(l10n.habitStatsCountBestDayTitle), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_count_best_day_card')), findsOneWidget);
      expect(
        find.text(
          '${_capitalizedWeekday(l10n, now.weekday)} ${String.fromCharCode(0x00B7)} 5 L',
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.habitStatsCountInsightCloseToGoal), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('count habit chart does not crash with empty unit', (tester) async {
      final habit = _habit(
        type: 'count',
        schedule: const {'type': 'daily'},
        target: 3,
        unit: '',
      );
      final store = _FakeStore(_rootState(habit: habit));

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitStatsTab(
            habit: habit,
            familyColor: Colors.green,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsCountLast7DaysChart), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_count_metric_grid')), findsOneWidget);
      expect(find.text(_l10n(tester).habitStatsCountBestDayNoDataYet), findsOneWidget);
      expect(
        find.text(_l10n(tester).habitStatsCountInsightAdjustPace),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('count habit chart does not crash with zero target', (tester) async {
      final now = DateTime.now();
      final habit = _habit(
        type: 'count',
        schedule: const {'type': 'daily'},
        target: 0,
        unit: 'times',
      );
      final store = _FakeStore(
        _rootState(
          habit: habit,
          countValues: {
            _dateKey(now.subtract(const Duration(days: 1))): 5,
            _dateKey(now): 7,
          },
        ),
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitStatsTab(
            habit: habit,
            familyColor: Colors.green,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsCountLast7DaysChart), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_count_metric_grid')), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('check habit is not routed to any legacy widget', (tester) async {
      final habit = _habit(type: 'check');
      final store = _FakeStore(_rootState(habit: habit));

      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitStatsTab(
            habit: habit,
            familyColor: Colors.green,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsLast7DaysCard), findsOneWidget);
      expect(find.byType(HabitStatsCountLast7DaysChart), findsNothing);
      expect(tester.takeException(), isNull);
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
        data: const MediaQueryData(size: Size(430, 932)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  final context = tester.element(find.byType(HabitStatsTab));
  return context.l10n;
}

Map<String, dynamic> _rootState({
  required Map<String, dynamic> habit,
  Map<String, bool> completions = const {},
  Map<String, num> countValues = const {},
  Map<String, int> completionTimes = const {},
  Map<String, bool> skips = const {},
}) {
  final completionsByDay = <String, dynamic>{};
  final countValuesByDay = <String, dynamic>{};
  final completionTimesByDay = <String, dynamic>{};
  final skipsByDay = <String, dynamic>{};
  for (final entry in completions.entries) {
    completionsByDay[entry.key] = {'habit-1': entry.value};
  }
  for (final entry in countValues.entries) {
    countValuesByDay[entry.key] = {'habit-1': entry.value};
  }
  for (final entry in completionTimes.entries) {
    completionTimesByDay[entry.key] = {'habit-1': entry.value};
  }
  for (final entry in skips.entries) {
    skipsByDay[entry.key] = {'habit-1': entry.value};
  }
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'history': <String, dynamic>{
        'habitCompletions': completionsByDay,
        'habitCountValues': countValuesByDay,
        'habitCompletionTimes': completionTimesByDay,
        'habitSkips': skipsByDay,
      },
      'activeHabits': [habit],
    },
  };
}

Map<String, dynamic> _habit({
  String type = 'check',
  int target = 1,
  String unit = 'times',
  Map<String, dynamic> schedule = const {'type': 'daily'},
}) {
  return <String, dynamic>{
    'id': 'habit-1',
    'title': 'Meditar',
    'familyId': 'mind',
    'type': type,
    'target': target,
    'unit': unit,
    'schedule': schedule,
  };
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _FakeStore implements UserStateStore {
  _FakeStore(
    this.state, {
    this.streakByHabitId = const <String, int>{},
  });

  @override
  final Map<String, dynamic>? state;

  final Map<String, int> streakByHabitId;

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
  HabitStreakSnapshot habitStreakSnapshotForHabitId(
    String habitId, {
    DateTime? today,
  }) {
    final streak = streakByHabitId[habitId] ?? 0;
    return HabitStreakSnapshot(
      habitId: habitId,
      currentStreak: streak,
      bestStreak: streak,
      totalCompletedDays: streak,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _countPerDayLabel(AppLocalizations l10n) {
  return l10n.localeName.startsWith('es') ? 'Por dia' : 'Per day';
}

String _countAverageLabel(AppLocalizations l10n) {
  return l10n.localeName.startsWith('es') ? 'Promedio' : 'Average';
}

String _countOfGoalLabel(AppLocalizations l10n) {
  return l10n.localeName.startsWith('es') ? 'Del objetivo' : 'Of goal';
}

String _capitalizedWeekday(AppLocalizations l10n, int weekday) {
  final raw = l10n.weekdayFull(weekday);
  if (raw.isEmpty) return raw;
  return '${raw[0].toUpperCase()}${raw.substring(1)}';
}
