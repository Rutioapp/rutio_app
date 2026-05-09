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
      test('uses completed expected habits over total expected active habits',
          () async {
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

      test('drops when active habits increase without more completions',
          () async {
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

      test(
          'excludes skipped scheduled habits from denominator (10 scheduled, 8 completed, 2 skipped)',
          () async {
        final habits = List<Map<String, dynamic>>.generate(10, (index) {
          final habit = _habit(
            id: 'habit-${index + 1}',
            title: 'Habit ${index + 1}',
            doneToday: index < 8,
            progress: index < 8 ? 1 : 0,
          );
          if (index >= 8) {
            habit['skippedToday'] = true;
          }
          return habit;
        }, growable: false);

        final result = await _buildDayViewData(
          now: now,
          activeHabits: habits,
          history: _historyForDay(
            now,
            completions: <String, dynamic>{
              for (var index = 0; index < 8; index++) 'habit-${index + 1}': true,
              'habit-9': true,
              'habit-10': true,
            },
            skips: <String, dynamic>{
              'habit-9': true,
              'habit-10': true,
            },
          ),
        );

        expect(result.totalDays, 8);
        expect(result.completedHabits, 8);
        expect(result.consistencyPct, 100);
      });

      test('skipped habit with stale done=true does not count as completed',
          () async {
        final skippedHabit = _habit(
          id: 'skipped-check',
          title: 'Skipped Check',
          doneToday: true,
          progress: 1,
        )..['skippedToday'] = true;

        final result = await _buildDayViewData(
          now: now,
          activeHabits: [skippedHabit],
          history: _historyForDay(
            now,
            completions: {'skipped-check': true},
            skips: {'skipped-check': true},
          ),
        );

        expect(result.totalDays, 0);
        expect(result.completedHabits, 0);
        expect(result.consistencyPct, 0);
      });

      test('unscheduled habits remain excluded from expected set', () async {
        final tomorrow = now.add(const Duration(days: 1));
        final result = await _buildDayViewData(
          now: now,
          activeHabits: [
            _habit(
              id: 'habit-once-tomorrow',
              title: 'Once Tomorrow',
              doneToday: true,
              progress: 1,
              schedule: <String, dynamic>{
                'type': 'once',
                'date': _dateKey(tomorrow),
              },
            ),
          ],
        );

        expect(result.totalDays, 0);
        expect(result.completedHabits, 0);
        expect(result.consistencyPct, 0);
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

      test('skipped count habit with count >= target does not count completed',
          () async {
        final skippedCountHabit = _habit(
          id: 'count-skipped',
          title: 'Count Skipped',
          type: 'count',
          target: 5,
          progress: 6,
          doneToday: true,
        )..['skippedToday'] = true;

        final result = await _buildDayViewData(
          now: now,
          activeHabits: [skippedCountHabit],
          history: _historyForDay(
            now,
            countValues: {'count-skipped': 6},
            skips: {'count-skipped': true},
          ),
        );

        expect(result.totalDays, 0);
        expect(result.completedHabits, 0);
        expect(result.consistencyPct, 0);
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

      test('calculates completed/expected/percentage correctly for a past day',
          () async {
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
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
            _habit(
                id: 'habit-b', title: 'Habit B', doneToday: true, progress: 1),
          ],
        );

        final oneUnticked = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
            _habit(
                id: 'habit-b', title: 'Habit B', doneToday: false, progress: 0),
          ],
        );

        final todayAllDone =
            allDone.weeklyActivity.firstWhere((item) => item.isToday);
        final todayUnticked =
            oneUnticked.weeklyActivity.firstWhere((item) => item.isToday);

        expect(todayAllDone.percentage, 100);
        expect(todayUnticked.percentage, 50);
      });

      test('excluded skips reduce expected count for that day', () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final monday = weekNow.subtract(
          Duration(days: weekNow.weekday - DateTime.monday),
        );
        final mondayKey = _dateKey(monday);

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
              id: 'habit-weekly-complete',
              title: 'Weekly Complete',
              schedule: {
                'type': 'weekly',
                'weekdays': [DateTime.monday],
              },
            ),
            _habit(
              id: 'habit-weekly-skipped',
              title: 'Weekly Skipped',
              schedule: {
                'type': 'weekly',
                'weekdays': [DateTime.monday],
              },
            ),
            _habit(
              id: 'habit-weekly-pending',
              title: 'Weekly Pending',
              schedule: {
                'type': 'weekly',
                'weekdays': [DateTime.monday],
              },
            ),
          ],
          history: {
            'habitCompletions': {
              mondayKey: {
                'habit-weekly-complete': true,
                'habit-weekly-skipped': true,
              },
            },
            'habitCompletionTimes': {
              mondayKey: {
                'habit-weekly-complete':
                    DateTime(2026, 5, 5, 8).millisecondsSinceEpoch,
                'habit-weekly-skipped':
                    DateTime(2026, 5, 5, 9).millisecondsSinceEpoch,
              },
            },
            'habitSkips': {
              mondayKey: {
                'habit-weekly-skipped': true,
              },
            },
            'habitCountValues': <String, dynamic>{},
          },
        );

        final mondayItem = result.weeklyActivity.first;
        expect(mondayItem.expectedCount, 2);
        expect(mondayItem.completedCount, 1);
        expect(mondayItem.percentage, 50);
      });

      test(
          'adding expected active habits without completion reduces today percentage',
          () async {
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

        final baseToday =
            base.weeklyActivity.firstWhere((item) => item.isToday);
        final newToday = withNewUncompleted.weeklyActivity
            .firstWhere((item) => item.isToday);

        expect(baseToday.percentage, 100);
        expect(newToday.percentage, 50);
      });

      test('count habits below target are not completed in weekly activity',
          () async {
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

        final todayItem =
            result.weeklyActivity.firstWhere((item) => item.isToday);
        expect(todayItem.expectedCount, 1);
        expect(todayItem.completedCount, 0);
        expect(todayItem.percentage, 0);
      });

      test('future days are marked as future and rendered neutral data',
          () async {
        final weekNow = DateTime(2026, 5, 6, 10);

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
          ],
        );

        final futureDays =
            result.weeklyActivity.where((item) => item.isFuture).toList();
        expect(futureDays, hasLength(4));
        for (final item in futureDays) {
          expect(item.completedCount, 0);
          expect(item.expectedCount, 0);
          expect(item.percentage, 0);
        }
      });
    });

    group('monthly calendar', () {
      test('returns the expected number of days for the current month',
          () async {
        final monthNow = DateTime(2026, 5, 6, 10);
        final result = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
          ],
        );

        expect(result.monthlyCalendarDays, hasLength(31));
        expect(result.monthlyCalendarDays.every((day) => day.isCurrentMonth),
            isTrue);
      });

      test(
          'calculates completed/expected/percentage correctly for a specific day',
          () async {
        final monthNow = DateTime(2026, 5, 6, 10);
        final mayFifth = DateTime(2026, 5, 5, 10);

        final result = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(id: 'habit-complete', title: 'Complete'),
            _habit(id: 'habit-pending', title: 'Pending'),
          ],
          history: _historyForDay(
            mayFifth,
            completions: {'habit-complete': true},
            completionTimes: {
              'habit-complete': DateTime(2026, 5, 5, 8).millisecondsSinceEpoch,
            },
          ),
        );

        final mayFifthItem =
            result.monthlyCalendarDays.firstWhere((item) => item.date.day == 5);
        expect(mayFifthItem.expectedCount, 2);
        expect(mayFifthItem.completedCount, 1);
        expect(mayFifthItem.percentage, 50);
      });

      test('excludes skipped habits from expected count for each calendar day',
          () async {
        final monthNow = DateTime(2026, 5, 6, 10);
        final mayFifth = DateTime(2026, 5, 5, 10);

        final result = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(id: 'habit-complete', title: 'Complete'),
            _habit(id: 'habit-skipped', title: 'Skipped'),
            _habit(id: 'habit-pending', title: 'Pending'),
          ],
          history: _historyForDay(
            mayFifth,
            completions: {
              'habit-complete': true,
              'habit-skipped': true,
            },
            skips: {
              'habit-skipped': true,
            },
            completionTimes: {
              'habit-complete': DateTime(2026, 5, 5, 8).millisecondsSinceEpoch,
              'habit-skipped': DateTime(2026, 5, 5, 9).millisecondsSinceEpoch,
            },
          ),
        );

        final mayFifthItem =
            result.monthlyCalendarDays.firstWhere((item) => item.date.day == 5);
        expect(mayFifthItem.expectedCount, 2);
        expect(mayFifthItem.completedCount, 1);
        expect(mayFifthItem.percentage, 50);
      });

      test('unticking one habit reduces today percentage', () async {
        final monthNow = DateTime(2026, 5, 6, 10);

        final allDone = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
            _habit(
                id: 'habit-b', title: 'Habit B', doneToday: true, progress: 1),
          ],
        );

        final oneUnticked = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
            _habit(
                id: 'habit-b', title: 'Habit B', doneToday: false, progress: 0),
          ],
        );

        final todayAllDone =
            allDone.monthlyCalendarDays.firstWhere((item) => item.isToday);
        final todayUnticked =
            oneUnticked.monthlyCalendarDays.firstWhere((item) => item.isToday);

        expect(todayAllDone.percentage, 100);
        expect(todayUnticked.percentage, 50);
      });

      test(
          'adding active unfinished habit reduces today percentage if expected today',
          () async {
        final monthNow = DateTime(2026, 5, 6, 10);

        final base = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(
                id: 'habit-existing',
                title: 'Existing',
                doneToday: true,
                progress: 1),
          ],
        );

        final withNewUncompleted = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(
                id: 'habit-existing',
                title: 'Existing',
                doneToday: true,
                progress: 1),
            _habit(
                id: 'habit-new', title: 'New', doneToday: false, progress: 0),
          ],
        );

        final baseToday =
            base.monthlyCalendarDays.firstWhere((item) => item.isToday);
        final newToday = withNewUncompleted.monthlyCalendarDays
            .firstWhere((item) => item.isToday);

        expect(baseToday.percentage, 100);
        expect(newToday.percentage, 50);
      });

      test('count habit below target is not completed', () async {
        final monthNow = DateTime(2026, 5, 6, 10);

        final result = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(
              id: 'count-monthly',
              title: 'Count Monthly',
              type: 'count',
              target: 5,
              progress: 4,
              doneToday: false,
            ),
          ],
          history: _historyForDay(
            monthNow,
            countValues: {'count-monthly': 4},
          ),
        );

        final todayItem =
            result.monthlyCalendarDays.firstWhere((item) => item.isToday);
        expect(todayItem.expectedCount, 1);
        expect(todayItem.completedCount, 0);
        expect(todayItem.percentage, 0);
      });

      test('future days are marked as future and rendered neutral data',
          () async {
        final monthNow = DateTime(2026, 5, 6, 10);

        final result = await _buildMonthViewData(
          now: monthNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
          ],
        );

        final futureDays =
            result.monthlyCalendarDays.where((item) => item.isFuture).toList();
        expect(futureDays, isNotEmpty);
        for (final item in futureDays) {
          expect(item.completedCount, 0);
          expect(item.expectedCount, 0);
          expect(item.percentage, 0);
        }
      });

      test('empty data does not crash', () async {
        final monthNow = DateTime(2026, 5, 6, 10);

        final result = await _buildMonthViewData(
          now: monthNow,
          activeHabits: const <Map<String, dynamic>>[],
        );

        expect(result.monthlyCalendarDays, hasLength(31));
        expect(result.monthlyCalendarDays.every((day) => day.percentage == 0),
            isTrue);
      });
    });

    group('yearly consistency', () {
      test('returns 12 month entries for year period', () async {
        final yearNow = DateTime(2026, 5, 20, 10);

        final result = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
          ],
        );

        expect(result.yearlyConsistencyMonths, hasLength(12));
        expect(result.yearlyConsistencyMonths.first.month, 1);
        expect(result.yearlyConsistencyMonths.last.month, 12);
      });

      test('calculates completed expected percentage for a past month',
          () async {
        final yearNow = DateTime(2026, 5, 20, 10);
        final history = _emptyHistory();
        _setCheckCompletion(history, DateTime(2026, 1, 1, 8), 'habit-jan');
        _setCheckCompletion(history, DateTime(2026, 1, 2, 8), 'habit-jan');
        _setCheckCompletion(history, DateTime(2026, 1, 3, 8), 'habit-jan');

        final result = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(id: 'habit-jan', title: 'Habit Jan'),
          ],
          history: history,
        );

        final january = result.yearlyConsistencyMonths.firstWhere(
          (item) => item.month == 1,
        );
        expect(january.expectedCount, 31);
        expect(january.completedCount, 3);
        expect(january.percentage, 10);
      });

      test('current month uses elapsed days only up to today', () async {
        final yearNow = DateTime(2026, 5, 20, 10);
        final history = _emptyHistory();
        for (var day = 1; day <= 10; day++) {
          _setCheckCompletion(history, DateTime(2026, 5, day, 8), 'habit-may');
        }

        final result = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(id: 'habit-may', title: 'Habit May'),
          ],
          history: history,
        );

        final may = result.yearlyConsistencyMonths.firstWhere(
          (item) => item.month == 5,
        );
        expect(may.expectedCount, 20);
        expect(may.completedCount, 10);
        expect(may.percentage, 50);
        expect(may.isCurrentMonth, isTrue);
      });

      test('excludes skipped habit instances from monthly denominator',
          () async {
        final yearNow = DateTime(2026, 5, 20, 10);
        final history = _emptyHistory();

        for (var day = 1; day <= 20; day++) {
          _setCheckCompletion(history, DateTime(2026, 5, day, 8), 'habit-a');
        }
        for (var day = 1; day <= 10; day++) {
          _setSkip(history, DateTime(2026, 5, day, 8), 'habit-b');
        }

        final result = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(
              id: 'habit-a',
              title: 'Habit A',
              doneToday: true,
              progress: 1,
            ),
            _habit(id: 'habit-b', title: 'Habit B'),
          ],
          history: history,
        );

        final may = result.yearlyConsistencyMonths.firstWhere(
          (item) => item.month == 5,
        );
        expect(may.expectedCount, 30);
        expect(may.completedCount, 20);
        expect(may.percentage, 67);
      });

      test('future months are marked future with neutral values', () async {
        final yearNow = DateTime(2026, 5, 20, 10);

        final result = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(id: 'habit-a', title: 'Habit A'),
          ],
        );

        final futureMonths = result.yearlyConsistencyMonths
            .where((item) => item.isFuture)
            .toList();
        expect(futureMonths, hasLength(7));
        for (final month in futureMonths) {
          expect(month.completedCount, 0);
          expect(month.expectedCount, 0);
          expect(month.percentage, 0);
        }
      });

      test('unticking a habit reduces current month percentage', () async {
        final yearNow = DateTime(2026, 5, 20, 10);
        final history = _emptyHistory();
        for (var day = 1; day <= 20; day++) {
          _setCheckCompletion(history, DateTime(2026, 5, day, 8), 'habit-a');
          _setCheckCompletion(history, DateTime(2026, 5, day, 8), 'habit-b');
        }

        final allDone = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
            _habit(
                id: 'habit-b', title: 'Habit B', doneToday: true, progress: 1),
          ],
          history: history,
        );
        final oneUnticked = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(
                id: 'habit-a', title: 'Habit A', doneToday: true, progress: 1),
            _habit(
                id: 'habit-b', title: 'Habit B', doneToday: false, progress: 0),
          ],
          history: history,
        );

        final mayAllDone = allDone.yearlyConsistencyMonths.firstWhere(
          (item) => item.month == 5,
        );
        final mayUnticked = oneUnticked.yearlyConsistencyMonths.firstWhere(
          (item) => item.month == 5,
        );

        expect(mayAllDone.percentage, 100);
        expect(mayUnticked.percentage, 98);
      });

      test('adding active unfinished habit reduces current month percentage',
          () async {
        final yearNow = DateTime(2026, 5, 20, 10);
        final history = _emptyHistory();
        for (var day = 1; day <= 20; day++) {
          _setCheckCompletion(
            history,
            DateTime(2026, 5, day, 8),
            'habit-existing',
          );
        }

        final base = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(
                id: 'habit-existing',
                title: 'Existing',
                doneToday: true,
                progress: 1),
          ],
          history: history,
        );
        final withNewUncompleted = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(
                id: 'habit-existing',
                title: 'Existing',
                doneToday: true,
                progress: 1),
            _habit(
                id: 'habit-new', title: 'New', doneToday: false, progress: 0),
          ],
          history: history,
        );

        final mayBase =
            base.yearlyConsistencyMonths.firstWhere((item) => item.month == 5);
        final mayNew = withNewUncompleted.yearlyConsistencyMonths.firstWhere(
          (item) => item.month == 5,
        );

        expect(mayBase.percentage, 100);
        expect(mayNew.percentage, 50);
      });

      test('count habit below target is not completed', () async {
        final yearNow = DateTime(2026, 5, 20, 10);
        final history = _historyForDay(
          yearNow,
          countValues: {'count-yearly': 4},
        );

        final result = await _buildYearViewData(
          now: yearNow,
          activeHabits: [
            _habit(
              id: 'count-yearly',
              title: 'Count Yearly',
              type: 'count',
              target: 5,
              progress: 4,
              doneToday: false,
            ),
          ],
          history: history,
        );

        final may = result.yearlyConsistencyMonths.firstWhere(
          (item) => item.month == 5,
        );
        expect(may.expectedCount, 20);
        expect(may.completedCount, 0);
        expect(may.percentage, 0);
      });

      test('empty data does not crash', () async {
        final yearNow = DateTime(2026, 5, 20, 10);

        final result = await _buildYearViewData(
          now: yearNow,
          activeHabits: const <Map<String, dynamic>>[],
        );

        expect(result.yearlyConsistencyMonths, hasLength(12));
        expect(
            result.yearlyConsistencyMonths
                .every((month) => month.percentage == 0),
            isTrue);
      });
    });

    group('weekly improvement', () {
      test('computes +12 delta when current week is 82 and previous week is 70',
          () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final currentMonday = _startOfWeek(weekNow);
        final previousMonday = currentMonday.subtract(const Duration(days: 7));
        final habits = _buildWeeklyHabits(
          count: 100,
          weekday: DateTime.monday,
        );
        final history = _emptyHistory();

        for (var index = 0; index < 82; index++) {
          _setCheckCompletion(
              history, currentMonday, 'weekly-habit-${index + 1}');
        }
        for (var index = 0; index < 70; index++) {
          _setCheckCompletion(
              history, previousMonday, 'weekly-habit-${index + 1}');
        }

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: habits,
          history: history,
        );

        expect(result.weeklyImprovement.hasComparison, isTrue);
        expect(result.weeklyImprovement.currentWeekPercentage, 82);
        expect(result.weeklyImprovement.previousWeekPercentage, 70);
        expect(result.weeklyImprovement.deltaPercentage, 12);
      });

      test('computes -8 delta when current week is 65 and previous week is 73',
          () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final currentMonday = _startOfWeek(weekNow);
        final previousMonday = currentMonday.subtract(const Duration(days: 7));
        final habits = _buildWeeklyHabits(
          count: 100,
          weekday: DateTime.monday,
        );
        final history = _emptyHistory();

        for (var index = 0; index < 65; index++) {
          _setCheckCompletion(
              history, currentMonday, 'weekly-habit-${index + 1}');
        }
        for (var index = 0; index < 73; index++) {
          _setCheckCompletion(
              history, previousMonday, 'weekly-habit-${index + 1}');
        }

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: habits,
          history: history,
        );

        expect(result.weeklyImprovement.hasComparison, isTrue);
        expect(result.weeklyImprovement.currentWeekPercentage, 65);
        expect(result.weeklyImprovement.previousWeekPercentage, 73);
        expect(result.weeklyImprovement.deltaPercentage, -8);
      });

      test(
          'returns zero delta when current and previous week percentages are equal',
          () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final currentMonday = _startOfWeek(weekNow);
        final previousMonday = currentMonday.subtract(const Duration(days: 7));
        final habits = _buildWeeklyHabits(
          count: 100,
          weekday: DateTime.monday,
        );
        final history = _emptyHistory();

        for (var index = 0; index < 70; index++) {
          final habitId = 'weekly-habit-${index + 1}';
          _setCheckCompletion(history, currentMonday, habitId);
          _setCheckCompletion(history, previousMonday, habitId);
        }

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: habits,
          history: history,
        );

        expect(result.weeklyImprovement.hasComparison, isTrue);
        expect(result.weeklyImprovement.currentWeekPercentage, 70);
        expect(result.weeklyImprovement.previousWeekPercentage, 70);
        expect(result.weeklyImprovement.deltaPercentage, 0);
      });

      test('returns no comparison when previous week has no expected habits',
          () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final currentMonday = _startOfWeek(weekNow);
        final habits = _buildWeeklyHabits(
          count: 10,
          weekday: DateTime.monday,
          createdAt: currentMonday,
        );
        final history = _emptyHistory();

        for (var index = 0; index < 6; index++) {
          _setCheckCompletion(
              history, currentMonday, 'weekly-habit-${index + 1}');
        }

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: habits,
          history: history,
        );

        expect(result.weeklyImprovement.hasComparison, isFalse);
        expect(result.weeklyImprovement.currentWeekPercentage, 60);
        expect(result.weeklyImprovement.previousWeekPercentage, 0);
        expect(result.weeklyImprovement.deltaPercentage, 0);
      });

      test('uses elapsed days only for current week consistency', () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final currentWeekStart = _startOfWeek(weekNow);
        final monday = currentWeekStart;
        final tuesday = currentWeekStart.add(const Duration(days: 1));
        final thursday = currentWeekStart.add(const Duration(days: 3));
        final history = _emptyHistory();
        _setCheckCompletion(history, monday, 'daily-habit');
        _setCheckCompletion(history, tuesday, 'daily-habit');
        _setCheckCompletion(history, thursday, 'daily-habit');

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
              id: 'daily-habit',
              title: 'Daily Habit',
            ),
          ],
          history: history,
        );

        expect(result.weeklyImprovement.currentWeekPercentage, 67);
      });

      test('uses full previous week window for previous consistency', () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final currentWeekStart = _startOfWeek(weekNow);
        final previousSunday =
            currentWeekStart.subtract(const Duration(days: 1));
        final history = _emptyHistory();
        _setCheckCompletion(history, previousSunday, 'sunday-habit');

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
              id: 'sunday-habit',
              title: 'Sunday Habit',
              schedule: {
                'type': 'weekly',
                'weekdays': [DateTime.sunday],
              },
            ),
          ],
          history: history,
        );

        expect(result.weeklyImprovement.hasComparison, isTrue);
        expect(result.weeklyImprovement.previousWeekPercentage, 100);
        expect(result.weeklyImprovement.currentWeekPercentage, 0);
        expect(result.weeklyImprovement.deltaPercentage, -100);
      });

      test('count habits below target remain unfinished for weekly improvement',
          () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final currentMonday = _startOfWeek(weekNow);
        final previousMonday = currentMonday.subtract(const Duration(days: 7));
        final history = _emptyHistory();
        _setCountValue(history, currentMonday, 'count-weekly', 4);
        _setCountValue(history, previousMonday, 'count-weekly', 5);

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: [
            _habit(
              id: 'count-weekly',
              title: 'Count Weekly',
              type: 'count',
              target: 5,
              schedule: {
                'type': 'weekly',
                'weekdays': [DateTime.monday],
              },
            ),
          ],
          history: history,
        );

        expect(result.weeklyImprovement.hasComparison, isTrue);
        expect(result.weeklyImprovement.currentWeekPercentage, 0);
        expect(result.weeklyImprovement.previousWeekPercentage, 100);
        expect(result.weeklyImprovement.deltaPercentage, -100);
      });

      test('weekly improvement excludes skipped habits from current week',
          () async {
        final weekNow = DateTime(2026, 5, 6, 10);
        final currentMonday = _startOfWeek(weekNow);
        final previousMonday = currentMonday.subtract(const Duration(days: 7));
        final history = _emptyHistory();
        final habits = _buildWeeklyHabits(
          count: 10,
          weekday: DateTime.monday,
        );

        for (var index = 0; index < 8; index++) {
          final habitId = 'weekly-habit-${index + 1}';
          _setCheckCompletion(history, currentMonday, habitId);
          _setCheckCompletion(history, previousMonday, habitId);
        }
        _setSkip(history, currentMonday, 'weekly-habit-9');
        _setSkip(history, currentMonday, 'weekly-habit-10');

        final result = await _buildWeekViewData(
          now: weekNow,
          activeHabits: habits,
          history: history,
        );

        expect(result.weeklyImprovement.hasComparison, isTrue);
        expect(result.weeklyImprovement.currentWeekPercentage, 100);
        expect(result.weeklyImprovement.previousWeekPercentage, 80);
        expect(result.weeklyImprovement.deltaPercentage, 20);
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

      test(
          'returns only the available habits when fewer than 3 have completions',
          () async {
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
      test('aggregates completions by family and returns up to 4 entries',
          () async {
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

      test('unknown or deleted habit ids in completions do not crash',
          () async {
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

Future<StatisticsV3ViewData> _buildYearViewData({
  required DateTime now,
  required List<Map<String, dynamic>> activeHabits,
  Map<String, dynamic>? history,
}) async {
  return _buildViewData(
    period: StatisticsV3Period.year,
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

Map<String, dynamic> _emptyHistory() {
  return <String, dynamic>{
    'habitCompletions': <String, dynamic>{},
    'habitCompletionTimes': <String, dynamic>{},
    'habitSkips': <String, dynamic>{},
    'habitCountValues': <String, dynamic>{},
  };
}

void _setCheckCompletion(
  Map<String, dynamic> history,
  DateTime day,
  String habitId,
) {
  final dayKey = _dateKey(day);
  final completionsRoot =
      history['habitCompletions'] as Map<String, dynamic>? ??
          <String, dynamic>{};
  history['habitCompletions'] = completionsRoot;
  final completionTimesRoot =
      history['habitCompletionTimes'] as Map<String, dynamic>? ??
          <String, dynamic>{};
  history['habitCompletionTimes'] = completionTimesRoot;

  final completions = _ensureDayMap(completionsRoot, dayKey);
  completions[habitId] = true;
  final times = _ensureDayMap(completionTimesRoot, dayKey);
  times[habitId] = DateTime(
    day.year,
    day.month,
    day.day,
    8,
  ).millisecondsSinceEpoch;
}

void _setCountValue(
  Map<String, dynamic> history,
  DateTime day,
  String habitId,
  num value,
) {
  final dayKey = _dateKey(day);
  final countValuesRoot =
      history['habitCountValues'] as Map<String, dynamic>? ??
          <String, dynamic>{};
  history['habitCountValues'] = countValuesRoot;

  final countValues = _ensureDayMap(countValuesRoot, dayKey);
  countValues[habitId] = value;
}

void _setSkip(
  Map<String, dynamic> history,
  DateTime day,
  String habitId,
) {
  final dayKey = _dateKey(day);
  final skipsRoot = history['habitSkips'] as Map<String, dynamic>? ??
      <String, dynamic>{};
  history['habitSkips'] = skipsRoot;

  final skips = _ensureDayMap(skipsRoot, dayKey);
  skips[habitId] = true;
}

DateTime _startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

List<Map<String, dynamic>> _buildWeeklyHabits({
  required int count,
  required int weekday,
  DateTime? createdAt,
}) {
  return List<Map<String, dynamic>>.generate(count, (index) {
    return _habit(
      id: 'weekly-habit-${index + 1}',
      title: 'Weekly habit ${index + 1}',
      schedule: {
        'type': 'weekly',
        'weekdays': [weekday],
      },
      createdAt: createdAt,
    );
  }, growable: false);
}

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
  DateTime? createdAt,
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
    if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
    'schedule': schedule ??
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
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
