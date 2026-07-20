import '../data/cloud/achievement_level_reward_errors.dart';
import '../data/cloud/achievement_level_reward_ledger.dart';
import '../data/cloud/achievement_level_reward_repository.dart';
import '../data/cloud/achievement_level_reward_config.dart';
import '../domain/models/pending_reward_claim.dart';
import '../domain/pending_reward_claim_store.dart';

class AchievementLevelRewardCoordinator {
  AchievementLevelRewardCoordinator({
    required AchievementLevelRewardRepository rewardRepository,
    required PendingRewardClaimStore pendingClaimStore,
    required String? Function() currentUserIdProvider,
    bool? enabled,
    DateTime Function()? nowProvider,
    int maxAutoRetries = 1,
  })  : _rewardRepository = rewardRepository,
        _pendingClaimStore = pendingClaimStore,
        _currentUserIdProvider = currentUserIdProvider,
        _enabled = AchievementLevelRewardConfig.resolveEnabled(override: enabled),
        _nowProvider = nowProvider ?? DateTime.now,
        _maxAutoRetries = maxAutoRetries;

  final AchievementLevelRewardRepository _rewardRepository;
  final PendingRewardClaimStore _pendingClaimStore;
  final String? Function() _currentUserIdProvider;
  final bool _enabled;
  final DateTime Function() _nowProvider;
  final int _maxAutoRetries;

  bool get isEnabled => _enabled;

  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimAchievementReward({
    required String achievementId,
    String? requestId,
  }) {
    return _execute(
      claimType: RewardClaimType.achievement,
      sourceId: achievementId,
      requestId: requestId,
    );
  }

  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimLevelReward({
    required int level,
    String? requestId,
  }) {
    return _execute(
      claimType: RewardClaimType.level,
      sourceId: level.toString(),
      requestId: requestId,
    );
  }

  Future<List<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>>
      resolvePendingForCurrentUser({
    int maxOperations = 5,
  }) async {
    if (!_enabled) {
      return const <AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>[];
    }

    final userId = _currentUserId();
    if (userId == null) {
      return const <AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>[];
    }

    final pending = await _pendingClaimStore.loadPendingClaims(userId);
    if (pending.isEmpty) {
      return const <AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>[];
    }

    final results =
        <AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>[];
    for (final operation in pending.take(maxOperations)) {
      final result = await _execute(
        claimType: operation.claimType,
        sourceId: operation.sourceId,
        requestId: operation.requestId,
      );
      results.add(result);
      if (!result.isSuccess && result.failure?.retryable == true) {
        break;
      }
    }
    return List<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>.unmodifiable(results);
  }

  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      _execute({
    required RewardClaimType claimType,
    required String sourceId,
    String? requestId,
  }) async {
    if (!_enabled) {
      return AchievementLevelRewardResult<
          AchievementLevelRewardLedgerEntry>.failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.featureDisabled,
          message: 'Cloud achievement and level rewards are disabled.',
          definitive: true,
        ),
      );
    }

    final userId = _currentUserId();
    if (userId == null) {
      return AchievementLevelRewardResult<
          AchievementLevelRewardLedgerEntry>.failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.unauthenticated,
          message: 'No authenticated user session is available.',
          definitive: true,
        ),
      );
    }

    final normalizedSourceId = sourceId.trim();
    if (normalizedSourceId.isEmpty) {
      return AchievementLevelRewardResult<
          AchievementLevelRewardLedgerEntry>.failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.invalidResponse,
          message: 'A reward source id is required.',
          definitive: true,
        ),
      );
    }

    final activeRequestId = _normalizeRequestId(
      requestId: requestId,
      userId: userId,
      claimType: claimType,
      sourceId: normalizedSourceId,
    );
    final existing = await _pendingClaimStore.loadPendingClaims(userId);
    final existingByRequest = existing.where((claim) => claim.requestId == activeRequestId);
    if (existingByRequest.isNotEmpty) {
      final current = existingByRequest.first;
      if (current.claimType != claimType || current.sourceId != normalizedSourceId) {
        return AchievementLevelRewardResult<
            AchievementLevelRewardLedgerEntry>.failure(
          failure: AchievementLevelRewardFailure(
            code: AchievementLevelRewardFailureCode.requestConflict,
            message: 'request_id is already bound to another reward claim.',
            definitive: true,
          ),
        );
      }
    }

    final pendingOperation = PendingRewardClaim(
      userId: userId,
      requestId: activeRequestId,
      claimType: claimType,
      sourceId: normalizedSourceId,
      createdAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
      lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
      attemptCount: 0,
      status: PendingRewardClaimStatus.pending,
    );
    await _upsertPendingClaim(pendingOperation);

    final maxAttempts = 1 + (_maxAutoRetries < 0 ? 0 : _maxAutoRetries);
    AchievementLevelRewardFailure? lastFailure;
    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      final attemptClaim = pendingOperation.copyWith(
        lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
        attemptCount: pendingOperation.attemptCount + attempt,
        status: attempt == 1
            ? PendingRewardClaimStatus.pending
            : PendingRewardClaimStatus.awaitingResolution,
      );
      await _upsertPendingClaim(attemptClaim);

      final response = claimType == RewardClaimType.achievement
          ? await _rewardRepository.claimAchievementReward(
              requestId: activeRequestId,
              achievementId: normalizedSourceId,
            )
          : await _rewardRepository.claimLevelReward(
              requestId: activeRequestId,
              level: int.tryParse(normalizedSourceId) ?? 0,
            );

      if (response.isSuccess && response.data != null) {
        final ledger = response.data!;
        if (ledger.userId != userId) {
          final failure = const AchievementLevelRewardFailure(
            code: AchievementLevelRewardFailureCode.sessionChanged,
            message: 'Authentication session changed during reward claim.',
            definitive: true,
          );
          await _savePendingAsAwaiting(attemptClaim);
          return AchievementLevelRewardResult<
              AchievementLevelRewardLedgerEntry>.failure(
            failure: failure,
          );
        }

        await _removePendingClaim(userId, activeRequestId);
        return AchievementLevelRewardResult<
            AchievementLevelRewardLedgerEntry>.success(data: ledger);
      }

      lastFailure = response.failure;
      if (lastFailure == null) {
        break;
      }

      if (lastFailure.retryable && attempt < maxAttempts) {
        continue;
      }

      if (lastFailure.definitive) {
        await _removePendingClaim(userId, activeRequestId);
        return AchievementLevelRewardResult<
            AchievementLevelRewardLedgerEntry>.failure(
          failure: lastFailure,
        );
      }

      await _savePendingAsAwaiting(attemptClaim);
      return AchievementLevelRewardResult<
          AchievementLevelRewardLedgerEntry>.failure(
        failure: lastFailure,
      );
    }

    final awaiting = pendingOperation.copyWith(
      status: PendingRewardClaimStatus.awaitingResolution,
      lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
      attemptCount: maxAttempts,
    );
    await _savePendingAsAwaiting(awaiting);
    return AchievementLevelRewardResult<
        AchievementLevelRewardLedgerEntry>.failure(
      failure: lastFailure ??
          const AchievementLevelRewardFailure(
            code: AchievementLevelRewardFailureCode.unknown,
            message: 'Cloud reward claim is pending resolution.',
            retryable: true,
          ),
    );
  }

  Future<void> _upsertPendingClaim(PendingRewardClaim claim) async {
    final userId = claim.userId.trim();
    if (userId.isEmpty) return;

    final current = await _pendingClaimStore.loadPendingClaims(userId);
    final next = <PendingRewardClaim>[
      ...current.where((entry) => entry.requestId != claim.requestId),
      claim,
    ]..sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.requestId.compareTo(b.requestId);
      });
    await _pendingClaimStore.savePendingClaims(userId, next);
  }

  Future<void> _savePendingAsAwaiting(PendingRewardClaim claim) async {
    await _upsertPendingClaim(
      claim.copyWith(status: PendingRewardClaimStatus.awaitingResolution),
    );
  }

  Future<void> _removePendingClaim(String userId, String requestId) async {
    final current = await _pendingClaimStore.loadPendingClaims(userId);
    final next = current.where((claim) => claim.requestId != requestId).toList(
          growable: false,
        );
    if (next.length == current.length) return;
    await _pendingClaimStore.savePendingClaims(userId, next);
  }

  String _normalizeRequestId({
    String? requestId,
    required String userId,
    required RewardClaimType claimType,
    required String sourceId,
  }) {
    final normalized = (requestId ?? '').trim();
    if (normalized.isNotEmpty) return normalized;
    return 'reward:${userId.trim()}:${claimType.name}:$sourceId';
  }

  String? _currentUserId() {
    try {
      final userId = _currentUserIdProvider()?.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }
}
