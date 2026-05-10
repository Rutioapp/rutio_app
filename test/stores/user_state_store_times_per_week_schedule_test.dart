import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore timesPerWeek canonical schedule', () {
    test('addCustomHabit persists canonical timesPerWeek for check habits',
        () async {
      final store = await _seedStore(habits: []);

      await store.addCustomHabit({
        'id': 'check-tpw',
        'name': 'Check TPW',
        'type': 'check',
        'frequencyMode': 'timesPerWeek',
        'timesPerWeekTarget': 3,
      });

      final habit = _activeHabitById(store, 'check-tpw');
      expect(habit, isNotNull);
      expect(
        habit!['schedule'],
        {
          'type': 'timesPerWeek',
          'timesPerWeek': 3,
          'weekStartsOn': 1,
        },
      );
    });

    test('addCustomHabit normalizes invalid timesPerWeek payload values',
        () async {
      final store = await _seedStore(habits: []);

      await store.addCustomHabit({
        'id': 'check-tpw-invalid',
        'name': 'Check TPW Invalid',
        'type': 'check',
        'schedule': {
          'type': 'timesPerWeek',
          'timesPerWeek': 0,
          'weekStartsOn': 9,
        },
      });

      final habit = _activeHabitById(store, 'check-tpw-invalid');
      expect(habit, isNotNull);
      expect(
        habit!['schedule'],
        {
          'type': 'timesPerWeek',
          'timesPerWeek': 1,
          'weekStartsOn': 1,
        },
      );
    });

    test('count habits do not persist timesPerWeek schedules', () async {
      final store = await _seedStore(habits: []);

      await store.addCustomHabit({
        'id': 'count-no-tpw',
        'name': 'Count Habit',
        'type': 'count',
        'target': 5,
        'frequencyMode': 'timesPerWeek',
        'timesPerWeekTarget': 4,
        'schedule': {
          'type': 'timesPerWeek',
          'timesPerWeek': 4,
          'weekStartsOn': 1,
        },
      });

      final habit = _activeHabitById(store, 'count-no-tpw');
      expect(habit, isNotNull);
      expect(habit!['schedule'], {'type': 'daily'});
    });

    test('updateHabitDetailsFromEdit keeps canonical timesPerWeek schedule',
        () async {
      final store = await _seedStore(
        habits: [_habit(id: 'edit-check', schedule: const {'type': 'daily'})],
      );

      await store.updateHabitDetailsFromEdit({
        'id': 'edit-check',
        'type': 'check',
        'frequencyMode': 'timesPerWeek',
        'timesPerWeekTarget': 4,
        'schedule': {
          'type': 'timesPerWeek',
          'timesPerWeek': 4,
          'weekStartsOn': 1,
        },
      });

      final habit = _activeHabitById(store, 'edit-check');
      expect(habit, isNotNull);
      expect(
        habit!['schedule'],
        {
          'type': 'timesPerWeek',
          'timesPerWeek': 4,
          'weekStartsOn': 1,
        },
      );
    });

    test('legacy timesPerWeek fields normalize into canonical schedule',
        () async {
      final store = await _seedStore(
        habits: [_habit(id: 'legacy-check', schedule: const {'type': 'daily'})],
      );

      await store.updateHabitDetailsFromEdit({
        'id': 'legacy-check',
        'type': 'check',
        'frequencyMode': 'timesPerWeek',
        'timesPerWeekTarget': 2,
      });

      final habit = _activeHabitById(store, 'legacy-check');
      expect(habit, isNotNull);
      expect(
        habit!['schedule'],
        {
          'type': 'timesPerWeek',
          'timesPerWeek': 2,
          'weekStartsOn': 1,
        },
      );
    });

    test('daily, weekly, and once schedules remain unchanged', () async {
      final store = await _seedStore(habits: []);

      await store.addCustomHabit({
        'id': 'daily-check',
        'name': 'Daily',
        'type': 'check',
        'schedule': {'type': 'daily'},
      });
      await store.addCustomHabit({
        'id': 'weekly-check',
        'name': 'Weekly',
        'type': 'check',
        'schedule': {
          'type': 'weekly',
          'weekdays': [1, 3, 5],
        },
      });
      await store.addCustomHabit({
        'id': 'once-check',
        'name': 'Once',
        'type': 'check',
        'schedule': {
          'type': 'once',
          'date': '2026-05-21',
        },
      });

      expect(_activeHabitById(store, 'daily-check')!['schedule'], {'type': 'daily'});
      expect(
        _activeHabitById(store, 'weekly-check')!['schedule'],
        {
          'type': 'weekly',
          'weekdays': [1, 3, 5],
        },
      );
      expect(
        _activeHabitById(store, 'once-check')!['schedule'],
        {
          'type': 'once',
          'date': '2026-05-21',
        },
      );
    });
  });
}

Future<UserStateStore> _seedStore({
  required List<Map<String, dynamic>> habits,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user_123');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(habits: habits));
  return store;
}

Map<String, dynamic> _baseState({
  required List<Map<String, dynamic>> habits,
}) {
  final today = _todayKey();
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'user_123',
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
      'activeHabits': habits,
    },
  };
}

Map<String, dynamic> _habit({
  required String id,
  required Map<String, dynamic> schedule,
  String type = 'check',
  String createdAt = '2026-05-01',
  num target = 1,
}) {
  return <String, dynamic>{
    'id': id,
    'createdAt': createdAt,
    'name': 'Habit $id',
    'emoji': '*',
    'familyId': 'mind',
    'type': type,
    'target': target,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': schedule,
    'archived': false,
    'isCustom': true,
    'reminderEnabled': false,
    'reminderTime': null,
  };
}

Map<String, dynamic>? _activeHabitById(UserStateStore store, String habitId) {
  final state = Map<String, dynamic>.from(store.state!);
  final userState = Map<String, dynamic>.from(state['userState'] as Map);
  final activeHabits =
      List<Map<String, dynamic>>.from((userState['activeHabits'] as List).map(
    (entry) => Map<String, dynamic>.from(entry as Map),
  ));
  for (final habit in activeHabits) {
    if ((habit['id'] ?? '').toString() == habitId) {
      return habit;
    }
  }
  return null;
}

String _todayKey() {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day);
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
