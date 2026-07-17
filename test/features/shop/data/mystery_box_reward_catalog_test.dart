import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/mystery_box_reward_catalog.dart';
import 'package:rutio/features/shop/domain/mystery_box_reward_resolver.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_definition.dart';

void main() {
  group('MysteryBoxRewardCatalog', () {
    test('contains exactly 8 rewards that sum to 100', () {
      expect(MysteryBoxRewardCatalog.defaultRewards, hasLength(8));

      final totalWeight = MysteryBoxRewardCatalog.defaultRewards
          .fold<int>(0, (sum, reward) => sum + reward.weight);

      expect(totalWeight, 100);
    });

    test('contains unique ids and valid values', () {
      final ids = MysteryBoxRewardCatalog.defaultRewards
          .map((reward) => reward.id)
          .toList(growable: false);
      expect(ids.toSet().length, ids.length);

      for (final reward in MysteryBoxRewardCatalog.defaultRewards) {
        expect(reward.weight, greaterThan(0), reason: reward.id);
        expect(reward.coins, greaterThanOrEqualTo(0), reason: reward.id);
        expect(reward.xp, greaterThanOrEqualTo(0), reason: reward.id);
        expect(reward.isEmpty, isFalse, reason: reward.id);
      }
    });

    test('validation passes for the production catalog', () {
      expect(MysteryBoxRewardCatalog.validateConfiguration(), isEmpty);
    });

    test('rejects catalogs that sum to 99 or 101', () {
      final resolver = const MysteryBoxRewardResolver();
      final baseRewards = MysteryBoxRewardCatalog.defaultRewards;

      final tooSmall = <MysteryBoxRewardDefinition>[
        ...baseRewards.take(baseRewards.length - 1),
        baseRewards.last.copyWith(weight: 2),
      ];
      final tooLarge = <MysteryBoxRewardDefinition>[
        ...baseRewards.take(baseRewards.length - 1),
        baseRewards.last.copyWith(weight: 4),
      ];

      expect(resolver.validateCatalog(tooSmall), isNotEmpty);
      expect(resolver.validateCatalog(tooLarge), isNotEmpty);
    });
  });
}
