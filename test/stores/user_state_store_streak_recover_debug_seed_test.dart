import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/habits/domain/models/recoverable_streak_break.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore debug streak recover seed', () {
    test('creates a recoverable break for yesterday', () async {
      final store = await _createStore(
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'proyecto_personal',
            'title': 'Proyecto personal',
          },
        ],
      );

      await store.seedDebugRecoverableStreakBreak(forceEnabled: true);

      final seeded =
          _breakFor(store, 'debug_streak_break_proyecto_personal_2026-07-21');
      expect(seeded, isNotNull);
      expect(seeded!.habitId, 'proyecto_personal');
      expect(seeded.userId, 'debug-user');
      expect(seeded.missedOccurrenceDateKey, '2026-07-21');
      expect(seeded.previousStreak, 3);
      expect(seeded.currentStreakAfterBreak, 0);
      expect(seeded.status, RecoverableStreakBreakStatus.recoverable);
      expect(seeded.shieldProtected, isFalse);
    });

    test('prefers proyecto_personal when it exists', () async {
      final store = await _createStore(
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-other',
            'title': 'Otro hábito',
          },
          <String, dynamic>{
            'id': 'proyecto_personal',
            'title': 'Proyecto personal',
          },
        ],
      );

      await store.seedDebugRecoverableStreakBreak(forceEnabled: true);

      final seeded =
          _breakFor(store, 'debug_streak_break_proyecto_personal_2026-07-21');
      expect(seeded, isNotNull);
      expect(seeded!.habitId, 'proyecto_personal');
    });

    test('falls back to the first active habit', () async {
      final store = await _createStore(
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-first',
            'title': 'Primer hábito',
          },
          <String, dynamic>{
            'id': 'habit-second',
            'title': 'Segundo hábito',
          },
        ],
      );

      await store.seedDebugRecoverableStreakBreak(forceEnabled: true);

      final seeded =
          _breakFor(store, 'debug_streak_break_habit-first_2026-07-21');
      expect(seeded, isNotNull);
      expect(seeded!.habitId, 'habit-first');
    });

    test('does not duplicate an existing debug break or touch other breaks',
        () async {
      final existingDebugBreak = RecoverableStreakBreak(
        id: 'debug_streak_break_proyecto_personal_2026-07-21',
        userId: 'debug-user',
        habitId: 'proyecto_personal',
        brokenAtMillis: 123,
        missedOccurrenceDateKey: '2026-07-21',
        previousStreak: 7,
        currentStreakAfterBreak: 1,
        status: RecoverableStreakBreakStatus.recoverable,
        shieldProtected: false,
      );
      final otherBreak = RecoverableStreakBreak(
        id: 'real-break-1',
        userId: 'debug-user',
        habitId: 'habit-other',
        brokenAtMillis: 456,
        missedOccurrenceDateKey: '2026-07-20',
        previousStreak: 9,
        currentStreakAfterBreak: 0,
        status: RecoverableStreakBreakStatus.recoverable,
        shieldProtected: false,
      );

      final store = await _createStore(
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'proyecto_personal',
            'title': 'Proyecto personal',
          },
        ],
        breaks: <String, dynamic>{
          existingDebugBreak.id: existingDebugBreak.toJson(),
          otherBreak.id: otherBreak.toJson(),
        },
      );

      await store.seedDebugRecoverableStreakBreak(forceEnabled: true);

      final breaks = _allBreaks(store);
      expect(breaks, hasLength(2));
      expect(_breakFor(store, existingDebugBreak.id)?.toJson(),
          existingDebugBreak.toJson());
      expect(_breakFor(store, otherBreak.id)?.toJson(), otherBreak.toJson());
    });

    test('does not execute when the flag is disabled', () async {
      final store = await _createStore(
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'proyecto_personal',
            'title': 'Proyecto personal',
          },
        ],
      );

      await store.seedDebugRecoverableStreakBreak();

      expect(
        _breakFor(store, 'debug_streak_break_proyecto_personal_2026-07-21'),
        isNull,
      );
      expect(_allBreaks(store), isEmpty);
    });
  });
}

Future<UserStateStore> _createStore({
  required List<Map<String, dynamic>> activeHabits,
  Map<String, dynamic> breaks = const <String, dynamic>{},
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('debug-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    nowProvider: () => DateTime.utc(2026, 7, 22, 12),
  );

  await store.save(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': 'debug-user',
        'meta': <String, dynamic>{
          'schemaVersion': 1,
          'lastSavedAt': '2026-07-22T12:00:00.000Z',
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
          'lastResetDate': '2026-07-22',
          'xpEarnedToday': 0,
          'coinsEarnedToday': 0,
          'habitsCompletedToday': <String, dynamic>{},
        },
        'history': <String, dynamic>{
          'habitCompletions': <String, dynamic>{},
          'habitCountValues': <String, dynamic>{},
          'habitSkips': <String, dynamic>{},
          'habitCompletionTimes': <String, dynamic>{},
          'habitOccurrenceStatuses': <String, dynamic>{},
          'habitStreakBreaks': breaks,
          'habitStreakShields': <String, dynamic>{},
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
        'activeHabits': activeHabits
            .map((habit) => Map<String, dynamic>.from(habit))
            .toList(growable: false),
      },
    },
  );

  return store;
}

List<RecoverableStreakBreak> _allBreaks(UserStateStore store) {
  return store.recoverableStreakBreaks.toList(growable: false);
}

RecoverableStreakBreak? _breakFor(UserStateStore store, String breakId) {
  for (final breakRecord in store.recoverableStreakBreaks) {
    if (breakRecord.id == breakId) return breakRecord;
  }
  return null;
}
