import 'demo_seed_models.dart';
import 'demo_seed_dates.dart';
import 'demo_seed_habits.dart';
import 'demo_seed_history.dart';

class DemoSeedData {
  const DemoSeedData._();

  static DemoSeedPayload build({required DateTime now}) {
    final today = DemoSeedDates.dateOnly(now.toLocal());
    final todayKey = DemoSeedDates.dateKey(today);
    final habits = DemoSeedHabits.build(now: today);
    final history = DemoSeedHistory.build(now: today, habits: habits);

    return DemoSeedPayload(
      userId: DemoSeedScope.userId,
      state: <String, dynamic>{
        'userState': <String, dynamic>{
          'userId': DemoSeedScope.userId,
          'meta': <String, dynamic>{
            'schemaVersion': 1,
            'lastSavedAt': today.toUtc().toIso8601String(),
            'diaryRewardAppliedDateKeys': <String>[],
            'onboardingDone': true,
            'activeViewDateKey': todayKey,
            'authEmail': 'demo@rutio.local',
          },
          'progression': <String, dynamic>{
            'level': 1,
            'xp': 0,
            'prestige': 0,
          },
          'wallet': <String, dynamic>{'coins': 0},
          'inventory': <String, dynamic>{'items': <dynamic>[]},
          'profile': <String, dynamic>{
            'displayName': 'Alex',
            'email': 'demo@rutio.local',
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
            'lastResetDate': todayKey,
            'xpEarnedToday': 0,
            'coinsEarnedToday': 0,
            'habitsCompletedToday': <String, dynamic>{},
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
          'history': <String, dynamic>{
            'habitCompletions': history.completions,
            'habitCountValues': history.countValues,
            'habitSkips': history.skips,
            'habitCompletionTimes': history.completionTimes,
          },
          'activeHabits': DemoSeedHabits.asStateActiveHabits(habits),
        },
      },
    );
  }
}
