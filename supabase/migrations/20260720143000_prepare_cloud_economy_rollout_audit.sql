begin;

create extension if not exists pgcrypto;

create table if not exists public.global_cloud_economy_rollout_audit (
  id uuid primary key default gen_random_uuid(),
  migration_name text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  wallet_state text not null,
  source_ambar_balance integer,
  wallet_coins bigint,
  wallet_version bigint,
  balance_delta bigint not null default 0,
  inventory_count integer not null default 0,
  equipped_count integer not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  constraint global_cloud_economy_rollout_audit_migration_name_check
    check (btrim(migration_name) <> ''),
  constraint global_cloud_economy_rollout_audit_wallet_state_check
    check (wallet_state in ('missing', 'preserved', 'created', 'conflict', 'demo')),
  constraint global_cloud_economy_rollout_audit_inventory_count_check
    check (inventory_count >= 0),
  constraint global_cloud_economy_rollout_audit_equipped_count_check
    check (equipped_count >= 0),
  constraint global_cloud_economy_rollout_audit_unique unique (migration_name, user_id, wallet_state)
);

create index if not exists idx_global_cloud_economy_rollout_audit_user_created_at
  on public.global_cloud_economy_rollout_audit (user_id, created_at desc);

alter table public.global_cloud_economy_rollout_audit enable row level security;

revoke all on public.global_cloud_economy_rollout_audit from public, anon, authenticated;

drop policy if exists global_cloud_economy_rollout_audit_select_own
  on public.global_cloud_economy_rollout_audit;
create policy global_cloud_economy_rollout_audit_select_own
  on public.global_cloud_economy_rollout_audit
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create or replace view public.global_cloud_economy_rollout_status as
select
  coalesce(up.user_id, uw.user_id) as user_id,
  case when uw.user_id is null then false else true end as has_wallet,
  uw.coins as wallet_coins,
  uw.version as wallet_version,
  up.ambar_balance as legacy_ambar_balance,
  coalesce(uw.coins, 0) - coalesce(up.ambar_balance, 0) as balance_delta,
  coalesce(inv.inventory_count, 0) as inventory_count,
  coalesce(eq.equipped_count, 0) as equipped_count
from public.user_progress up
full outer join public.user_wallets uw
  on uw.user_id = up.user_id
left join (
  select user_id, count(*)::integer as inventory_count
  from public.user_inventory
  group by user_id
) inv on inv.user_id = coalesce(up.user_id, uw.user_id)
left join (
  select user_id, count(*)::integer as equipped_count
  from public.user_equipped_cosmetics
  group by user_id
) eq on eq.user_id = coalesce(up.user_id, uw.user_id);

revoke all on public.global_cloud_economy_rollout_status from public, anon, authenticated;
grant select on public.global_cloud_economy_rollout_status to authenticated;

comment on table public.global_cloud_economy_rollout_audit is
  'Audit trail for the final cloud economy rollout and reconciliation checks.';

comment on view public.global_cloud_economy_rollout_status is
  'Read-only rollout snapshot comparing legacy ambar_balance with user_wallets.';

commit;
