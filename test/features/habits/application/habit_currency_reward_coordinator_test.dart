import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/application/habit_currency_reward_coordinator.dart';
import 'package:rutio/features/habits/application/habit_currency_reward_result.dart';
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_errors.dart';
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_ledger.dart';
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_repository.dart';
import 'package:rutio/features/habits/domain/habit_reward_transaction_repository.dart';
import 'package:rutio/features/habits/domain/models/habit_reward_transaction.dart';
import 'package:rutio/features/habits/domain/models/pending_currency_operation.dart';
import 'package:rutio/features/habits/domain/pending_currency_operation_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HabitCurrencyRewardCoordinator', () {
    test('check habit completion grants once', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-check-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.transaction?.totalCoins, 5);
      expect(repo.applyCalls, 1);
      expect(await _transactionRepo.loadTransactions('user-1'), hasLength(1));
      expect(await _pendingStore.loadPendingOperations('user-1'), isEmpty);
    });

    test('count habit completion grants the server computed amount once',
        () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 3);
      final coordinator = _createCoordinator(repo: repo);

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-count',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-count-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.transaction?.totalCoins, 3);
      expect(result.transaction?.cloudOperationType, 'apply');
    });

    test('double complete does not duplicate the reward', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      final first = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-check-2',
      );
      final second = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-check-2',
      );

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(repo.applyCalls, 1);
      expect(second.transaction?.applyRequestId, first.transaction?.applyRequestId);
    });

    test('reverse subtracts exactly once', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-1',
      );
      final reversed = await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-1',
      );

      expect(reversed.isSuccess, isTrue);
      expect(reversed.transaction?.isReversed, isTrue);
      expect(reversed.transaction?.totalCoins, 5);
      expect(repo.reverseCalls, 1);
      expect(await _transactionRepo.loadTransactions('user-1'), hasLength(1));
    });

    test('double reverse does not subtract twice', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-2',
      );
      await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-2',
      );
      final secondReverse = await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-2',
      );

      expect(secondReverse.isSuccess, isTrue);
      expect(repo.reverseCalls, 1);
    });

    test('complete reverse complete uses a fresh cloud event', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      final first = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-cycle-1',
      );
      await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-cycle-1',
      );
      final second = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
      );

      expect(first.transaction?.applyRequestId, isNotNull);
      expect(second.transaction?.isReversed, isFalse);
      expect(repo.applyCalls, 2);
      expect(repo.applyRequests[0].requestId, isNot(equals(repo.applyRequests[1].requestId)));
    });

    test('timeout leaves the operation pending', () async {
      final repo = _FakeHabitCurrencyRewardRepository(
        applyHandler: (request) => HabitCurrencyRewardResult.failure(
          failure: const HabitCurrencyRewardFailure(
            code: HabitCurrencyRewardFailureCode.timeout,
            message: 'timeout',
            retryable: true,
          ),
        ),
      );
      final coordinator = _createCoordinator(repo: repo, maxAutoRetries: 0);

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-timeout-1',
      );
      final pending = await _pendingStore.loadPendingOperations('user-1');

      expect(result.isPending, isTrue);
      expect(pending, hasLength(1));
      expect(pending.single.requestId, isNotEmpty);
    });

    test('retry with the same requestId resolves the pending reward', () async {
      var callCount = 0;
      final repo = _FakeHabitCurrencyRewardRepository(
        applyHandler: (request) {
          callCount += 1;
          if (callCount == 1) {
            return HabitCurrencyRewardResult.failure(
              failure: const HabitCurrencyRewardFailure(
                code: HabitCurrencyRewardFailureCode.timeout,
                message: 'timeout',
                retryable: true,
              ),
            );
          }
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'user-1',
              coinDelta: 5,
              balanceAfter: 5,
            ),
          );
        },
      );
      final coordinator = _createCoordinator(repo: repo, maxAutoRetries: 0);

      final first = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-retry-1',
      );
      final second = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-retry-1',
      );

      expect(first.isPending, isTrue);
      expect(second.isSuccess, isTrue);
      expect(repo.applyCalls, 2);
      expect(repo.applyRequests.first.requestId, repo.applyRequests.last.requestId);
      expect(await _pendingStore.loadPendingOperations('user-1'), isEmpty);
    });

    test('change of session is rejected and keeps the pending operation',
        () async {
      final repo = _FakeHabitCurrencyRewardRepository(
        ledgerUserId: 'user-2',
        applyCoinDelta: 5,
      );
      final coordinator = _createCoordinator(repo: repo);

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-session-1',
      );
      final pending = await _pendingStore.loadPendingOperations('user-1');

      expect(result.state, HabitCurrencyRewardState.failure);
      expect(result.failure?.code, HabitCurrencyRewardFailureCode.sessionChanged);
      expect(pending, hasLength(1));
    });

    test('resolvePendingForCurrentUser survives an app restart', () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      final restartState = _RepoRestartState();
      final repo = _FakeHabitCurrencyRewardRepository(
        applyHandler: (request) {
          if (restartState.shouldFailFirst) {
            restartState.shouldFailFirst = false;
            return HabitCurrencyRewardResult.failure(
              failure: const HabitCurrencyRewardFailure(
                code: HabitCurrencyRewardFailureCode.networkUnavailable,
                message: 'offline',
                retryable: true,
              ),
            );
          }
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'user-1',
              coinDelta: 5,
              balanceAfter: 5,
            ),
          );
        },
      );
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );

      final pendingResult = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-restart-1',
      );
      expect(pendingResult.isPending, isTrue);

      final restartedCoordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );
      final resolved = await restartedCoordinator.resolvePendingForCurrentUser();

      expect(resolved, isNotEmpty);
      expect(resolved.last.isSuccess, isTrue);
      expect(await pendingStore.loadPendingOperations('user-1'), isEmpty);
    });

    test('feature flag disabled skips the cloud operation', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo, enabled: false);

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-disabled-1',
      );

      expect(result.isSkipped, isTrue);
      expect(repo.applyCalls, 0);
      expect(await _pendingStore.loadPendingOperations('user-1'), isEmpty);
    });
  });
}

late _MemoryHabitRewardTransactionRepository _transactionRepo;
late _MemoryPendingCurrencyOperationStore _pendingStore;

HabitCurrencyRewardCoordinator _createCoordinator({
  required _FakeHabitCurrencyRewardRepository repo,
  bool enabled = true,
  int maxAutoRetries = 1,
  _MemoryPendingCurrencyOperationStore? pendingStore,
  _MemoryHabitRewardTransactionRepository? transactionRepo,
}) {
  _transactionRepo = transactionRepo ?? _MemoryHabitRewardTransactionRepository();
  _pendingStore = pendingStore ?? _MemoryPendingCurrencyOperationStore();
  return HabitCurrencyRewardCoordinator(
    rewardRepository: repo,
    pendingOperationStore: _pendingStore,
    transactionRepository: _transactionRepo,
    currentUserIdProvider: () => 'user-1',
    enabled: enabled,
    maxAutoRetries: maxAutoRetries,
  );
}

HabitCurrencyRewardLedgerEntry _ledgerFor({
  required _HabitCurrencyRewardRequest request,
  required String userId,
  required int coinDelta,
  required int balanceAfter,
}) {
  return HabitCurrencyRewardLedgerEntry(
    id: 'ledger-${request.operationType}-${request.requestId}',
    userId: userId,
    requestId: request.requestId,
    operationType: request.operationType,
    sourceType: 'habit_completion',
    sourceId: request.completionEventId,
    habitId: request.habitId,
    logicalDateKey: request.logicalDateKey,
    coinDelta: coinDelta,
    balanceAfter: balanceAfter,
    createdAt: DateTime.utc(2026, 7, 18, 12, 0, 0),
    isIdempotent: false,
    relatedLedgerId: null,
  );
}

class _RepoRestartState {
  bool shouldFailFirst = true;
}

class _HabitCurrencyRewardRequest {
  const _HabitCurrencyRewardRequest({
    required this.requestId,
    required this.habitId,
    required this.logicalDateKey,
    required this.completionEventId,
    required this.operationType,
  });

  final String requestId;
  final String habitId;
  final String logicalDateKey;
  final String completionEventId;
  final String operationType;
}

class _FakeHabitCurrencyRewardRepository
    implements HabitCurrencyRewardRepository {
  _FakeHabitCurrencyRewardRepository({
    this.applyHandler,
    this.applyCoinDelta = 5,
    this.ledgerUserId = 'user-1',
  });

  final HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry> Function(
    _HabitCurrencyRewardRequest request,
  )?
  applyHandler;
  final int applyCoinDelta;
  final String ledgerUserId;

  int applyCalls = 0;
  int reverseCalls = 0;
  final List<_HabitCurrencyRewardRequest> applyRequests =
      <_HabitCurrencyRewardRequest>[];
  final List<_HabitCurrencyRewardRequest> reverseRequests =
      <_HabitCurrencyRewardRequest>[];

  @override
  Future<HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>>
      applyHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) async {
    final request = _HabitCurrencyRewardRequest(
      requestId: requestId,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
      operationType: 'apply',
    );
    applyCalls += 1;
    applyRequests.add(request);

    final handler = applyHandler;
    if (handler != null) {
      return handler(request);
    }

    return HabitCurrencyRewardResult.success(
      data: _ledgerFor(
        request: request,
        userId: ledgerUserId,
        coinDelta: applyCoinDelta,
        balanceAfter: applyCoinDelta,
      ),
    );
  }

  @override
  Future<HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>>
      reverseHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) async {
    final request = _HabitCurrencyRewardRequest(
      requestId: requestId,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
      operationType: 'reverse',
    );
    reverseCalls += 1;
    reverseRequests.add(request);

    return HabitCurrencyRewardResult.success(
      data: _ledgerFor(
        request: request,
        userId: ledgerUserId,
        coinDelta: -applyCoinDelta,
        balanceAfter: 0,
      ),
    );
  }
}

class _MemoryHabitRewardTransactionRepository
    implements HabitRewardTransactionRepository {
  final Map<String, List<HabitRewardTransaction>> _transactionsByUser =
      <String, List<HabitRewardTransaction>>{};

  @override
  Future<HabitRewardTransaction?> findByCompletion({
    required String userScope,
    required String habitId,
    required String localDateKey,
  }) async {
    final transactions = _transactionsByUser[userScope] ?? const <HabitRewardTransaction>[];
    for (final transaction in transactions) {
      if (transaction.habitId == habitId &&
          transaction.localDateKey == localDateKey) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<List<HabitRewardTransaction>> loadTransactions(String userScope) async {
    return List<HabitRewardTransaction>.unmodifiable(
      _transactionsByUser[userScope] ?? const <HabitRewardTransaction>[],
    );
  }

  @override
  Future<void> saveTransaction(
    String userScope,
    HabitRewardTransaction transaction,
  ) async {
    final current = List<HabitRewardTransaction>.from(
      _transactionsByUser[userScope] ?? const <HabitRewardTransaction>[],
    );
    current.removeWhere(
      (existing) =>
          existing.habitId == transaction.habitId &&
          existing.localDateKey == transaction.localDateKey,
    );
    current.add(transaction);
    _transactionsByUser[userScope] = current;
  }
}

class _MemoryPendingCurrencyOperationStore
    implements PendingCurrencyOperationStore {
  final Map<String, List<PendingCurrencyOperation>> _pendingByUser =
      <String, List<PendingCurrencyOperation>>{};

  @override
  Future<void> clearPendingOperations(String userId) async {
    _pendingByUser.remove(userId);
  }

  @override
  Future<List<PendingCurrencyOperation>> loadPendingOperations(
    String userId,
  ) async {
    return List<PendingCurrencyOperation>.unmodifiable(
      _pendingByUser[userId] ?? const <PendingCurrencyOperation>[],
    );
  }

  @override
  Future<void> savePendingOperations(
    String userId,
    List<PendingCurrencyOperation> operations,
  ) async {
    _pendingByUser[userId] = List<PendingCurrencyOperation>.from(operations);
  }
}
