# Shop Cloud Read Integration

## 1. Objective

This phase adds a read-only Supabase layer for the Rutio shop so the app can inspect an authenticated user's remote shop state without changing the local shop behavior.

The local catalog, local wallet flow, local backpack, and local equip flow remain the functional source of truth in production UI.

## 2. Added Architecture

Added layers live under `lib/features/shop/data/cloud/` and a small diagnostic hook in the shop controller.

Key pieces:

- `ShopCatalogRemoteDataSource`
- `ShopUserStateRemoteDataSource`
- `ShopCloudReadRepository`
- `ShopCloudSnapshot`
- `ShopCloudReadResult`
- `ShopCloudReadError`
- `ShopCloudWarning`
- `ShopCloudCatalogReconciler`

The repository uses the existing Supabase client path through `RutioSupabaseClient` and does not create a second client.

## 3. DTOs

Remote DTOs added for defensive parsing:

- `RemoteShopItemDto`
- `RemoteWalletDto`
- `RemoteInventoryItemDto`
- `RemoteEquippedCosmeticDto`

Parsing rules:

- empty IDs are rejected
- negative prices, coins, versions, and quantities are rejected
- invalid timestamps are rejected
- unknown category, rarity, and equip slot values are preserved as controlled `unknown` values where it is safe to do so
- invalid rows are dropped without crashing the app

The shop item DTO keeps `assetKey` as a local Flutter asset reference, not as a URL.

## 4. Data Sources

The Supabase-backed implementations read:

- active rows from `public.shop_items`
- the authenticated user's row from `public.user_wallets`
- the authenticated user's rows from `public.user_inventory`
- the authenticated user's rows from `public.user_equipped_cosmetics`

The remote user ID is never accepted from the UI. It always comes from the current authenticated Supabase session.

Explicit `user_id` filtering is applied for user-scoped tables.

## 5. Snapshot

`ShopCloudSnapshot` is the immutable aggregate returned by the repository.

Fields:

- `authenticatedUserId`
- `catalogItems`
- `wallet`
- `inventory`
- `equippedCosmetics`
- `fetchedAt`
- `catalogVersion`
- `warnings`

The snapshot is read sequentially, not as a cross-table transaction, so the tables may change between queries. That is acceptable in this phase and is surfaced only as a diagnostic snapshot.

## 6. Hybrid Policy

The remote catalog currently contains only five utilities. Because of that:

- the local catalog is preserved
- local cosmetics not present remotely are not removed
- local shop behavior is not switched to remote
- cosmetics are not hidden just because they are not yet seeded in Supabase
- the wallet remote state is not used as the visible balance source
- remote inventory is not applied to the local backpack
- remote equipped cosmetics are not applied to Home

The reconciliation is non-destructive and only emits warnings.

It compares:

- remote IDs against local IDs
- known and unknown remote IDs
- local IDs absent from remote
- prices when IDs match
- consumable and stackable configuration when IDs match

## 7. Feature Flag

Feature flag:

- `SHOP_CLOUD_READ_ENABLED`

Default:

- `false`

Behavior when disabled:

- no extra cloud reads are performed
- the diagnostic method returns `null`
- local behavior remains unchanged

Behavior when enabled:

- `ShopCloudReadRepository` can load a remote snapshot
- the controller can log the snapshot in debug mode
- no production UI is changed

## 8. Session Handling

The read layer treats these cases conservatively:

- unauthenticated user
- expired session
- change of user
- logout
- background and restore scenarios
- unstable connectivity
- timeout
- temporary Supabase outage

Rules:

- snapshots are not reused across different users
- the in-memory cache is cleared on logout
- the cache is invalidated when the observed user changes
- stale responses are ignored if the session changes during a fetch
- local shop behavior is not blocked if cloud fetches fail

## 9. Errors

Controlled error codes:

- `featureDisabled`
- `unauthenticated`
- `sessionChanged`
- `networkUnavailable`
- `timeout`
- `malformedResponse`
- `invalidRemoteItem`
- `walletMissing`
- `unknown`

Repository code maps raw Supabase or parsing failures into these controlled values and does not expose raw PostgreSQL messages to presentation.

## 10. Cache

The repository keeps an in-memory cache keyed by authenticated user ID.

Cache behavior:

- cleared on logout
- cleared on user change
- includes the snapshot timestamp
- does not replace local persistence
- does not survive incorrectly between accounts

## 11. Tests

Tests added under `test/features/shop/data/` cover:

- DTO parsing
- negative values
- unknown category and slot handling
- incomplete JSON
- wallet missing
- invalid inventory rows
- feature flag disabled behavior
- no query when disabled
- successful diagnostic snapshot
- session change during load
- reconciliation for known utilities, unknown remote IDs, price diffs, config diffs, and non-mutating behavior

## 12. Current Limitations

- No cloud writes are connected yet
- No RPCs are called from production UI
- No Realtime subscription is added
- No persistent cloud cache is added
- Remote wallet, inventory, and equipped cosmetics are diagnostic only

## 13. How to Enable Diagnostic Reads

Use the Dart define:

```bash
flutter run --dart-define=SHOP_CLOUD_READ_ENABLED=true
```

The app still keeps the local shop behavior. The diagnostic snapshot is only available when the flag is enabled and a valid Supabase session exists.

## 14. Next Phase

The next phase should connect cloud writes using the existing transactional RPCs:

- `purchase_shop_item`
- `equip_shop_cosmetic`

That phase should keep the same non-destructive migration strategy and only switch functional ownership when the write flow is ready.
