-- RUTIO — read-only verification for the level-reward helper and immediate RPC dependencies.

select
  to_regprocedure('app_private.level_reward_ambar_for_level(integer)')
    as level_reward_helper,
  to_regprocedure('app_private.economy_level_progress(integer)')
    as economy_level_progress,
  to_regprocedure('app_private.refresh_authoritative_user_progress(uuid)')
    as refresh_authoritative_user_progress,
  to_regprocedure('public.claim_level_reward(text,integer,text)')
    as claim_level_reward,
  to_regclass('public.user_wallets') as user_wallets,
  to_regclass('public.economy_xp_ledger') as economy_xp_ledger,
  to_regclass('public.achievement_level_reward_ledger')
    as achievement_level_reward_ledger;

select level, reward_ambar
from (values
  (1, app_private.level_reward_ambar_for_level(1)),
  (5, app_private.level_reward_ambar_for_level(5)),
  (10, app_private.level_reward_ambar_for_level(10)),
  (20, app_private.level_reward_ambar_for_level(20)),
  (30, app_private.level_reward_ambar_for_level(30)),
  (40, app_private.level_reward_ambar_for_level(40)),
  (50, app_private.level_reward_ambar_for_level(50)),
  (60, app_private.level_reward_ambar_for_level(60)),
  (6, app_private.level_reward_ambar_for_level(6))
) as expected(level, reward_ambar);

select
  position('app_private.level_reward_ambar_for_level' in
    pg_get_functiondef('public.claim_level_reward(text,integer,text)'::regprocedure)) > 0
    as claim_references_level_helper,
  position('app_private.economy_level_progress' in
    pg_get_functiondef('public.claim_level_reward(text,integer,text)'::regprocedure)) > 0
    as claim_references_authoritative_level,
  position('public.economy_xp_ledger' in
    pg_get_functiondef('public.claim_level_reward(text,integer,text)'::regprocedure)) > 0
    as claim_reads_xp_ledger,
  position('public.user_wallets' in
    pg_get_functiondef('public.claim_level_reward(text,integer,text)'::regprocedure)) > 0
    as claim_reads_wallet,
  position('public.achievement_level_reward_ledger' in
    pg_get_functiondef('public.claim_level_reward(text,integer,text)'::regprocedure)) > 0
    as claim_writes_reward_ledger,
  position('app_private.refresh_authoritative_user_progress' in
    pg_get_functiondef('public.claim_level_reward(text,integer,text)'::regprocedure)) > 0
    as claim_refreshes_projection;
