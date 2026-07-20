enum ShopItemCategory {
  cosmetic,
  utility,
}

extension ShopItemCategoryX on ShopItemCategory {
  String get key {
    switch (this) {
      case ShopItemCategory.cosmetic:
        return 'cosmetic';
      case ShopItemCategory.utility:
        return 'utility';
    }
  }

  static ShopItemCategory fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'utility':
        return ShopItemCategory.utility;
      case 'cosmetic':
      default:
        return ShopItemCategory.cosmetic;
    }
  }
}

enum ShopItemType {
  background,
  habitCard,
  userCard,
  xpBoost,
  coinBoost,
  streakRecover,
  streakShield,
  mysteryBox,
}

extension ShopItemTypeX on ShopItemType {
  String get key {
    switch (this) {
      case ShopItemType.background:
        return 'background';
      case ShopItemType.habitCard:
        return 'habitCard';
      case ShopItemType.userCard:
        return 'userCard';
      case ShopItemType.xpBoost:
        return 'xpBoost';
      case ShopItemType.coinBoost:
        return 'coinBoost';
      case ShopItemType.streakRecover:
        return 'streakRecover';
      case ShopItemType.streakShield:
        return 'streakShield';
      case ShopItemType.mysteryBox:
        return 'mysteryBox';
    }
  }

  static ShopItemType fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'habitCard':
        return ShopItemType.habitCard;
      case 'userCard':
        return ShopItemType.userCard;
      case 'xpBoost':
        return ShopItemType.xpBoost;
      case 'coinBoost':
        return ShopItemType.coinBoost;
      case 'streakRecover':
        return ShopItemType.streakRecover;
      case 'streakShield':
        return ShopItemType.streakShield;
      case 'mysteryBox':
        return ShopItemType.mysteryBox;
      case 'background':
      default:
        return ShopItemType.background;
    }
  }
}

enum ShopItemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

extension ShopItemRarityX on ShopItemRarity {
  String get key {
    switch (this) {
      case ShopItemRarity.common:
        return 'common';
      case ShopItemRarity.uncommon:
        return 'uncommon';
      case ShopItemRarity.rare:
        return 'rare';
      case ShopItemRarity.epic:
        return 'epic';
      case ShopItemRarity.legendary:
        return 'legendary';
    }
  }

  static ShopItemRarity fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'uncommon':
        return ShopItemRarity.uncommon;
      case 'rare':
        return ShopItemRarity.rare;
      case 'epic':
        return ShopItemRarity.epic;
      case 'legendary':
        return ShopItemRarity.legendary;
      case 'common':
      default:
        return ShopItemRarity.common;
    }
  }
}

enum CosmeticSlot {
  background,
  habitCard,
  userCard,
}

extension CosmeticSlotX on CosmeticSlot {
  String get key {
    switch (this) {
      case CosmeticSlot.background:
        return 'background';
      case CosmeticSlot.habitCard:
        return 'habitCard';
      case CosmeticSlot.userCard:
        return 'userCard';
    }
  }

  static CosmeticSlot fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'habitCard':
        return CosmeticSlot.habitCard;
      case 'userCard':
        return CosmeticSlot.userCard;
      case 'background':
      default:
        return CosmeticSlot.background;
    }
  }

  String get remoteDbKey {
    switch (this) {
      case CosmeticSlot.background:
        return 'screen_background';
      case CosmeticSlot.habitCard:
        return 'habit_card_background';
      case CosmeticSlot.userCard:
        return 'user_card_background';
    }
  }
}

enum ConsumableType {
  xpBoost,
  coinBoost,
  streakRecover,
  streakShield,
  mysteryBox,
}

extension ConsumableTypeX on ConsumableType {
  String get key {
    switch (this) {
      case ConsumableType.xpBoost:
        return 'xpBoost';
      case ConsumableType.coinBoost:
        return 'coinBoost';
      case ConsumableType.streakRecover:
        return 'streakRecover';
      case ConsumableType.streakShield:
        return 'streakShield';
      case ConsumableType.mysteryBox:
        return 'mysteryBox';
    }
  }

  static ConsumableType fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'coinBoost':
        return ConsumableType.coinBoost;
      case 'streakRecover':
        return ConsumableType.streakRecover;
      case 'streakShield':
        return ConsumableType.streakShield;
      case 'mysteryBox':
        return ConsumableType.mysteryBox;
      case 'xpBoost':
      default:
        return ConsumableType.xpBoost;
    }
  }
}
