import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/achievements/application/achievement_catalog.dart';
import 'package:rutio/features/achievements/domain/models/achievement.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Special achievements balance phase 1', () {
    test('flash no longer unlocks at the old threshold of 5 habits in one day',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-flash-old-threshold';
      final date = DateTime.now();
      final dateKey = _dateKey(date);
      final habits = List<Map<String, dynamic>>.generate(
        5,
        (index) => _habit(
          id: 'flash-old-$index',
          familyId: 'mind',
          type: 'check',
          target: 1,
        ),
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: <String, Map<String, dynamic>>{
            dateKey: <String, dynamic>{
              for (final habit in habits) habit['id'] as String: true,
            },
          },
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);

      expect(
        store.unlockedAchievementsById.containsKey('special:flash'),
        isFalse,
      );
      expect(store.achievementMetricSnapshots['special:flash']?.bestStreak, 5);
    });

    test('flash unlocks at the new threshold of 8 habits in one day', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-flash-new-threshold';
      final date = DateTime.now();
      final dateKey = _dateKey(date);
      final habits = List<Map<String, dynamic>>.generate(
        8,
        (index) => _habit(
          id: 'flash-new-$index',
          familyId: 'mind',
          type: 'check',
          target: 1,
        ),
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: <String, Map<String, dynamic>>{
            dateKey: <String, dynamic>{
              for (final habit in habits) habit['id'] as String: true,
            },
          },
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);
      final record = store.unlockedAchievementsById['special:flash'];
      final achievement = AchievementCatalog.achievementForId('special:flash');

      expect(record, isNotNull);
      expect(record!.targetValue, 8);
      expect(achievement?.targetValue, 8);
    });

    test(
        'el centurion no longer unlocks at the old threshold of 100 total completions',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-centurion-old-threshold';
      final today = DateTime.now();
      final habit = _habit(
        id: 'centurion-old',
        familyId: 'body',
        type: 'check',
        target: 1,
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: <Map<String, dynamic>>[habit],
          completionsByDay: _dailyCheckCompletions(
            habitId: habit['id'] as String,
            endDate: today,
            dayCount: 100,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);

      expect(
        store.unlockedAchievementsById.containsKey('special:el_centurion'),
        isFalse,
      );
      expect(
        store.achievementMetricSnapshots['special:el_centurion']?.bestStreak,
        100,
      );
    });

    test('el centurion unlocks at the new threshold of 150 total completions',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-centurion-new-threshold';
      final today = DateTime.now();
      final habit = _habit(
        id: 'centurion-new',
        familyId: 'body',
        type: 'check',
        target: 1,
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: <Map<String, dynamic>>[habit],
          completionsByDay: _dailyCheckCompletions(
            habitId: habit['id'] as String,
            endDate: today,
            dayCount: 150,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);
      final record = store.unlockedAchievementsById['special:el_centurion'];
      final achievement =
          AchievementCatalog.achievementForId('special:el_centurion');

      expect(record, isNotNull);
      expect(record!.targetValue, 150);
      expect(achievement?.targetValue, 150);
    });

    test('already unlocked special achievements are not revoked', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-persisted-unlock';
      final date = DateTime.now();
      final dateKey = _dateKey(date);
      final habits = List<Map<String, dynamic>>.generate(
        5,
        (index) => _habit(
          id: 'persisted-flash-$index',
          familyId: 'mind',
          type: 'check',
          target: 1,
        ),
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: <String, Map<String, dynamic>>{
            dateKey: <String, dynamic>{
              for (final habit in habits) habit['id'] as String: true,
            },
          },
          unlocked: <Map<String, dynamic>>[
            _unlockedRecordJson(
              id: 'special:flash',
              tier: AchievementTier.bronze,
              habitName: 'Flash',
              targetValue: 5,
              unlockedAt: DateTime(2026, 1, 1),
            ),
          ],
          rewardAppliedAchievementIds: const <String>['special:flash'],
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);
      final record = store.unlockedAchievementsById['special:flash'];
      final root = store.state as Map<String, dynamic>;
      final userState = root['userState'] as Map<String, dynamic>;
      final achievements =
          userState['profile'] as Map<String, dynamic>;
      final achievementRoot =
          achievements['achievements'] as Map<String, dynamic>;

      expect(record, isNotNull);
      expect(record!.targetValue, 5);
      expect(
        achievementRoot['rewardAppliedAchievementIds'],
        contains('special:flash'),
      );
    });

    test(
        'francotirados no longer unlocks at the old phase 1 threshold of 35 exact hits',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-francotirados-old-threshold';
      final today = DateTime.now();
      final habit = _habit(
        id: 'francotirados-old',
        familyId: 'discipline',
        type: 'count',
        target: 5,
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: <Map<String, dynamic>>[habit],
          countValuesByDay: _dailyCountValues(
            habitId: habit['id'] as String,
            endDate: today,
            dayCount: 35,
            value: 5,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);

      expect(
        store.unlockedAchievementsById.containsKey('special:francotirados'),
        isFalse,
      );
      expect(
        store.achievementMetricSnapshots['special:francotirados']?.bestStreak,
        35,
      );
    });

    test('francotirados unlocks at the new threshold of 100 exact hits',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-francotirados-new-threshold';
      final today = DateTime.now();
      final habit = _habit(
        id: 'francotirados-new',
        familyId: 'discipline',
        type: 'count',
        target: 5,
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: <Map<String, dynamic>>[habit],
          countValuesByDay: _dailyCountValues(
            habitId: habit['id'] as String,
            endDate: today,
            dayCount: 100,
            value: 5,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);
      final record = store.unlockedAchievementsById['special:francotirados'];
      final achievement =
          AchievementCatalog.achievementForId('special:francotirados');

      expect(record, isNotNull);
      expect(record!.targetValue, 100);
      expect(achievement?.targetValue, 100);
    });
  });
}

Future<void> _seedStore({
  required String scopeUserId,
  required Map<String, dynamic> state,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(scopeUserId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(state);
}

Future<UserStateStore> _reloadStore({
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
  Map<String, Map<String, dynamic>> completionsByDay =
      const <String, Map<String, dynamic>>{},
  Map<String, Map<String, dynamic>> countValuesByDay =
      const <String, Map<String, dynamic>>{},
  List<Map<String, dynamic>> unlocked = const <Map<String, dynamic>>[],
  List<String> rewardAppliedAchievementIds = const <String>[],
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
          'unlocked': unlocked,
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': rewardAppliedAchievementIds,
          'progress': <String, dynamic>{},
        },
      },
      'claims': <String, dynamic>{
        'milestonesClaimed': <dynamic>[],
        'achievementRewardsClaimed': <dynamic>[],
        'prestigeClaimed': <dynamic>[],
      },
      'daily': <String, dynamic>{
        'lastResetDate': _dateKey(DateTime.now()),
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': completionsByDay,
        'habitCountValues': countValuesByDay,
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
  required String familyId,
  required String type,
  required num target,
}) {
  return <String, dynamic>{
    'id': id,
    'createdAt': '2026-01-01',
    'name': 'Habit $id',
    'emoji': '*',
    'familyId': familyId,
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

Map<String, Map<String, dynamic>> _dailyCheckCompletions({
  required String habitId,
  required DateTime endDate,
  required int dayCount,
}) {
  final output = <String, Map<String, dynamic>>{};

  for (var offset = 0; offset < dayCount; offset += 1) {
    final day = endDate.subtract(Duration(days: offset));
    output[_dateKey(day)] = <String, dynamic>{habitId: true};
  }

  return output;
}

Map<String, Map<String, dynamic>> _dailyCountValues({
  required String habitId,
  required DateTime endDate,
  required int dayCount,
  required num value,
}) {
  final output = <String, Map<String, dynamic>>{};

  for (var offset = 0; offset < dayCount; offset += 1) {
    final day = endDate.subtract(Duration(days: offset));
    output[_dateKey(day)] = <String, dynamic>{habitId: value};
  }

  return output;
}

Map<String, dynamic> _unlockedRecordJson({
  required String id,
  required AchievementTier tier,
  required String habitName,
  required int targetValue,
  required DateTime unlockedAt,
}) {
  return <String, dynamic>{
    'id': id,
    'type': 'special',
    'tier': tier.key,
    'unlockedAt': unlockedAt.toUtc().toIso8601String(),
    'habitId': id,
    'habitName': habitName,
    'familyId': 'special',
    'targetValue': targetValue,
  };
}

String _dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
