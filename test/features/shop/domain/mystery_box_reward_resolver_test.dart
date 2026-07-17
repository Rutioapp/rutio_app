import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/mystery_box_reward_catalog.dart';
import 'package:rutio/features/shop/domain/mystery_box_reward_resolver.dart';

import '../../../support/fixed_random_source.dart';

void main() {
  group('MysteryBoxRewardResolver', () {
    test('resolves the exact configured ranges', () {
      const resolver = MysteryBoxRewardResolver();

      final expectations = <int, String>{
        0: 'reward_80_coins_40_xp',
        39: 'reward_80_coins_40_xp',
        40: 'reward_100_coins_50_xp',
        64: 'reward_100_coins_50_xp',
        65: 'reward_125_coins',
        79: 'reward_125_coins',
        80: 'reward_150_coins',
        84: 'reward_150_coins',
        85: 'reward_xp_boost_30_coins',
        89: 'reward_xp_boost_30_coins',
        90: 'reward_coin_boost_30_coins',
        93: 'reward_coin_boost_30_coins',
        94: 'reward_streak_shield_40_coins',
        96: 'reward_streak_shield_40_coins',
        97: 'reward_streak_recover_50_coins',
        99: 'reward_streak_recover_50_coins',
      };

      for (final entry in expectations.entries) {
        final reward = resolver.resolveByRoll(
          catalog: MysteryBoxRewardCatalog.defaultRewards,
          roll: entry.key,
        );
        expect(reward.id, entry.value, reason: 'roll ${entry.key}');
      }
    });

    test('can resolve through a controlled RandomSource', () {
      const resolver = MysteryBoxRewardResolver();
      final reward = resolver.resolve(
        catalog: MysteryBoxRewardCatalog.defaultRewards,
        randomSource: FixedRandomSource(<int>[99]),
      );

      expect(reward.id, 'reward_streak_recover_50_coins');
    });
  });
}
