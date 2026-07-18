-- Shop catalog verification for the conservative seed.
-- Run this after applying the shop foundation and catalog seed.

select
  'counts' as check_name,
  count(*) as total_rows,
  count(*) filter (where category = 'utility') as utility_rows,
  count(*) filter (where category <> 'utility') as cosmetic_rows,
  count(*) filter (where is_active) as active_rows,
  count(*) filter (where not is_active) as inactive_rows
from public.shop_items;

select
  'duplicate_ids' as check_name,
  id,
  count(*) as occurrences
from public.shop_items
group by id
having count(*) > 1
order by id;

select
  'duplicate_asset_keys' as check_name,
  asset_key,
  count(*) as occurrences
from public.shop_items
group by asset_key
having count(*) > 1
order by asset_key;

select
  'duplicate_localization_keys' as check_name,
  localization_key,
  count(*) as occurrences
from public.shop_items
where btrim(coalesce(localization_key, '')) <> ''
group by localization_key
having count(*) > 1
order by localization_key;

select
  'empty_assets_or_localization_keys' as check_name,
  id,
  asset_key,
  localization_key
from public.shop_items
where btrim(coalesce(asset_key, '')) = ''
   or btrim(coalesce(localization_key, '')) = ''
order by category, rarity, sort_order, id;

select
  'invalid_configs' as check_name,
  count(*) filter (
    where price_coins < 0
       or sort_order < 0
       or catalog_version < 1
  ) as basic_invalid_rows,
  count(*) filter (
    where category = 'utility'
      and (
        is_consumable is distinct from true
        or is_stackable is distinct from true
        or max_quantity is not null
        or equip_slot is not null
        or rarity is not null
      )
  ) as utility_invalid_rows,
  count(*) filter (
    where category <> 'utility'
      and (
        is_consumable is distinct from false
        or is_stackable is distinct from false
        or max_quantity is distinct from 1
        or equip_slot is distinct from category
        or rarity not in ('common', 'rare', 'epic', 'legendary')
      )
  ) as cosmetic_invalid_rows
from public.shop_items;

select
  'utilities_found' as check_name,
  id,
  subtype,
  rarity,
  price_coins,
  asset_key,
  localization_key,
  is_active,
  sort_order
from public.shop_items
where category = 'utility'
order by sort_order, id;

select
  'utility_contract' as check_name,
  count(*) filter (
    where category = 'utility'
      and rarity is null
      and max_quantity is null
      and equip_slot is null
      and is_consumable = true
      and is_stackable = true
  ) as utility_ok,
  count(*) filter (
    where category = 'utility'
      and (
        rarity is not null
        or max_quantity is not null
        or equip_slot is not null
        or is_consumable is distinct from true
        or is_stackable is distinct from true
      )
  ) as utility_bad
from public.shop_items;

select
  'active_inactive' as check_name,
  category,
  count(*) filter (where is_active) as active_rows,
  count(*) filter (where not is_active) as inactive_rows
from public.shop_items
group by category
order by category;

select
  'slot_correspondence' as check_name,
  count(*) filter (where category = 'utility' and equip_slot is null) as utility_ok,
  count(*) filter (where category = 'utility' and equip_slot is not null) as utility_bad,
  count(*) filter (where category <> 'utility' and equip_slot = category) as cosmetic_ok,
  count(*) filter (where category <> 'utility' and equip_slot is distinct from category) as cosmetic_bad
from public.shop_items;
