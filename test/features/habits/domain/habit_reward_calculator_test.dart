import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/habit_reward_calculator.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';

void main() {
  const calculator = HabitRewardCalculator();

  group('HabitRewardCalculator', () {
    test('XP boost adds exactly 50 percent and consumes one use', () {
      final result = calculator.calculate(
        baseXp: 10,
        baseCoins: 0,
        xpBoost: _boost(ActiveUtilityEffectType.xpBoost),
        coinBoost: null,
      );

      expect(result.bonusXp, 5);
      expect(result.totalXp, 15);
      expect(result.bonusCoins, 0);
      expect(result.totalCoins, 0);
      expect(result.consumesXpBoostUse, isTrue);
      expect(result.consumesCoinBoostUse, isFalse);
    });

    test('Coin boost rounds up a 50 percent bonus', () {
      final result = calculator.calculate(
        baseXp: 0,
        baseCoins: 5,
        xpBoost: null,
        coinBoost: _boost(ActiveUtilityEffectType.coinBoost),
      );

      expect(result.bonusCoins, 3);
      expect(result.totalCoins, 8);
      expect(result.bonusXp, 0);
      expect(result.totalXp, 0);
      expect(result.consumesXpBoostUse, isFalse);
      expect(result.consumesCoinBoostUse, isTrue);
    });

    test('XP and Coin boosts can coexist on the same reward', () {
      final result = calculator.calculate(
        baseXp: 4,
        baseCoins: 5,
        xpBoost: _boost(ActiveUtilityEffectType.xpBoost),
        coinBoost: _boost(ActiveUtilityEffectType.coinBoost),
      );

      expect(result.bonusXp, 2);
      expect(result.totalXp, 6);
      expect(result.bonusCoins, 3);
      expect(result.totalCoins, 8);
      expect(result.consumesXpBoostUse, isTrue);
      expect(result.consumesCoinBoostUse, isTrue);
    });

    test('zero-base rewards do not consume boost uses', () {
      final result = calculator.calculate(
        baseXp: 0,
        baseCoins: 0,
        xpBoost: _boost(ActiveUtilityEffectType.xpBoost),
        coinBoost: _boost(ActiveUtilityEffectType.coinBoost),
      );

      expect(result.bonusXp, 0);
      expect(result.bonusCoins, 0);
      expect(result.totalXp, 0);
      expect(result.totalCoins, 0);
      expect(result.consumesXpBoostUse, isFalse);
      expect(result.consumesCoinBoostUse, isFalse);
    });
  });
}

ActiveUtilityEffect _boost(ActiveUtilityEffectType type) {
  return ActiveUtilityEffect(
    id: type.key,
    utilityId: type == ActiveUtilityEffectType.xpBoost
        ? 'utility_xp_boost_1d'
        : 'utility_coin_boost_1d',
    type: type,
    activatedAtMillis: 1,
    remainingUses: 10,
    totalUses: 10,
  );
}
