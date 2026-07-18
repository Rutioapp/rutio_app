begin;

-- Conservative catalog seed for the shop foundation.
-- This version only loads the five utility items that have complete source data.
-- Cosmetics and bundles remain excluded until their DB contracts are modeled.

with seed_data (
  id,
  category,
  subtype,
  rarity,
  price_coins,
  is_consumable,
  is_stackable,
  max_quantity,
  equip_slot,
  asset_key,
  localization_key,
  is_active,
  sort_order,
  catalog_version
) as (
  values
    ('utility_xp_boost_1d', 'utility', 'xpBoost', null::text, 75, true, true, null::integer, null::text, 'assets/shop/utilities/boost_xp.png', 'shopXpBoostTitle', true, 0, 1),
    ('utility_coin_boost_1d', 'utility', 'coinBoost', null::text, 100, true, true, null::integer, null::text, 'assets/shop/utilities/boost_coins.png', 'shopCoinBoostTitle', true, 1, 1),
    ('utility_streak_recover_1', 'utility', 'streakRecover', null::text, 250, true, true, null::integer, null::text, 'assets/shop/utilities/streak_recover.png', 'shopStreakRecoverTitle', true, 2, 1),
    ('utility_streak_shield_1', 'utility', 'streakShield', null::text, 300, true, true, null::integer, null::text, 'assets/shop/utilities/streak_shield.png', 'shopStreakShieldTitle', true, 3, 1),
    ('utility_mystery_box_basic', 'utility', 'mysteryBox', null::text, 100, true, true, null::integer, null::text, 'assets/shop/utilities/mystery_box_basic.png', 'shopMysteryBoxTitle', true, 4, 1)
)
insert into public.shop_items (
  id,
  category,
  subtype,
  rarity,
  price_coins,
  is_consumable,
  is_stackable,
  max_quantity,
  equip_slot,
  asset_key,
  localization_key,
  is_active,
  sort_order,
  catalog_version
)
select
  id,
  category,
  subtype,
  rarity,
  price_coins,
  is_consumable,
  is_stackable,
  max_quantity,
  equip_slot,
  asset_key,
  localization_key,
  is_active,
  sort_order,
  catalog_version
from seed_data
order by category, rarity, sort_order, id
on conflict (id) do update set
  category = excluded.category,
  subtype = excluded.subtype,
  rarity = excluded.rarity,
  price_coins = excluded.price_coins,
  is_consumable = excluded.is_consumable,
  is_stackable = excluded.is_stackable,
  max_quantity = excluded.max_quantity,
  equip_slot = excluded.equip_slot,
  asset_key = excluded.asset_key,
  localization_key = excluded.localization_key,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order,
  catalog_version = excluded.catalog_version,
  updated_at = now();

commit;
