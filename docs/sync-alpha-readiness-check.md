# Sync Alpha Readiness Check

Date: 2026-06-26
Branch: `qa/sync-alpha-readiness-check`

## Goal

This document is the final alpha-readiness checklist for Rutio's completed sync foundation across Diary V2, Habits, Auth scope separation, and User Progress restore.

This is a closure and verification phase only.

It does not add features, alter UI/design, change Supabase schema, or intentionally change sync behavior.

## 1. Scope

This checklist covers:

- Diary V2 sync
- Habits sync
- User progress restore
- Auth, demo, and guest scope separation
- Cache-clear and clean-device behavior

Validated sync foundation in scope:

- Diary V2 local -> Supabase push
- Diary V2 Supabase -> local conservative pull and merge
- Diary V2 manual pull-to-refresh
- Diary V2 controlled sync policy
- DailyMood stored separately from `DiaryEntry.mood`
- DailyMood month preview sync behavior
- Habits local -> Supabase push
- Habits Supabase -> local conservative pull and merge
- Home manual pull-to-refresh
- Habits controlled sync policy
- Fail-closed user scope protection
- Mixed-user or missing-user remote habit rows abort merge
- Remote missing habit data does not delete local data
- Remote habit pull does not trigger XP, rewards, or confetti
- `user_progress` remote restore from Supabase
- Clean-device or cache-clear login restores level, XP, and coins
- Progress restore happens before local-to-remote backfill
- Template `level=1/xp=0/coins=0` should not overwrite an existing remote `user_progress` row

## 2. Automated Validation Commands

Run these focused commands from the project root.

### Static analysis

```bash
flutter analyze
```

### Diary V2 focused tests

```bash
flutter test test/stores/user_state_store_diary_sync_test.dart
flutter test test/screens/diary_v2/diary_v2_screen_refresh_test.dart
flutter test test/screens/diary_v2/diary_v2_daily_mood_resolver_test.dart
flutter test test/data/repositories/diary_v2_supabase_repository_test.dart
```

### Habits focused tests

```bash
flutter test test/stores/user_state_store_habits_remote_pull_test.dart
flutter test test/screens/home/home_screen_refresh_test.dart
flutter test test/data/repositories/habit_remote_fetch_repository_test.dart
```

### User progress focused tests

```bash
flutter test test/stores/user_state_store_user_progress_restore_test.dart
flutter test test/stores/user_state_store_reward_persistence_test.dart
flutter test test/data/repositories/user_progress_repository_test.dart
```

Notes:

- Prefer these focused checks over full-suite runs during alpha readiness verification.
- If this phase remains documentation-only, `flutter analyze` is sufficient for acceptance.
- If any related Dart test is changed in this phase, run only the affected focused test file(s).

## 3. Manual QA Checklist

Use at least one authenticated test account. Use two accounts for scope-separation verification where possible.

### A. Clean-device login

- Clear app storage or uninstall and reinstall the app.
- Start the app with:

```bash
flutter run --dart-define-from-file=dart_defines/dev.json
```

- Sign in with an account that already has remote `user_progress` data.
- Verify level, XP, and coins restore from Supabase.
- Verify the restored values appear before any local template reset could backfill.
- Verify no template `level=1/xp=0/coins=0` snapshot overwrites an existing remote `user_progress` row.

### B. Habits sync

- Verify Home opens without duplicating habits.
- Verify controlled sync does not loop or repeatedly re-run on its own.
- Verify Home pull-to-refresh works.
- Verify remote empty habit results do not delete existing local habits.
- Verify mixed-user or missing-user remote habit data fails closed and aborts merge.
- Verify only current-user habits appear after refresh.
- Verify remote pull does not trigger XP, rewards, or confetti.

### C. Diary V2 sync

- Create a diary entry and verify it persists normally.
- Edit a diary entry and verify the update persists normally.
- Delete a diary entry and verify delete behavior remains correct.
- Create or update a `DailyMood`.
- Verify `DiaryEntry.mood` and `DailyMood.mood` remain separate concepts.
- Verify month preview uses `DailyMood`.
- Verify pull-to-refresh brings remote diary entries and daily moods into local state without duplicates.
- Verify a local diary entry that is not present remotely is not deleted by conservative pull logic.

### D. Scope separation

- Verify guest scope does not pull authenticated remote data.
- Verify demo scope does not pull authenticated remote data.
- Verify an authenticated user does not read demo local state.
- Verify switching between different authenticated users does not mix habits, diary data, or progress.

### E. Failure cases

- Verify no-auth behavior stays safe and non-destructive.
- Verify network or Supabase failure keeps local data intact.
- Verify an unsafe remote habits response aborts merge.
- Verify missing remote data does not clear local state.

## 4. Supabase SQL Diagnostics

These queries are optional and intended for development/debug verification only.

Replace `<USER_ID>` with the authenticated user's UUID.

### Count habits by user_id

```sql
select
  user_id,
  count(*) as habit_count
from public.habits
group by user_id
order by habit_count desc, user_id;
```

### Inspect current user's habits

```sql
select
  id,
  user_id,
  name,
  family_id,
  habit_type,
  created_at,
  updated_at
from public.habits
where user_id = '<USER_ID>'
order by updated_at desc nulls last, created_at desc nulls last;
```

### Inspect current user's habit_logs

```sql
select
  id,
  user_id,
  habit_id,
  log_date,
  value,
  completed,
  created_at,
  updated_at
from public.habit_logs
where user_id = '<USER_ID>'
order by log_date desc, updated_at desc nulls last;
```

### Inspect user_progress for current user

```sql
select
  user_id,
  level,
  total_xp,
  current_level_xp,
  next_level_xp,
  ambar_balance,
  total_ambar_earned,
  total_ambar_spent,
  updated_at
from public.user_progress
where user_id = '<USER_ID>';
```

### Verify no habits or logs remain for a user after cleanup if needed

```sql
select 'habits' as table_name, count(*) as row_count
from public.habits
where user_id = '<USER_ID>'
union all
select 'habit_logs' as table_name, count(*) as row_count
from public.habit_logs
where user_id = '<USER_ID>';
```

## 5. Known Limitations / Future Work

Intentionally out of scope for sync alpha readiness:

- No full conflict resolution UI
- No multi-device real-time sync
- No remote delete tombstone strategy beyond conservative local preservation
- No `journal_entries` legacy migration
- No habit contamination auto-cleanup for local rows with unknown ownership
- No advanced server-side repair tooling
- No analytics or telemetry sync dashboard

## 6. Exit Criteria

Sync alpha readiness is considered passed when all of the following are true:

- All focused validation tests that are run for this phase pass
- `flutter analyze` passes
- Clean-device login restores progress from Supabase
- Habits refresh does not import another user's data
- Diary refresh does not duplicate entries or mix daily mood with entry mood
- Remote errors do not clear local state
- Remote pulls do not trigger XP, rewards, or confetti
- The manual QA checklist has been completed

## Acceptance Notes

- `docs/sync-alpha-readiness-check.md` must exist.
- The phase remains documentation-first unless a tiny, clearly related bug is discovered.
- No UI changes are required for this checklist.
- No Supabase schema changes are required for this checklist.
- No feature behavior changes are required for this checklist.
