-- RUTIO: diagnóstico post-migración 20261019100000
-- SOLO LECTURA. Ejecutar únicamente en Supabase Staging.
-- No cambia de rol, no invoca RPCs y no modifica permisos ni datos.
-- Sustituir únicamente el literal de request_id del bloque 6 por el request_id
-- de una prueba real ya realizada. No incluir user_id, UUIDs de hábitos ni PII.

-- 1. Cadena RPC: propietario, SECURITY DEFINER, search_path y ACL cruda.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as identity_arguments,
  r.rolname as owner_name,
  p.prosecdef as security_definer,
  p.proconfig as function_config,
  p.proacl as raw_acl,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
  has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
  has_function_privilege('service_role', p.oid, 'EXECUTE') as service_role_execute
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_roles r on r.oid = p.proowner
where p.oid in (
  to_regprocedure('public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)')::oid,
  to_regprocedure('public.apply_habit_completion_reward(text,uuid,text,text,text)')::oid,
  to_regprocedure('public.reverse_habit_completion_reward(text,uuid,text,text,text)')::oid
)
order by p.proname;

-- 2. Definición efectiva de la RPC pública y de los helpers.
-- La salida permite comprobar si Staging coincide con el SQL versionado.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as identity_arguments,
  pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where p.oid in (
  to_regprocedure('public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)')::oid,
  to_regprocedure('public.apply_habit_completion_reward(text,uuid,text,text,text)')::oid,
  to_regprocedure('public.reverse_habit_completion_reward(text,uuid,text,text,text)')::oid
)
order by p.proname;

-- 3. ACL efectiva de cada función, incluyendo PUBLIC (grantee_oid = 0).
-- Si proacl es NULL, PostgreSQL usa acldefault('f', owner_oid).
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as identity_arguments,
  x.grantee as grantee_oid,
  case when x.grantee = 0 then 'PUBLIC' else coalesce(gr.rolname, 'UNKNOWN_ROLE') end as grantee_name,
  x.privilege_type,
  x.is_grantable,
  case when x.grantee = 0 then 'PUBLIC' else 'ROLE' end as grantee_kind
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) x
left join pg_roles gr on gr.oid = x.grantee
where p.oid in (
  to_regprocedure('public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)')::oid,
  to_regprocedure('public.apply_habit_completion_reward(text,uuid,text,text,text)')::oid,
  to_regprocedure('public.reverse_habit_completion_reward(text,uuid,text,text,text)')::oid
)
order by p.proname, x.grantee, x.privilege_type;

-- 4. Dependencias de la RPC: funciones y tablas referenciadas por el cuerpo.
select
  src.nspname as source_schema,
  src.proname as source_function,
  pg_get_function_identity_arguments(src.oid) as source_arguments,
  dep_class.relkind as dependency_kind,
  coalesce(dep_ns.nspname, dep_class.relnamespace::regnamespace::text) as dependency_schema,
  dep_class.relname as dependency_name,
  dep_obj.objid::oid as dependency_oid
from pg_depend dep_obj
join pg_proc src on src.oid = dep_obj.objid
join pg_namespace src_ns on src_ns.oid = src.pronamespace
join pg_class dep_class on dep_class.oid = dep_obj.refobjid
left join pg_namespace dep_ns on dep_ns.oid = dep_class.relnamespace
where src.oid = to_regprocedure(
  'public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)'
)::oid
order by dependency_kind, dependency_schema, dependency_name;

-- 5. Triggers que pueden escribir habit_logs, user_progress o los ledgers.
select
  tn.nspname as table_schema,
  c.relname as table_name,
  t.tgname as trigger_name,
  pg_get_triggerdef(t.oid) as trigger_definition,
  p.pronamespace::regnamespace::text as trigger_function_schema,
  p.proname as trigger_function_name,
  pg_get_function_identity_arguments(p.oid) as trigger_function_arguments,
  p.prosecdef as trigger_function_security_definer,
  p.proconfig as trigger_function_config
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace tn on tn.oid = c.relnamespace
join pg_proc p on p.oid = t.tgfoid
where not t.tgisinternal
  and c.relname in (
    'habit_logs', 'user_progress', 'economy_habit_transition_ledger',
    'economy_xp_ledger', 'habit_currency_reward_ledger', 'user_wallets'
  )
order by table_name, trigger_name;

-- 6. Resultado persistido de una prueba concreta, sin devolver user_id ni PII.
-- Reemplazar el literal por el request_id enviado por Flutter.
with probe as (
  select 'REPLACE_WITH_TEST_REQUEST_ID'::text as request_id
),
counts as (
  select
    (select count(*) from public.economy_habit_transition_ledger t, probe p
     where t.request_id = p.request_id) as transition_rows,
    (select count(*) from public.habit_currency_reward_ledger l, probe p
     where l.request_id in (p.request_id, p.request_id || ':coins')) as coin_ledger_rows,
    (select coalesce(sum(l.coin_delta), 0) from public.habit_currency_reward_ledger l, probe p
     where l.request_id in (p.request_id, p.request_id || ':coins')) as coin_delta,
    (select count(*) from public.economy_xp_ledger l, probe p
     where l.request_id in (p.request_id, p.request_id || ':xp')) as xp_ledger_rows,
    (select coalesce(sum(l.xp_delta), 0) from public.economy_xp_ledger l, probe p
     where l.request_id in (p.request_id, p.request_id || ':xp')) as xp_delta
)
select *,
  case
    when transition_rows = 1 and coin_ledger_rows >= 1 and xp_ledger_rows = 1
      then 'PERMITIDO: operación económica persistida'
    when transition_rows = 0 and coin_ledger_rows = 0 and xp_ledger_rows = 0
      then 'REQUIERE REVISION: no hay rastro; revisar error RPC/eligibilidad/caché'
    else 'REQUIERE REVISION: estado parcial; la transacción esperada no es coherente'
  end as interpretation
from counts;

-- 7. Estado de las funciones ausentes, para distinguir ausencia de objeto.
select
  expected.function_name,
  expected.signature,
  case when expected.object_oid is null then 'AUSENTE' else 'PRESENTE' end as object_status
from (
  values
    ('complete_habit_economy_v1', 'public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)',
      to_regprocedure('public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)')::oid),
    ('apply_habit_completion_reward', 'public.apply_habit_completion_reward(text,uuid,text,text,text)',
      to_regprocedure('public.apply_habit_completion_reward(text,uuid,text,text,text)')::oid),
    ('reverse_habit_completion_reward', 'public.reverse_habit_completion_reward(text,uuid,text,text,text)',
      to_regprocedure('public.reverse_habit_completion_reward(text,uuid,text,text,text)')::oid)
) as expected(function_name, signature, object_oid)
order by expected.function_name;
