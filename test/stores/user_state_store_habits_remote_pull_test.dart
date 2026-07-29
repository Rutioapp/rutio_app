import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/models/remote/remote_habit.dart';
import 'package:rutio/data/models/remote/remote_habit_log.dart';
import 'package:rutio/data/repositories/diary_v2_supabase_repository.dart';
import 'package:rutio/data/repositories/habit_log_repository.dart';
import 'package:rutio/data/repositories/habit_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/devtools/demo_seed/demo_seed_models.dart';
import 'package:rutio/features/habits/data/cloud/streak_protection_remote_models.dart';
import 'package:rutio/features/habits/data/cloud/streak_protection_repository.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore habits remote pull', () {
    test('adds a new remote habit locally', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Drink Water',
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Drink Water');
      expect(
        store.activeHabits.first['remoteId'],
        '550e8400-e29b-41d4-a716-446655440000',
      );
      expect(
        (store.activeHabits.first['id'] as String).startsWith('remote_'),
        isTrue,
      );
    });

    test('existing remoteId match does not duplicate and newer remote updates',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Hydrate Better',
            updatedAt: DateTime.utc(2026, 6, 22, 10),
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Drink Water',
            updatedAt: '2026-06-20T09:00:00.000Z',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Hydrate Better');
    });

    test('newer remote habit updates local schedule', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Hydrate Better',
            updatedAt: DateTime.utc(2026, 6, 22, 10),
            schedule: const <String, dynamic>{
              'type': 'weekly',
              'weekdays': <int>[5, 1, 3],
            },
            hasExplicitSchedule: true,
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Drink Water',
            updatedAt: '2026-06-20T09:00:00.000Z',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['schedule'], {
        'type': 'weekly',
        'weekdays': <int>[1, 3, 5],
      });
    });

    test(
        'old remote response without schedule does not clear valid local schedule',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Hydrate Better',
            updatedAt: DateTime.utc(2026, 6, 22, 10),
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Drink Water',
            updatedAt: '2026-06-20T09:00:00.000Z',
            schedule: const <String, dynamic>{
              'type': 'once',
              'date': '2026-07-25',
            },
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Hydrate Better');
      expect(store.activeHabits.first['schedule'], {
        'type': 'once',
        'date': '2026-07-25',
      });
    });

    test('remote null schedule does not clear valid local weekly schedule',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          RemoteHabit.fromMap(
            <String, dynamic>{
              'id': '550e8400-e29b-41d4-a716-446655440000',
              'user_id': 'user-1',
              'name': 'Hydrate Better',
              'habit_type': 'check',
              'reminder_enabled': false,
              'schedule': null,
              'is_archived': false,
              'sort_order': 0,
              'created_at': '2026-06-20T08:00:00.000Z',
              'updated_at': '2026-06-22T10:00:00.000Z',
            },
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Drink Water',
            updatedAt: '2026-06-20T09:00:00.000Z',
            schedule: const <String, dynamic>{
              'type': 'weekly',
              'weekdays': <int>[1, 3, 5],
            },
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Hydrate Better');
      expect(store.activeHabits.first['schedule'], {
        'type': 'weekly',
        'weekdays': <int>[1, 3, 5],
      });
    });

    test('local habit is kept when remote is missing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository:
            _FakeHabitRepository(fetchedHabits: const <RemoteHabit>[]),
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Local Only'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Local Only');
    });

    test('foreign remote habit aborts pull and keeps local state unchanged',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            RemoteHabit(
              id: '550e8400-e29b-41d4-a716-446655440043',
              userId: 'user-999',
              name: 'Foreign Habit',
              habitType: 'check',
              reminderEnabled: false,
              isArchived: false,
              sortOrder: 0,
            ),
          ],
        ),
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Local Only'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Local Only');
    });

    test(
        '1 local habit and 43 foreign remote habits keeps only the local habit',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final foreignHabits = List<RemoteHabit>.generate(
        43,
        (index) => RemoteHabit(
          id: '550e8400-e29b-41d4-a716-44665544${index.toString().padLeft(4, '0')}',
          userId: 'user-999',
          name: 'Foreign Habit $index',
          habitType: 'check',
          reminderEnabled: false,
          isArchived: false,
          sortOrder: index,
        ),
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(fetchedHabits: foreignHabits),
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Local Only'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.single['name'], 'Local Only');
    });

    test(
        'mixed-user remote habits abort pull and local state remains unchanged',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440001',
              name: 'My Habit',
            ),
            RemoteHabit(
              id: '550e8400-e29b-41d4-a716-446655440043',
              userId: 'user-999',
              name: 'Foreign Habit',
              habitType: 'check',
              reminderEnabled: false,
              isArchived: false,
              sortOrder: 1,
            ),
          ],
        ),
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Local Only'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.single['name'], 'Local Only');
    });

    test(
        'missing remote habit user id aborts pull and keeps local state unchanged',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            const RemoteHabit(
              id: '550e8400-e29b-41d4-a716-446655440055',
              userId: '',
              name: 'Broken Habit',
              habitType: 'check',
              reminderEnabled: false,
              isArchived: false,
              sortOrder: 0,
            ),
          ],
        ),
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Local Only'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.single['name'], 'Local Only');
    });

    test('mixed-user remote habits with empty local state import zero habits',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440001',
              name: 'My Habit',
            ),
            const RemoteHabit(
              id: '550e8400-e29b-41d4-a716-446655440043',
              userId: 'user-999',
              name: 'Foreign Habit',
              habitType: 'check',
              reminderEnabled: false,
              isArchived: false,
              sortOrder: 1,
            ),
          ],
        ),
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, isEmpty);
    });

    test('local habit is preferred when timestamps are missing or unclear',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Remote Name',
            updatedAt: DateTime.utc(2026, 6, 22, 10),
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Local Name',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Local Name');
    });

    test('archived local habit is not revived by stale remote state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Remote Active',
            isArchived: false,
            updatedAt: DateTime.utc(2026, 6, 20, 8),
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Local Archived',
            archived: true,
            updatedAt: '2026-06-21T09:00:00.000Z',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['archived'], isTrue);
      expect(store.activeHabits.first['name'], 'Local Archived');
    });

    test('adds remote progress for a new date without side effects', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository(
        logsByRemoteHabitId: <String, List<RemoteHabitLog>>{
          '550e8400-e29b-41d4-a716-446655440000': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440000',
              userId: 'user-1',
              habitId: '550e8400-e29b-41d4-a716-446655440000',
              logDate: DateTime(2026, 6, 21),
              value: 1,
              isCompleted: true,
              source: 'manual',
              updatedAt: DateTime.utc(2026, 6, 21, 7),
            ),
          ],
        },
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Read',
            ),
          ],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Read',
            updatedAt: '2026-06-20T09:00:00.000Z',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      final history = ((store.state!['userState'] as Map)['history'] as Map);
      final completions = (((history['habitCompletions'] as Map)['2026-06-21']
          as Map)['habit-1']);
      expect(completions, isTrue);
      expect(store.pendingAchievementUnlockCount, 0);
      expect(store.pendingLevelCelebrationCount, 0);
      expect(
          ((store.state!['userState'] as Map)['progression'] as Map)['xp'], 0);
      expect(((store.state!['userState'] as Map)['wallet'] as Map)['coins'], 0);
    });

    test('multiple habits use a single batch logs query', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository(
        logsByRemoteHabitId: <String, List<RemoteHabitLog>>{
          '550e8400-e29b-41d4-a716-446655440000': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440000',
              userId: 'user-1',
              habitId: '550e8400-e29b-41d4-a716-446655440000',
              logDate: DateTime(2026, 6, 21),
              value: 1,
              isCompleted: true,
              source: 'manual',
              updatedAt: DateTime.utc(2026, 6, 21, 7),
            ),
          ],
          '550e8400-e29b-41d4-a716-446655440001': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440001',
              userId: 'user-1',
              habitId: '550e8400-e29b-41d4-a716-446655440001',
              logDate: DateTime(2026, 6, 21),
              value: 3,
              isCompleted: false,
              source: 'manual',
              updatedAt: DateTime.utc(2026, 6, 21, 7),
            ),
          ],
        },
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Read',
            ),
            _remoteCountHabit(
              id: '550e8400-e29b-41d4-a716-446655440001',
              name: 'Push Ups',
              targetCount: 10,
            ),
          ],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Read',
          ),
          _localCountHabit(
            id: 'habit-2',
            remoteId: '550e8400-e29b-41d4-a716-446655440001',
            name: 'Push Ups',
            target: 10,
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(habitLogRepository.fetchCalls, 0);
      expect(habitLogRepository.batchFetchCalls, 1);
      final history = ((store.state!['userState'] as Map)['history'] as Map);
      final completions = history['habitCompletions'] as Map;
      final countValues = history['habitCountValues'] as Map;
      expect(((completions['2026-06-21'] as Map)['habit-1']), isTrue);
      expect(((countValues['2026-06-21'] as Map)['habit-2']), 3);
    });

    test('no remote habits do not trigger a batch logs query', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository();
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: const <RemoteHabit>[],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: const <Map<String, dynamic>>[],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(habitLogRepository.fetchCalls, 0);
      expect(habitLogRepository.batchFetchCalls, 0);
    });

    test('foreign remote logs abort merge and keep local progress unchanged',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository(
        logsByRemoteHabitId: <String, List<RemoteHabitLog>>{
          '550e8400-e29b-41d4-a716-446655440000': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440099',
              userId: 'user-999',
              habitId: '550e8400-e29b-41d4-a716-446655440000',
              logDate: DateTime(2026, 6, 21),
              value: 1,
              isCompleted: true,
              source: 'manual',
              updatedAt: DateTime.utc(2026, 6, 21, 7),
            ),
          ],
        },
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Read',
            ),
          ],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Read',
            updatedAt: '2026-06-20T09:00:00.000Z',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      final history = ((store.state!['userState'] as Map)['history'] as Map);
      expect((history['habitCompletions'] as Map).containsKey('2026-06-21'),
          isFalse);
    });

    test('foreign remote logs abort before partial habit merge', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository(
        logsByRemoteHabitId: <String, List<RemoteHabitLog>>{
          '550e8400-e29b-41d4-a716-446655440000': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440096',
              userId: 'user-999',
              habitId: '550e8400-e29b-41d4-a716-446655440000',
              logDate: DateTime(2026, 6, 21),
              value: 1,
              isCompleted: true,
              source: 'manual',
              updatedAt: DateTime.utc(2026, 6, 21, 7),
            ),
          ],
        },
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Should Not Partially Merge',
            ),
          ],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Local Only'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.single['name'], 'Local Only');
      final history = ((store.state!['userState'] as Map)['history'] as Map);
      expect((history['habitCompletions'] as Map).containsKey('2026-06-21'),
          isFalse);
    });

    test(
        'missing remote log user id aborts merge and keeps local progress unchanged',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository(
        logsByRemoteHabitId: <String, List<RemoteHabitLog>>{
          '550e8400-e29b-41d4-a716-446655440000': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440097',
              userId: '',
              habitId: '550e8400-e29b-41d4-a716-446655440000',
              logDate: DateTime(2026, 6, 21),
              value: 1,
              isCompleted: true,
              source: 'manual',
            ),
          ],
        },
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Read',
            ),
          ],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Read',
            updatedAt: '2026-06-20T09:00:00.000Z',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      final history = ((store.state!['userState'] as Map)['history'] as Map);
      expect((history['habitCompletions'] as Map).containsKey('2026-06-21'),
          isFalse);
    });

    test('missing remote log user id aborts before partial habit merge',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository(
        logsByRemoteHabitId: <String, List<RemoteHabitLog>>{
          '550e8400-e29b-41d4-a716-446655440000': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440095',
              userId: '',
              habitId: '550e8400-e29b-41d4-a716-446655440000',
              logDate: DateTime(2026, 6, 21),
              value: 1,
              isCompleted: true,
              source: 'manual',
            ),
          ],
        },
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Should Not Partially Merge',
            ),
          ],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Local Only'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.single['name'], 'Local Only');
      final history = ((store.state!['userState'] as Map)['history'] as Map);
      expect((history['habitCompletions'] as Map).containsKey('2026-06-21'),
          isFalse);
    });

    test('foreign logs for a different habit id are not merged locally',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository(
        logsByRemoteHabitId: <String, List<RemoteHabitLog>>{
          '550e8400-e29b-41d4-a716-446655440000': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440098',
              userId: 'user-1',
              habitId: '550e8400-e29b-41d4-a716-446655440999',
              logDate: DateTime(2026, 6, 21),
              value: 1,
              isCompleted: true,
              source: 'manual',
              updatedAt: DateTime.utc(2026, 6, 21, 7),
            ),
          ],
        },
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Read',
            ),
          ],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'habit-1',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Read',
            updatedAt: '2026-06-20T09:00:00.000Z',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      final history = ((store.state!['userState'] as Map)['history'] as Map);
      expect((history['habitCompletions'] as Map).containsKey('2026-06-21'),
          isFalse);
    });

    test('existing local count progress is not overwritten by remote data',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitLogRepository = _FakeHabitLogRepository(
        logsByRemoteHabitId: <String, List<RemoteHabitLog>>{
          '550e8400-e29b-41d4-a716-446655440001': <RemoteHabitLog>[
            RemoteHabitLog(
              id: '660e8400-e29b-41d4-a716-446655440001',
              userId: 'user-1',
              habitId: '550e8400-e29b-41d4-a716-446655440001',
              logDate: DateTime(2026, 6, 21),
              value: 3,
              isCompleted: false,
              source: 'manual',
              updatedAt: DateTime.utc(2026, 6, 21, 7),
            ),
          ],
        },
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCountHabit(
              id: '550e8400-e29b-41d4-a716-446655440001',
              name: 'Push Ups',
              targetCount: 10,
            ),
          ],
        ),
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCountHabit(
            id: 'habit-2',
            remoteId: '550e8400-e29b-41d4-a716-446655440001',
            name: 'Push Ups',
            target: 10,
          ),
        ],
        historyCompletions: <String, dynamic>{
          '2026-06-21': <String, dynamic>{'habit-2': false},
        },
        historyCountValues: <String, dynamic>{
          '2026-06-21': <String, dynamic>{'habit-2': 8},
        },
      );

      await store.syncHabitsFromRemoteBestEffort();

      final history = ((store.state!['userState'] as Map)['history'] as Map);
      final countValue = (((history['habitCountValues'] as Map)['2026-06-21']
          as Map)['habit-2']);
      expect(countValue, 8);
    });

    test('pull repair prunes only clearly foreign-owned polluted local habits',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchedHabits: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Current User Remote Habit',
            ),
          ],
        ),
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'foreign-owned',
            name: 'Foreign Owned',
            remoteId: '550e8400-e29b-41d4-a716-446655440099',
            remoteUserId: 'user-999',
          ),
          _localCheckHabit(
            id: 'unknown-owner',
            name: 'Unknown Owner Local',
            remoteId: '550e8400-e29b-41d4-a716-446655440098',
          ),
          _localCheckHabit(
            id: 'local-only',
            name: 'Local Only',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(
        store.activeHabits.map((habit) => habit['name']).toList(),
        containsAll(<String>[
          'Unknown Owner Local',
          'Local Only',
          'Current User Remote Habit',
        ]),
      );
      expect(
        store.activeHabits.any((habit) => habit['name'] == 'Foreign Owned'),
        isFalse,
      );
      expect(store.pendingAchievementUnlockCount, 0);
      expect(store.pendingLevelCelebrationCount, 0);
      expect(
        ((store.state!['userState'] as Map)['progression'] as Map)['xp'],
        0,
      );
      expect(((store.state!['userState'] as Map)['wallet'] as Map)['coins'], 0);
    });

    test('pull repair keeps local-only habits without ownership metadata',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository:
            _FakeHabitRepository(fetchedHabits: const <RemoteHabit>[]),
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(
            id: 'local-1',
            name: 'Keep Me',
            remoteId: '550e8400-e29b-41d4-a716-446655440111',
          ),
          _localCheckHabit(
            id: 'local-2',
            name: 'Keep Me Too',
          ),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(
        store.activeHabits.map((habit) => habit['name']).toList(),
        containsAll(<String>['Keep Me', 'Keep Me Too']),
      );
    });

    test('no-auth pull is safe and does not call remote repositories',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Should Not Load',
          ),
        ],
      );
      final habitLogRepository = _FakeHabitLogRepository();
      final store = await _buildStore(
        authenticatedUserId: null,
        habitRepository: habitRepository,
        habitLogRepository: habitLogRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Local Only'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(habitRepository.fetchCalls, 0);
      expect(habitLogRepository.fetchCalls, 0);
      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Local Only');
    });

    test('demo scope does not pull authenticated user data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Should Not Load',
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        userId: DemoSeedScope.userId,
        habitRepository: habitRepository,
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(habitRepository.fetchCalls, 0);
      expect(store.activeHabits, isEmpty);
    });

    test('remote fetch error keeps local state intact', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: _FakeHabitRepository(
          fetchResult: RepositoryResult<List<RemoteHabit>>.failure(
            const RepositoryError(
              code: RepositoryErrorCode.network,
              message: 'offline',
            ),
          ),
        ),
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Keep Me'),
        ],
      );

      await store.syncHabitsFromRemoteBestEffort();

      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Keep Me');
    });

    test('controlled auto sync triggers remote pull when allowed', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      var now = DateTime(2026, 6, 26, 9, 0);

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Drink Water',
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        nowProvider: () => now,
      );

      await store.maybeSyncHabitsFromRemoteBestEffort();

      expect(habitRepository.fetchCalls, 1);
      expect(store.lastHabitsRemotePullAttemptAt, now);
      expect(store.lastHabitsRemotePullSuccessAt, now);
    });

    test('controlled auto sync does not trigger repeatedly within cooldown',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      var now = DateTime(2026, 6, 26, 9, 0);

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Drink Water',
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        nowProvider: () => now,
      );

      await store.maybeSyncHabitsFromRemoteBestEffort();
      now = now.add(const Duration(minutes: 5));
      await store.maybeSyncHabitsFromRemoteBestEffort();
      now = now.add(const Duration(minutes: 11));
      await store.maybeSyncHabitsFromRemoteBestEffort();

      expect(habitRepository.fetchCalls, 2);
    });

    test('controlled auto sync does not run concurrently', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fetchCompleter = Completer<RepositoryResult<List<RemoteHabit>>>();

      final habitRepository = _FakeHabitRepository(
        fetchHandler: () => fetchCompleter.future,
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
      );

      final firstCall = store.maybeSyncHabitsFromRemoteBestEffort();
      await Future<void>.delayed(Duration.zero);
      final secondCall = store.maybeSyncHabitsFromRemoteBestEffort();
      await Future<void>.delayed(Duration.zero);

      expect(habitRepository.fetchCalls, 1);

      fetchCompleter.complete(
        RepositoryResult<List<RemoteHabit>>.success(
          data: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Drink Water',
            ),
          ],
        ),
      );

      await Future.wait(<Future<void>>[firstCall, secondCall]);
      expect(habitRepository.fetchCalls, 1);
    });

    test('manual controlled sync bypasses cooldown safely', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      var now = DateTime(2026, 6, 26, 9, 0);

      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Drink Water',
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        nowProvider: () => now,
      );

      await store.maybeSyncHabitsFromRemoteBestEffort();
      now = now.add(const Duration(minutes: 1));
      await store.maybeSyncHabitsFromRemoteBestEffort(ignoreCooldown: true);

      expect(habitRepository.fetchCalls, 2);
      expect(store.lastHabitsRemotePullAttemptAt, now);
    });

    test('essential bootstrap uses valid scoped habit cache', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final habitRepository = _FakeHabitRepository();
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
        activeHabits: <Map<String, dynamic>>[
          _localCheckHabit(id: 'habit-1', name: 'Cached Habit'),
        ],
      );

      final result =
          await store.prepareEssentialHabitsForBootstrap(userId: 'user-1');

      expect(result.status, EssentialHabitsBootstrapStatus.readyFromCache);
      expect(result.canBuildHome, isTrue);
      expect(habitRepository.fetchCalls, 0);
    });

    test('essential bootstrap does not treat empty template as ready',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final habitRepository = _FakeHabitRepository();
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
      );

      final result =
          await store.prepareEssentialHabitsForBootstrap(userId: 'user-1');

      expect(habitRepository.fetchCalls, 1);
      expect(result.status, EssentialHabitsBootstrapStatus.confirmedEmpty);
      expect(result.source, 'confirmed_empty');
    });

    test('essential bootstrap remote pull applies habits before Home',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final habitRepository = _FakeHabitRepository(
        fetchedHabits: <RemoteHabit>[
          _remoteCheckHabit(
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Remote Habit',
          ),
        ],
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
      );

      final result =
          await store.prepareEssentialHabitsForBootstrap(userId: 'user-1');

      expect(result.status, EssentialHabitsBootstrapStatus.readyFromRemote);
      expect(store.activeHabits, hasLength(1));
      expect(store.activeHabits.first['name'], 'Remote Habit');
    });

    test('essential bootstrap shares in-flight remote pull', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fetchCompleter = Completer<RepositoryResult<List<RemoteHabit>>>();
      final habitRepository = _FakeHabitRepository(
        fetchHandler: () => fetchCompleter.future,
      );
      final store = await _buildStore(
        authenticatedUserId: 'user-1',
        habitRepository: habitRepository,
      );

      final first = store.prepareEssentialHabitsForBootstrap(userId: 'user-1');
      await Future<void>.delayed(Duration.zero);
      final second = store.prepareEssentialHabitsForBootstrap(userId: 'user-1');
      await Future<void>.delayed(Duration.zero);

      expect(habitRepository.fetchCalls, 1);
      fetchCompleter.complete(
        RepositoryResult<List<RemoteHabit>>.success(
          data: <RemoteHabit>[
            _remoteCheckHabit(
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'Remote Habit',
            ),
          ],
        ),
      );

      final results =
          await Future.wait(<Future<EssentialHabitsBootstrapResult>>[
        first,
        second,
      ]);
      expect(results.every((result) => result.canBuildHome), isTrue);
      expect(habitRepository.fetchCalls, 1);
    });
  });
}

Future<UserStateStore> _buildStore({
  required String? authenticatedUserId,
  String userId = 'user-1',
  HabitRepository? habitRepository,
  HabitLogRepository? habitLogRepository,
  DateTime Function()? nowProvider,
  List<Map<String, dynamic>> activeHabits = const <Map<String, dynamic>>[],
  Map<String, dynamic> historyCompletions = const <String, dynamic>{},
  Map<String, dynamic> historyCountValues = const <String, dynamic>{},
  Map<String, dynamic> historySkips = const <String, dynamic>{},
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(userId);
  final store = UserStateStore(
    repo,
    diaryV2SupabaseRepository: _FakeDiaryV2SupabaseRepository(),
    habitRepository: habitRepository ?? _FakeHabitRepository(),
    habitLogRepository: habitLogRepository ?? _FakeHabitLogRepository(),
    journalEntrySyncService: JournalEntrySyncService(),
    streakProtectionRepository: _FakeStreakProtectionRepository(),
    currentSupabaseUserIdProvider: () => authenticatedUserId,
    nowProvider: nowProvider,
  );
  await store.switchLocalScope(userId: userId);
  await store.save(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': userId,
        'meta': <String, dynamic>{
          'schemaVersion': 1,
          'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
          'diaryRewardAppliedDateKeys': <dynamic>[],
          'activeViewDateKey': _todayKey(),
        },
        'progression': <String, dynamic>{'level': 1, 'xp': 0, 'prestige': 0},
        'wallet': <String, dynamic>{'coins': 0},
        'inventory': <String, dynamic>{'items': <dynamic>[]},
        'profile': <String, dynamic>{
          'equipped': <String, dynamic>{},
          'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
          'achievements': <String, dynamic>{
            'unlocked': <dynamic>[],
            'featured': <dynamic>[],
            'rewardAppliedAchievementIds': <dynamic>[],
            'progress': <String, dynamic>{},
          },
        },
        'claims': <String, dynamic>{
          'milestonesClaimed': <dynamic>[],
          'achievementRewardsClaimed': <dynamic>[],
          'prestigeClaimed': <dynamic>[],
        },
        'daily': <String, dynamic>{
          'lastResetDate': _todayKey(),
          'xpEarnedToday': 0,
          'coinsEarnedToday': 0,
          'habitsCompletedToday': <String, dynamic>{},
        },
        'history': <String, dynamic>{
          'habitCompletions': _cloneNestedMap(historyCompletions),
          'habitCountValues': _cloneNestedMap(historyCountValues),
          'habitSkips': _cloneNestedMap(historySkips),
          'habitCompletionTimes': <String, dynamic>{},
        },
        'familyXp': <String, dynamic>{
          'mind': 0,
          'spirit': 0,
          'body': 0,
          'emotional': 0,
          'social': 0,
          'discipline': 0,
          'professional': 0,
        },
        'activeHabits': activeHabits
            .map((habit) => Map<String, dynamic>.from(habit))
            .toList(growable: false),
        'diaryEntries': <dynamic>[],
        'dailyMoods': <String, dynamic>{},
      },
    },
  );
  return store;
}

Map<String, dynamic> _localCheckHabit({
  required String id,
  required String name,
  String? remoteId,
  String? remoteUserId,
  String? updatedAt,
  Map<String, dynamic> schedule = const <String, dynamic>{'type': 'daily'},
  bool archived = false,
}) {
  return <String, dynamic>{
    'id': id,
    'habitId': id,
    'name': name,
    'type': 'check',
    'target': 1,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': schedule,
    'createdAt': '2026-06-20',
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (remoteId != null) 'remoteId': remoteId,
    if (remoteUserId != null) 'remoteUserId': remoteUserId,
    if (archived) 'archived': true,
  };
}

Map<String, dynamic> _localCountHabit({
  required String id,
  required String name,
  required num target,
  String? remoteId,
  String? remoteUserId,
}) {
  return <String, dynamic>{
    'id': id,
    'habitId': id,
    'name': name,
    'type': 'count',
    'target': target,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': const <String, dynamic>{'type': 'daily'},
    'createdAt': '2026-06-20',
    if (remoteId != null) 'remoteId': remoteId,
    if (remoteUserId != null) 'remoteUserId': remoteUserId,
  };
}

RemoteHabit _remoteCheckHabit({
  required String id,
  required String name,
  bool isArchived = false,
  DateTime? updatedAt,
  Map<String, dynamic> schedule = const <String, dynamic>{'type': 'daily'},
  bool hasExplicitSchedule = false,
}) {
  return RemoteHabit(
    id: id,
    userId: 'user-1',
    name: name,
    habitType: 'check',
    reminderEnabled: false,
    isArchived: isArchived,
    sortOrder: 0,
    schedule: schedule,
    hasExplicitSchedule: hasExplicitSchedule,
    createdAt: DateTime.utc(2026, 6, 20, 8),
    updatedAt: updatedAt,
  );
}

RemoteHabit _remoteCountHabit({
  required String id,
  required String name,
  required int targetCount,
  DateTime? updatedAt,
}) {
  return RemoteHabit(
    id: id,
    userId: 'user-1',
    name: name,
    habitType: 'count',
    targetCount: targetCount,
    unit: 'reps',
    reminderEnabled: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 6, 20, 8),
    updatedAt: updatedAt,
  );
}

String _todayKey() {
  final now = DateTime.now();
  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

Map<String, dynamic> _cloneNestedMap(Map<String, dynamic> source) {
  return <String, dynamic>{
    for (final entry in source.entries)
      entry.key: entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : entry.value,
  };
}

class _FakeHabitRepository extends HabitRepository {
  _FakeHabitRepository({
    RepositoryResult<List<RemoteHabit>>? fetchResult,
    List<RemoteHabit> fetchedHabits = const <RemoteHabit>[],
    this.fetchHandler,
  })  : _fetchResult = fetchResult,
        _fetchedHabits = fetchedHabits,
        super(
          client: SupabaseClient('https://example.com', 'anon-key'),
          currentUserIdProvider: () => 'user-1',
        );

  final RepositoryResult<List<RemoteHabit>>? _fetchResult;
  final List<RemoteHabit> _fetchedHabits;
  final Future<RepositoryResult<List<RemoteHabit>>> Function()? fetchHandler;

  int fetchCalls = 0;

  @override
  Future<RepositoryResult<List<RemoteHabit>>>
      fetchHabitsForCurrentUser() async {
    fetchCalls += 1;
    if (fetchHandler != null) {
      return fetchHandler!();
    }
    return _fetchResult ??
        RepositoryResult<List<RemoteHabit>>.success(data: _fetchedHabits);
  }
}

class _FakeHabitLogRepository extends HabitLogRepository {
  _FakeHabitLogRepository({
    this.logsByRemoteHabitId = const <String, List<RemoteHabitLog>>{},
    RepositoryResult<List<RemoteHabitLog>>? fetchResult,
  })  : _fetchResult = fetchResult,
        super(
          client: SupabaseClient('https://example.com', 'anon-key'),
          currentUserIdProvider: () => 'user-1',
        );

  final Map<String, List<RemoteHabitLog>> logsByRemoteHabitId;
  final RepositoryResult<List<RemoteHabitLog>>? _fetchResult;

  int fetchCalls = 0;
  int batchFetchCalls = 0;

  @override
  Future<RepositoryResult<List<RemoteHabitLog>>> fetchLogsForHabit(
    String habitId, {
    DateTime? start,
    DateTime? end,
  }) async {
    fetchCalls += 1;
    return _fetchResult ??
        RepositoryResult<List<RemoteHabitLog>>.success(
          data: logsByRemoteHabitId[habitId] ?? const <RemoteHabitLog>[],
        );
  }

  @override
  Future<RepositoryResult<List<RemoteHabitLog>>> fetchLogsForHabits(
    Iterable<String> habitIds, {
    DateTime? start,
    DateTime? end,
  }) async {
    batchFetchCalls += 1;
    final data = <RemoteHabitLog>[];
    for (final habitId in habitIds) {
      data.addAll(logsByRemoteHabitId[habitId] ?? const <RemoteHabitLog>[]);
    }
    return _fetchResult ??
        RepositoryResult<List<RemoteHabitLog>>.success(data: data);
  }
}

class _FakeDiaryV2SupabaseRepository extends DiaryV2SupabaseRepository {
  _FakeDiaryV2SupabaseRepository()
      : super(
          client: SupabaseClient('https://example.com', 'anon-key'),
          currentUserIdProvider: () => 'user-1',
        );
}

class _FakeStreakProtectionRepository implements StreakProtectionRepository {
  @override
  Future<RepositoryResult<void>> setHabitTimeZone(String timeZone) async {
    return const RepositoryResult<void>.success();
  }

  @override
  Future<RepositoryResult<ActivateStreakShieldRemoteResult>>
      activateStreakShield({
    required String requestId,
    required String habitId,
    required String protectedOccurrenceDate,
    required String operationId,
    required String utilityId,
  }) async {
    return RepositoryResult<ActivateStreakShieldRemoteResult>.failure(
      const RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'Not implemented in this fake.',
      ),
    );
  }

  @override
  Future<RepositoryResult<CloseMissedHabitOccurrenceRemoteResult>>
      closeMissedHabitOccurrence({
    required String requestId,
    required String habitId,
    required String logicalDate,
    required String breakId,
  }) async {
    return RepositoryResult<CloseMissedHabitOccurrenceRemoteResult>.failure(
      const RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'Not implemented in this fake.',
      ),
    );
  }

  @override
  Future<RepositoryResult<RecoverStreakBreakRemoteResult>> recoverStreakBreak({
    required String requestId,
    required String breakId,
    required String utilityId,
  }) async {
    return RepositoryResult<RecoverStreakBreakRemoteResult>.failure(
      const RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'Not implemented in this fake.',
      ),
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchArmedShieldsForCurrentUser() async {
    return const RepositoryResult<List<HabitStreakShieldRemote>>.success(
      data: <HabitStreakShieldRemote>[],
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchRecoverableBreaksForCurrentUser() async {
    return const RepositoryResult<List<HabitStreakBreakRemote>>.success(
      data: <HabitStreakBreakRemote>[],
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchShieldsForCurrentUser() async {
    return const RepositoryResult<List<HabitStreakShieldRemote>>.success(
      data: <HabitStreakShieldRemote>[],
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchBreaksForCurrentUser() async {
    return const RepositoryResult<List<HabitStreakBreakRemote>>.success(
      data: <HabitStreakBreakRemote>[],
    );
  }
}
