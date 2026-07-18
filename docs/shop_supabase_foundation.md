# Shop Supabase Foundation

## 1. Scope

This repository now version-controls the Supabase base for the Rutio shop phase that was manually applied in the SQL Editor.

It covers:

- the base schema and integrity helpers
- the transactional shop RPC layer
- a conservative catalog seed
- a verification SQL script

No Flutter changes are included in this phase.

## 2. Files

- Base schema migration: `supabase/migrations/20260717130000_create_shop_foundation.sql`
- Transactional RPC migration: `supabase/migrations/20260718100000_create_shop_transactional_operations.sql`
- Catalog seed migration: `supabase/migrations/20260718101000_seed_shop_catalog_v1.sql`
- Reset-time seed: `supabase/seed.sql`
- Verification SQL: `supabase/tests/shop_catalog_verification.sql`

## 3. Base Schema

The foundation migration creates or manages:

- `app_private.set_updated_at()`
- `public.shop_items`
- `public.user_wallets`
- `public.user_inventory`
- `public.user_equipped_cosmetics`

It also adds:

- foreign keys
- checks
- triggers
- indexes
- row level security
- policies
- grants and revokes

### Integrity Notes

- `shop_items` keeps the category and role checks for utilities and cosmetics.
- `app_private.set_updated_at()` is used by the update triggers so the helper stays out of the public schema.
- `user_equipped_cosmetics` uses the composite FK `(item_id, slot)` against `shop_items(id, equip_slot)`.

## 4. Transactional Layer

The transactional migration adds:

- `public.shop_ledger`
- `public.purchase_shop_item(text, text, uuid)`
- `public.equip_shop_cosmetic(text, text, uuid)`

The RPCs are `SECURITY DEFINER`, use `request_id` idempotency, lock per user and request, and validate ownership before changing inventory or equipped cosmetics.

Permissions are locked down so that:

- `EXECUTE` is granted only to `authenticated`
- `public` and `anon` are revoked
- direct table writes are not exposed to the app

## 5. Catalog Seed

The shop catalog seed is intentionally conservative.

Seeded rows:

- 5 utilities
- 0 cosmetics
- 0 bundles

The seed uses the same ordered catalog data in both places:

- `supabase/migrations/20260718101000_seed_shop_catalog_v1.sql`
- `supabase/seed.sql`

The rows are ordered deterministically by:

- `category`
- `rarity`
- `sort_order`
- `id`

## 6. Exclusions

The full snapshot contains 89 catalog entries.

Seed exclusions:

- 62 cosmetics
- 22 bundles

Why they were excluded:

- the 62 cosmetics in the snapshot do not have `localization_key` values, so adding new keys would be inventing data
- the 22 bundles need a dedicated bundle persistence contract that is not modeled by the current schema
- the 5 utilities keep their source assets and localization keys, but their DB rows use `rarity = null`, `max_quantity = null`, and `equip_slot = null` to match the current schema contract

The excluded rows are documented in `docs/shop_cloud_catalog_inventory.md`.

## 7. Validation

Run `supabase/tests/shop_catalog_verification.sql` after the foundation and seed are applied.

The script checks:

- total counts
- duplicate IDs
- duplicate asset keys
- duplicate localization keys
- empty asset or localization keys
- invalid config combinations
- utility rows found
- active versus inactive rows
- slot correspondence

## 8. Local Development

Recommended local flow:

```powershell
supabase start
supabase db reset
```

Then run the verification SQL in the local SQL Editor or with `psql` against the local database URL.

Use `supabase db reset` only on a disposable local database.

## 9. SQL Editor Flow

To replay the work in Supabase SQL Editor:

1. Apply `supabase/migrations/20260717130000_create_shop_foundation.sql`.
2. Apply `supabase/migrations/20260718100000_create_shop_transactional_operations.sql`.
3. Apply `supabase/migrations/20260718101000_seed_shop_catalog_v1.sql` or run `supabase/seed.sql`.
4. Run `supabase/tests/shop_catalog_verification.sql`.

## 10. Migration Versus Seed

- The migration file is the versioned history artifact for future environments.
- `supabase/seed.sql` is the reset-time loader used by the local Supabase workflow.
- Both files contain the exact same catalog rows.

## 11. Remote Safety

Do not run `supabase db reset` against a remote Supabase project.

That command is only safe for local disposable environments because it drops and rebuilds the local database before loading the seed.

For remote development environments, use controlled migration application instead of a full reset.

## 12. Next Phase

The next step is a read-only Flutter integration that reads this catalog and uses the RPC layer for write operations.

That phase should focus on:

- catalog reads from Supabase
- wallet and inventory reads
- purchase RPC calls
- equip RPC calls
- keeping the local UI behavior stable while the backend becomes the source of truth
