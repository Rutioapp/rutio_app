enum ShopAssetCategory {
  wallpaper,
  habitCard,
  userCard,
}

extension ShopAssetCategoryX on ShopAssetCategory {
  String get key {
    switch (this) {
      case ShopAssetCategory.wallpaper:
        return 'wallpaper';
      case ShopAssetCategory.habitCard:
        return 'habit_card';
      case ShopAssetCategory.userCard:
        return 'user_card';
    }
  }

  static ShopAssetCategory fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'habit_card':
      case 'habitCard':
        return ShopAssetCategory.habitCard;
      case 'user_card':
      case 'userCard':
        return ShopAssetCategory.userCard;
      case 'wallpaper':
      default:
        return ShopAssetCategory.wallpaper;
    }
  }
}

enum ShopAssetRarity {
  common,
  rare,
  epic,
  legendary,
}

extension ShopAssetRarityX on ShopAssetRarity {
  String get key {
    switch (this) {
      case ShopAssetRarity.common:
        return 'common';
      case ShopAssetRarity.rare:
        return 'rare';
      case ShopAssetRarity.epic:
        return 'epic';
      case ShopAssetRarity.legendary:
        return 'legendary';
    }
  }

  static ShopAssetRarity fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'rare':
        return ShopAssetRarity.rare;
      case 'epic':
        return ShopAssetRarity.epic;
      case 'legendary':
        return ShopAssetRarity.legendary;
      case 'common':
      default:
        return ShopAssetRarity.common;
    }
  }
}
