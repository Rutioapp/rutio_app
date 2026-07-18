import 'package:flutter/painting.dart';

import 'package:rutio/features/shop/domain/models/habit_card_content_tone.dart';
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

  static const int commonBundleDiscountPercentage = 10;
  static const int rareBundleDiscountPercentage = 12;
  static const int epicBundleDiscountPercentage = 15;

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
      id: 'habit_card_soft_camel',
      familyId: 'soft_camel',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Camel suave',
      nameEn: 'Soft Camel Habit Card',
      sortOrder: 11,
    ),
    _asset(
      id: 'habit_card_sand_plain',
      familyId: 'sand_plain',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Blanco roto',
      nameEn: 'Off White Habit Card',
      sortOrder: 12,
    ),
    _asset(
      id: 'habit_card_cream_light',
      familyId: 'cream_light',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Amarillo crema',
      nameEn: 'Cream Yellow Habit Card',
      sortOrder: 13,
    ),
    _asset(
      id: 'habit_card_mist_blue',
      familyId: 'mist_blue',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Azul niebla',
      nameEn: 'Mist Blue Habit Card',
      sortOrder: 14,
    ),
    _asset(
      id: 'habit_card_stone_gray',
      familyId: 'stone_gray',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Gris piedra',
      nameEn: 'Stone Gray Habit Card',
      sortOrder: 15,
    ),
    _asset(
      id: 'habit_card_dusty_lilac',
      familyId: 'dusty_lilac',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Lila empolvado',
      nameEn: 'Dusty Lilac Habit Card',
      sortOrder: 16,
    ),
    _asset(
      id: 'habit_card_clay_rose',
      familyId: 'clay_rose',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Rosa arcilla',
      nameEn: 'Clay Rose Habit Card',
      sortOrder: 17,
    ),
    _asset(
      id: 'habit_card_soft_terracotta',
      familyId: 'soft_terracotta',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Terracota suave',
      nameEn: 'Soft Terracotta Habit Card',
      sortOrder: 18,
    ),
    _asset(
      id: 'habit_card_soft_sage',
      familyId: 'soft_sage',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'Card Verde savia',
      nameEn: 'Soft Sage Habit Card',
      sortOrder: 19,
    ),
    _asset(
      id: 'wallpaper_jungle_sunrise',
      familyId: 'jungle_sunrise',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Fondo Amanecer en la selva',
      nameEn: 'Jungle Sunrise Wallpaper',
      sortOrder: 20,
    ),
    _asset(
      id: 'habit_card_lilac_dawn',
      familyId: 'lilac_dawn',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Amanecer lila',
      nameEn: 'Lilac Dawn Habit Card',
      sortOrder: 21,
    ),
    _asset(
      id: 'wallpaper_carnival_pastel',
      familyId: 'carnival_pastel',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Fondo Carnaval pastel',
      nameEn: 'Carnival Pastel Wallpaper',
      sortOrder: 22,
    ),
    _asset(
      id: 'habit_card_lavender_blue',
      familyId: 'lavender_blue',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Azul lavanda',
      nameEn: 'Lavender Blue Habit Card',
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
      id: 'habit_card_golden_camel',
      familyId: 'golden_camel',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Camel dorado',
      nameEn: 'Golden Camel Habit Card',
      sortOrder: 25,
    ),
    _asset(
      id: 'habit_card_sage_bloom',
      familyId: 'sage_bloom',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Verde savia',
      nameEn: 'Sage Bloom Habit Card',
      sortOrder: 26,
    ),
    _asset(
      id: 'habit_card_dusty_rose',
      familyId: 'dusty_rose',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Rosa empolvado',
      nameEn: 'Dusty Rose Habit Card',
      sortOrder: 27,
    ),
    _asset(
      id: 'habit_card_pastel_sky',
      familyId: 'pastel_sky',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Cielo pastel',
      nameEn: 'Pastel Sky Habit Card',
      sortOrder: 28,
    ),
    _asset(
      id: 'habit_card_soft_peach',
      familyId: 'soft_peach',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'Card Melocoton suave',
      nameEn: 'Soft Peach Habit Card',
      sortOrder: 29,
    ),
    _asset(
      id: 'habit_card_ocean_depth',
      familyId: 'ocean_depth',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Oceano profundo',
      nameEn: 'Ocean Depth Habit Card',
      contentTone: HabitCardContentTone.light,
      useContentScrim: true,
      sortOrder: 30,
    ),
    _asset(
      id: 'habit_card_city_sunrise',
      familyId: 'city_sunrise',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Amanecer en la ciudad',
      nameEn: 'City Sunrise Habit Card',
      sortOrder: 31,
    ),
    _asset(
      id: 'habit_card_leopard',
      familyId: 'leopard',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Leopardo',
      nameEn: 'Leopard Habit Card',
      sortOrder: 32,
    ),
    _asset(
      id: 'habit_card_full_moon',
      familyId: 'full_moon',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Noche con luna llena',
      nameEn: 'Full Moon Habit Card',
      contentTone: HabitCardContentTone.light,
      useContentScrim: true,
      sortOrder: 33,
    ),
    _asset(
      id: 'habit_card_golden_clouds',
      familyId: 'golden_clouds',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Nubes doradas',
      nameEn: 'Golden Clouds Habit Card',
      sortOrder: 34,
    ),
    _asset(
      id: 'habit_card_zebra_minimal',
      familyId: 'zebra_minimal',
      category: ShopAssetCategory.habitCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Card Zebra',
      nameEn: 'Minimal Zebra Habit Card',
      sortOrder: 35,
    ),
    _asset(
      id: 'wallpaper_starry_sky',
      familyId: 'starry_sky',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Cielo estrellado',
      nameEn: 'Starry Sky Wallpaper',
      sortOrder: 36,
    ),
    _asset(
      id: 'wallpaper_mint_abstract',
      familyId: 'mint_abstract',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Menta abstracta',
      nameEn: 'Mint Abstract Wallpaper',
      sortOrder: 37,
    ),
    _asset(
      id: 'wallpaper_zebra_minimal',
      familyId: 'zebra_minimal',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Zebra minimal',
      nameEn: 'Minimal Zebra Wallpaper',
      sortOrder: 38,
    ),
    _asset(
      id: 'wallpaper_wild_stripes',
      familyId: 'wild_stripes',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Rayas salvajes',
      nameEn: 'Wild Stripes Wallpaper',
      sortOrder: 39,
    ),
    _asset(
      id: 'wallpaper_cow_spots',
      familyId: 'cow_spots',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Vaca minimal',
      nameEn: 'Minimal Cow Wallpaper',
      sortOrder: 40,
    ),
    _asset(
      id: 'wallpaper_city_sunrise',
      familyId: 'city_sunrise',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Amanecer en la ciudad',
      nameEn: 'City Sunrise Wallpaper',
      sortOrder: 41,
    ),
    _asset(
      id: 'wallpaper_ocean_depth',
      familyId: 'ocean_depth',
      category: ShopAssetCategory.wallpaper,
      rarity: ShopAssetRarity.epic,
      nameEs: 'Fondo Oceano profundo',
      nameEn: 'Ocean Depth Wallpaper',
      sortOrder: 42,
    ),
    _asset(
      id: 'user_card_warm_beige',
      familyId: 'warm_beige',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Beige Rutio',
      nameEn: 'Rutio Beige User Card',
      sortOrder: 44,
    ),
    _asset(
      id: 'user_card_soft_camel',
      familyId: 'soft_camel',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Camel suave',
      nameEn: 'Soft Camel User Card',
      sortOrder: 45,
    ),
    _asset(
      id: 'user_card_sand_plain',
      familyId: 'sand_plain',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Blanco roto',
      nameEn: 'Off White User Card',
      sortOrder: 46,
    ),
    _asset(
      id: 'user_card_cream_light',
      familyId: 'cream_light',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Amarillo crema',
      nameEn: 'Cream Yellow User Card',
      sortOrder: 47,
    ),
    _asset(
      id: 'user_card_mist_blue',
      familyId: 'mist_blue',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Azul niebla',
      nameEn: 'Mist Blue User Card',
      sortOrder: 48,
    ),
    _asset(
      id: 'user_card_stone_gray',
      familyId: 'stone_gray',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Gris piedra',
      nameEn: 'Stone Gray User Card',
      sortOrder: 49,
    ),
    _asset(
      id: 'user_card_dusty_lilac',
      familyId: 'dusty_lilac',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Lila empolvado',
      nameEn: 'Dusty Lilac User Card',
      sortOrder: 50,
    ),
    _asset(
      id: 'user_card_clay_rose',
      familyId: 'clay_rose',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Rosa arcilla',
      nameEn: 'Clay Rose User Card',
      sortOrder: 51,
    ),
    _asset(
      id: 'user_card_soft_terracotta',
      familyId: 'soft_terracotta',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Terracota suave',
      nameEn: 'Soft Terracotta User Card',
      sortOrder: 52,
    ),
    _asset(
      id: 'user_card_soft_sage',
      familyId: 'soft_sage',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.common,
      nameEs: 'User Card Verde salvia',
      nameEn: 'Soft Sage User Card',
      sortOrder: 53,
    ),
    _asset(
      id: 'user_card_lilac_dawn',
      familyId: 'lilac_dawn',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'User Card Lila-beige',
      nameEn: 'Lilac Dawn User Card',
      sortOrder: 54,
    ),
    _asset(
      id: 'user_card_dusty_rose',
      familyId: 'dusty_rose',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'User Card Rosa lavanda',
      nameEn: 'Dusty Rose User Card',
      sortOrder: 55,
    ),
    _asset(
      id: 'user_card_golden_camel',
      familyId: 'golden_camel',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'User Card Camel dorado suave',
      nameEn: 'Golden Camel User Card',
      sortOrder: 56,
    ),
    _asset(
      id: 'user_card_pastel_sky',
      familyId: 'pastel_sky',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'User Card Cielo pastel',
      nameEn: 'Pastel Sky User Card',
      sortOrder: 57,
    ),
    _asset(
      id: 'user_card_soft_peach',
      familyId: 'soft_peach',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.rare,
      nameEs: 'User Card Amanecer crema-rosa',
      nameEn: 'Soft Peach User Card',
      sortOrder: 58,
    ),
    _asset(
      id: 'user_card_ocean_depth',
      familyId: 'ocean_depth',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'User Card Fondo marino',
      nameEn: 'Ocean Depth User Card',
      sortOrder: 59,
    ),
    _asset(
      id: 'user_card_city_sunrise',
      familyId: 'city_sunrise',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'User Card Amanecer en ciudad',
      nameEn: 'City Sunrise User Card',
      sortOrder: 60,
    ),
    _asset(
      id: 'user_card_full_moon',
      familyId: 'full_moon',
      category: ShopAssetCategory.userCard,
      rarity: ShopAssetRarity.epic,
      nameEs: 'User Card Luna llena',
      nameEn: 'Full Moon User Card',
      sortOrder: 61,
    ),
  ];

  static final List<ShopBundle> allBundles = <ShopBundle>[
    _bundle(
      id: 'pack_beige_rutio',
      familyId: 'pack_beige_rutio',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Beige Rutio',
      nameEn: 'Rutio Beige Pack',
      descriptionEs: 'Un trio neutro y sereno para una base limpia y elegante.',
      descriptionEn:
          'A neutral and serene trio for a clean, elegant foundation.',
      wallpaperItemId: 'wallpaper_rutio_beige',
      habitCardItemId: 'habit_card_warm_beige',
      userCardItemId: 'user_card_warm_beige',
      isFeatured: true,
      sortOrder: 0,
    ),
    _bundle(
      id: 'pack_camel_suave',
      familyId: 'pack_camel_suave',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Camel suave',
      nameEn: 'Soft Camel Pack',
      descriptionEs: 'Calidez suave y equilibrada para una rutina tranquila.',
      descriptionEn: 'Soft, balanced warmth for a calm and steady routine.',
      wallpaperItemId: 'wallpaper_mellow_camel',
      habitCardItemId: 'habit_card_soft_camel',
      userCardItemId: 'user_card_soft_camel',
      sortOrder: 1,
    ),
    _bundle(
      id: 'pack_blanco_roto',
      familyId: 'pack_blanco_roto',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Blanco roto',
      nameEn: 'Off White Pack',
      descriptionEs: 'Minimalismo claro con una lectura fresca y luminosa.',
      descriptionEn: 'Bright minimalism with a fresh, airy reading.',
      wallpaperItemId: 'wallpaper_off_white',
      habitCardItemId: 'habit_card_sand_plain',
      userCardItemId: 'user_card_sand_plain',
      sortOrder: 2,
    ),
    _bundle(
      id: 'pack_verde_savia',
      familyId: 'pack_verde_savia',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Verde savia',
      nameEn: 'Soft Sage Pack',
      descriptionEs: 'Fresco, suave y natural para una interfaz muy calmada.',
      descriptionEn: 'Fresh, soft and natural for a very calm interface.',
      wallpaperItemId: 'wallpaper_soft_sage',
      habitCardItemId: 'habit_card_soft_sage',
      userCardItemId: 'user_card_soft_sage',
      sortOrder: 3,
    ),
    _bundle(
      id: 'pack_amanecer_lila',
      familyId: 'pack_amanecer_lila',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Amanecer lila',
      nameEn: 'Lilac Dawn Pack',
      descriptionEs: 'Un degradado suave con un acabado editorial y delicado.',
      descriptionEn: 'A soft gradient with a delicate editorial finish.',
      wallpaperItemId: 'wallpaper_dusty_lilac',
      habitCardItemId: 'habit_card_lilac_dawn',
      userCardItemId: 'user_card_lilac_dawn',
      isFeatured: true,
      sortOrder: 4,
    ),
    _bundle(
      id: 'pack_azul_lavanda',
      familyId: 'pack_azul_lavanda',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Azul lavanda',
      nameEn: 'Lavender Blue Pack',
      descriptionEs: 'Azules suaves y lavanda limpia con aire pastel.',
      descriptionEn: 'Soft blues and clean lavender with a pastel feel.',
      wallpaperItemId: 'wallpaper_mist_blue',
      habitCardItemId: 'habit_card_lavender_blue',
      userCardItemId: 'user_card_pastel_sky',
      sortOrder: 5,
    ),
    _bundle(
      id: 'pack_camel_dorado',
      familyId: 'pack_camel_dorado',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Camel dorado',
      nameEn: 'Golden Camel Pack',
      descriptionEs: 'Tonos cálidos con un acabado premium y luminoso.',
      descriptionEn: 'Warm tones with a premium, luminous finish.',
      wallpaperItemId: 'wallpaper_cream_yellow',
      habitCardItemId: 'habit_card_golden_camel',
      userCardItemId: 'user_card_golden_camel',
      sortOrder: 6,
    ),
    _bundle(
      id: 'pack_rosa_empolvado',
      familyId: 'pack_rosa_empolvado',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Rosa empolvado',
      nameEn: 'Dusty Rose Pack',
      descriptionEs: 'Rosa suave con una lectura delicada y calmada.',
      descriptionEn: 'Soft rose with a delicate, calm reading.',
      wallpaperItemId: 'wallpaper_clay_rose',
      habitCardItemId: 'habit_card_dusty_rose',
      userCardItemId: 'user_card_dusty_rose',
      sortOrder: 7,
    ),
    _bundle(
      id: 'pack_oceano_profundo',
      familyId: 'pack_oceano_profundo',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Oceano profundo',
      nameEn: 'Ocean Depth Pack',
      descriptionEs: 'Profundidad submarina con mucha calma visual.',
      descriptionEn: 'Submarine depth with a lot of visual calm.',
      wallpaperItemId: 'wallpaper_ocean_depth',
      habitCardItemId: 'habit_card_ocean_depth',
      userCardItemId: 'user_card_ocean_depth',
      isFeatured: true,
      sortOrder: 8,
    ),
    _bundle(
      id: 'pack_amanecer_ciudad',
      familyId: 'pack_amanecer_ciudad',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Amanecer en ciudad',
      nameEn: 'City Sunrise Pack',
      descriptionEs: 'Horizonte pastel con luz urbana amplia y cálida.',
      descriptionEn: 'Pastel horizon with broad, warm urban light.',
      wallpaperItemId: 'wallpaper_city_sunrise',
      habitCardItemId: 'habit_card_city_sunrise',
      userCardItemId: 'user_card_city_sunrise',
      sortOrder: 9,
    ),
    _bundle(
      id: 'pack_luna_llena',
      familyId: 'pack_luna_llena',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Luna llena',
      nameEn: 'Full Moon Pack',
      descriptionEs: 'Noche serena con brillo lunar y contraste elegante.',
      descriptionEn: 'A serene night with lunar glow and elegant contrast.',
      wallpaperItemId: 'wallpaper_starry_sky',
      habitCardItemId: 'habit_card_full_moon',
      userCardItemId: 'user_card_full_moon',
      sortOrder: 10,
    ),
    _bundle(
      id: 'pack_zebra_minimal',
      familyId: 'pack_zebra_minimal',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Zebra minimal',
      nameEn: 'Minimal Zebra Pack',
      descriptionEs: 'Monocromo editorial con un cierre más gráfico.',
      descriptionEn: 'Editorial monochrome with a more graphic finish.',
      wallpaperItemId: 'wallpaper_zebra_minimal',
      habitCardItemId: 'habit_card_zebra_minimal',
      userCardItemId: 'user_card_stone_gray',
      sortOrder: 11,
    ),
    _bundle(
      id: 'pack_mineral_urbano',
      familyId: 'pack_mineral_urbano',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Mineral urbano',
      nameEn: 'Urban Mineral Pack',
      descriptionEs:
          'Un gris limpio y arquitectónico para una interfaz serena y moderna.',
      descriptionEn:
          'A clean, architectural gray for a serene and modern interface.',
      wallpaperItemId: 'wallpaper_stone_gray',
      habitCardItemId: 'habit_card_stone_gray',
      userCardItemId: 'user_card_stone_gray',
      sortOrder: 12,
    ),
    _bundle(
      id: 'pack_terracota_suave',
      familyId: 'pack_terracota_suave',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Terracota suave',
      nameEn: 'Soft Terracotta Pack',
      descriptionEs:
          'Tonos terracota cálidos para una composición muy acogedora.',
      descriptionEn: 'Warm terracotta tones for a very welcoming composition.',
      wallpaperItemId: 'wallpaper_soft_terracotta',
      habitCardItemId: 'habit_card_soft_terracotta',
      userCardItemId: 'user_card_soft_terracotta',
      sortOrder: 13,
    ),
    _bundle(
      id: 'pack_hielo_pastel',
      familyId: 'pack_hielo_pastel',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Hielo pastel',
      nameEn: 'Pastel Ice Pack',
      descriptionEs: 'Azul claro y frío con una lectura ligera y muy limpia.',
      descriptionEn: 'Light, cool blue with a clean and airy reading.',
      wallpaperItemId: 'wallpaper_mist_blue',
      habitCardItemId: 'habit_card_mist_blue',
      userCardItemId: 'user_card_mist_blue',
      sortOrder: 14,
    ),
    _bundle(
      id: 'pack_crema_clara',
      familyId: 'pack_crema_clara',
      rarity: ShopAssetRarity.common,
      nameEs: 'Pack Crema clara',
      nameEn: 'Clear Cream Pack',
      descriptionEs:
          'Una mezcla suave de crema y luz para un acabado muy amable.',
      descriptionEn: 'A soft mix of cream and light for a very gentle finish.',
      wallpaperItemId: 'wallpaper_cream_yellow',
      habitCardItemId: 'habit_card_cream_light',
      userCardItemId: 'user_card_cream_light',
      sortOrder: 15,
    ),
    _bundle(
      id: 'pack_lila_profunda',
      familyId: 'pack_lila_profunda',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Lila profunda',
      nameEn: 'Deep Lilac Pack',
      descriptionEs: 'Un lila elegante y envolvente con mucho aire editorial.',
      descriptionEn:
          'An elegant, enveloping lilac with a strong editorial feel.',
      wallpaperItemId: 'wallpaper_dusty_lilac',
      habitCardItemId: 'habit_card_dusty_lilac',
      userCardItemId: 'user_card_dusty_lilac',
      sortOrder: 16,
    ),
    _bundle(
      id: 'pack_coral_atardecer',
      familyId: 'pack_coral_atardecer',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Coral atardecer',
      nameEn: 'Coral Sunset Pack',
      descriptionEs:
          'Coral y rosa arcilla con un final cálido, delicado y luminoso.',
      descriptionEn:
          'Coral and clay rose with a warm, delicate, luminous finish.',
      wallpaperItemId: 'wallpaper_clay_rose',
      habitCardItemId: 'habit_card_clay_rose',
      userCardItemId: 'user_card_clay_rose',
      sortOrder: 17,
    ),
    _bundle(
      id: 'pack_fresa_crema',
      familyId: 'pack_fresa_crema',
      rarity: ShopAssetRarity.rare,
      nameEs: 'Pack Fresa crema',
      nameEn: 'Strawberry Cream Pack',
      descriptionEs:
          'Un pastel afrutado y suave que deja una sensación muy dulce.',
      descriptionEn: 'A soft fruity pastel with a very sweet overall feeling.',
      wallpaperItemId: 'wallpaper_strawberry_pastel',
      habitCardItemId: 'habit_card_soft_peach',
      userCardItemId: 'user_card_soft_peach',
      sortOrder: 18,
    ),
    _bundle(
      id: 'pack_noche_lunar',
      familyId: 'pack_noche_lunar',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Noche lunar',
      nameEn: 'Lunar Night Pack',
      descriptionEs:
          'Una noche serena con cielo estrellado y un brillo lunar muy limpio.',
      descriptionEn:
          'A serene night with a starry sky and a very clean lunar glow.',
      wallpaperItemId: 'wallpaper_starry_sky',
      habitCardItemId: 'habit_card_full_moon',
      userCardItemId: 'user_card_full_moon',
      isFeatured: true,
      sortOrder: 19,
    ),
    _bundle(
      id: 'pack_bruma_abstracta',
      familyId: 'pack_bruma_abstracta',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Bruma abstracta',
      nameEn: 'Abstract Mist Pack',
      descriptionEs:
          'Una lectura abstracta y fría con una composición muy contemporánea.',
      descriptionEn:
          'An abstract, cool reading with a very contemporary composition.',
      wallpaperItemId: 'wallpaper_mint_abstract',
      habitCardItemId: 'habit_card_zebra_minimal',
      userCardItemId: 'user_card_stone_gray',
      sortOrder: 20,
    ),
    _bundle(
      id: 'pack_manchas_salvajes',
      familyId: 'pack_manchas_salvajes',
      rarity: ShopAssetRarity.epic,
      nameEs: 'Pack Manchas salvajes',
      nameEn: 'Wild Spots Pack',
      descriptionEs:
          'Un gráfico animal muy limpio con contraste editorial y premium.',
      descriptionEn:
          'A clean animal graphic with a premium editorial contrast.',
      wallpaperItemId: 'wallpaper_cow_spots',
      habitCardItemId: 'habit_card_leopard',
      userCardItemId: 'user_card_stone_gray',
      sortOrder: 21,
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

  static ShopBundle _bundle({
    required String id,
    required String familyId,
    required ShopAssetRarity rarity,
    required String nameEs,
    required String nameEn,
    required String descriptionEs,
    required String descriptionEn,
    required String wallpaperItemId,
    required String habitCardItemId,
    required String userCardItemId,
    bool isFeatured = false,
    required int sortOrder,
  }) {
    final wallpaper = getAssetById(wallpaperItemId);
    final habitCard = getAssetById(habitCardItemId);
    final userCard = getAssetById(userCardItemId);
    final originalPrice = <ShopAsset?>[
      wallpaper,
      habitCard,
      userCard,
    ].whereType<ShopAsset>().fold<int>(0, (int total, ShopAsset asset) {
      return total + asset.priceAmber;
    });
    final discountPercentage = switch (rarity) {
      ShopAssetRarity.common => commonBundleDiscountPercentage,
      ShopAssetRarity.rare => rareBundleDiscountPercentage,
      ShopAssetRarity.epic => epicBundleDiscountPercentage,
      ShopAssetRarity.legendary => epicBundleDiscountPercentage,
    };
    final discountedPrice =
        _discountedBundlePrice(originalPrice, discountPercentage);

    return ShopBundle(
      id: id,
      familyId: familyId,
      rarity: rarity,
      nameEs: nameEs,
      nameEn: nameEn,
      descriptionEs: descriptionEs,
      descriptionEn: descriptionEn,
      wallpaperItemId: wallpaperItemId,
      habitCardItemId: habitCardItemId,
      userCardItemId: userCardItemId,
      originalPriceAmber: originalPrice,
      priceAmber: discountedPrice,
      discountPercentage: discountPercentage,
      isFeatured: isFeatured,
      isPurchasable: true,
      sortOrder: sortOrder,
    );
  }

  static int _discountedBundlePrice(
    int originalPrice,
    int discountPercentage,
  ) {
    if (originalPrice <= 0) return 0;

    final discounted = originalPrice * (100 - discountPercentage) / 100;
    final rounded = (discounted / 5).round() * 5;
    if (rounded <= 0) return 5;
    if (rounded >= originalPrice) {
      final fallback = originalPrice - 5;
      return fallback > 0 ? fallback : originalPrice;
    }
    return rounded;
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
    HabitCardContentTone contentTone = HabitCardContentTone.dark,
    bool useContentScrim = false,
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
      contentTone: contentTone,
      useContentScrim: useContentScrim,
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
    final fileName = switch (category) {
      ShopAssetCategory.habitCard =>
        _habitCardAssetFileNames[assetId] ?? assetId,
      ShopAssetCategory.userCard => _userCardAssetFileNames[assetId] ?? assetId,
      ShopAssetCategory.wallpaper => assetId,
    };

    return 'assets/shop/$folder/${rarity.key}/$fileName.webp';
  }
}
