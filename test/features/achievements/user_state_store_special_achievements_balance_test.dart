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
        'turista no longer unlocks when 6 families are spread outside a 7-day window',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-turista-old-semantics';
      final today = DateTime.now();
      final familyIds = <String>[
        'mind',
        'spirit',
        'body',
        'emotional',
        'social',
        'discipline',
      ];
      final habits = familyIds
          .map(
            (familyId) => _habit(
              id: 'turista-$familyId',
              familyId: familyId,
              type: 'check',
              target: 1,
            ),
          )
          .toList(growable: false);

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: _spreadFamilyCompletions(
            habits: habits,
            endDate: today,
            spacingDays: 2,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);

      expect(
        store.unlockedAchievementsById.containsKey('special:turista'),
        isFalse,
      );
      expect(
        store.achievementMetricSnapshots['special:turista']?.bestStreak,
        4,
      );
    });

    test('turista unlocks with 6 families completed inside 7 days', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-turista-new-semantics';
      final today = DateTime.now();
      final familyIds = <String>[
        'mind',
        'spirit',
        'body',
        'emotional',
        'social',
        'discipline',
      ];
      final habits = familyIds
          .map(
            (familyId) => _habit(
              id: 'turista-fast-$familyId',
              familyId: familyId,
              type: 'check',
              target: 1,
            ),
          )
          .toList(growable: false);

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: _spreadFamilyCompletions(
            habits: habits,
            endDate: today,
            spacingDays: 1,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);
      final record = store.unlockedAchievementsById['special:turista'];
      final achievement = AchievementCatalog.achievementForId('special:turista');

      expect(record, isNotNull);
      expect(record!.targetValue, 6);
      expect(achievement?.targetValue, 6);
    });

    test('polimota no longer unlocks just for having 7 active families', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-polimota-old-semantics';
      final habits = <Map<String, dynamic>>[
        _habit(id: 'polimota-mind', familyId: 'mind', type: 'check', target: 1),
        _habit(
          id: 'polimota-spirit',
          familyId: 'spirit',
          type: 'check',
          target: 1,
        ),
        _habit(id: 'polimota-body', familyId: 'body', type: 'check', target: 1),
        _habit(
          id: 'polimota-emotional',
          familyId: 'emotional',
          type: 'check',
          target: 1,
        ),
        _habit(
          id: 'polimota-social',
          familyId: 'social',
          type: 'check',
          target: 1,
        ),
        _habit(
          id: 'polimota-discipline',
          familyId: 'discipline',
          type: 'check',
          target: 1,
        ),
        _habit(
          id: 'polimota-professional',
          familyId: 'professional',
          type: 'check',
          target: 1,
        ),
      ];

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);

      expect(
        store.unlockedAchievementsById.containsKey('special:polimota'),
        isFalse,
      );
      expect(store.achievementMetricSnapshots['special:polimota']?.bestStreak, 0);
    });

    test('polimota unlocks with 7 families completed inside 21 days', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-polimota-new-semantics';
      final today = DateTime.now();
      final habits = <Map<String, dynamic>>[
        _habit(id: 'pm-mind', familyId: 'mind', type: 'check', target: 1),
        _habit(id: 'pm-spirit', familyId: 'spirit', type: 'check', target: 1),
        _habit(id: 'pm-body', familyId: 'body', type: 'check', target: 1),
        _habit(
          id: 'pm-emotional',
          familyId: 'emotional',
          type: 'check',
          target: 1,
        ),
        _habit(id: 'pm-social', familyId: 'social', type: 'check', target: 1),
        _habit(
          id: 'pm-discipline',
          familyId: 'discipline',
          type: 'check',
          target: 1,
        ),
        _habit(
          id: 'pm-professional',
          familyId: 'professional',
          type: 'check',
          target: 1,
        ),
      ];

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: _spreadFamilyCompletions(
            habits: habits,
            endDate: today,
            spacingDays: 1,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);
      final record = store.unlockedAchievementsById['special:polimota'];

      expect(record, isNotNull);
      expect(record!.targetValue, 7);
    });

    test(
        'el centurion no longer unlocks with 150 days at exactly 50 percent completion',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-centurion-old-semantics';
      final today = DateTime.now();
      final habits = <Map<String, dynamic>>[
        _habit(id: 'centurion-a', familyId: 'body', type: 'check', target: 1),
        _habit(id: 'centurion-b', familyId: 'mind', type: 'check', target: 1),
      ];

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: _partialDailyCompletions(
            completedHabitIdsByDay: List<List<String>>.generate(
              150,
              (_) => <String>['centurion-a'],
            ),
            endDate: today,
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
        0,
      );
    });

    test('el centurion unlocks with 150 majority-consistency days',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-centurion-new-threshold';
      final today = DateTime.now();
      final habits = <Map<String, dynamic>>[
        _habit(id: 'centurion-1', familyId: 'body', type: 'check', target: 1),
        _habit(id: 'centurion-2', familyId: 'mind', type: 'check', target: 1),
        _habit(
          id: 'centurion-3',
          familyId: 'discipline',
          type: 'check',
          target: 1,
        ),
      ];

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: _partialDailyCompletions(
            completedHabitIdsByDay: List<List<String>>.generate(
              150,
              (_) => <String>['centurion-1', 'centurion-2'],
            ),
            endDate: today,
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

    test('hay alguien ahi no longer unlocks with only 7 social days', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-social-old-semantics';
      final today = DateTime.now();
      final habit = _habit(
        id: 'social-old',
        familyId: 'social',
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
            dayCount: 7,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);

      expect(
        store.unlockedAchievementsById.containsKey('special:hay_alguien_ahi'),
        isFalse,
      );
      expect(
        store.achievementMetricSnapshots['special:hay_alguien_ahi']?.bestStreak,
        7,
      );
    });

    test('hay alguien ahi unlocks with 15 social completions', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-social-new-semantics';
      final today = DateTime.now();
      final habits = <Map<String, dynamic>>[
        _habit(id: 'social-1', familyId: 'social', type: 'check', target: 1),
        _habit(id: 'social-2', familyId: 'social', type: 'check', target: 1),
        _habit(id: 'social-3', familyId: 'social', type: 'check', target: 1),
      ];

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: _partialDailyCompletions(
            completedHabitIdsByDay: List<List<String>>.generate(
              5,
              (_) => <String>['social-1', 'social-2', 'social-3'],
            ),
            endDate: today,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);
      final record = store.unlockedAchievementsById['special:hay_alguien_ahi'];

      expect(record, isNotNull);
      expect(record!.targetValue, 15);
    });

    test('ave fenix unlocks after returning from a 2-day inactivity gap',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievements-balance-ave-fenix-new-semantics';
      final today = DateTime.now();
      final habit = _habit(
        id: 'ave-fenix',
        familyId: 'mind',
        type: 'check',
        target: 1,
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: <Map<String, dynamic>>[habit],
          completionsByDay: _partialDailyCompletions(
            completedHabitIdsByDay: <List<String>>[
              <String>[habit['id'] as String],
              <String>[],
              <String>[],
              <String>[habit['id'] as String],
            ],
            endDate: today,
          ),
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);
      final record = store.unlockedAchievementsById['special:ave_fenix'];

      expect(record, isNotNull);
      expect(record!.targetValue, 1);
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

Map<String, Map<String, dynamic>> _spreadFamilyCompletions({
  required List<Map<String, dynamic>> habits,
  required DateTime endDate,
  required int spacingDays,
}) {
  final output = <String, Map<String, dynamic>>{};

  for (var index = 0; index < habits.length; index += 1) {
    final day = endDate.subtract(Duration(days: index * spacingDays));
    output[_dateKey(day)] = <String, dynamic>{habits[index]['id'] as String: true};
  }

  return output;
}

Map<String, Map<String, dynamic>> _partialDailyCompletions({
  required List<List<String>> completedHabitIdsByDay,
  required DateTime endDate,
}) {
  final output = <String, Map<String, dynamic>>{};

  for (var offset = 0; offset < completedHabitIdsByDay.length; offset += 1) {
    final habitIds = completedHabitIdsByDay[offset];
    if (habitIds.isEmpty) continue;

    final day = endDate.subtract(Duration(days: offset));
    output[_dateKey(day)] = <String, dynamic>{
      for (final habitId in habitIds) habitId: true,
    };
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
