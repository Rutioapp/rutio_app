begin;

with bundle_data (
  id,
  family_id,
  rarity,
  price_coins,
  original_price_coins,
  is_active,
  sort_order,
  catalog_version,
  wallpaper_item_id,
  habit_card_item_id,
  user_card_item_id
) as (
  values
    ('pack_beige_rutio', 'pack_beige_rutio', 'common', 325, 360, true, 0, 1, 'wallpaper_rutio_beige', 'habit_card_warm_beige', 'user_card_warm_beige'),
    ('pack_camel_suave', 'pack_camel_suave', 'common', 325, 360, true, 1, 1, 'wallpaper_mellow_camel', 'habit_card_soft_camel', 'user_card_soft_camel'),
    ('pack_blanco_roto', 'pack_blanco_roto', 'common', 325, 360, true, 2, 1, 'wallpaper_off_white', 'habit_card_sand_plain', 'user_card_sand_plain'),
    ('pack_verde_savia', 'pack_verde_savia', 'common', 325, 360, true, 3, 1, 'wallpaper_soft_sage', 'habit_card_soft_sage', 'user_card_soft_sage'),
    ('pack_amanecer_lila', 'pack_amanecer_lila', 'rare', 545, 620, true, 4, 1, 'wallpaper_dusty_lilac', 'habit_card_lilac_dawn', 'user_card_lilac_dawn'),
    ('pack_azul_lavanda', 'pack_azul_lavanda', 'rare', 545, 620, true, 5, 1, 'wallpaper_mist_blue', 'habit_card_lavender_blue', 'user_card_pastel_sky'),
    ('pack_camel_dorado', 'pack_camel_dorado', 'rare', 545, 620, true, 6, 1, 'wallpaper_cream_yellow', 'habit_card_golden_camel', 'user_card_golden_camel'),
    ('pack_rosa_empolvado', 'pack_rosa_empolvado', 'rare', 545, 620, true, 7, 1, 'wallpaper_clay_rose', 'habit_card_dusty_rose', 'user_card_dusty_rose'),
    ('pack_oceano_profundo', 'pack_oceano_profundo', 'epic', 1405, 1650, true, 8, 1, 'wallpaper_ocean_depth', 'habit_card_ocean_depth', 'user_card_ocean_depth'),
    ('pack_amanecer_ciudad', 'pack_amanecer_ciudad', 'epic', 1405, 1650, true, 9, 1, 'wallpaper_city_sunrise', 'habit_card_city_sunrise', 'user_card_city_sunrise'),
    ('pack_luna_llena', 'pack_luna_llena', 'epic', 1405, 1650, true, 10, 1, 'wallpaper_starry_sky', 'habit_card_full_moon', 'user_card_full_moon'),
    ('pack_zebra_minimal', 'pack_zebra_minimal', 'epic', 1035, 1220, true, 11, 1, 'wallpaper_zebra_minimal', 'habit_card_zebra_minimal', 'user_card_stone_gray'),
    ('pack_mineral_urbano', 'pack_mineral_urbano', 'common', 325, 360, true, 12, 1, 'wallpaper_stone_gray', 'habit_card_stone_gray', 'user_card_stone_gray'),
    ('pack_terracota_suave', 'pack_terracota_suave', 'common', 325, 360, true, 13, 1, 'wallpaper_soft_terracotta', 'habit_card_soft_terracotta', 'user_card_soft_terracotta'),
    ('pack_hielo_pastel', 'pack_hielo_pastel', 'common', 325, 360, true, 14, 1, 'wallpaper_mist_blue', 'habit_card_mist_blue', 'user_card_mist_blue'),
    ('pack_crema_clara', 'pack_crema_clara', 'common', 325, 360, true, 15, 1, 'wallpaper_cream_yellow', 'habit_card_cream_light', 'user_card_cream_light'),
    ('pack_lila_profunda', 'pack_lila_profunda', 'rare', 545, 620, true, 16, 1, 'wallpaper_dusty_lilac', 'habit_card_dusty_lilac', 'user_card_dusty_lilac'),
    ('pack_coral_atardecer', 'pack_coral_atardecer', 'rare', 545, 620, true, 17, 1, 'wallpaper_clay_rose', 'habit_card_clay_rose', 'user_card_clay_rose'),
    ('pack_fresa_crema', 'pack_fresa_crema', 'rare', 660, 750, true, 18, 1, 'wallpaper_strawberry_pastel', 'habit_card_soft_peach', 'user_card_soft_peach'),
    ('pack_noche_lunar', 'pack_noche_lunar', 'epic', 1405, 1650, true, 19, 1, 'wallpaper_starry_sky', 'habit_card_full_moon', 'user_card_full_moon'),
    ('pack_bruma_abstracta', 'pack_bruma_abstracta', 'epic', 1035, 1220, true, 20, 1, 'wallpaper_mint_abstract', 'habit_card_zebra_minimal', 'user_card_stone_gray'),
    ('pack_manchas_salvajes', 'pack_manchas_salvajes', 'epic', 1035, 1220, true, 21, 1, 'wallpaper_cow_spots', 'habit_card_leopard', 'user_card_stone_gray')
)
insert into public.shop_bundles (
  id,
  family_id,
  rarity,
  price_coins,
  original_price_coins,
  is_active,
  sort_order,
  catalog_version
)
select
  id,
  family_id,
  rarity,
  price_coins,
  original_price_coins,
  is_active,
  sort_order,
  catalog_version
from bundle_data
on conflict (id) do update set
  family_id = excluded.family_id,
  rarity = excluded.rarity,
  price_coins = excluded.price_coins,
  original_price_coins = excluded.original_price_coins,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order,
  catalog_version = excluded.catalog_version,
  updated_at = now();

with bundle_data (
  id,
  wallpaper_item_id,
  habit_card_item_id,
  user_card_item_id
) as (
  values
    ('pack_beige_rutio', 'wallpaper_rutio_beige', 'habit_card_warm_beige', 'user_card_warm_beige'),
    ('pack_camel_suave', 'wallpaper_mellow_camel', 'habit_card_soft_camel', 'user_card_soft_camel'),
    ('pack_blanco_roto', 'wallpaper_off_white', 'habit_card_sand_plain', 'user_card_sand_plain'),
    ('pack_verde_savia', 'wallpaper_soft_sage', 'habit_card_soft_sage', 'user_card_soft_sage'),
    ('pack_amanecer_lila', 'wallpaper_dusty_lilac', 'habit_card_lilac_dawn', 'user_card_lilac_dawn'),
    ('pack_azul_lavanda', 'wallpaper_mist_blue', 'habit_card_lavender_blue', 'user_card_pastel_sky'),
    ('pack_camel_dorado', 'wallpaper_cream_yellow', 'habit_card_golden_camel', 'user_card_golden_camel'),
    ('pack_rosa_empolvado', 'wallpaper_clay_rose', 'habit_card_dusty_rose', 'user_card_dusty_rose'),
    ('pack_oceano_profundo', 'wallpaper_ocean_depth', 'habit_card_ocean_depth', 'user_card_ocean_depth'),
    ('pack_amanecer_ciudad', 'wallpaper_city_sunrise', 'habit_card_city_sunrise', 'user_card_city_sunrise'),
    ('pack_luna_llena', 'wallpaper_starry_sky', 'habit_card_full_moon', 'user_card_full_moon'),
    ('pack_zebra_minimal', 'wallpaper_zebra_minimal', 'habit_card_zebra_minimal', 'user_card_stone_gray'),
    ('pack_mineral_urbano', 'wallpaper_stone_gray', 'habit_card_stone_gray', 'user_card_stone_gray'),
    ('pack_terracota_suave', 'wallpaper_soft_terracotta', 'habit_card_soft_terracotta', 'user_card_soft_terracotta'),
    ('pack_hielo_pastel', 'wallpaper_mist_blue', 'habit_card_mist_blue', 'user_card_mist_blue'),
    ('pack_crema_clara', 'wallpaper_cream_yellow', 'habit_card_cream_light', 'user_card_cream_light'),
    ('pack_lila_profunda', 'wallpaper_dusty_lilac', 'habit_card_dusty_lilac', 'user_card_dusty_lilac'),
    ('pack_coral_atardecer', 'wallpaper_clay_rose', 'habit_card_clay_rose', 'user_card_clay_rose'),
    ('pack_fresa_crema', 'wallpaper_strawberry_pastel', 'habit_card_soft_peach', 'user_card_soft_peach'),
    ('pack_noche_lunar', 'wallpaper_starry_sky', 'habit_card_full_moon', 'user_card_full_moon'),
    ('pack_bruma_abstracta', 'wallpaper_mint_abstract', 'habit_card_zebra_minimal', 'user_card_stone_gray'),
    ('pack_manchas_salvajes', 'wallpaper_cow_spots', 'habit_card_leopard', 'user_card_stone_gray')
)
insert into public.shop_bundle_items (
  bundle_id,
  item_id,
  slot
)
select
  id,
  wallpaper_item_id,
  'screen_background'
from bundle_data
union all
select
  id,
  habit_card_item_id,
  'habit_card_background'
from bundle_data
union all
select
  id,
  user_card_item_id,
  'user_card_background'
from bundle_data
on conflict (bundle_id, item_id) do update set
  slot = excluded.slot;

commit;
