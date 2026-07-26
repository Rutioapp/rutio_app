grant select
on table public.shop_bundle_items
to authenticated;

drop policy if exists shop_bundle_items_select_active
on public.shop_bundle_items;

create policy shop_bundle_items_select_active
on public.shop_bundle_items
for select
to authenticated
using (
  exists (
    select 1
    from public.shop_bundles b
    where b.id = shop_bundle_items.bundle_id
      and b.is_active = true
  )
);
