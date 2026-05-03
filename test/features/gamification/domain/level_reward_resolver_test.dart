import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/gamification/domain/level_reward_resolver.dart';

void main() {
  const resolver = LevelRewardResolver();

  group('LevelRewardResolver', () {
    test('level 5 rewards +50', () {
      expect(resolver.rewardForLevel(5), 50);
    });

    test('level 10 rewards +150', () {
      expect(resolver.rewardForLevel(10), 150);
    });

    test('level 20 rewards +300', () {
      expect(resolver.rewardForLevel(20), 300);
    });

    test('level 30 rewards +500', () {
      expect(resolver.rewardForLevel(30), 500);
    });

    test('level 40 rewards +750', () {
      expect(resolver.rewardForLevel(40), 750);
    });

    test('level 50 rewards +1000', () {
      expect(resolver.rewardForLevel(50), 1000);
    });

    test('level 6 rewards 0', () {
      expect(resolver.rewardForLevel(6), 0);
      expect(resolver.hasRewardForLevel(6), isFalse);
    });

    test('level 11 rewards 0', () {
      expect(resolver.rewardForLevel(11), 0);
      expect(resolver.hasRewardForLevel(11), isFalse);
    });

    test('level 60 rewards level * 20', () {
      expect(resolver.rewardForLevel(60), 1200);
      expect(resolver.hasRewardForLevel(60), isTrue);
    });
  });
}
