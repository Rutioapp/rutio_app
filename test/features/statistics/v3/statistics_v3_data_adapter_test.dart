import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_period.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/stores/user_state_store.dart';

final AppLocalizationsEn _l10n = AppLocalizationsEn();
final DateTime _now = DateTime.now();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = _l10n;
  final now = _now;

  group('buildStatisticsV3ViewData', () {
    group('day consistency', () {
      test('uses completed expected habits over total expected active habits', () async {
        final result = await _buildDayViewData(
          now: now,
          activeHabits: _buildDailyHabits(
            total: 19,
            completed: 19,
          ),
        );

        expect(result.completedHabits, 19);
        expect(result.totalDays, 19);
        expect(result.consistencyPct, 100);
      });

      test('drops when active habits increase without more completions', () async {
        final result = await _buildDayViewData(
          now: now,
          activeHabits: _buildDailyHabits(
            total: 19,
            completed: 18,
          ),
        );

        expect(result.completedHabits, 18);
        expect(result.totalDays, 19);
        expect(result.consistencyPct, 95);
      });

      test('drops further for 19 completed out of 21 active habits', () async {
        final result = await _buildDayViewData(
          now: now,
          activeHabits: _buildDailyHabits(
            total: 21,
            completed: 19,
          ),
        );

        expect(result.completedHabits, 19);
        expect(result.totalDays, 21);
        expect(result.consistencyPct, 90);
      });

      test('handles zero active habits safely', () async {
        final result = await _buildDayViewData(
          now: now,
          activeHabits: const <Map<String, dynamic>>[],
        );

        expect(result.completedHabits, 0);
        expect(result.totalDays, 0);
        expect(result.consistencyPct, 0);
        expect(result.highlightedHabits, isEmpty);
        expect(result.families, isEmpty);
      });
    });

    group('count habits', () {
      test('count below target does not count as completed', () async {
        final habit = _habit(
          id: 'count-a',
          title: 'Count A',
          type: 'count',
          target: 5,
          progress: 4,
          doneToday: false,
        );

        final result = await _buildDayViewData(
          now: now,
          activeHabits: [habit],
          history: _historyForDay(
            now,
            countValues: {
              'count-a': 4,
            },
          ),
        );

        expect(result.completedHabits, 0);
        expect(result.consistencyPct, 0);
        expect(result.highlightedHabits, isEmpty);
      });

      test('count equal to target counts as completed', () async {
        final habit = _habit(
          id: 'count-b',
          title: 'Count B',
          type: 'count',
          target: 5,
          progress: 5,
          doneToday: true,
        );

        final result = await _buildDayViewData(
          now: now,
          activeHabits: [habit],
          history: _historyForDay(
            now,
            countValues: {
              'count-b': 5,
            },
          ),
        );

        expect(result.completedHabits, 1);
        expect(result.totalDays, 1);
        expect(result.consistencyPct, 100);
        expect(result.highlightedHabits.single.completedCount, 1);
      });

      test('count above target counts as completed', () async {
        final habit = _habit(
          id: 'count-c',
          title: 'Count C',
          type: 'count',
          target: 5,
          progress: 6,
          doneToday: true,
        );

        final result = await _buildDayViewData(
          now: now,
          activeHabits: [habit],
          history: _historyForDay(
            now,
            countValues: {
              'count-c': 6,
            },
          ),
        );

        expect(result.completedHabits, 1);
        expect(result.totalDays, 1);
        expect(result.consistencyPct, 100);
        expect(result.highlightedHabits.single.completedCount, 1);
      });
    });

    group('weekly activity', () {
      test('returns 7 day entries for the current week', () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(id: 'habit-a', title: 'Habit A'),
          ],
        );

        expect(result.weeklyActivity, hasLength(7));
        expect(result.weeklyActivity.first.date.weekday, DateTime.monday);
        expect(result.weeklyActivity.last.date.weekday, DateTime.sunday);
      });

      test('calculates completed/expected/percentage correctly for a past day', () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final monday = weekNow.subtract(
          Duration(days: weekNow.weekday - DateTime.monday),
        );
        final mondayKey = _dateKey(monday);

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
              id: 'habit-weekly-monday',
              title: 'Monday Habit',
              schedule: {
                'type': 'weekly',
                'weekdays': [DateTime.monday],
              },
            ),
          ],
          history: {
            'habitCompletions': {
              mondayKey: {'habit-weekly-monday': true},
            },
            'habitCompletionTimes': {
              mondayKey: {
                'habit-weekly-monday': DateTime(
                  monday.year,
                  monday.month,
                  monday.day,
                  8,
                ).millisecondsSinceEpoch,
              },
            },
            'habitSkips': <String, dynamic>{},
            'habitCountValues': <String, dynamic>{},
          },
        );

        final mondayItem = result.weeklyActivity.first;
        expect(mondayItem.expectedCount, 1);
        expect(mondayItem.completedCount, 1);
        expect(mondayItem.percentage, 100);
      });

      test('unticking one habit reduces today percentage', () async {
        final weekNow = DateTime(2026, 5, 6, 10);

        final allDone = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
            _habit(id: 'habit-b', title: 'Habit B', doneToday: true, progress: 1),
          ],
        );

        final oneUnticked = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
            _habit(id: 'habit-b', title: 'Habit B', doneToday: false, progress: 0),
          ],
        );

        final todayAllDone = allDone.weeklyActivity.firstWhere((item) => item.isToday);
        final todayUnticked =
            oneUnticked.weeklyActivity.firstWhere((item) => item.isToday);

        expect(todayAllDone.percentage, 100);
        expect(todayUnticked.percentage, 50);
      });

      test('adding expected active habits without completion reduces today percentage', () async {
        final weekNow = DateTime(2026, 5, 6, 10);

        final base = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
              id: 'habit-existing',
              title: 'Existing Habit',
              doneToday: true,
              progress: 1,
            ),
          ],
        );

        final withNewUncompleted = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
              id: 'habit-existing',
              title: 'Existing Habit',
              doneToday: true,
              progress: 1,
            ),
            _habit(
              id: 'habit-new',
              title: 'New Habit',
              doneToday: false,
              progress: 0,
            ),
          ],
        );

        final baseToday = base.weeklyActivity.firstWhere((item) => item.isToday);
        final newToday =
            withNewUncompleted.weeklyActivity.firstWhere((item) => item.isToday);

        expect(baseToday.percentage, 100);
        expect(newToday.percentage, 50);
      });

      test('count habits below target are not completed in weekly activity', () async {
        final weekNow = DateTime(2026, 5, 6, 10);

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
              id: 'count-weekly',
              title: 'Count Weekly',
              type: 'count',
              target: 5,
              progress: 4,
              doneToday: false,
            ),
          ],
          history: _historyForDay(
            weekNow,
            countValues: {'count-weekly': 4},
          ),
        );

        final todayItem = result.weeklyActivity.firstWhere((item) => item.isToday);
        expect(todayItem.expectedCount, 1);
        expect(todayItem.completedCount, 0);
        expect(todayItem.percentage, 0);
      });

      test('future days are marked as future and rendered neutral data', () async {
        final weekNow = DateTime(2026, 5, 6, 10);

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
          ],
        );

        final futureDays = result.weeklyActivity.where((item) => item.isFuture).toList();
        expect(futureDays, hasLength(4));
        for (final item in futureDays) {
          expect(item.completedCount, 0);
          expect(item.expectedCount, 0);
          expect(item.percentage, 0);
        }
      });
    });

    group('highlighted habits', () {
      test('returns the top 3 habits in descending completion order', () async {
        final result = await _buildMonthViewData(
          now: now,
          activeHabits: [
            _habit(id: 'habit-alpha', title: 'Alpha', emoji: 'A'),
            _habit(id: 'habit-beta', title: 'Beta', emoji: 'B'),
            _habit(id: 'habit-gamma', title: 'Gamma', emoji: 'G'),
            _habit(id: 'habit-delta', title: 'Delta', emoji: 'D'),
          ],
          history: _historyForMonth(
            now,
            completionsByHabit: {
              'habit-alpha': _days([1, 2, 3, 4]),
              'habit-beta': _days([1, 2, 3, 4]),
              'habit-gamma': _days([1, 2, 3]),
              'habit-delta': _days([1]),
            },
          ),
        );

        expect(result.highlightedHabits, hasLength(3));
        expect(
          result.highlightedHabits.map((item) => item.name).toList(),
          ['Alpha', 'Beta', 'Gamma'],
        );
        expect(
          result.highlightedHabits.map((item) => item.completedCount).toList(),
          [4, 4, 3],
        );
      });

      test('returns only the available habits when fewer than 3 have completions', () async {
        final result = await _buildMonthViewData(
          now: now,
          activeHabits: [
            _habit(id: 'habit-one', title: 'One', emoji: '1'),
            _habit(id: 'habit-two', title: 'Two', emoji: '2'),
            _habit(id: 'habit-three', title: 'Three', emoji: '3'),
          ],
          history: _historyForMonth(
            now,
            completionsByHabit: {
              'habit-one': _days([1, 2, 3]),
              'habit-two': _days([1]),
              'habit-three': const <int>[],
            },
          ),
        );

        expect(result.highlightedHabits, hasLength(2));
        expect(
          result.highlightedHabits.map((item) => item.name).toList(),
          ['One', 'Two'],
        );
        expect(
          result.highlightedHabits.map((item) => item.completedCount).toList(),
          [3, 1],
        );
      });
    });

    group('families', () {
      test('aggregates completions by family and returns up to 4 entries', () async {
        final result = await _buildMonthViewData(
          now: now,
          activeHabits: [
            _habit(
              id: 'mind-1',
              title: 'Mind 1',
              familyId: 'mind',
            ),
            _habit(
              id: 'mind-2',
              title: 'Mind 2',
              familyId: 'mind',
            ),
            _habit(
              id: 'body-1',
              title: 'Body 1',
              familyId: 'body',
            ),
            _habit(
              id: 'no-family-1',
              title: 'No Family 1',
            ),
            _habit(
              id: 'social-1',
              title: 'Social 1',
              familyId: 'social',
            ),
          ],
          history: _historyForMonth(
            now,
            completionsByHabit: {
              'mind-1': _days([1, 2, 3]),
              'mind-2': _days([1, 2]),
              'body-1': _days([1, 2, 3, 4]),
              'no-family-1': _days([1, 2, 3]),
              'social-1': _days([1, 2]),
            },
          ),
        );

        expect(result.families, hasLength(4));
        expect(
          result.families.map((item) => item.completedCount).toList(),
          [5, 4, 3, 2],
        );
        expect(
          result.families.map((item) => item.name).toList(),
          contains(l10n.statisticsV3NoFamily),
        );
        expect(
          result.families
              .firstWhere((item) => item.name == l10n.statisticsV3NoFamily)
              .completedCount,
          3,
        );
      });

      test('returns an empty safe state when there is no data', () async {
        final result = await _buildMonthViewData(
          now: now,
          activeHabits: const <Map<String, dynamic>>[],
          history: _historyForMonth(
            now,
            completionsByHabit: {
              'deleted-1': _days([1, 2, 3]),
            },
          ),
        );

        expect(result.families, isEmpty);
        expect(result.highlightedHabits, isEmpty);
        expect(result.consistencyPct, 0);
      });
    });

    group('empty and partial data', () {
      test('active habits with no completions stays safe', () async {
        final result = await _buildDayViewData(
          now: now,
          activeHabits: [
            _habit(id: 'habit-a', title: 'Habit A'),
            _habit(id: 'habit-b', title: 'Habit B'),
          ],
        );

        expect(result.completedHabits, 0);
        expect(result.consistencyPct, 0);
        expect(result.highlightedHabits, isEmpty);
        expect(result.families, isEmpty);
      });

      test('unknown or deleted habit ids in completions do not crash', () async {
        final result = await _buildMonthViewData(
          now: now,
          activeHabits: [
            _habit(id: 'habit-a', title: 'Habit A'),
          ],
          history: _historyForMonth(
            now,
            completionsByHabit: {
              'deleted-habit': _days([1, 2, 3]),
            },
            countValuesByHabit: {
              'deleted-habit': _days([1]),
            },
          ),
        );

        expect(result.completedHabits, 0);
        expect(result.highlightedHabits, isEmpty);
        expect(result.families, isEmpty);
        expect(result.consistencyPct, 0);
      });
    });
  });
}

Future<StatisticsV3ViewData> _buildDayViewData({
  required DateTime now,
  required List<Map<String, dynamic>> activeHabits,
  Map<String, dynamic>? history,
}) async {
  return _buildViewData(
    period: StatisticsV3Period.day,
    now: now,
    activeHabits: activeHabits,
    history: history,
  );
}

Future<StatisticsV3ViewData> _buildWeekViewData({
  required DateTime now,
  required List<Map<String, dynamic>> activeHabits,
  Map<String, dynamic>? history,
}) async {
  return _buildViewData(
    period: StatisticsV3Period.week,
    now: now,
    activeHabits: activeHabits,
    history: history,
  );
}

Future<StatisticsV3ViewData> _buildMonthViewData({
  required DateTime now,
  required List<Map<String, dynamic>> activeHabits,
  Map<String, dynamic>? history,
}) async {
  return _buildViewData(
    period: StatisticsV3Period.month,
    now: now,
    activeHabits: activeHabits,
    history: history,
  );
}

Future<StatisticsV3ViewData> _buildViewData({
  required StatisticsV3Period period,
  required DateTime now,
  required List<Map<String, dynamic>> activeHabits,
  Map<String, dynamic>? history,
}) async {
  final root = _rootState(
    activeHabits: activeHabits,
    history: history ?? <String, dynamic>{},
    activeViewDateKey: _dateKey(now),
  );
  final store = _FakeStatisticsV3Store(root);

  return buildStatisticsV3ViewData(
    store: store,
    period: period,
    l10n: _l10n,
    now: now,
  );
}

Map<String, dynamic> _rootState({
  required List<Map<String, dynamic>> activeHabits,
  required Map<String, dynamic> history,
  required String activeViewDateKey,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'test-user',
      'meta': <String, dynamic>{
        'activeViewDateKey': activeViewDateKey,
      },
      'daily': <String, dynamic>{},
      'history': <String, dynamic>{
        'habitCompletions': history['habitCompletions'] ?? <String, dynamic>{},
        'habitCompletionTimes':
            history['habitCompletionTimes'] ?? <String, dynamic>{},
        'habitSkips': history['habitSkips'] ?? <String, dynamic>{},
        'habitCountValues': history['habitCountValues'] ?? <String, dynamic>{},
      },
      'activeHabits': activeHabits,
      'progression': <String, dynamic>{},
      'wallet': <String, dynamic>{},
      'familyXp': <String, dynamic>{},
      'profile': <String, dynamic>{},
    },
  };
}

Map<String, dynamic> _historyForDay(
  DateTime date, {
  Map<String, dynamic>? completions,
  Map<String, dynamic>? countValues,
  Map<String, dynamic>? skips,
  Map<String, dynamic>? completionTimes,
}) {
  final dayKey = _dateKey(date);
  return <String, dynamic>{
    'habitCompletions': <String, dynamic>{
      dayKey: completions ?? <String, dynamic>{},
    },
    'habitCompletionTimes': <String, dynamic>{
      dayKey: completionTimes ?? <String, dynamic>{},
    },
    'habitSkips': <String, dynamic>{
      dayKey: skips ?? <String, dynamic>{},
    },
    'habitCountValues': <String, dynamic>{
      dayKey: countValues ?? <String, dynamic>{},
    },
  };
}

Map<String, dynamic> _historyForMonth(
  DateTime now, {
  Map<String, List<int>> completionsByHabit = const <String, List<int>>{},
  Map<String, List<int>> countValuesByHabit = const <String, List<int>>{},
}) {
  final completions = <String, dynamic>{};
  final countValues = <String, dynamic>{};
  final skips = <String, dynamic>{};
  final completionTimes = <String, dynamic>{};

  for (final habitEntry in completionsByHabit.entries) {
    for (final day in habitEntry.value) {
      final dayKey = _dateKey(DateTime(now.year, now.month, day));
      final dayMap = _ensureDayMap(completions, dayKey);
      dayMap[habitEntry.key] = true;

      final timeMap = _ensureDayMap(completionTimes, dayKey);
      timeMap[habitEntry.key] = DateTime(
        now.year,
        now.month,
        day,
        8,
      ).millisecondsSinceEpoch;
    }
  }

  for (final habitEntry in countValuesByHabit.entries) {
    for (final day in habitEntry.value) {
      final dayKey = _dateKey(DateTime(now.year, now.month, day));
      final dayMap = _ensureDayMap(countValues, dayKey);
      dayMap[habitEntry.key] = 1;
    }
  }

  return <String, dynamic>{
    'habitCompletions': completions,
    'habitCompletionTimes': completionTimes,
    'habitSkips': skips,
    'habitCountValues': countValues,
  };
}

Map<String, dynamic> _ensureDayMap(
  Map<String, dynamic> root,
  String dayKey,
) {
  final existing = root[dayKey];
  if (existing is Map<String, dynamic>) return existing;
  final next = <String, dynamic>{};
  root[dayKey] = next;
  return next;
}

List<int> _days(List<int> dayNumbers) => dayNumbers;

List<Map<String, dynamic>> _buildDailyHabits({
  required int total,
  required int completed,
}) {
  return List<Map<String, dynamic>>.generate(total, (index) {
    final habitId = 'habit-${index + 1}';
    final isCompleted = index < completed;
    return _habit(
      id: habitId,
      title: 'Habit ${index + 1}',
      doneToday: isCompleted,
      progress: isCompleted ? 1 : 0,
    );
  }, growable: false);
}

Map<String, dynamic> _habit({
  required String id,
  required String title,
  String type = 'check',
  num target = 1,
  num progress = 0,
  bool doneToday = false,
  String? familyId,
  String emoji = '✨',
  Map<String, dynamic>? schedule,
}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'name': title,
    'emoji': emoji,
    'type': type,
    'target': target,
    'progress': progress,
    'doneToday': doneToday,
    'skippedToday': false,
    if (familyId != null) 'familyId': familyId,
    'schedule':
        schedule ??
        <String, dynamic>{
          'type': 'daily',
        },
  };
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
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
        .map((entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
