import '../../../data/mappers/habit_remote_mapper.dart';
import '../data/cloud/habit_currency_reward_errors.dart';
import '../data/cloud/habit_currency_reward_ledger.dart';
import '../data/cloud/habit_currency_reward_repository.dart';
import '../domain/habit_reward_transaction_repository.dart';
import '../domain/models/habit_reward_transaction.dart';
import '../domain/models/pending_currency_operation.dart';
import '../domain/pending_currency_operation_store.dart';
import 'habit_currency_reward_result.dart';

String buildHabitRewardCompletionEventId({
  required String remoteHabitId,
  required String logicalDateKey,
}) {
  return 'habit_cloud_reward|${remoteHabitId.trim().toLowerCase()}|${logicalDateKey.trim()}';
}

String buildHabitRewardApplyRequestId({
  required String remoteHabitId,
  required String logicalDateKey,
}) {
  return 'habit_cloud_reward_apply|${remoteHabitId.trim().toLowerCase()}|${logicalDateKey.trim()}';
}

String buildHabitRewardReverseRequestId({
  required String remoteHabitId,
  required String logicalDateKey,
}) {
  return 'habit_cloud_reward_reverse|${remoteHabitId.trim().toLowerCase()}|${logicalDateKey.trim()}';
}

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
    String? remoteHabitId,
    required String logicalDateKey,
    String? completionEventId,
    String? requestId,
  }) async {
    return _execute(
      operationType: HabitRewardOperationType.apply,
      habitId: habitId,
      remoteHabitId: remoteHabitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
      requestId: requestId,
    );
  }

  Future<HabitCurrencyRewardOperationResult> reverseHabitReward({
    required String habitId,
    String? remoteHabitId,
    required String logicalDateKey,
    String? completionEventId,
    String? requestId,
  }) async {
    return _execute(
      operationType: HabitRewardOperationType.reverse,
      habitId: habitId,
      remoteHabitId: remoteHabitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
      requestId: requestId,
    );
  }

  Future<List<HabitCurrencyRewardOperationResult>>
      resolvePendingForCurrentUser({
    int maxOperations = 3,
  }) async {
    if (!_enabled) return const <HabitCurrencyRewardOperationResult>[];
    final userId = _currentUserId();
    if (userId == null) return const <HabitCurrencyRewardOperationResult>[];

    final pending = await _pendingOperationStore.loadPendingOperations(userId);
    if (pending.isEmpty) return const <HabitCurrencyRewardOperationResult>[];

    final results = <HabitCurrencyRewardOperationResult>[];
    for (final operation in pending.take(maxOperations)) {
      final remoteHabitId = _normalizeRemoteHabitId(operation.habitId);
      if (remoteHabitId == null) {
        results.add(
          HabitCurrencyRewardOperationResult(
            state: HabitCurrencyRewardState.pending,
            pendingOperation: operation,
            failure: const HabitCurrencyRewardFailure(
              code: HabitCurrencyRewardFailureCode.invalidResponse,
              message:
                  'Pending habit reward needs a remote habit UUID before retry.',
            ),
          ),
        );
        continue;
      }
      final result = await _execute(
        operationType: operation.operationType,
        habitId: operation.habitId,
        remoteHabitId: remoteHabitId,
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
    String? remoteHabitId,
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
    final normalizedRemoteHabitId = _normalizeRemoteHabitId(remoteHabitId);
    final pendingHabitId = normalizedRemoteHabitId ?? normalizedHabitId;
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
      return _pendingHabitMatches(
            operation.habitId,
            localHabitId: normalizedHabitId,
            remoteHabitId: normalizedRemoteHabitId,
          ) &&
          operation.logicalDateKey == normalizedDateKey &&
          operation.operationType == operationType;
    }).toList(growable: false);
    final activePendingOperation = pendingOperationForSource.isNotEmpty
        ? pendingOperationForSource.first
        : null;
    final activeRemoteHabitId = normalizedRemoteHabitId ??
        _normalizeRemoteHabitId(activePendingOperation?.habitId);
    final activeCompletionEventId = _resolveCompletionEventId(
      transaction: transaction,
      pendingOperation: activePendingOperation,
      operationType: operationType,
      providedCompletionEventId: completionEventId,
      remoteHabitId: activeRemoteHabitId,
      logicalDateKey: normalizedDateKey,
    );
    final activeRequestId = _normalizeRequestId(
      requestId: requestId,
      pendingOperation: activePendingOperation,
      remoteHabitId: activeRemoteHabitId,
      logicalDateKey: normalizedDateKey,
      operationType: operationType,
    );
    if (activeRemoteHabitId == null ||
        activeCompletionEventId.isEmpty ||
        activeRequestId.isEmpty) {
      return HabitCurrencyRewardOperationResult(
        state: HabitCurrencyRewardState.failure,
        failure: const HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.invalidResponse,
          message:
              'Remote habit id is required to create a habit cloud reward.',
          definitive: true,
        ),
      );
    }

    final hasConfirmedCloudTransaction =
        _isConfirmedCloudHabitRewardTransaction(transaction);
    final hasConfirmedCloudReversal =
        _isConfirmedCloudHabitRewardReversal(transaction);

    if (transaction != null) {
      if (operationType == HabitRewardOperationType.apply &&
          hasConfirmedCloudTransaction) {
        if (activePendingOperation != null) {
          await _removePendingOperation(
              userId, activePendingOperation.requestId);
        }
        return HabitCurrencyRewardOperationResult(
          state: HabitCurrencyRewardState.success,
          transaction: transaction,
        );
      }
      if (operationType == HabitRewardOperationType.reverse &&
          hasConfirmedCloudReversal) {
        if (activePendingOperation != null) {
          await _removePendingOperation(
              userId, activePendingOperation.requestId);
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
      if (!_pendingHabitMatches(
            pending.habitId,
            localHabitId: normalizedHabitId,
            remoteHabitId: normalizedRemoteHabitId,
          ) ||
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
          _pendingHabitMatches(
            operation.habitId,
            localHabitId: normalizedHabitId,
            remoteHabitId: normalizedRemoteHabitId,
          ) &&
          operation.logicalDateKey == normalizedDateKey &&
          operation.completionEventId == activeCompletionEventId &&
          operation.operationType == operationType,
    );
    final hasExistingPending = existingPendingBySource.isNotEmpty;
    final pendingOperation = hasExistingPending
        ? existingPendingBySource.first
        : PendingCurrencyOperation(
            userId: userId,
            requestId: activeRequestId,
            habitId: pendingHabitId,
            logicalDateKey: normalizedDateKey,
            completionEventId: activeCompletionEventId,
            operationType: operationType,
            createdAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
            lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
            attemptCount: 0,
            status: PendingCurrencyOperationStatus.pending,
          );

    if (!hasExistingPending) {
      await _upsertPendingOperation(pendingOperation);
    }

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
        habitId: activeRemoteHabitId,
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

        await _transactionRepository.saveTransaction(
            userId, updatedTransaction);
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

  Future<void> _upsertPendingOperation(
      PendingCurrencyOperation operation) async {
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

  Future<void> _savePendingAsAwaiting(
      PendingCurrencyOperation operation) async {
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
    final baseCoins =
        ledger.coinDelta < 0 ? -ledger.coinDelta : ledger.coinDelta;
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
              applyRequestId: operationType == HabitRewardOperationType.apply
                  ? requestId
                  : null,
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

  bool _isConfirmedCloudHabitRewardTransaction(
    HabitRewardTransaction? transaction,
  ) {
    final cloudOperationType = transaction?.cloudOperationType?.trim() ?? '';
    final applyRequestId = transaction?.applyRequestId?.trim() ?? '';
    final completionEventId = transaction?.completionEventId?.trim() ?? '';
    return transaction != null &&
        transaction.isReversed == false &&
        cloudOperationType == 'apply' &&
        applyRequestId.isNotEmpty &&
        completionEventId.isNotEmpty;
  }

  bool _isConfirmedCloudHabitRewardReversal(
    HabitRewardTransaction? transaction,
  ) {
    final cloudOperationType = transaction?.cloudOperationType?.trim() ?? '';
    final reverseRequestId = transaction?.reverseRequestId?.trim() ?? '';
    final completionEventId = transaction?.completionEventId?.trim() ?? '';
    return transaction != null &&
        transaction.isReversed == true &&
        cloudOperationType == 'reverse' &&
        reverseRequestId.isNotEmpty &&
        completionEventId.isNotEmpty;
  }

  String _resolveCompletionEventId({
    required HabitRewardOperationType operationType,
    required HabitRewardTransaction? transaction,
    required PendingCurrencyOperation? pendingOperation,
    required String? providedCompletionEventId,
    required String? remoteHabitId,
    required String logicalDateKey,
  }) {
    final pending = pendingOperation?.completionEventId.trim();
    if (pending != null && pending.isNotEmpty) {
      return pending;
    }

    final provided = providedCompletionEventId?.trim();
    if (provided != null && provided.isNotEmpty) {
      return provided;
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
      final remote = remoteHabitId?.trim();
      if (remote != null && remote.isNotEmpty) {
        return buildHabitRewardCompletionEventId(
          remoteHabitId: remote,
          logicalDateKey: logicalDateKey,
        );
      }
    }

    final remote = remoteHabitId?.trim();
    if (remote != null && remote.isNotEmpty) {
      return buildHabitRewardCompletionEventId(
        remoteHabitId: remote,
        logicalDateKey: logicalDateKey,
      );
    }

    return '';
  }

  String _normalizeRequestId({
    String? requestId,
    required PendingCurrencyOperation? pendingOperation,
    required String? remoteHabitId,
    required String logicalDateKey,
    required HabitRewardOperationType operationType,
  }) {
    final pending = pendingOperation?.requestId.trim();
    if (pending != null && pending.isNotEmpty) {
      return pending;
    }
    final provided = requestId?.trim();
    if (provided != null && provided.isNotEmpty) {
      return provided;
    }
    final remote = remoteHabitId?.trim();
    if (remote == null || remote.isEmpty) return '';
    if (operationType == HabitRewardOperationType.reverse) {
      return buildHabitRewardReverseRequestId(
        remoteHabitId: remote,
        logicalDateKey: logicalDateKey,
      );
    }
    return buildHabitRewardApplyRequestId(
      remoteHabitId: remote,
      logicalDateKey: logicalDateKey,
    );
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

  bool _pendingHabitMatches(
    String pendingHabitId, {
    required String localHabitId,
    required String? remoteHabitId,
  }) {
    final normalizedPending = pendingHabitId.trim();
    if (normalizedPending == localHabitId) return true;
    final normalizedRemote = remoteHabitId?.trim();
    return normalizedRemote != null &&
        normalizedRemote.isNotEmpty &&
        _normalizeRemoteHabitId(normalizedPending) == normalizedRemote;
  }

  static String? _normalizeRemoteHabitId(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty || !HabitRemoteMapper.isUuid(normalized)) {
      return null;
    }
    return normalized.toLowerCase();
  }
}
