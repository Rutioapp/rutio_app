# Supabase User Progress - Phase 6 Foundation

Date: April 27, 2026  
Branch: `feature/supabase-user-progress`

## Goal

Persist local XP, level, and Ambar state plus new reward/spend events to Supabase with best-effort writes and no change to existing local-first gameplay behavior.

## Confirmed Supabase Schema Used

### `public.user_progress`

- `user_id`
- `level`
- `total_xp`
- `current_level_xp`
- `next_level_xp`
- `ambar_balance`
- `total_ambar_earned`
- `total_ambar_spent`

### `public.xp_events`

- `user_id`
- `amount`
- `source`
- `source_id`
- `description`

Allowed `source` values used by the app:

- `habit_completed`
- `habit_count_progress`
- `achievement_unlocked`
- `level_bonus`
- `migration`
- `system`

### `public.currency_events`

- `user_id`
- `amount`
- `currency`
- `source`
- `source_id`
- `description`

Currency writes are normalized to `ambar`.

Allowed `source` values used by the app:

- `habit_completed`
- `achievement_unlocked`
- `shop_purchase`
- `refund`
- `migration`
- `system`

## Mapping Used

### `user_progress`

- local `progression.level` -> `level`
- local `progression.xp` -> `total_xp`
- `progression.xp % 100` -> `current_level_xp`
- `max(1, 100 - (progression.xp % 100))` -> `next_level_xp`
- local `wallet.coins` -> `ambar_balance`

Totals:

- `total_ambar_earned` = existing remote value + known positive currency delta
- `total_ambar_spent` = existing remote value + known spend delta

If current remote totals cannot be fetched, sync still continues with safe non-negative values.

## Source Mapping

Internal source -> DB source:

- `habit_completion` -> `habit_completed`
- `habit_completed` -> `habit_completed`
- `habit_count_progress` -> `habit_count_progress` for XP events
- `habit_count_progress` -> `habit_completed` for currency events
- `shop_purchase` -> `shop_purchase`
- `achievement` -> `achievement_unlocked`
- `achievement_unlocked` -> `achievement_unlocked`
- `migration` -> `migration`
- `system` -> `system`
- unknown -> `system`

## Event Insert Fallback

Fallback keeps required non-null columns and uses valid source/currency values:

- XP event fallback payload: `{ user_id, amount, source }`
- Currency event fallback payload: `{ user_id, amount, currency: 'ambar', source }`

## Trigger Points

After local mutation save succeeds:

1. Habit reward flows in `_setCountHabitValue` and `_completeHabit`
2. Shop spend flow in `_buyItem`

Each trigger performs best-effort remote writes:

- `user_progress` upsert
- `xp_events` insert when XP delta is positive
- `currency_events` insert when currency delta is non-zero

No remote write failure blocks local success.

## Debug Logging

`kDebugMode` logs include:

- reward sync trigger with XP/currency deltas
- `user_progress` payload keys/values (user id redacted)
- `xp_events` payload keys/values
- `currency_events` payload keys/values
- insert/upsert success or failure

No emails, tokens, or keys are logged.

## Scope Deferred Beyond Phase 6

- remote-to-local progress merge
- multi-device conflict resolution
- achievements remote persistence and reward idempotency (Phase 7)
- diary/journal reward-event integration
