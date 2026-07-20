begin;

create extension if not exists pgcrypto;

create table if not exists public.global_cloud_wallet_backfill_audit (
  user_id uuid primary key references auth.users(id) on delete cascade,
  source_ambar_balance integer not null,
  source_progress_updated_at timestamptz,
  created_wallet_coins bigint not null,
  created_wallet_version bigint not null default 0,
  migration_name text not null,
  migrated_at timestamptz not null default now()
);

alter table public.global_cloud_wallet_backfill_audit
  alter column migrated_at set default now();

revoke all on public.global_cloud_wallet_backfill_audit from public, anon, authenticated;

with candidate_users as (
  select
    up.user_id,
    up.ambar_balance,
    up.updated_at as progress_updated_at
  from public.user_progress up
  where not exists (
      select 1
      from public.user_wallets uw
      where uw.user_id = up.user_id
    )
),
inserted_wallets as (
  insert into public.user_wallets (
    user_id,
    coins,
    version,
    created_at,
    updated_at
  )
  select
    candidate_users.user_id,
    candidate_users.ambar_balance::bigint,
    0,
    now(),
    now()
  from candidate_users
  on conflict (user_id) do nothing
  returning user_id, coins, version
)
insert into public.global_cloud_wallet_backfill_audit (
  user_id,
  source_ambar_balance,
  source_progress_updated_at,
  created_wallet_coins,
  created_wallet_version,
  migration_name,
  migrated_at
)
select
  inserted_wallets.user_id,
  candidate_users.ambar_balance,
  candidate_users.progress_updated_at,
  inserted_wallets.coins,
  inserted_wallets.version,
  '20260718120000_backfill_global_cloud_wallet_from_user_progress',
  now()
from inserted_wallets
join candidate_users using (user_id)
on conflict (user_id) do nothing;

commit;

