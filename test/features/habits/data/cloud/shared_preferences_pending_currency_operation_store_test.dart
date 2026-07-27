import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/data/cloud/shared_preferences_pending_currency_operation_store.dart';
import 'package:rutio/features/habits/domain/models/pending_currency_operation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesPendingCurrencyOperationStore', () {
    late SharedPreferencesPendingCurrencyOperationStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store = SharedPreferencesPendingCurrencyOperationStore();
    });

    test('saves and loads pending operations per user', () async {
      final pending = PendingCurrencyOperation(
        userId: 'user-1',
        requestId: 'req-1',
        habitId: 'habit-1',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-1',
        operationType: HabitRewardOperationType.apply,
        createdAtMillis: 10,
        lastAttemptAtMillis: 11,
        attemptCount: 1,
        status: PendingCurrencyOperationStatus.pending,
      );

      await store
          .savePendingOperations('user-1', <PendingCurrencyOperation>[pending]);

      final loaded = await store.loadPendingOperations('user-1');

      expect(loaded, hasLength(1));
      expect(loaded.single.requestId, 'req-1');
      expect(await store.loadPendingOperations('user-2'), isEmpty);
    });

    test('does not mix users and persists after recreation', () async {
      final first = PendingCurrencyOperation(
        userId: 'user-1',
        requestId: 'req-1',
        habitId: 'habit-1',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-1',
        operationType: HabitRewardOperationType.apply,
        createdAtMillis: 10,
        lastAttemptAtMillis: 11,
        attemptCount: 1,
        status: PendingCurrencyOperationStatus.pending,
      );
      final second = PendingCurrencyOperation(
        userId: 'user-2',
        requestId: 'req-2',
        habitId: 'habit-2',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-2',
        operationType: HabitRewardOperationType.reverse,
        createdAtMillis: 20,
        lastAttemptAtMillis: 21,
        attemptCount: 1,
        status: PendingCurrencyOperationStatus.awaitingResolution,
      );

      await store
          .savePendingOperations('user-1', <PendingCurrencyOperation>[first]);
      await store
          .savePendingOperations('user-2', <PendingCurrencyOperation>[second]);

      store = SharedPreferencesPendingCurrencyOperationStore();

      final user1 = await store.loadPendingOperations('user-1');
      final user2 = await store.loadPendingOperations('user-2');

      expect(user1.single.requestId, 'req-1');
      expect(user2.single.requestId, 'req-2');
    });

    test('clear removes one user bucket only', () async {
      final pending = PendingCurrencyOperation(
        userId: 'user-1',
        requestId: 'req-1',
        habitId: 'habit-1',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-1',
        operationType: HabitRewardOperationType.apply,
        createdAtMillis: 10,
        lastAttemptAtMillis: 11,
        attemptCount: 1,
        status: PendingCurrencyOperationStatus.pending,
      );
      await store
          .savePendingOperations('user-1', <PendingCurrencyOperation>[pending]);
      await store.clearPendingOperations('user-1');

      expect(await store.loadPendingOperations('user-1'), isEmpty);
    });

    test('loads and preserves legacy pending identifiers unchanged', () async {
      final legacyJson = <Map<String, dynamic>>[
        <String, dynamic>{
          'userId': 'user-1',
          'requestId': 'habit_reward_habit-local_2026-07-18',
          'habitId': 'habit-local',
          'logicalDateKey': '2026-07-18',
          'completionEventId': 'habit_cloud_reward|habit-local|2026-07-18',
          'operationType': 'reverse',
          'createdAtMillis': 10,
          'lastAttemptAtMillis': 11,
          'attemptCount': 1,
          'status': 'awaitingResolution',
        },
      ];
      SharedPreferences.setMockInitialValues(<String, Object>{
        '${SharedPreferencesPendingCurrencyOperationStore.storagePrefix}_user-1':
            jsonEncode(legacyJson),
      });
      store = SharedPreferencesPendingCurrencyOperationStore();

      final loaded = await store.loadPendingOperations('user-1');

      expect(loaded, hasLength(1));
      expect(loaded.single.requestId, 'habit_reward_habit-local_2026-07-18');
      expect(loaded.single.habitId, 'habit-local');
      expect(
        loaded.single.completionEventId,
        'habit_cloud_reward|habit-local|2026-07-18',
      );
      expect(loaded.single.operationType, HabitRewardOperationType.reverse);

      await store.savePendingOperations('user-1', loaded);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(
        '${SharedPreferencesPendingCurrencyOperationStore.storagePrefix}_user-1',
      );
      final encoded = jsonDecode(raw!) as List<dynamic>;
      final saved = Map<String, dynamic>.from(encoded.single as Map);
      expect(saved['requestId'], 'habit_reward_habit-local_2026-07-18');
      expect(
        saved['completionEventId'],
        'habit_cloud_reward|habit-local|2026-07-18',
      );
      expect(saved['habitId'], 'habit-local');
    });
  });
}
