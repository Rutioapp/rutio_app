import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/application/open_mystery_box_use_case.dart';
import 'package:rutio/features/shop/data/local_mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/active_utility_effects_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fixed_random_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpenMysteryBoxUseCase', () {
    test('opening consumes one box and grants the resolved reward', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 3),
          ],
        ),
      );

      final result = await env.useCase.open(transactionId: 'tx-1');

      expect(result.status, MysteryBoxOperationStatus.success);
      expect(result.transaction, isNotNull);
      expect(result.transaction!.reward.rewardId, 'reward_80_coins_40_xp');
      expect(
          (await env.shopRepository.load()).backpackItems.single.quantity, 2);
      expect(_xp(env.store), 40);
      expect(_coins(env.store), 80);
      expect(
        (await env.transactionRepository.loadTransactions('user-a')),
        hasLength(1),
      );
      expect(
        (await env.transactionRepository.loadTransactions('user-a'))
            .single
            .status,
        MysteryBoxOpeningStatus.granted,
      );
    });

    test('the same transaction id is idempotent', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 3),
          ],
        ),
      );

      final first = await env.useCase.open(transactionId: 'tx-1');
      final second = await env.useCase.open(transactionId: 'tx-1');

      expect(first.status, MysteryBoxOperationStatus.success);
      expect(second.status, MysteryBoxOperationStatus.success);
      expect(second.transaction!.reward.rewardId,
          first.transaction!.reward.rewardId);
      expect(
          (await env.shopRepository.load()).backpackItems.single.quantity, 2);
      expect(_xp(env.store), 40);
      expect(_coins(env.store), 80);
      expect(
        (await env.transactionRepository.loadTransactions('user-a')),
        hasLength(1),
      );
    });

    test('a reward containing utilities increases backpack quantity only',
        () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 1),
          ],
        ),
        randomValues: <int>[85],
        activeEffects: <ActiveUtilityEffect>[
          _effect(
            id: 'xp-effect',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
            remainingUses: 6,
          ),
          _effect(
            id: 'coin-effect',
            utilityId: 'utility_coin_boost_1d',
            type: ActiveUtilityEffectType.coinBoost,
            remainingUses: 4,
          ),
        ],
      );

      final result = await env.useCase.open(transactionId: 'tx-utility');

      expect(result.status, MysteryBoxOperationStatus.success);
      expect(result.transaction!.reward.rewardId, 'reward_xp_boost_30_coins');
      expect(_coins(env.store), 30);
      expect(_xp(env.store), 0);
      final backpackItems = (await env.shopRepository.load()).backpackItems;
      expect(backpackItems, hasLength(1));
      expect(backpackItems.single.itemId, 'utility_xp_boost_1d');
      expect(backpackItems.single.quantity, 1);
      expect((await env.activeEffectsRepository.loadEffects('user-a')),
          hasLength(2));
      expect(
        (await env.activeEffectsRepository.loadEffects('user-a'))
            .map((effect) => effect.remainingUses),
        containsAll(<int>[6, 4]),
      );
    });

    test('a failing persistence step rolls everything back', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 1),
          ],
        ),
        failOnTransactionSave: true,
      );

      final result = await env.useCase.open(transactionId: 'tx-fail');

      expect(result.status, MysteryBoxOperationStatus.persistenceError);
      expect(_xp(env.store), 0);
      expect(_coins(env.store), 0);
      expect(
          (await env.shopRepository.load()).backpackItems.single.quantity, 1);
      expect(
          await env.transactionRepository.loadTransactions('user-a'), isEmpty);
    });

    test('presentation marks a pending result as presented', () async {
      final env = await _createEnv(
        scopeUserId: 'user-a',
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 1),
          ],
        ),
      );

      final opened = await env.useCase.open(transactionId: 'tx-present');
      expect(opened.status, MysteryBoxOperationStatus.success);

      final marked = await env.useCase.markPresented('tx-present');
      expect(marked.status, MysteryBoxOperationStatus.success);
      expect(marked.transaction!.status, MysteryBoxOpeningStatus.presented);
      expect(
        (await env.transactionRepository.loadTransactions('user-a'))
            .single
            .status,
        MysteryBoxOpeningStatus.presented,
      );
    });

    test('effects stay scoped to the current user', () async {
      final envA = await _createEnv(
        scopeUserId: 'user-a',
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 1),
          ],
        ),
      );
      await envA.useCase.open(transactionId: 'tx-a');

      final envB = await _createEnv(
        scopeUserId: 'user-b',
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 1),
          ],
        ),
      );

      expect(
          await envB.transactionRepository.loadTransactions('user-b'), isEmpty);
      expect(_xp(envB.store), 0);
      expect(_coins(envB.store), 0);
    });
  });
}

class _Env {
  const _Env({
    required this.store,
    required this.useCase,
    required this.shopRepository,
    required this.transactionRepository,
    required this.activeEffectsRepository,
  });

  final UserStateStore store;
  final OpenMysteryBoxUseCase useCase;
  final ShopLocalRepository shopRepository;
  final MysteryBoxOpeningRepository transactionRepository;
  final _InMemoryActiveUtilityEffectsRepository activeEffectsRepository;
}

class _InMemoryActiveUtilityEffectsRepository
    implements ActiveUtilityEffectsRepository {
  _InMemoryActiveUtilityEffectsRepository({
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
}

Future<_Env> _createEnv({
  required String scopeUserId,
  required ShopState shopState,
  List<ActiveUtilityEffect> activeEffects = const <ActiveUtilityEffect>[],
  List<int> randomValues = const <int>[0],
  bool failOnTransactionSave = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final activeEffectsRepository = _InMemoryActiveUtilityEffectsRepository(
    initial: <String, List<ActiveUtilityEffect>>{
      scopeUserId: activeEffects,
    },
  );
  final transactionRepository = LocalMysteryBoxOpeningRepository(
    scopeResolver: () => scopeUserId,
  );
  final shopRepository = ShopLocalRepository(
    scopeResolver: () => scopeUserId,
  );
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(scopeUserId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    activeUtilityEffectsRepository: activeEffectsRepository,
  );
  await store.save(
    _baseState(
      userId: scopeUserId,
      dateKey: '2026-07-13',
    ),
  );
  await shopRepository.save(shopState);

  final failingTransactionRepository = failOnTransactionSave
      ? _FailingMysteryBoxOpeningRepository(
          delegate: transactionRepository,
        )
      : transactionRepository;

  return _Env(
    store: store,
    useCase: OpenMysteryBoxUseCase(
      userStateStore: store,
      shopRepository: shopRepository,
      mysteryBoxOpeningRepository: failingTransactionRepository,
      randomSource: FixedRandomSource(randomValues),
      nowProvider: () => DateTime(2026, 7, 13, 12),
    ),
    shopRepository: shopRepository,
    transactionRepository: transactionRepository,
    activeEffectsRepository: activeEffectsRepository,
  );
}

class _FailingMysteryBoxOpeningRepository
    implements MysteryBoxOpeningRepository {
  _FailingMysteryBoxOpeningRepository({required this.delegate});

  final LocalMysteryBoxOpeningRepository delegate;

  @override
  Future<List<MysteryBoxOpeningTransaction>> loadTransactions(
    String userScope,
  ) {
    return delegate.loadTransactions(userScope);
  }

  @override
  Future<void> saveTransactions(
    String userScope,
    List<MysteryBoxOpeningTransaction> transactions,
  ) {
    throw StateError('transaction save failed');
  }
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
        'lastSavedAt': '2026-07-13T12:00:00.000Z',
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

List<ActiveUtilityEffect> _cloneEffects(List<ActiveUtilityEffect> effects) {
  return effects.map((effect) => effect.copyWith()).toList(growable: false);
}

ActiveUtilityEffect _effect({
  required String id,
  required String utilityId,
  required ActiveUtilityEffectType type,
  required int remainingUses,
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
