# Backend Manual Smoke Test Checklist (Phase 9)

Date: April 28, 2026

This checklist validates backend hardening while keeping Rutio local-first.

## Preconditions

1. Build uses valid Supabase env defines (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
2. Use at least two test accounts (User A and User B).
3. Start with clean app install data if possible for one run, then also test with existing local data.

## App flow checks

1. Create account
- Sign up a new account.
- Confirm app reaches authenticated state.
- Confirm no crash if profile row is absent initially.

2. Login
- Sign out and sign back in.
- Confirm local scoped state loads correctly for that account.

3. Logout
- Logout from settings/account.
- Confirm app returns to guest flow and prior authenticated local scope is not shown.

4. Delete account
- Run delete-account flow.
- Confirm local scoped state for deleted user is cleared.
- Confirm guest scope still works.

5. User A/B local state isolation
- Sign in as User A and create/complete data.
- Sign out, sign in as User B.
- Confirm User B does not see User A habits/history/progress/achievements/diary.
- Sign back as User A and confirm A data remains.

6. Habit create/edit/archive/delete
- Create habit.
- Edit habit fields.
- Archive/unarchive as supported.
- Delete habit.
- Confirm local behavior unchanged and no blocking from remote failures.

7. Check habit completion
- Complete and uncomplete a check habit.
- Confirm daily state toggles correctly.

8. Count habit progress
- Increment/decrement/set count values.
- Confirm completion when target reached.

9. Habit logs rows
- For check and count habits, perform today and non-today updates.
- Confirm one row per `(user_id, habit_id, log_date)` with expected value/completion.

10. User progress updates
- Trigger rewards (habit completion and diary reward).
- Confirm `user_progress` snapshot updates.

11. XP and currency events rows
- Confirm event rows insert on reward/spend paths.
- Confirm `currency='ambar'`.

12. Achievement unlock reward once
- Unlock one achievement.
- Confirm XP/currency reward is applied only once locally.
- Reopen app and verify reward does not replay.

13. User achievements rows
- Confirm unlocked achievements are persisted remotely.
- Confirm tier values are technical values (`wood`, `stone`, `bronze`, `silver`, `gold`, `diamond`, `prismaticDiamond`).

14. Diary daily reward once
- Create a valid diary entry.
- Confirm daily diary reward applies once per date.
- Add another same-day entry and confirm no duplicate daily reward.

15. Journal create/edit/delete/backfill
- Create diary entry and confirm remote persistence.
- Edit entry and confirm remote update.
- Delete entry and confirm remote soft delete (`is_deleted=true`).
- Restart/sign in again and confirm backfill marker logic does not duplicate already linked entries.

16. Offline/failed Supabase behavior
- Disable network (or use invalid connection temporarily).
- Perform local habit and diary mutations.
- Confirm local save succeeds and app does not block/crash.
- Re-enable network and verify normal flow resumes.

17. No duplicate rows sanity
- Run SQL checks below after test actions.

## SQL verification queries

Replace `:user_id` with the authenticated user uuid.

### 1) Duplicate habits by identity fields (suspicion check)
```sql
select
  user_id,
  lower(trim(name)) as name_key,
  coalesce(lower(trim(family_id)), '') as family_key,
  coalesce(lower(trim(habit_type)), '') as type_key,
  count(*) as row_count
from public.habits
where user_id = :user_id
group by 1,2,3,4
having count(*) > 1
order by row_count desc, name_key;
```

### 2) Duplicate habit logs (should be zero due unique key)
```sql
select
  user_id,
  habit_id,
  log_date,
  count(*) as row_count
from public.habit_logs
where user_id = :user_id
group by 1,2,3
having count(*) > 1
order by row_count desc, log_date desc;
```

### 3) Duplicate user achievements by logical key (should be zero)
```sql
select
  user_id,
  achievement_id,
  count(*) as row_count
from public.user_achievements
where user_id = :user_id
group by 1,2
having count(*) > 1
order by row_count desc, achievement_id;
```

### 4) Journal duplicate suspicion check (not by date uniqueness)
```sql
select
  user_id,
  entry_date,
  coalesce(local_habit_id, '') as local_habit_id,
  md5(content) as content_hash,
  count(*) as row_count
from public.journal_entries
where user_id = :user_id
  and is_deleted = false
group by 1,2,3,4
having count(*) > 1
order by row_count desc, entry_date desc;
```

### 5) XP event sanity
```sql
select
  source,
  count(*) as row_count,
  sum(amount) as total_amount,
  min(created_at) as first_seen,
  max(created_at) as last_seen
from public.xp_events
where user_id = :user_id
group by source
order by last_seen desc;
```

### 6) Currency event sanity
```sql
select
  currency,
  source,
  count(*) as row_count,
  sum(amount) as total_amount,
  min(created_at) as first_seen,
  max(created_at) as last_seen
from public.currency_events
where user_id = :user_id
group by currency, source
order by last_seen desc;
```

### 7) Progress snapshot sanity
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
where user_id = :user_id;
```

## Notes

- Journal entries can legitimately have multiple rows on the same day.
- Local marker keys are device-local local-first controls, not multi-device sync state.
- If SQL checks fail but app local behavior is correct, prioritize preserving local state and inspect schema constraints/indexes first.
