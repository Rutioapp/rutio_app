import 'demo_seed_models.dart';

class DemoSeedData {
  const DemoSeedData._();

  static DemoSeedPayload build({required DateTime now}) {
    final today = _dayOnly(now);
    final todayKey = _dateKey(today);
    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
    final twoDaysAgoKey = _dateKey(today.subtract(const Duration(days: 2)));
    final threeDaysAgoKey = _dateKey(today.subtract(const Duration(days: 3)));

    const waterId = 'demo_habit_water';
    const readId = 'demo_habit_read';
    const stepsId = 'demo_habit_steps';

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
            'displayName': 'Demo User',
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
            'habitCompletions': <String, dynamic>{
              yesterdayKey: <String, dynamic>{
                waterId: true,
                readId: true,
                stepsId: true,
              },
              twoDaysAgoKey: <String, dynamic>{
                waterId: true,
                readId: false,
                stepsId: false,
              },
              threeDaysAgoKey: <String, dynamic>{
                readId: false,
              },
            },
            'habitCountValues': <String, dynamic>{
              yesterdayKey: <String, dynamic>{stepsId: 9200},
              twoDaysAgoKey: <String, dynamic>{stepsId: 5100},
            },
            'habitSkips': <String, dynamic>{
              threeDaysAgoKey: <String, dynamic>{readId: true},
            },
          },
          'activeHabits': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': waterId,
              'createdAt': threeDaysAgoKey,
              'name': 'Drink Water',
              'emoji': 'W',
              'description': 'Finish your water bottle',
              'familyId': 'body',
              'allFamilies': false,
              'type': 'check',
              'target': 1,
              'progress': 0,
              'doneToday': false,
              'skippedToday': false,
              'schedule': <String, dynamic>{'type': 'daily'},
              'isCustom': true,
            },
            <String, dynamic>{
              'id': readId,
              'createdAt': threeDaysAgoKey,
              'name': 'Read 10 min',
              'emoji': 'R',
              'description': 'Read at least 10 minutes',
              'familyId': 'mind',
              'allFamilies': false,
              'type': 'check',
              'target': 1,
              'progress': 0,
              'doneToday': false,
              'skippedToday': false,
              'schedule': <String, dynamic>{
                'type': 'weekly',
                'weekdays': <int>[1, 2, 3, 4, 5],
              },
              'isCustom': true,
            },
            <String, dynamic>{
              'id': stepsId,
              'createdAt': threeDaysAgoKey,
              'name': 'Walk Steps',
              'emoji': 'S',
              'description': 'Reach 8000 steps',
              'familyId': 'discipline',
              'allFamilies': false,
              'type': 'count',
              'unit': 'steps',
              'target': 8000,
              'progress': 0,
              'doneToday': false,
              'skippedToday': false,
              'schedule': <String, dynamic>{'type': 'daily'},
              'isCustom': true,
            },
          ],
        },
      },
    );
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
