# RUTIO — Validación de seguridad económica en Staging

Estado: migraciones aplicadas y verificadas en Supabase Staging; Producción sin modificar.

## Revisión de las migraciones aplicadas

`20261019100000_revoke_direct_habit_reward_helper_execution.sql` revoca
`EXECUTE` sobre los helpers de recompensa para `PUBLIC`, `anon`,
`authenticated` y `service_role`, conserva `owner = postgres` y no concede
nuevos permisos. La RPC pública `complete_habit_economy_v1` los sigue usando
indirectamente como `SECURITY DEFINER`; la revocación directa no rompe esa
cadena porque el propietario de la función mantiene sus privilegios.

`20261019103000_allow_legitimate_archived_habit_reversal.sql` reemplaza la
misma firma pública, mantiene `search_path = ''`, `owner = postgres` y el
`EXECUTE` únicamente para `authenticated`. Permite una reversión solo si
existe un log completado; una finalización nueva sobre un hábito archivado
lanza `habit is archived`.

Orden aplicado: `20261019100000`, `20261019103000`, `20261019110000` y
`20261019120000`. La migración `20261019110000` conserva los bloqueos de DML
directo sobre `user_progress` y `habit_logs`, pero no contiene un `REVOKE` sobre
`record_habit_log`, porque esa función no existe en el catálogo de Staging.

La migración `20261019120000` repara el bootstrap de wallets con una función
`SECURITY DEFINER`, `search_path = ''`, inserción idempotente y un trigger sobre
`auth.users`. No concede permisos de escritura económica al cliente.

## Vulnerabilidades corregidas

- Ejecución directa de los helpers de recompensa revocada para roles cliente.
- Nuevas recompensas bloqueadas para hábitos archivados.
- Reversión histórica legítima conservada mediante la RPC pública.
- Escrituras directas de cliente sobre `user_progress` y `habit_logs` revocadas.
- Bootstrap de `user_wallets` reparado para cuentas nuevas y cuentas existentes
  sin wallet, sin alterar wallets ya existentes.

No se encontraron referencias desde RevenueCat a estos helpers. Las RPC de
nivel y logros no son modificadas.

## Matriz preparada

| Caso | Resultado esperado | Observado localmente | Staging |
|---|---|---|---|
| A/B/C: llamada directa a helpers | Denegada para autenticado y anon | Static tests confirman revocación | Verificado |
| D/E: CHECK y COUNT propios | Permitido vía RPC pública | Contrato y tests existentes | Verificado en Pixel 9 |
| F: hábito de otro usuario | Denegado | Ownership presente en RPC | Pendiente |
| G/H/I: DML wallet/progress/XP | Denegado | Migraciones revocan DML cliente | Pendiente |
| J/K: replay y concurrencia | Una sola mutación económica | Locks/índices/idempotencia revisados | Pendiente |
| L: nueva recompensa archivada | Denegada | Static test confirma guard | Pendiente prueba funcional |
| M/N: reversión archivada y replay | Permitida una vez; replay idempotente | Static test confirma contrato | Pendiente |
| O: offline previo al archivado | Reintento conserva `request_id` | Flujo cliente preserva RPC pública | Verificado reinicio; archivado pendiente |

## Resultados funcionales de Staging

En Pixel 9 conectado exclusivamente a Staging se verificaron correctamente:

- Finalización CHECK y recompensa.
- Reversión CHECK.
- Finalización COUNT y recompensa calculada por servidor.
- Persistencia y recuperación correcta después de reiniciar la aplicación.

La reversión de una recompensa histórica sobre un hábito archivado y el rechazo
de una nueva recompensa sobre un hábito archivado permanecen como pruebas
funcionales pendientes de ejecución controlada.

## Estado de Producción y riesgos pendientes

Producción no fue modificada. No se aplicó la migración 3 fuera de Staging.

Antes de integrar en `develop` debe completarse la prueba funcional de archivado
con una cuenta Premium legítima, verificando rechazo de nueva recompensa,
reversión histórica única e idempotencia. También debe conservarse evidencia de
que no se modifican saldos de otras cuentas.

## Consultas read-only para Staging

Ejecutar con una sesión de inspección autorizada, nunca con el JWT de un
usuario ni contra Producción.

```sql
-- Funciones, propietario y search_path
select n.nspname as schema_name, p.proname,
       pg_get_function_identity_arguments(p.oid) as identity_args,
       r.rolname as owner_name, p.prosecdef as security_definer,
       p.proconfig
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_roles r on r.oid = p.proowner
where n.nspname in ('public', 'app_private')
  and p.proname in (
    'complete_habit_economy_v1', 'apply_habit_completion_reward',
    'reverse_habit_completion_reward', 'claim_level_reward',
    'claim_achievement_reward'
  )
order by n.nspname, p.proname;

-- EXECUTE efectivo por función y rol
select routine_schema, routine_name, specific_name, grantee, privilege_type
from information_schema.routine_privileges
where routine_schema in ('public', 'app_private')
  and routine_name in (
    'complete_habit_economy_v1', 'apply_habit_completion_reward',
    'reverse_habit_completion_reward', 'claim_level_reward',
    'claim_achievement_reward'
  )
order by routine_name, grantee;

-- Privilegios de tablas económicas
select table_schema, table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in (
    'user_wallets', 'user_progress', 'economy_xp_ledger',
    'economy_habit_transition_ledger'
  )
order by table_name, grantee, privilege_type;

-- RLS y políticas
select schemaname, tablename, rowsecurity, policyname, roles,
       cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'user_wallets', 'user_progress', 'economy_xp_ledger',
    'economy_habit_transition_ledger'
  )
order by tablename, policyname;
```

## Plan manual de aplicación y rollback

1. Exportar únicamente metadatos read-only y confirmar que no hay cambios de
   balances ni ledgers durante la ventana.
2. Revisar los resultados anteriores y aplicar las dos migraciones en orden en
   una instancia Staging aislada.
3. Repetir las consultas de permisos y ejecutar la matriz con cuentas y
   hábitos fixture exclusivos de Staging.
4. Si una prueba legítima falla, detenerse. No restaurar permisos directos de
   los helpers: el rollback seguro requiere restaurar la definición anterior
   de `complete_habit_economy_v1` desde una copia versionada y revertir la
   segunda definición de función mediante una migración revisada.
5. Comparar wallet, `user_progress`, ledgers y logs antes/después; no borrar
   datos ni usar `service_role` como sustituto de una prueba autenticada.

La restauración debe aprobarse explícitamente antes de ejecutarse. No se han
generado tokens, fixtures remotos ni conexiones en esta fase.
