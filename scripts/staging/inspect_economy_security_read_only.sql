/*
  RUTIO — read-only economy security inspection

  Run only in the Supabase STAGING SQL Editor.
  Every executable statement in this file is a SELECT. This script does not
  set a role, change permissions, or modify data.
*/

-- 1) Exact function signatures, owners, SECURITY DEFINER and search_path.
with target_functions(schema_name, function_name, identity_args) as (
  values
    ('public', 'apply_habit_completion_reward', 'text, uuid, text, text, text'),
    ('public', 'reverse_habit_completion_reward', 'text, uuid, text, text, text'),
    ('public', 'complete_habit_economy_v1', 'text, uuid, date, boolean, integer, text, text'),
    ('public', 'claim_level_reward', 'text, integer, text'),
    ('public', 'claim_achievement_reward', 'text, text, text')
)
select tf.schema_name,
       tf.function_name,
       tf.identity_args,
       case when p.oid is null then 'REQUIERE_REVISION' else 'ENCONTRADA' end as status,
       case when p.oid is null then null else pg_get_function_identity_arguments(p.oid) end as actual_identity_args,
       case when p.oid is null then null else r.rolname end as owner_name,
       case when p.oid is null then null else p.prosecdef end as security_definer,
       case
         when p.oid is null then 'REQUIERE_REVISION: falta la firma exacta'
         when p.prosecdef and coalesce(array_to_string(p.proconfig, ','), '') like '%search_path=%'
           then 'PERMITIDO: SECURITY DEFINER con search_path explícito'
         when p.prosecdef then 'REQUIERE_REVISION: SECURITY DEFINER sin search_path explícito'
         else 'REQUIERE_REVISION: no es SECURITY DEFINER'
       end as interpretation,
       case when p.oid is null then null else p.proconfig end as function_config
from target_functions tf
left join pg_proc p
  on p.pronamespace = to_regnamespace(tf.schema_name)
 and p.proname = tf.function_name
 and pg_get_function_identity_arguments(p.oid) = tf.identity_args
left join pg_roles r on r.oid = p.proowner
order by tf.function_name;

-- 2) EXECUTE efectivo para los roles solicitados.
with target_functions(function_name, identity_args, function_oid) as (
  values
    ('apply_habit_completion_reward', 'text, uuid, text, text, text', to_regprocedure('public.apply_habit_completion_reward(text,uuid,text,text,text)')::oid),
    ('reverse_habit_completion_reward', 'text, uuid, text, text, text', to_regprocedure('public.reverse_habit_completion_reward(text,uuid,text,text,text)')::oid),
    ('complete_habit_economy_v1', 'text, uuid, date, boolean, integer, text, text', to_regprocedure('public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)')::oid),
    ('claim_level_reward', 'text, integer, text', to_regprocedure('public.claim_level_reward(text,integer,text)')::oid),
    ('claim_achievement_reward', 'text, text, text', to_regprocedure('public.claim_achievement_reward(text,text,text)')::oid)
), target_roles(role_name, is_public) as (
  values ('PUBLIC'::name, true), ('anon'::name, false),
         ('authenticated'::name, false), ('service_role'::name, false)
)
select tf.function_name,
       tf.identity_args,
       tr.role_name,
       case
         when tf.function_oid is null then 'REQUIERE_REVISION'
         when tr.is_public and exists (
           select 1
           from pg_proc p
           cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner)))
             as acl(grantor, grantee, privilege_type, is_grantable)
           where p.oid = tf.function_oid
             and acl.grantee = 0
             and acl.privilege_type = 'EXECUTE'
         ) then 'PERMITIDO'
         when not tr.is_public and has_function_privilege(tr.role_name, tf.function_oid, 'EXECUTE') then 'PERMITIDO'
         else 'DENEGADO'
       end as execute_status,
       case
         when tf.function_oid is null then 'REQUIERE_REVISION: firma no existe'
         when tr.is_public and exists (
           select 1
           from pg_proc p
           cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner)))
             as acl(grantor, grantee, privilege_type, is_grantable)
           where p.oid = tf.function_oid
             and acl.grantee = 0
             and acl.privilege_type = 'EXECUTE'
         )
           then 'PERMITIDO: PUBLIC tiene EXECUTE en la ACL efectiva (grantee 0)'
         when not tr.is_public and has_function_privilege(tr.role_name, tf.function_oid, 'EXECUTE')
           then 'PERMITIDO: el rol puede ejecutar la función'
         when tr.is_public then 'DENEGADO: PUBLIC no tiene EXECUTE en la ACL efectiva'
         else 'DENEGADO: el rol no puede ejecutar la función por privilegios efectivos'
       end as interpretation
from target_functions tf
cross join target_roles tr
order by tf.function_name, tr.role_name;

-- 3) RLS y políticas de tablas económicas.
with target_tables(table_name, table_oid) as (
  values
    ('user_wallets', to_regclass('public.user_wallets')::oid),
    ('user_progress', to_regclass('public.user_progress')::oid),
    ('economy_xp_ledger', to_regclass('public.economy_xp_ledger')::oid),
    ('habit_logs', to_regclass('public.habit_logs')::oid)
)
select tt.table_name,
       case when c.oid is null then 'REQUIERE_REVISION' when c.relrowsecurity then 'PERMITIDO' else 'REQUIERE_REVISION' end as rls_status,
       case when c.oid is null then 'REQUIERE_REVISION: tabla no existe' when c.relrowsecurity then 'PERMITIDO: RLS habilitado' else 'REQUIERE_REVISION: RLS deshabilitado' end as interpretation,
       coalesce(p.policyname, '[sin políticas]') as policy_name,
       p.permissive,
       p.roles,
       p.cmd,
       p.qual as using_expression,
       p.with_check
from target_tables tt
left join pg_class c on c.oid = tt.table_oid
left join pg_policies p on p.schemaname = 'public' and p.tablename = tt.table_name
order by tt.table_name, p.policyname nulls first;

-- 4) INSERT/UPDATE/DELETE efectivos sobre tablas económicas.
with target_tables(table_name, table_oid) as (
  values
    ('user_wallets', to_regclass('public.user_wallets')::oid),
    ('user_progress', to_regclass('public.user_progress')::oid),
    ('economy_xp_ledger', to_regclass('public.economy_xp_ledger')::oid),
    ('habit_logs', to_regclass('public.habit_logs')::oid)
), target_roles(role_name, is_public) as (
  values ('PUBLIC'::name, true), ('anon'::name, false),
         ('authenticated'::name, false), ('service_role'::name, false)
), operations(operation_name) as (
  values ('INSERT'), ('UPDATE'), ('DELETE')
)
select tt.table_name,
       tr.role_name,
       op.operation_name,
       case
         when tt.table_oid is null then 'REQUIERE_REVISION'
         when tr.is_public and exists (
           select 1
           from pg_class c
           cross join lateral aclexplode(coalesce(c.relacl, acldefault('r', c.relowner)))
             as acl(grantor, grantee, privilege_type, is_grantable)
           where c.oid = tt.table_oid
             and acl.grantee = 0
             and acl.privilege_type = op.operation_name
         ) then 'PERMITIDO'
         when not tr.is_public and has_table_privilege(tr.role_name, tt.table_oid, op.operation_name) then 'PERMITIDO'
         else 'DENEGADO'
       end as privilege_status,
       case
         when tt.table_oid is null then 'REQUIERE_REVISION: tabla no existe'
         when tr.is_public and exists (
           select 1
           from pg_class c
           cross join lateral aclexplode(coalesce(c.relacl, acldefault('r', c.relowner)))
             as acl(grantor, grantee, privilege_type, is_grantable)
           where c.oid = tt.table_oid
             and acl.grantee = 0
             and acl.privilege_type = op.operation_name
         ) then 'REQUIERE_REVISION: PUBLIC tiene DML explícito o predeterminado'
         when not tr.is_public and has_table_privilege(tr.role_name, tt.table_oid, op.operation_name)
           then 'REQUIERE_REVISION: existe DML efectivo; confirmar si es intencionado'
         when tr.is_public then 'DENEGADO: PUBLIC sin DML en la ACL efectiva'
         else 'DENEGADO: sin DML efectivo'
       end as interpretation
from target_tables tt
cross join target_roles tr
cross join operations op
order by tt.table_name, tr.role_name, op.operation_name;

-- 5) Dependencias necesarias para las dos migraciones nuevas.
with required_objects(object_kind, object_name, object_oid) as (
  values
    ('table', 'public.user_wallets', to_regclass('public.user_wallets')::oid),
    ('table', 'public.user_progress', to_regclass('public.user_progress')::oid),
    ('table', 'public.economy_xp_ledger', to_regclass('public.economy_xp_ledger')::oid),
    ('table', 'public.economy_habit_transition_ledger', to_regclass('public.economy_habit_transition_ledger')::oid),
    ('table', 'public.habit_currency_reward_ledger', to_regclass('public.habit_currency_reward_ledger')::oid),
    ('table', 'public.habit_logs', to_regclass('public.habit_logs')::oid),
    ('table', 'public.habits', to_regclass('public.habits')::oid),
    ('table', 'public.profiles', to_regclass('public.profiles')::oid),
    ('table', 'public.economy_runtime_policy', to_regclass('public.economy_runtime_policy')::oid),
    ('function', 'public.apply_habit_completion_reward(text,uuid,text,text,text)', to_regprocedure('public.apply_habit_completion_reward(text,uuid,text,text,text)')::oid),
    ('function', 'public.reverse_habit_completion_reward(text,uuid,text,text,text)', to_regprocedure('public.reverse_habit_completion_reward(text,uuid,text,text,text)')::oid),
    ('function', 'app_private.economy_assert_client_version(text)', to_regprocedure('app_private.economy_assert_client_version(text)')::oid),
    ('function', 'app_private.is_habit_scheduled_on(jsonb,date)', to_regprocedure('app_private.is_habit_scheduled_on(jsonb,date)')::oid),
    ('function', 'app_private.refresh_authoritative_user_progress(uuid)', to_regprocedure('app_private.refresh_authoritative_user_progress(uuid)')::oid)
)
select object_kind,
       object_name,
       case when object_oid is null then 'REQUIERE_REVISION' else 'ENCONTRADO' end as dependency_status,
       case when object_oid is null then 'REQUIERE_REVISION: resolver antes de aplicar migraciones' else 'PERMITIDO: dependencia presente' end as interpretation
from required_objects
order by object_kind, object_name;

-- 6) Columnas mínimas usadas por las migraciones de archivado/economía.
with required_columns(table_name, column_name) as (
  values
    ('public.habits', 'id'), ('public.habits', 'user_id'), ('public.habits', 'is_archived'),
    ('public.habits', 'habit_type'), ('public.habits', 'target_count'), ('public.habits', 'schedule'),
    ('public.habits', 'created_at'), ('public.habit_logs', 'user_id'), ('public.habit_logs', 'habit_id'),
    ('public.habit_logs', 'log_date'), ('public.habit_logs', 'is_completed'),
    ('public.economy_habit_transition_ledger', 'request_id'),
    ('public.economy_habit_transition_ledger', 'transition_no'),
    ('public.economy_habit_transition_ledger', 'logical_date')
)
select rc.table_name,
       rc.column_name,
       case when a.attname is null then 'REQUIERE_REVISION' else 'ENCONTRADA' end as column_status,
       case when a.attname is null then 'REQUIERE_REVISION: columna ausente' else 'PERMITIDO: columna presente' end as interpretation
from required_columns rc
left join pg_attribute a
  on a.attrelid = to_regclass(rc.table_name)::oid
 and a.attname = rc.column_name
 and a.attnum > 0
 and not a.attisdropped
order by rc.table_name, rc.column_name;
