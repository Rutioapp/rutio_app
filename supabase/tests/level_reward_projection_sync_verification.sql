-- RUTIO — administrative read-only verification for level reward projection.
-- Run before and after a positive Staging claim. Never run against Production.

with target as (
  select '78d7f999-8f36-466c-aa3f-21d81b0510bf'::uuid as user_id
), reward_totals as (
  select user_id,
         coalesce(sum(coin_delta) filter (where coin_delta > 0), 0)::bigint as reward_coins
  from public.achievement_level_reward_ledger
  where user_id = (select user_id from target)
  group by user_id
)
select
  t.user_id,
  w.coins as wallet_coins,
  w.version as wallet_version,
  p.ambar_balance as projected_ambar_balance,
  coalesce(r.reward_coins, 0) as level_and_achievement_reward_coins,
  (w.coins = p.ambar_balance) as wallet_projection_equal,
  p.total_xp,
  p.level,
  p.current_level_xp,
  p.next_level_xp
from target t
join public.user_wallets w on w.user_id = t.user_id
join public.user_progress p on p.user_id = t.user_id
left join reward_totals r on r.user_id = t.user_id;

select
  request_id,
  source_type,
  source_id,
  coin_delta,
  balance_after,
  is_idempotent,
  created_at
from public.achievement_level_reward_ledger
where user_id = '78d7f999-8f36-466c-aa3f-21d81b0510bf'::uuid
  and source_type = 'level_reward'
order by created_at, id;

-- The claim RPC must not create XP rows for a level reward.
select count(*)::bigint as level_reward_xp_rows
from public.economy_xp_ledger
where user_id = '78d7f999-8f36-466c-aa3f-21d81b0510bf'::uuid
  and source_type = 'level_reward';
