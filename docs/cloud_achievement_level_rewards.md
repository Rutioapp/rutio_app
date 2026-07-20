# Cloud Achievement And Level Rewards

## Goal

Rutio now moves monetary rewards for achievements and level-ups to Supabase in a
cloud-safe way while keeping the existing local progression and celebration
experience intact.

## Current flow

- Unlocks and level changes are still detected in `UserStateStore`.
- Monetary rewards are no longer written directly into the legacy wallet path
  when the feature flag is enabled.
- The server is responsible for validating the reward and updating
  `public.user_wallets`.
- The UI only sees the wallet after the global wallet controller refreshes.

## Canonical source

- `public.user_wallets` is the canonical source for coins.
- `public.user_progress.ambar_balance` remains legacy and is not written from
  this feature.
- `public.user_achievements.reward_applied` continues to exist as a confirmed
  local/remote marker for achievement claims.

## Feature flag

- `CLOUD_ACHIEVEMENT_LEVEL_REWARDS_ENABLED`
- Default: `false`
- When disabled, the legacy in-app coin path remains active.
- When enabled, Flutter does not dual-write to the wallet and the cloud claim
  path is used instead.

## Architecture

- `AchievementLevelRewardCoordinator` orchestrates claim retries and pending
  operations.
- `AchievementLevelRewardRepository` owns the RPC boundary.
- `PendingRewardClaimStore` persists pending claims per user.
- `AchievementLevelRewardLedgerEntry` is the auditable server response.
- `ClaimAchievementRewardUseCase` and `ClaimLevelRewardUseCase` provide thin
  application-layer entry points.

## Claim IDs

Claim requests use stable, user-scoped request ids:

- Achievement: `reward:{userId}:achievement:{achievementId}`
- Level: `reward:{userId}:level:{level}`

These ids are reused across retries and app restarts.

## Idempotency

- Supabase enforces uniqueness on `request_id`.
- Supabase also enforces uniqueness on `(user_id, operation_type, source_type,
  source_id)`.
- The client only sends stable identifiers, never free-form coin amounts.
- The server computes or validates the final coin delta.

## Cache and pending state

- Pending claims are stored per `userId` in SharedPreferences.
- Pending claims survive app restarts.
- Pending claims do not mix between users.
- Confirmed achievement ids are mirrored into `rewardAppliedAchievementIds`
  and `claims.achievementRewardsClaimed`.
- Confirmed level claims are mirrored into `claims.milestonesClaimed`.

## Session handling

- Claims are scoped to the authenticated Supabase user.
- Requests are ignored if the active auth session changes mid-flight.
- Logout clears in-memory state, but not the per-user pending cache.
- On next login, the coordinator can resolve the pending queue for that user.

## States

The UI keeps the existing gameplay/overlay states, but reward confirmation is
decoupled from presentation.

- `loading`
- `ready`
- `stale`
- `syncing`
- `walletMissing`
- `unauthenticated`
- `failed`

## Migration proposal

The SQL migration creates:

- `public.achievement_level_reward_ledger`
- `public.claim_achievement_reward(...)`
- `public.claim_level_reward(...)`

It also adds private helpers for reward amounts by tier and level.

The migration is safe for existing users because it only adds the claim path
and the ledger. It does not backfill legacy rewards again.

## Risks

- If a reward was never confirmed and no pending claim exists, it will not be
  retroactively inferred by the client.
- If the server-side reward mapping is changed without mirroring the Dart
  constants, validation will fail.
- Because level rewards are now claimed separately from the celebration modal,
  any modal-specific logic should stay presentation-only.

## Next phase

- Migrate the remaining legacy coin producers to the same claim pattern.
- Consider a server-side backfill if any historical reward rows need to be
  reconstructed as audit records.
- Remove the remaining local-wallet fallbacks once the migration is fully
  verified in production.
