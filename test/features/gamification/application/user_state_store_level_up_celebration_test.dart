import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore level-up celebration lifecycle', () {
    test('enqueueing level-up does not mark level as celebrated', () async {
      final thresholdLevel2 = LevelProgression.xpToReachLevel(2);
      final store = await _seedStore(
        xp: thresholdLevel2 - 10,
        lastCelebratedLevel: 0,
        habits: [_checkHabit('habit_one')],
      );

      await store.completeHabit(habitId: 'habit_one');

      expect(store.pendingLevelCelebrationCount, 1);
      expect(_lastCelebratedLevelFromStore(store), 0);
    });

    test('consuming level-up marks level as celebrated and persists it', () async {
      final thresholdLevel2 = LevelProgression.xpToReachLevel(2);
      final store = await _seedStore(
        xp: thresholdLevel2 - 10,
        lastCelebratedLevel: 0,
        habits: [_checkHabit('habit_one')],
      );

      await store.completeHabit(habitId: 'habit_one');
      final event = store.peekNextPendingLevelCelebration();

      expect(event, isNotNull);
      expect(event!.level, 2);
      expect(_lastCelebratedLevelFromStore(store), 0);

      await store.markLevelCelebrationAsCelebrated(level: event.level);

      expect(store.pendingLevelCelebrationCount, 0);
      expect(_lastCelebratedLevelFromStore(store), 2);

      final reloaded = await _buildStore(resetStorage: false);
      await reloaded.load();

      expect(_lastCelebratedLevelFromStore(reloaded), 2);
      expect(reloaded.pendingLevelCelebrationCount, 0);
    });

    test('already celebrated level is not enqueued again', () async {
      final thresholdLevel2 = LevelProgression.xpToReachLevel(2);
      final store = await _seedStore(
        xp: thresholdLevel2 - 10,
        lastCelebratedLevel: 2,
        habits: [_checkHabit('habit_one')],
      );

      await store.completeHabit(habitId: 'habit_one');

      expect(store.pendingLevelCelebrationCount, 0);
      expect(_lastCelebratedLevelFromStore(store), 2);
    });

    test('two XP gains in same level do not duplicate level-up popup', () async {
      final thresholdLevel2 = LevelProgression.xpToReachLevel(2);
      final store = await _seedStore(
        xp: thresholdLevel2 - 10,
        lastCelebratedLevel: 0,
        habits: [
          _checkHabit('habit_one'),
          _checkHabit('habit_two'),
        ],
      );

      await store.completeHabit(habitId: 'habit_one');
      expect(store.pendingLevelCelebrationCount, 1);

      await store.completeHabit(habitId: 'habit_two');
      expect(store.pendingLevelCelebrationCount, 1);
      expect(store.peekNextPendingLevelCelebration()?.level, 2);
    });
  });
}

Future<UserStateStore> _seedStore({
  required int xp,
  required int lastCelebratedLevel,
  required List<Map<String, dynamic>> habits,
}) async {
  final store = await _buildStore();
  final state = _baseState(
    xp: xp,
    lastCelebratedLevel: lastCelebratedLevel,
    habits: habits,
  );
  await store.save(state);
  return store;
}

Future<UserStateStore> _buildStore({bool resetStorage = true}) async {
  if (resetStorage) {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  }

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user_123');
  return UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
}

Map<String, dynamic> _baseState({
  required int xp,
  required int lastCelebratedLevel,
  required List<Map<String, dynamic>> habits,
}) {
  final safeXp = xp < 0 ? 0 : xp;
  final level = LevelProgression.fromTotalXp(safeXp).level;
  final today = _todayKey();

  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'user_123',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
        'diaryRewardAppliedDateKeys': <dynamic>[],
        'lastCelebratedLevel': lastCelebratedLevel,
      },
      'progression': <String, dynamic>{
        'level': level,
        'xp': safeXp,
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

Map<String, dynamic> _checkHabit(String id) {
  return <String, dynamic>{
    'id': id,
    'createdAt': _todayKey(),
    'name': 'Habit $id',
    'emoji': '*',
    'familyId': 'mind',
    'type': 'check',
    'target': 1,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': <String, dynamic>{'type': 'daily'},
    'isCustom': true,
    'reminderEnabled': false,
    'reminderTime': null,
  };
}

int _lastCelebratedLevelFromStore(UserStateStore store) {
  final root = Map<String, dynamic>.from(store.state!);
  final userState = Map<String, dynamic>.from(root['userState'] as Map);
  final meta = Map<String, dynamic>.from(userState['meta'] as Map);
  final raw = meta['lastCelebratedLevel'];
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

String _todayKey() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
