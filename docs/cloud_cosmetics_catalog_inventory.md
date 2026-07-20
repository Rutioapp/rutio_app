# Cloud Cosmetics Catalog and Inventory

## Scope

This phase moves the shop cosmetics catalog, ownership, and equip state for:

- Wallpapers
- Habit Cards
- User Cards

Local image assets remain unchanged. Supabase stores catalog metadata and user state only.

## Source Of Truth

- `public.shop_items` is the catalog source of truth for cosmetics.
- `public.user_inventory` stores ownership.
- `public.user_equipped_cosmetics` stores equipped cosmetics by slot.
- `purchase_shop_item` handles purchase.
- `equip_shop_cosmetic` handles equip and unequip.

The UI reads through `ShopCosmeticsController`. When `CLOUD_COSMETICS_ENABLED` is enabled, the controller resolves cosmetics from the cloud snapshot instead of the legacy local repository.

## Catalog Shape

Each cosmetic row stores:

- `id`
- `category`
- `subtype`
- `rarity`
- `price_coins`
- `equip_slot`
- `asset_key`
- `localization_key`
- `is_active`
- `sort_order`
- `catalog_version`

Asset paths remain local, for example:

- `assets/shop/wallpapers/<rarity>/<id>.webp`
- `assets/shop/habit_cards/<rarity>/<id>.webp`
- `assets/shop/user_cards/<rarity>/<id>.webp`

Some habit and user cards reuse the existing local filename aliases already declared in `ShopAssetsCatalog`.

## Cloud State

The controller now keeps a reactive cloud snapshot that exposes:

- `loading`
- `ready`
- `stale`
- `unauthenticated`
- `walletMissing`
- `failed`

The cloud snapshot is isolated by user id and never mixes data across sessions.

## Cache

Cloud cosmetics state is cached locally per user id in `SharedPreferences`.

The cache stores:

- owned cosmetic ids
- equipped cosmetic ids
- catalog version
- fetch and update timestamps

Cache rules:

- one cache entry per user id
- no cross-user reuse
- last known state is reusable when the network fails
- stale cache can be shown, but it is never authoritative

## Session Handling

On login or user switch:

- the controller clears in-memory cosmetics state for the previous user
- the new user starts in loading state
- late responses from the previous session are ignored

On logout:

- in-memory state is cleared
- the persisted cache remains on disk, scoped by user id

## Feature Flag

Flag:

- `CLOUD_COSMETICS_ENABLED`

Default:

- `false`

When disabled, the legacy local cosmetics repository keeps working.

## Migration

The current migration seeds all active cosmetics into `public.shop_items`.

Created migration:

- `supabase/migrations/20260719194500_seed_shop_cosmetics_catalog_v1.sql`

This migration is idempotent and uses `on conflict (id)` to keep the row definitions aligned.

## What Remains Legacy

Bundles are still handled by the existing local cosmetics flow in this phase.

That is intentional. Bundle migration should happen only after the individual cosmetics catalog is stable.

## Risks

- Bundles still use the legacy flow.
- Remote catalog and local catalog must stay aligned on ids and prices.
- The UI only uses the cloud path when the feature flag is enabled.

## Next Phase

- migrate bundles after the individual cosmetics catalog stabilizes
- decide whether the legacy local cosmetics store can be removed
- add remote reconciliation checks for the full cosmetic catalog
