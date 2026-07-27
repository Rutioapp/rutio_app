-- Read-only preflight for 20260727200000_harden_habit_reward_rpcs_logical_idempotency.sql.
-- Run before applying the migration. Expected result for duplicate/inconsistency
-- checks is zero rows unless the output is intentionally reviewed first.

-- 1) Duplicate apply rows by logical reward identity.
select user_id, habit_id, logical_date_key, count(*) as row_count
from public.habit_currency_reward_ledger
where operation_type = 'apply'
group by user_id, habit_id, logical_date_key
having count(*) > 1;

-- 2) Duplicate reverse rows by logical reward identity.
select user_id, habit_id, logical_date_key, count(*) as row_count
from public.habit_currency_reward_ledger
where operation_type = 'reverse'
group by user_id, habit_id, logical_date_key
having count(*) > 1;

-- 3) Reverse rows without a logical apply.
select r.*
from public.habit_currency_reward_ledger as r
left join public.habit_currency_reward_ledger as a
  on a.user_id = r.user_id
 and a.habit_id = r.habit_id
 and a.logical_date_key = r.logical_date_key
 and a.operation_type = 'apply'
where r.operation_type = 'reverse'
  and a.id is null;

-- 4) Reverse rows whose related_ledger_id does not point to the compatible apply.
select r.*
from public.habit_currency_reward_ledger as r
left join public.habit_currency_reward_ledger as a
  on a.id = r.related_ledger_id
where r.operation_type = 'reverse'
  and (
    a.id is null
    or a.operation_type <> 'apply'
    or a.user_id <> r.user_id
    or a.habit_id <> r.habit_id
    or a.logical_date_key <> r.logical_date_key
  );

-- 5) Request IDs that are duplicated or reused across operation types.
select
  request_id,
  count(*) as row_count,
  array_agg(distinct operation_type order by operation_type) as operation_types
from public.habit_currency_reward_ledger
group by request_id
having count(*) > 1
   or count(distinct operation_type) > 1;

-- 6) Rows where source_id and completion_event_id diverge.
select *
from public.habit_currency_reward_ledger
where source_id <> completion_event_id;

-- 7) Multiple operations by logical identity for review.
select
  user_id,
  habit_id,
  logical_date_key,
  count(*) filter (where operation_type = 'apply') as apply_count,
  count(*) filter (where operation_type = 'reverse') as reverse_count,
  count(*) as total_count
from public.habit_currency_reward_ledger
group by user_id, habit_id, logical_date_key
having count(*) > 1;
