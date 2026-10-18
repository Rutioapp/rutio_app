# Diseño de integración aislada — recompensa de nivel 5

## Estrategia

La prueba recomendada usa una instancia Supabase/PostgreSQL desechable, separada de Staging y Producción, con un marcador `ISOLATED`. El usuario ficticio debe ser distinto del usuario A y provisionarse en Auth de esa instancia. No se reutilizan URLs, claves ni JWT reales.

En este equipo está disponible Supabase CLI, pero no Docker ni `psql`; por eso no se puede levantar Supabase local ni ejecutar el reset o la integración durante esta preparación.

## Dependencias

- Supabase local o PostgreSQL compatible con esquemas `auth`, `public`, `extensions` y `app_private`.
- Migraciones base del repositorio aplicadas en orden, incluida `20261017120000_authoritative_economy_phase1.sql` y `20261018100000_sync_level_reward_user_progress.sql`.
- `pgcrypto`, roles Supabase y las funciones `auth.uid()`/`app_private.refresh_authoritative_user_progress`.
- Python 3 y `psycopg2` para la prueba de dos conexiones.
- Un marcador creado manualmente solo en la instancia desechable:

```sql
create table public.rutio_isolated_test_marker (
  marker text primary key,
  environment text not null check (environment = 'ISOLATED'),
  enabled boolean not null default true
);
```

La creación de la instancia, el usuario Auth y el marcador no se ejecutaron.

## Fixture

[isolated_level_reward_fixture_setup.sql](D:/dev/alpha/rutio_app-security-economy/supabase/tests/isolated_level_reward_fixture_setup.sql) exige el marcador y un UUID ficticio. Rechaza el UUID del usuario A, comprueba que el usuario Auth existe y rechaza datos económicos previos.

En esa base aislada inserta una única fila sintética de `715 XP` en `economy_xp_ledger`, la fuente que consulta `claim_level_reward`, y proyecta `user_progress` mediante `refresh_authoritative_user_progress`. Esto es válido para probar la RPC, wallet, ledger e idempotencia; no demuestra que el XP se haya adquirido legítimamente mediante hábitos.

Estado inicial esperado: XP 715, nivel 5, wallet 5/version 11, `ambar_balance` 5 y cero filas de recompensa de nivel.

## Pruebas

[isolated_level_reward_integration.py](D:/dev/alpha/rutio_app-security-economy/scripts/isolated_level_reward_integration.py) ejecuta, en este orden:

1. Dos claims concurrentes con request IDs distintos.
2. Verificación de una sola fila de ledger y wallet 55/version 12.
3. Verificación de `user_progress.ambar_balance = 55`.
4. Replay con el mismo request ID.
5. Claim con request ID distinto para la misma fuente.

Las conexiones establecen `request.jwt.claim.sub` al UUID ficticio. El script rechaza DSNs de Staging, Producción y `supabase.co`, y nunca crea datos ni aplica migraciones.

Snapshots y limpieza:

- [snapshot](D:/dev/alpha/rutio_app-security-economy/supabase/tests/isolated_level_reward_fixture_snapshot.sql)
- [cleanup protegido](D:/dev/alpha/rutio_app-security-economy/supabase/tests/isolated_level_reward_fixture_cleanup.sql)

## Comandos preparados

```powershell
$env:RUTIO_ISOLATED_DATABASE_URL = '<local-or-disposable-dsn>'
$env:RUTIO_ISOLATED_TEST_USER_ID = '<fictional-auth-user-uuid>'
$env:RUTIO_ISOLATED_MARKER = '<random-isolated-marker>'

psql $env:RUTIO_ISOLATED_DATABASE_URL -v ON_ERROR_STOP=1 `
  -v isolated_marker=$env:RUTIO_ISOLATED_MARKER `
  -v test_user_id=$env:RUTIO_ISOLATED_TEST_USER_ID `
  -f .\supabase\tests\isolated_level_reward_fixture_setup.sql

python .\scripts\isolated_level_reward_integration.py

psql $env:RUTIO_ISOLATED_DATABASE_URL -v ON_ERROR_STOP=1 `
  -v isolated_marker=$env:RUTIO_ISOLATED_MARKER `
  -v test_user_id=$env:RUTIO_ISOLATED_TEST_USER_ID `
  -f .\supabase\tests\isolated_level_reward_fixture_snapshot.sql

# Solo al destruir la instancia desechable:
psql $env:RUTIO_ISOLATED_DATABASE_URL -v ON_ERROR_STOP=1 `
  -v isolated_marker=$env:RUTIO_ISOLATED_MARKER `
  -v test_user_id=$env:RUTIO_ISOLATED_TEST_USER_ID `
  -v confirm_cleanup=YES `
  -f .\supabase\tests\isolated_level_reward_fixture_cleanup.sql
```

## Limitación integral

El seed de 715 XP permite verificar la reclamación válida y la sincronización, pero no sustituye una prueba integral de adquisición legítima. Esa prueba requeriría completar hábitos mediante `complete_habit_economy_v1`, respetar calendario y ventana de fechas y acumular 695 XP desde el estado del usuario A; actualmente no hay capacidad suficiente y no se modifica A para forzarla.

## Estado

Diseño y archivos locales preparados. No se ejecutaron migraciones, SQL, RPCs, pruebas remotas, commits, push ni merge.
