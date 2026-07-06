import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';

class ShopAssetsCatalog {
  static const int commonAssetPrice = 120;
  static const int rareAssetPrice = 250;
  static const int epicAssetPrice = 550;
  static const int legendaryAssetPrice = 1200;

  static const int commonBundlePrice = 300;
  static const int rareBundlePrice = 650;
  static const int epicBundlePrice = 1400;
  static const int legendaryBundlePrice = 3000;

  static final List<ShopAsset> allAssets = <ShopAsset>[
    _asset(
      id: 'wallpaper_warm_beige',
      familyId: 'warm_beige',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Beige calido',
      nameEn: 'Warm Beige Wallpaper',
      sortOrder: 0,
    ),
    _asset(
      id: 'habit_card_warm_beige',
      familyId: 'warm_beige',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Beige calido',
      nameEn: 'Warm Beige Habit Card',
      sortOrder: 1,
    ),
    _asset(
      id: 'user_card_warm_beige',
      familyId: 'warm_beige',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Tarjeta Beige calido',
      nameEn: 'Warm Beige User Card',
      sortOrder: 2,
    ),
    _asset(
      id: 'wallpaper_soft_camel',
      familyId: 'soft_camel',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Camel suave',
      nameEn: 'Soft Camel Wallpaper',
      sortOrder: 3,
    ),
    _asset(
      id: 'habit_card_soft_camel',
      familyId: 'soft_camel',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Camel suave',
      nameEn: 'Soft Camel Habit Card',
      sortOrder: 4,
    ),
    _asset(
      id: 'user_card_soft_camel',
      familyId: 'soft_camel',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Tarjeta Camel suave',
      nameEn: 'Soft Camel User Card',
      sortOrder: 5,
    ),
    _asset(
      id: 'wallpaper_sand_plain',
      familyId: 'sand_plain',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Arena lisa',
      nameEn: 'Plain Sand Wallpaper',
      sortOrder: 6,
    ),
    _asset(
      id: 'habit_card_sand_plain',
      familyId: 'sand_plain',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Arena lisa',
      nameEn: 'Plain Sand Habit Card',
      sortOrder: 7,
    ),
    _asset(
      id: 'user_card_sand_plain',
      familyId: 'sand_plain',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Tarjeta Arena lisa',
      nameEn: 'Plain Sand User Card',
      sortOrder: 8,
    ),
    _asset(
      id: 'wallpaper_cream_light',
      familyId: 'cream_light',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Crema claro',
      nameEn: 'Light Cream Wallpaper',
      sortOrder: 9,
    ),
    _asset(
      id: 'habit_card_cream_light',
      familyId: 'cream_light',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Crema claro',
      nameEn: 'Light Cream Habit Card',
      sortOrder: 10,
    ),
    _asset(
      id: 'user_card_cream_light',
      familyId: 'cream_light',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Tarjeta Crema claro',
      nameEn: 'Light Cream User Card',
      sortOrder: 11,
    ),
    _asset(
      id: 'wallpaper_calm_sand',
      familyId: 'calm_sand',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Fondo Arena calma',
      nameEn: 'Calm Sand Wallpaper',
      sortOrder: 12,
    ),
    _asset(
      id: 'habit_card_calm_sand',
      familyId: 'calm_sand',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Arena calma',
      nameEn: 'Calm Sand Habit Card',
      sortOrder: 13,
    ),
    _asset(
      id: 'user_card_calm_sand',
      familyId: 'calm_sand',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Tarjeta Arena calma',
      nameEn: 'Calm Sand User Card',
      sortOrder: 14,
    ),
    _asset(
      id: 'wallpaper_soft_linen',
      familyId: 'soft_linen',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Fondo Lino suave',
      nameEn: 'Soft Linen Wallpaper',
      sortOrder: 15,
    ),
    _asset(
      id: 'habit_card_soft_linen',
      familyId: 'soft_linen',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Lino suave',
      nameEn: 'Soft Linen Habit Card',
      sortOrder: 16,
    ),
    _asset(
      id: 'user_card_soft_linen',
      familyId: 'soft_linen',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Tarjeta Lino suave',
      nameEn: 'Soft Linen User Card',
      sortOrder: 17,
    ),
    _asset(
      id: 'wallpaper_paper_dawn',
      familyId: 'paper_dawn',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Fondo Amanecer de papel',
      nameEn: 'Paper Dawn Wallpaper',
      sortOrder: 18,
    ),
    _asset(
      id: 'habit_card_paper_dawn',
      familyId: 'paper_dawn',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Amanecer de papel',
      nameEn: 'Paper Dawn Habit Card',
      sortOrder: 19,
    ),
    _asset(
      id: 'user_card_paper_dawn',
      familyId: 'paper_dawn',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Tarjeta Amanecer de papel',
      nameEn: 'Paper Dawn User Card',
      sortOrder: 20,
    ),
    _asset(
      id: 'wallpaper_lavender_mist',
      familyId: 'lavender_mist',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Niebla lavanda',
      nameEn: 'Lavender Mist Wallpaper',
      sortOrder: 21,
    ),
    _asset(
      id: 'habit_card_lavender_mist',
      familyId: 'lavender_mist',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Niebla lavanda',
      nameEn: 'Lavender Mist Habit Card',
      sortOrder: 22,
    ),
    _asset(
      id: 'user_card_lavender_mist',
      familyId: 'lavender_mist',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Tarjeta Niebla lavanda',
      nameEn: 'Lavender Mist User Card',
      sortOrder: 23,
    ),
    _asset(
      id: 'wallpaper_dune_layers',
      familyId: 'dune_layers',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Capas de duna',
      nameEn: 'Dune Layers Wallpaper',
      sortOrder: 24,
    ),
    _asset(
      id: 'habit_card_dune_layers',
      familyId: 'dune_layers',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Capas de duna',
      nameEn: 'Dune Layers Habit Card',
      sortOrder: 25,
    ),
    _asset(
      id: 'user_card_dune_layers',
      familyId: 'dune_layers',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Tarjeta Capas de duna',
      nameEn: 'Dune Layers User Card',
      sortOrder: 26,
    ),
    _asset(
      id: 'wallpaper_golden_dawn',
      familyId: 'golden_dawn',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.legendary,
      nameEs: 'Fondo Amanecer dorado',
      nameEn: 'Golden Dawn Wallpaper',
      sortOrder: 27,
    ),
    _asset(
      id: 'habit_card_golden_dawn',
      familyId: 'golden_dawn',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.legendary,
      nameEs: 'Card Amanecer dorado',
      nameEn: 'Golden Dawn Habit Card',
      sortOrder: 28,
    ),
    _asset(
      id: 'user_card_golden_dawn',
      familyId: 'golden_dawn',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.legendary,
      nameEs: 'Tarjeta Amanecer dorado',
      nameEn: 'Golden Dawn User Card',
      sortOrder: 29,
    ),
  ];

  static final List<ShopBundle> allBundles = <ShopBundle>[
    _bundle(
      id: 'bundle_warm_beige',
      familyId: 'warm_beige',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Beige calido',
      nameEn: 'Warm Beige Bundle',
      sortOrder: 0,
    ),
    _bundle(
      id: 'bundle_soft_camel',
      familyId: 'soft_camel',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Camel suave',
      nameEn: 'Soft Camel Bundle',
      sortOrder: 1,
    ),
    _bundle(
      id: 'bundle_sand_plain',
      familyId: 'sand_plain',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Arena lisa',
      nameEn: 'Plain Sand Bundle',
      sortOrder: 2,
    ),
    _bundle(
      id: 'bundle_cream_light',
      familyId: 'cream_light',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Crema claro',
      nameEn: 'Light Cream Bundle',
      sortOrder: 3,
    ),
    _bundle(
      id: 'bundle_calm_sand',
      familyId: 'calm_sand',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Arena calma',
      nameEn: 'Calm Sand Bundle',
      sortOrder: 4,
    ),
    _bundle(
      id: 'bundle_soft_linen',
      familyId: 'soft_linen',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Lino suave',
      nameEn: 'Soft Linen Bundle',
      sortOrder: 5,
    ),
    _bundle(
      id: 'bundle_paper_dawn',
      familyId: 'paper_dawn',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Amanecer de papel',
      nameEn: 'Paper Dawn Bundle',
      sortOrder: 6,
    ),
    _bundle(
      id: 'bundle_lavender_mist',
      familyId: 'lavender_mist',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Niebla lavanda',
      nameEn: 'Lavender Mist Bundle',
      sortOrder: 7,
    ),
    _bundle(
      id: 'bundle_dune_layers',
      familyId: 'dune_layers',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Capas de duna',
      nameEn: 'Dune Layers Bundle',
      sortOrder: 8,
    ),
    _bundle(
      id: 'bundle_golden_dawn',
      familyId: 'golden_dawn',
      rarity: ShopAssetRarity.legendary,
      nameEs: 'Pack Amanecer dorado',
      nameEn: 'Golden Dawn Bundle',
      sortOrder: 9,
    ),
  ];

  static ShopAsset? getAssetById(String assetId) {
    for (final asset in allAssets) {
      if (asset.id == assetId) {
        return asset;
      }
    }
    return null;
  }

  static ShopBundle? getBundleById(String bundleId) {
    for (final bundle in allBundles) {
      if (bundle.id == bundleId) {
        return bundle;
      }
    }
    return null;
  }

  static List<ShopAsset> assetsByCategory(ShopAssetCategory category) {
    return allAssets
        .where((ShopAsset asset) => asset.category == category)
        .toList(growable: false);
  }

  static List<ShopAsset> assetsByFamily(String familyId) {
    return allAssets
        .where((ShopAsset asset) => asset.familyId == familyId)
        .toList(growable: false);
  }

  static List<ShopBundle> bundlesByFamily(String familyId) {
    return allBundles
        .where((ShopBundle bundle) => bundle.familyId == familyId)
        .toList(growable: false);
  }

  static List<ShopAsset> assetsByRarity(ShopAssetRarity rarity) {
    return allAssets
        .where((ShopAsset asset) => asset.rarity == rarity)
        .toList(growable: false);
  }

  static ShopAsset _asset({
    required String id,
    required String familyId,
    required ShopAssetCategory category,
    required ShopAssetRarity rarity,
    required String nameEs,
    required String nameEn,
    required int sortOrder,
  }) {
    final assetPath = _assetPathFor(
      assetId: id,
      rarity: rarity,
      category: category,
    );

    return ShopAsset(
      id: id,
      familyId: familyId,
      category: category,
      rarity: rarity,
      nameEs: nameEs,
      nameEn: nameEn,
      priceAmber: _assetPriceFor(rarity),
      assetPath: assetPath,
      previewAssetPath: assetPath,
      isPurchasable: true,
      sortOrder: sortOrder,
    );
  }

  static ShopBundle _bundle({
    required String id,
    required String familyId,
    required ShopAssetRarity rarity,
    required String nameEs,
    required String nameEn,
    required int sortOrder,
  }) {
    return ShopBundle(
      id: id,
      familyId: familyId,
      rarity: rarity,
      nameEs: nameEs,
      nameEn: nameEn,
      priceAmber: _bundlePriceFor(rarity),
      assetIds: <String>[
        'wallpaper_$familyId',
        'habit_card_$familyId',
        'user_card_$familyId',
      ],
      isPurchasable: true,
      sortOrder: sortOrder,
    );
  }

  static int _assetPriceFor(ShopAssetRarity rarity) {
    switch (rarity) {
      case ShopAssetRarity.common:
        return commonAssetPrice;
      case ShopAssetRarity.rare:
        return rareAssetPrice;
      case ShopAssetRarity.epic:
        return epicAssetPrice;
      case ShopAssetRarity.legendary:
        return legendaryAssetPrice;
    }
  }

  static int _bundlePriceFor(ShopAssetRarity rarity) {
    switch (rarity) {
      case ShopAssetRarity.common:
        return commonBundlePrice;
      case ShopAssetRarity.rare:
        return rareBundlePrice;
      case ShopAssetRarity.epic:
        return epicBundlePrice;
      case ShopAssetRarity.legendary:
        return legendaryBundlePrice;
    }
  }

  static String _assetPathFor({
    required String assetId,
    required ShopAssetRarity rarity,
    required ShopAssetCategory category,
  }) {
    final folder = switch (category) {
      ShopAssetCategory.wallpaper => 'wallpapers',
      ShopAssetCategory.habitCard => 'habit_cards',
      ShopAssetCategory.userCard => 'user_cards',
    };

    return 'assets/shop/$folder/${rarity.key}/$assetId.webp';
  }
}
