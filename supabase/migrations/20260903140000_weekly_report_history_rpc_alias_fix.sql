-- Forward repair for the already-applied Weekly Report read API.
-- The original function's JSON builder referenced r outside its subquery;
-- the row available at that level is x. Contract and security are unchanged.

create or replace function public.list_my_weekly_reports(
  p_before_week_start date default null, p_limit integer default 20
)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
    'reportId', x.id, 'weekStartDate', x.week_start_date, 'weekEndDate', x.week_end_date,
    'status', x.status, 'completionRate', x.completion_rate,
    'completedCount', x.completed_count, 'scheduledCount', x.scheduled_count,
    'firstPartialWeek', x.is_first_partial_week,
    'refreshedAt', x.refreshed_at, 'finalizedAt', x.finalized_at
  ) order by x.week_start_date desc, x.id desc) from (
    select r.* from public.weekly_reports r
    where r.user_id = v_user_id
      and (p_before_week_start is null or r.week_start_date < p_before_week_start)
    order by r.week_start_date desc, r.id desc
    limit v_limit
  ) x), '[]'::jsonb);
end;
$$;
