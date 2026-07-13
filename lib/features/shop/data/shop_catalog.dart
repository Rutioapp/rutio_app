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
      id: 'wallpaper_mist_blue',
      title: 'Mist Blue Wallpaper',
      description: 'Fondo azul niebla suave para una base limpia y serena.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'mist_blue',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_rutio_beige',
      title: 'Rutio Beige Wallpaper',
      description: 'Fondo beige Rutio con calidez neutra y elegante.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'rutio_beige',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_off_white',
      title: 'Off White Wallpaper',
      description: 'Fondo blanco roto con sensacion ligera y editorial.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'off_white',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_mellow_camel',
      title: 'Mellow Camel Wallpaper',
      description: 'Fondo camel suave con tono calido y relajado.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'mellow_camel',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_stone_gray',
      title: 'Stone Gray Wallpaper',
      description: 'Fondo gris piedra, neutro y muy facil de combinar.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'stone_gray',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_dusty_lilac',
      title: 'Dusty Lilac Wallpaper',
      description: 'Fondo lila empolvado con calma suave y contenida.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'dusty_lilac',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_clay_rose',
      title: 'Clay Rose Wallpaper',
      description: 'Fondo rosa arcilla con presencia amable y suave.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'clay_rose',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_soft_terracotta',
      title: 'Soft Terracotta Wallpaper',
      description: 'Fondo terracota suave con calidez sutil y estable.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_terracotta',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_soft_sage',
      title: 'Soft Sage Wallpaper',
      description: 'Fondo verde salvia con sensacion fresca y tranquila.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_sage',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_cream_yellow',
      title: 'Cream Yellow Wallpaper',
      description: 'Fondo amarillo crema luminoso y muy acogedor.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'cream_yellow',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_warm_beige',
      title: 'Rutio Beige Habit Card',
      description: 'Habit card beige Rutio, limpia y serena.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'warm_beige',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_soft_camel',
      title: 'Soft Camel Habit Card',
      description: 'Habit card camel suave para un look sereno.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_camel',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_sand_plain',
      title: 'Off White Habit Card',
      description: 'Habit card blanco roto pensada para integracion rapida.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'sand_plain',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_cream_light',
      title: 'Cream Yellow Habit Card',
      description: 'Habit card amarillo crema, limpio y aireado.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'cream_light',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_mist_blue',
      title: 'Mist Blue Habit Card',
      description: 'Habit card azul niebla con base limpia y muy serena.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'mist_blue',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_stone_gray',
      title: 'Stone Gray Habit Card',
      description: 'Habit card gris piedra suave y facil de combinar.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'stone_gray',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_dusty_lilac',
      title: 'Dusty Lilac Habit Card',
      description: 'Habit card lila empolvado con tono calmado y limpio.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'dusty_lilac',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_clay_rose',
      title: 'Clay Rose Habit Card',
      description: 'Habit card rosa arcilla con presencia amable y suave.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'clay_rose',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_soft_terracotta',
      title: 'Soft Terracotta Habit Card',
      description: 'Habit card terracota suave con calidez sutil y estable.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_terracotta',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'habit_card_soft_sage',
      title: 'Soft Sage Habit Card',
      description: 'Habit card verde savia con frescura discreta y serena.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_sage',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'wallpaper_jungle_sunrise',
      title: 'Jungle Sunrise Wallpaper',
      description: 'Degradado crema y salvia con un amanecer suave y natural.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'jungle_sunrise',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_lilac_dawn',
      title: 'Lilac Dawn Habit Card',
      description: 'Habit card lavanda suave con transicion limpia y serena.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'lilac_dawn',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'wallpaper_carnival_pastel',
      title: 'Carnival Pastel Wallpaper',
      description: 'Degradado limpio con menta, aqua y lima de energia suave.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'carnival_pastel',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_lavender_blue',
      title: 'Lavender Blue Habit Card',
      description: 'Habit card azul lavanda con lectura limpia y suave.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'lavender_blue',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'wallpaper_strawberry_pastel',
      title: 'Strawberry Pastel Wallpaper',
      description: 'Degradado rosa fresa con base lila y acabado dulce.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'strawberry_pastel',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_golden_camel',
      title: 'Golden Camel Habit Card',
      description: 'Habit card camel dorado con profundidad suave y calida.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'golden_camel',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_sage_bloom',
      title: 'Sage Bloom Habit Card',
      description: 'Habit card verde savia con base limpia y frescura suave.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'sage_bloom',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_dusty_rose',
      title: 'Dusty Rose Habit Card',
      description: 'Habit card rosa empolvado con transicion delicada.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'dusty_rose',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_pastel_sky',
      title: 'Pastel Sky Habit Card',
      description: 'Habit card cielo pastel con degradado amplio y limpio.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'pastel_sky',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_soft_peach',
      title: 'Soft Peach Habit Card',
      description: 'Habit card melocoton suave con calidez ligera y serena.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'soft_peach',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'habit_card_ocean_depth',
      title: 'Ocean Depth Habit Card',
      description:
          'Habit card oceano profundo con luz submarina y calma amplia.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'ocean_depth',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'habit_card_city_sunrise',
      title: 'City Sunrise Habit Card',
      description:
          'Habit card amanecer urbano con luz pastel y horizonte suave.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'city_sunrise',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'habit_card_leopard',
      title: 'Leopard Habit Card',
      description: 'Habit card leopardo con patron calido y look editorial.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'leopard',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'habit_card_full_moon',
      title: 'Full Moon Habit Card',
      description: 'Habit card nocturna con luna llena y atmosfera serena.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'full_moon',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'habit_card_golden_clouds',
      title: 'Golden Clouds Habit Card',
      description: 'Habit card de nubes doradas con brillo suave y calido.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'golden_clouds',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'habit_card_zebra_minimal',
      title: 'Minimal Zebra Habit Card',
      description: 'Habit card zebra minimal con contraste limpio y grafico.',
      type: ShopItemType.habitCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'zebra_minimal',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'wallpaper_starry_sky',
      title: 'Starry Sky Wallpaper',
      description: 'Cielo nocturno con neblina violeta y puntos de luz.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'starry_sky',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'wallpaper_mint_abstract',
      title: 'Mint Abstract Wallpaper',
      description:
          'Formas organicas menta sobre base malva con look editorial.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'mint_abstract',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'wallpaper_zebra_minimal',
      title: 'Minimal Zebra Wallpaper',
      description: 'Patron zebra de alto contraste con lectura muy limpia.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'zebra_minimal',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'wallpaper_wild_stripes',
      title: 'Wild Stripes Wallpaper',
      description: 'Rayas salvajes en naranja intenso con energia animal.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'wild_stripes',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'wallpaper_cow_spots',
      title: 'Minimal Cow Wallpaper',
      description: 'Manchas vaca minimal en blanco y negro con gesto pop.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'cow_spots',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'wallpaper_city_sunrise',
      title: 'City Sunrise Wallpaper',
      description: 'Amanecer urbano pastel con skyline luminoso y sereno.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'city_sunrise',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'wallpaper_ocean_depth',
      title: 'Ocean Depth Wallpaper',
      description: 'Escena marina profunda con fauna azul y luz cenital.',
      type: ShopItemType.background,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'ocean_depth',
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
      id: 'user_card_warm_beige',
      title: 'Rutio Beige User Card',
      description: 'User card beige Rutio, limpia y serena.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'warm_beige',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_soft_camel',
      title: 'Soft Camel User Card',
      description: 'User card camel suave para un look sereno y calido.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_camel',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_sand_plain',
      title: 'Off White User Card',
      description: 'User card blanco roto pensada para una lectura limpia.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'sand_plain',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_cream_light',
      title: 'Cream Yellow User Card',
      description: 'User card amarillo crema con tono aireado y suave.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'cream_light',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_mist_blue',
      title: 'Mist Blue User Card',
      description: 'User card azul niebla con base limpia y muy serena.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'mist_blue',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_stone_gray',
      title: 'Stone Gray User Card',
      description: 'User card gris piedra suave y facil de combinar.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'stone_gray',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_dusty_lilac',
      title: 'Dusty Lilac User Card',
      description: 'User card lila empolvado con tono calmado y limpio.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'dusty_lilac',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_clay_rose',
      title: 'Clay Rose User Card',
      description: 'User card rosa arcilla con presencia amable y suave.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'clay_rose',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_soft_terracotta',
      title: 'Soft Terracotta User Card',
      description: 'User card terracota suave con calidez sutil y estable.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_terracotta',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_soft_sage',
      title: 'Soft Sage User Card',
      description: 'User card verde salvia con frescura discreta y serena.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.common,
      priceCoins: 120,
      familyId: 'soft_sage',
      collectionId: 'minimal',
    ),
    _cosmetic(
      id: 'user_card_lilac_dawn',
      title: 'Lilac Dawn User Card',
      description: 'User card lila-beige con transicion suave y editorial.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'lilac_dawn',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_dusty_rose',
      title: 'Dusty Rose User Card',
      description: 'User card rosa lavanda con degradado delicado y limpio.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'dusty_rose',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_golden_camel',
      title: 'Golden Camel User Card',
      description: 'User card camel dorado suave con profundidad calida.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'golden_camel',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_pastel_sky',
      title: 'Pastel Sky User Card',
      description: 'User card cielo pastel con degradado amplio y ligero.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'pastel_sky',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_soft_peach',
      title: 'Soft Peach User Card',
      description: 'User card amanecer crema-rosa con calidez suave.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.rare,
      priceCoins: 250,
      familyId: 'soft_peach',
      collectionId: 'gradient',
    ),
    _cosmetic(
      id: 'user_card_ocean_depth',
      title: 'Ocean Depth User Card',
      description: 'User card fondo marino con luz amplia y calma profunda.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'ocean_depth',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'user_card_city_sunrise',
      title: 'City Sunrise User Card',
      description: 'User card amanecer urbano con horizonte pastel sereno.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'city_sunrise',
      collectionId: 'landscape',
    ),
    _cosmetic(
      id: 'user_card_full_moon',
      title: 'Full Moon User Card',
      description: 'User card nocturna con luna llena y atmosfera serena.',
      type: ShopItemType.userCard,
      rarity: ShopItemRarity.epic,
      priceCoins: 550,
      familyId: 'full_moon',
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
      return 'assets/shop/habit_cards/$rarityKey/${_habitCardAssetFileNames[assetId] ?? assetId}.webp';
    }
    return 'assets/shop/user_cards/$rarityKey/${_userCardAssetFileNames[assetId] ?? assetId}.webp';
  }

  static const Map<String, String> _habitCardAssetFileNames = <String, String>{
    'habit_card_warm_beige': 'habit_card_rutio_beige',
    'habit_card_soft_camel': 'habit_card_soft_camel',
    'habit_card_sand_plain': 'habit_card_off_white',
    'habit_card_cream_light': 'habit_card_cream_yellow',
    'habit_card_mist_blue': 'habit_card_mist_blue',
    'habit_card_stone_gray': 'habit_card_stone_gray',
    'habit_card_dusty_lilac': 'habit_card_dusty_lilac',
    'habit_card_clay_rose': 'habit_card_clay_rose',
    'habit_card_soft_terracotta': 'habit_card_soft_terracotta',
    'habit_card_soft_sage': 'habit_card_soft_sage',
  };

  static const Map<String, String> _userCardAssetFileNames = <String, String>{
    'user_card_warm_beige': 'user_card_rutio_beige',
    'user_card_soft_camel': 'user_card_soft_camel',
    'user_card_sand_plain': 'user_card_off_white',
    'user_card_cream_light': 'user_card_cream_yellow',
    'user_card_mist_blue': 'user_card_mist_blue',
    'user_card_stone_gray': 'user_card_stone_gray',
    'user_card_dusty_lilac': 'user_card_dusty_lilac',
    'user_card_clay_rose': 'user_card_clay_rose',
    'user_card_soft_terracotta': 'user_card_soft_terracotta',
    'user_card_soft_sage': 'user_card_soft_sage',
  };

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
