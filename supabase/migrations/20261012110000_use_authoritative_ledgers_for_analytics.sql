begin;

-- Economic analytics consume server-authoritative ledgers. Legacy event tables
-- remain readable for history but are not a client write path.
create or replace view public.analytics_economic_movements as
select l.user_id, l.created_at, l.request_id, l.operation_type,
  l.source_type, l.source_id,
  (case when l.operation_type = 'apply'
    then l.base_xp + l.bonus_xp
    else -(l.base_xp + l.bonus_xp) end)::bigint as xp_delta,
  l.coin_delta::bigint as ambar_delta
from public.habit_currency_reward_ledger l
union all
select l.user_id, l.created_at, l.request_id, l.operation_type,
  l.source_type, l.source_id, 0::bigint as xp_delta,
  l.coin_delta::bigint as ambar_delta
from public.achievement_level_reward_ledger l
union all
select l.user_id, l.created_at, l.request_id, l.operation_type,
  l.source_type, l.source_id, l.xp_delta::bigint,
  l.coin_delta::bigint as ambar_delta
from public.mystery_box_opening_ledger l
union all
select l.user_id, l.created_at, l.request_id, l.operation as operation_type,
  'shop_purchase'::text as source_type, l.item_id as source_id,
  0::bigint as xp_delta, l.coins_delta::bigint as ambar_delta
from public.shop_ledger l
where l.operation = 'purchase';

comment on view public.analytics_economic_movements is
  'Internal/admin analytics only. Normalized authoritative economic movements; excludes client-write legacy event mirrors.';
revoke all on public.analytics_economic_movements from public, anon, authenticated;
grant select on public.analytics_economic_movements to service_role;

create or replace view public.analytics_daily_active_users as
with activity_events as (
  select h.user_id, h.created_at::date as activity_date from public.habits h
  union all select hl.user_id, hl.created_at::date from public.habit_logs hl
  union all select hl.user_id, hl.updated_at::date from public.habit_logs hl
  union all select je.user_id, je.created_at::date from public.journal_entries je
    where coalesce(je.is_deleted, false) = false
  union all select je.user_id, je.updated_at::date from public.journal_entries je
    where coalesce(je.is_deleted, false) = false
  union all select ua.user_id, ua.unlocked_at::date from public.user_achievements ua
  union all select ua.user_id, ua.created_at::date from public.user_achievements ua
)
select ae.activity_date, count(distinct ae.user_id)::bigint as active_users
from activity_events ae
where ae.activity_date is not null
group by ae.activity_date
order by ae.activity_date;

comment on view public.analytics_daily_active_users is
  'Internal/admin analytics only. DAU from canonical product activity; economic events are not activity proxies.';

create or replace view public.analytics_xp_generated_by_day as
select m.created_at::date as event_date,
  sum(case when m.xp_delta > 0 then m.xp_delta else 0 end)::bigint as xp_generated,
  count(*)::bigint as events_count,
  count(distinct m.user_id)::bigint as unique_users
from public.analytics_economic_movements m
group by m.created_at::date
order by event_date;

comment on view public.analytics_xp_generated_by_day is
  'Internal/admin analytics only. Positive XP movements from authoritative reward ledgers.';

create or replace view public.analytics_ambar_by_day as
select m.created_at::date as event_date,
  sum(case when m.ambar_delta > 0 then m.ambar_delta else 0 end)::bigint as ambar_generated,
  sum(case when m.ambar_delta < 0 then -m.ambar_delta else 0 end)::bigint as ambar_spent,
  sum(m.ambar_delta)::bigint as net_ambar,
  count(*)::bigint as events_count,
  count(distinct m.user_id)::bigint as unique_users
from public.analytics_economic_movements m
group by m.created_at::date
order by event_date;

comment on view public.analytics_ambar_by_day is
  'Internal/admin analytics only. Ambar movements from authoritative reward and shop ledgers.';
revoke all on public.analytics_daily_active_users from public, anon, authenticated;
revoke all on public.analytics_xp_generated_by_day from public, anon, authenticated;
revoke all on public.analytics_ambar_by_day from public, anon, authenticated;
grant select on public.analytics_daily_active_users,
  public.analytics_xp_generated_by_day,
  public.analytics_ambar_by_day to service_role;

commit;
