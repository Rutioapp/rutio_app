-- Isolated PostgreSQL integration test for 20261013100000.
-- Never run against staging or production. Requires the prior RevenueCat
-- migrations plus this corrective migration; all data is rolled back.
begin;

do $$
declare
  v_user uuid := gen_random_uuid();
  v_new_user uuid := gen_random_uuid();
  v_cancel_user uuid := gen_random_uuid();
  v_t0 timestamptz := '2026-01-01 00:00:00+00';
  v_t1 timestamptz := '2026-01-01 01:00:00+00';
  v_t2 timestamptz := '2026-01-01 02:00:00+00';
  v_t3 timestamptz := '2026-01-01 03:00:00+00';
  v_t4 timestamptz := '2026-01-01 04:00:00+00';
  v_result boolean;
  v_state public.revenuecat_entitlement_state%rowtype;
  v_new_state public.revenuecat_entitlement_state%rowtype;
  v_cancel_state public.revenuecat_entitlement_state%rowtype;
begin
  insert into auth.users (id, email)
  values (v_user, 'temporal-precedence-' || txid_current()::text || '@example.invalid');
  insert into auth.users (id, email)
  values (v_new_user, 'temporal-new-' || txid_current()::text || '@example.invalid');
  insert into auth.users (id, email)
  values (v_cancel_user, 'temporal-cancel-' || txid_current()::text || '@example.invalid');

  v_result := public.apply_revenuecat_entitlement_v2(
    v_user, v_user::text, true, null, v_t2 + interval '1 day', 'premium', null,
    'SANDBOX', null, 'v1-authoritative-1', v_t1, 'test-app', 'backfill', v_t1, true);
  if not v_result then raise exception 'authoritative seed was not applied'; end if;

  -- API v2/local observation is unversioned: it cannot revoke or replace the
  -- active state, even when its local observation appears newer.
  v_result := public.apply_revenuecat_entitlement_v2(
    v_user, v_user::text, false, null, null, 'premium', null, 'SANDBOX',
    v_t2, 'webhook-v2', v_t2, 'test-app', 'webhook', v_t2, true);
  select * into v_state from public.revenuecat_entitlement_state where user_id = v_user;
  if v_result or not v_state.is_active or not v_state.reconciliation_required
     or v_state.last_conflict_code <> 'SNAPSHOT_CLOCK_MISMATCH' then
    raise exception 'unversioned/cross-clock snapshot changed entitlement';
  end if;
  raise notice 'PASS unversioned snapshot preserves active entitlement';

  -- Older v1 observations are ignored without creating a conflict.
  v_result := public.apply_revenuecat_entitlement_v2(
    v_user, v_user::text, false, null, null, 'premium', null, 'SANDBOX',
    null, 'v1-authoritative-old', v0, 'test-app', 'backfill', v0, true);
  if v_result then raise exception 'older observed snapshot applied'; end if;
  raise notice 'PASS older observed snapshot ignored';

  -- Same timestamp with a different event is ambiguous and preserves access.
  v_result := public.apply_revenuecat_entitlement_v2(
    v_user, v_user::text, false, null, null, 'premium', null, 'SANDBOX',
    null, 'v1-authoritative-tie', v_t1, 'test-app', 'backfill', v_t1, true);
  select * into v_state from public.revenuecat_entitlement_state where user_id = v_user;
  if v_result or not v_state.is_active or v_state.last_conflict_code <> 'SNAPSHOT_VERSION_TIE' then
    raise exception 'equal observed snapshot did not fail closed';
  end if;
  raise notice 'PASS equal observed snapshot requires reconciliation';

  -- A complete later authoritative reconciliation is the recovery path.
  v_result := public.apply_revenuecat_entitlement_v2(
    v_user, v_user::text, false, null, null, 'premium', null, 'SANDBOX',
    null, 'reconciliation-1', v_t2, 'test-app', 'reconciliation', v_t2, true);
  select * into v_state from public.revenuecat_entitlement_state where user_id = v_user;
  if not v_result or v_state.is_active or v_state.reconciliation_required then
    raise exception 'authoritative reconciliation did not recover';
  end if;
  raise notice 'PASS authoritative reconciliation recovers state';

  if has_function_privilege('anon', 'public.apply_revenuecat_entitlement_v2(uuid,text,boolean,timestamptz,timestamptz,text,text,text,timestamptz,text,timestamptz,text,text,timestamptz,boolean)', 'EXECUTE')
     or has_function_privilege('authenticated', 'public.apply_revenuecat_entitlement_v2(uuid,text,boolean,timestamptz,timestamptz,text,text,text,timestamptz,text,timestamptz,text,text,timestamptz,boolean)', 'EXECUTE')
     or not has_function_privilege('service_role', 'public.apply_revenuecat_entitlement_v2(uuid,text,boolean,timestamptz,timestamptz,text,text,text,timestamptz,text,timestamptz,text,text,timestamptz,boolean)', 'EXECUTE') then
    raise exception 'projection EXECUTE privileges are not restricted correctly';
  end if;
  if not exists (select 1 from pg_class where oid = 'public.revenuecat_entitlement_state'::regclass and relrowsecurity) then
    raise exception 'entitlement state RLS is not enabled';
  end if;
  raise notice 'PASS service-role-only execution and RLS';

  -- A new v2 purchase is observed but cannot activate Premium without a
  -- versioned/reconciliation path. A duplicate event remains idempotent.
  v_result := public.apply_revenuecat_entitlement_v2(
    v_new_user, v_new_user::text, true, null, v_t4 + interval '1 day', 'premium', null,
    'SANDBOX', v_t1, 'purchase-v2', v_t1, 'test-app', 'webhook', null, false);
  select * into v_new_state from public.revenuecat_entitlement_state where user_id = v_new_user;
  if v_result or v_new_state.is_active is distinct from false
     or v_new_state.reconciliation_required is distinct from true then
    raise exception 'new v2 purchase activated without reliable version';
  end if;
  v_result := public.apply_revenuecat_entitlement_v2(
    v_new_user, v_new_user::text, false, null, null, 'premium', null,
    'SANDBOX', v_t1, 'purchase-v2', v_t1, 'test-app', 'webhook', null, false);
  if v_result then raise exception 'duplicate webhook was not idempotent'; end if;
  raise notice 'PASS new purchase and duplicate webhook remain safe';

  -- A later complete v1 observation models a renewal, then a legitimate
  -- expiry. These are observation-order tests, not proof of remote ordering.
  v_result := public.apply_revenuecat_entitlement_v2(
    v_user, v_user::text, true, null, v_t4 + interval '1 day', 'premium', null,
    'SANDBOX', null, 'renewal-v1', v_t3, 'test-app', 'backfill', v_t3, true);
  if not v_result then raise exception 'renewal observation was not applied'; end if;
  v_result := public.apply_revenuecat_entitlement_v2(
    v_user, v_user::text, false, null, v_t4, 'premium', null,
    'SANDBOX', null, 'expiry-v1', v_t4, 'test-app', 'backfill', v_t4, true);
  select * into v_state from public.revenuecat_entitlement_state where user_id = v_user;
  if not v_result or v_state.is_active then raise exception 'legitimate expiry was not applied'; end if;
  raise notice 'PASS renewal and legitimate expiry';

  -- Cancellation with access retained must not revoke before the known end.
  v_result := public.apply_revenuecat_entitlement_v2(
    v_cancel_user, v_cancel_user::text, true, null, v_t4 + interval '1 day', 'premium', null,
    'SANDBOX', null, 'cancel-seed', v_t1, 'test-app', 'backfill', v_t1, true);
  v_result := public.apply_revenuecat_entitlement_v2(
    v_cancel_user, v_cancel_user::text, true, null, v_t4 + interval '1 day', 'premium', null,
    'SANDBOX', v_t2, 'cancel-current', v_t2, 'test-app', 'backfill', v_t2, true);
  select * into v_cancel_state from public.revenuecat_entitlement_state where user_id = v_cancel_user;
  if not v_result or not v_cancel_state.is_active then raise exception 'cancellation-with-access was revoked'; end if;
  raise notice 'PASS cancellation preserves current-period access';
end;
$$;

rollback;
