import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/gamification/domain/level_event.dart';
import 'package:rutio/features/gamification/domain/level_event_resolver.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';

void main() {
  group('LevelProgression', () {
    test('totalXp = 0 produces level 1', () {
      final progress = LevelProgression.fromTotalXp(0);

      expect(progress.level, 1);
      expect(progress.currentLevelXp, 0);
      expect(progress.progress, inInclusiveRange(0.0, 1.0));
    });

    test('negative totalXp is clamped safely', () {
      final progress = LevelProgression.fromTotalXp(-42);

      expect(progress.totalXp, 0);
      expect(progress.level, 1);
      expect(progress.currentLevelXp, 0);
      expect(progress.xpToNextLevel, greaterThanOrEqualTo(0));
    });

    test('XP just before level 2 threshold stays at level 1', () {
      final beforeLevel2 = LevelProgression.xpToReachLevel(2) - 1;
      final progress = LevelProgression.fromTotalXp(beforeLevel2);

      expect(progress.level, 1);
    });

    test('XP exactly at level 2 threshold levels up to 2', () {
      final level2Threshold = LevelProgression.xpToReachLevel(2);
      final progress = LevelProgression.fromTotalXp(level2Threshold);

      expect(progress.level, 2);
      expect(progress.currentLevelXp, 0);
    });

    test('currentLevelXp is correct after level up', () {
      final level2Start = LevelProgression.xpToReachLevel(2);
      final progress = LevelProgression.fromTotalXp(level2Start + 7);

      expect(progress.level, 2);
      expect(progress.currentLevelXp, 7);
    });

    test('xpForNextLevel matches required XP for current level', () {
      final cases = <int>[0, 1, 80, 200, 1000, 5000];
      for (final totalXp in cases) {
        final progress = LevelProgression.fromTotalXp(totalXp);
        expect(
          progress.xpForNextLevel,
          LevelProgression.xpRequiredForLevel(progress.level),
        );
      }
    });

    test('xpToNextLevel is correct and never negative', () {
      final cases = <int>[0, 1, 79, 80, 81, 250, 3000, 50000];
      for (final totalXp in cases) {
        final progress = LevelProgression.fromTotalXp(totalXp);
        expect(progress.xpToNextLevel, greaterThanOrEqualTo(0));
        expect(
          progress.xpToNextLevel,
          progress.xpForNextLevel - progress.currentLevelXp,
        );
      }
    });

    test('progress stays between 0 and 1', () {
      final samples = <int>[0, 1, 79, 80, 81, 250, 3000, 50000];
      for (final xp in samples) {
        final progress = LevelProgression.fromTotalXp(xp);
        expect(progress.progress, inInclusiveRange(0.0, 1.0));
      }
    });

    test('high totalXp values do not fail', () {
      final progress = LevelProgression.fromTotalXp(2000000000);

      expect(progress.level, greaterThanOrEqualTo(1));
      expect(progress.currentLevelXp, greaterThanOrEqualTo(0));
      expect(progress.xpForNextLevel, greaterThan(0));
      expect(progress.progress, inInclusiveRange(0.0, 1.0));
    });

    test('xpRequiredForLevel values grow for sampled levels', () {
      final xp1 = LevelProgression.xpRequiredForLevel(1);
      final xp2 = LevelProgression.xpRequiredForLevel(2);
      final xp5 = LevelProgression.xpRequiredForLevel(5);
      final xp10 = LevelProgression.xpRequiredForLevel(10);

      expect(xp1, greaterThan(0));
      expect(xp2, greaterThan(xp1));
      expect(xp5, greaterThan(xp2));
      expect(xp10, greaterThan(xp5));
    });
  });

  group('LevelEventResolver', () {
    const resolver = LevelEventResolver();

    test('level 5 => firstMilestone', () {
      expect(
        resolver.eventTypeForLevel(5),
        LevelEventType.firstMilestone,
      );
    });

    test('level 10 => majorMilestone', () {
      expect(
        resolver.eventTypeForLevel(10),
        LevelEventType.majorMilestone,
      );
    });

    test('level 20 => majorMilestone', () {
      expect(
        resolver.eventTypeForLevel(20),
        LevelEventType.majorMilestone,
      );
    });

    test('level 30 => majorMilestone', () {
      expect(
        resolver.eventTypeForLevel(30),
        LevelEventType.majorMilestone,
      );
    });

    test('level 2 => normalLevelUp', () {
      expect(
        resolver.eventTypeForLevel(2),
        LevelEventType.normalLevelUp,
      );
    });

    test('level 3 => normalLevelUp', () {
      expect(
        resolver.eventTypeForLevel(3),
        LevelEventType.normalLevelUp,
      );
    });

    test('level 6 => normalLevelUp', () {
      expect(
        resolver.eventTypeForLevel(6),
        LevelEventType.normalLevelUp,
      );
    });

    test('level 7 => normalLevelUp', () {
      expect(
        resolver.eventTypeForLevel(7),
        LevelEventType.normalLevelUp,
      );
    });

    test('no event when there is no real level-up transition', () {
      final events = resolver.resolveLevelUps(previousLevel: 1, currentLevel: 1);
      expect(events, isEmpty);
    });
  });
}
