import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/habits/data/cloud/device_time_zone_provider.dart';
import 'package:rutio/features/habits/data/cloud/streak_protection_remote_models.dart';
import 'package:rutio/features/habits/data/cloud/streak_protection_repository.dart';
import 'package:rutio/features/habits/domain/models/streak_recover_operation_result.dart';
import 'package:rutio/features/habits/domain/models/streak_shield_operation_result.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Streak Protection atomic RPCs', () {
    test('close RPC uses p_logical_date exactly', () {
      final params = buildCloseMissedHabitOccurrenceRpcParams(
        requestId: 'req-1',
        habitId: 'habit-1',
        logicalDate: '2026-07-24',
        breakId: 'break-1',
      );

      expect(params, containsPair('p_request_id', 'req-1'));
      expect(params, containsPair('p_habit_id', 'habit-1'));
      expect(params, containsPair('p_logical_date', '2026-07-24'));
      expect(params, containsPair('p_break_id', 'break-1'));
      expect(params.containsKey('p_missed_occurrence_date'), isFalse);
    });

    test('activacion cloud guarda el shield remoto y usa IDs estables',
        () async {
      final now = DateTime(2026, 7, 24, 10);
      final repository = _FakeStreakProtectionRepository();
      final store = await _createStore(
        repository: repository,
        nowProvider: () => now,
      );

      final result = await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'op-1',
      );

      expect(result.status, StreakShieldOperationStatus.success);
      expect(repository.activateCalls, hasLength(1));
      expect(
        repository.activateCalls.single['requestId'],
        startsWith(
          'streak-shield:11111111-1111-4111-8111-111111111111:op-1:2026-07-24:',
        ),
      );
      expect(repository.activateCalls.single['operationId'], 'op-1');
      expect(store.activeStreakShieldForHabit('habit-1')?.id,
          'remote-shield-op-1');
    });

    test('shield retry after midnight reuses the persisted requestId',
        () async {
      var now = DateTime(2026, 7, 24, 10);
      final repository = _FakeStreakProtectionRepository()..failActivate = true;
      final store = await _createStore(
        repository: repository,
        nowProvider: () => now,
      );

      final first = await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-retry',
      );

      expect(first.status, StreakShieldOperationStatus.persistenceFailure);
      expect(repository.activateCalls, hasLength(1));

      now = DateTime(2026, 7, 25, 10);
      repository.failActivate = false;
      final second = await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-retry',
      );

      expect(second.status, StreakShieldOperationStatus.success);
      expect(repository.activateCalls, hasLength(2));
      expect(repository.activateCalls[0]['requestId'],
          repository.activateCalls[1]['requestId']);
      expect(repository.activateCalls[0]['date'], '2026-07-24');
      expect(repository.activateCalls[1]['date'], '2026-07-24');
    });

    test('error cloud de activacion conserva la cache local', () async {
      final repository = _FakeStreakProtectionRepository()..failActivate = true;
      final store = await _createStore(repository: repository);

      final result = await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'op-fail',
      );

      expect(result.status, StreakShieldOperationStatus.persistenceFailure);
      expect(store.activeStreakShieldForHabit('habit-1'), isNull);
      expect(repository.activateCalls, hasLength(1));
    });

    test('simulated calendar skips cloud shield activation', () async {
      final repository = _FakeStreakProtectionRepository();
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 10),
        calendarNowProvider: () => DateTime(2026, 7, 26, 10),
      );

      final result = await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'op-simulated',
      );

      expect(result.status, StreakShieldOperationStatus.success);
      expect(repository.activateCalls, isEmpty);
      expect(result.shield, isNotNull);
    });

    test('armed shield allows the remote close RPC to run', () async {
      final repository = _FakeStreakProtectionRepository();
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-25',
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
        initialShieldCache: <String, dynamic>{
          'habit-1': _remoteShieldCacheJson(status: 'armed'),
        },
      );

      await store.syncStreakProtectionFromRemoteBestEffort();

      expect(repository.closeCalls, hasLength(1));
    });

    test('consumed shield avoids the duplicate close RPC', () async {
      final repository = _FakeStreakProtectionRepository();
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-25',
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
        initialShieldCache: <String, dynamic>{
          'habit-1': _remoteShieldCacheJson(status: 'consumed'),
        },
      );

      await store.syncStreakProtectionFromRemoteBestEffort();

      expect(repository.closeCalls, isEmpty);
    });

    test('expired shield still allows the remote close RPC', () async {
      final repository = _FakeStreakProtectionRepository();
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-25',
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
        initialShieldCache: <String, dynamic>{
          'habit-1': _remoteShieldCacheJson(status: 'expired'),
        },
      );

      await store.syncStreakProtectionFromRemoteBestEffort();

      expect(repository.closeCalls, hasLength(1));
    });

    test('failed close leaves the local cache unchanged', () async {
      final repository = _FakeStreakProtectionRepository(failClose: true);
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-25',
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
        initialShieldCache: <String, dynamic>{
          'habit-1': _localShieldCacheJson(
            status: 'armed',
            protectedDateKey: '2026-07-25',
            activatedAtKey: '2026-07-25',
          ),
        },
        initialBreakCache: <String, dynamic>{
          'local-break': _localBreakCacheJson(status: 'recoverable'),
        },
      );

      await store.syncStreakProtectionFromRemoteBestEffort();

      final history = _history(store);
      expect(history['habitStreakShields']['habit-1']['status'], 'armed');
      expect(
          history['habitStreakBreaks']['local-break']['status'], 'recoverable');
    });

    test('authenticated reset does not consume a remote shield locally',
        () async {
      final repository = _FakeStreakProtectionRepository(failClose: true);
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-24',
        initialShieldCache: <String, dynamic>{
          'habit-1': _remoteShieldCacheJson(
            status: 'armed',
            protectedDateKey: '2026-07-25',
            activatedAtKey: '2026-07-25',
          ),
        },
        initialBreakCache: const <String, dynamic>{},
      );

      await store.load();

      final history = _history(store);
      expect(
        history['habitOccurrenceStatuses']['2026-07-24']['habit-1'],
        'missed',
      );
      expect(history['habitStreakShields']['habit-1']['status'], 'armed');
      expect(history['habitStreakBreaks'], isEmpty);
    });

    test('load does not wait for the remote close RPC', () async {
      final closeGate = Completer<void>();
      final repository = _FakeStreakProtectionRepository(
        closeGate: closeGate.future,
      );
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-24',
      );

      await store.load().timeout(const Duration(seconds: 1));

      expect(repository.closeCalls, isEmpty);
      expect(closeGate.isCompleted, isFalse);
    });

    test('concurrent close sync calls share one Future and one RPC', () async {
      final closeGate = Completer<void>();
      final repository = _FakeStreakProtectionRepository(
        closeGate: closeGate.future,
      );
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-25',
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
      );

      final first = store.syncStreakProtectionFromRemoteBestEffort();
      await _waitUntil(() => repository.closeCalls.length == 1);
      final second = store.syncStreakProtectionFromRemoteBestEffort();

      await Future<void>.delayed(Duration.zero);
      expect(repository.closeCalls, hasLength(1));

      closeGate.complete();
      await Future.wait(<Future<void>>[first, second]);

      expect(repository.closeCalls, hasLength(1));
    });

    test('close success is preserved even when the snapshot fails', () async {
      final repository = _FakeStreakProtectionRepository(
        failShieldFetch: true,
      )..closeStatus = CloseMissedHabitOccurrenceRemoteStatus.shieldConsumed;
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-25',
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
        initialShieldCache: <String, dynamic>{
          'habit-1': _localShieldCacheJson(
            status: 'armed',
            protectedDateKey: '2026-07-25',
            activatedAtKey: '2026-07-25',
          ),
        },
      );

      await store.syncStreakProtectionFromRemoteBestEffort();

      final history = _history(store);
      expect(repository.closeCalls, hasLength(1));
      expect(history['habitStreakShields']['habit-1']['status'], 'consumed');
    });

    test('cierre cloud usa IDs deterministas y crea break remoto', () async {
      final repository = _FakeStreakProtectionRepository();
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        lastResetDate: '2026-07-25',
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
      );

      await store.syncStreakProtectionFromRemoteBestEffort();

      expect(repository.closeCalls, hasLength(1));
      expect(repository.closeCalls.single['requestId'],
          'streak-close:11111111-1111-4111-8111-111111111111:2026-07-24');
      expect(repository.closeCalls.single['breakId'],
          'streak-break:11111111-1111-4111-8111-111111111111:2026-07-24');
      expect(store.recoverableStreakBreaks.single.id,
          'streak-break:11111111-1111-4111-8111-111111111111:2026-07-24');
    });

    test('cierre already_continuous elimina la rotura local provisional',
        () async {
      final repository = _FakeStreakProtectionRepository()
        ..closeStatus =
            CloseMissedHabitOccurrenceRemoteStatus.alreadyContinuous;
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 0, 1),
        occurrenceStatuses: <String, dynamic>{
          '2026-07-24': <String, dynamic>{'habit-1': 'missed'},
        },
      );

      await store.syncStreakProtectionFromRemoteBestEffort();

      expect(repository.closeCalls, hasLength(1));
      expect(store.recoverableStreakBreaks, isEmpty);
    });

    test('recover retry reuses the same requestId', () async {
      final repository = _FakeStreakProtectionRepository()..failRecover = true;
      final store = await _createStore(
        repository: repository,
        recoverableBreaks: <String, dynamic>{
          'remote-break-1': _remoteBreakLocalJson(status: 'recoverable'),
        },
      );

      final first = await store.recoverStreakBreak(
        breakId: 'remote-break-1',
        operationId: 'recover-retry',
      );
      expect(first.status, StreakRecoverOperationStatus.persistenceFailure);
      expect(repository.recoverCalls, hasLength(1));

      repository.failRecover = false;
      final second = await store.recoverStreakBreak(
        breakId: 'remote-break-1',
        operationId: 'recover-retry',
      );
      expect(second.status, StreakRecoverOperationStatus.success);
      expect(repository.recoverCalls, hasLength(2));
      expect(repository.recoverCalls[0]['requestId'],
          repository.recoverCalls[1]['requestId']);
      expect(
        repository.recoverCalls[1]['requestId'],
        startsWith('streak-recover:remote-break-1:recover-retry:'),
      );
    });

    test('recuperacion cloud aplica recovered y expired desde Supabase',
        () async {
      final repository = _FakeStreakProtectionRepository();
      final store = await _createStore(
        repository: repository,
        recoverableBreaks: <String, dynamic>{
          'remote-break-1': _remoteBreakLocalJson(status: 'recoverable'),
        },
      );

      final recovered = await store.recoverStreakBreak(
        breakId: 'remote-break-1',
        operationId: 'recover-1',
      );

      expect(recovered.status, StreakRecoverOperationStatus.success);
      expect(repository.recoverCalls.single['requestId'],
          startsWith('streak-recover:remote-break-1:recover-1:'));
      expect(store.recoverableStreakBreaks.single.isRecovered, isTrue);

      repository.recoverStatus = 'expired';
      final expiredStore = await _createStore(
        repository: repository,
        resetPrefs: true,
        recoverableBreaks: <String, dynamic>{
          'remote-break-1': _remoteBreakLocalJson(status: 'recoverable'),
        },
      );
      final expired = await expiredStore.recoverStreakBreak(
        breakId: 'remote-break-1',
        operationId: 'recover-2',
      );

      expect(expired.status, StreakRecoverOperationStatus.recoveryExpired);
      expect(_cachedBreakStatus(expiredStore, 'remote-break-1'), 'expired');
    });

    test('simulated calendar skips cloud break recovery', () async {
      final repository = _FakeStreakProtectionRepository();
      final store = await _createStore(
        repository: repository,
        nowProvider: () => DateTime(2026, 7, 25, 10),
        calendarNowProvider: () => DateTime(2026, 7, 26, 10),
        recoverableBreaks: <String, dynamic>{
          'remote-break-1': _remoteBreakLocalJson(status: 'recoverable'),
        },
      );

      final result = await store.recoverStreakBreak(
        breakId: 'remote-break-1',
        operationId: 'recover-simulated',
      );

      expect(result.status, StreakRecoverOperationStatus.success);
      expect(repository.recoverCalls, isEmpty);
      expect(result.recoveredBreak?.isRecovered, isTrue);
    });
  });
}

String? _cachedBreakStatus(UserStateStore store, String breakId) {
  final state = store.state?['userState'];
  if (state is! Map) return null;
  final history = state['history'];
  if (history is! Map) return null;
  final breaks = history['habitStreakBreaks'];
  if (breaks is! Map) return null;
  final entry = breaks[breakId];
  if (entry is! Map) return null;
  return entry['status']?.toString();
}

Future<UserStateStore> _createStore({
  required _FakeStreakProtectionRepository repository,
  DateTime Function()? nowProvider,
  DateTime Function()? calendarNowProvider,
  bool resetPrefs = true,
  String lastResetDate = '2026-07-24',
  Map<String, dynamic> initialShieldCache = const <String, dynamic>{},
  Map<String, dynamic> recoverableBreaks = const <String, dynamic>{},
  Map<String, dynamic> initialBreakCache = const <String, dynamic>{},
  Map<String, dynamic> occurrenceStatuses = const <String, dynamic>{},
}) async {
  if (resetPrefs) {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  }
  final currentNow = nowProvider ?? (() => DateTime(2026, 7, 24, 10));
  final stateRepository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('u1');
  final store = UserStateStore(
    stateRepository,
    journalEntrySyncService: JournalEntrySyncService(),
    streakProtectionRepository: repository,
    deviceTimeZoneProvider: const _FakeDeviceTimeZoneProvider(),
    currentSupabaseUserIdProvider: () => 'u1',
    nowProvider: currentNow,
    calendarNowProvider: calendarNowProvider,
  );
  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'u1',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': currentNow().toUtc().toIso8601String(),
      },
      'daily': <String, dynamic>{'lastResetDate': lastResetDate},
      'activeHabits': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'habit-1',
          'title': 'Leer',
          'type': 'check',
          'doneToday': false,
          'skippedToday': false,
          'remoteId': '11111111-1111-4111-8111-111111111111',
        },
      ],
      'history': <String, dynamic>{
        'habitOccurrenceStatuses':
            Map<String, dynamic>.from(occurrenceStatuses),
        'habitStreakShields': Map<String, dynamic>.from(initialShieldCache),
        'habitStreakBreaks': <String, dynamic>{
          ...recoverableBreaks,
          ...initialBreakCache,
        },
      },
    },
  });
  return store;
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var i = 0; i < 100; i += 1) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue);
}

Map<String, dynamic> _remoteBreakLocalJson({required String status}) {
  return <String, dynamic>{
    'id': 'remote-break-1',
    'userId': 'u1',
    'habitId': 'habit-1',
    'brokenAtMillis': DateTime.utc(2026, 7, 23).millisecondsSinceEpoch,
    'missedOccurrenceDateKey': '2026-07-23',
    'previousStreak': 3,
    'currentStreakAfterBreak': 0,
    'status': status,
    'shieldProtected': false,
    'remoteId': 'remote-row-break-1',
    'remoteHabitId': '11111111-1111-4111-8111-111111111111',
    'logicalTimeZone': 'Europe/Madrid',
  };
}

Map<String, dynamic> _localBreakCacheJson({
  required String status,
  String protectedDateKey = '2026-07-23',
}) {
  return <String, dynamic>{
    'id': 'local-break',
    'userId': 'u1',
    'habitId': 'habit-1',
    'brokenAtMillis': DateTime.utc(2026, 7, 23).millisecondsSinceEpoch,
    'missedOccurrenceDateKey': protectedDateKey,
    'previousStreak': 3,
    'currentStreakAfterBreak': 0,
    'status': status,
    'shieldProtected': false,
  };
}

Map<String, dynamic> _remoteShieldCacheJson({
  required String status,
  String protectedDateKey = '2026-07-24',
  String activatedAtKey = '2026-07-24',
}) {
  return <String, dynamic>{
    'id': 'remote-shield',
    'userId': 'u1',
    'habitId': 'habit-1',
    'utilityId': 'utility_streak_shield_1',
    'activatedAtMillis':
        DateTime.parse('${activatedAtKey}T08:00:00Z').millisecondsSinceEpoch,
    'status': status,
    'protectedOccurrenceDateKey': protectedDateKey,
    'operationId': 'shield-op',
    'remoteHabitId': '11111111-1111-4111-8111-111111111111',
    'effectId': 'effect-shield-op',
    'logicalTimeZone': 'Europe/Madrid',
    'requestId': 'request-shield-op',
  };
}

Map<String, dynamic> _localShieldCacheJson({
  required String status,
  String protectedDateKey = '2026-07-24',
  String activatedAtKey = '2026-07-24',
}) {
  return <String, dynamic>{
    'id': 'local-shield',
    'userId': 'u1',
    'habitId': 'habit-1',
    'utilityId': 'utility_streak_shield_1',
    'activatedAtMillis':
        DateTime.parse('${activatedAtKey}T08:00:00Z').millisecondsSinceEpoch,
    'status': status,
    'protectedOccurrenceDateKey': protectedDateKey,
    'operationId': 'local-op',
  };
}

Map<String, dynamic> _history(UserStateStore store) {
  final state = store.state?['userState'];
  if (state is! Map) {
    return <String, dynamic>{};
  }
  final history = state['history'];
  if (history is! Map) {
    return <String, dynamic>{};
  }
  return Map<String, dynamic>.from(history.cast<String, dynamic>());
}

class _FakeDeviceTimeZoneProvider implements DeviceTimeZoneProvider {
  const _FakeDeviceTimeZoneProvider();

  @override
  Future<String?> getLocalIanaTimeZone() async => 'Europe/Madrid';
}

class _FakeStreakProtectionRepository implements StreakProtectionRepository {
  _FakeStreakProtectionRepository({
    List<HabitStreakShieldRemote> shields = const <HabitStreakShieldRemote>[],
    List<HabitStreakBreakRemote> breaks = const <HabitStreakBreakRemote>[],
    this.failShieldFetch = false,
    this.failClose = false,
    this.closeGate,
  })  : shields = List<HabitStreakShieldRemote>.from(shields),
        breaks = List<HabitStreakBreakRemote>.from(breaks);

  final List<Map<String, String>> activateCalls = <Map<String, String>>[];
  final List<Map<String, String>> closeCalls = <Map<String, String>>[];
  final List<Map<String, String>> recoverCalls = <Map<String, String>>[];
  final List<HabitStreakShieldRemote> shields;
  final List<HabitStreakBreakRemote> breaks;

  final bool failShieldFetch;
  final bool failClose;
  final Future<void>? closeGate;

  bool failActivate = false;
  bool failRecover = false;
  String recoverStatus = 'recovered';
  CloseMissedHabitOccurrenceRemoteStatus closeStatus =
      CloseMissedHabitOccurrenceRemoteStatus.breakRecorded;

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
    activateCalls.add(<String, String>{
      'requestId': requestId,
      'habitId': habitId,
      'date': protectedOccurrenceDate,
      'operationId': operationId,
      'utilityId': utilityId,
    });
    if (failActivate) {
      return const RepositoryResult<ActivateStreakShieldRemoteResult>.failure(
        RepositoryError(
          code: RepositoryErrorCode.network,
          message: 'offline',
        ),
      );
    }
    final shield = _shield(
      id: 'remote-shield-$operationId',
      habitId: habitId,
      date: protectedOccurrenceDate,
      operationId: operationId,
      status: 'armed',
    );
    shields
      ..removeWhere((entry) => entry.id == shield.id)
      ..add(shield);
    return RepositoryResult<ActivateStreakShieldRemoteResult>.success(
      data: ActivateStreakShieldRemoteResult(shield: shield),
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
      'date': logicalDate,
      'breakId': breakId,
    });
    await closeGate;
    if (failClose) {
      return const RepositoryResult<
          CloseMissedHabitOccurrenceRemoteResult>.failure(
        RepositoryError(
          code: RepositoryErrorCode.network,
          message: 'offline',
        ),
      );
    }
    if (closeStatus ==
        CloseMissedHabitOccurrenceRemoteStatus.alreadyContinuous) {
      return RepositoryResult<CloseMissedHabitOccurrenceRemoteResult>.success(
        data: CloseMissedHabitOccurrenceRemoteResult(status: closeStatus),
      );
    }
    if (closeStatus == CloseMissedHabitOccurrenceRemoteStatus.shieldConsumed) {
      final shield = _shield(
        id: 'remote-shield-$breakId',
        habitId: habitId,
        date: logicalDate,
        operationId: 'shield-$breakId',
        status: 'consumed',
      );
      shields
        ..removeWhere((entry) => entry.id == shield.id)
        ..add(shield);
      return RepositoryResult<CloseMissedHabitOccurrenceRemoteResult>.success(
        data: CloseMissedHabitOccurrenceRemoteResult(
          status: closeStatus,
          shield: shield,
        ),
      );
    }
    final breakRecord = _break(
      breakId: breakId,
      habitId: habitId,
      date: logicalDate,
      status: closeStatus == CloseMissedHabitOccurrenceRemoteStatus.breakExpired
          ? 'expired'
          : 'recoverable',
    );
    breaks
      ..removeWhere((entry) => entry.breakId == breakId)
      ..add(breakRecord);
    return RepositoryResult<CloseMissedHabitOccurrenceRemoteResult>.success(
      data: CloseMissedHabitOccurrenceRemoteResult(
        status: closeStatus,
        breakRecord: breakRecord,
      ),
    );
  }

  @override
  Future<RepositoryResult<RecoverStreakBreakRemoteResult>> recoverStreakBreak({
    required String requestId,
    required String breakId,
    required String utilityId,
  }) async {
    recoverCalls.add(<String, String>{
      'requestId': requestId,
      'breakId': breakId,
      'utilityId': utilityId,
    });
    if (failRecover) {
      return const RepositoryResult<RecoverStreakBreakRemoteResult>.failure(
        RepositoryError(
          code: RepositoryErrorCode.network,
          message: 'offline',
        ),
      );
    }
    final breakRecord = _break(
      breakId: breakId,
      habitId: '11111111-1111-4111-8111-111111111111',
      date: '2026-07-23',
      status: recoverStatus,
    );
    breaks
      ..removeWhere((entry) => entry.breakId == breakId)
      ..add(breakRecord);
    return RepositoryResult<RecoverStreakBreakRemoteResult>.success(
      data: RecoverStreakBreakRemoteResult(
        status: recoverStatus,
        breakRecord: breakRecord,
      ),
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchArmedShieldsForCurrentUser() async {
    return RepositoryResult<List<HabitStreakShieldRemote>>.success(
      data: shields.where((entry) => entry.isArmed).toList(growable: false),
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchBreaksForCurrentUser() async {
    return RepositoryResult<List<HabitStreakBreakRemote>>.success(data: breaks);
  }

  @override
  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchShieldsForCurrentUser() async {
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
  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchRecoverableBreaksForCurrentUser() async {
    return RepositoryResult<List<HabitStreakBreakRemote>>.success(
      data:
          breaks.where((entry) => entry.isRecoverable).toList(growable: false),
    );
  }
}

HabitStreakShieldRemote _shield({
  required String id,
  required String habitId,
  required String date,
  required String operationId,
  required String status,
}) {
  return HabitStreakShieldRemote.fromMap(<String, dynamic>{
    'id': id,
    'request_id': 'req-$operationId',
    'operation_id': operationId,
    'habit_id': habitId,
    'utility_id': 'utility_streak_shield_1',
    'effect_id': 'effect-$operationId',
    'logical_time_zone': 'Europe/Madrid',
    'protected_occurrence_date': date,
    'status': status,
    'activated_at': '2026-07-24T08:00:00Z',
  });
}

HabitStreakBreakRemote _break({
  required String breakId,
  required String habitId,
  required String date,
  required String status,
}) {
  return HabitStreakBreakRemote.fromMap(<String, dynamic>{
    'id': 'row-$breakId',
    'request_id': 'req-$breakId',
    'recovery_request_id': 'rec-$breakId',
    'break_id': breakId,
    'habit_id': habitId,
    'logical_time_zone': 'Europe/Madrid',
    'missed_occurrence_date': date,
    'previous_streak': 3,
    'current_streak_after_break': status == 'recovered' ? 3 : 0,
    'status': status,
    'broken_at': '2026-07-24T00:00:00Z',
    'recoverable_until': '2026-07-26T00:00:00Z',
    if (status == 'recovered') 'recovered_at': '2026-07-24T09:00:00Z',
  });
}
