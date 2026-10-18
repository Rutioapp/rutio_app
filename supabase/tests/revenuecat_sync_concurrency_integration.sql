-- Dynamic integration test for the post-Stage-A RevenueCat lease migration.
-- Run only against an isolated PostgreSQL database after applying Stage A and
-- 20261012152000. The transaction rolls back all test rows at the end.
-- This file is intentionally not a production/staging check.

begin;

do $$
declare
  v_event_id text := 'integration-revenuecat-claim-first-' || txid_current()::text;
  v_first jsonb;
  v_duplicate jsonb;
  v_failed_retry jsonb;
  v_abandoned_retry jsonb;
  v_first_token uuid;
  v_new_token uuid;
begin
  v_first := public.claim_revenuecat_webhook_event(
    v_event_id, 'TEST', null, now(), 'PRODUCTION');
  if v_first->>'status' <> 'claimed'
     or nullif(v_first->>'lease_token', '') is null then
    raise exception 'first claim did not return claimed with a token: %', v_first;
  end if;
  v_first_token := (v_first->>'lease_token')::uuid;

  v_duplicate := public.claim_revenuecat_webhook_event(
    v_event_id, 'TEST', null, now(), 'PRODUCTION');
  if v_duplicate->>'status' <> 'in_progress' then
    raise exception 'live duplicate was not in_progress: %', v_duplicate;
  end if;

  perform public.finalize_revenuecat_webhook_event(
    v_event_id, v_first_token, 'failed', 'integration_failure');
  v_failed_retry := public.claim_revenuecat_webhook_event(
    v_event_id, 'TEST', null, now(), 'PRODUCTION');
  if v_failed_retry->>'status' <> 'claimed' then
    raise exception 'failed event was not reclaimable: %', v_failed_retry;
  end if;
  v_new_token := (v_failed_retry->>'lease_token')::uuid;

  begin
    perform public.finalize_revenuecat_webhook_event(
      v_event_id, v_first_token, 'processed', null);
    raise exception 'stale lease unexpectedly finalized a newer claim';
  exception when others then
    if sqlerrm <> 'webhook lease lost' then raise; end if;
  end;

  update public.revenuecat_webhook_events
     set processing_lease_until = now() - interval '1 second'
   where event_id = v_event_id;
  v_abandoned_retry := public.claim_revenuecat_webhook_event(
    v_event_id, 'TEST', null, now(), 'PRODUCTION');
  if v_abandoned_retry->>'status' <> 'claimed'
     or (v_abandoned_retry->>'lease_token')::uuid = v_new_token then
    raise exception 'expired lease was not replaced: %', v_abandoned_retry;
  end if;

  perform public.finalize_revenuecat_webhook_event(
    v_event_id, (v_abandoned_retry->>'lease_token')::uuid, 'processed', null);
  if (public.claim_revenuecat_webhook_event(
        v_event_id, 'TEST', null, now(), 'PRODUCTION')->>'status') <> 'processed' then
    raise exception 'processed event was claimable again';
  end if;
end;
$$;

rollback;

-- Concurrency requirement: execute the first claim statement from two
-- separate PostgreSQL sessions with the same event_id while both sessions are
-- allowed to commit. Exactly one result must be claimed and the other must be
-- in_progress; the unique event_id constraint plus row lock provide that
-- serialization. This cannot be reproduced by a single-session SQL runner.
