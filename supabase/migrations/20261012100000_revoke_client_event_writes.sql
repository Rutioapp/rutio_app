begin;

-- xp_events and currency_events are historical/read-only projections for clients.
-- Reward authority remains in the existing server-side reward ledgers and RPCs.
-- Keep service_role available for controlled backfills/reconciliation; this migration
-- only removes client DML and the legacy self-insert policies.
do $$
begin
  if to_regclass('public.xp_events') is not null then
    execute 'revoke insert, update, delete on table public.xp_events from public, anon, authenticated';
    execute 'drop policy if exists xp_events_insert_own on public.xp_events';
  end if;

  if to_regclass('public.currency_events') is not null then
    execute 'revoke insert, update, delete on table public.currency_events from public, anon, authenticated';
    execute 'drop policy if exists currency_events_insert_own on public.currency_events';
  end if;
end;
$$;

commit;
