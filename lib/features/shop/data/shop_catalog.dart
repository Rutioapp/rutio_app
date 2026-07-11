import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

class ShopCatalog {
  static const List<ShopCollection> allCollections = <ShopCollection>[
    ShopCollection(
      id: 'minimal',
      title: 'Minimal',
      description: 'Colores planos y familias suaves para una base calmada.',
      themeKey: 'minimal',
      sortOrder: 0,
    ),
    ShopCollection(
      id: 'gradient',
      title: 'Gradient',
      description: 'Texturas y degradados sutiles con identidad editorial.',
      themeKey: 'gradient',
      sortOrder: 1,
    ),
    ShopCollection(
      id: 'landscape',
      title: 'Landscape',
      description:
          'Composiciones con mas presencia visual y profundidad suave.',
      themeKey: 'landscape',
      sortOrder: 2,
    ),
  ];

  static final List<ShopItem> allItems = <ShopItem>[
    ..._cosmeticItems,
    ..._utilityItems,
  ];

  static final List<ShopItem> _cosmeticItems = <ShopItem>[
    _cosmetic(
      id: 'wallpaper_warm_beige',
      title: 'Warm Beige Wallpaper',
      description: 'Fondo beige calido y liso para una base suave.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'warm_beige',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_warm_beige',
      title: 'Warm Beige Habit Card',
      description: 'Habit card beige calido, limpio y muy legible.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'warm_beige',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_warm_beige',
      title: 'Warm Beige User Card',
      description: 'User card beige calido con presencia minimal.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'warm_beige',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_soft_camel',
      title: 'Soft Camel Wallpaper',
      description: 'Fondo camel suave con tono calido y premium.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_camel',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_soft_camel',
      title: 'Soft Camel Habit Card',
      description: 'Habit card camel claro para un look sereno.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_camel',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_soft_camel',
      title: 'Soft Camel User Card',
      description: 'User card camel suave con profundidad contenida.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_camel',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_sand_plain',
      title: 'Plain Sand Wallpaper',
      description: 'Fondo arena neutro, sobrio y funcional.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'sand_plain',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_sand_plain',
      title: 'Plain Sand Habit Card',
      description: 'Habit card arena lisa pensada para integracion rapida.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'sand_plain',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_sand_plain',
      title: 'Plain Sand User Card',
      description: 'User card arena equilibrada y muy utilitaria.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'sand_plain',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_cream_light',
      title: 'Light Cream Wallpaper',
      description: 'Fondo crema claro y luminoso con aire editorial.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'cream_light',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_cream_light',
      title: 'Light Cream Habit Card',
      description: 'Habit card crema claro, limpio y aireado.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'cream_light',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_cream_light',
      title: 'Light Cream User Card',
      description: 'User card crema claro con sensacion iOS-first.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'cream_light',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_calm_sand',
      title: 'Calm Sand Wallpaper',
      description: 'Fondo arena con textura suave y calma editorial.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'calm_sand',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_calm_sand',
      title: 'Calm Sand Habit Card',
      description: 'Habit card arena calma con textura discreta.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'calm_sand',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_calm_sand',
      title: 'Calm Sand User Card',
      description: 'User card arena calma con suavidad natural.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'calm_sand',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'wallpaper_soft_linen',
      title: 'Soft Linen Wallpaper',
      description: 'Fondo lino suave con textura textil muy ligera.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'soft_linen',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_soft_linen',
      title: 'Soft Linen Habit Card',
      description: 'Habit card con tacto visual de lino y papel.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'soft_linen',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_soft_linen',
      title: 'Soft Linen User Card',
      description: 'User card refinada con textura calmada.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'soft_linen',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'wallpaper_paper_dawn',
      title: 'Paper Dawn Wallpaper',
      description: 'Fondo amanecer de papel con degradado muy suave.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'paper_dawn',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_paper_dawn',
      title: 'Paper Dawn Habit Card',
      description: 'Habit card con calidez de amanecer y papel.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'paper_dawn',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_paper_dawn',
      title: 'Paper Dawn User Card',
      description: 'User card crema-peach con profundidad muy sutil.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'paper_dawn',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'wallpaper_lavender_mist',
      title: 'Lavender Mist Wallpaper',
      description: 'Fondo beige con acento lavanda tenue y calmado.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'lavender_mist',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_lavender_mist',
      title: 'Lavender Mist Habit Card',
      description: 'Habit card con mas personalidad y niebla lavanda.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'lavender_mist',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_lavender_mist',
      title: 'Lavender Mist User Card',
      description: 'User card atmosferica, calmada y muy legible.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'lavender_mist',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'wallpaper_dune_layers',
      title: 'Dune Layers Wallpaper',
      description: 'Fondo con capas organicas inspiradas en dunas.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'dune_layers',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'habit_card_dune_layers',
      title: 'Dune Layers Habit Card',
      description: 'Habit card con capas suaves y mas caracter visual.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'dune_layers',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'user_card_dune_layers',
      title: 'Dune Layers User Card',
      description: 'User card de duna con profundidad sutil y elegante.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'dune_layers',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'wallpaper_golden_dawn',
      title: 'Golden Dawn Wallpaper',
      description: 'Fondo premium calido con detalle dorado suave.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.legendary,
      priceCoins: 1200,
      familyId: 'golden_dawn',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'habit_card_golden_dawn',
      title: 'Golden Dawn Habit Card',
      description: 'Habit card premium con profundidad refinada.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.legendary,
      priceCoins: 1200,
      familyId: 'golden_dawn',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'user_card_golden_dawn',
      title: 'Golden Dawn User Card',
      description:
          'User card premium, calida y exclusiva sin brillos agresivos.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.legendary,
      priceCoins: 1200,
      familyId: 'golden_dawn',
      collectionId: 'landscape',
    ),
  ];

  static const List<ShopItem> _utilityItems = <ShopItem>[
    ShopItem(
      id: 'utility_xp_boost_1d',
      title: 'XP Boost 1 Dia',
      description:
          'Aumenta temporalmente la experiencia obtenida al completar habitos.',
      category: ShopItemCategory.utility,
      type: ShopItemType.xpBoost,
      rarity: ShopItemRarity.common,
      priceCoins: 75,
      assetRef: 'assets/shop/utilities/boost_xp.png',
      metadata: <String, dynamic>{'durationHours': 24, 'multiplier': 2},
    ),
    ShopItem(
      id: 'utility_coin_boost_1d',
      title: 'Coin Boost 1 Dia',
      description:
          'Aumenta temporalmente las monedas obtenidas al completar habitos.',
      category: ShopItemCategory.utility,
      type: ShopItemType.coinBoost,
      rarity: ShopItemRarity.common,
      priceCoins: 100,
      assetRef: 'assets/shop/utilities/boost_coins.png',
      metadata: <String, dynamic>{'durationHours': 24, 'multiplier': 2},
    ),
    ShopItem(
      id: 'utility_streak_recover_1',
      title: 'Streak Recover',
      description: 'Permite recuperar una racha perdida una vez.',
      category: ShopItemCategory.utility,
      type: ShopItemType.streakRecover,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      assetRef: 'catalog:utility_streak_recover_1',
      metadata: <String, dynamic>{'charges': 1},
    ),
    ShopItem(
      id: 'utility_streak_shield_1',
      title: 'Streak Shield',
      description: 'Protege una racha frente a un dia fallado.',
      category: ShopItemCategory.utility,
      type: ShopItemType.streakShield,
      rarity: ShopItemRarity.rare,
      priceCoins: 300,
      assetRef: 'catalog:utility_streak_shield_1',
      metadata: <String, dynamic>{'charges': 1},
    ),
    ShopItem(
      id: 'utility_mystery_box_basic',
      title: 'Mystery Box Basic',
      description: 'Caja misteriosa basica con sorpresa futura.',
      category: ShopItemCategory.utility,
      type: ShopItemType.mysteryBox,
      rarity: ShopItemRarity.common,
      priceCoins: 100,
      assetRef: 'assets/shop/utilities/mystery_box_basic.png',
      metadata: <String, dynamic>{'boxTier': 'basic'},
    ),
  ];

  static ShopItem _cosmetic({
    required String id,
    required String title,
    required String description,
    required ShopItemType type,
    required ShopItemRarity rarity,
    required int priceCoins,
    required String familyId,
    required String collectionId,
  }) {
    return ShopItem(
      id: id,
      title: title,
      description: description,
      category: ShopItemCategory.cosmetic,
      type: type,
      rarity: rarity,
      collectionId: collectionId,
      priceCoins: priceCoins,
      assetRef: _assetPathFor(id, rarity),
      metadata: <String, dynamic>{
        'familyId': familyId,
        'placeholder': true,
      },
    );
  }

  static String _assetPathFor(String assetId, ShopItemRarity rarity) {
    final rarityKey = rarity.key;
    if (assetId.startsWith('wallpaper_')) {
      return 'assets/shop/wallpapers/$rarityKey/$assetId.webp';
    }
    if (assetId.startsWith('habit_card_')) {
      return 'assets/shop/habit_cards/$rarityKey/$assetId.webp';
    }
    return 'assets/shop/user_cards/$rarityKey/$assetId.webp';
  }

  static ShopItem? getItemById(String itemId) {
    for (final item in allItems) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  static List<ShopItem> itemsByCategory(ShopItemCategory category) {
    return allItems
        .where((ShopItem item) => item.category == category)
        .toList(growable: false);
  }

  static List<ShopItem> itemsByType(ShopItemType type) {
    return allItems
        .where((ShopItem item) => item.type == type)
        .toList(growable: false);
  }

  static List<ShopItem> itemsByCollection(String collectionId) {
    return allItems
        .where((ShopItem item) => item.collectionId == collectionId)
        .toList(growable: false);
  }

  static String utilityCategoryLabel(ShopItem item) {
    switch (item.type) {
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
        return 'Boosts';
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return 'Rachas';
      case ShopItemType.mysteryBox:
        return 'Cajas';
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return 'Utilidad';
    }
  }

  static String utilityDurationLabel(ShopItem item) {
    final Object? rawDuration = item.metadata['durationHours'];
    if (rawDuration is num && rawDuration > 0) {
      final int durationHours = rawDuration.toInt();
      return durationHours == 1 ? '1 hora' : '$durationHours horas';
    }

    final Object? rawCharges = item.metadata['charges'];
    if (rawCharges is num && rawCharges > 0) {
      final int charges = rawCharges.toInt();
      return charges == 1 ? '1 uso' : '$charges usos';
    }

    if (item.type == ShopItemType.mysteryBox) {
      return '1 caja';
    }

    return 'Uso inmediato';
  }

  static String utilityEffectLabel(ShopItem item) {
    switch (item.type) {
      case ShopItemType.xpBoost:
        return 'Multiplicador de XP x2';
      case ShopItemType.coinBoost:
        return 'Multiplicador de monedas x2';
      case ShopItemType.streakRecover:
        return 'Recuperacion de racha';
      case ShopItemType.streakShield:
        return 'Proteccion de racha';
      case ShopItemType.mysteryBox:
        return 'Sorpresa futura';
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return 'Personalizacion';
    }
  }
}
