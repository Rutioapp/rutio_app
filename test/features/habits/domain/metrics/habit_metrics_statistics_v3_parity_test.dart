import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_occurrence_evaluator.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';
import 'package:rutio/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_period.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/stores/user_state_store.dart';

final _l10n = AppLocalizationsEn();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Habit metrics parity with Statistics V3', () {
    test('check daily matches Statistics V3 totals for a single habit', () {
      final habit = HabitSnapshot(
        habitId: 'check-1',
        name: 'Check',
        kind: HabitKind.check,
        schedule: HabitSchedule.daily(),
      );
      final evaluator = HabitOccurrenceEvaluator();
      final result = evaluator.evaluate(
        habit: habit,
        date: DateTime(2026, 9, 1),
        completed: true,
        skipped: false,
      );

      final viewData = _buildViewData(
        period: StatisticsV3Period.day,
        now: DateTime(2026, 9, 1),
        activeHabits: [
          _habitMap(
            id: 'check-1',
            title: 'Check',
            schedule: const <String, dynamic>{'type': 'daily'},
            doneToday: true,
            progress: 1,
          ),
        ],
        history: _historyForDay(
          DateTime(2026, 9, 1),
          completions: {'check-1': true},
        ),
      );

      expect(result.scheduled, isTrue);
      expect(result.completed, isTrue);
      expect(viewData.totalDays, 1);
      expect(viewData.completedHabits, 1);
      expect(viewData.consistencyPct, 100);
    });

    test('count daily matches Statistics V3 threshold completion', () {
      final habit = HabitSnapshot(
        habitId: 'count-1',
        name: 'Count',
        kind: HabitKind.count,
        target: 10,
        schedule: HabitSchedule.daily(),
      );
      final evaluator = HabitOccurrenceEvaluator();
      final result = evaluator.evaluate(
        habit: habit,
        date: DateTime(2026, 9, 1),
        completed: false,
        skipped: false,
        progress: 5,
      );

      final viewData = _buildViewData(
        period: StatisticsV3Period.day,
        now: DateTime(2026, 9, 1),
        activeHabits: [
          _habitMap(
            id: 'count-1',
            title: 'Count',
            type: 'count',
            target: 10,
            progress: 5,
            schedule: const <String, dynamic>{'type': 'daily'},
          ),
        ],
        history: _historyForDay(
          DateTime(2026, 9, 1),
          countValues: {'count-1': 5},
        ),
      );

      expect(result.scheduled, isTrue);
      expect(result.completed, isFalse);
      expect(result.isPartialProgress, isTrue);
      expect(viewData.totalDays, 1);
      expect(viewData.completedHabits, 0);
      expect(viewData.consistencyPct, 0);
    });

    test('weekly and once scheduling match Statistics V3 exclusion rules', () {
      final weekHabit = HabitSnapshot(
        habitId: 'weekly-1',
        name: 'Weekly',
        kind: HabitKind.check,
        schedule: HabitSchedule.weekly(weekdays: [DateTime.monday]),
      );
      final onceHabit = HabitSnapshot(
        habitId: 'once-1',
        name: 'Once',
        kind: HabitKind.check,
        schedule: HabitSchedule.once(date: DateTime(2026, 9, 3)),
      );
      final evaluator = HabitOccurrenceEvaluator();

      final weeklyResult = evaluator.evaluate(
        habit: weekHabit,
        date: DateTime(2026, 9, 2),
        completed: true,
        skipped: false,
      );
      final onceResult = evaluator.evaluate(
        habit: onceHabit,
        date: DateTime(2026, 9, 2),
        completed: true,
        skipped: false,
      );

      final viewData = _buildViewData(
        period: StatisticsV3Period.day,
        now: DateTime(2026, 9, 2),
        activeHabits: [
          _habitMap(
            id: 'weekly-1',
            title: 'Weekly',
            schedule: {
              'type': 'weekly',
              'weekdays': [DateTime.monday],
            },
            doneToday: true,
            progress: 1,
          ),
          _habitMap(
            id: 'once-1',
            title: 'Once',
            schedule: {
              'type': 'once',
              'date': '2026-09-03',
            },
            doneToday: true,
            progress: 1,
          ),
        ],
      );

      expect(weeklyResult.scheduled, isFalse);
      expect(onceResult.scheduled, isFalse);
      expect(viewData.totalDays, 0);
      expect(viewData.completedHabits, 0);
      expect(viewData.consistencyPct, 0);
    });

    test('timesPerWeek keeps the weekly quota contract instead of a daily one',
        () {
      final habit = HabitSnapshot(
        habitId: 'tpw-1',
        name: 'Times Per Week',
        kind: HabitKind.check,
        schedule: HabitSchedule.timesPerWeek(timesPerWeek: 3),
        createdAt: DateTime(2026, 9, 1),
      );
      final evaluator = HabitOccurrenceEvaluator();
      final week = WeeklyReportWeek.fromDate(DateTime(2026, 9, 1));
      final quota = evaluator.effectiveScheduledQuota(habit: habit, week: week);

      final viewData = _buildViewData(
        period: StatisticsV3Period.week,
        now: DateTime(2026, 9, 1),
        activeHabits: [
          _habitMap(
            id: 'tpw-1',
            title: 'Times Per Week',
            schedule: {
              'type': 'timesPerWeek',
              'timesPerWeek': 3,
              'weekStartsOn': 1,
            },
            doneToday: true,
            progress: 1,
          ),
        ],
        history: _historyForDay(
          DateTime(2026, 9, 1),
          completions: {'tpw-1': true},
        ),
      );

      expect(quota.scheduledCount, 3);
      expect(viewData.consistencyPct, inInclusiveRange(0, 100));
    });
  });
}

StatisticsV3ViewData _buildViewData({
  required StatisticsV3Period period,
  required DateTime now,
  required List<Map<String, dynamic>> activeHabits,
  Map<String, dynamic> history = const <String, dynamic>{},
}) {
  final store = _FakeStatisticsV3Store(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': 'user-1',
        'meta': <String, dynamic>{
          'activeViewDateKey': _dateKey(now),
        },
        'daily': <String, dynamic>{},
        'history': <String, dynamic>{
          'habitCompletions':
              history['habitCompletions'] ?? <String, dynamic>{},
          'habitCompletionTimes':
              history['habitCompletionTimes'] ?? <String, dynamic>{},
          'habitSkips': history['habitSkips'] ?? <String, dynamic>{},
          'habitCountValues':
              history['habitCountValues'] ?? <String, dynamic>{},
        },
        'activeHabits': activeHabits,
        'progression': <String, dynamic>{},
        'wallet': <String, dynamic>{},
        'familyXp': <String, dynamic>{},
        'profile': <String, dynamic>{},
      },
    },
  );

  return buildStatisticsV3ViewData(
    store: store,
    period: period,
    l10n: _l10n,
    now: now,
  );
}

Map<String, dynamic> _historyForDay(
  DateTime date, {
  Map<String, dynamic>? completions,
  Map<String, dynamic>? countValues,
}) {
  final dayKey = _dateKey(date);
  return <String, dynamic>{
    'habitCompletions': <String, dynamic>{
      dayKey: completions ?? <String, dynamic>{}
    },
    'habitCountValues': <String, dynamic>{
      dayKey: countValues ?? <String, dynamic>{}
    },
    'habitSkips': <String, dynamic>{dayKey: <String, dynamic>{}},
    'habitCompletionTimes': <String, dynamic>{dayKey: <String, dynamic>{}},
  };
}

Map<String, dynamic> _habitMap({
  required String id,
  required String title,
  String type = 'check',
  num target = 1,
  num progress = 0,
  bool doneToday = false,
  Map<String, dynamic>? schedule,
}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'name': title,
    'type': type,
    'target': target,
    'progress': progress,
    'doneToday': doneToday,
    'skippedToday': false,
    'schedule': schedule ?? <String, dynamic>{'type': 'daily'},
    'archived': false,
  };
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _FakeStatisticsV3Store implements UserStateStore {
  _FakeStatisticsV3Store(this._state);

  final Map<String, dynamic>? _state;

  @override
  Map<String, dynamic>? get state => _state;

  @override
  List<Map<String, dynamic>> get activeHabits {
    final userState = _state?['userState'];
    if (userState is! Map) return const <Map<String, dynamic>>[];
    final habits = userState['activeHabits'];
    if (habits is! List) return const <Map<String, dynamic>>[];
    return habits
        .whereType<Map>()
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
