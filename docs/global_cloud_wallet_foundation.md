# Global Cloud Wallet Foundation

## Objective

This foundation prepares Rutio for a single global cloud wallet while keeping the current app behavior safe by default.

It now exposes the wallet to the main UI through a shared controller, but it still does not move any reward logic, XP, achievements, or level-up behavior onto the cloud wallet.

## Architecture

The new module lives under `lib/features/global_wallet/` and mirrors the same separation used by the shop cloud layer:

- `CloudWalletSnapshot`
- `CloudWalletRepository`
- `GlobalWalletController`
- `GlobalWalletState`
- `WalletCache`
- `WalletFailure`

The module is isolated from `UserStateStore` on purpose so wallet hydration does not trigger gamification side effects.

### Layers

- Remote data source: talks to Supabase and only knows about `public.user_wallets`.
- Repository: validates session, normalizes failures, and returns a typed snapshot.
- Cache: persists the last confirmed wallet per `userId`.
- Controller: manages session changes, cache fallback, reactive state, and UI-safe status transitions.

## Source Canonical

Future canonical source:

- `public.user_wallets`

Legacy source:

- `public.user_progress.ambar_balance`

`ambar_balance` remains in place for now and is treated as legacy/projection data.

The new foundation does not write back to `user_progress`.
It also does not dual-write to both tables from Flutter.

## Cache

The cache is local and user-scoped.

Stored per user:

- balance
- version
- wallet update timestamp
- local cache timestamp

Rules:

- cache entries are keyed by `userId`
- a snapshot from one user never overwrites another user’s cache
- stale network results cannot overwrite a newer cached snapshot
- cache is only a fallback, never the source of truth

When the network fails and a cached confirmed wallet exists, the controller moves to `stale` and serves the cached snapshot.

## Session

The controller is designed for auth-driven session changes.

Login flow:

- the controller reads the current authenticated user
- it clears the previous in-memory session state
- it fetches the wallet for the new user
- it ignores late responses from the previous session
- `walletMissing` is reported explicitly instead of falling back silently

Logout flow:

- in-memory wallet state is cleared
- the previous balance is not shown
- cached entries stay on disk for their original user

This lets the app keep a safe last-known wallet without leaking state across users.

## States

The controller exposes these states:

- `loading`
- `syncing`
- `ready`
- `stale`
- `unauthenticated`
- `walletMissing`
- `failed`

Notes:

- `stale` means a confirmed cached wallet is being used because fresh data could not be trusted or loaded.
- `walletMissing` means the authenticated user does not currently have a wallet row.
- `failed` is used for feature flag off, parse problems, and non-wallet-specific failures when no cache can rescue the state.
- `syncing` means a confirmed cached wallet is being shown while a refresh is in flight.

## Feature Flag

Flag:

- `GLOBAL_CLOUD_WALLET_ENABLED`

Default:

- `false`

With the flag off:

- the controller stays inert for wallet hydration
- the repository returns a controlled `featureDisabled` failure
- no app surface should consume this wallet yet

With the flag on:

- UI reads the wallet from `GlobalWalletController`
- `UserStateStore.wallet.coins` remains legacy-only
- the UI keeps showing the last confirmed wallet when a cache exists
- the controller isolates user sessions and ignores tardy responses from prior users

## Migration Proposal

A versioned SQL migration has been added to backfill missing `public.user_wallets` rows from `public.user_progress`.

It is designed to:

- create a wallet when one does not exist
- copy `ambar_balance` only during the initial backfill
- never overwrite an existing wallet row
- stay idempotent
- record which users were backfilled in an audit table
- avoid running from Flutter

Migration file:

- [`supabase/migrations/20260718120000_backfill_global_cloud_wallet_from_user_progress.sql`](/D:/dev/alpha/rutio_app/supabase/migrations/20260718120000_backfill_global_cloud_wallet_from_user_progress.sql)

Audit table:

- `public.global_cloud_wallet_backfill_audit`

## Risks

- Existing `user_progress.ambar_balance` values are still legacy and may diverge from `user_wallets` until a later migration phase.
- The cache can become stale between refreshes, so the UI must keep respecting the state and status.
- `walletMissing` still requires a follow-up product decision for onboarding and backfill gaps.
- Remote responses can arrive out of order, so session fencing remains important.

## Next Phase

The next phase should migrate the remaining wallet-adjacent flows and remove the last legacy-visible reads:

- habit reward writes
- any remaining legacy wallet reads in non-main surfaces
- future migration away from `UserStateStore.wallet.coins`

That phase should also define whether `user_progress.ambar_balance` becomes a pure shadow/projection or gets retired after the migration window.
