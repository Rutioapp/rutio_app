import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/gamification/application/level_up_celebration_controller.dart';
import 'package:rutio/features/gamification/domain/level_event.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';

void main() {
  const controller = LevelUpCelebrationController();

  group('LevelUpCelebrationController', () {
    test('does not emit event when previousLevel == newLevel', () {
      final previousXp = LevelProgression.xpToReachLevel(3);
      final nextXp = previousXp + 5;

      final decision = controller.evaluateXpChange(
        previousXp: previousXp,
        newXp: nextXp,
        lastCelebratedLevel: 0,
      );

      expect(decision.event, isNull);
      expect(decision.lastCelebratedLevel, 0);
    });

    test('emits event when newLevel > previousLevel', () {
      final previousXp = LevelProgression.xpToReachLevel(3) - 1;
      final nextXp = LevelProgression.xpToReachLevel(3);

      final decision = controller.evaluateXpChange(
        previousXp: previousXp,
        newXp: nextXp,
        lastCelebratedLevel: 0,
      );

      expect(decision.event, isNotNull);
      expect(decision.event!.level, 3);
      expect(decision.event!.type, LevelEventType.normalLevelUp);
      expect(decision.lastCelebratedLevel, 3);
    });

    test('when one XP grant crosses several levels, only final level is emitted', () {
      final previousXp = LevelProgression.xpToReachLevel(4) - 1;
      final nextXp = LevelProgression.xpToReachLevel(7);

      final decision = controller.evaluateXpChange(
        previousXp: previousXp,
        newXp: nextXp,
        lastCelebratedLevel: 0,
      );

      expect(decision.event, isNotNull);
      expect(decision.event!.level, 7);
      expect(decision.lastCelebratedLevel, 7);
    });

    test('does not re-emit event for an already celebrated level', () {
      final previousXp = LevelProgression.xpToReachLevel(9);
      final nextXp = LevelProgression.xpToReachLevel(10);

      final decision = controller.evaluateXpChange(
        previousXp: previousXp,
        newXp: nextXp,
        lastCelebratedLevel: 10,
      );

      expect(decision.event, isNull);
      expect(decision.lastCelebratedLevel, 10);
    });
  });
}
