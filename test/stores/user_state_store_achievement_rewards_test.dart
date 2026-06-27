import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore achievement rewards', () {
    test('achievement reward adds coins to the real wallet on unlock', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievement-wallet-reward';
      final today = DateTime.now();
      final habits = List<Map<String, dynamic>>.generate(
        8,
        (index) => _habit(id: 'flash-$index'),
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: <String, Map<String, dynamic>>{
            _dateKey(today): <String, dynamic>{
              for (final habit in habits) habit['id'] as String: true,
            },
          },
        ),
      );

      final store = await _reloadStore(scopeUserId: scopeUserId);

      expect(_coins(store), 100);
      expect(_rewardAppliedIds(store), contains('special:flash'));
      expect(_unlockedAchievementIds(store), contains('special:flash'));
    });

    test('already rewarded achievement does not add wallet coins twice',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const scopeUserId = 'achievement-wallet-no-double-reward';
      final today = DateTime.now();
      final habits = List<Map<String, dynamic>>.generate(
        8,
        (index) => _habit(id: 'flash-repeat-$index'),
      );

      await _seedStore(
        scopeUserId: scopeUserId,
        state: _baseState(
          userId: scopeUserId,
          habits: habits,
          completionsByDay: <String, Map<String, dynamic>>{
            _dateKey(today): <String, dynamic>{
              for (final habit in habits) habit['id'] as String: true,
            },
          },
        ),
      );

      final firstLoad = await _reloadStore(scopeUserId: scopeUserId);
      expect(_coins(firstLoad), 100);

      final secondLoad = await _reloadStore(scopeUserId: scopeUserId);
      expect(_coins(secondLoad), 100);
      expect(_rewardAppliedIds(secondLoad), contains('special:flash'));
      expect(
        _rewardAppliedIds(secondLoad)
            .where((id) => id == 'special:flash')
            .length,
        1,
      );
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
        'lastResetDate': _dateKey(DateTime.now()),
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': completionsByDay,
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

Map<String, dynamic> _habit({required String id}) {
  return <String, dynamic>{
    'id': id,
    'createdAt': '2026-01-01',
    'name': 'Habit $id',
    'emoji': '*',
    'familyId': 'mind',
    'type': 'check',
    'target': 1,
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

int _coins(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final wallet = userState['wallet'] as Map<String, dynamic>;
  return (wallet['coins'] as num).toInt();
}

List<String> _rewardAppliedIds(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final profile = userState['profile'] as Map<String, dynamic>;
  final achievements = profile['achievements'] as Map<String, dynamic>;
  return (achievements['rewardAppliedAchievementIds'] as List<dynamic>)
      .map((entry) => entry.toString())
      .toList(growable: false);
}

List<String> _unlockedAchievementIds(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final profile = userState['profile'] as Map<String, dynamic>;
  final achievements = profile['achievements'] as Map<String, dynamic>;
  return (achievements['unlocked'] as List<dynamic>)
      .whereType<Map>()
      .map((entry) => entry['id'].toString())
      .toList(growable: false);
}

String _dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
