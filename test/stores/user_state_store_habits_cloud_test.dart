import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/habits/application/habit_currency_reward_coordinator.dart';
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_errors.dart';
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_ledger.dart';
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_repository.dart';
import 'package:rutio/features/habits/domain/habit_reward_transaction_repository.dart';
import 'package:rutio/features/habits/domain/models/habit_reward_transaction.dart';
import 'package:rutio/features/habits/domain/models/pending_currency_operation.dart';
import 'package:rutio/features/habits/domain/pending_currency_operation_store.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_state.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/global_wallet/data/cloud/wallet_cache.dart';
import 'package:rutio/features/shop/domain/active_utility_effects_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _remoteHabitUuid1 = '11111111-1111-4111-8111-111111111111';
const String _remoteHabitUuid2 = '22222222-2222-4222-8222-222222222222';
const String _remoteHabitUuid3 = '33333333-3333-4333-8333-333333333333';
const String _remoteHabitUuid4 = '44444444-4444-4444-8444-444444444444';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore habit cloud rewards', () {
    test(
        'habit without a previous transaction calls the RPC and consumes boost',
        () async {
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-1',
        cloudHabitRewardsEnabled: true,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid1,
          ),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
          ),
        ],
        rewardHandler: (request, effects) {
          effects.consumeEffect('cloud-habit-user-1', 'xp-boost');
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-1',
              coinDelta: 8,
              balanceAfter: 18,
              baseXp: 10,
              bonusXp: 5,
              bonusCoins: 3,
              appliedEffectIds: const <String>['xp-boost'],
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(fixture.rewardRepository.applyCalls, 1);
      expect(fixture.rewardRepository.applyRequests.single.habitId,
          _remoteHabitUuid1);
      expect(
        fixture.rewardRepository.applyRequests.single.completionEventId,
        'habit_cloud_reward|$_remoteHabitUuid1|2026-07-18',
      );
      expect(
        fixture.rewardRepository.applyRequests.single.requestId,
        'habit_cloud_reward_apply|$_remoteHabitUuid1|2026-07-18',
      );
      expect(
        fixture.rewardRepository.applyRequests.single.requestId,
        isNot(contains('habit-check')),
      );
      expect(fixture.transactions, hasLength(1));
      expect(fixture.transactions.single.cloudOperationType, 'apply');
      expect(fixture.transactions.single.applyRequestId, isNotEmpty);
      expect(
          fixture.transactions.single.appliedEffectIds, contains('xp-boost'));
      expect(_xp(fixture.store), 0);
      expect(_coins(fixture.store), 0);
      expect((await fixture.effects()).single.remainingUses, 9);
    });

    test('confirmed reward updates GlobalWalletController immediately',
        () async {
      final walletCache = _MemoryWalletCache();
      final walletController = GlobalWalletController(
        repository: _NeverWalletRepository(),
        cache: walletCache,
        currentUserIdProvider: () => 'cloud-habit-user-wallet-1',
        enabled: true,
        nowProvider: () => DateTime.utc(2026, 7, 18, 12),
      );
      var walletNotifications = 0;
      walletController.addListener(() {
        walletNotifications += 1;
      });
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-wallet-1',
        cloudHabitRewardsEnabled: true,
        globalWalletController: walletController,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid1,
          ),
        ],
        activeEffects: const <ActiveUtilityEffect>[],
        rewardHandler: (request, effects) {
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-wallet-1',
              coinDelta: 10,
              balanceAfter: 5010,
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(walletController.state.status, GlobalWalletStatus.ready);
      expect(walletController.state.coins, 5010);
      expect(walletCache.readSync('cloud-habit-user-wallet-1')?.coins, 5010);
      expect(walletNotifications, 1);
    });

    test('uses balanceAfter instead of adding coinDelta locally', () async {
      final walletController = GlobalWalletController(
        repository: _NeverWalletRepository(),
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'cloud-habit-user-wallet-2',
        enabled: true,
      );
      await walletController.applyConfirmedBalance(
        userId: 'cloud-habit-user-wallet-2',
        coins: 5000,
        version: 1,
        updatedAt: DateTime.utc(2026, 7, 18, 11),
      );
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-wallet-2',
        cloudHabitRewardsEnabled: true,
        globalWalletController: walletController,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid1,
          ),
        ],
        activeEffects: const <ActiveUtilityEffect>[],
        rewardHandler: (request, effects) {
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-wallet-2',
              coinDelta: 10,
              balanceAfter: 7000,
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(walletController.state.coins, 7000);
    });

    test('idempotent reward response does not duplicate coins', () async {
      final walletController = GlobalWalletController(
        repository: _NeverWalletRepository(),
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'cloud-habit-user-wallet-3',
        enabled: true,
      );
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-wallet-3',
        cloudHabitRewardsEnabled: true,
        globalWalletController: walletController,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid1,
          ),
        ],
        activeEffects: const <ActiveUtilityEffect>[],
        rewardHandler: (request, effects) {
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-wallet-3',
              coinDelta: 10,
              balanceAfter: 5010,
              isIdempotent: true,
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await walletController.applyConfirmedBalance(
        userId: 'cloud-habit-user-wallet-3',
        coins: 5010,
        updatedAt: DateTime.utc(2026, 7, 18, 12),
      );

      expect(walletController.state.coins, 5010);
    });

    test('consecutive rewards apply the final confirmed balance', () async {
      var call = 0;
      final walletController = GlobalWalletController(
        repository: _NeverWalletRepository(),
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'cloud-habit-user-wallet-4',
        enabled: true,
      );
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-wallet-4',
        cloudHabitRewardsEnabled: true,
        globalWalletController: walletController,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid1,
          ),
          _habit(
            id: 'habit-count',
            type: 'count',
            target: 5,
            remoteId: _remoteHabitUuid2,
          ),
        ],
        activeEffects: const <ActiveUtilityEffect>[],
        rewardHandler: (request, effects) {
          call += 1;
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-wallet-4',
              coinDelta: 10,
              balanceAfter: call == 1 ? 5010 : 5020,
              createdAt: DateTime.utc(2026, 7, 18, 12, call),
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await fixture.store.setCountHabitValue(habitId: 'habit-count', value: 5);

      expect(walletController.state.coins, 5020);
    });

    test('remote error preserves the previous visible wallet balance',
        () async {
      final walletController = GlobalWalletController(
        repository: _NeverWalletRepository(),
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'cloud-habit-user-wallet-5',
        enabled: true,
      );
      await walletController.applyConfirmedBalance(
        userId: 'cloud-habit-user-wallet-5',
        coins: 5000,
        updatedAt: DateTime.utc(2026, 7, 18, 11),
      );
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-wallet-5',
        cloudHabitRewardsEnabled: true,
        globalWalletController: walletController,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid1,
          ),
        ],
        activeEffects: const <ActiveUtilityEffect>[],
        rewardHandler: (request, effects) {
          return HabitCurrencyRewardResult.failure(
            failure: const HabitCurrencyRewardFailure(
              code: HabitCurrencyRewardFailureCode.networkUnavailable,
              message: 'offline',
              retryable: true,
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(walletController.state.coins, 5000);
      expect(fixture.rewardRepository.applyCalls, greaterThanOrEqualTo(1));
    });

    test('local mode does not touch GlobalWalletController', () async {
      final walletController = GlobalWalletController(
        repository: _NeverWalletRepository(),
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'local-habit-wallet-user',
        enabled: true,
      );
      final fixture = await _seedFixture(
        scopeUserId: 'local-habit-wallet-user',
        cloudHabitRewardsEnabled: false,
        globalWalletController: walletController,
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: const <ActiveUtilityEffect>[],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(walletController.state.status, GlobalWalletStatus.unauthenticated);
      expect(_coins(fixture.store), greaterThan(0));
    });

    test('legacy local transaction does not block the cloud RPC', () async {
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-2',
        cloudHabitRewardsEnabled: true,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteHabitId: _remoteHabitUuid2,
          ),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
          ),
        ],
        initialTransactions: <HabitRewardTransaction>[
          HabitRewardTransaction(
            id: 'habit-check|2026-07-18',
            habitId: 'habit-check',
            localDateKey: '2026-07-18',
            baseXp: 10,
            bonusXp: 5,
            baseCoins: 5,
            bonusCoins: 3,
            appliedEffectIds: const <String>['legacy-xp'],
            createdAtMillis:
                DateTime.utc(2026, 7, 18, 12).millisecondsSinceEpoch,
            isReversed: false,
          ),
        ],
        rewardHandler: (request, effects) {
          effects.consumeEffect('cloud-habit-user-2', 'xp-boost');
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-2',
              coinDelta: 8,
              balanceAfter: 18,
              baseXp: 10,
              bonusXp: 5,
              bonusCoins: 3,
              appliedEffectIds: const <String>['xp-boost'],
            ),
          );
        },
      );

      final root = fixture.store.state as Map<String, dynamic>;
      final userState = root['userState'] as Map<String, dynamic>;
      final progression = userState['progression'] as Map<String, dynamic>;
      final wallet = userState['wallet'] as Map<String, dynamic>;
      progression['xp'] = 15;
      wallet['coins'] = 8;
      await fixture.store.save(root);

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(fixture.rewardRepository.applyCalls, 1);
      expect(fixture.rewardRepository.applyRequests.single.habitId,
          _remoteHabitUuid2);
      expect(
        fixture.rewardRepository.applyRequests.single.completionEventId,
        'habit_cloud_reward|$_remoteHabitUuid2|2026-07-18',
      );
      expect(
        fixture.rewardRepository.applyRequests.single.requestId,
        'habit_cloud_reward_apply|$_remoteHabitUuid2|2026-07-18',
      );
      expect(fixture.transactions, hasLength(1));
      expect(fixture.transactions.single.cloudOperationType, 'apply');
      expect(_xp(fixture.store), 15);
      expect(_coins(fixture.store), 8);
      expect((await fixture.effects()).single.remainingUses, 9);
    });

    test('cloud confirmed transaction avoids duplicate completion', () async {
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-3',
        cloudHabitRewardsEnabled: true,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            supabaseHabitId: _remoteHabitUuid3,
          ),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
            remainingUses: 9,
          ),
        ],
        initialTransactions: <HabitRewardTransaction>[
          HabitRewardTransaction(
            id: 'habit-check|2026-07-18',
            habitId: 'habit-check',
            localDateKey: '2026-07-18',
            completionEventId: 'event-cloud-confirmed-1',
            applyRequestId: 'request-apply-cloud',
            cloudOperationType: 'apply',
            baseXp: 10,
            bonusXp: 5,
            baseCoins: 5,
            bonusCoins: 3,
            appliedEffectIds: const <String>['xp-boost'],
            createdAtMillis:
                DateTime.utc(2026, 7, 18, 12).millisecondsSinceEpoch,
            isReversed: false,
          ),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(fixture.rewardRepository.applyCalls, 0);
      expect(fixture.transactions, hasLength(1));
      expect((await fixture.effects()).single.remainingUses, 9);
    });

    test('migrating from local to cloud does not duplicate xp or coins',
        () async {
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-4',
        cloudHabitRewardsEnabled: true,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid4,
          ),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
          ),
          _effect(
            id: 'coin-boost',
            utilityId: 'utility_coin_boost_1d',
            type: ActiveUtilityEffectType.coinBoost,
          ),
        ],
        initialTransactions: <HabitRewardTransaction>[
          HabitRewardTransaction(
            id: 'habit-check|2026-07-18',
            habitId: 'habit-check',
            localDateKey: '2026-07-18',
            baseXp: 10,
            bonusXp: 5,
            baseCoins: 5,
            bonusCoins: 3,
            appliedEffectIds: const <String>['legacy-xp', 'legacy-coin'],
            createdAtMillis:
                DateTime.utc(2026, 7, 18, 12).millisecondsSinceEpoch,
            isReversed: false,
          ),
        ],
        rewardHandler: (request, effects) {
          effects.consumeEffect('cloud-habit-user-4', 'xp-boost');
          effects.consumeEffect('cloud-habit-user-4', 'coin-boost');
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-4',
              coinDelta: 8,
              balanceAfter: 18,
              baseXp: 10,
              bonusXp: 5,
              bonusCoins: 3,
              appliedEffectIds: const <String>['xp-boost', 'coin-boost'],
            ),
          );
        },
      );

      final root = fixture.store.state as Map<String, dynamic>;
      final userState = root['userState'] as Map<String, dynamic>;
      final progression = userState['progression'] as Map<String, dynamic>;
      final wallet = userState['wallet'] as Map<String, dynamic>;
      progression['xp'] = 15;
      wallet['coins'] = 8;
      await fixture.store.save(root);

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(_xp(fixture.store), 15);
      expect(_coins(fixture.store), 8);
      expect(fixture.rewardRepository.applyCalls, 1);
      expect(fixture.rewardRepository.applyRequests.single.habitId,
          _remoteHabitUuid4);
      expect(fixture.transactions, hasLength(1));
      expect(fixture.transactions.single.cloudOperationType, 'apply');
      final effects = await fixture.effects();
      expect(
        effects,
        isNotEmpty,
      );
      expect(
        effects.any(
            (effect) => effect.id == 'xp-boost' && effect.remainingUses == 9),
        isTrue,
      );
      expect(
        effects.any(
          (effect) => effect.id == 'coin-boost' && effect.remainingUses == 9,
        ),
        isTrue,
      );
    });

    test('check and count habits both use the cloud path', () async {
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-5',
        cloudHabitRewardsEnabled: true,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid1,
          ),
          _habit(
            id: 'habit-count',
            type: 'count',
            target: 5,
            supabaseHabitId: _remoteHabitUuid2,
          ),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
          ),
        ],
        rewardHandler: (request, effects) {
          if (request.habitId == _remoteHabitUuid1) {
            return HabitCurrencyRewardResult.success(
              data: _ledgerFor(
                request: request,
                userId: 'cloud-habit-user-5',
                coinDelta: 5,
                balanceAfter: 5,
                baseXp: 10,
                bonusXp: 5,
                bonusCoins: 0,
                appliedEffectIds: const <String>[],
              ),
            );
          }
          effects.consumeEffect('cloud-habit-user-5', 'xp-boost');
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-5',
              coinDelta: 6,
              balanceAfter: 11,
              baseXp: 12,
              bonusXp: 6,
              bonusCoins: 0,
              appliedEffectIds: const <String>['xp-boost'],
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await fixture.store.setCountHabitValue(habitId: 'habit-count', value: 5);

      expect(fixture.rewardRepository.applyCalls, 2);
      expect(
          fixture.rewardRepository.applyRequests
              .map((request) => request.habitId),
          containsAll(<String>{_remoteHabitUuid1, _remoteHabitUuid2}));
      expect(fixture.transactions, hasLength(2));
      expect(
        fixture.transactions.map((tx) => tx.habitId).toSet(),
        containsAll(<String>{'habit-check', 'habit-count'}),
      );
      expect(
        (await fixture.effects()).any(
          (effect) => effect.id == 'xp-boost' && effect.remainingUses == 9,
        ),
        isTrue,
      );
    });

    test('double completion is idempotent in cloud mode', () async {
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-6',
        cloudHabitRewardsEnabled: true,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteId: _remoteHabitUuid1,
          ),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
          ),
        ],
        rewardHandler: (request, effects) {
          effects.consumeEffect('cloud-habit-user-6', 'xp-boost');
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-6',
              coinDelta: 8,
              balanceAfter: 8,
              baseXp: 10,
              bonusXp: 5,
              bonusCoins: 3,
              appliedEffectIds: const <String>['xp-boost'],
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(fixture.rewardRepository.applyCalls, 1);
      expect(fixture.transactions, hasLength(1));
    });

    test('missing remote UUID does not create a partial cloud reward',
        () async {
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-7',
        cloudHabitRewardsEnabled: true,
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
          ),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(fixture.rewardRepository.applyCalls, 0);
      expect(fixture.transactions, isEmpty);
      expect(_xp(fixture.store), 0);
      expect(_coins(fixture.store), 0);
      expect((await fixture.effects()).single.remainingUses, 10);
    });

    test('reversal uses the same remote UUID and keeps local ids intact',
        () async {
      final fixture = await _seedFixture(
        scopeUserId: 'cloud-habit-user-8',
        cloudHabitRewardsEnabled: true,
        habits: <Map<String, dynamic>>[
          _habit(
            id: 'habit-check',
            type: 'check',
            target: 1,
            remoteHabitId: _remoteHabitUuid2,
          ),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
          ),
        ],
        rewardHandler: (request, effects) {
          effects.consumeEffect('cloud-habit-user-8', 'xp-boost');
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-8',
              coinDelta: 8,
              balanceAfter: 8,
              baseXp: 10,
              bonusXp: 5,
              bonusCoins: 3,
              appliedEffectIds: const <String>['xp-boost'],
            ),
          );
        },
        reverseHandler: (request, effects) {
          effects.consumeEffect('cloud-habit-user-8', 'xp-boost');
          return HabitCurrencyRewardResult.success(
            data: _ledgerFor(
              request: request,
              userId: 'cloud-habit-user-8',
              coinDelta: -8,
              balanceAfter: 0,
              baseXp: 10,
              bonusXp: 5,
              bonusCoins: 3,
              appliedEffectIds: const <String>['xp-boost'],
            ),
          );
        },
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await fixture.store.setHabitSkip(
        habitId: 'habit-check',
        date: DateTime.utc(2026, 7, 18, 12),
        skipped: true,
      );

      expect(fixture.rewardRepository.applyCalls, 1);
      expect(fixture.rewardRepository.reverseCalls, 1);
      expect(fixture.rewardRepository.applyRequests.single.habitId,
          _remoteHabitUuid2);
      expect(fixture.rewardRepository.reverseRequests.single.habitId,
          _remoteHabitUuid2);
      expect(
        fixture.rewardRepository.reverseRequests.single.completionEventId,
        'habit_cloud_reward|$_remoteHabitUuid2|2026-07-18',
      );
      expect(
        fixture.rewardRepository.reverseRequests.single.requestId,
        'habit_cloud_reward_reverse|$_remoteHabitUuid2|2026-07-18',
      );
      expect(
        fixture.rewardRepository.applyRequests.single.requestId,
        isNot(fixture.rewardRepository.reverseRequests.single.requestId),
      );
    });

    test('local mode remains intact', () async {
      final fixture = await _seedFixture(
        scopeUserId: 'local-habit-user-1',
        cloudHabitRewardsEnabled: false,
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-boost',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
          ),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(fixture.rewardRepository.applyCalls, 0);
      expect(fixture.transactions, hasLength(1));
      expect((await fixture.effects()).single.remainingUses, 9);
      expect(_xp(fixture.store), greaterThan(0));
      expect(_coins(fixture.store), greaterThan(0));
    });
  });
}

Future<_Fixture> _seedFixture({
  required String scopeUserId,
  required bool cloudHabitRewardsEnabled,
  required List<Map<String, dynamic>> habits,
  required List<ActiveUtilityEffect> activeEffects,
  List<HabitRewardTransaction> initialTransactions =
      const <HabitRewardTransaction>[],
  HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry> Function(
    _HabitCurrencyRewardRequest request,
    _TrackingActiveUtilityEffectsRepository effects,
  )? rewardHandler,
  HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry> Function(
    _HabitCurrencyRewardRequest request,
    _TrackingActiveUtilityEffectsRepository effects,
  )? reverseHandler,
  GlobalWalletController? globalWalletController,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final activeEffectsRepository = _TrackingActiveUtilityEffectsRepository(
    initial: <String, List<ActiveUtilityEffect>>{
      scopeUserId: activeEffects,
    },
  );
  final transactionRepository = _MemoryHabitRewardTransactionRepository(
    initial: <String, List<HabitRewardTransaction>>{
      scopeUserId: initialTransactions,
    },
  );
  final rewardRepository = _FakeHabitCurrencyRewardRepository(
    rewardHandler: rewardHandler,
    reverseHandler: reverseHandler,
    effectsRepository: activeEffectsRepository,
  );
  final coordinator = _createCoordinator(
    repo: rewardRepository,
    transactionRepository: transactionRepository,
    userId: scopeUserId,
  );
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(scopeUserId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    nowProvider: () => DateTime.utc(2026, 7, 18, 12),
    activeUtilityEffectsRepository: activeEffectsRepository,
    habitCurrencyRewardCoordinator: coordinator,
    habitRewardTransactionRepository: transactionRepository,
    cloudHabitRewardsEnabledOverride: cloudHabitRewardsEnabled,
    globalWalletController: globalWalletController,
    currentSupabaseUserIdProvider: () => scopeUserId,
  );
  await store.save(
    _baseState(
      userId: scopeUserId,
      habits: habits,
      dateKey: '2026-07-18',
    ),
  );

  return _Fixture(
    store: store,
    rewardRepository: rewardRepository,
    activeEffectsRepository: activeEffectsRepository,
    transactionRepository: transactionRepository,
    scopeUserId: scopeUserId,
  );
}

HabitCurrencyRewardCoordinator _createCoordinator({
  required _FakeHabitCurrencyRewardRepository repo,
  required _MemoryHabitRewardTransactionRepository transactionRepository,
  required String userId,
}) {
  return HabitCurrencyRewardCoordinator(
    rewardRepository: repo,
    pendingOperationStore: _NoopPendingCurrencyOperationStore(),
    transactionRepository: transactionRepository,
    currentUserIdProvider: () => userId,
  );
}

HabitCurrencyRewardLedgerEntry _ledgerFor({
  required _HabitCurrencyRewardRequest request,
  required String userId,
  required int coinDelta,
  required int balanceAfter,
  int baseXp = 0,
  int bonusXp = 0,
  int bonusCoins = 0,
  List<String> appliedEffectIds = const <String>[],
  DateTime? createdAt,
  bool isIdempotent = false,
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
    createdAt: createdAt ?? DateTime.utc(2026, 7, 18, 12, 0, 0),
    isIdempotent: isIdempotent,
    baseXp: baseXp,
    bonusXp: bonusXp,
    bonusCoins: bonusCoins,
    appliedEffectIds: appliedEffectIds,
    relatedLedgerId: null,
  );
}

Map<String, dynamic> _baseState({
  required String userId,
  required List<Map<String, dynamic>> habits,
  required String dateKey,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': userId,
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': '2026-07-18T12:00:00.000Z',
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'progression': <String, dynamic>{
        'level': 1,
        'xp': 0,
        'prestige': 0,
      },
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
        'lastResetDate': dateKey,
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
      },
      'familyXp': <String, dynamic>{
        'mind': 0,
        'spirit': 0,
        'body': 0,
        'emotional': 0,
        'social': 0,
        'discipline': 0,
        'professional': 0,
      },
      'activeHabits': habits,
    },
  };
}

Map<String, dynamic> _habit({
  required String id,
  required String type,
  required num target,
  String? remoteId,
  String? remoteHabitId,
  String? supabaseHabitId,
}) {
  return <String, dynamic>{
    'id': id,
    'createdAt': '2026-07-18',
    'name': 'Habit $id',
    'emoji': '*',
    'familyId': 'mind',
    'type': type,
    'target': target,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': const <String, dynamic>{'type': 'daily'},
    'archived': false,
    'isCustom': true,
    'reminderEnabled': false,
    'reminderTime': null,
    if (remoteId != null) 'remoteId': remoteId,
    if (remoteHabitId != null) 'remoteHabitId': remoteHabitId,
    if (supabaseHabitId != null) 'supabaseHabitId': supabaseHabitId,
  };
}

ActiveUtilityEffect _effect({
  required String id,
  required String utilityId,
  required ActiveUtilityEffectType type,
  int remainingUses = 10,
}) {
  return ActiveUtilityEffect(
    id: id,
    utilityId: utilityId,
    type: type,
    activatedAtMillis: 1,
    remainingUses: remainingUses,
    totalUses: 10,
  );
}

class _Fixture {
  _Fixture({
    required this.store,
    required this.rewardRepository,
    required this.activeEffectsRepository,
    required this.transactionRepository,
    required this.scopeUserId,
  });

  final UserStateStore store;
  final _FakeHabitCurrencyRewardRepository rewardRepository;
  final _TrackingActiveUtilityEffectsRepository activeEffectsRepository;
  final _MemoryHabitRewardTransactionRepository transactionRepository;
  final String scopeUserId;

  Future<List<ActiveUtilityEffect>> effects() async {
    return activeEffectsRepository.loadEffects(scopeUserId);
  }

  List<HabitRewardTransaction> get transactions =>
      transactionRepository.currentTransactions(scopeUserId);
}

class _TrackingActiveUtilityEffectsRepository
    implements ActiveUtilityEffectsRepository {
  _TrackingActiveUtilityEffectsRepository({
    Map<String, List<ActiveUtilityEffect>> initial =
        const <String, List<ActiveUtilityEffect>>{},
  }) {
    for (final entry in initial.entries) {
      _effects[entry.key] = _cloneEffects(entry.value);
    }
  }

  final Map<String, List<ActiveUtilityEffect>> _effects =
      <String, List<ActiveUtilityEffect>>{};

  @override
  Future<List<ActiveUtilityEffect>> loadEffects(String userScope) async {
    return _cloneEffects(_effects[userScope] ?? const <ActiveUtilityEffect>[]);
  }

  @override
  Future<void> saveEffects(
    String userScope,
    List<ActiveUtilityEffect> effects,
  ) async {
    _effects[userScope] = _cloneEffects(effects);
  }

  void consumeEffect(String userScope, String effectId) {
    final current = _effects[userScope];
    if (current == null) return;

    final next = <ActiveUtilityEffect>[];
    for (final effect in current) {
      if (effect.id == effectId) {
        final updated = effect.copyWith(
          remainingUses: effect.remainingUses - 1,
        );
        if (updated.remainingUses > 0) {
          next.add(updated);
        }
        continue;
      }
      next.add(effect);
    }
    _effects[userScope] = next;
  }
}

class _MemoryHabitRewardTransactionRepository
    implements HabitRewardTransactionRepository {
  _MemoryHabitRewardTransactionRepository({
    Map<String, List<HabitRewardTransaction>> initial =
        const <String, List<HabitRewardTransaction>>{},
  }) {
    for (final entry in initial.entries) {
      _transactions[entry.key] = _cloneTransactions(entry.value);
    }
  }

  final Map<String, List<HabitRewardTransaction>> _transactions =
      <String, List<HabitRewardTransaction>>{};

  @override
  Future<HabitRewardTransaction?> findByCompletion({
    required String userScope,
    required String habitId,
    required String localDateKey,
  }) async {
    final transactions =
        _transactions[userScope] ?? const <HabitRewardTransaction>[];
    for (final tx in transactions) {
      if (tx.habitId == habitId && tx.localDateKey == localDateKey) {
        return tx;
      }
    }
    return null;
  }

  @override
  Future<List<HabitRewardTransaction>> loadTransactions(
      String userScope) async {
    return _cloneTransactions(
        _transactions[userScope] ?? const <HabitRewardTransaction>[]);
  }

  @override
  Future<void> saveTransaction(
    String userScope,
    HabitRewardTransaction transaction,
  ) async {
    final current = List<HabitRewardTransaction>.from(
      _transactions[userScope] ?? const <HabitRewardTransaction>[],
    );
    current.removeWhere(
      (existing) =>
          existing.habitId == transaction.habitId &&
          existing.localDateKey == transaction.localDateKey,
    );
    current.add(transaction);
    _transactions[userScope] = current;
  }

  List<HabitRewardTransaction> currentTransactions(String userScope) {
    return _cloneTransactions(
        _transactions[userScope] ?? const <HabitRewardTransaction>[]);
  }
}

class _FakeHabitCurrencyRewardRepository
    implements HabitCurrencyRewardRepository {
  _FakeHabitCurrencyRewardRepository({
    this.rewardHandler,
    this.reverseHandler,
    required this.effectsRepository,
  });

  final HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry> Function(
    _HabitCurrencyRewardRequest request,
    _TrackingActiveUtilityEffectsRepository effects,
  )? rewardHandler;
  final HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry> Function(
    _HabitCurrencyRewardRequest request,
    _TrackingActiveUtilityEffectsRepository effects,
  )? reverseHandler;
  final _TrackingActiveUtilityEffectsRepository effectsRepository;

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

    final handler = rewardHandler;
    if (handler != null) {
      return handler(request, effectsRepository);
    }

    return HabitCurrencyRewardResult.failure(
      failure: const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.unknown,
        message: 'No apply handler configured.',
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
      return handler(request, effectsRepository);
    }

    return HabitCurrencyRewardResult.failure(
      failure: const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.unknown,
        message: 'No reverse handler configured.',
      ),
    );
  }
}

class _NoopPendingCurrencyOperationStore
    implements PendingCurrencyOperationStore {
  @override
  Future<void> clearPendingOperations(String userId) async {}

  @override
  Future<List<PendingCurrencyOperation>> loadPendingOperations(
    String userId,
  ) async {
    return const <PendingCurrencyOperation>[];
  }

  @override
  Future<void> savePendingOperations(
    String userId,
    List<PendingCurrencyOperation> operations,
  ) async {}
}

class _NeverWalletRepository implements CloudWalletRepository {
  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() {
    throw StateError('Wallet refresh should not run for this test.');
  }
}

class _MemoryWalletCache implements WalletCache {
  final Map<String, WalletCacheEntry> _entries = <String, WalletCacheEntry>{};

  WalletCacheEntry? readSync(String userId) => _entries[userId];

  @override
  Future<WalletCacheEntry?> read(String userId) async => _entries[userId];

  @override
  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot) async {
    final entry = WalletCacheEntry.fromSnapshot(
      snapshot,
      cachedAt: DateTime.utc(2026, 7, 18, 12),
    );
    _entries[snapshot.userId] = entry;
    return entry;
  }

  @override
  Future<void> clearForUser(String userId) async {
    _entries.remove(userId);
  }
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

List<ActiveUtilityEffect> _cloneEffects(List<ActiveUtilityEffect> effects) {
  return effects.map((effect) => effect.copyWith()).toList(growable: false);
}

List<HabitRewardTransaction> _cloneTransactions(
  List<HabitRewardTransaction> transactions,
) {
  return transactions
      .map((transaction) => transaction.copyWith())
      .toList(growable: false);
}

int _xp(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final progression = userState['progression'] as Map<String, dynamic>;
  return (progression['xp'] as num).toInt();
}

int _coins(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final wallet = userState['wallet'] as Map<String, dynamic>;
  return (wallet['coins'] as num).toInt();
}
