# Supabase User Achievements - Phase 7B (Local Unlock Persistence)

Date: April 28, 2026  
Branch: `feature/supabase-user-achievements`

## Goal

Persist locally unlocked achievements to Supabase `public.user_achievements` with best-effort, non-blocking writes while preserving Rutio's local-first behavior.

## Local-First Rules (Preserved)

- Local unlock state remains source of truth.
- Local reward idempotency remains source of truth from Phase 7A (`rewardAppliedAchievementIds`).
- Remote persistence is fire-and-forget, best-effort, and never blocks unlock UI or popup flow.
- No remote-to-local achievement download/merge in this phase.
- No remote-triggered reward re-application in this phase.

## Recommended SQL (Schema + Constraints)

```sql
create extension if not exists pgcrypto;

create table if not exists public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null,
  family_id text null,
  tier text not null,
  unlocked_at timestamptz not null default now(),
  reward_xp integer not null default 0,
  reward_ambar integer not null default 0,
  reward_applied boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, achievement_id)
);
```

## Recommended `updated_at` Trigger

```sql
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_user_achievements_set_updated_at
  on public.user_achievements;

create trigger trg_user_achievements_set_updated_at
before update on public.user_achievements
for each row
execute function public.set_updated_at();
```

## Recommended Indexes

```sql
create index if not exists idx_user_achievements_user_unlocked_at
  on public.user_achievements (user_id, unlocked_at desc);

create index if not exists idx_user_achievements_family_id
  on public.user_achievements (family_id);
```

## Recommended RLS Policies

```sql
alter table public.user_achievements enable row level security;

create policy if not exists "user_achievements_select_own"
on public.user_achievements
for select
to authenticated
using (auth.uid() = user_id);

create policy if not exists "user_achievements_insert_own"
on public.user_achievements
for insert
to authenticated
with check (auth.uid() = user_id);

create policy if not exists "user_achievements_update_own"
on public.user_achievements
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
```

## What Rutio Writes

When a new local unlock is saved, Rutio upserts one row per achievement id:

- `achievement_id`
- `family_id` (nullable)
- `tier`
- `unlocked_at`
- `reward_xp`
- `reward_ambar`
- `reward_applied` (from local `rewardAppliedAchievementIds`)

Conflict target:

- `on conflict (user_id, achievement_id)` upsert
- If PostgREST returns `42P10` for conflict target resolution, Rutio uses a safe fallback:
  - `update ... where user_id + achievement_id`
  - if no row updated, `insert`

`user_id` is always forced from the active Supabase session server-side payload generation; local UI/user state ids are not trusted for write scope.

## Backfill Behavior (One-Time Per User)

Backfill API:

- `syncExistingLocalAchievementsOnce({force = false})`

Marker:

- `userState.meta.supabaseAchievementsBackfillCompletedByUser[userId] = true`

Rules:

- Runs only when authenticated Supabase session exists and local scoped `userId` matches that session.
- Uploads all local unlocked achievements.
- Does not create XP/currency events.
- Does not apply rewards.
- Marks completion only when:
  - processing finished with `failedCount == 0`, and
  - there were actual candidates, or local unlocked achievements are truly zero.
- Partial failure keeps marker unset so retries can happen later.
- If a completion marker exists but local unlocked achievements are present and remote row count is zero, Rutio safely retries backfill automatically.

## Missing Table/Schema Behavior

- If `public.user_achievements` is missing (or expected schema is missing), repository returns safe `RepositoryError` and no crash is thrown into UI/store flows.
- Service handles errors with debug-only logging.
- Local unlock and local rewards continue normally.
- Backfill remains incomplete (marker not set) until backend schema is ready and a later retry succeeds.
- Temporary schema suppression (`schemaUnavailable`) is only enabled for true schema/object cases:
  - `PGRST205` / `42P01` (table/relation missing)
  - `PGRST204` / `42703` (expected column missing or stale schema cache)
- It is not enabled for:
  - RLS permission errors (`42501`)
  - constraint/value errors (for example tier check)
  - generic payload/unknown failures
  - network failures

## Force Retry Path

Public store API:

- `syncExistingLocalAchievementsOnce(force: true)`

Behavior:

- Ignores local completion marker.
- Re-attempts upload for all currently unlocked local achievements.
- Keeps local-only reward ownership (no XP/currency event writes, no reward re-apply).
- Uses upsert conflict target `(user_id, achievement_id)`.
- Marks completion only under the same successful conditions described above.

## Debug Logging Added

In `kDebugMode`, Phase 7B emits diagnostic logs for:

- unlock sync trigger and achievement ids/tiers/family ids
- auth bootstrap start/return of achievements backfill call
- backfill precheck state:
  - marker status
  - raw local unlocked count
  - parsed local unlocked count
- candidate counts and summary totals
- repository upsert payload (user id redacted), success, and Postgrest failure code/message
- full PostgREST fields when available:
  - `code`
  - `message`
  - `details`
  - `hint`

Common no-row reason:

- new unlock sync only fires for newly unlocked achievements in the current session;
  previously unlocked achievements rely on backfill.

Additional common no-row checks:

- verify unique constraint exists on `(user_id, achievement_id)`
- verify RLS policies allow `insert` and `update` with `auth.uid() = user_id`
- verify tier value sent is one of:
  - `wood`, `stone`, `bronze`, `silver`, `gold`, `diamond`, `prismaticDiamond`

## Reward Idempotency Boundary

Phase 7B does not change reward rules:

- Rewards are applied locally once (Phase 7A) based on local idempotency marker.
- Remote rows are persistence records, not reward triggers.
- No retroactive reward grant from remote rows.

## Deferred to Future Multi-Device Sync

- Remote achievement download into local state.
- Conflict resolution between local and remote unlock ledgers.
- Cross-device reconciliation strategy for reward-applied semantics.
