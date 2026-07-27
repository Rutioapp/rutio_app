# Onboarding Remote State - Phase 2A

Fecha: 2026-07-27

## Resumen

La Fase 2A anade estado remoto minimo de onboarding en Supabase para que la Fase 2B pueda dejar de depender solo de `userState.meta.onboardingDone` local durante el arranque.

No se ha implementado Flutter en esta fase. No se han modificado `AppStartupGate`, `AuthController`, navegacion ni repositorios.

## Archivo de migracion

`supabase/migrations/20260727210441_add_remote_onboarding_state.sql`

La migracion fue creada con:

```powershell
supabase migration new add_remote_onboarding_state
```

## Inspeccion previa

| Area | Resultado |
| --- | --- |
| Tabla de perfiles | `public.profiles`. El cliente Flutter la consume desde `ProfileRepository._profilesTable = 'profiles'`. |
| Tabla remota real | Consulta `information_schema.columns` sobre el proyecto enlazado confirma `public.profiles` con `id`, `email`, `display_name`, `avatar_url`, `onboarding_completed`, `created_at`, `updated_at` y `habit_time_zone`. La columna legacy remota `onboarding_completed boolean not null default false` no se usa para esta nueva fase. |
| Migracion/schema local que define perfiles | `supabase/sql/supabase_backend_phase_9_schema_patch.sql` contiene el contrato consolidado local de `public.profiles`, incluyendo `id uuid primary key references auth.users(id) on delete cascade`, columnas de identidad/configuracion y RLS. |
| Migraciones posteriores sobre perfiles | `supabase/migrations/20260725110000_create_streak_protection_foundation.sql` anade `habit_time_zone` y el trigger `trg_profiles_validate_habit_time_zone` solo para validar esa columna. |
| Trigger remoto de perfil nuevo | El proyecto enlazado tiene `on_auth_user_created after insert on auth.users execute function handle_new_user()`. La funcion `public.handle_new_user()` inserta explicitamente `id`, `email`, `display_name` en `public.profiles`; al no enviar las nuevas columnas, los defaults `pending/1/null` actuaran correctamente. No requiere cambio. |
| Triggers remotos sobre `public.profiles` | `set_profiles_updated_at` y `trg_profiles_validate_habit_time_zone`; ninguno enumera ni valida columnas de onboarding remoto. |
| Politicas RLS actuales remotas | `Users can view their own profile`, `Users can insert their own profile`, `Users can update their own profile`, todas para rol `authenticated` y con `auth.uid() = id`. |
| Constraints remotas existentes | `profiles_pkey (id)` y `profiles_id_fkey` (`id references auth.users(id) on delete cascade`). No habia constraints de `onboarding_status`/`onboarding_version`. |
| Modelo Flutter | `lib/data/models/remote/remote_profile.dart` aun no mapea `onboarding_status`, `onboarding_version` ni `onboarding_completed_at`. |
| Repositorio Flutter | `lib/data/repositories/profile_repository.dart` hace `select()` y `upsert(... onConflict: 'id')`; las nuevas columnas podran leerse en `raw`, pero Fase 2B debe tiparlas. |

Tambien se ejecuto `supabase migration list --linked`; la lista remota estaba alineada con las migraciones locales hasta `20260727203000`.

## Tabla afectada

`public.profiles`

## Columnas anadidas

| Columna | Tipo | Final |
| --- | --- | --- |
| `onboarding_status` | `text` | `not null default 'pending'` |
| `onboarding_version` | `integer` | `not null default 1` |
| `onboarding_completed_at` | `timestamptz` | nullable, sin default |

No se usa enum PostgreSQL.

## Defaults

| Columna | Default |
| --- | --- |
| `onboarding_status` | `'pending'` |
| `onboarding_version` | `1` |
| `onboarding_completed_at` | ninguno |

Estos defaults cubren perfiles creados despues de la migracion por el upsert actual de Flutter, siempre que no envie explicitamente estas columnas.

## Constraints

| Constraint | Regla |
| --- | --- |
| `profiles_onboarding_status_check` | `onboarding_status in ('pending', 'in_progress', 'completed')` |
| `profiles_onboarding_version_check` | `onboarding_version >= 1` |
| `profiles_onboarding_completed_at_consistency_check` | `completed` exige `onboarding_completed_at is not null`; `pending` e `in_progress` exigen `onboarding_completed_at is null`. |

## Orden exacto del backfill

1. Abrir transaccion.
2. Crear tabla temporal con `statement_timestamp()` como timestamp tecnico de migracion.
3. Anadir `onboarding_status`, `onboarding_version` y `onboarding_completed_at` permitiendo temporalmente valores `null`.
4. Actualizar todas las filas existentes de `public.profiles` a:
   - `onboarding_status = 'completed'`
   - `onboarding_version = 1`
   - `onboarding_completed_at = migrated_at`
5. Configurar defaults para futuras filas:
   - `onboarding_status default 'pending'`
   - `onboarding_version default 1`
6. Aplicar `not null` a `onboarding_status` y `onboarding_version`.
7. Eliminar constraints previas con los mismos nombres, si existieran.
8. Crear constraints explicitas de valores, version y consistencia temporal.
9. Anadir comentarios de columna.
10. Commit.

El timestamp de `onboarding_completed_at` para filas existentes representa el backfill tecnico, no la fecha historica real de onboarding.

## Cuentas existentes

Todas las filas existentes de `public.profiles` antes de esta migracion quedan como `completed` con version `1` y timestamp tecnico unico de migracion.

La migracion no crea perfiles faltantes para usuarios de `auth.users` que no tengan fila en `public.profiles`, porque esta fase modifica la tabla real de perfiles existente y el flujo actual ya crea/asegura perfiles desde Flutter. Si en produccion existen usuarios sin perfil, seguiran requiriendo que `ProfileRepository.ensureCurrentProfile(...)` cree su fila; esa fila recibira defaults `pending/1/null`.

## Cuentas nuevas

Las nuevas filas de `public.profiles` creadas despues de la migracion empiezan automaticamente con:

```text
onboarding_status = pending
onboarding_version = 1
onboarding_completed_at = null
```

No se modifica ningun trigger. El trigger remoto `on_auth_user_created` llama a `public.handle_new_user()`, que enumera solo `id`, `email` y `display_name`; precisamente por omitir las nuevas columnas, PostgreSQL aplicara los defaults `pending`, `1` y `null`. Los triggers existentes sobre `public.profiles` (`set_profiles_updated_at` y `trg_profiles_validate_habit_time_zone`) no necesitan cambios.

## Revision RLS

No se cambia RLS.

Las politicas remotas actuales de `public.profiles` ya permiten:

- leer el perfil propio: `Users can view their own profile`, `auth.uid() = id`
- insertar el perfil propio: `Users can insert their own profile`, `with check auth.uid() = id`
- actualizar el perfil propio: `Users can update their own profile`, `using auth.uid() = id` y `with check auth.uid() = id`

Por tanto, cada usuario autenticado podra actualizar su propio estado remoto de onboarding cuando Fase 2B lo implemente. Las politicas no permiten leer ni actualizar perfiles de otros usuarios desde rol `authenticated`. No se duplicaron politicas ni se ampliaron permisos.

## Impacto previsto en Flutter para Fase 2B

Fase 2B debera modificar:

- `lib/data/models/remote/remote_profile.dart`: mapear `onboarding_status`, `onboarding_version`, `onboarding_completed_at`.
- `lib/data/repositories/profile_repository.dart`: exponer escritura explicita del estado de onboarding.
- Flujo de onboarding: marcar `completed` con timestamp al finalizar.
- Bootstrap/startup: leer estado remoto antes de decidir Welcome/Auth/Home.

Restricciones respetadas en Fase 2A:

- No se modifico Flutter.
- No se modifico `AppStartupGate`.
- No se modifico `AuthController`.
- No se modifico navegacion.
- No se aplico la migracion remotamente.
- No se uso Docker.
- No se ejecuto `supabase db reset`.
- No se ejecuto `supabase db push` sin `--dry-run`.

## Validaciones ejecutadas

| Comando | Resultado |
| --- | --- |
| `supabase --version` | Disponible: `2.90.0`. |
| `supabase migration list --linked` | Ejecutado correctamente; remoto y local alineados hasta `20260727203000`, y la nueva migracion local `20260727210441` aparece pendiente en remoto. |
| `supabase status` | Fallo esperado porque intenta inspeccionar Docker local; no se usa para esta fase. |
| `supabase db dump --linked --schema public` | No completo dentro del timeout disponible; no genero dump util. |
| `supabase db query --linked` sobre `information_schema.columns` | Confirmo columnas remotas reales de `public.profiles`, incluyendo `onboarding_completed boolean not null default false` preexistente. |
| `supabase db query --linked` sobre `pg_constraint` | Confirmo `profiles_pkey` y `profiles_id_fkey`; no habia constraints de las nuevas columnas. |
| `supabase db query --linked` sobre `pg_trigger` para `public.profiles` y `auth.users` | Confirmo `set_profiles_updated_at`, `trg_profiles_validate_habit_time_zone`, `on_auth_user_created` y `trg_auth_users_bootstrap_user_wallet`. |
| `supabase db query --linked` sobre `pg_proc` | Confirmo que `public.handle_new_user()` inserta `id`, `email`, `display_name` en `public.profiles` y omite las nuevas columnas, permitiendo defaults. |
| `supabase db query --linked` sobre `pg_policies` | Confirmo politicas reales: `Users can view/insert/update their own profile`, scoped por `auth.uid() = id`. |
| `rg` sobre `supabase`, `docs`, `lib/data/models/remote`, `lib/data/repositories`, `lib/application/auth` | Confirmo consumo Flutter actual y que no hay implementacion local de las nuevas columnas. |
| `supabase db push --linked --dry-run` | Ejecutado correctamente. Resultado: `Would push these migrations: 20260727210441_add_remote_onboarding_state.sql`. No se aplico nada remotamente. |
| `supabase db lint --linked` | Ejecutado. Reporta incidencias preexistentes en funciones ajenas a esta fase: warnings de volatilidad en `app_private.is_habit_scheduled_on` y `public.is_valid_habit_schedule`, errores de referencias ambiguas en `public.record_journal_entry` y `public.record_habit_log`, y warning de variable no leida en `public.reverse_habit_completion_reward`. No reporta incidencias especificas de la nueva migracion porque no esta aplicada en remoto. |

## SQL completo guardado

```sql
begin;

create temp table _rutio_remote_onboarding_state_migration_context (
  migrated_at timestamptz not null
) on commit drop;

insert into _rutio_remote_onboarding_state_migration_context (migrated_at)
values (statement_timestamp());

alter table public.profiles
  add column onboarding_status text,
  add column onboarding_version integer,
  add column onboarding_completed_at timestamptz;

update public.profiles
set
  onboarding_status = 'completed',
  onboarding_version = 1,
  onboarding_completed_at = (
    select migrated_at
    from _rutio_remote_onboarding_state_migration_context
  );

alter table public.profiles
  alter column onboarding_status set default 'pending',
  alter column onboarding_version set default 1;

alter table public.profiles
  alter column onboarding_status set not null,
  alter column onboarding_version set not null;

alter table public.profiles
  add constraint profiles_onboarding_status_check
  check (onboarding_status in ('pending', 'in_progress', 'completed')),
  add constraint profiles_onboarding_version_check
  check (onboarding_version >= 1),
  add constraint profiles_onboarding_completed_at_consistency_check
  check (
    (
      onboarding_status = 'completed'
      and onboarding_completed_at is not null
    )
    or (
      onboarding_status in ('pending', 'in_progress')
      and onboarding_completed_at is null
    )
  );

comment on column public.profiles.onboarding_status is
  'Remote onboarding state for startup/bootstrap decisions. Valid values: pending, in_progress, completed.';
comment on column public.profiles.onboarding_version is
  'Version of the remote onboarding contract understood by the app.';
comment on column public.profiles.onboarding_completed_at is
  'Timestamp when onboarding was marked completed. Backfilled rows use the migration timestamp, not the historical onboarding date.';

commit;
```

## Fase 2B - Integracion Flutter

### Modelo y enum

Se amplio `lib/data/models/remote/remote_profile.dart` con:

- `enum OnboardingStatus { pending, inProgress, completed }`
- `RemoteProfileParseException`
- `RemoteProfile.onboardingStatus`
- `RemoteProfile.onboardingVersion`
- `RemoteProfile.onboardingCompletedAt`

Mapeo Supabase:

| Flutter | Supabase |
| --- | --- |
| `OnboardingStatus.pending` | `pending` |
| `OnboardingStatus.inProgress` | `in_progress` |
| `OnboardingStatus.completed` | `completed` |

El modelo valida:

- `onboarding_status` desconocido: error de parseo controlado.
- `onboarding_version >= 1`.
- `completed` requiere `onboarding_completed_at`.
- `pending` e `in_progress` requieren `onboarding_completed_at = null`.
- Los timestamps se parsean con `DateTime.tryParse` y se serializan en UTC.

### Repositorio ampliado

Se amplio `lib/data/repositories/profile_repository.dart`:

- `fetchCurrentProfile()` devuelve el estado remoto real desde `public.profiles`.
- `markOnboardingInProgress({int onboardingVersion = 1})`.
- `markOnboardingCompleted({int onboardingVersion = 1})`.
- `currentUserIdProvider` opcional para tests sin sesion Supabase real.

`UserStateStore.onboardingDone` no se elimina ni se usa como fuente para leer el estado remoto.

### Transiciones

Permitidas por el contrato:

- `pending -> in_progress`
- `pending -> completed`
- `in_progress -> completed`
- `completed -> completed`

Implementadas ahora:

- `pending -> in_progress`
- `in_progress -> in_progress`
- `completed -> completed` como operacion idempotente sin escritura adicional

Bloqueadas:

- `completed -> pending`
- `completed -> in_progress`
- `in_progress -> pending`

### Tratamiento de errores

Se mantiene `RepositoryResult` y `RepositoryErrorCode`:

- perfil no encontrado: `notFound`
- estado remoto invalido o inconsistente: `invalidResponse`
- version menor que 1: `invalidResponse`
- error de permisos/RLS: `permissionDenied`
- error de red: `network`
- errores restantes: `unknown`

### Timestamp del servidor

No se envia una hora local para `onboarding_completed_at`.

La API directa de Supabase/PostgREST usada por `supabase_flutter` actualiza filas mediante JSON y no permite asignar de forma segura una expresion SQL como `now()` en `onboarding_completed_at`. Por eso `markOnboardingCompleted()` solo es idempotente cuando el perfil remoto ya esta en `completed`. Para completar perfiles `pending` o `in_progress` hace falta una pequena RPC en una fase posterior, por ejemplo `complete_onboarding(version integer)`, que ejecute en PostgreSQL:

```sql
onboarding_status = 'completed',
onboarding_version = greatest(input_version, 1),
onboarding_completed_at = now()
```

Esta decision evita fingir tiempo de servidor con el reloj del dispositivo.

### Tests anadidos

- `test/data/models/remote_profile_onboarding_test.dart`
- `test/data/repositories/profile_repository_onboarding_test.dart`

Cobertura:

- parseo de `pending`
- parseo de `in_progress`
- parseo de `completed` con fecha
- rechazo de estado desconocido
- rechazo de version menor que 1
- rechazo de `completed` sin fecha
- rechazo de `pending` o `in_progress` con fecha
- serializacion hacia Supabase
- actualizacion a `in_progress`
- idempotencia de `completed`
- bloqueo de transicion regresiva `completed -> in_progress`
- error controlado para `pending -> completed` hasta disponer de RPC con timestamp de servidor

### Pendiente para Bootstrap Gate

- Consumir `RemoteProfile.onboardingStatus` en el arranque.
- Definir comportamiento offline cuando no hay cache local y no se puede leer remoto.
- Sustituir gradualmente `UserStateStore.onboardingDone` como fuente de decision.
- Implementar RPC de completado remoto con timestamp del servidor antes de conectar pantallas de onboarding.
