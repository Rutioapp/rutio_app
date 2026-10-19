-- Rutio staging bootstrap 04C — logical deletion validation.
-- READ-ONLY. Exactly one SELECT statement; no application rows are read.

with
checks(category, check_name, status, details) as (
  select 'table', 'public.habits exists',
    case when c.oid is not null then 'PASS' else 'FAIL' end,
    case when c.oid is null then 'missing' else 'present' end
  from (values (to_regclass('public.habits'))) expected(table_oid)
  left join pg_class c on c.oid = expected.table_oid
  union all
  select 'columns', 'habits.is_archived boolean',
    case when a.attrelid is not null and format_type(a.atttypid, a.atttypmod) = 'boolean' then 'PASS' else 'FAIL' end,
    'type=' || coalesce(format_type(a.atttypid, a.atttypmod), 'missing')
  from (values (to_regclass('public.habits'))) expected(table_oid)
  left join pg_attribute a on a.attrelid = expected.table_oid
    and a.attname = 'is_archived' and a.attnum > 0 and not a.attisdropped
  union all
  select 'rls', 'habits RLS enabled',
    case when c.oid is not null and c.relrowsecurity then 'PASS' else 'FAIL' end,
    'relrowsecurity=' || coalesce(c.relrowsecurity::text, 'missing')
  from (values (to_regclass('public.habits'))) expected(table_oid)
  left join pg_class c on c.oid = expected.table_oid
  union all
  select 'rls', 'habits_update_own preserves ownership',
    case when p.policyname is not null
      and upper(p.cmd) = 'UPDATE'
      and lower(regexp_replace(coalesce(p.qual, ''), E'\\s+', '', 'g')) like '%auth.uid()=user_id%'
      and lower(regexp_replace(coalesce(p.with_check, ''), E'\\s+', '', 'g')) like '%auth.uid()=user_id%'
      then 'PASS' else 'FAIL' end,
    'policy=' || coalesce(p.policyname, 'missing') || '; qual=' || coalesce(p.qual, 'NULL')
      || '; with_check=' || coalesce(p.with_check, 'NULL')
  from (values (1)) expected(dummy)
  left join pg_policies p on p.schemaname = 'public'
    and p.tablename = 'habits' and p.policyname = 'habits_update_own'
  union all
  select 'privileges', 'authenticated DELETE denied',
    case when not has_table_privilege('authenticated', 'public.habits', 'DELETE') then 'PASS' else 'FAIL' end,
    'effective_delete=' || has_table_privilege('authenticated', 'public.habits', 'DELETE')::text
  union all
  select 'privileges', 'anon DELETE denied',
    case when not has_table_privilege('anon', 'public.habits', 'DELETE') then 'PASS' else 'FAIL' end,
    'effective_delete=' || has_table_privilege('anon', 'public.habits', 'DELETE')::text
  union all
  select 'privileges', 'PUBLIC DELETE denied',
    case when c.oid is not null and not exists (
      select 1 from aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
      where a.grantee = 0 and a.privilege_type = 'DELETE'
    ) then 'PASS' else 'FAIL' end,
    'PUBLIC has no DELETE grant'
  from (values (to_regclass('public.habits'))) expected(table_oid)
  left join pg_class c on c.oid = expected.table_oid
  union all
  select 'paths', 'no installed function deletes public.habits',
    case when not exists (
      select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname in ('public', 'app_private')
        and lower(p.prosrc) ~ 'delete[[:space:]]+from[[:space:]]+(public[.])?habits'
    ) then 'PASS' else 'FAIL' end,
    'catalog function source scan'
  union all
  select 'paths', 'no habit DELETE trigger path',
    case when not exists (
      select 1 from pg_trigger t join pg_proc p on p.oid = t.tgfoid
      where t.tgrelid = to_regclass('public.habits') and not t.tgisinternal
        and lower(p.prosrc) ~ 'delete[[:space:]]+from[[:space:]]+(public[.])?habits'
    ) then 'PASS' else 'FAIL' end,
    'trigger function source scan'
)
select category, check_name, status, details
from checks
order by category, check_name;
