import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/mystery_box_reward_resolver.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_definition.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

class MysteryBoxRewardCatalog {
  static const String mysteryBoxUtilityId = 'utility_mystery_box_basic';

  static final List<MysteryBoxRewardDefinition> defaultRewards =
      <MysteryBoxRewardDefinition>[
    MysteryBoxRewardDefinition(
      id: 'reward_80_coins_40_xp',
      weight: 40,
      coins: 80,
      xp: 40,
      utilityRewards: <String, int>{},
    ),
    MysteryBoxRewardDefinition(
      id: 'reward_100_coins_50_xp',
      weight: 25,
      coins: 100,
      xp: 50,
      utilityRewards: <String, int>{},
    ),
    MysteryBoxRewardDefinition(
      id: 'reward_125_coins',
      weight: 15,
      coins: 125,
      xp: 0,
      utilityRewards: <String, int>{},
    ),
    MysteryBoxRewardDefinition(
      id: 'reward_150_coins',
      weight: 5,
      coins: 150,
      xp: 0,
      utilityRewards: <String, int>{},
    ),
    MysteryBoxRewardDefinition(
      id: 'reward_xp_boost_30_coins',
      weight: 5,
      coins: 30,
      xp: 0,
      utilityRewards: <String, int>{
        'utility_xp_boost_1d': 1,
      },
    ),
    MysteryBoxRewardDefinition(
      id: 'reward_coin_boost_30_coins',
      weight: 4,
      coins: 30,
      xp: 0,
      utilityRewards: <String, int>{
        'utility_coin_boost_1d': 1,
      },
    ),
    MysteryBoxRewardDefinition(
      id: 'reward_streak_shield_40_coins',
      weight: 3,
      coins: 40,
      xp: 0,
      utilityRewards: <String, int>{
        'utility_streak_shield_1': 1,
      },
    ),
    MysteryBoxRewardDefinition(
      id: 'reward_streak_recover_50_coins',
      weight: 3,
      coins: 50,
      xp: 0,
      utilityRewards: <String, int>{
        'utility_streak_recover_1': 1,
      },
    ),
  ];

  static List<String> validateConfiguration() {
    return const MysteryBoxRewardResolver().validateCatalog(
      defaultRewards,
      validUtilityIds: ShopCatalog.allItems
          .where((item) => item.category == ShopItemCategory.utility)
          .map((item) => item.id)
          .toSet(),
    );
  }

  static void debugValidateConfiguration() {
    assert(() {
      final errors = validateConfiguration();
      if (errors.isNotEmpty) {
        throw StateError(
          'Invalid mystery box reward catalog: ${errors.join('; ')}',
        );
      }
      return true;
    }());
  }
}
