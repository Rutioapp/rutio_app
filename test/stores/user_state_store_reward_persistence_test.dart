import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/constants/reward_constants.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/devtools/demo_seed/demo_seed_models.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore rewards and scoped persistence', () {
    test(
        'check habit completion grants XP/coins and persists for scoped real user',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'real-user-1';
      final store = await _seedScopedStore(
        scopeUserId: scopeUserId,
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-check', type: 'check', target: 1),
        ],
      );

      await store.completeHabit(habitId: 'habit-check');

      expect(_xp(store), RewardConstants.habitCheckXpReward);
      expect(_coins(store), RewardConstants.habitCheckAmbarReward);
      expect(
        _level(store),
        LevelProgression.fromTotalXp(RewardConstants.habitCheckXpReward).level,
      );

      final reloaded = await _reloadScopedStore(scopeUserId: scopeUserId);
      expect(_xp(reloaded), RewardConstants.habitCheckXpReward);
      expect(_coins(reloaded), RewardConstants.habitCheckAmbarReward);
      expect(
        _level(reloaded),
        LevelProgression.fromTotalXp(RewardConstants.habitCheckXpReward).level,
      );
      expect(reloaded.userId, scopeUserId);
    });

    test('count habit grants reward once when reaching target', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'real-user-2';
      final store = await _seedScopedStore(
        scopeUserId: scopeUserId,
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-count', type: 'count', target: 5),
        ],
      );

      await store.setCountHabitValue(habitId: 'habit-count', value: 4);
      expect(_xp(store), 0);
      expect(_coins(store), 0);

      await store.setCountHabitValue(habitId: 'habit-count', value: 5);
      final expectedXp = RewardConstants.habitCountXpReward(5);
      final expectedCoins = RewardConstants.habitCountAmbarReward(expectedXp);
      expect(_xp(store), expectedXp);
      expect(_coins(store), expectedCoins);
      expect(_level(store), LevelProgression.fromTotalXp(expectedXp).level);

      await store.setCountHabitValue(habitId: 'habit-count', value: 9);
      expect(_xp(store), expectedXp);
      expect(_coins(store), expectedCoins);

      final reloaded = await _reloadScopedStore(scopeUserId: scopeUserId);
      expect(_xp(reloaded), expectedXp);
      expect(_coins(reloaded), expectedCoins);
      expect(_level(reloaded), LevelProgression.fromTotalXp(expectedXp).level);
    });

    test('count habit rollback removes granted coins and can re-grant later', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'real-user-count-rollback';
      final store = await _seedScopedStore(
        scopeUserId: scopeUserId,
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-count-rollback', type: 'count', target: 5),
        ],
      );

      await store.setCountHabitValue(habitId: 'habit-count-rollback', value: 5);
      final expectedCoins = RewardConstants.habitCountAmbarReward(
        RewardConstants.habitCountXpReward(5),
      );
      expect(_coins(store), expectedCoins);

      await store.setCountHabitValue(habitId: 'habit-count-rollback', value: 4);
      expect(_coins(store), 0);

      await store.setCountHabitValue(habitId: 'habit-count-rollback', value: 5);
      expect(_coins(store), expectedCoins);
    });

    test('logout/reset overlay guards do not block normal reward application',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'real-user-3';
      final store = await _seedScopedStore(
        scopeUserId: scopeUserId,
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-guard', type: 'check', target: 1),
        ],
      );

      store.suppressGamificationOverlaysDuringLogout();
      store.restoreGamificationOverlaysAfterLogout();
      await store.completeHabit(habitId: 'habit-guard');

      expect(_xp(store), RewardConstants.habitCheckXpReward);
      expect(_coins(store), RewardConstants.habitCheckAmbarReward);
    });

    test('uncompleting today removes granted coins and keeps XP', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final today = DateTime.now();
      const scopeUserId = 'real-user-4';
      final store = await _seedScopedStore(
        scopeUserId: scopeUserId,
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-undo', type: 'check', target: 1),
        ],
      );

      await store.completeHabit(habitId: 'habit-undo');
      await store.setHabitCompletion(
        habitId: 'habit-undo',
        date: today,
        done: false,
      );

      expect(_xp(store), RewardConstants.habitCheckXpReward);
      expect(_coins(store), 0);
    });

    test('uncompleting a non-rewarded habit does not subtract coins', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final today = DateTime.now();
      const scopeUserId = 'real-user-5';
      final store = await _seedScopedStore(
        scopeUserId: scopeUserId,
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-no-reward', type: 'check', target: 1),
        ],
      );

      await store.setHabitCompletion(
        habitId: 'habit-no-reward',
        date: today,
        done: false,
      );

      expect(_xp(store), 0);
      expect(_coins(store), 0);
    });

    test('coin rollback never makes wallet negative', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final today = DateTime.now();
      const scopeUserId = 'real-user-6';
      final store = await _seedScopedStore(
        scopeUserId: scopeUserId,
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-spend-then-undo', type: 'check', target: 1),
        ],
      );

      await store.completeHabit(habitId: 'habit-spend-then-undo');
      final wallet =
          ((store.state?['userState'] as Map?)?['wallet'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      wallet['coins'] = 0;
      await store.save(store.state!);

      await store.setHabitCompletion(
        habitId: 'habit-spend-then-undo',
        date: today,
        done: false,
      );

      expect(_coins(store), 0);
    });

    test('switching authenticated local scopes does not mix saved habit state',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await _seedScopedStore(
        scopeUserId: 'real-user-a',
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-a', type: 'check', target: 1),
        ],
      );
      await _seedScopedStore(
        scopeUserId: 'real-user-b',
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'habit-b', type: 'check', target: 1),
        ],
      );

      final repo = UserStateRepository(storage: UserStateStorage())
        ..setActiveUserScope('real-user-a');
      final store = UserStateStore(
        repo,
        journalEntrySyncService: JournalEntrySyncService(),
      );

      await store.load();
      expect(store.activeHabits.map((habit) => habit['id']), <String>['habit-a']);

      await store.switchLocalScope(userId: 'real-user-b');
      expect(store.activeHabits.map((habit) => habit['id']), <String>['habit-b']);

      await store.switchLocalScope(userId: 'real-user-a');
      expect(store.activeHabits.map((habit) => habit['id']), <String>['habit-a']);
    });

    test('demo and authenticated scopes stay isolated from each other',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await _seedScopedStore(
        scopeUserId: DemoSeedScope.userId,
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'demo-habit', type: 'check', target: 1),
        ],
      );
      await _seedScopedStore(
        scopeUserId: 'real-user-auth',
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'auth-habit', type: 'check', target: 1),
        ],
      );

      final demoStore =
          await _reloadScopedStore(scopeUserId: DemoSeedScope.userId);
      final authStore =
          await _reloadScopedStore(scopeUserId: 'real-user-auth');

      expect(
        demoStore.activeHabits.map((habit) => habit['id']),
        <String>['demo-habit'],
      );
      expect(
        authStore.activeHabits.map((habit) => habit['id']),
        <String>['auth-habit'],
      );
    });

    test('guest scope does not read authenticated scoped state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await _seedScopedStore(
        scopeUserId: 'real-user-auth',
        stateUserId: 'user_123',
        habits: <Map<String, dynamic>>[
          _habit(id: 'auth-habit', type: 'check', target: 1),
        ],
      );

      final repo = UserStateRepository(storage: UserStateStorage());
      final guestStore = UserStateStore(
        repo,
        journalEntrySyncService: JournalEntrySyncService(),
      );

      await guestStore.load();

      expect(guestStore.userId, isNull);
      expect(guestStore.activeHabits, isEmpty);
    });
  });
}

Future<UserStateStore> _seedScopedStore({
  required String scopeUserId,
  required String stateUserId,
  required List<Map<String, dynamic>> habits,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(scopeUserId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(userId: stateUserId, habits: habits));
  return store;
}

Future<UserStateStore> _reloadScopedStore({
  required String scopeUserId,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(scopeUserId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.load();
  return store;
}

Map<String, dynamic> _baseState({
  required String userId,
  required List<Map<String, dynamic>> habits,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': userId,
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
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
        'lastResetDate': _todayKey(),
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
    'createdAt': '2026-01-01',
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

int _xp(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final progression = userState['progression'] as Map<String, dynamic>;
  return (progression['xp'] as num).toInt();
}

int _level(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final progression = userState['progression'] as Map<String, dynamic>;
  return (progression['level'] as num).toInt();
}

int _coins(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final wallet = userState['wallet'] as Map<String, dynamic>;
  return (wallet['coins'] as num).toInt();
}

String _todayKey() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
