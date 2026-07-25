import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/models/remote/remote_habit.dart';
import 'package:rutio/data/models/remote/remote_habit_log.dart';
import 'package:rutio/data/repositories/habit_log_repository.dart';
import 'package:rutio/data/repositories/habit_repository.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/habits/data/cloud/device_time_zone_provider.dart';
import 'package:rutio/features/habits/data/cloud/streak_protection_remote_models.dart';
import 'package:rutio/features/habits/data/cloud/streak_protection_repository.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore streak protection remote sync', () {
    test('does not resend the timezone when it has not changed', () async {
      final repository = _FakeStreakProtectionRepository();
      final provider = _FakeDeviceTimeZoneProvider('Europe/Madrid');
      final fixture = await _createFixture(
        repository: repository,
        provider: provider,
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();
      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(repository.timeZoneCalls, <String>['Europe/Madrid']);
    });

    test('simulated calendar skips remote close mutations', () async {
      final repository = _FakeStreakProtectionRepository();
      final provider = _FakeDeviceTimeZoneProvider('Europe/Madrid');
      final fixture = await _createFixture(
        repository: repository,
        provider: provider,
        calendarNowProvider: () => DateTime(2026, 7, 26, 10),
        nowProvider: () => DateTime(2026, 7, 25, 10),
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(repository.closeCalls, isEmpty);
    });

    test('updates the timezone when the device zone changes', () async {
      final repository = _FakeStreakProtectionRepository();
      final provider = _FakeDeviceTimeZoneProvider('Europe/Madrid');
      final fixture = await _createFixture(
        repository: repository,
        provider: provider,
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();
      provider.timeZone = 'Asia/Tokyo';
      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(repository.timeZoneCalls, <String>['Europe/Madrid', 'Asia/Tokyo']);
    });

    test('timezone persists when shield download fails', () async {
      final repository = _FakeStreakProtectionRepository(
        failShieldFetch: true,
      );
      final provider = _FakeDeviceTimeZoneProvider('Europe/Madrid');
      final fixture = await _createFixture(
        repository: repository,
        provider: provider,
        initialLastSyncedTimeZone: 'Asia/Tokyo',
        initialShieldCache: <String, dynamic>{
          'habit-1': _remoteShieldCacheJson(
            id: 'remote-shield-old',
            status: 'armed',
            protectedDateKey: '2026-07-24',
            activatedAtKey: '2026-07-24',
          ),
        },
        initialBreakCache: <String, dynamic>{
          'local-break': _localBreakCacheJson(status: 'recoverable'),
        },
        nowProvider: () => DateTime(2026, 7, 24, 12),
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      final userState = fixture.store.state!['userState'] as Map;
      final meta = userState['meta'] as Map;
      expect(repository.timeZoneCalls, <String>['Europe/Madrid']);
      expect(repository.shieldFetchCalls, 1);
      expect(repository.breakFetchCalls, 0);
      expect(meta['lastSyncedHabitTimeZone'], 'Europe/Madrid');
      expect(_history(fixture.store)['habitStreakShields']['habit-1']['id'],
          'remote-shield-old');
      expect(_history(fixture.store)['habitStreakBreaks']['local-break']['id'],
          'local-break');
    });

    test('timezone persists when break download fails', () async {
      final repository = _FakeStreakProtectionRepository(
        failBreakFetch: true,
        shields: <HabitStreakShieldRemote>[
          _remoteShield(
            id: 'remote-shield',
            habitId: _remoteHabitId,
            status: 'consumed',
            protectedDate: DateTime(2026, 7, 25),
          ),
        ],
      );
      final provider = _FakeDeviceTimeZoneProvider('Europe/Madrid');
      final fixture = await _createFixture(
        repository: repository,
        provider: provider,
        initialLastSyncedTimeZone: 'Asia/Tokyo',
        initialShieldCache: <String, dynamic>{
          'habit-1': _remoteShieldCacheJson(
            id: 'remote-shield-old',
            status: 'armed',
            protectedDateKey: '2026-07-24',
            activatedAtKey: '2026-07-24',
          ),
        },
        initialBreakCache: <String, dynamic>{
          'local-break': _localBreakCacheJson(status: 'recoverable'),
        },
        nowProvider: () => DateTime(2026, 7, 24, 12),
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      final userState = fixture.store.state!['userState'] as Map;
      final meta = userState['meta'] as Map;
      expect(repository.timeZoneCalls, <String>['Europe/Madrid']);
      expect(repository.shieldFetchCalls, 1);
      expect(repository.breakFetchCalls, 1);
      expect(meta['lastSyncedHabitTimeZone'], 'Europe/Madrid');
      expect(_history(fixture.store)['habitStreakShields']['habit-1']['id'],
          'remote-shield-old');
      expect(_history(fixture.store)['habitStreakShields']['habit-1']['status'],
          'armed');
      expect(_history(fixture.store)['habitStreakBreaks']['local-break']['id'],
          'local-break');
    });

    test('two concurrent calls execute a single download', () async {
      final shieldsGate = Completer<void>();
      final breaksGate = Completer<void>();
      final repository = _FakeStreakProtectionRepository(
        shieldsGate: shieldsGate.future,
        breaksGate: breaksGate.future,
        shields: <HabitStreakShieldRemote>[
          _remoteShield(
            id: 'remote-shield',
            habitId: _remoteHabitId,
            status: 'armed',
            protectedDate: DateTime(2026, 7, 25),
          ),
        ],
      );
      final fixture = await _createFixture(
        repository: repository,
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
      );

      var secondCompleted = false;
      final first = fixture.store.syncStreakProtectionFromRemoteBestEffort();
      await _waitUntil(() => repository.shieldFetchCalls == 1);
      final second = fixture.store
          .syncStreakProtectionFromRemoteBestEffort()
          .then((_) => secondCompleted = true);

      await Future<void>.delayed(Duration.zero);
      expect(secondCompleted, isFalse);
      expect(repository.shieldFetchCalls, 1);
      expect(repository.breakFetchCalls, 0);

      shieldsGate.complete();
      await _waitUntil(() => repository.breakFetchCalls == 1);
      breaksGate.complete();
      await Future.wait(<Future<void>>[first, second]);

      expect(secondCompleted, isTrue);
      expect(repository.shieldFetchCalls, 1);
      expect(repository.breakFetchCalls, 1);
    });

    test('habit refresh and direct sync share one snapshot fetch', () async {
      final shieldsGate = Completer<void>();
      final breaksGate = Completer<void>();
      final repository = _FakeStreakProtectionRepository(
        shieldsGate: shieldsGate.future,
        breaksGate: breaksGate.future,
        shields: <HabitStreakShieldRemote>[
          _remoteShield(
            id: 'remote-shield',
            habitId: _remoteHabitId,
            status: 'armed',
            protectedDate: DateTime(2026, 7, 25),
          ),
        ],
        breaks: <HabitStreakBreakRemote>[
          _remoteBreak(
            id: 'remote-row',
            breakId: 'remote-break',
            habitId: _remoteHabitId,
            status: 'recoverable',
            missedDate: DateTime(2026, 7, 24),
          ),
        ],
      );
      final fixture = await _createFixture(
        repository: repository,
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
        habitRepository: _FakeHabitRepository(
          <RemoteHabit>[
            _remoteHabit(),
          ],
        ),
        habitLogRepository: _FakeHabitLogRepository(),
      );

      var directCompleted = false;
      final refresh = fixture.store.syncHabitsFromRemoteBestEffort();
      await _waitUntil(() => repository.shieldFetchCalls == 1);
      final direct = fixture.store
          .syncStreakProtectionFromRemoteBestEffort()
          .then((_) => directCompleted = true);

      await Future<void>.delayed(Duration.zero);
      expect(directCompleted, isFalse);
      expect(repository.shieldFetchCalls, 1);
      expect(repository.breakFetchCalls, 0);

      shieldsGate.complete();
      await _waitUntil(() => repository.breakFetchCalls == 1);
      breaksGate.complete();
      await Future.wait(<Future<void>>[refresh, direct]);

      expect(directCompleted, isTrue);
      expect(repository.shieldFetchCalls, 1);
      expect(repository.breakFetchCalls, 1);
      final history = _history(fixture.store);
      expect(history['habitStreakShields']['habit-1']['id'], 'remote-shield');
      expect(history['habitStreakBreaks']['remote-break']['remoteId'],
          'remote-row');
    });

    test('snapshot Future is cleared after success and error', () async {
      final successRepository = _FakeStreakProtectionRepository();
      final successFixture = await _createFixture(
        repository: successRepository,
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
      );

      await successFixture.store.syncStreakProtectionFromRemoteBestEffort();
      await successFixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(successRepository.shieldFetchCalls, 2);
      expect(successRepository.breakFetchCalls, 2);

      final errorRepository = _FakeStreakProtectionRepository(
        failShieldFetch: true,
      );
      final errorFixture = await _createFixture(
        repository: errorRepository,
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
      );

      await errorFixture.store.syncStreakProtectionFromRemoteBestEffort();
      await errorFixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(errorRepository.shieldFetchCalls, 2);
      expect(errorRepository.breakFetchCalls, 0);
    });

    test('AuthController does not launch a second streak protection sync',
        () async {
      final authSource = await File('lib/application/auth/auth_controller.dart')
          .readAsString();
      final habitRefreshSource =
          await File('lib/stores/user_state_store_habits.dart').readAsString();

      expect(authSource, isNot(contains('syncStreakProtectionFromRemote')));
      expect(
          habitRefreshSource, contains('_syncStreakProtectionIntoUserState'));
    });

    test('reconciles by habit and date with cloud winning', () async {
      final repository = _FakeStreakProtectionRepository(
        shields: <HabitStreakShieldRemote>[
          _remoteShield(
            id: 'remote-shield',
            habitId: _remoteHabitId,
            status: 'consumed',
            protectedDate: DateTime(2026, 7, 24),
          ),
        ],
        breaks: <HabitStreakBreakRemote>[
          _remoteBreak(
            id: 'remote-row',
            breakId: 'remote-break',
            habitId: _remoteHabitId,
            status: 'recovered',
            missedDate: DateTime(2026, 7, 23),
          ),
        ],
      );
      final fixture = await _createFixture(
        repository: repository,
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
        localShieldStatus: 'armed',
        localBreakStatus: 'recoverable',
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      final history = _history(fixture.store);
      final shields = history['habitStreakShields'] as Map;
      final breaks = history['habitStreakBreaks'] as Map;
      expect(shields['habit-1']['id'], 'remote-shield');
      expect(shields['habit-1']['status'], 'consumed');
      expect(shields['habit-1']['requestId'], 'request-remote-shield');
      expect(shields['habit-1']['operationId'], 'operation-remote-shield');
      expect(breaks.containsKey('local-break'), isFalse);
      expect(breaks['remote-break']['status'], 'recovered');
      expect(breaks['remote-break']['habitId'], 'habit-1');
      expect(breaks['remote-break']['requestId'], 'request-remote-row');
      expect(
        breaks['remote-break']['recoveryRequestId'],
        'recovery-remote-row',
      );
    });

    test('empty remote data is compatible with users without cloud rows',
        () async {
      final fixture = await _createFixture(
        repository: _FakeStreakProtectionRepository(),
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(_history(fixture.store)['habitStreakShields'], isEmpty);
      expect(_history(fixture.store)['habitStreakBreaks'], isEmpty);
    });

    test('removed remote shield disappears from cache', () async {
      final fixture = await _createFixture(
        repository: _FakeStreakProtectionRepository(),
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
        initialLastSyncedTimeZone: 'Europe/Madrid',
        initialShieldCache: <String, dynamic>{
          'habit-1': _remoteShieldCacheJson(id: 'remote-shield-old'),
        },
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(_history(fixture.store)['habitStreakShields'], isEmpty);
    });

    test('removed remote break disappears from cache', () async {
      final fixture = await _createFixture(
        repository: _FakeStreakProtectionRepository(),
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
        initialLastSyncedTimeZone: 'Europe/Madrid',
        initialBreakCache: <String, dynamic>{
          'remote-break-old': _remoteBreakCacheJson(
            breakId: 'remote-break-old',
            remoteId: 'remote-row-old',
          ),
        },
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(_history(fixture.store)['habitStreakBreaks'], isEmpty);
    });

    test('legacy local records are preserved when remote snapshot is empty',
        () async {
      final fixture = await _createFixture(
        repository: _FakeStreakProtectionRepository(),
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
        initialLastSyncedTimeZone: 'Europe/Madrid',
        localShieldStatus: 'armed',
        localBreakStatus: 'recoverable',
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      final history = _history(fixture.store);
      expect(history['habitStreakShields']['habit-1']['id'], 'local-shield');
      expect(history['habitStreakBreaks']['local-break']['id'], 'local-break');
    });

    test('failure of one download does not apply a partial snapshot', () async {
      final fixture = await _createFixture(
        repository: _FakeStreakProtectionRepository(
          failBreakFetch: true,
          shields: <HabitStreakShieldRemote>[
            _remoteShield(
              id: 'remote-shield-new',
              habitId: _remoteHabitId,
              status: 'consumed',
              protectedDate: DateTime(2026, 7, 25),
            ),
          ],
        ),
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
        initialLastSyncedTimeZone: 'Europe/Madrid',
        initialShieldCache: <String, dynamic>{
          'habit-1': _remoteShieldCacheJson(id: 'remote-shield-old'),
        },
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      final shields = _history(fixture.store)['habitStreakShields'] as Map;
      expect(shields['habit-1']['id'], 'remote-shield-old');
      expect(shields['habit-1']['status'], 'armed');
    });

    test('network error keeps the local cache intact', () async {
      final fixture = await _createFixture(
        repository: _FakeStreakProtectionRepository(failShieldFetch: true),
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
        localShieldStatus: 'armed',
        localBreakStatus: 'recoverable',
      );

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      final history = _history(fixture.store);
      expect(history['habitStreakShields']['habit-1']['id'], 'local-shield');
      expect(
        history['habitStreakBreaks']['local-break']['status'],
        'recoverable',
      );
    });

    test('notifies and saves once for a successful snapshot', () async {
      final repository = _FakeStreakProtectionRepository(
        shields: <HabitStreakShieldRemote>[
          _remoteShield(
            id: 'remote-shield',
            habitId: _remoteHabitId,
            status: 'armed',
            protectedDate: DateTime(2026, 7, 25),
          ),
        ],
      );
      final fixture = await _createFixture(
        repository: repository,
        provider: _FakeDeviceTimeZoneProvider('Europe/Madrid'),
      );
      var notifications = 0;
      fixture.store.addListener(() => notifications += 1);
      fixture.repository.saveCalls = 0;

      await fixture.store.syncStreakProtectionFromRemoteBestEffort();

      expect(notifications, 1);
      expect(fixture.repository.saveCalls, 1);
    });
  });
}

const String _remoteHabitId = '11111111-1111-4111-8111-111111111111';

Future<_StoreFixture> _createFixture({
  required _FakeStreakProtectionRepository repository,
  required DeviceTimeZoneProvider provider,
  HabitRepository? habitRepository,
  HabitLogRepository? habitLogRepository,
  DateTime Function()? nowProvider,
  DateTime Function()? calendarNowProvider,
  Map<String, dynamic>? occurrenceStatuses,
  String? localShieldStatus,
  String? localBreakStatus,
  String? initialLastSyncedTimeZone,
  Map<String, dynamic>? initialShieldCache,
  Map<String, dynamic>? initialBreakCache,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final stateRepository =
      _CountingUserStateRepository(storage: UserStateStorage())
        ..setActiveUserScope('cloud-user');
  final store = UserStateStore(
    stateRepository,
    journalEntrySyncService: JournalEntrySyncService(),
    habitRepository: habitRepository,
    habitLogRepository: habitLogRepository,
    streakProtectionRepository: repository,
    deviceTimeZoneProvider: provider,
    currentSupabaseUserIdProvider: () => 'cloud-user',
    nowProvider: nowProvider ?? () => DateTime(2026, 7, 25, 12),
    calendarNowProvider: calendarNowProvider,
  );

  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'cloud-user',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        if (initialLastSyncedTimeZone != null)
          'lastSyncedHabitTimeZone': initialLastSyncedTimeZone,
        'diaryRewardAppliedDateKeys': <dynamic>[],
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
        'lastResetDate': '2026-07-25',
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
        'habitOccurrenceStatuses': Map<String, dynamic>.from(
            occurrenceStatuses ?? const <String, dynamic>{}),
        'habitStreakShields': initialShieldCache ??
            (localShieldStatus == null
                ? <String, dynamic>{}
                : <String, dynamic>{
                    'habit-1': <String, dynamic>{
                      'id': 'local-shield',
                      'userId': 'cloud-user',
                      'habitId': 'habit-1',
                      'utilityId': 'utility_streak_shield_1',
                      'activatedAtMillis': 1,
                      'protectedOccurrenceDateKey': '2026-07-24',
                      'status': localShieldStatus,
                    },
                  }),
        'habitStreakBreaks': initialBreakCache ??
            (localBreakStatus == null
                ? <String, dynamic>{}
                : <String, dynamic>{
                    'local-break': <String, dynamic>{
                      'id': 'local-break',
                      'userId': 'cloud-user',
                      'habitId': 'habit-1',
                      'brokenAtMillis': 1,
                      'missedOccurrenceDateKey': '2026-07-23',
                      'previousStreak': 3,
                      'currentStreakAfterBreak': 0,
                      'status': localBreakStatus,
                      'shieldProtected': false,
                    },
                  }),
      },
      'familyXp': <String, dynamic>{},
      'activeHabits': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'habit-1',
          'title': 'Leer',
          'remoteId': _remoteHabitId,
        },
      ],
    },
  });
  return _StoreFixture(store: store, repository: stateRepository);
}

RemoteHabit _remoteHabit() {
  return RemoteHabit(
    id: _remoteHabitId,
    userId: 'cloud-user',
    name: 'Leer',
    habitType: 'check',
    reminderEnabled: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 7, 20),
  );
}

Map<String, dynamic> _history(UserStateStore store) {
  final root = store.state!;
  final userState = root['userState'] as Map;
  return Map<String, dynamic>.from(userState['history'] as Map);
}

Map<String, dynamic> _remoteShieldCacheJson({
  required String id,
  String status = 'armed',
  String protectedDateKey = '2026-07-25',
  String activatedAtKey = '2026-07-25',
}) {
  return <String, dynamic>{
    'id': id,
    'userId': 'cloud-user',
    'habitId': 'habit-1',
    'utilityId': 'utility_streak_shield_1',
    'activatedAtMillis':
        DateTime.parse('${activatedAtKey}T08:00:00Z').millisecondsSinceEpoch,
    'protectedOccurrenceDateKey': protectedDateKey,
    'status': status,
    'remoteHabitId': _remoteHabitId,
    'effectId': 'effect-old',
    'logicalTimeZone': 'Europe/Madrid',
  };
}

Map<String, dynamic> _localBreakCacheJson({required String status}) {
  return <String, dynamic>{
    'id': 'local-break',
    'userId': 'cloud-user',
    'habitId': 'habit-1',
    'brokenAtMillis': DateTime.utc(2026, 7, 24).millisecondsSinceEpoch,
    'missedOccurrenceDateKey': '2026-07-24',
    'previousStreak': 3,
    'currentStreakAfterBreak': 0,
    'status': status,
    'shieldProtected': false,
  };
}

Map<String, dynamic> _remoteBreakCacheJson({
  required String breakId,
  required String remoteId,
}) {
  return <String, dynamic>{
    'id': breakId,
    'userId': 'cloud-user',
    'habitId': 'habit-1',
    'brokenAtMillis': DateTime.utc(2026, 7, 24, 8).millisecondsSinceEpoch,
    'missedOccurrenceDateKey': '2026-07-23',
    'previousStreak': 3,
    'currentStreakAfterBreak': 0,
    'status': 'recoverable',
    'shieldProtected': false,
    'remoteId': remoteId,
    'remoteHabitId': _remoteHabitId,
    'logicalTimeZone': 'Europe/Madrid',
  };
}

HabitStreakShieldRemote _remoteShield({
  required String id,
  required String habitId,
  required String status,
  required DateTime protectedDate,
}) {
  return HabitStreakShieldRemote(
    id: id,
    requestId: 'request-$id',
    operationId: 'operation-$id',
    habitId: habitId,
    utilityId: 'utility_streak_shield_1',
    effectId: 'effect-1',
    logicalTimeZone: 'Europe/Madrid',
    protectedOccurrenceDate: protectedDate,
    status: status,
    activatedAt: DateTime.utc(2026, 7, 25, 8),
  );
}

HabitStreakBreakRemote _remoteBreak({
  required String id,
  required String breakId,
  required String habitId,
  required String status,
  required DateTime missedDate,
}) {
  return HabitStreakBreakRemote(
    id: id,
    requestId: 'request-$id',
    recoveryRequestId: 'recovery-$id',
    breakId: breakId,
    habitId: habitId,
    logicalTimeZone: 'Europe/Madrid',
    missedOccurrenceDate: missedDate,
    previousStreak: 7,
    currentStreakAfterBreak: 0,
    status: status,
    brokenAt: DateTime.utc(2026, 7, 24, 8),
    recoverableUntil: DateTime.utc(2026, 7, 25, 22),
    recoveredAt: status == 'recovered' ? DateTime.utc(2026, 7, 25, 9) : null,
  );
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for condition.');
}

class _StoreFixture {
  const _StoreFixture({required this.store, required this.repository});

  final UserStateStore store;
  final _CountingUserStateRepository repository;
}

class _CountingUserStateRepository extends UserStateRepository {
  _CountingUserStateRepository({required super.storage});

  int saveCalls = 0;

  @override
  Future<void> save(Map<String, dynamic> userStateJson) async {
    saveCalls += 1;
    await super.save(userStateJson);
  }
}

SupabaseClient _fakeSupabaseClient() {
  return SupabaseClient(
    'https://example.supabase.co',
    'public-anon-key',
  );
}

class _FakeHabitRepository extends HabitRepository {
  _FakeHabitRepository(this.habits) : super(client: _fakeSupabaseClient());

  final List<RemoteHabit> habits;
  int fetchCalls = 0;

  @override
  Future<RepositoryResult<List<RemoteHabit>>>
      fetchHabitsForCurrentUser() async {
    fetchCalls += 1;
    return RepositoryResult<List<RemoteHabit>>.success(data: habits);
  }
}

class _FakeHabitLogRepository extends HabitLogRepository {
  _FakeHabitLogRepository() : super(client: _fakeSupabaseClient());

  int fetchCalls = 0;

  @override
  Future<RepositoryResult<List<RemoteHabitLog>>> fetchLogsForHabit(
    String habitId, {
    DateTime? start,
    DateTime? end,
  }) async {
    fetchCalls += 1;
    return const RepositoryResult<List<RemoteHabitLog>>.success(
      data: <RemoteHabitLog>[],
    );
  }
}

class _FakeDeviceTimeZoneProvider implements DeviceTimeZoneProvider {
  _FakeDeviceTimeZoneProvider(this.timeZone);

  String? timeZone;

  @override
  Future<String?> getLocalIanaTimeZone() async => timeZone;
}

class _FakeStreakProtectionRepository implements StreakProtectionRepository {
  _FakeStreakProtectionRepository({
    this.shields = const <HabitStreakShieldRemote>[],
    this.breaks = const <HabitStreakBreakRemote>[],
    this.failShieldFetch = false,
    this.failBreakFetch = false,
    this.shieldsGate,
    this.breaksGate,
  });

  final List<HabitStreakShieldRemote> shields;
  final List<HabitStreakBreakRemote> breaks;
  final bool failShieldFetch;
  final bool failBreakFetch;
  final Future<void>? shieldsGate;
  final Future<void>? breaksGate;
  final List<String> timeZoneCalls = <String>[];
  final List<Map<String, String>> closeCalls = <Map<String, String>>[];
  int shieldFetchCalls = 0;
  int breakFetchCalls = 0;

  @override
  Future<RepositoryResult<void>> setHabitTimeZone(String timeZone) async {
    timeZoneCalls.add(timeZone);
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
    return const RepositoryResult<ActivateStreakShieldRemoteResult>.failure(
      RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'not implemented by sync fake',
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
    closeCalls.add(<String, String>{
      'requestId': requestId,
      'habitId': habitId,
      'logicalDate': logicalDate,
      'breakId': breakId,
    });
    return const RepositoryResult<
        CloseMissedHabitOccurrenceRemoteResult>.failure(
      RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'not implemented by sync fake',
      ),
    );
  }

  @override
  Future<RepositoryResult<RecoverStreakBreakRemoteResult>> recoverStreakBreak({
    required String requestId,
    required String breakId,
    required String utilityId,
  }) async {
    return const RepositoryResult<RecoverStreakBreakRemoteResult>.failure(
      RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'not implemented by sync fake',
      ),
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchShieldsForCurrentUser() async {
    shieldFetchCalls += 1;
    await shieldsGate;
    if (failShieldFetch) {
      return const RepositoryResult<List<HabitStreakShieldRemote>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.network,
          message: 'offline',
        ),
      );
    }
    return RepositoryResult<List<HabitStreakShieldRemote>>.success(
      data: shields,
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchArmedShieldsForCurrentUser() async {
    return RepositoryResult<List<HabitStreakShieldRemote>>.success(
      data: shields.where((shield) => shield.isArmed).toList(growable: false),
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchBreaksForCurrentUser() async {
    breakFetchCalls += 1;
    await breaksGate;
    if (failBreakFetch) {
      return const RepositoryResult<List<HabitStreakBreakRemote>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.network,
          message: 'offline',
        ),
      );
    }
    return RepositoryResult<List<HabitStreakBreakRemote>>.success(data: breaks);
  }

  @override
  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchRecoverableBreaksForCurrentUser() async {
    return RepositoryResult<List<HabitStreakBreakRemote>>.success(
      data: breaks.where((streakBreak) => streakBreak.isRecoverable).toList(
            growable: false,
          ),
    );
  }
}
