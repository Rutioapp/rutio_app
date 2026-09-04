begin;

do $$
declare
  v_source text;
begin
  if to_regprocedure(
       'app_private.weekly_report_pick_copy_key(uuid,date,text,integer,text)'
     ) is not null then
    raise exception 'obsolete five-argument copy-key overload must be removed';
  end if;
  if to_regprocedure(
       'app_private.weekly_report_pick_copy_key(uuid,date,text,integer,text,uuid)'
     ) is null then
    raise exception 'six-argument copy-key overload must remain';
  end if;

  select prosrc into v_source
  from pg_proc
  where oid = 'public.refresh_my_weekly_report(date)'::regprocedure;
  if v_source not like '%auth.uid()%'
     or v_source not like '%weekly_report_activations%'
     or v_source not like '%only the current eligible week may be refreshed%'
     or v_source not like '%generate_or_refresh_weekly_report%' then
    raise exception 'public refresh must remain authenticated and current-week-only';
  end if;
end;
$$;

rollback;
