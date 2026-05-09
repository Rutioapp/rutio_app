import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore expected-date mutation guards', () {
    test('weekly completion is ignored on non-scheduled weekday', () async {
      final store = await _seedStore(habits: [
        _habit(
          id: 'weekly-check',
          schedule: const {'type': 'weekly', 'weekdays': [1, 3]},
        ),
      ]);

      await store.setHabitCompletionForKey(
        habitId: 'weekly-check',
        dateKey: '2026-05-12',
        done: true,
      );

      expect(_historyDoneFor(store, '2026-05-12', 'weekly-check'), isNull);
    });

    test('weekly completion works on scheduled weekday', () async {
      final store = await _seedStore(habits: [
        _habit(
          id: 'weekly-check',
          schedule: const {'type': 'weekly', 'weekdays': [1, 3]},
        ),
      ]);

      await store.setHabitCompletionForKey(
        habitId: 'weekly-check',
        dateKey: '2026-05-11',
        done: true,
      );

      expect(_historyDoneFor(store, '2026-05-11', 'weekly-check'), isTrue);
    });

    test('weekly skip is ignored on non-scheduled weekday', () async {
      final store = await _seedStore(habits: [
        _habit(
          id: 'weekly-check',
          schedule: const {'type': 'weekly', 'weekdays': [1, 3]},
        ),
      ]);

      await store.setHabitSkipForKey(
        habitId: 'weekly-check',
        dateKey: '2026-05-12',
        skipped: true,
      );

      expect(_historySkipFor(store, '2026-05-12', 'weekly-check'), isNull);
    });

    test('count value update is ignored on non-scheduled weekday', () async {
      final store = await _seedStore(habits: [
        _habit(
          id: 'weekly-count',
          type: 'count',
          target: 5,
          schedule: const {'type': 'weekly', 'weekdays': [1, 3]},
        ),
      ]);

      await store.setCountHabitValueForDate(
        habitId: 'weekly-count',
        date: DateTime(2026, 5, 12),
        value: 3,
      );

      expect(_historyCountFor(store, '2026-05-12', 'weekly-count'), isNull);
      expect(_historyDoneFor(store, '2026-05-12', 'weekly-count'), isNull);
      expect(_historySkipFor(store, '2026-05-12', 'weekly-count'), isNull);
    });

    test('once completion only works on configured date', () async {
      final store = await _seedStore(habits: [
        _habit(
          id: 'once-check',
          schedule: const {'type': 'once', 'date': '2026-05-20'},
        ),
      ]);

      await store.setHabitCompletionForKey(
        habitId: 'once-check',
        dateKey: '2026-05-19',
        done: true,
      );
      expect(_historyDoneFor(store, '2026-05-19', 'once-check'), isNull);

      await store.setHabitCompletionForKey(
        habitId: 'once-check',
        dateKey: '2026-05-20',
        done: true,
      );
      expect(_historyDoneFor(store, '2026-05-20', 'once-check'), isTrue);
    });

    test('completion is ignored before createdAt', () async {
      final store = await _seedStore(habits: [
        _habit(
          id: 'daily-future',
          createdAt: '2026-05-20',
          schedule: const {'type': 'daily'},
        ),
      ]);

      await store.setHabitCompletionForKey(
        habitId: 'daily-future',
        dateKey: '2026-05-19',
        done: true,
      );

      expect(_historyDoneFor(store, '2026-05-19', 'daily-future'), isNull);
    });

    test('archived habit cannot be mutated', () async {
      final store = await _seedStore(habits: [
        _habit(
          id: 'archived-count',
          type: 'count',
          target: 2,
          archived: true,
          schedule: const {'type': 'daily'},
        ),
      ]);

      await store.setHabitCompletionForKey(
        habitId: 'archived-count',
        dateKey: '2026-05-11',
        done: true,
      );
      await store.setHabitSkipForKey(
        habitId: 'archived-count',
        dateKey: '2026-05-11',
        skipped: true,
      );
      await store.setCountHabitValueForDate(
        habitId: 'archived-count',
        date: DateTime(2026, 5, 11),
        value: 2,
      );

      expect(_historyDoneFor(store, '2026-05-11', 'archived-count'), isNull);
      expect(_historySkipFor(store, '2026-05-11', 'archived-count'), isNull);
      expect(_historyCountFor(store, '2026-05-11', 'archived-count'), isNull);
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
  bool archived = false,
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
    'archived': archived,
    'isCustom': true,
    'reminderEnabled': false,
    'reminderTime': null,
  };
}

dynamic _historyDoneFor(UserStateStore store, String dateKey, String habitId) {
  final state = Map<String, dynamic>.from(store.state!);
  final userState = Map<String, dynamic>.from(state['userState'] as Map);
  final history = Map<String, dynamic>.from(userState['history'] as Map);
  final completions =
      Map<String, dynamic>.from(history['habitCompletions'] as Map);
  final day = Map<String, dynamic>.from((completions[dateKey] as Map?) ?? {});
  return day[habitId];
}

dynamic _historySkipFor(UserStateStore store, String dateKey, String habitId) {
  final state = Map<String, dynamic>.from(store.state!);
  final userState = Map<String, dynamic>.from(state['userState'] as Map);
  final history = Map<String, dynamic>.from(userState['history'] as Map);
  final skips = Map<String, dynamic>.from(history['habitSkips'] as Map);
  final day = Map<String, dynamic>.from((skips[dateKey] as Map?) ?? {});
  return day[habitId];
}

dynamic _historyCountFor(
  UserStateStore store,
  String dateKey,
  String habitId,
) {
  final state = Map<String, dynamic>.from(store.state!);
  final userState = Map<String, dynamic>.from(state['userState'] as Map);
  final history = Map<String, dynamic>.from(userState['history'] as Map);
  final values = Map<String, dynamic>.from(history['habitCountValues'] as Map);
  final day = Map<String, dynamic>.from((values[dateKey] as Map?) ?? {});
  return day[habitId];
}

String _todayKey() {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day);
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
