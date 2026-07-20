import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/application/open_mystery_box_use_case.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_dtos.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_errors.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_repository.dart'
    as cloud;
import 'package:rutio/features/shop/data/cloud/pending_mystery_box_operation_store.dart';
import 'package:rutio/features/shop/data/local_mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fixed_random_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpenMysteryBoxUseCase cloud', () {
    test('cloud success persists the confirmed result once', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        cloudResponses: <Object>[
          _remoteResult(
            requestId: 'tx-1',
            rewardId: 'reward_80_coins_40_xp',
            coins: 80,
            xp: 40,
            balanceAfter: 980,
            walletVersion: 7,
            remainingBoxes: 2,
          ),
        ],
      );

      final result = await env.useCase.open(transactionId: 'tx-1');

      expect(result.status, MysteryBoxOperationStatus.success);
      expect(result.transaction, isNotNull);
      expect(result.transaction!.reward.rewardId, 'reward_80_coins_40_xp');
      expect(result.walletCoins, 980);
      expect(env.cloudRepo.calls, 1);
      expect(
        await env.pendingStore.loadPendingOperations('user-a'),
        isEmpty,
      );
      expect(
        await env.transactionRepository.loadTransactions('user-a'),
        hasLength(1),
      );
      expect(_xp(env.store), 40);
      expect(_coins(env.store), 0);
    });

    test('utility rewards are preserved in the confirmed transaction', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        cloudResponses: <Object>[
          _remoteResult(
            requestId: 'tx-utility',
            rewardId: 'reward_xp_boost_30_coins',
            rewardType: RemoteMysteryBoxRewardType.utility,
            quantity: 1,
            coins: 30,
            xp: 0,
            utilityRewards: const <String, int>{
              'utility_xp_boost_1d': 1,
            },
            balanceAfter: 930,
            walletVersion: 8,
            remainingBoxes: 1,
          ),
        ],
      );

      final result = await env.useCase.open(transactionId: 'tx-utility');

      expect(result.status, MysteryBoxOperationStatus.success);
      expect(result.transaction!.reward.utilityRewards, {
        'utility_xp_boost_1d': 1,
      });
      expect(result.walletCoins, 930);
      expect(env.cloudRepo.calls, 1);
      expect(_xp(env.store), 0);
    });

    test('the same request id reuses the persisted transaction', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        cloudResponses: <Object>[
          _remoteResult(
            requestId: 'tx-idempotent',
            rewardId: 'reward_125_coins',
            coins: 125,
            xp: 0,
            balanceAfter: 1125,
            walletVersion: 3,
            remainingBoxes: 0,
          ),
        ],
      );

      final first = await env.useCase.open(transactionId: 'tx-idempotent');
      final second = await env.useCase.open(transactionId: 'tx-idempotent');

      expect(first.status, MysteryBoxOperationStatus.success);
      expect(second.status, MysteryBoxOperationStatus.success);
      expect(env.cloudRepo.calls, 1);
      expect(
        await env.transactionRepository.loadTransactions('user-a'),
        hasLength(1),
      );
    });

    test('timeout keeps the request pending and retry reuses the same id',
        () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        cloudResponses: <Object>[
          const MysteryBoxOpeningCloudException(
            code: MysteryBoxOpeningCloudErrorCode.timeout,
            message: 'timed out',
            retryable: true,
          ),
          _remoteResult(
            requestId: 'tx-timeout',
            rewardId: 'reward_100_coins_50_xp',
            coins: 100,
            xp: 50,
            balanceAfter: 1100,
            walletVersion: 4,
            remainingBoxes: 0,
          ),
        ],
      );

      final first = await env.useCase.open(transactionId: 'tx-timeout');
      final pendingAfterFirst =
          await env.pendingStore.loadPendingOperations('user-a');
      final second = await env.useCase.open(transactionId: 'tx-timeout');

      expect(first.status, MysteryBoxOperationStatus.timeout);
      expect(pendingAfterFirst, hasLength(1));
      expect(pendingAfterFirst.single.requestId, 'tx-timeout');
      expect(second.status, MysteryBoxOperationStatus.success);
      expect(env.cloudRepo.calls, 2);
      expect(env.cloudRepo.requestIds, everyElement('tx-timeout'));
      expect(
        await env.pendingStore.loadPendingOperations('user-a'),
        isEmpty,
      );
    });

    test('retry after app restart returns the confirmed transaction', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        cloudResponses: <Object>[
          _remoteResult(
            requestId: 'tx-restart',
            rewardId: 'reward_150_coins',
            coins: 150,
            xp: 0,
            balanceAfter: 1150,
            walletVersion: 5,
            remainingBoxes: 1,
          ),
        ],
      );

      final first = await env.useCase.open(transactionId: 'tx-restart');
      expect(first.status, MysteryBoxOperationStatus.success);

      final restarted = await _createEnv(
        scopeUserId: 'user-a',
        resetSharedPreferences: false,
        cloudResponses: <Object>[
          StateError('cloud should not be called after restart'),
        ],
      );

      final second = await restarted.useCase.open(transactionId: 'tx-restart');

      expect(second.status, MysteryBoxOperationStatus.success);
      expect(restarted.cloudRepo.calls, 0);
      expect(
        await restarted.transactionRepository.loadTransactions('user-a'),
        hasLength(1),
      );
    });

    test('cloud feature disabled falls back to the legacy local path',
        () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        cloudEnabled: false,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 1),
          ],
        ),
        cloudResponses: <Object>[
          StateError('cloud should not be called when the flag is off'),
        ],
      );

      final result = await env.useCase.open(transactionId: 'tx-legacy');

      expect(result.status, MysteryBoxOperationStatus.success);
      expect(env.cloudRepo.calls, 0);
      expect(
        await env.transactionRepository.loadTransactions('user-a'),
        hasLength(1),
      );
      expect(_coins(env.store), 80);
      expect(_xp(env.store), 40);
    });

    test('a cloud no-inventory error resolves to noBoxes', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        cloudResponses: <Object>[
          const MysteryBoxOpeningCloudException(
            code: MysteryBoxOpeningCloudErrorCode.noInventory,
            message: 'no boxes',
            definitive: true,
          ),
        ],
      );

      final result = await env.useCase.open(transactionId: 'tx-empty');

      expect(result.status, MysteryBoxOperationStatus.noBoxes);
      expect(env.cloudRepo.calls, 1);
      expect(
        await env.pendingStore.loadPendingOperations('user-a'),
        isEmpty,
      );
    });

    test('switching users keeps the pending queue isolated', () async {
      final envA = await _createEnv(
        scopeUserId: 'user-a',
        cloudResponses: <Object>[
          const MysteryBoxOpeningCloudException(
            code: MysteryBoxOpeningCloudErrorCode.timeout,
            message: 'timed out',
            retryable: true,
          ),
        ],
      );
      final first = await envA.useCase.open(transactionId: 'tx-shared');
      expect(first.status, MysteryBoxOperationStatus.timeout);

      final envB = await _createEnv(
        scopeUserId: 'user-b',
        resetSharedPreferences: false,
        cloudResponses: <Object>[
          _remoteResult(
            requestId: 'tx-shared',
            rewardId: 'reward_80_coins_40_xp',
            coins: 80,
            xp: 40,
            balanceAfter: 1080,
            walletVersion: 2,
            remainingBoxes: 0,
          ),
        ],
      );

      final second = await envB.useCase.open(transactionId: 'tx-shared');
      expect(second.status, MysteryBoxOperationStatus.success);
      expect(envB.cloudRepo.calls, 1);
      expect(
        await envA.pendingStore.loadPendingOperations('user-a'),
        hasLength(1),
      );
      expect(
        await envB.pendingStore.loadPendingOperations('user-b'),
        isEmpty,
      );
    });
  });
}

class _Env {
  const _Env({
    required this.store,
    required this.useCase,
    required this.transactionRepository,
    required this.pendingStore,
    required this.cloudRepo,
  });

  final UserStateStore store;
  final OpenMysteryBoxUseCase useCase;
  final MysteryBoxOpeningRepository transactionRepository;
  final SharedPreferencesPendingMysteryBoxOperationStore pendingStore;
  final _FakeCloudMysteryBoxOpeningRepository cloudRepo;
}

class _FakeCloudMysteryBoxOpeningRepository
    extends cloud.SupabaseCloudMysteryBoxOpeningRepository {
  _FakeCloudMysteryBoxOpeningRepository({
    List<Object> scriptedResponses = const <Object>[],
    RemoteMysteryBoxOpeningResultDto? fallbackResponse,
  })  : _scriptedResponses = List<Object>.from(scriptedResponses),
        _fallbackResponse = fallbackResponse,
        super(enabled: true, currentUserIdProvider: () => 'user-a');

  final List<Object> _scriptedResponses;
  final RemoteMysteryBoxOpeningResultDto? _fallbackResponse;
  final List<String> requestIds = <String>[];
  int calls = 0;

  @override
  Future<RemoteMysteryBoxOpeningResultDto> openMysteryBox({
    required String requestId,
  }) async {
    calls += 1;
    requestIds.add(requestId);

    final next =
        _scriptedResponses.isNotEmpty ? _scriptedResponses.removeAt(0) : null;
    final value = next ?? _fallbackResponse;
    if (value is RemoteMysteryBoxOpeningResultDto) {
      return value;
    }
    if (value is FutureOr<RemoteMysteryBoxOpeningResultDto> Function(String)) {
      return value(requestId);
    }
    if (value is MysteryBoxOpeningCloudException) {
      throw value;
    }
    if (value is Exception) {
      throw value;
    }
    if (value is Error) {
      throw value;
    }
    throw StateError('No scripted cloud response configured.');
  }
}

Future<_Env> _createEnv({
  required String scopeUserId,
  required List<Object> cloudResponses,
  ShopState shopState = const ShopState.initial(),
  Future<SharedPreferences> Function()? sharedPreferencesProvider,
  bool cloudEnabled = true,
  bool resetSharedPreferences = true,
}) async {
  final sharedPreferences =
      sharedPreferencesProvider ?? SharedPreferences.getInstance;
  if (resetSharedPreferences) {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  }

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(scopeUserId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(
    _baseState(
      userId: scopeUserId,
      dateKey: '2026-07-19',
    ),
  );

  final shopRepository = ShopLocalRepository(scopeResolver: () => scopeUserId);
  await shopRepository.save(shopState);

  final transactionRepository = LocalMysteryBoxOpeningRepository(
    scopeResolver: () => scopeUserId,
    sharedPreferencesProvider: sharedPreferences,
  );
  final pendingStore = SharedPreferencesPendingMysteryBoxOperationStore(
    sharedPreferencesProvider: sharedPreferences,
  );
  final cloudRepo = _FakeCloudMysteryBoxOpeningRepository(
    scriptedResponses: cloudResponses,
  );

  return _Env(
    store: store,
    useCase: OpenMysteryBoxUseCase(
      userStateStore: store,
      shopRepository: shopRepository,
      mysteryBoxOpeningRepository: transactionRepository,
      randomSource: FixedRandomSource(<int>[0]),
      cloudMysteryBoxOpeningRepository: cloudRepo,
      pendingMysteryBoxOperationStore: pendingStore,
      cloudEnabled: cloudEnabled,
      nowProvider: () => DateTime.utc(2026, 7, 19, 12),
    ),
    transactionRepository: transactionRepository,
    pendingStore: pendingStore,
    cloudRepo: cloudRepo,
  );
}

RemoteMysteryBoxOpeningResultDto _remoteResult({
  required String requestId,
  required String rewardId,
  required int coins,
  required int xp,
  required int balanceAfter,
  required int walletVersion,
  required int remainingBoxes,
  RemoteMysteryBoxRewardType rewardType = RemoteMysteryBoxRewardType.coins,
  Map<String, int> utilityRewards = const <String, int>{},
  int quantity = 1,
  int weight = 40,
  String? rarity = 'common',
  bool isActive = true,
  int catalogVersion = 1,
  String userId = 'user-a',
}) {
  return RemoteMysteryBoxOpeningResultDto(
    requestId: requestId,
    operation: 'open',
    userId: userId,
    mysteryBoxUtilityId: 'utility_mystery_box_basic',
    reward: RemoteMysteryBoxRewardDto(
      rewardId: rewardId,
      rewardType: rewardType,
      quantity: quantity,
      weight: weight,
      rarity: rarity,
      isActive: isActive,
      catalogVersion: catalogVersion,
      coins: coins,
      xp: xp,
      utilityRewards: utilityRewards,
      maxQuantity: null,
    ),
    createdAt: DateTime.utc(2026, 7, 19, 12),
    balanceAfter: balanceAfter,
    walletVersion: walletVersion,
    remainingBoxes: remainingBoxes,
  );
}

Map<String, dynamic> _baseState({
  required String userId,
  required String dateKey,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': userId,
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': '2026-07-19T12:00:00.000Z',
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
      'activeHabits': <dynamic>[],
    },
  };
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
