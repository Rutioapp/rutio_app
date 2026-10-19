-- RUTIO: diagnóstico de bootstrap económico de una cuenta nueva
-- SOLO LECTURA. Ejecutar únicamente en Supabase Staging.
-- Sustituir ACCOUNT_UUID por el UUID de la cuenta de prueba.

-- 1. Triggers presentes sobre auth.users y profiles.
select
  n.nspname as table_schema,
  c.relname as table_name,
  t.tgname as trigger_name,
  pg_get_triggerdef(t.oid) as trigger_definition,
  pn.nspname as function_schema,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as function_arguments,
  p.prosecdef as security_definer,
  p.proconfig as function_config,
  r.rolname as owner_name
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
join pg_proc p on p.oid = t.tgfoid
join pg_namespace pn on pn.oid = p.pronamespace
join pg_roles r on r.oid = p.proowner
where not t.tgisinternal
  and ((n.nspname = 'auth' and c.relname = 'users')
    or (n.nspname = 'public' and c.relname = 'profiles'))
order by table_schema, table_name, trigger_name;

-- 2. Definición efectiva de los helpers de bootstrap.
select
  n.nspname as function_schema,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as function_arguments,
  r.rolname as owner_name,
  p.prosecdef as security_definer,
  p.proconfig as function_config,
  pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_roles r on r.oid = p.proowner
where p.oid in (
  to_regprocedure('app_private.bootstrap_user_wallet_on_auth_insert()')::oid,
  to_regprocedure('app_private.ensure_user_bootstrap_state_row(uuid)')::oid
)
order by function_schema, function_name;

-- 3. Existencia y estado mínimo de la cuenta de prueba.
-- No devuelve correo, nombre ni ningún dato sensible.
with target as (
  select 'ACCOUNT_UUID'::uuid as user_id
)
select
  (select count(*) from auth.users u, target t where u.id = t.user_id) as auth_user_rows,
  (select count(*) from public.profiles p, target t where p.id = t.user_id) as profile_rows,
  (select count(*) from public.habits h, target t where h.user_id = t.user_id) as habit_rows,
  (select count(*) from public.user_wallets w, target t where w.user_id = t.user_id) as wallet_rows,
  (select count(*) from public.user_progress p, target t where p.user_id = t.user_id) as progress_rows,
  (select count(*) from public.habit_logs l, target t where l.user_id = t.user_id) as habit_log_rows,
  (select count(*) from public.economy_habit_transition_ledger l, target t where l.user_id = t.user_id) as transition_rows,
  (select count(*) from public.economy_xp_ledger l, target t where l.user_id = t.user_id) as xp_ledger_rows,
  (select count(*) from public.habit_currency_reward_ledger l, target t where l.user_id = t.user_id) as coin_ledger_rows;

-- 4. Cobertura global del bootstrap: solo totales, sin identificar usuarios.
select
  (select count(*) from auth.users) as auth_users,
  (select count(*) from public.user_wallets) as wallets,
  (select count(*) from auth.users u
   where not exists (select 1 from public.user_wallets w where w.user_id = u.id))
    as auth_users_without_wallet,
  (select count(*) from public.user_progress) as progress_rows;

-- 5. La RPC exige wallet previa y crea/refresca user_progress al final.
select
  position('wallet missing for user' in
    pg_get_functiondef(to_regprocedure(
      'public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)'
    )::oid)
  ) > 0 as rpc_requires_wallet,
  position('insert into public.user_progress' in
    pg_get_functiondef(to_regprocedure(
      'public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)'
    )::oid)
  ) > 0 as rpc_refreshes_progress;

-- 6. Confirmación de que la cuenta no tiene un estado remoto de completado.
with target as (
  select 'ACCOUNT_UUID'::uuid as user_id
)
select
  (select count(*) from public.habit_logs l, target t
   where l.user_id = t.user_id and l.is_completed) as completed_log_rows,
  (select count(*) from public.economy_habit_transition_ledger l, target t
   where l.user_id = t.user_id and l.is_completed) as completed_transition_rows,
  case
    when (select count(*) from public.habit_logs l, target t
          where l.user_id = t.user_id and l.is_completed) = 0
     and (select count(*) from public.economy_habit_transition_ledger l, target t
          where l.user_id = t.user_id and l.is_completed) = 0
      then 'REQUIERE REVISION: completado solo local o RPC abortada'
    else 'REQUIERE REVISION: existe estado remoto; correlacionar request_id'
  end as interpretation;
