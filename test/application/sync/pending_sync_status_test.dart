import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/application/sync/pending_sync_status.dart';
import 'package:rutio/core/storage/pending_queue_storage.dart';
import 'package:rutio/features/achievements/domain/models/pending_reward_claim.dart';
import 'package:rutio/features/achievements/domain/pending_reward_claim_store.dart';
import 'package:rutio/features/habits/data/pending_habit_mutation.dart';
import 'package:rutio/features/habits/domain/models/pending_currency_operation.dart';
import 'package:rutio/features/habits/domain/pending_currency_operation_store.dart';

void main() {
  const userId = 'user-a';
  final habitValue = PendingHabitMutation(
    operationId: 'operation-1',
    userId: userId,
    localHabitId: 'habit-1',
    type: PendingHabitMutationType.create,
    snapshot: const <String, dynamic>{'name': 'Habit'},
    createdAt: DateTime.utc(2026, 1, 1),
  );
  final currencyValue = PendingCurrencyOperation(
    userId: userId,
    requestId: 'request-1',
    habitId: 'habit-1',
    logicalDateKey: '2026-01-01',
    completionEventId: 'event-1',
    operationType: HabitRewardOperationType.apply,
    createdAtMillis: 1,
    lastAttemptAtMillis: 1,
    attemptCount: 0,
    status: PendingCurrencyOperationStatus.pending,
  );
  final rewardValue = PendingRewardClaim(
    userId: userId,
    requestId: 'claim-1',
    claimType: RewardClaimType.achievement,
    sourceId: 'achievement-1',
    createdAtMillis: 1,
    lastAttemptAtMillis: 1,
    attemptCount: 0,
    status: PendingRewardClaimStatus.pending,
  );

  PendingQueueReadResult<T> queue<T>(
    PendingQueueReadStatus status, [
    List<T>? values,
  ]) {
    return PendingQueueReadResult<T>(
      status: status,
      values: values ?? <T>[],
    );
  }

  Future<PendingQueueReadResult<PendingHabitMutation>> habit(
    PendingQueueReadStatus status, [
    List<PendingHabitMutation> values = const <PendingHabitMutation>[],
  ]) async =>
      queue(status, values);

  Future<PendingQueueReadResult<PendingCurrencyOperation>> currency(
    PendingQueueReadStatus status, [
    List<PendingCurrencyOperation> values = const <PendingCurrencyOperation>[],
  ]) async =>
      queue(status, values);

  Future<PendingQueueReadResult<PendingRewardClaim>> rewards(
    PendingQueueReadStatus status, [
    List<PendingRewardClaim> values = const <PendingRewardClaim>[],
  ]) async =>
      queue(status, values);

  PendingSyncStatusReader reader({
    required Future<PendingQueueReadResult<PendingHabitMutation>> Function(
      String,
    ) habitReader,
    required Future<PendingQueueReadResult<PendingCurrencyOperation>> Function(
      String,
    ) currencyReader,
    required Future<PendingQueueReadResult<PendingRewardClaim>> Function(
      String,
    ) rewardReader,
  }) {
    return PendingSyncStatusReader(
      currentUserIdProvider: () => userId,
      habitMutationReader: habitReader,
      habitCurrencyStore: _FakeCurrencyStore(currencyReader),
      rewardClaimStore: _FakeRewardStore(rewardReader),
    );
  }

  test('empty queues are synchronized and a pending create is visible',
      () async {
    final empty = reader(
      habitReader: (_) => habit(PendingQueueReadStatus.empty),
      currencyReader: (_) => currency(PendingQueueReadStatus.empty),
      rewardReader: (_) => rewards(PendingQueueReadStatus.empty),
    );
    expect((await empty.readCurrent()).kind, SyncStatusKind.synchronized);

    final pending = reader(
      habitReader: (_) => habit(PendingQueueReadStatus.valid, [habitValue]),
      currencyReader: (_) => currency(PendingQueueReadStatus.empty),
      rewardReader: (_) => rewards(PendingQueueReadStatus.empty),
    );
    final snapshot = await pending.readCurrent();
    expect(snapshot.kind, SyncStatusKind.pending);
    expect(snapshot.pendingDomains, contains('habit_mutations'));
  });

  test('pending rewards remain visible across both safe reward domains',
      () async {
    final pending = reader(
      habitReader: (_) => habit(PendingQueueReadStatus.empty),
      currencyReader: (_) =>
          currency(PendingQueueReadStatus.valid, [currencyValue]),
      rewardReader: (_) => rewards(PendingQueueReadStatus.valid, [rewardValue]),
    );
    final snapshot = await pending.readCurrent();
    expect(snapshot.kind, SyncStatusKind.pending);
    expect(
        snapshot.pendingDomains,
        containsAll(<String>[
          'habit_rewards',
          'achievement_level_rewards',
        ]));
  });

  test('corrupt, incompatible, and storage-error queues require attention',
      () async {
    final statuses = <PendingQueueReadStatus>[
      PendingQueueReadStatus.corrupt,
      PendingQueueReadStatus.incompatible,
      PendingQueueReadStatus.storageError,
    ];
    for (final status in statuses) {
      final snapshot = await reader(
        habitReader: (_) => habit(status),
        currencyReader: (_) => currency(PendingQueueReadStatus.empty),
        rewardReader: (_) => rewards(PendingQueueReadStatus.empty),
      ).readCurrent();
      expect(snapshot.kind, SyncStatusKind.attention);
      expect(snapshot.isVisible, isTrue);
    }
  });

  test('a transiently pending queue is not classified as attention', () async {
    final snapshot = await reader(
      habitReader: (_) => habit(PendingQueueReadStatus.valid, [habitValue]),
      currencyReader: (_) => currency(PendingQueueReadStatus.empty),
      rewardReader: (_) => rewards(PendingQueueReadStatus.empty),
    ).readCurrent();
    expect(snapshot.kind, SyncStatusKind.pending);
    expect(snapshot.needsAttention, isFalse);
  });

  test('awaiting-resolution operations require attention', () async {
    final snapshot = await reader(
      habitReader: (_) => habit(
        PendingQueueReadStatus.valid,
        [habitValue.copyWith(uncertain: true)],
      ),
      currencyReader: (_) => currency(
        PendingQueueReadStatus.valid,
        [
          currencyValue.copyWith(
            status: PendingCurrencyOperationStatus.awaitingResolution,
          ),
        ],
      ),
      rewardReader: (_) => rewards(
        PendingQueueReadStatus.valid,
        [
          rewardValue.copyWith(
            status: PendingRewardClaimStatus.awaitingResolution,
          ),
        ],
      ),
    ).readCurrent();
    expect(snapshot.kind, SyncStatusKind.attention);
  });

  test('no authenticated user produces no visible status', () async {
    final status = PendingSyncStatusReader(currentUserIdProvider: () => null);
    final snapshot = await status.readCurrent();
    expect(snapshot.isVisible, isFalse);
    expect(snapshot.kind, SyncStatusKind.synchronized);
  });
}

class _FakeCurrencyStore
    implements
        PendingCurrencyOperationStore,
        PendingCurrencyOperationStoreWithStatus {
  _FakeCurrencyStore(this.reader);

  final Future<PendingQueueReadResult<PendingCurrencyOperation>> Function(
    String,
  ) reader;

  @override
  Future<PendingQueueReadResult<PendingCurrencyOperation>>
      loadPendingOperationsWithStatus(String userId) => reader(userId);

  @override
  Future<List<PendingCurrencyOperation>> loadPendingOperations(String userId) =>
      reader(userId).then((result) => result.values);

  @override
  Future<void> savePendingOperations(
    String userId,
    List<PendingCurrencyOperation> operations,
  ) async {}

  @override
  Future<bool> savePendingOperationsConfirmed(
    String userId,
    List<PendingCurrencyOperation> operations,
  ) async =>
      true;

  @override
  Future<void> clearPendingOperations(String userId) async {}
}

class _FakeRewardStore
    implements PendingRewardClaimStore, PendingRewardClaimStoreWithStatus {
  _FakeRewardStore(this.reader);

  final Future<PendingQueueReadResult<PendingRewardClaim>> Function(String)
      reader;

  @override
  Future<PendingQueueReadResult<PendingRewardClaim>>
      loadPendingClaimsWithStatus(String userId) => reader(userId);

  @override
  Future<List<PendingRewardClaim>> loadPendingClaims(String userId) =>
      reader(userId).then((result) => result.values);

  @override
  Future<void> savePendingClaims(
    String userId,
    List<PendingRewardClaim> claims,
  ) async {}

  @override
  Future<bool> savePendingClaimsConfirmed(
    String userId,
    List<PendingRewardClaim> claims,
  ) async =>
      true;

  @override
  Future<void> clearPendingClaims(String userId) async {}
}
