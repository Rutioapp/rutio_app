# Global Cloud Wallet UI

## Scope

This document describes how the main UI of Rutio consumes the global cloud wallet foundation.

The UI now reads the wallet from `GlobalWalletController` when the feature flag is enabled. It does not read wallet coins directly from `UserStateStore` in those paths.

## Connected Surfaces

The following areas now resolve the visible balance from the global wallet controller when the feature is enabled:

- Home user card
- Home header balance
- Weekly header balance
- Monthly header balance
- Edit profile stats row
- Shop header and shop flow wrappers
- Shop cosmetics entry points that still need a wallet value

## Balance Source

When `GLOBAL_CLOUD_WALLET_ENABLED` is `true`:

- UI -> `GlobalWalletController` -> `public.user_wallets`
- cached confirmed balance can be reused while the wallet is `loading`, `syncing`, or `stale`
- `UserStateStore.wallet.coins` becomes a legacy fallback only

When the flag is `false`:

- the UI keeps using the legacy wallet values from `UserStateStore`
- the global wallet controller stays effectively inert

## Visible States

The UI recognizes these controller states:

- `loading`
- `syncing`
- `ready`
- `stale`
- `walletMissing`
- `unauthenticated`
- `failed`

Display rules:

- do not show zero while a confirmed cache exists
- do not show another user’s balance after a session change
- do not present pending cloud changes as confirmed balance
- `stale` keeps the last confirmed balance visible with a stale status
- `walletMissing` surfaces as a controlled empty/error state instead of silently falling back

## Pending Balance Policy

The UI currently shows the confirmed balance only.

Reasoning:

- it avoids presenting pending cloud operations as final
- it keeps the wallet authoritative and easy to reason about
- it leaves room for a future explicit pending-delta badge if we want one

If offline reward operations exist later, they should be shown separately as a syncing/pending indicator, not merged into the confirmed balance.

## Session Handling

Login:

- the auth controller asks the global wallet controller to sync the current user
- late responses from previous sessions are ignored
- the UI updates to the new user only after the wallet controller accepts that session

Logout:

- in-memory wallet state is cleared
- the previous balance disappears from the UI
- persisted cache remains only for the original user id

User switch:

- the controller re-hydrates for the new user
- cached data is partitioned by `userId`
- stale responses from the old user cannot overwrite the new session

## Cache

The UI relies on the wallet cache as a last known good fallback.

Cache fields:

- `userId`
- `coins`
- `version`
- `updatedAt`
- `cachedAt`

Rules:

- cache is isolated per user
- cache never becomes the source of truth
- a newer snapshot is never overwritten by an older response
- cache can be shown while the wallet is `syncing` or `stale`

## Feature Flag

Flag:

- `GLOBAL_CLOUD_WALLET_ENABLED`

Default:

- `false`

With the flag disabled:

- the UI continues to use legacy wallet values
- no cloud wallet authority is shown

## Legacy Compatibility

`UserStateStore.wallet.coins` still exists for compatibility.

It is no longer the visual authority when the global wallet is enabled.

Do not write to both systems from the UI.

## Risks

- Some legacy utilities still read `UserStateStore.wallet.coins` outside the main surfaces.
- Cached balances can become stale during offline use.
- `walletMissing` still needs product guidance for the best user-facing recovery path.
- A future pending-delta UI will need a clear rule for how to present local optimism without confusing the confirmed balance.

## Next Phase

The next phase should finish migrating the remaining wallet-adjacent flows:

- habit reward writes and reversals
- any leftover legacy reads in secondary screens
- final removal of visual dependence on `UserStateStore.wallet.coins`

