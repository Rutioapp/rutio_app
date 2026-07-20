import '../../features/achievements/application/achievement_catalog.dart';
import '../../features/achievements/domain/models/unlocked_achievement_record.dart';
import '../../features/gamification/domain/level_progression.dart';
import 'demo_seed_models.dart';
import 'demo_seed_dates.dart';
import 'demo_seed_habits.dart';
import 'demo_seed_history.dart';

class DemoSeedData {
  const DemoSeedData._();

  static const int initialDemoCoins = 1240;

  static DemoSeedPayload build({required DateTime now}) {
    final today = DemoSeedDates.dateOnly(now.toLocal());
    final todayKey = DemoSeedDates.dateKey(today);
    final habits = DemoSeedHabits.build(now: today);
    final history = DemoSeedHistory.build(now: today, habits: habits);
    final seededGamification = _buildGamificationState();
    final unlockedAchievements = _buildUnlockedAchievements(now: today);
    final unlockedAchievementJson = unlockedAchievements
        .map((record) => record.toJson())
        .toList(growable: false);
    final rewardAppliedAchievementIds =
        unlockedAchievements.map((record) => record.id).toList(growable: false);
    final featuredAchievementIds = _buildFeaturedAchievementIds(
      rewardAppliedAchievementIds,
    );

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
            // Prevent level-up overlays from replaying at every demo launch.
            'lastCelebratedLevel': seededGamification.level,
          },
          'progression': <String, dynamic>{
            'level': seededGamification.level,
            'xp': seededGamification.totalXp,
            'prestige': 0,
          },
          'wallet': <String, dynamic>{'coins': seededGamification.coins},
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
              'unlocked': unlockedAchievementJson,
              'featured': featuredAchievementIds,
              // Rewards are already reflected in seeded demo progression/wallet.
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

  static _DemoGamificationState _buildGamificationState() {
    const targetLevel = 12;
    final xpAtLevelStart = LevelProgression.xpToReachLevel(targetLevel);
    final xpForLevel = LevelProgression.xpRequiredForLevel(targetLevel);
    final xpIntoLevel = (xpForLevel * 0.42).round();
    final totalXp = xpAtLevelStart + xpIntoLevel;
    final progress = LevelProgression.fromTotalXp(totalXp);

    return _DemoGamificationState(
      totalXp: totalXp,
      level: progress.level,
      coins: initialDemoCoins,
    );
  }

  static List<UnlockedAchievementRecord> _buildUnlockedAchievements({
    required DateTime now,
  }) {
    const ids = <String>[
      'family_consistency:mind:madera',
      'family_consistency:mind:piedra',
      'family_consistency:mind:bronce',
      'family_consistency:mind:plata',
      'family_consistency:body:madera',
      'family_consistency:body:piedra',
      'family_consistency:body:bronce',
      'family_consistency:body:plata',
      'family_consistency:body:oro',
      'family_consistency:discipline:madera',
      'family_consistency:discipline:piedra',
      'family_consistency:discipline:bronce',
      'family_consistency:discipline:plata',
      'family_consistency:emotional:madera',
      'family_consistency:professional:madera',
      'family_consistency:spirit:madera',
      'special:flash',
      'special:el_centurion',
      'special:turista',
      'special:polimota',
      'special:hay_alguien_ahi',
      'special:guerrero_del_finde',
      'special:francotirados',
      'special:madrugador',
      'special:buho_nocturno',
      'special:imparable',
      'special:el_arquitecto',
      'special:leyenda_viva',
    ];

    final output = <UnlockedAchievementRecord>[];
    for (var index = 0; index < ids.length; index += 1) {
      final id = ids[index];
      final achievement = AchievementCatalog.achievementForId(id);
      if (achievement == null) continue;

      output.add(
        UnlockedAchievementRecord(
          id: achievement.id,
          type: achievement.type,
          tier: achievement.tier,
          unlockedAt: now.subtract(Duration(days: 190 - (index * 3))),
          habitId: achievement.habitId,
          habitName: achievement.habitName,
          familyId: achievement.familyId,
          targetValue: achievement.targetValue,
        ),
      );
    }

    output.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    return output;
  }

  static List<String> _buildFeaturedAchievementIds(List<String> unlockedIds) {
    const preferred = <String>[
      'special:el_centurion',
      'special:imparable',
      'family_consistency:mind:bronce',
    ];

    final featured = <String>[];
    for (final id in preferred) {
      if (!unlockedIds.contains(id)) continue;
      if (featured.contains(id)) continue;
      featured.add(id);
    }
    return featured;
  }
}

class _DemoGamificationState {
  const _DemoGamificationState({
    required this.totalXp,
    required this.level,
    required this.coins,
  });

  final int totalXp;
  final int level;
  final int coins;
}
