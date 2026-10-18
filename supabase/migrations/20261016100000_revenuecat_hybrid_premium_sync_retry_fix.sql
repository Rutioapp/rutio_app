begin;

-- A transient reconciliation failure must remain discoverable by the worker.
-- claim_revenuecat_premium_sync sets pending=false while a lease is held;
-- completion must restore pending=true unless the error is permanent.
create or replace function public.complete_revenuecat_premium_sync(
  p_user_id uuid, p_app_id text, p_environment text, p_lease_token uuid,
  p_success boolean, p_error_code text default null
)
returns boolean language plpgsql security definer set search_path = ''
as $$
begin
  update public.revenuecat_premium_sync_queue
     set lease_until = null,
         lease_token = null,
         pending = case
           when p_success then false
           when left(coalesce(p_error_code, ''), 10) = 'PERMANENT:' then false
           else true
         end,
         next_at = case
           when p_success then now() + interval '365 days'
           when left(coalesce(p_error_code, ''), 10) = 'PERMANENT:' then now() + interval '365 days'
           else now() + make_interval(secs => least(
             3600,
             300 * power(2::numeric, least(greatest(attempt_count - 1, 0), 4))
           ))
         end,
         last_error_code = case
           when p_success then null
           else nullif(left(coalesce(p_error_code, 'SYNC_FAILED'), 80), '')
         end,
         updated_at = now()
   where user_id = p_user_id
     and app_id = p_app_id
     and environment = p_environment
     and lease_token = p_lease_token;
  if not found then raise exception 'reconciliation lease lost'; end if;
  return true;
end;
$$;

revoke all on function public.complete_revenuecat_premium_sync(
  uuid, text, text, uuid, boolean, text
) from public, anon, authenticated;
grant execute on function public.complete_revenuecat_premium_sync(
  uuid, text, text, uuid, boolean, text
) to service_role;

commit;
