import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

extension ShopL10nX on AppLocalizations {
  String shopUtilityTitle(String id, {String? fallback}) {
    switch (id) {
      case 'utility_xp_boost_1d':
        return shopXpBoostTitle;
      case 'utility_coin_boost_1d':
        return shopCoinBoostTitle;
      case 'utility_streak_recover_1':
        return shopStreakRecoverTitle;
      case 'utility_streak_shield_1':
        return shopStreakShieldTitle;
      case 'utility_mystery_box_basic':
        return shopMysteryBoxTitle;
      default:
        return fallback ?? id;
    }
  }

  String shopUtilityTitleForItem(ShopItem item) {
    return shopUtilityTitle(item.id, fallback: item.title);
  }

  String shopUtilityDescription(String id, {String? fallback}) {
    switch (id) {
      case 'utility_xp_boost_1d':
        return shopXpBoostDescription;
      case 'utility_coin_boost_1d':
        return shopCoinBoostDescription;
      case 'utility_streak_recover_1':
        return shopStreakRecoverDescription;
      case 'utility_streak_shield_1':
        return shopStreakShieldDescription;
      case 'utility_mystery_box_basic':
        return shopMysteryBoxDescription;
      default:
        return fallback ?? '';
    }
  }

  String shopUtilityDescriptionForItem(ShopItem item) {
    return shopUtilityDescription(item.id, fallback: item.description);
  }

  String shopUtilityCategoryLabel(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
        return shopCategoryBoosts;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return shopCategoryStreaks;
      case ShopItemType.mysteryBox:
        return shopCategoryBoxes;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return shopCategoryUtility;
    }
  }

  String shopUtilityEffectLabel(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
        return shopXpBoostEffect;
      case ShopItemType.coinBoost:
        return shopCoinBoostEffect;
      case ShopItemType.streakRecover:
        return shopStreakRecoverEffect;
      case ShopItemType.streakShield:
        return shopStreakShieldEffect;
      case ShopItemType.mysteryBox:
        return shopMysteryBoxEffect;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return shopCustomizationTitle;
    }
  }

  String shopUtilityCategoryLabelForItem(ShopItem item) {
    switch (item.type) {
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
        return shopCategoryBoosts;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return shopCategoryStreaks;
      case ShopItemType.mysteryBox:
        return shopCategoryBoxes;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return shopCategoryUtility;
    }
  }

  String shopUtilityDurationLabel(ShopItem item) {
    final Object? rawDuration = item.metadata['durationHours'];
    if (rawDuration is num && rawDuration > 0) {
      final int durationHours = rawDuration.toInt();
      return shopUtilityDurationHours(durationHours);
    }

    final Object? rawCharges = item.metadata['charges'];
    if (rawCharges is num && rawCharges > 0) {
      final int charges = rawCharges.toInt();
      return shopUtilityCharges(charges);
    }

    if (item.type == ShopItemType.mysteryBox) {
      return shopActionOpen;
    }

    return shopActionActive;
  }

  String shopUtilityEffectLabelForItem(ShopItem item) {
    switch (item.type) {
      case ShopItemType.xpBoost:
        return shopXpBoostEffect;
      case ShopItemType.coinBoost:
        return shopCoinBoostEffect;
      case ShopItemType.streakRecover:
        return shopStreakRecoverEffect;
      case ShopItemType.streakShield:
        return shopStreakShieldEffect;
      case ShopItemType.mysteryBox:
        return shopMysteryBoxEffect;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return shopCustomizationTitle;
    }
  }

  String shopCollectionTitle(String id, {String? fallback}) {
    switch (id) {
      case 'minimal':
        return shopCollectionMinimalTitle;
      case 'gradient':
        return shopCollectionGradientTitle;
      case 'landscape':
        return shopCollectionLandscapeTitle;
      default:
        return fallback ?? id;
    }
  }

  String shopCollectionDescription(String id, {String? fallback}) {
    switch (id) {
      case 'minimal':
        return shopCollectionMinimalDescription;
      case 'gradient':
        return shopCollectionGradientDescription;
      case 'landscape':
        return shopCollectionLandscapeDescription;
      default:
        return fallback ?? '';
    }
  }

  String shopAssetCategoryLabel(ShopAssetCategory category) {
    switch (category) {
      case ShopAssetCategory.wallpaper:
        return shopCategoryWallpaper;
      case ShopAssetCategory.habitCard:
        return shopCategoryHabitCard;
      case ShopAssetCategory.userCard:
        return shopCategoryUserCard;
    }
  }

  String shopItemTypeLabel(ShopItemType type) {
    switch (type) {
      case ShopItemType.background:
        return shopCategoryWallpaper;
      case ShopItemType.habitCard:
        return shopCategoryHabitCard;
      case ShopItemType.userCard:
        return shopCategoryUserCard;
      case ShopItemType.xpBoost:
        return shopXpBoostTitle;
      case ShopItemType.coinBoost:
        return shopCoinBoostTitle;
      case ShopItemType.streakRecover:
        return shopStreakRecoverTitle;
      case ShopItemType.streakShield:
        return shopStreakShieldTitle;
      case ShopItemType.mysteryBox:
        return shopMysteryBoxTitle;
    }
  }

  String shopRarityLabelByShopItem(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.common:
        return shopRarityCommon;
      case ShopItemRarity.uncommon:
        return shopRarityUncommon;
      case ShopItemRarity.rare:
        return shopRarityRare;
      case ShopItemRarity.epic:
        return shopRarityEpic;
      case ShopItemRarity.legendary:
        return shopRarityLegendary;
    }
  }

  String shopAssetRarityLabel(ShopAssetRarity rarity) {
    switch (rarity) {
      case ShopAssetRarity.common:
        return shopRarityCommon;
      case ShopAssetRarity.rare:
        return shopRarityRare;
      case ShopAssetRarity.epic:
        return shopRarityEpic;
      case ShopAssetRarity.legendary:
        return shopRarityLegendary;
    }
  }

  String shopFilterLabel(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
        return shopFilterBoosts;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return shopFilterStreak;
      case ShopItemType.mysteryBox:
        return shopFilterBoxes;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return shopFilterAll;
    }
  }

  String shopBackpackActiveEffectsProgressText(
    int remainingUses,
    int totalUses,
  ) {
    return shopBackpackActiveEffectsProgressLabel(remainingUses, totalUses);
  }
}
