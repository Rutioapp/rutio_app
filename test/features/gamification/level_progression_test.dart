import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';

void main() {
  test('level one uses the canonical 80 XP requirement', () {
    expect(LevelProgression.xpRequiredForLevel(1), 80);
    expect(LevelProgression.xpToReachLevel(1), 0);
    expect(LevelProgression.fromTotalXp(0).level, 1);
    expect(LevelProgression.fromTotalXp(79).level, 1);
    expect(LevelProgression.fromTotalXp(80).level, 2);
  });

  test('level boundaries are monotonic and internally consistent', () {
    for (var level = 1; level <= 20; level++) {
      final start = LevelProgression.xpToReachLevel(level);
      final requirement = LevelProgression.xpRequiredForLevel(level);
      final next = LevelProgression.xpToReachLevel(level + 1);

      expect(requirement, greaterThan(0));
      expect(next, start + requirement);
      expect(LevelProgression.fromTotalXp(start).level, level);
      expect(LevelProgression.fromTotalXp(next - 1).level, level);
      expect(LevelProgression.fromTotalXp(next).level, level + 1);
    }
  });

  test('legacy next_level_xp=100 is not the progression formula', () {
    expect(LevelProgression.xpRequiredForLevel(1), isNot(100));
  });
}
