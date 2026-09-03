begin;

-- Expand the V1 pools without changing the established content version. This
-- migration is additive and leaves already-finalized snapshots untouched.
insert into app_private.weekly_report_copy_catalog(message_key, family, content_version, sort_order)
select 'weekly_report_' || x.family_key || '_' || lpad(g.n::text, 2, '0'), x.family, 1, g.n
from (values
 ('summary_first_partial','summary_first_partial',8),
 ('summary_provisional','summary_provisional',8),
 ('summary_no_schedule','summary_no_schedule',6),
 ('summary_strong','summary_strong',10), ('summary_good','summary_good',10),
 ('summary_mixed','summary_mixed',10), ('summary_needs_recovery','summary_needs_recovery',10),
 ('summary_improved','summary_improved',8), ('summary_declined','summary_declined',8),
 ('habit_highlighted','habit_highlighted',8), ('habit_stable','habit_stable',8),
 ('habit_needs_attention','habit_needs_attention',8)) as x(family_key, family, max_n)
cross join lateral generate_series(1, x.max_n) as g(n)
on conflict (message_key) do nothing;

-- For observations, the current report pool has priority over historical
-- rotation. If the pool is exhausted, deterministic reuse is allowed.
create or replace function app_private.weekly_report_pick_copy_key(
  p_user_id uuid, p_week_start date, p_family text, p_content_version integer,
  p_habit_id text default null, p_report_id uuid default null
) returns text language plpgsql stable security definer set search_path = '' as $$
declare v_key text; v_seed text;
begin
  v_seed := p_user_id::text || ':' || p_week_start::text || ':' || p_family || ':' || p_content_version::text || ':' || coalesce(p_habit_id,'');
  select c.message_key into v_key
  from app_private.weekly_report_copy_catalog c
  where c.family = p_family and c.content_version = p_content_version
    and not exists (
      select 1 from public.weekly_reports r
      where r.user_id = p_user_id and r.status = 'final'
        and r.week_start_date < p_week_start
        and r.week_start_date >= p_week_start - 28
        and (r.message_keys @> jsonb_build_array(c.message_key)
          or (p_habit_id is not null and exists (
            select 1 from public.weekly_report_habits h
            where h.report_id = r.id and h.habit_id = p_habit_id
              and h.observation_key = c.message_key)))
    )
    and (p_report_id is null or not exists (
      select 1 from public.weekly_report_habits h
      join app_private.weekly_report_copy_catalog used on used.message_key = h.observation_key
      where h.report_id = p_report_id and used.family = p_family
    ))
  order by md5(v_seed || ':' || c.sort_order), c.sort_order limit 1;
  if v_key is null and p_report_id is not null then
    select c.message_key into v_key from app_private.weekly_report_copy_catalog c
    where c.family = p_family and c.content_version = p_content_version
      and not exists (select 1 from public.weekly_report_habits h where h.report_id = p_report_id and h.observation_key = c.message_key)
    order by md5(v_seed || ':' || c.sort_order), c.sort_order limit 1;
  end if;
  if v_key is null then
    select c.message_key into v_key from app_private.weekly_report_copy_catalog c
    where c.family = p_family and c.content_version = p_content_version
    order by md5(v_seed || ':' || c.sort_order), c.sort_order limit 1;
  end if;
  return v_key;
end;
$$;

-- Recompute observation assignment in deterministic habit order after the
-- generator has inserted the complete child set (avoids physical row order).
drop trigger if exists trg_weekly_report_set_habit_observation on public.weekly_report_habits;
create or replace function app_private.weekly_report_assign_observations()
returns trigger language plpgsql security definer set search_path = '' as $$
declare r record; fam text; key text; report_start date; version integer; assigned uuid;
begin
  for assigned in
    select distinct h.report_id
    from public.weekly_report_habits h
    join public.weekly_reports wr on wr.id = h.report_id
    where wr.status = 'provisional'
      and h.observation_key is null
  loop
    select week_start_date, content_version into report_start, version from public.weekly_reports where id = assigned;
    for r in select h.* from public.weekly_report_habits h where h.report_id = assigned order by h.name, h.habit_id loop
      fam := case r.classification when 'highlighted' then 'habit_highlighted' when 'stable' then 'habit_stable' when 'needs_attention' then 'habit_needs_attention' else null end;
      key := case when fam is null then null else app_private.weekly_report_pick_copy_key(r.user_id, report_start, fam, version, r.habit_id, assigned) end;
      update public.weekly_report_habits set observation_key = key where report_id = r.report_id and habit_id = r.habit_id;
    end loop;
  end loop;
  return null;
end;
$$;
create trigger trg_weekly_report_assign_observations
after insert on public.weekly_report_habits
referencing new table as new_table
for each statement execute function app_private.weekly_report_assign_observations();

revoke all on function app_private.weekly_report_pick_copy_key(uuid,date,text,integer,text,uuid) from public,anon,authenticated;
revoke all on function app_private.weekly_report_assign_observations() from public,anon,authenticated;

commit;
