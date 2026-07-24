import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/mappers/habit_remote_mapper.dart';
import 'package:rutio/data/models/remote/remote_habit.dart';

void main() {
  group('habit schedule cloud mapper', () {
    test('creates daily habit payload for Supabase', () {
      final remote = HabitRemoteMapper.toRemoteHabit(
        _localHabit(schedule: const <String, dynamic>{'type': 'daily'}),
        userId: 'user-1',
        sortOrder: 0,
      );

      expect(remote.toUpsertMap()['schedule'], {'type': 'daily'});
    });

    test('creates weekly habit payload with weekdays for Supabase', () {
      final remote = HabitRemoteMapper.toRemoteHabit(
        _localHabit(
          schedule: const <String, dynamic>{
            'type': 'weekly',
            'weekdays': <int>[5, 1, 3],
          },
        ),
        userId: 'user-1',
        sortOrder: 0,
      );

      expect(remote.toUpsertMap()['schedule'], {
        'type': 'weekly',
        'weekdays': <int>[1, 3, 5],
      });
    });

    test('creates once habit payload for Supabase', () {
      final remote = HabitRemoteMapper.toRemoteHabit(
        _localHabit(
          schedule: const <String, dynamic>{
            'type': 'once',
            'date': '2026-07-25',
          },
        ),
        userId: 'user-1',
        sortOrder: 0,
      );

      expect(remote.toUpsertMap()['schedule'], {
        'type': 'once',
        'date': '2026-07-25',
      });
    });

    test('creates timesPerWeek habit payload for Supabase', () {
      final remote = HabitRemoteMapper.toRemoteHabit(
        _localHabit(
          schedule: const <String, dynamic>{
            'type': 'timesPerWeek',
            'timesPerWeekTarget': 3,
            'weekStartsOn': 1,
          },
        ),
        userId: 'user-1',
        sortOrder: 0,
      );

      expect(remote.toUpsertMap()['schedule'], {
        'type': 'timesPerWeek',
        'timesPerWeek': 3,
        'weekStartsOn': 1,
      });
    });

    test('reads every schedule type from Supabase', () {
      expect(
        _remoteFromSchedule(const <String, dynamic>{'type': 'daily'}).schedule,
        {'type': 'daily'},
      );
      expect(
        _remoteFromSchedule(
          const <String, dynamic>{
            'type': 'weekly',
            'weekdays': <int>[2, 4]
          },
        ).schedule,
        {
          'type': 'weekly',
          'weekdays': <int>[2, 4]
        },
      );
      expect(
        _remoteFromSchedule(
          const <String, dynamic>{'type': 'once', 'date': '2026-07-25'},
        ).schedule,
        {'type': 'once', 'date': '2026-07-25'},
      );
      expect(
        _remoteFromSchedule(
          const <String, dynamic>{
            'type': 'timesPerWeek',
            'timesPerWeek': 4,
            'weekStartsOn': 7,
          },
        ).schedule,
        {'type': 'timesPerWeek', 'timesPerWeek': 4, 'weekStartsOn': 7},
      );
    });

    test('applies daily fallback for missing or invalid Supabase schedule', () {
      expect(_remoteFromSchedule(null).schedule, {'type': 'daily'});
      expect(_remoteWithNullSchedule().schedule, {'type': 'daily'});
      expect(_remoteWithNullSchedule().hasExplicitSchedule, isFalse);
      expect(_remoteFromSchedule(null).hasExplicitSchedule, isFalse);
      expect(
        _remoteFromSchedule(
          const <String, dynamic>{'type': 'once', 'date': '2026-02-31'},
        ).schedule,
        {'type': 'daily'},
      );
      expect(
        _remoteFromSchedule(
          const <String, dynamic>{'type': 'once', 'date': '2026-02-31'},
        ).hasExplicitSchedule,
        isFalse,
      );
    });

    test('weekly empty normalizes to daily', () {
      final remote = HabitRemoteMapper.toRemoteHabit(
        _localHabit(
          schedule: const <String, dynamic>{
            'type': 'weekly',
            'weekdays': <int>[],
          },
        ),
        userId: 'user-1',
        sortOrder: 0,
      );

      expect(remote.toUpsertMap()['schedule'], {'type': 'daily'});
    });

    test('normalizes repeated invalid and unordered weekdays', () {
      final remote = HabitRemoteMapper.toRemoteHabit(
        _localHabit(
          schedule: const <String, dynamic>{
            'type': 'weekly',
            'weekdays': <Object>[7, 1, 9, 1, 0, 3, '2', 2.5, '4.5'],
          },
        ),
        userId: 'user-1',
        sortOrder: 0,
      );

      expect(remote.toUpsertMap()['schedule'], {
        'type': 'weekly',
        'weekdays': <int>[1, 2, 3, 7],
      });
    });

    test('rejects decimal weekdays timesPerWeek and weekStartsOn', () {
      expect(
        HabitRemoteMapper.toRemoteHabit(
          _localHabit(
            schedule: const <String, dynamic>{
              'type': 'weekly',
              'weekdays': <Object>[1.5],
            },
          ),
          userId: 'user-1',
          sortOrder: 0,
        ).toUpsertMap()['schedule'],
        {'type': 'daily'},
      );
      expect(
        HabitRemoteMapper.toRemoteHabit(
          _localHabit(
            schedule: const <String, dynamic>{
              'type': 'timesPerWeek',
              'timesPerWeek': 2.5,
            },
          ),
          userId: 'user-1',
          sortOrder: 0,
        ).toUpsertMap()['schedule'],
        {'type': 'daily'},
      );
      expect(
        HabitRemoteMapper.toRemoteHabit(
          _localHabit(
            schedule: const <String, dynamic>{
              'type': 'timesPerWeek',
              'timesPerWeek': 2,
              'weekStartsOn': 1.5,
            },
          ),
          userId: 'user-1',
          sortOrder: 0,
        ).toUpsertMap()['schedule'],
        {'type': 'timesPerWeek', 'timesPerWeek': 2},
      );
    });

    test('new habit without local schedule uses daily', () {
      final remote = HabitRemoteMapper.toRemoteHabit(
        <String, dynamic>{
          'id': 'local-habit',
          'name': 'Habit',
          'type': 'check',
          'target': 1,
        },
        userId: 'user-1',
        sortOrder: 0,
      );

      expect(remote.toUpsertMap()['schedule'], {'type': 'daily'});
    });

    test('migration allows null temporarily and rejects weekly empty', () {
      final migration = _readScheduleMigration();

      expect(migration, contains('add column if not exists schedule jsonb;'));
      expect(migration, isNot(contains('schedule jsonb not null')));
      expect(migration, isNot(contains('default \'{"type":"daily"}')));
      expect(migration, contains('schedule is null'));
      expect(
        migration,
        contains("jsonb_array_length(value->'weekdays') = 0"),
      );
    });

    test('keeps schedules scoped to their remote users', () {
      final userOne = _remoteFromSchedule(
        const <String, dynamic>{
          'type': 'weekly',
          'weekdays': <int>[1]
        },
        userId: 'user-1',
      );
      final userTwo = _remoteFromSchedule(
        const <String, dynamic>{
          'type': 'weekly',
          'weekdays': <int>[5]
        },
        userId: 'user-2',
      );

      expect(userOne.userId, 'user-1');
      expect(userOne.schedule['weekdays'], <int>[1]);
      expect(userTwo.userId, 'user-2');
      expect(userTwo.schedule['weekdays'], <int>[5]);
    });
  });
}

String _readScheduleMigration() {
  return File(
    Uri.base
        .resolve('supabase/migrations/20260725090000_add_habit_schedule.sql')
        .toFilePath(),
  ).readAsStringSync();
}

Map<String, dynamic> _localHabit({
  required Map<String, dynamic> schedule,
}) {
  return <String, dynamic>{
    'id': 'local-habit',
    'name': 'Habit',
    'type': 'check',
    'target': 1,
    'schedule': schedule,
  };
}

RemoteHabit _remoteFromSchedule(
  Map<String, dynamic>? schedule, {
  String userId = 'user-1',
}) {
  return RemoteHabit.fromMap(
    <String, dynamic>{
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'user_id': userId,
      'name': 'Habit',
      'habit_type': 'check',
      'reminder_enabled': false,
      'is_archived': false,
      'sort_order': 0,
      if (schedule != null) 'schedule': schedule,
    },
  );
}

RemoteHabit _remoteWithNullSchedule() {
  return RemoteHabit.fromMap(
    <String, dynamic>{
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'user_id': 'user-1',
      'name': 'Habit',
      'habit_type': 'check',
      'reminder_enabled': false,
      'is_archived': false,
      'sort_order': 0,
      'schedule': null,
    },
  );
}
