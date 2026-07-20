import 'dart:math';

import '../data/cloud/habit_currency_reward_errors.dart';
import '../data/cloud/habit_currency_reward_ledger.dart';
import '../data/cloud/habit_currency_reward_repository.dart';
import '../domain/habit_reward_transaction_repository.dart';
import '../domain/models/habit_reward_transaction.dart';
import '../domain/models/pending_currency_operation.dart';
import '../domain/pending_currency_operation_store.dart';
import 'habit_currency_reward_result.dart';

class HabitCurrencyRewardCoordinator {
  HabitCurrencyRewardCoordinator({
    required HabitCurrencyRewardRepository rewardRepository,
    required PendingCurrencyOperationStore pendingOperationStore,
    required HabitRewardTransactionRepository transactionRepository,
    required String? Function() currentUserIdProvider,
    bool? enabled,
    DateTime Function()? nowProvider,
    int maxAutoRetries = 1,
  })  : _rewardRepository = rewardRepository,
        _pendingOperationStore = pendingOperationStore,
        _transactionRepository = transactionRepository,
        _currentUserIdProvider = currentUserIdProvider,
        _enabled = enabled ?? true,
        _nowProvider = nowProvider ?? DateTime.now,
        _maxAutoRetries = maxAutoRetries;

  final HabitCurrencyRewardRepository _rewardRepository;
  final PendingCurrencyOperationStore _pendingOperationStore;
  final HabitRewardTransactionRepository _transactionRepository;
  final String? Function() _currentUserIdProvider;
  final bool _enabled;
  final DateTime Function() _nowProvider;
  final int _maxAutoRetries;

  Future<HabitCurrencyRewardOperationResult> applyHabitReward({
    required String habitId,
    required String logicalDateKey,
    String? completionEventId,
    String? requestId,
  }) async {
    return _execute(
      operationType: HabitRewardOperationType.apply,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
      requestId: requestId,
    );
  }

  Future<HabitCurrencyRewardOperationResult> reverseHabitReward({
    required String habitId,
    required String logicalDateKey,
    String? completionEventId,
    String? requestId,
  }) async {
    return _execute(
      operationType: HabitRewardOperationType.reverse,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
      requestId: requestId,
    );
  }

  Future<List<HabitCurrencyRewardOperationResult>> resolvePendingForCurrentUser({
    int maxOperations = 3,
  }) async {
    if (!_enabled) return const <HabitCurrencyRewardOperationResult>[];
    final userId = _currentUserId();
    if (userId == null) return const <HabitCurrencyRewardOperationResult>[];

    final pending = await _pendingOperationStore.loadPendingOperations(userId);
    if (pending.isEmpty) return const <HabitCurrencyRewardOperationResult>[];

    final results = <HabitCurrencyRewardOperationResult>[];
    for (final operation in pending.take(maxOperations)) {
      final result = await _execute(
        operationType: operation.operationType,
        habitId: operation.habitId,
        logicalDateKey: operation.logicalDateKey,
        completionEventId: operation.completionEventId,
        requestId: operation.requestId,
      );
      results.add(result);
      if (result.isPending) break;
    }
    return List<HabitCurrencyRewardOperationResult>.unmodifiable(results);
  }

  Future<HabitCurrencyRewardOperationResult> _execute({
    required HabitRewardOperationType operationType,
    required String habitId,
    required String logicalDateKey,
    String? completionEventId,
    String? requestId,
  }) async {
    if (!_enabled) {
      return HabitCurrencyRewardOperationResult(
        state: HabitCurrencyRewardState.skipped,
        failure: const HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.featureDisabled,
          message: 'Habit cloud rewards are disabled.',
          definitive: true,
        ),
      );
    }

    final userId = _currentUserId();
    if (userId == null) {
      return HabitCurrencyRewardOperationResult(
        state: HabitCurrencyRewardState.failure,
        failure: const HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.unauthenticated,
          message: 'No authenticated user session is available.',
          definitive: true,
        ),
      );
    }

    final normalizedHabitId = habitId.trim();
    final normalizedDateKey = logicalDateKey.trim();
    if (normalizedHabitId.isEmpty || normalizedDateKey.isEmpty) {
      return HabitCurrencyRewardOperationResult(
        state: HabitCurrencyRewardState.failure,
        failure: const HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.invalidResponse,
          message: 'Habit id and logical date are required.',
          definitive: true,
        ),
      );
    }

    final transaction = await _transactionRepository.findByCompletion(
      userScope: userId,
      habitId: normalizedHabitId,
      localDateKey: normalizedDateKey,
    );
    final pendingOperations =
        await _pendingOperationStore.loadPendingOperations(userId);
    final pendingOperationForSource = pendingOperations.where((operation) {
      return operation.habitId == normalizedHabitId &&
          operation.logicalDateKey == normalizedDateKey &&
          operation.operationType == operationType;
    }).toList(growable: false);
    final activePendingOperation = pendingOperationForSource.isNotEmpty
        ? pendingOperationForSource.first
        : null;
    final activeCompletionEventId = _resolveCompletionEventId(
      transaction: transaction,
      pendingOperation: activePendingOperation,
      operationType: operationType,
      providedCompletionEventId: completionEventId,
    );
    final activeRequestId = _normalizeRequestId(
      requestId: requestId,
      userId: userId,
      habitId: normalizedHabitId,
      logicalDateKey: normalizedDateKey,
      operationType: operationType,
      completionEventId: activeCompletionEventId,
    );

    if (transaction != null) {
      if (operationType == HabitRewardOperationType.apply &&
          transaction.isReversed == false) {
        if (activePendingOperation != null) {
          await _removePendingOperation(userId, activePendingOperation.requestId);
        }
        return HabitCurrencyRewardOperationResult(
          state: HabitCurrencyRewardState.success,
          transaction: transaction,
        );
      }
      if (operationType == HabitRewardOperationType.reverse &&
          transaction.isReversed == true) {
        if (activePendingOperation != null) {
          await _removePendingOperation(userId, activePendingOperation.requestId);
        }
        return HabitCurrencyRewardOperationResult(
          state: HabitCurrencyRewardState.success,
          transaction: transaction,
        );
      }
    }

    final pendingByRequest = pendingOperations.where(
      (operation) => operation.requestId == activeRequestId,
    );
    if (pendingByRequest.isNotEmpty) {
      final pending = pendingByRequest.first;
      if (pending.habitId != normalizedHabitId ||
          pending.logicalDateKey != normalizedDateKey ||
          pending.operationType != operationType) {
        return HabitCurrencyRewardOperationResult(
          state: HabitCurrencyRewardState.failure,
          failure: const HabitCurrencyRewardFailure(
            code: HabitCurrencyRewardFailureCode.requestConflict,
            message: 'request_id is already bound to another habit reward.',
            definitive: true,
          ),
        );
      }
    }

    final existingPendingBySource = pendingOperations.where(
      (operation) =>
          operation.habitId == normalizedHabitId &&
          operation.logicalDateKey == normalizedDateKey &&
          operation.completionEventId == activeCompletionEventId &&
          operation.operationType == operationType,
    );
    final pendingOperation = existingPendingBySource.isNotEmpty
        ? existingPendingBySource.first.copyWith(
            lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
            attemptCount: existingPendingBySource.first.attemptCount,
            status: PendingCurrencyOperationStatus.pending,
          )
        : PendingCurrencyOperation(
            userId: userId,
            requestId: activeRequestId,
            habitId: normalizedHabitId,
            logicalDateKey: normalizedDateKey,
            completionEventId: activeCompletionEventId,
            operationType: operationType,
            createdAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
            lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
            attemptCount: 0,
            status: PendingCurrencyOperationStatus.pending,
          );

    await _upsertPendingOperation(pendingOperation);

    final maxAttempts = 1 + _maxAutoRetries;
    HabitCurrencyRewardFailure? lastFailure;
    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      final attemptOperation = pendingOperation.copyWith(
        lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
        attemptCount: pendingOperation.attemptCount + attempt,
        status: attempt == 1
            ? PendingCurrencyOperationStatus.pending
            : PendingCurrencyOperationStatus.awaitingResolution,
      );
      await _upsertPendingOperation(attemptOperation);

      final response = await _callRemote(
        operationType: operationType,
        requestId: activeRequestId,
        habitId: normalizedHabitId,
        logicalDateKey: normalizedDateKey,
        completionEventId: activeCompletionEventId,
      );
      if (response.isSuccess && response.data != null) {
        final ledger = response.data!;
        if (ledger.userId != userId) {
          final failure = const HabitCurrencyRewardFailure(
            code: HabitCurrencyRewardFailureCode.sessionChanged,
            message: 'Authentication session changed during habit reward.',
            definitive: true,
          );
          await _savePendingAsAwaiting(attemptOperation);
          return HabitCurrencyRewardOperationResult(
            state: HabitCurrencyRewardState.failure,
            failure: failure,
          );
        }

        final updatedTransaction = _buildUpdatedTransaction(
          transaction: transaction,
          habitId: normalizedHabitId,
          logicalDateKey: normalizedDateKey,
          completionEventId: activeCompletionEventId,
          operationType: operationType,
          requestId: activeRequestId,
          ledger: ledger,
        );

        await _transactionRepository.saveTransaction(userId, updatedTransaction);
        await _removePendingOperation(userId, activeRequestId);
        return HabitCurrencyRewardOperationResult(
          state: HabitCurrencyRewardState.success,
          ledger: ledger,
          transaction: updatedTransaction,
        );
      }

      lastFailure = response.failure;
      if (lastFailure == null) {
        break;
      }

      if (lastFailure.retryable && attempt < maxAttempts) {
        continue;
      }

      if (lastFailure.definitive) {
        await _removePendingOperation(userId, activeRequestId);
        return HabitCurrencyRewardOperationResult(
          state: HabitCurrencyRewardState.failure,
          failure: lastFailure,
          transaction: transaction,
        );
      }

      await _savePendingAsAwaiting(attemptOperation);
      return HabitCurrencyRewardOperationResult(
        state: HabitCurrencyRewardState.pending,
        failure: lastFailure,
        pendingOperation: attemptOperation.copyWith(
          status: PendingCurrencyOperationStatus.awaitingResolution,
        ),
        transaction: transaction,
      );
    }

    final awaiting = pendingOperation.copyWith(
      status: PendingCurrencyOperationStatus.awaitingResolution,
      lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
      attemptCount: maxAttempts,
    );
    await _savePendingAsAwaiting(awaiting);
    return HabitCurrencyRewardOperationResult(
      state: HabitCurrencyRewardState.pending,
      failure: lastFailure,
      pendingOperation: awaiting,
      transaction: transaction,
    );
  }

  Future<HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>>
      _callRemote({
    required HabitRewardOperationType operationType,
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) {
    if (operationType == HabitRewardOperationType.reverse) {
      return _rewardRepository.reverseHabitCompletionReward(
        requestId: requestId,
        habitId: habitId,
        logicalDateKey: logicalDateKey,
        completionEventId: completionEventId,
      );
    }

    return _rewardRepository.applyHabitCompletionReward(
      requestId: requestId,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
    );
  }

  Future<void> _upsertPendingOperation(PendingCurrencyOperation operation) async {
    final userId = operation.userId.trim();
    if (userId.isEmpty) return;
    final current = await _pendingOperationStore.loadPendingOperations(userId);
    final next = <PendingCurrencyOperation>[
      for (final existing in current)
        if (existing.requestId != operation.requestId) existing,
      operation,
    ]..sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.requestId.compareTo(b.requestId);
      });
    await _pendingOperationStore.savePendingOperations(userId, next);
  }

  Future<void> _removePendingOperation(String userId, String requestId) async {
    final current = await _pendingOperationStore.loadPendingOperations(userId);
    final next = current
        .where((operation) => operation.requestId != requestId)
        .toList(growable: false);
    await _pendingOperationStore.savePendingOperations(userId, next);
  }

  Future<void> _savePendingAsAwaiting(PendingCurrencyOperation operation) async {
    await _upsertPendingOperation(operation.copyWith(
      status: PendingCurrencyOperationStatus.awaitingResolution,
    ));
  }

  HabitRewardTransaction _buildUpdatedTransaction({
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
    required HabitRewardOperationType operationType,
    required String requestId,
    required HabitCurrencyRewardLedgerEntry ledger,
    required HabitRewardTransaction? transaction,
  }) {
    final baseCoins = ledger.coinDelta < 0 ? -ledger.coinDelta : ledger.coinDelta;
    final baseXp = ledger.baseXp;
    final bonusXp = ledger.bonusXp;
    final bonusCoins = ledger.bonusCoins;
    final appliedEffectIds = ledger.appliedEffectIds.isEmpty
        ? transaction?.appliedEffectIds ?? const <String>[]
        : ledger.appliedEffectIds;

    return (transaction ??
            HabitRewardTransaction(
              id: _transactionId(habitId, logicalDateKey),
              habitId: habitId,
              localDateKey: logicalDateKey,
              completionEventId: completionEventId,
              applyRequestId:
                  operationType == HabitRewardOperationType.apply ? requestId : null,
              reverseRequestId:
                  operationType == HabitRewardOperationType.reverse
                      ? requestId
                      : null,
              cloudOperationType: operationType.name,
              baseXp: baseXp,
              bonusXp: bonusXp,
              baseCoins: baseCoins,
              bonusCoins: bonusCoins,
              appliedEffectIds: appliedEffectIds,
              createdAtMillis: ledger.createdAt.toUtc().millisecondsSinceEpoch,
              isReversed: operationType == HabitRewardOperationType.reverse,
            ))
        .copyWith(
      completionEventId: completionEventId,
      applyRequestId: operationType == HabitRewardOperationType.apply
          ? requestId
          : transaction?.applyRequestId,
      reverseRequestId: operationType == HabitRewardOperationType.reverse
          ? requestId
          : transaction?.reverseRequestId,
      cloudOperationType: operationType.name,
      baseXp: baseXp,
      bonusXp: bonusXp,
      baseCoins: baseCoins,
      bonusCoins: bonusCoins,
      appliedEffectIds: appliedEffectIds,
      createdAtMillis: ledger.createdAt.toUtc().millisecondsSinceEpoch,
      isReversed: operationType == HabitRewardOperationType.reverse,
    );
  }

  String _transactionId(String habitId, String logicalDateKey) {
    return '$habitId|$logicalDateKey';
  }

  String _resolveCompletionEventId({
    required HabitRewardOperationType operationType,
    required HabitRewardTransaction? transaction,
    required PendingCurrencyOperation? pendingOperation,
    required String? providedCompletionEventId,
  }) {
    final provided = providedCompletionEventId?.trim();
    if (provided != null && provided.isNotEmpty) {
      return provided;
    }

    final pending = pendingOperation?.completionEventId.trim();
    if (pending != null && pending.isNotEmpty) {
      return pending;
    }

    if (transaction != null &&
        transaction.completionEventId != null &&
        transaction.completionEventId!.trim().isNotEmpty &&
        transaction.isReversed == false) {
      return transaction.completionEventId!;
    }

    if (transaction != null &&
        transaction.completionEventId != null &&
        transaction.completionEventId!.trim().isNotEmpty &&
        operationType == HabitRewardOperationType.reverse) {
      return transaction.completionEventId!;
    }

    if (transaction != null &&
        transaction.isReversed == true &&
        operationType == HabitRewardOperationType.apply) {
      return _generateUuidV4();
    }

    return _generateUuidV4();
  }

  String _normalizeRequestId({
    String? requestId,
    required String userId,
    required String habitId,
    required String logicalDateKey,
    required HabitRewardOperationType operationType,
    required String completionEventId,
  }) {
    final provided = requestId?.trim();
    if (provided != null && provided.isNotEmpty) {
      return provided;
    }
    return '$userId|$habitId|$logicalDateKey|${operationType.name}|$completionEventId';
  }

  String? _currentUserId() {
    try {
      final current = _currentUserIdProvider()?.trim();
      if (current == null || current.isEmpty) return null;
      return current;
    } catch (_) {
      return null;
    }
  }

  static String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final parts = <String>[
      _hex(bytes.sublist(0, 4)),
      _hex(bytes.sublist(4, 6)),
      _hex(bytes.sublist(6, 8)),
      _hex(bytes.sublist(8, 10)),
      _hex(bytes.sublist(10, 16)),
    ];
    return parts.join('-');
  }

  static String _hex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
