begin;

do $$
declare
  v_public_rpc text := pg_get_functiondef(
    'public.get_current_user_bootstrap_decision()'::regprocedure
  );
  v_internal_rpc text := pg_get_functiondef(
    'app_private.get_current_user_bootstrap_decision_row(uuid)'::regprocedure
  );
  v_bootstrap_wallet text := pg_get_functiondef(
    'app_private.bootstrap_user_wallet_on_auth_insert()'::regprocedure
  );
  v_profile_insert text := pg_get_functiondef(
    'app_private.bootstrap_profile_state_on_insert()'::regprocedure
  );
  v_profile_update text := pg_get_functiondef(
    'app_private.bootstrap_profile_state_on_update()'::regprocedure
  );
  v_profile_delete text := pg_get_functiondef(
    'app_private.bootstrap_profile_state_on_delete()'::regprocedure
  );
begin
  if not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app_private'
      and c.relname = 'user_bootstrap_state'
      and c.relkind = 'r'
  ) then
    raise exception 'app_private.user_bootstrap_state must exist';
  end if;

  if not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app_private'
      and c.relname = 'bootstrap_policy'
      and c.relkind = 'r'
  ) then
    raise exception 'app_private.bootstrap_policy must exist';
  end if;

  if not exists (
    select 1
    from pg_attribute
    where attrelid = 'app_private.user_bootstrap_state'::regclass
      and attname = 'profile_revision'
      and attnotnull
      and not attisdropped
  ) then
    raise exception 'user_bootstrap_state.profile_revision must exist and be required';
  end if;

  if not exists (
    select 1
    from pg_attribute
    where attrelid = 'app_private.bootstrap_policy'::regclass
      and attname = 'policy_revision'
      and attnotnull
      and not attisdropped
  ) then
    raise exception 'bootstrap_policy.policy_revision must exist and be required';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'app_private.user_bootstrap_state'::regclass
      and conname = 'user_bootstrap_state_account_status_check'
      and pg_get_constraintdef(oid) like '%active%'
      and pg_get_constraintdef(oid) like '%suspended%'
      and pg_get_constraintdef(oid) like '%pending_deletion%'
  ) then
    raise exception 'user_bootstrap_state.account_status must be constrained to the expected lifecycle states';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'app_private.user_bootstrap_state'::regclass
      and conname = 'user_bootstrap_state_profile_state_check'
      and pg_get_constraintdef(oid) like '%uninitialized%'
      and pg_get_constraintdef(oid) like '%ready%'
      and pg_get_constraintdef(oid) like '%deleted%'
  ) then
    raise exception 'user_bootstrap_state.profile_state must be constrained to the expected lifecycle states';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'app_private.bootstrap_policy'::regclass
      and conname = 'bootstrap_policy_onboarding_enforcement_check'
      and pg_get_constraintdef(oid) like '%advisory%'
      and pg_get_constraintdef(oid) like '%required%'
  ) then
    raise exception 'bootstrap_policy.onboarding_enforcement must be constrained to advisory/required';
  end if;

  if (select count(*) from app_private.bootstrap_policy where singleton = true) <> 1 then
    raise exception 'bootstrap_policy must contain exactly one singleton row';
  end if;

  if exists (
    select 1
    from auth.users u
    left join app_private.user_bootstrap_state s on s.user_id = u.id
    where s.user_id is null
  ) then
    raise exception 'every auth user must have an authoritative bootstrap state row after backfill';
  end if;

  if exists (
    select 1
    from auth.users u
    join public.profiles p on p.id = u.id
    join app_private.user_bootstrap_state s on s.user_id = u.id
    where s.profile_state <> 'ready'
  ) then
    raise exception 'users with a profile row must be backfilled as ready';
  end if;

  if exists (
    select 1
    from auth.users u
    left join public.profiles p on p.id = u.id
    join app_private.user_bootstrap_state s on s.user_id = u.id
    where p.id is null
      and s.profile_state <> 'uninitialized'
  ) then
    raise exception 'users without a profile row must be backfilled as uninitialized';
  end if;

  if not exists (
    select 1
    from pg_trigger
    where tgrelid = 'auth.users'::regclass
      and tgname = 'trg_auth_users_bootstrap_user_wallet'
      and not tgisinternal
  ) then
    raise exception 'the existing auth.users bootstrap trigger must still exist';
  end if;

  if not exists (
    select 1
    from pg_trigger
    where tgrelid = 'public.profiles'::regclass
      and tgname = 'trg_profiles_bootstrap_state_on_insert'
      and not tgisinternal
  ) or not exists (
    select 1
    from pg_trigger
    where tgrelid = 'public.profiles'::regclass
      and tgname = 'trg_profiles_bootstrap_state_on_update'
      and not tgisinternal
  ) or not exists (
    select 1
    from pg_trigger
    where tgrelid = 'public.profiles'::regclass
      and tgname = 'trg_profiles_bootstrap_state_on_delete'
      and not tgisinternal
  ) then
    raise exception 'all profile lifecycle bootstrap triggers must exist';
  end if;

  if lower(v_public_rpc) not like '%security definer%'
     or lower(v_public_rpc) not like '%set search_path to ''''%'
     or v_public_rpc not like '%auth.uid()%'
     or v_public_rpc like '%p_user_id%'
     or v_public_rpc like '%email%'
     or v_public_rpc like '%display_name%'
     or v_public_rpc like '%avatar%'
     or v_public_rpc like '%theme%'
     or v_public_rpc like '%accent_color%' then
    raise exception 'public bootstrap RPC must be auth.uid()-scoped, security definer, locked search_path, and expose no sensitive profile fields';
  end if;

  if lower(v_internal_rpc) not like '%security definer%'
     or lower(v_internal_rpc) not like '%set search_path to ''''%'
     or v_internal_rpc not like '%profile_uninitialized%'
     or v_internal_rpc not like '%profile_deleted%'
     or v_internal_rpc not like '%account_suspended%'
     or v_internal_rpc not like '%account_pending_deletion%'
     or v_internal_rpc not like '%invalid_profile%'
     or v_internal_rpc not like '%onboarding%'
     or v_internal_rpc not like '%home%' then
    raise exception 'internal bootstrap decision helper must remain fail-closed and expose the full authoritative decision set';
  end if;

  if lower(v_bootstrap_wallet) not like '%security definer%'
     or lower(v_bootstrap_wallet) not like '%set search_path to ''''%'
     or v_bootstrap_wallet not like '%perform app_private.ensure_user_bootstrap_state_row(new.id)%' then
    raise exception 'auth bootstrap helper must still be security definer and create the bootstrap state row';
  end if;

  if lower(v_profile_insert) not like '%security definer%'
     or lower(v_profile_insert) not like '%set search_path to ''''%'
     or v_profile_insert not like '%profile_state = ''ready''%'
     or v_profile_insert not like '%profile_revision + 1%' then
    raise exception 'profile insert trigger helper must mark ready and bump revision';
  end if;

  if lower(v_profile_update) not like '%security definer%'
     or lower(v_profile_update) not like '%set search_path to ''''%'
     or v_profile_update not like '%old.onboarding_status is not distinct from new.onboarding_status%'
     or v_profile_update not like '%old.onboarding_version is not distinct from new.onboarding_version%'
     or v_profile_update not like '%old.onboarding_completed_at is not distinct from new.onboarding_completed_at%' then
    raise exception 'profile update trigger helper must ignore non-bootstrap-relevant updates';
  end if;

  if lower(v_profile_delete) not like '%security definer%'
     or lower(v_profile_delete) not like '%set search_path to ''''%'
     or v_profile_delete not like '%profile_state = ''deleted''%'
     or v_profile_delete not like '%where user_id = old.id%' then
    raise exception 'profile delete trigger helper must mark deleted only for the same user';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_current_user_bootstrap_decision()'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'anon must not execute public.get_current_user_bootstrap_decision';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_current_user_bootstrap_decision()'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'authenticated must execute public.get_current_user_bootstrap_decision';
  end if;

  if has_function_privilege(
    'authenticated',
    'app_private.get_current_user_bootstrap_decision_row(uuid)'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'authenticated must not execute app_private.get_current_user_bootstrap_decision_row directly';
  end if;

  if has_function_privilege(
    'authenticated',
    'app_private.ensure_user_bootstrap_state_row(uuid)'::regprocedure,
    'EXECUTE'
  ) or has_function_privilege(
    'authenticated',
    'app_private.set_user_bootstrap_account_status(uuid, text)'::regprocedure,
    'EXECUTE'
  ) or has_function_privilege(
    'authenticated',
    'app_private.set_bootstrap_policy(integer, text)'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'authenticated must not execute internal bootstrap helpers directly';
  end if;

  if has_table_privilege('anon', 'app_private.user_bootstrap_state', 'SELECT')
     or has_table_privilege('authenticated', 'app_private.user_bootstrap_state', 'SELECT')
     or has_table_privilege('anon', 'app_private.bootstrap_policy', 'SELECT')
     or has_table_privilege('authenticated', 'app_private.bootstrap_policy', 'SELECT') then
    raise exception 'client roles must not read app_private bootstrap tables directly';
  end if;
end;
$$;

rollback;
