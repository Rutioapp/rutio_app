import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore addHabitFromCatalog', () {
    test('creates check habit and it appears in Home', () async {
      final store = await _seedStore();

      await store.addHabitFromCatalog(
        habitDef: <String, dynamic>{
          'id': 'check-habit',
          'name': 'Stretch',
          'emoji': '🧍',
          'type': 'check',
          'metric': <String, dynamic>{'unit': null},
        },
        familyId: 'body',
      );

      final habit = _activeHabitById(store, 'check-habit');
      expect(habit, isNotNull);
      expect(habit!['type'], 'check');
      expect(habit['schedule'], {'type': 'daily'});

      final home = _homeViewForToday(store);
      expect(home.viewHabits.map((habit) => habit['id']), contains('check-habit'));
    });

    test('creates count habit with defaults and it appears in Home', () async {
      final store = await _seedStore();

      await store.addHabitFromCatalog(
        habitDef: <String, dynamic>{
          'id': 'count-default',
          'name': 'Read',
          'emoji': '📚',
          'type': 'count',
          'metric': <String, dynamic>{'unit': 'minutes'},
          'nameTemplate': 'Read {target} minutes',
        },
        familyId: 'mind',
      );

      final habit = _activeHabitById(store, 'count-default');
      expect(habit, isNotNull);
      expect(habit!['type'], 'count');
      expect(habit['target'], 10);
      expect(habit['targetCount'], 10);
      expect(habit['unit'], 'minutes');
      expect(habit['unitLabel'], 'minutes');
      expect(habit['schedule'], {'type': 'daily'});

      final home = _homeViewForToday(store);
      expect(home.viewHabits.map((habit) => habit['id']), contains('count-default'));
    });

    test('creates count habit with modified target and it appears in Home',
        () async {
      final store = await _seedStore();

      await store.addHabitFromCatalog(
        habitDef: <String, dynamic>{
          'id': 'count-edited',
          'name': 'Meditate',
          'emoji': '🧘',
          'type': 'count',
          'metric': <String, dynamic>{'unit': 'minutes'},
          'nameTemplate': 'Meditate {target} minutes',
        },
        familyId: 'spirit',
        target: 15,
      );

      final habit = _activeHabitById(store, 'count-edited');
      expect(habit, isNotNull);
      expect(habit!['type'], 'count');
      expect(habit['target'], 15);
      expect(habit['targetCount'], 15);
      expect(habit['unit'], 'minutes');
      expect(habit['unitLabel'], 'minutes');
      expect(habit['name'], 'Meditate 15 minutes');

      final home = _homeViewForToday(store);
      expect(home.viewHabits.map((habit) => habit['id']), contains('count-edited'));
    });

    test('creates count habit with weekly frequency and expected model values',
        () async {
      final store = await _seedStore();
      final today = _todayDate();

      await store.addHabitFromCatalog(
        habitDef: <String, dynamic>{
          'id': 'count-weekly',
          'name': 'Walk',
          'emoji': '🚶',
          'type': 'count',
          'metric': <String, dynamic>{'unit': 'minutes'},
          'nameTemplate': 'Walk {target} minutes',
        },
        familyId: 'body',
        target: 25,
        scheduleType: 'weekly',
        weekdays: <int>[today.weekday],
      );

      final habit = _activeHabitById(store, 'count-weekly');
      expect(habit, isNotNull);
      expect(habit!['type'], 'count');
      expect(
        habit['schedule'],
        {
          'type': 'weekly',
          'weekdays': <int>[today.weekday],
        },
      );
      expect(habit['target'], 25);
      expect(habit['targetCount'], 25);

      final home = _homeViewForToday(store);
      expect(home.viewHabits.map((habit) => habit['id']), contains('count-weekly'));
    });
  });
}

Future<UserStateStore> _seedStore() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user_123');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState());
  return store;
}

Map<String, dynamic> _baseState() {
  final today = _todayKey();
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'user_123',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
        'activeViewDateKey': today,
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
        'equipped': <String, dynamic>{
          'avatar_skin': null,
          'aura': null,
          'badge': null,
          'title': null,
          'animation': null,
        },
        'badges': <String, dynamic>{
          'owned': <dynamic>[],
          'shown': null,
        },
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
        'lastResetDate': today,
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
      'activeHabits': <Map<String, dynamic>>[],
    },
  };
}

Map<String, dynamic>? _activeHabitById(UserStateStore store, String habitId) {
  for (final habit in store.activeHabits) {
    if ((habit['id'] ?? '').toString() == habitId) {
      return habit;
    }
  }
  return null;
}

HomeViewData _homeViewForToday(UserStateStore store) {
  return buildHomeViewData(store.state, _todayDate());
}

DateTime _todayDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _todayKey() {
  final today = _todayDate();
  final y = today.year.toString().padLeft(4, '0');
  final m = today.month.toString().padLeft(2, '0');
  final d = today.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
