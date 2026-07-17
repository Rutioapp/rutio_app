import '../../shop/domain/models/active_utility_effect.dart';

class HabitRewardResult {
  const HabitRewardResult({
    required this.baseXp,
    required this.bonusXp,
    required this.totalXp,
    required this.baseCoins,
    required this.bonusCoins,
    required this.totalCoins,
    required this.consumesXpBoostUse,
    required this.consumesCoinBoostUse,
  });

  final int baseXp;
  final int bonusXp;
  final int totalXp;
  final int baseCoins;
  final int bonusCoins;
  final int totalCoins;
  final bool consumesXpBoostUse;
  final bool consumesCoinBoostUse;
}

class HabitRewardCalculator {
  const HabitRewardCalculator();

  HabitRewardResult calculate({
    required int baseXp,
    required int baseCoins,
    required ActiveUtilityEffect? xpBoost,
    required ActiveUtilityEffect? coinBoost,
  }) {
    final safeBaseXp = baseXp < 0 ? 0 : baseXp;
    final safeBaseCoins = baseCoins < 0 ? 0 : baseCoins;

    final bonusXp =
        xpBoost != null && safeBaseXp > 0 ? (safeBaseXp * 0.5).round() : 0;
    final bonusCoins = coinBoost != null && safeBaseCoins > 0
        ? (safeBaseCoins * 0.5).ceil()
        : 0;

    return HabitRewardResult(
      baseXp: safeBaseXp,
      bonusXp: bonusXp,
      totalXp: safeBaseXp + bonusXp,
      baseCoins: safeBaseCoins,
      bonusCoins: bonusCoins,
      totalCoins: safeBaseCoins + bonusCoins,
      consumesXpBoostUse: xpBoost != null && safeBaseXp > 0,
      consumesCoinBoostUse: coinBoost != null && safeBaseCoins > 0,
    );
  }
}
