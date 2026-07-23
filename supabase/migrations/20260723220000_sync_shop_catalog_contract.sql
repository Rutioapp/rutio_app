begin;

with bundle_data (
  id,
  family_id,
  rarity,
  price_coins,
  original_price_coins,
  is_active,
  sort_order,
  catalog_version
) as (
  values
    ('pack_lila_profunda', 'pack_lila_profunda', 'rare', 315, 360, true, 16, 2),
    ('pack_coral_atardecer', 'pack_coral_atardecer', 'rare', 315, 360, true, 17, 2)
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

commit;

