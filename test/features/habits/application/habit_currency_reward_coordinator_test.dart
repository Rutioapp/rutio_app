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

const String _remoteHabitUuid = '11111111-1111-4111-8111-111111111111';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HabitCurrencyRewardCoordinator', () {
    test('builds deterministic remote completion and request ids', () {
      const localHabitId = 'habit-local-1';
      final firstCompletion = buildHabitRewardCompletionEventId(
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
      );
      final secondCompletion = buildHabitRewardCompletionEventId(
        remoteHabitId: _remoteHabitUuid.toUpperCase(),
        logicalDateKey: '2026-07-18',
      );
      final applyRequestId = buildHabitRewardApplyRequestId(
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
      );
      final reverseRequestId = buildHabitRewardReverseRequestId(
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
      );

      expect(
        firstCompletion,
        'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
      );
      expect(secondCompletion, firstCompletion);
      expect(firstCompletion, isNot(contains(localHabitId)));
      expect(
        applyRequestId,
        'habit_cloud_reward_apply|$_remoteHabitUuid|2026-07-18',
      );
      expect(
        reverseRequestId,
        'habit_cloud_reward_reverse|$_remoteHabitUuid|2026-07-18',
      );
      expect(applyRequestId, isNot(reverseRequestId));
      expect(applyRequestId, isNot(contains(localHabitId)));
      expect(reverseRequestId, isNot(contains(localHabitId)));
    });

    test('check habit completion grants once', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
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
        remoteHabitId: _remoteHabitUuid,
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
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-check-2',
      );
      final second = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-check-2',
      );

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(repo.applyCalls, 1);
      expect(second.transaction?.applyRequestId,
          first.transaction?.applyRequestId);
    });

    test('reverse subtracts exactly once', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-1',
      );
      final reversed = await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
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
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-2',
      );
      await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-2',
      );
      final secondReverse = await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-reverse-2',
      );

      expect(secondReverse.isSuccess, isTrue);
      expect(repo.reverseCalls, 1);
    });

    test('complete reverse complete reuses the deterministic apply id',
        () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      final first = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-cycle-1',
      );
      await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-cycle-1',
      );
      final second = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
      );

      expect(first.transaction?.applyRequestId, isNotNull);
      expect(second.transaction?.isReversed, isFalse);
      expect(repo.applyCalls, 2);
      expect(repo.applyRequests[0].requestId, repo.applyRequests[1].requestId);
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
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-timeout-1',
      );
      final pending = await _pendingStore.loadPendingOperations('user-1');

      expect(result.isPending, isTrue);
      expect(pending, hasLength(1));
      expect(pending.single.requestId, isNotEmpty);
    });

    test('new apply persists remote ids before calling the repository',
        () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      late _FakeHabitCurrencyRewardRepository repo;
      repo = _FakeHabitCurrencyRewardRepository(
        applyHandler: (request) {
          expect(pendingStore.saveCount, greaterThanOrEqualTo(1));
          expect(
            pendingStore.lastSavedFor('user-1').single.requestId,
            'habit_cloud_reward_apply|$_remoteHabitUuid|2026-07-18',
          );
          expect(
            pendingStore.lastSavedFor('user-1').single.habitId,
            _remoteHabitUuid,
          );
          expect(
            pendingStore.lastSavedFor('user-1').single.completionEventId,
            'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
          );
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

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
      );

      expect(result.isSuccess, isTrue);
      expect(repo.applyRequests.single.habitId, _remoteHabitUuid);
      expect(
        repo.applyRequests.single.completionEventId,
        'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
      );
      expect(
        repo.applyRequests.single.requestId,
        'habit_cloud_reward_apply|$_remoteHabitUuid|2026-07-18',
      );
    });

    test('legacy apply retry keeps pending ids but sends remote UUID',
        () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      final legacyPending = PendingCurrencyOperation(
        userId: 'user-1',
        requestId: 'habit_reward_habit-check_2026-07-18',
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'habit_cloud_reward|habit-check|2026-07-18',
        operationType: HabitRewardOperationType.apply,
        createdAtMillis: 1,
        lastAttemptAtMillis: 1,
        attemptCount: 0,
        status: PendingCurrencyOperationStatus.awaitingResolution,
      );
      await pendingStore
          .savePendingOperations('user-1', <PendingCurrencyOperation>[
        legacyPending,
      ]);
      final repo = _FakeHabitCurrencyRewardRepository(
        applyHandler: (request) {
          expect(pendingStore.saveCount, 2);
          expect(pendingStore.lastSavedFor('user-1').single.requestId,
              legacyPending.requestId);
          expect(pendingStore.lastSavedFor('user-1').single.habitId,
              legacyPending.habitId);
          expect(pendingStore.lastSavedFor('user-1').single.completionEventId,
              legacyPending.completionEventId);
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

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
        requestId: 'habit_cloud_reward_apply|$_remoteHabitUuid|2026-07-18',
      );

      expect(result.isSuccess, isTrue);
      expect(repo.applyRequests.single.habitId, _remoteHabitUuid);
      expect(repo.applyRequests.single.requestId,
          'habit_reward_habit-check_2026-07-18');
      expect(repo.applyRequests.single.completionEventId,
          'habit_cloud_reward|habit-check|2026-07-18');
    });

    test('legacy apply retry preserves identity and updates attempt metadata',
        () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      final legacyPending = PendingCurrencyOperation(
        userId: 'user-1',
        requestId: 'habit_reward_habit-check_2026-07-18',
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'habit_cloud_reward|habit-check|2026-07-18',
        operationType: HabitRewardOperationType.apply,
        createdAtMillis: 123,
        lastAttemptAtMillis: 456,
        attemptCount: 2,
        status: PendingCurrencyOperationStatus.awaitingResolution,
      );
      await pendingStore
          .savePendingOperations('user-1', <PendingCurrencyOperation>[
        legacyPending,
      ]);
      final repo = _FakeHabitCurrencyRewardRepository(
        applyHandler: (request) => HabitCurrencyRewardResult.failure(
          failure: const HabitCurrencyRewardFailure(
            code: HabitCurrencyRewardFailureCode.networkUnavailable,
            message: 'offline',
            retryable: true,
          ),
        ),
      );
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
        nowProvider: () => DateTime.utc(2026, 7, 18, 12, 30),
      );

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
      );

      expect(result.isPending, isTrue);
      expect(repo.applyRequests.single.habitId, _remoteHabitUuid);
      expect(repo.applyRequests.single.requestId, legacyPending.requestId);
      expect(repo.applyRequests.single.completionEventId,
          legacyPending.completionEventId);
      final pending =
          (await pendingStore.loadPendingOperations('user-1')).single;
      expect(pending.userId, legacyPending.userId);
      expect(pending.requestId, legacyPending.requestId);
      expect(pending.habitId, legacyPending.habitId);
      expect(pending.logicalDateKey, legacyPending.logicalDateKey);
      expect(pending.completionEventId, legacyPending.completionEventId);
      expect(pending.operationType, legacyPending.operationType);
      expect(pending.createdAtMillis, legacyPending.createdAtMillis);
      expect(pending.attemptCount, legacyPending.attemptCount + 1);
      expect(
        pending.lastAttemptAtMillis,
        DateTime.utc(2026, 7, 18, 12, 30).millisecondsSinceEpoch,
      );
      expect(pending.status, PendingCurrencyOperationStatus.awaitingResolution);
    });

    test('new reverse uses a distinct deterministic request id', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final transactionRepo = _MemoryHabitRewardTransactionRepository();
      await transactionRepo.saveTransaction(
        'user-1',
        HabitRewardTransaction(
          id: 'habit-check|2026-07-18',
          habitId: 'habit-check',
          localDateKey: '2026-07-18',
          completionEventId: 'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
          applyRequestId:
              'habit_cloud_reward_apply|$_remoteHabitUuid|2026-07-18',
          cloudOperationType: 'apply',
          baseXp: 10,
          bonusXp: 0,
          baseCoins: 5,
          bonusCoins: 0,
          appliedEffectIds: const <String>[],
          createdAtMillis: 1,
          isReversed: false,
        ),
      );
      final coordinator = _createCoordinator(
        repo: repo,
        transactionRepo: transactionRepo,
      );

      final result = await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
      );

      expect(result.isSuccess, isTrue);
      expect(repo.reverseRequests.single.habitId, _remoteHabitUuid);
      expect(
        repo.reverseRequests.single.completionEventId,
        'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
      );
      expect(
        repo.reverseRequests.single.requestId,
        'habit_cloud_reward_reverse|$_remoteHabitUuid|2026-07-18',
      );
      expect(
        repo.reverseRequests.single.requestId,
        isNot(repo.applyRequests.isEmpty
            ? 'habit_cloud_reward_apply|$_remoteHabitUuid|2026-07-18'
            : repo.applyRequests.single.requestId),
      );
    });

    test('legacy reverse retry keeps pending ids but sends remote UUID',
        () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      final legacyPending = PendingCurrencyOperation(
        userId: 'user-1',
        requestId: 'habit_reward_habit-check_2026-07-18',
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'habit_cloud_reward|habit-check|2026-07-18',
        operationType: HabitRewardOperationType.reverse,
        createdAtMillis: 1,
        lastAttemptAtMillis: 1,
        attemptCount: 0,
        status: PendingCurrencyOperationStatus.awaitingResolution,
      );
      await pendingStore
          .savePendingOperations('user-1', <PendingCurrencyOperation>[
        legacyPending,
      ]);
      final repo = _FakeHabitCurrencyRewardRepository(
        applyCoinDelta: 5,
        reverseHandler: (request) {
          expect(pendingStore.saveCount, 2);
          expect(pendingStore.lastSavedFor('user-1').single.requestId,
              legacyPending.requestId);
          expect(pendingStore.lastSavedFor('user-1').single.habitId,
              legacyPending.habitId);
          expect(pendingStore.lastSavedFor('user-1').single.completionEventId,
              legacyPending.completionEventId);
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'user-1',
              coinDelta: -5,
              balanceAfter: 0,
            ),
          );
        },
      );
      final transactionRepo = _MemoryHabitRewardTransactionRepository();
      await transactionRepo.saveTransaction(
        'user-1',
        HabitRewardTransaction(
          id: 'habit-check|2026-07-18',
          habitId: 'habit-check',
          localDateKey: '2026-07-18',
          completionEventId: 'habit_cloud_reward|habit-check|2026-07-18',
          applyRequestId: 'habit_reward_habit-check_2026-07-18',
          cloudOperationType: 'apply',
          baseXp: 10,
          bonusXp: 0,
          baseCoins: 5,
          bonusCoins: 0,
          appliedEffectIds: const <String>[],
          createdAtMillis: 1,
          isReversed: false,
        ),
      );
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        transactionRepo: transactionRepo,
        maxAutoRetries: 0,
      );

      final result = await coordinator.reverseHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
        requestId: 'habit_cloud_reward_reverse|$_remoteHabitUuid|2026-07-18',
      );

      expect(result.isSuccess, isTrue);
      expect(repo.reverseRequests.single.habitId, _remoteHabitUuid);
      expect(repo.reverseRequests.single.requestId,
          'habit_reward_habit-check_2026-07-18');
      expect(repo.reverseRequests.single.completionEventId,
          'habit_cloud_reward|habit-check|2026-07-18');
      expect(pendingStore.saveCount, 3);
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
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-retry-1',
      );
      final second = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-retry-1',
      );

      expect(first.isPending, isTrue);
      expect(second.isSuccess, isTrue);
      expect(repo.applyCalls, 2);
      expect(repo.applyRequests.first.requestId,
          repo.applyRequests.last.requestId);
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
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-session-1',
      );
      final pending = await _pendingStore.loadPendingOperations('user-1');

      expect(result.state, HabitCurrencyRewardState.failure);
      expect(
          result.failure?.code, HabitCurrencyRewardFailureCode.sessionChanged);
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
        remoteHabitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'event-restart-1',
      );
      expect(pendingResult.isPending, isTrue);
      expect(
        (await pendingStore.loadPendingOperations('user-1')).single.habitId,
        _remoteHabitUuid,
      );

      final restartedCoordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );
      final resolved =
          await restartedCoordinator.resolvePendingForCurrentUser();

      expect(resolved, isNotEmpty);
      expect(resolved.last.isSuccess, isTrue);
      expect(repo.applyRequests.last.habitId, _remoteHabitUuid);
      expect(await pendingStore.loadPendingOperations('user-1'), isEmpty);
    });

    test('resolvePendingForCurrentUser keeps local-id legacy apply pending',
        () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      await pendingStore
          .savePendingOperations('user-1', <PendingCurrencyOperation>[
        PendingCurrencyOperation(
          userId: 'user-1',
          requestId: 'habit_reward_habit-check_2026-07-18',
          habitId: 'habit-check',
          logicalDateKey: '2026-07-18',
          completionEventId: 'habit_cloud_reward|habit-check|2026-07-18',
          operationType: HabitRewardOperationType.apply,
          createdAtMillis: 1,
          lastAttemptAtMillis: 1,
          attemptCount: 0,
          status: PendingCurrencyOperationStatus.awaitingResolution,
        ),
      ]);
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );

      final result = await coordinator.resolvePendingForCurrentUser();

      expect(result.single.isPending, isTrue);
      expect(repo.applyCalls, 0);
      final pending = await pendingStore.loadPendingOperations('user-1');
      expect(pending, hasLength(1));
      expect(pending.single.requestId, 'habit_reward_habit-check_2026-07-18');
      expect(pending.single.habitId, 'habit-check');
      expect(pending.single.completionEventId,
          'habit_cloud_reward|habit-check|2026-07-18');
    });

    test(
        'resolvePendingForCurrentUser does not let legacy local pending block UUID pending',
        () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      final legacyPending = PendingCurrencyOperation(
        userId: 'user-1',
        requestId: 'habit_reward_habit-check_2026-07-18',
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
        completionEventId: 'habit_cloud_reward|habit-check|2026-07-18',
        operationType: HabitRewardOperationType.apply,
        createdAtMillis: 1,
        lastAttemptAtMillis: 1,
        attemptCount: 0,
        status: PendingCurrencyOperationStatus.awaitingResolution,
      );
      final uuidPending = PendingCurrencyOperation(
        userId: 'user-1',
        requestId: 'habit_cloud_reward_apply|$_remoteHabitUuid|2026-07-18',
        habitId: _remoteHabitUuid,
        logicalDateKey: '2026-07-18',
        completionEventId: 'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
        operationType: HabitRewardOperationType.apply,
        createdAtMillis: 2,
        lastAttemptAtMillis: 2,
        attemptCount: 0,
        status: PendingCurrencyOperationStatus.awaitingResolution,
      );
      await pendingStore.savePendingOperations(
        'user-1',
        <PendingCurrencyOperation>[legacyPending, uuidPending],
      );
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );

      final results = await coordinator.resolvePendingForCurrentUser();

      expect(results, hasLength(2));
      expect(results.first.isPending, isTrue);
      expect(
          results.first.pendingOperation?.requestId, legacyPending.requestId);
      expect(results.last.isSuccess, isTrue);
      expect(repo.applyCalls, 1);
      expect(repo.applyRequests.single.habitId, _remoteHabitUuid);
      expect(repo.applyRequests.single.requestId, uuidPending.requestId);
      final remaining = await pendingStore.loadPendingOperations('user-1');
      expect(remaining, hasLength(1));
      expect(remaining.single.requestId, legacyPending.requestId);
      expect(remaining.single.habitId, legacyPending.habitId);
      expect(
          remaining.single.completionEventId, legacyPending.completionEventId);
    });

    test('resolvePendingForCurrentUser keeps local-id legacy reverse pending',
        () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      await pendingStore
          .savePendingOperations('user-1', <PendingCurrencyOperation>[
        PendingCurrencyOperation(
          userId: 'user-1',
          requestId: 'habit_reward_habit-check_2026-07-18',
          habitId: 'habit-check',
          logicalDateKey: '2026-07-18',
          completionEventId: 'habit_cloud_reward|habit-check|2026-07-18',
          operationType: HabitRewardOperationType.reverse,
          createdAtMillis: 1,
          lastAttemptAtMillis: 1,
          attemptCount: 0,
          status: PendingCurrencyOperationStatus.awaitingResolution,
        ),
      ]);
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final transactionRepo = _MemoryHabitRewardTransactionRepository();
      await transactionRepo.saveTransaction(
        'user-1',
        HabitRewardTransaction(
          id: 'habit-check|2026-07-18',
          habitId: 'habit-check',
          localDateKey: '2026-07-18',
          completionEventId: 'habit_cloud_reward|habit-check|2026-07-18',
          applyRequestId: 'habit_reward_habit-check_2026-07-18',
          cloudOperationType: 'apply',
          baseXp: 10,
          bonusXp: 0,
          baseCoins: 5,
          bonusCoins: 0,
          appliedEffectIds: const <String>[],
          createdAtMillis: 1,
          isReversed: false,
        ),
      );
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        transactionRepo: transactionRepo,
        maxAutoRetries: 0,
      );

      final result = await coordinator.resolvePendingForCurrentUser();

      expect(result.single.isPending, isTrue);
      expect(repo.reverseCalls, 0);
      final pending = await pendingStore.loadPendingOperations('user-1');
      expect(pending, hasLength(1));
      expect(pending.single.requestId, 'habit_reward_habit-check_2026-07-18');
      expect(pending.single.habitId, 'habit-check');
      expect(pending.single.completionEventId,
          'habit_cloud_reward|habit-check|2026-07-18');
    });

    test('does not create a cloud pending operation without remote habit id',
        () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo);

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        logicalDateKey: '2026-07-18',
      );

      expect(result.state, HabitCurrencyRewardState.failure);
      expect(repo.applyCalls, 0);
      expect(await _pendingStore.loadPendingOperations('user-1'), isEmpty);
    });

    test('rejects invalid remote habit ids without creating pending', () async {
      for (final invalidRemoteHabitId in <String>[
        'habit-check',
        'texto-no-uuid',
        '',
      ]) {
        final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
        final coordinator = _createCoordinator(repo: repo);

        final applyResult = await coordinator.applyHabitReward(
          habitId: 'habit-check',
          remoteHabitId: invalidRemoteHabitId,
          logicalDateKey: '2026-07-18',
        );
        final reverseResult = await coordinator.reverseHabitReward(
          habitId: 'habit-check',
          remoteHabitId: invalidRemoteHabitId,
          logicalDateKey: '2026-07-18',
        );

        expect(applyResult.state, HabitCurrencyRewardState.failure);
        expect(reverseResult.state, HabitCurrencyRewardState.failure);
        expect(repo.applyCalls, 0);
        expect(repo.reverseCalls, 0);
        expect(await _pendingStore.loadPendingOperations('user-1'), isEmpty);
      }
    });

    test('normalizes uppercase remote UUID for new pending ids', () async {
      final pendingStore = _MemoryPendingCurrencyOperationStore();
      final repo = _FakeHabitCurrencyRewardRepository(
        applyHandler: (request) => HabitCurrencyRewardResult.failure(
          failure: const HabitCurrencyRewardFailure(
            code: HabitCurrencyRewardFailureCode.networkUnavailable,
            message: 'offline',
            retryable: true,
          ),
        ),
      );
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid.toUpperCase(),
        logicalDateKey: '2026-07-18',
      );

      expect(result.isPending, isTrue);
      final pending = await pendingStore.loadPendingOperations('user-1');
      expect(pending.single.habitId, _remoteHabitUuid);
      expect(
        pending.single.completionEventId,
        'habit_cloud_reward|$_remoteHabitUuid|2026-07-18',
      );
      expect(
        pending.single.requestId,
        'habit_cloud_reward_apply|$_remoteHabitUuid|2026-07-18',
      );
      expect(repo.applyRequests.single.habitId, _remoteHabitUuid);
    });

    test('feature flag disabled skips the cloud operation', () async {
      final repo = _FakeHabitCurrencyRewardRepository(applyCoinDelta: 5);
      final coordinator = _createCoordinator(repo: repo, enabled: false);

      final result = await coordinator.applyHabitReward(
        habitId: 'habit-check',
        remoteHabitId: _remoteHabitUuid,
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
  DateTime Function()? nowProvider,
}) {
  _transactionRepo =
      transactionRepo ?? _MemoryHabitRewardTransactionRepository();
  _pendingStore = pendingStore ?? _MemoryPendingCurrencyOperationStore();
  return HabitCurrencyRewardCoordinator(
    rewardRepository: repo,
    pendingOperationStore: _pendingStore,
    transactionRepository: _transactionRepo,
    currentUserIdProvider: () => 'user-1',
    enabled: enabled,
    maxAutoRetries: maxAutoRetries,
    nowProvider: nowProvider,
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
    this.reverseHandler,
    this.applyCoinDelta = 5,
    this.ledgerUserId = 'user-1',
  });

  final HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry> Function(
    _HabitCurrencyRewardRequest request,
  )? applyHandler;
  final HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry> Function(
    _HabitCurrencyRewardRequest request,
  )? reverseHandler;
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

    final handler = reverseHandler;
    if (handler != null) {
      return handler(request);
    }

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
    final transactions =
        _transactionsByUser[userScope] ?? const <HabitRewardTransaction>[];
    for (final transaction in transactions) {
      if (transaction.habitId == habitId &&
          transaction.localDateKey == localDateKey) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<List<HabitRewardTransaction>> loadTransactions(
      String userScope) async {
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
  int saveCount = 0;

  List<PendingCurrencyOperation> lastSavedFor(String userId) {
    return List<PendingCurrencyOperation>.unmodifiable(
      _pendingByUser[userId] ?? const <PendingCurrencyOperation>[],
    );
  }

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
    saveCount += 1;
    _pendingByUser[userId] = List<PendingCurrencyOperation>.from(operations);
  }
}
