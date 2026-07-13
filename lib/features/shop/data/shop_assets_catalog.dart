import 'package:flutter/painting.dart';

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
      id: 'wallpaper_mist_blue',
      familyId: 'mist_blue',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Azul niebla',
      nameEn: 'Mist Blue Wallpaper',
      sortOrder: 0,
    ),
    _asset(
      id: 'wallpaper_rutio_beige',
      familyId: 'rutio_beige',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Beige Rutio',
      nameEn: 'Rutio Beige Wallpaper',
      sortOrder: 1,
    ),
    _asset(
      id: 'wallpaper_off_white',
      familyId: 'off_white',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Blanco roto',
      nameEn: 'Off White Wallpaper',
      sortOrder: 2,
    ),
    _asset(
      id: 'wallpaper_mellow_camel',
      familyId: 'mellow_camel',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Camel suave',
      nameEn: 'Mellow Camel Wallpaper',
      sortOrder: 3,
    ),
    _asset(
      id: 'wallpaper_stone_gray',
      familyId: 'stone_gray',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Gris piedra',
      nameEn: 'Stone Gray Wallpaper',
      sortOrder: 4,
    ),
    _asset(
      id: 'wallpaper_dusty_lilac',
      familyId: 'dusty_lilac',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Lila empolvado',
      nameEn: 'Dusty Lilac Wallpaper',
      sortOrder: 5,
    ),
    _asset(
      id: 'wallpaper_clay_rose',
      familyId: 'clay_rose',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Rosa arcilla',
      nameEn: 'Clay Rose Wallpaper',
      sortOrder: 6,
    ),
    _asset(
      id: 'wallpaper_soft_terracotta',
      familyId: 'soft_terracotta',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Terracota suave',
      nameEn: 'Soft Terracotta Wallpaper',
      sortOrder: 7,
    ),
    _asset(
      id: 'wallpaper_soft_sage',
      familyId: 'soft_sage',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Verde salvia',
      nameEn: 'Soft Sage Wallpaper',
      sortOrder: 8,
    ),
    _asset(
      id: 'wallpaper_cream_yellow',
      familyId: 'cream_yellow',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.common,
      nameEs: 'Fondo Amarillo crema',
      nameEn: 'Cream Yellow Wallpaper',
      sortOrder: 9,
    ),
    _asset(
      id: 'habit_card_warm_beige',
      familyId: 'warm_beige',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Beige Rutio',
      nameEn: 'Rutio Beige Habit Card',
      sortOrder: 10,
    ),
    _asset(
      id: 'user_card_warm_beige',
      familyId: 'warm_beige',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Tarjeta Beige calido',
      nameEn: 'Warm Beige User Card',
      sortOrder: 11,
    ),
    _asset(
      id: 'habit_card_soft_camel',
      familyId: 'soft_camel',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Camel suave',
      nameEn: 'Soft Camel Habit Card',
      sortOrder: 12,
    ),
    _asset(
      id: 'user_card_soft_camel',
      familyId: 'soft_camel',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Tarjeta Camel suave',
      nameEn: 'Soft Camel User Card',
      sortOrder: 13,
    ),
    _asset(
      id: 'habit_card_sand_plain',
      familyId: 'sand_plain',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Blanco roto',
      nameEn: 'Off White Habit Card',
      sortOrder: 14,
    ),
    _asset(
      id: 'user_card_sand_plain',
      familyId: 'sand_plain',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Tarjeta Arena lisa',
      nameEn: 'Plain Sand User Card',
      sortOrder: 15,
    ),
    _asset(
      id: 'habit_card_cream_light',
      familyId: 'cream_light',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Amarillo crema',
      nameEn: 'Cream Yellow Habit Card',
      sortOrder: 16,
    ),
    _asset(
      id: 'user_card_cream_light',
      familyId: 'cream_light',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Tarjeta Crema claro',
      nameEn: 'Light Cream User Card',
      sortOrder: 17,
    ),
    _asset(
      id: 'wallpaper_jungle_sunrise',
      familyId: 'jungle_sunrise',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Fondo Amanecer en la selva',
      nameEn: 'Jungle Sunrise Wallpaper',
      sortOrder: 18,
    ),
    _asset(
      id: 'habit_card_calm_sand',
      familyId: 'calm_sand',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Gris piedra',
      nameEn: 'Stone Gray Habit Card',
      sortOrder: 19,
    ),
    _asset(
      id: 'user_card_calm_sand',
      familyId: 'calm_sand',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Tarjeta Arena calma',
      nameEn: 'Calm Sand User Card',
      sortOrder: 20,
    ),
    _asset(
      id: 'wallpaper_carnival_pastel',
      familyId: 'carnival_pastel',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Fondo Carnaval pastel',
      nameEn: 'Carnival Pastel Wallpaper',
      sortOrder: 21,
    ),
    _asset(
      id: 'habit_card_soft_linen',
      familyId: 'soft_linen',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Terracota suave',
      nameEn: 'Soft Terracotta Habit Card',
      sortOrder: 22,
    ),
    _asset(
      id: 'user_card_soft_linen',
      familyId: 'soft_linen',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Tarjeta Lino suave',
      nameEn: 'Soft Linen User Card',
      sortOrder: 23,
    ),
    _asset(
      id: 'wallpaper_strawberry_pastel',
      familyId: 'strawberry_pastel',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Fondo Pastel de fresa',
      nameEn: 'Strawberry Pastel Wallpaper',
      sortOrder: 24,
    ),
    _asset(
      id: 'habit_card_paper_dawn',
      familyId: 'paper_dawn',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Rosa arcilla',
      nameEn: 'Clay Rose Habit Card',
      sortOrder: 25,
    ),
    _asset(
      id: 'habit_card_violet_flame',
      familyId: 'violet_flame',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Llama violeta',
      nameEn: 'Violet Flame Habit Card',
      imageAlignmentX: 0.65,
      overlayColorValue: 0xCCFFFFFF,
      overlayOpacity: 0.18,
      sortOrder: 26,
    ),
    _asset(
      id: 'user_card_paper_dawn',
      familyId: 'paper_dawn',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Tarjeta Amanecer de papel',
      nameEn: 'Paper Dawn User Card',
      sortOrder: 27,
    ),
    _asset(
      id: 'wallpaper_starry_sky',
      familyId: 'starry_sky',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Cielo estrellado',
      nameEn: 'Starry Sky Wallpaper',
      sortOrder: 28,
    ),
    _asset(
      id: 'habit_card_lavender_mist',
      familyId: 'lavender_mist',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Lila empolvado',
      nameEn: 'Dusty Lilac Habit Card',
      sortOrder: 29,
    ),
    _asset(
      id: 'user_card_lavender_mist',
      familyId: 'lavender_mist',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Tarjeta Niebla lavanda',
      nameEn: 'Lavender Mist User Card',
      sortOrder: 30,
    ),
    _asset(
      id: 'wallpaper_mint_abstract',
      familyId: 'mint_abstract',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Menta abstracta',
      nameEn: 'Mint Abstract Wallpaper',
      sortOrder: 31,
    ),
    _asset(
      id: 'habit_card_dune_layers',
      familyId: 'dune_layers',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Azul niebla',
      nameEn: 'Mist Blue Habit Card',
      sortOrder: 32,
    ),
    _asset(
      id: 'user_card_dune_layers',
      familyId: 'dune_layers',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Tarjeta Capas de duna',
      nameEn: 'Dune Layers User Card',
      sortOrder: 33,
    ),
    _asset(
      id: 'wallpaper_zebra_minimal',
      familyId: 'zebra_minimal',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Zebra minimal',
      nameEn: 'Minimal Zebra Wallpaper',
      sortOrder: 34,
    ),
    _asset(
      id: 'wallpaper_wild_stripes',
      familyId: 'wild_stripes',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Rayas salvajes',
      nameEn: 'Wild Stripes Wallpaper',
      sortOrder: 35,
    ),
    _asset(
      id: 'wallpaper_cow_spots',
      familyId: 'cow_spots',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Vaca minimal',
      nameEn: 'Minimal Cow Wallpaper',
      sortOrder: 36,
    ),
    _asset(
      id: 'wallpaper_city_sunrise',
      familyId: 'city_sunrise',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Amanecer en la ciudad',
      nameEn: 'City Sunrise Wallpaper',
      sortOrder: 37,
    ),
    _asset(
      id: 'wallpaper_ocean_depth',
      familyId: 'ocean_depth',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Oceano profundo',
      nameEn: 'Ocean Depth Wallpaper',
      sortOrder: 38,
    ),
    _asset(
      id: 'wallpaper_golden_dawn',
      familyId: 'golden_dawn',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.legendary,
      nameEs: 'Fondo Amanecer dorado',
      nameEn: 'Golden Dawn Wallpaper',
      sortOrder: 39,
    ),
    _asset(
      id: 'habit_card_golden_dawn',
      familyId: 'golden_dawn',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.legendary,
      nameEs: 'Card Verde savia',
      nameEn: 'Soft Sage Habit Card',
      sortOrder: 40,
    ),
    _asset(
      id: 'user_card_golden_dawn',
      familyId: 'golden_dawn',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.legendary,
      nameEs: 'Tarjeta Amanecer dorado',
      nameEn: 'Golden Dawn User Card',
      sortOrder: 41,
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
      assetIds: const <String>[
        'habit_card_warm_beige',
        'user_card_warm_beige',
      ],
    ),
    _bundle(
      id: 'bundle_soft_camel',
      familyId: 'soft_camel',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Camel suave',
      nameEn: 'Soft Camel Bundle',
      sortOrder: 1,
      assetIds: const <String>[
        'habit_card_soft_camel',
        'user_card_soft_camel',
      ],
    ),
    _bundle(
      id: 'bundle_sand_plain',
      familyId: 'sand_plain',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Arena lisa',
      nameEn: 'Plain Sand Bundle',
      sortOrder: 2,
      assetIds: const <String>[
        'habit_card_sand_plain',
        'user_card_sand_plain',
      ],
    ),
    _bundle(
      id: 'bundle_cream_light',
      familyId: 'cream_light',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Crema claro',
      nameEn: 'Light Cream Bundle',
      sortOrder: 3,
      assetIds: const <String>[
        'habit_card_cream_light',
        'user_card_cream_light',
      ],
    ),
    _bundle(
      id: 'bundle_calm_sand',
      familyId: 'calm_sand',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Arena calma',
      nameEn: 'Calm Sand Bundle',
      sortOrder: 4,
      assetIds: const <String>['habit_card_calm_sand', 'user_card_calm_sand'],
    ),
    _bundle(
      id: 'bundle_soft_linen',
      familyId: 'soft_linen',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Lino suave',
      nameEn: 'Soft Linen Bundle',
      sortOrder: 5,
      assetIds: const <String>[
        'habit_card_soft_linen',
        'user_card_soft_linen',
      ],
    ),
    _bundle(
      id: 'bundle_paper_dawn',
      familyId: 'paper_dawn',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Amanecer de papel',
      nameEn: 'Paper Dawn Bundle',
      sortOrder: 6,
      assetIds: const <String>[
        'habit_card_paper_dawn',
        'user_card_paper_dawn',
      ],
    ),
    _bundle(
      id: 'bundle_lavender_mist',
      familyId: 'lavender_mist',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Niebla lavanda',
      nameEn: 'Lavender Mist Bundle',
      sortOrder: 7,
      assetIds: const <String>[
        'habit_card_lavender_mist',
        'user_card_lavender_mist',
      ],
    ),
    _bundle(
      id: 'bundle_dune_layers',
      familyId: 'dune_layers',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Capas de duna',
      nameEn: 'Dune Layers Bundle',
      sortOrder: 8,
      assetIds: const <String>[
        'habit_card_dune_layers',
        'user_card_dune_layers',
      ],
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

  static const Map<String, String> _habitCardAssetFileNames = <String, String>{
    'habit_card_warm_beige': 'habit_card_rutio_beige',
    'habit_card_soft_camel': 'habit_card_soft_camel',
    'habit_card_sand_plain': 'habit_card_off_white',
    'habit_card_cream_light': 'habit_card_cream_yellow',
    'habit_card_calm_sand': 'habit_card_stone_gray',
    'habit_card_soft_linen': 'habit_card_soft_terracotta',
    'habit_card_paper_dawn': 'habit_card_clay_rose',
    'habit_card_violet_flame': 'habit_card_violet_flame',
    'habit_card_lavender_mist': 'habit_card_dusty_lilac',
    'habit_card_dune_layers': 'habit_card_mist_blue',
    'habit_card_golden_dawn': 'habit_card_soft_sage',
  };

  static ShopAsset _asset({
    required String id,
    required String familyId,
    required ShopAssetCategory category,
    required ShopAssetRarity rarity,
    required String nameEs,
    required String nameEn,
    BoxFit imageFit = BoxFit.cover,
    double imageAlignmentX = 0,
    double imageAlignmentY = 0,
    int? overlayColorValue,
    double overlayOpacity = 0,
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
      imageFit: imageFit,
      imageAlignmentX: imageAlignmentX,
      imageAlignmentY: imageAlignmentY,
      overlayColorValue: overlayColorValue,
      overlayOpacity: overlayOpacity,
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
    List<String>? assetIds,
  }) {
    return ShopBundle(
      id: id,
      familyId: familyId,
      rarity: rarity,
      nameEs: nameEs,
      nameEn: nameEn,
      priceAmber: _bundlePriceFor(rarity),
      assetIds: assetIds ??
          <String>[
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
    final fileName = category == ShopAssetCategory.habitCard
        ? _habitCardAssetFileNames[assetId] ?? assetId
        : assetId;

    return 'assets/shop/$folder/${rarity.key}/$fileName.webp';
  }
}
