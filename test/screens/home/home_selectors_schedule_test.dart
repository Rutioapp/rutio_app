import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/home/home_screen.dart';

void main() {
  group('isHabitExpectedForDate', () {
    final day = DateTime(2026, 5, 11);

    test('daily habit is expected on and after createdAt', () {
      final habit = _habit(
        id: 'daily-1',
        createdAt: '2026-05-10',
        schedule: const {'type': 'daily'},
      );

      expect(isHabitExpectedForDate(habit, day), isTrue);
      expect(
        isHabitExpectedForDate(habit, DateTime(2026, 5, 9)),
        isFalse,
      );
    });

    test('weekly habit is expected only on selected weekdays', () {
      final habit = _habit(
        id: 'weekly-1',
        createdAt: '2026-05-01',
        schedule: const {
          'type': 'weekly',
          'weekdays': [1, 3, 5],
        },
      );

      expect(isHabitExpectedForDate(habit, DateTime(2026, 5, 11)), isTrue);
      expect(isHabitExpectedForDate(habit, DateTime(2026, 5, 12)), isFalse);
    });

    test('once habit is expected only on configured date', () {
      final habit = _habit(
        id: 'once-1',
        createdAt: '2026-05-01',
        schedule: const {
          'type': 'once',
          'date': '2026-05-20',
        },
      );

      expect(isHabitExpectedForDate(habit, DateTime(2026, 5, 20)), isTrue);
      expect(isHabitExpectedForDate(habit, DateTime(2026, 5, 21)), isFalse);
    });

    test('archived habit is never expected', () {
      final habit = _habit(
        id: 'archived-1',
        createdAt: '2026-05-01',
        archived: true,
        schedule: const {'type': 'daily'},
      );

      expect(isHabitExpectedForDate(habit, day), isFalse);
    });
  });

  group('buildHomeViewData schedule filtering', () {
    test('excludes unscheduled habits from pending/completed/skipped and totals',
        () {
      final today = DateTime.now();
      final selectedDay = DateTime(today.year, today.month, today.day);
      final selectedKey = _dateKey(selectedDay);

      final root = <String, dynamic>{
        'userState': {
          'activeHabits': [
            _habit(
              id: 'daily-pending',
              createdAt: '2020-01-01',
              schedule: const {'type': 'daily'},
              doneToday: false,
              skippedToday: false,
            ),
            _habit(
              id: 'weekly-unscheduled-done',
              createdAt: '2020-01-01',
              schedule: {
                'type': 'weekly',
                'weekdays': [((selectedDay.weekday % 7) + 1)],
              },
              doneToday: true,
              skippedToday: false,
            ),
            _habit(
              id: 'once-unscheduled-skipped',
              createdAt: '2020-01-01',
              schedule: const {
                'type': 'once',
                'date': '1999-01-01',
              },
              doneToday: false,
              skippedToday: true,
            ),
          ],
          'history': {
            'habitCompletions': {
              selectedKey: {
                'daily-pending': false,
                'weekly-unscheduled-done': true,
                'once-unscheduled-skipped': false,
              },
            },
            'habitCountValues': {
              selectedKey: {},
            },
          },
        },
      };

      final view = buildHomeViewData(root, selectedDay);

      expect(view.viewHabits.map((h) => h['id']), ['daily-pending']);
      expect(view.pendingHabits.map((h) => h['id']), ['daily-pending']);
      expect(view.completedHabits, isEmpty);
      expect(view.skippedHabits, isEmpty);
      expect(view.doneCount, 0);
      expect(view.totalCount, 1);
    });

    test('non-today view uses selected day skips and skip wins over stale done',
        () {
      final selectedDay = DateTime(2026, 5, 11);
      final selectedKey = _dateKey(selectedDay);

      final root = <String, dynamic>{
        'userState': {
          'activeHabits': [
            _habit(
              id: 'daily-check',
              createdAt: '2020-01-01',
              schedule: const {'type': 'daily'},
              doneToday: true,
              skippedToday: true,
            ),
          ],
          'history': {
            'habitCompletions': {
              selectedKey: {
                'daily-check': true,
              },
            },
            'habitCountValues': {
              selectedKey: {},
            },
            'habitSkips': {
              selectedKey: {
                'daily-check': false,
              },
            },
          },
        },
      };

      final view = buildHomeViewData(root, selectedDay);
      expect(view.pendingHabits, isEmpty);
      expect(view.completedHabits.map((h) => h['id']), ['daily-check']);
      expect(view.skippedHabits, isEmpty);
      expect(view.doneCount, 1);
      expect(view.totalCount, 1);
    });
  });
}

Map<String, dynamic> _habit({
  required String id,
  required String createdAt,
  required Map<String, dynamic> schedule,
  bool archived = false,
  bool doneToday = false,
  bool skippedToday = false,
}) {
  return {
    'id': id,
    'createdAt': createdAt,
    'schedule': schedule,
    'archived': archived,
    'doneToday': doneToday,
    'skippedToday': skippedToday,
    'type': 'check',
    'title': id,
  };
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
