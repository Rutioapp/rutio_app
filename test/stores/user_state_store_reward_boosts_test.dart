import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/constants/reward_constants.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/habits/domain/habit_reward_transaction_repository.dart';
import 'package:rutio/features/habits/domain/models/habit_reward_transaction.dart';
import 'package:rutio/features/shop/domain/active_utility_effects_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore reward boosts', () {
    test('check habit completion consumes one use from each applicable boost',
        () async {
      final expectedXp = RewardConstants.habitCheckXpReward +
          (RewardConstants.habitCheckXpReward * 0.5).round();
      final expectedCoins = RewardConstants.habitCheckAmbarReward +
          (RewardConstants.habitCheckAmbarReward * 0.5).ceil();
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-1',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(_xp(fixture.store), expectedXp);
      expect(_coins(fixture.store), expectedCoins);
      expect(await _effectsFor(fixture, 'boost-user-1'), hasLength(2));
      expect(await _remainingUses(fixture, 'xp-boost'), 9);
      expect(await _remainingUses(fixture, 'coin-boost'), 9);
      expect(await _transactionsFor(fixture, 'boost-user-1'), hasLength(1));
      expect(
        (await _transactionsFor(fixture, 'boost-user-1'))
            .first
            .appliedEffectIds,
        containsAll(<String>['xp-boost', 'coin-boost']),
      );
    });

    test('partial count progress does not consume boost uses', () async {
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-2',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-count', type: 'count', target: 5),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
      );

      await fixture.store.setCountHabitValue(habitId: 'habit-count', value: 3);

      expect(_xp(fixture.store), 0);
      expect(_coins(fixture.store), 0);
      expect(await _effectsFor(fixture, 'boost-user-2'), hasLength(2));
      expect(await _remainingUses(fixture, 'xp-boost'), 10);
      expect(await _remainingUses(fixture, 'coin-boost'), 10);
      expect(await _transactionsFor(fixture, 'boost-user-2'), isEmpty);
    });

    test('count habit consumes exactly one use when reaching the target',
        () async {
      final baseXp = RewardConstants.habitCountXpReward(5);
      final baseCoins = RewardConstants.habitCountAmbarReward(baseXp);
      final expectedXp = baseXp + (baseXp * 0.5).round();
      final expectedCoins = baseCoins + (baseCoins * 0.5).ceil();
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-3',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-count', type: 'count', target: 5),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
      );

      await fixture.store.setCountHabitValue(habitId: 'habit-count', value: 5);

      expect(_xp(fixture.store), expectedXp);
      expect(_coins(fixture.store), expectedCoins);
      expect(await _remainingUses(fixture, 'xp-boost'), 9);
      expect(await _remainingUses(fixture, 'coin-boost'), 9);
      expect(await _transactionsFor(fixture, 'boost-user-3'), hasLength(1));
    });

    test('duplicate completion does not pay twice or consume twice', () async {
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-4',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(
        _xp(fixture.store),
        RewardConstants.habitCheckXpReward +
            (RewardConstants.habitCheckXpReward * 0.5).round(),
      );
      expect(
        _coins(fixture.store),
        RewardConstants.habitCheckAmbarReward +
            (RewardConstants.habitCheckAmbarReward * 0.5).ceil(),
      );
      expect(await _remainingUses(fixture, 'xp-boost'), 9);
      expect(await _remainingUses(fixture, 'coin-boost'), 9);
      expect(await _transactionsFor(fixture, 'boost-user-4'), hasLength(1));
    });

    test(
        'uncompleting removes reward once and never returns boost uses, even on repeat',
        () async {
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-5',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await fixture.store.setHabitCompletion(
        habitId: 'habit-check',
        date: fixture.now,
        done: false,
      );
      await fixture.store.setHabitCompletion(
        habitId: 'habit-check',
        date: fixture.now,
        done: false,
      );

      expect(_xp(fixture.store), 0);
      expect(_coins(fixture.store), 0);
      expect(await _remainingUses(fixture, 'xp-boost'), 9);
      expect(await _remainingUses(fixture, 'coin-boost'), 9);
      expect(
        (await _transactionsFor(fixture, 'boost-user-5')).single.isReversed,
        isTrue,
      );
    });

    test(
        'complete, undo, and re-complete the same day does not farm or spend an extra use',
        () async {
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-6',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await fixture.store.setHabitCompletion(
        habitId: 'habit-check',
        date: fixture.now,
        done: false,
      );
      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(_xp(fixture.store), 0);
      expect(_coins(fixture.store), 0);
      expect(await _remainingUses(fixture, 'xp-boost'), 9);
      expect(await _remainingUses(fixture, 'coin-boost'), 9);
      expect(
        (await _transactionsFor(fixture, 'boost-user-6')).single.isReversed,
        isTrue,
      );
    });

    test('diary rewards do not consume boosts', () async {
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-7',
        habits: <Map<String, dynamic>>[],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
      );

      await fixture.store.addDiaryEntry(
        DiaryEntry(
          id: 'journal-1',
          createdAt: fixture.now.millisecondsSinceEpoch,
          text: 'Entrada de prueba',
        ),
      );

      expect(_xp(fixture.store), RewardConstants.dailyDiaryXpReward);
      expect(_coins(fixture.store), RewardConstants.dailyDiaryAmbarReward);
      expect(await _remainingUses(fixture, 'xp-boost'), 10);
      expect(await _remainingUses(fixture, 'coin-boost'), 10);
      expect(await _transactionsFor(fixture, 'boost-user-7'), isEmpty);
    });

    test('completion failure rolls back core state and boost uses', () async {
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-8',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
        failOnTransactionSave: true,
      );

      await expectLater(
        () => fixture.store.completeHabit(habitId: 'habit-check'),
        throwsA(isA<StateError>()),
      );

      expect(_xp(fixture.store), 0);
      expect(_coins(fixture.store), 0);
      expect(fixture.store.activeHabits.first['doneToday'], isFalse);
      expect(await _effectsFor(fixture, 'boost-user-8'), hasLength(2));
      expect(await _remainingUses(fixture, 'xp-boost'), 10);
      expect(await _remainingUses(fixture, 'coin-boost'), 10);
      expect(await _transactionsFor(fixture, 'boost-user-8'), isEmpty);
    });

    test('reversal clamps XP and coins at zero', () async {
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-9',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost),
          _effect('coin-boost', 'utility_coin_boost_1d',
              ActiveUtilityEffectType.coinBoost),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');

      final root = fixture.store.state!;
      final userState = root['userState'] as Map<String, dynamic>;
      final progression = userState['progression'] as Map<String, dynamic>;
      final wallet = userState['wallet'] as Map<String, dynamic>;
      progression['xp'] = 0;
      wallet['coins'] = 0;
      await fixture.store.save(root);

      await fixture.store.setHabitCompletion(
        habitId: 'habit-check',
        date: fixture.now,
        done: false,
      );

      expect(_xp(fixture.store), 0);
      expect(_coins(fixture.store), 0);
      expect(await _remainingUses(fixture, 'xp-boost'), 9);
      expect(await _remainingUses(fixture, 'coin-boost'), 9);
    });

    test(
        'a one-use boost disappears when it reaches zero and never goes negative',
        () async {
      final fixture = await _seedStore(
        scopeUserId: 'boost-user-10',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
        activeEffects: <ActiveUtilityEffect>[
          _effect('xp-boost', 'utility_xp_boost_1d',
              ActiveUtilityEffectType.xpBoost,
              remainingUses: 1),
        ],
      );

      await fixture.store.completeHabit(habitId: 'habit-check');
      await fixture.store.completeHabit(habitId: 'habit-check');

      expect(await _effectsFor(fixture, 'boost-user-10'), isEmpty);
      expect(await _transactionsFor(fixture, 'boost-user-10'), hasLength(1));
    });
  });
}

class _Fixture {
  _Fixture({
    required this.store,
    required this.activeEffectsRepository,
    required this.transactionRepository,
    required this.scopeUserId,
    required this.now,
  });

  final UserStateStore store;
  final _InMemoryActiveUtilityEffectsRepository activeEffectsRepository;
  final _InMemoryHabitRewardTransactionRepository transactionRepository;
  final String scopeUserId;
  final DateTime now;
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

class _InMemoryHabitRewardTransactionRepository
    implements HabitRewardTransactionRepository {
  _InMemoryHabitRewardTransactionRepository({
    Map<String, List<HabitRewardTransaction>> initial =
        const <String, List<HabitRewardTransaction>>{},
    this.failNextSave = false,
  }) {
    for (final entry in initial.entries) {
      _transactions[entry.key] = _cloneTransactions(entry.value);
    }
  }

  final Map<String, List<HabitRewardTransaction>> _transactions =
      <String, List<HabitRewardTransaction>>{};
  bool failNextSave;

  @override
  Future<HabitRewardTransaction?> findByCompletion({
    required String userScope,
    required String habitId,
    required String localDateKey,
  }) async {
    final transactions = await loadTransactions(userScope);
    for (final tx in transactions) {
      if (tx.habitId == habitId.trim() &&
          tx.localDateKey == localDateKey.trim()) {
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
    if (failNextSave) {
      failNextSave = false;
      throw StateError('transaction save failed');
    }
    final existing = await loadTransactions(userScope);
    final next = <HabitRewardTransaction>[
      ...existing.where(
        (current) =>
            current.habitId != transaction.habitId ||
            current.localDateKey != transaction.localDateKey,
      ),
      transaction,
    ];
    _transactions[userScope] = _cloneTransactions(next);
  }
}

Future<_Fixture> _seedStore({
  required String scopeUserId,
  required List<Map<String, dynamic>> habits,
  List<ActiveUtilityEffect> activeEffects = const <ActiveUtilityEffect>[],
  bool failOnTransactionSave = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final activeEffectsRepository = _InMemoryActiveUtilityEffectsRepository(
    initial: <String, List<ActiveUtilityEffect>>{
      scopeUserId: activeEffects,
    },
  );
  final transactionRepository = _InMemoryHabitRewardTransactionRepository(
    failNextSave: failOnTransactionSave,
  );

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(scopeUserId);
  final now = DateTime(2026, 7, 13, 12);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    nowProvider: () => now,
    activeUtilityEffectsRepository: activeEffectsRepository,
    habitRewardTransactionRepository: transactionRepository,
  );
  await store.save(
    _baseState(
      userId: scopeUserId,
      habits: habits,
      dateKey: _dateKey(now),
    ),
  );

  return _Fixture(
    store: store,
    activeEffectsRepository: activeEffectsRepository,
    transactionRepository: transactionRepository,
    scopeUserId: scopeUserId,
    now: now,
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
      'activeHabits': habits,
    },
  };
}

Map<String, dynamic> _habit({
  required String id,
  required String type,
  required num target,
}) {
  return <String, dynamic>{
    'id': id,
    'createdAt': '2026-07-13',
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
  };
}

ActiveUtilityEffect _effect(
  String id,
  String utilityId,
  ActiveUtilityEffectType type, {
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

Future<List<ActiveUtilityEffect>> _effectsFor(_Fixture fixture, String scope) {
  return fixture.activeEffectsRepository.loadEffects(scope);
}

Future<List<HabitRewardTransaction>> _transactionsFor(
  _Fixture fixture,
  String scope,
) {
  return fixture.transactionRepository.loadTransactions(scope);
}

Future<int> _remainingUses(_Fixture fixture, String effectId) async {
  final effect = (await _effectsFor(fixture, fixture.scopeUserId))
      .firstWhere((current) => current.id == effectId);
  return effect.remainingUses;
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

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
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
