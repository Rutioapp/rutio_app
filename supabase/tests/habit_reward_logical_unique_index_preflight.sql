-- Read-only preflight for
-- 20260727203000_add_habit_reward_logical_unique_index.sql.
-- Run before applying the migration. Duplicate and anomaly checks are expected
-- to return zero rows unless intentionally reviewed first.

-- 1) Current ledger definition.
select
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'habit_currency_reward_ledger'
order by ordinal_position;

-- 2) Constraints currently attached to the ledger.
select
  c.conname as constraint_name,
  c.contype as constraint_type,
  pg_catalog.pg_get_constraintdef(c.oid) as constraint_definition
from pg_catalog.pg_constraint as c
where c.conrelid = 'public.habit_currency_reward_ledger'::regclass
order by c.conname;

-- 3) Indexes currently attached to the ledger.
select
  i.relname as index_name,
  ix.indisunique as is_unique,
  ix.indisprimary as is_primary,
  ix.indisvalid as is_valid,
  ix.indisready as is_ready,
  pg_catalog.pg_get_indexdef(ix.indexrelid) as index_definition
from pg_catalog.pg_index as ix
join pg_catalog.pg_class as i on i.oid = ix.indexrelid
where ix.indrelid = 'public.habit_currency_reward_ledger'::regclass
order by i.relname;

-- 4) Confirm no existing unique index or constraint covers the exact logical identity.
select
  i.relname as index_name,
  ix.indisunique as is_unique,
  pg_catalog.pg_get_indexdef(ix.indexrelid) as index_definition
from pg_catalog.pg_index as ix
join pg_catalog.pg_class as i on i.oid = ix.indexrelid
where ix.indrelid = 'public.habit_currency_reward_ledger'::regclass
  and ix.indisunique
  and pg_catalog.pg_get_indexdef(ix.indexrelid) ilike '%(user_id, operation_type, habit_id, logical_date_key)%';

-- 5) Duplicate logical operations that would block the unique index.
select
  user_id,
  operation_type,
  habit_id,
  logical_date_key,
  count(*) as row_count
from public.habit_currency_reward_ledger
group by
  user_id,
  operation_type,
  habit_id,
  logical_date_key
having count(*) > 1;

-- 6) Incomplete logical identities. Expected: zero rows.
select *
from public.habit_currency_reward_ledger
where user_id is null
   or operation_type is null
   or habit_id is null
   or logical_date_key is null
   or pg_catalog.btrim(logical_date_key) = '';

-- 7) Non-canonical logical dates. Expected: zero rows.
with date_parts as materialized (
  select
    l.*,
    case
      when l.logical_date_key ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
      then split_part(l.logical_date_key, '-', 1)::integer
      else null
    end as parsed_year,
    case
      when l.logical_date_key ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
      then split_part(l.logical_date_key, '-', 2)::integer
      else null
    end as parsed_month,
    case
      when l.logical_date_key ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
      then split_part(l.logical_date_key, '-', 3)::integer
      else null
    end as parsed_day
  from public.habit_currency_reward_ledger as l
),
month_validation as materialized (
  select
    date_parts.*,
    case
      when parsed_year between 1 and 9999
       and parsed_month between 1 and 12
       and parsed_day between 1 and 31
      then pg_catalog.make_date(parsed_year, parsed_month, 1)
      else null
    end as month_start
  from date_parts
),
validated_dates as (
  select
    month_validation.*,
    case
      when month_start is not null
       and parsed_day <= extract(
         day from month_start + interval '1 month - 1 day'
       )::integer
      then pg_catalog.make_date(
        parsed_year,
        parsed_month,
        parsed_day
      )
      else null
    end as parsed_logical_date
  from month_validation
)
select *
from validated_dates
where parsed_logical_date is null
   or logical_date_key <> parsed_logical_date::text;

-- 8) Current operation types.
select operation_type, count(*)
from public.habit_currency_reward_ledger
group by operation_type
order by operation_type;

-- 9) Current source types.
select source_type, count(*)
from public.habit_currency_reward_ledger
group by source_type
order by source_type;
