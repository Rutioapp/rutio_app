import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/achievements/application/achievement_level_reward_coordinator.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_errors.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_ledger.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_repository.dart';
import 'package:rutio/features/achievements/domain/models/pending_reward_claim.dart';
import 'package:rutio/features/achievements/domain/pending_reward_claim_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AchievementLevelRewardCoordinator', () {
    test('achievement reward is claimed once', () async {
      final repo = _FakeAchievementLevelRewardRepository();
      final pendingStore = _MemoryPendingRewardClaimStore();
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
      );

      final first = await coordinator.claimAchievementReward(
        achievementId: 'special:flash',
      );
      final second = await coordinator.claimAchievementReward(
        achievementId: 'special:flash',
      );

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(repo.achievementChargeCount, 1);
      expect(repo.achievementCallCount, 2);
      expect(first.data?.requestId, second.data?.requestId);
    });

    test('double level claim does not duplicate the reward', () async {
      final repo = _FakeAchievementLevelRewardRepository();
      final pendingStore = _MemoryPendingRewardClaimStore();
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
      );

      final first = await coordinator.claimLevelReward(level: 5);
      final second = await coordinator.claimLevelReward(level: 5);

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(repo.levelChargeCount, 1);
      expect(repo.levelCallCount, 2);
    });

    test('timeout leaves the operation pending and retry resolves it',
        () async {
      final repo = _FakeAchievementLevelRewardRepository();
      final pendingStore = _MemoryPendingRewardClaimStore();
      repo.enqueueAchievementFailure(
        'special:flash',
        const AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.timeout,
          message: 'timeout',
          retryable: true,
        ),
      );
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );

      final first = await coordinator.claimAchievementReward(
        achievementId: 'special:flash',
      );
      final pending = await pendingStore.loadPendingClaims('user-1');
      final second = await coordinator.claimAchievementReward(
        achievementId: 'special:flash',
      );

      expect(first.isSuccess, isFalse);
      expect(first.failure?.code, AchievementLevelRewardFailureCode.timeout);
      expect(pending, hasLength(1));
      expect(second.isSuccess, isTrue);
      expect(repo.achievementChargeCount, 1);
      expect(repo.achievementCallCount, 2);
      expect(repo.achievementRequests.first, repo.achievementRequests.last);
      expect(await pendingStore.loadPendingClaims('user-1'), isEmpty);
    });

    test('restart reuses the pending request id', () async {
      final repo = _FakeAchievementLevelRewardRepository();
      final pendingStore = _MemoryPendingRewardClaimStore();
      repo.enqueueLevelFailure(
        5,
        const AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.networkUnavailable,
          message: 'offline',
          retryable: true,
        ),
      );
      final firstCoordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );

      final first = await firstCoordinator.claimLevelReward(level: 5);
      expect(first.isSuccess, isFalse);
      expect(await pendingStore.loadPendingClaims('user-1'), hasLength(1));

      final secondCoordinator =
          _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
        maxAutoRetries: 0,
      );
      final second = await secondCoordinator.claimLevelReward(level: 5);

      expect(second.isSuccess, isTrue);
      expect(repo.levelChargeCount, 1);
      expect(repo.levelRequests.first, repo.levelRequests.last);
      expect(await pendingStore.loadPendingClaims('user-1'), isEmpty);
    });

    test('change of user is rejected and keeps the pending claim', () async {
      final repo = _FakeAchievementLevelRewardRepository(responseUserId: 'user-2');
      final pendingStore = _MemoryPendingRewardClaimStore();
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
      );

      final result = await coordinator.claimAchievementReward(
        achievementId: 'special:flash',
      );
      final pending = await pendingStore.loadPendingClaims('user-1');

      expect(result.isSuccess, isFalse);
      expect(result.failure?.code, AchievementLevelRewardFailureCode.sessionChanged);
      expect(pending, hasLength(1));
    });

    test('multiple levels claim independently', () async {
      final repo = _FakeAchievementLevelRewardRepository();
      final pendingStore = _MemoryPendingRewardClaimStore();
      final coordinator = _createCoordinator(
        repo: repo,
        pendingStore: pendingStore,
      );

      final first = await coordinator.claimLevelReward(level: 5);
      final second = await coordinator.claimLevelReward(level: 10);

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(repo.levelChargeCount, 2);
      expect(repo.levelRequests, hasLength(2));
    });

    test('feature disabled returns a legacy-safe skip', () async {
      final repo = _FakeAchievementLevelRewardRepository();
      final pendingStore = _MemoryPendingRewardClaimStore();
      final coordinator = AchievementLevelRewardCoordinator(
        rewardRepository: repo,
        pendingClaimStore: pendingStore,
        currentUserIdProvider: () => 'user-1',
        enabled: false,
      );

      final result = await coordinator.claimAchievementReward(
        achievementId: 'special:flash',
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure?.code, AchievementLevelRewardFailureCode.featureDisabled);
      expect(repo.achievementCallCount, 0);
    });
  });
}

AchievementLevelRewardCoordinator _createCoordinator({
  required _FakeAchievementLevelRewardRepository repo,
  required _MemoryPendingRewardClaimStore pendingStore,
  int maxAutoRetries = 1,
}) {
  return AchievementLevelRewardCoordinator(
    rewardRepository: repo,
    pendingClaimStore: pendingStore,
    currentUserIdProvider: () => 'user-1',
    maxAutoRetries: maxAutoRetries,
    enabled: true,
  );
}

class _FakeAchievementLevelRewardRepository
    implements AchievementLevelRewardRepository {
  _FakeAchievementLevelRewardRepository({
    this.responseUserId = 'user-1',
  });

  final String responseUserId;
  final int defaultAchievementReward = 25;
  final Map<String, Queue<AchievementLevelRewardFailure>> _achievementFailures =
      <String, Queue<AchievementLevelRewardFailure>>{};
  final Map<String, Queue<AchievementLevelRewardFailure>> _levelFailures =
      <String, Queue<AchievementLevelRewardFailure>>{};
  final Map<String, AchievementLevelRewardLedgerEntry> _ledgerBySource =
      <String, AchievementLevelRewardLedgerEntry>{};
  final Map<String, int> _balanceByUser = <String, int>{};

  int achievementCallCount = 0;
  int achievementChargeCount = 0;
  int levelCallCount = 0;
  int levelChargeCount = 0;
  final List<String> achievementRequests = <String>[];
  final List<String> levelRequests = <String>[];

  void enqueueAchievementFailure(
    String achievementId,
    AchievementLevelRewardFailure failure,
  ) {
    (_achievementFailures[achievementId] ??= Queue<AchievementLevelRewardFailure>())
        .add(failure);
  }

  void enqueueLevelFailure(int level, AchievementLevelRewardFailure failure) {
    (_levelFailures[level.toString()] ??= Queue<AchievementLevelRewardFailure>())
        .add(failure);
  }

  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimAchievementReward({
    required String requestId,
    required String achievementId,
  }) async {
    achievementCallCount += 1;
    achievementRequests.add(requestId);
    final queued = _achievementFailures[achievementId];
    if (queued != null && queued.isNotEmpty) {
      final failure = queued.removeFirst();
      return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
          .failure(failure: failure);
    }

    return _claim(
      requestId: requestId,
      sourceType: 'achievement_reward',
      sourceId: achievementId,
      amount: defaultAchievementReward,
      chargeCounter: () => achievementChargeCount += 1,
    );
  }

  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimLevelReward({
    required String requestId,
    required int level,
  }) async {
    levelCallCount += 1;
    levelRequests.add(requestId);
    final queued = _levelFailures[level.toString()];
    if (queued != null && queued.isNotEmpty) {
      final failure = queued.removeFirst();
      return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
          .failure(failure: failure);
    }

    return _claim(
      requestId: requestId,
      sourceType: 'level_reward',
      sourceId: level.toString(),
      amount: level >= 5
          ? (level == 5
              ? 50
              : level == 10
                  ? 150
                  : 0)
          : 0,
      chargeCounter: () => levelChargeCount += 1,
    );
  }

  AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry> _claim({
    required String requestId,
    required String sourceType,
    required String sourceId,
    required int amount,
    required void Function() chargeCounter,
  }) {
    final sourceKey = '$sourceType|$sourceId';
    final existing = _ledgerBySource[sourceKey];
    if (existing != null) {
      return AchievementLevelRewardResult<
          AchievementLevelRewardLedgerEntry>.success(
        data: AchievementLevelRewardLedgerEntry(
          id: existing.id,
          userId: existing.userId,
          requestId: requestId,
          operationType: existing.operationType,
          sourceType: existing.sourceType,
          sourceId: existing.sourceId,
          coinDelta: existing.coinDelta,
          balanceAfter: existing.balanceAfter,
          createdAt: existing.createdAt,
          isIdempotent: true,
          relatedLedgerId: existing.relatedLedgerId,
        ),
      );
    }

    chargeCounter();
    final nextBalance = (_balanceByUser[responseUserId] ?? 0) + amount;
    final ledger = AchievementLevelRewardLedgerEntry(
      id: '${sourceType}_$sourceId',
      userId: responseUserId,
      requestId: requestId,
      operationType: 'claim',
      sourceType: sourceType,
      sourceId: sourceId,
      coinDelta: amount,
      balanceAfter: nextBalance,
      createdAt: DateTime(2026, 7, 19),
      isIdempotent: false,
    );
    _balanceByUser[responseUserId] = nextBalance;
    _ledgerBySource[sourceKey] = ledger;
    return AchievementLevelRewardResult<
        AchievementLevelRewardLedgerEntry>.success(data: ledger);
  }
}

class _MemoryPendingRewardClaimStore implements PendingRewardClaimStore {
  final Map<String, List<PendingRewardClaim>> _entries =
      <String, List<PendingRewardClaim>>{};

  @override
  Future<List<PendingRewardClaim>> loadPendingClaims(String userId) async {
    return List<PendingRewardClaim>.from(_entries[userId] ?? const <PendingRewardClaim>[]);
  }

  @override
  Future<void> savePendingClaims(
    String userId,
    List<PendingRewardClaim> claims,
  ) async {
    _entries[userId] = List<PendingRewardClaim>.from(claims);
  }

  @override
  Future<void> clearPendingClaims(String userId) async {
    _entries.remove(userId);
  }
}
