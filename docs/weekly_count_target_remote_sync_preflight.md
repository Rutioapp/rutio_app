# Weekly Count Target — Remote & Sync Preflight

> Pre-flight de solo lectura para la FASE 4C. Este documento define el contrato remoto y las condiciones de convergencia; no implementa migrations, SQL ni cambios de producción.

## 1. Executive summary

La FASE 4A/4B ya tiene una semántica local coherente: `COUNT + targetPeriod=weekly` suma los logs diarios de lunes a domingo, mantiene un claim local durable por `habitId|weekStartLocal` y utiliza una transacción local determinista (`weekly_count_target:<habitId>:<weekStart>`). El hueco de production safety está en la frontera remota.

La conclusión es:

- `targetPeriod` debe ser una columna explícita `target_period` en `public.habits`, no un campo dentro de `schedule`.
- Hace falta una migration compatible antes de desplegar una app que escriba o lea weekly de forma funcional.
- Los mappers y el repositorio cloud actuales pierden el campo en local→remote y la hidratación local lo fuerza a `daily` en remote→local.
- El legacy sin campo se interpreta como `daily`, pero durante la ventana de rollout un remote legacy no debe sobrescribir un weekly local más nuevo.
- El ledger económico actual tiene buenas protecciones de request, source y fecha lógica, pero no expresa de forma nativa el periodo weekly ni una identidad de claim. No debe ser la única representación del achievement.
- Se recomienda un claim remoto separado, con unique `(user_id, habit_id, week_start_date)`. La autoridad económica seguirá siendo una operación de reward server-side idempotente, vinculada a ese claim.
- La carrera multi-device requiere una RPC transaccional de “ensure weekly reward” o una extensión equivalente del reward RPC actual. Dos `request_id` distintos no pueden depender solo de una cadena determinista enviada por el cliente.
- La edición de target/period puede cambiar la UI inmediatamente, pero invalida la elegibilidad económica de la semana abierta para la nueva configuración. La nueva elegibilidad comienza el lunes siguiente.
- El `weekly_report_habit_config_versions` existente es reutilizable como historial de configuración efectiva, pero es feature-scoped y server-only; no sustituye al claim ni debe convertirse en una dependencia runtime del cliente.

No se ha implementado ninguna de estas propuestas.

## 2. Current remote habit schema

### Fuente real inspeccionada

El contrato de `public.habits` está definido principalmente en `supabase/sql/supabase_backend_phase_9_schema_patch.sql` y ampliado por `20260725090000_add_habit_schedule.sql` y `20260901110000_weekly_report_history_sync.sql`. La tabla contiene:

| Concepto | Persistencia actual |
|---|---|
| identidad | `id uuid primary key` |
| propietario | `user_id uuid not null references auth.users(id) on delete cascade` |
| nombre/metadatos | `name`, `family_id`, `emoji`, `unit`, `color_id` |
| tipo | `habit_type text`, CHECK `check/count` |
| target | `target_count integer`, nullable pero validado por la app para COUNT |
| disponibilidad | `schedule jsonb`, normalizado a daily/weekly/once/timesPerWeek |
| archive | `is_archived boolean not null default false` |
| orden | `sort_order integer` |
| sincronización/historial | `created_at`, `updated_at`, `source_mutation_id`, `effective_from`, `effective_timezone_name` |

Los triggers actualizan `updated_at` y, tras la foundation de Weekly Report, capturan cambios de configuración efectiva. `habit_logs` mantiene un registro diario por `(user_id, habit_id, log_date)` mediante índice único; su `value` es la fuente remota del progreso numérico diario. El `habit_id` de `habit_logs` dejó de tener FK en la migration de history sync para conservar logs huérfanos tras un delete del hábito.

### Columna explícita frente a JSON

**Recomendación: columna explícita `target_period text not null default 'daily'`.**

Meter el valor dentro de `schedule` sería incorrecto: `schedule` responde “cuándo está previsto o disponible el hábito”, mientras que `target_period` responde “en qué ventana se acumula el target”. El contrato V1 permitido debe seguir siendo:

```text
habit_type=count
target_count=3
target_period=weekly
schedule={type: daily}
```

La columna debe tener CHECK `target_period in ('daily', 'weekly')`. Para CHECK la convención canónica será almacenar `daily`, aunque el campo no tenga efecto funcional. Así no hay tres representaciones de “no aplicable” y el default de base de datos permanece estable.

La migration debe normalizar cualquier valor inválido/null existente a `daily` antes de endurecer `NOT NULL`; no se necesita backfill destructivo de logs.

## 3. RemoteHabit mapping

### Flujo actual local → remoto

El flujo real es:

```text
activeHabits[*]
  -> HabitSyncService._syncUpsert
  -> HabitRemoteMapper.toRemoteHabit
  -> RemoteHabit.toUpsertMap
  -> HabitRepository.upsertHabitForCurrentUser
  -> public.habits
```

`RemoteHabit` transporta actualmente `habitType`, `targetCount`, `unit`, `schedule`, archive, timestamps y metadatos de configuración efectiva, pero no `targetPeriod`. `HabitRemoteMapper.toRemoteHabit` resuelve target y normaliza schedule; al construir `RemoteHabit` descarta cualquier `localHabit['targetPeriod']`. `RemoteHabit.toUpsertMap` tampoco emite `target_period`. `HabitRepository._habitColumns` tampoco lo selecciona.

Por tanto, hoy un weekly local llega a Supabase sin el dato y el servidor conserva el default/valor previo, normalmente daily.

### Flujo actual remoto → local

```text
public.habits
  -> HabitRepository.fetchHabitsForCurrentUser
  -> RemoteHabit.fromMap
  -> _mergeRemoteHabitIntoExistingLocal / _localHabitFromRemote
  -> activeHabits[*]
```

`RemoteHabit.fromMap` ignora `target_period`. `_mergeRemoteHabitIntoExistingLocal` actualiza type, target, unit, schedule y metadatos, pero no target period. `_localHabitFromRemote` inserta explícitamente `targetPeriod: daily` para todos los COUNT. Ese es el punto exacto donde un weekly remoto se perdería durante hydration.

La futura implementación debe añadir el campo en ambos mappers, en la lista de columnas y en el merge. Conviene conservar una señal de presencia (`hasExplicitTargetPeriod`) durante la transición, porque “ausente en una fila legacy” y “daily confirmado por la migration” no son el mismo hecho para resolver conflictos.

También debe entrar en el fingerprint de backfill; el fingerprint actual no incluye schedule ni target period y no es suficiente para identificar de forma segura dos configuraciones semánticamente distintas.

## 4. Local-to-remote sync

`HabitSyncService` hace writes optimistas locales y un espejo remoto best-effort. Create puede insertar sin UUID remoto; update/archive requieren UUID remoto. El repository intenta update scoped por `(user_id, id)` y, si no encuentra fila, inserta. Tras un insert devuelve el UUID y lo persiste en el hábito local mediante callback. Los errores se registran y no se lanzan a la mutación de UI; no existe una cola durable general de cambios de configuración equivalente a la de rewards.

Las ediciones estampan `sourceMutationId`, `effectiveFrom` y, cuando está disponible, `effectiveTimezoneName`. `updated_at` remoto se actualiza por trigger. La política de conflicto actual del pull es: reemplazar la configuración local solo cuando `remote.updatedAt` es posterior al `local.updatedAt`; si faltan timestamps, se conserva el local.

El cambio futuro debe incluir `targetPeriod` en:

1. la lectura del mapa local;
2. `RemoteHabit` y su normalización;
3. el payload upsert;
4. la respuesta seleccionada por `HabitRepository`;
5. el fingerprint/backfill;
6. el snapshot de configuración efectiva enviado al historial de Weekly Report.

El retry actual es best-effort y no garantiza orden si hay varias mutaciones offline. Para target/period, la siguiente fase debe conservar la mutation id y una marca de efectividad local; el servidor debe deduplicar `source_mutation_id` en config history y usar `updated_at/effective_from` únicamente con la política ya existente. No se debe asumir que el último HTTP request observado es el último cambio lógico.

## 5. Remote-to-local hydration

El merge remoto filtra por `user_id`, enlaza por UUID remoto y evita duplicados. Para un hábito existente exige tipo compatible y `updatedAt` remoto posterior. Para uno nuevo crea un id local `remote_<uuid>`. Los logs remotos se mezclan a granularidad diaria; en COUNT el `value` remoto se escribe en `history.habitCountValues` y no se sobreescribe un count local por un log remoto no-completado.

El riesgo de rollout es:

```text
local weekly, mutation todavía no confirmada
remote legacy sin target_period
remote updated_at posterior o mapper que hace default daily
=> local weekly podría degradarse silenciosamente a daily
```

La solución no es hacer que el mapper ignore siempre el remote. La solución es:

- migrar primero el esquema y hacer que el lector conozca el campo;
- diferenciar ausencia legacy de `daily` explícito mientras dura la compatibilidad;
- si el remote no trae el campo y el local tiene weekly con `sourceMutationId/effectiveFrom` pendiente o más reciente, conservar weekly y reintentar el upsert;
- después de que la migration haya materializado `daily` para legacy, tratar `daily` como una decisión remota explícita solo si su timestamp/mutation es realmente posterior;
- nunca cambiar target period por el merge de logs: los logs solo actualizan actividad diaria.

Si existe conflicto real entre dos configuraciones, gana la versión efectiva más nueva según la política de configuración, no el valor por defecto del mapper.

## 6. Backward compatibility

Contrato obligatorio:

| Entrada remota | Resultado local |
|---|---|
| columna ausente/null/valor inválido durante transición | `daily` como fallback seguro |
| `target_period='daily'` | `daily` |
| `target_period='weekly'` y `habit_type='count'` | `weekly` |
| `target_period='weekly'` y `habit_type='check'` | almacenar/normalizar `daily`; no tiene semántica funcional |

La columna final debe ser `NOT NULL DEFAULT 'daily'` con CHECK. El backfill es de configuración, no de progreso: no se recalculan ni borran `habit_logs` ni buckets locales. Los clientes antiguos que solo escriben las columnas conocidas no deben romper el row; el default deja daily. La app nueva no debe depender funcionalmente de weekly hasta que el schema y la lectura estén desplegados.

Cambiar de daily a weekly no debe reescribir la historia previa. La UI puede usar la nueva configuración desde su efectividad; la elegibilidad económica de la semana abierta se regula por el modelo de la sección 14.

## 7. Rollout ordering

Orden production-safe:

1. Revisar y aplicar migration de columna, CHECK, defaults, selección y permisos sin exponer todavía UI weekly remota.
2. Aplicar la ampliación de config history y de los payloads de report futuros para que una configuración weekly no se pierda en snapshots.
3. Aplicar la identidad remota de claims y el endurecimiento de reward/ensure RPC, con lecturas tolerantes a filas existentes.
4. Desplegar readers nuevos: mappers, hydration y reconciliación, con fallback daily y protección contra remote legacy stale.
5. Desplegar writers nuevos: sync de target period y source mutation idempotente.
6. Activar el feature gate para un cohort controlado y observar mismatches, claims y rewards duplicados.
7. Solo después habilitar creación/edición weekly en producción.
8. Ampliar cohort y eliminar el gate únicamente cuando la convergencia y la reconciliación estén verificadas.

La regla crítica es que no debe existir una ventana donde la app escriba weekly en un servidor que descarte la columna y luego hidrate ese mismo hábito como daily.

## 8. Current local achievement ledger

`LocalWeeklyCountAchievementLedger` usa SharedPreferences con una clave versionada y scopeada por usuario. Su identidad es `habitId|weekStartLocal`, donde la semana es lunes local. El payload contiene como mínimo la key y `achievedAt`; no depende de que el hábito siga activo. La escritura tiene una protección en memoria contra doble claim dentro del proceso y la lectura de payload corrupto es no destructiva.

Garantías actuales:

- un claim por hábito y lunes dentro de un scope local;
- supervivencia a reinicio si SharedPreferences conserva el scope;
- no se mezcla la cuenta entre usuarios;
- rollback de progreso no revoca el claim;
- re-entry posterior no crea otro claim local;
- no hay garantía cross-device ni atomicidad distribuida con Supabase;
- no es una fuente global de economía.

Debe mantenerse como cache/ledger offline-first durante la transición, pero la futura reconciliación debe poder reparar el estado desde claim remoto y reward ledger.

## 9. Current remote reward ledger

La tabla actual es `public.habit_currency_reward_ledger`. Sus defensas reales son:

- `request_id` UNIQUE;
- UNIQUE `(user_id, operation_type, source_type, source_id)`;
- índice/unique adicional UNIQUE `(user_id, operation_type, habit_id, logical_date_key)`;
- `operation_type` apply/reverse;
- `source_type` actualmente fijado a `habit_completion`;
- `source_id` y `completion_event_id` no vacíos;
- advisory locks por usuario, request y combinación hábito/fecha en las RPC actuales;
- RPC security-definer que deriva el usuario de `auth.uid()`;
- RLS y ausencia de grants directos de escritura.

La RPC valida `logical_date` como ISO date y usa el hábito remoto para calcular el reward. La infraestructura actual puede recibir el lunes como `logical_date_key`, y Fase 4B ya construye IDs deterministas con prefijo weekly en el cliente. Sin embargo, la base no tiene una columna de periodo/claim y no conoce el significado “semana weekly”; además, la unique actual por hábito+fecha no incluye periodo. Eso es suficiente como dedupe parcial para una única clase de operación, pero no es una identidad remota explícita de achievement weekly.

El FK actual `habit_id references public.habits(id) on delete cascade` es incompatible con conservar indefinidamente historia económica cuando se borra un hábito.

## 10. Global economic idempotency

La autoridad global debe ser el ledger económico remoto, no el claim local ni el `id` local de SharedPreferences. La regla recomendada es:

```text
una identidad económica = user + remoteHabitId + period + weekStart + rewardKind
```

El claim responde a “la semana alcanzó el objetivo”; la transacción responde a “la economía ya fue aplicada”. Un claim no debe pagar por sí mismo.

La transaction ID local `weekly_count_target:<habitId>:<weekStart>` es determinista, pero no existe actualmente como columna única en el ledger remoto y el RPC no la recibe. Por eso **no se puede afirmar que la transaction ID local ya tenga una unique constraint remota suficiente**. La protección disponible es indirecta mediante `request_id`, `source_id` y fecha lógica, y dos dispositivos podrían usar IDs distintos si el contrato no los obliga a resolver el mismo claim.

Recomendación: hacer que la operación server-side reciba la identidad del claim y asegure un único apply por claim, manteniendo `request_id` como idempotencia de transporte. El resultado idempotente debe devolver la transacción existente y sus deltas, nunca volver a aplicar boosts ni wallet.

## 11. Multi-device race

Caso Pixel/iPhone, ambos offline en `2/3`:

1. Ambos registran localmente `3/3` y crean el mismo `claimKey` lógico usando el UUID remoto del hábito y el lunes local.
2. El primer sync hace insert/ensure del claim y solicita el reward.
3. El segundo sync hace upsert idempotente del mismo claim y solicita el mismo ensure.
4. Una transacción server-side con lock por `(user, habit, week)` encuentra la fila/transaction ya aplicada y devuelve `is_idempotent=true`.
5. Cada dispositivo adopta el resultado remoto, elimina su pending operation y nunca aplica dos veces wallet/boost.

El servidor debe ser autoritativo para la economía. Si aún no puede validar todos los logs diarios sincronizados, puede aceptar un evento weekly generado por el cliente solo dentro de un rollout controlado; la fase posterior debe decidir si la elegibilidad se valida consultando logs server-side. No se debe mantener indefinidamente una economía basada en dos clientes que calculan independientemente la validez.

## 12. Claim/reward reconciliation

### Claim remoto sin reward

Un worker/sync de reconciliación, ejecutable al login, al sync de datos/rewards y por retry background cuando exista, debe consultar claims `pending` y llamar a `ensure weekly reward`. No debe depender de abrir Home. Si el reward está deshabilitado para el usuario, el claim debe converger a `not_applicable`; si está habilitado, a `granted` con la transaction remota asociada.

### Reward remoto sin claim

Si el ledger contiene un apply weekly con identidad reconocible pero falta el claim, la reconciliación debe crear o reparar el claim con `rewardStatus=granted`, usando `targetAtClaim`/`achievedAt` del evento o una marca de reparación explícita. **No debe volver a pagar.** Si la fila legacy no contiene suficiente metadata para reconstruir una semana, se conserva la transacción como autoridad económica y se crea un claim de auditoría con `targetAtClaim` desconocido o estado de reparación, sin inferir un segundo reward.

### Divergencia local/remota

Remote claim granted vence al claim local ausente. Remote claim o ledger existente no se borra porque el progreso visual haya bajado por una edición o decremento. El progreso actual se deriva de logs; el histórico económico se deriva de claim/transaction.

## 13. Target-edit exploit

Caso crítico:

```text
target 3, actual 2
editar a 2
actual 1 -> 2
```

No se debe detectar esa segunda llegada como una nueva oportunidad económica. La comparación de threshold debe estar ligada a una configuración de elegibilidad, no únicamente a `actual >= target`.

Política recomendada:

- la edición cambia de inmediato target/progreso visible;
- si cambia `target` o `targetPeriod` durante una semana abierta, la nueva configuración queda `rewardEligibleFromWeekStart = siguiente lunes`;
- la configuración anterior conserva su claim/reward ya obtenido o todavía pendiente según su identidad original;
- si no hubo claim anterior, la nueva configuración no puede crear reward esa semana;
- volver weekly después de pasar a daily en la misma semana no reabre la oportunidad: el lunes de elegibilidad sigue siendo el siguiente lunes.

El guard debe estar persistido o reconstruible remotamente; un booleano solo en memoria no sirve para restart ni multi-device.

## 14. Reward eligibility policy

Modelo mínimo recomendado: cada claim weekly debe almacenar la configuración efectiva que habilitó la oportunidad:

```text
claimKey = userId|remoteHabitId|weekStart
eligibleConfigVersion / eligibleFromWeekStart
targetAtEligibility
targetPeriodAtEligibility=weekly
```

La opción preferida es reutilizar la semántica de effective configuration history para obtener `eligibleFromWeekStart`, pero materializar en el claim los datos económicos relevantes. Así el claim sigue siendo estable aunque el historial general cambie.

Reglas:

- target edit midweek: UI cambia, reward weekly bloqueado para esa semana;
- daily→weekly midweek: UI puede mostrar suma semanal, reward weekly habilitado el lunes siguiente;
- weekly→daily: claim/reward weekly histórico permanece; no se revierte economía;
- daily target no crea claim weekly;
- target edit después de un reward: el reward anterior permanece y llegar al nuevo target no paga segundo reward en la misma semana;
- el siguiente lunes inicia una nueva identidad de periodo y puede ser elegible con la configuración vigente.

No se debe confiar en solo `targetAtClaim` para cerrar el exploit: hace falta saber cuándo la configuración se volvió elegible. El estado mínimo durable es `claimKey`, `weekStart`, `targetPeriod`, `targetAtEligibility` y `eligibleFromWeekStart` o referencia equivalente a la versión efectiva.

## 15. Existing config-history reuse

Sí existe infraestructura reutilizable: `weekly_report_habit_config_versions` guarda `effective_from`, `effective_local_date`, timezone, nombre, tipo, target, schedule, archive, `source_mutation_id` y eventos insert/update/archive/delete/explicit_sync. Sus índices y RPC interna de explicit sync ya soportan dedupe de mutation IDs. Los snapshots de report además son inmutables cuando finalizan y `habit_id` es una referencia lógica sin FK para preservar contexto histórico.

La reutilización recomendada es:

- ampliar el snapshot de configuración con `target_period`;
- hacer que el trigger considere el cambio de target period como cambio de configuración;
- usar su fecha efectiva para determinar la semana elegible;
- copiar los campos económicos mínimos al claim semanal.

No se recomienda que el runtime local consulte directamente `weekly_report_habit_config_versions`: sus tablas son server-only y su acceso está revocado para clientes. Tampoco se debe hacer depender el reward de que Weekly Report esté activado. El claim/reward necesita su propia representación remota, aunque comparta la política de effective dates.

## 16. Archive/delete semantics

Archive (`is_archived=true`) es reversible y debe conservar habit, logs, claims y rewards. Puede impedir nuevas mutaciones/rewards según la política de producto, pero no elimina historia.

Delete remoto actual borra `habits` y, por su FK cascade, puede borrar `habit_currency_reward_ledger`; eso es un riesgo económico crítico. El reward histórico no debe desaparecer ni revertirse. La migration futura debe quitar el cascade del FK económico, preferiblemente mantener `habit_id` como identidad lógica no-FK o cambiarlo a nullable con `on delete set null` y conservar `source_id/claim_key` inmutables. Para claims también se recomienda una referencia lógica sin FK destructiva o `set null` con identidad estable separada.

El delete de `habit_logs` ya quedó desacoplado de `habits`, por lo que los logs históricos pueden sobrevivir; el generador deberá seguir filtrando correctamente por configuración/archive.

Account delete sí puede eliminar datos personales mediante los FKs a `auth.users on delete cascade`. Es una política distinta: borrar la cuenta puede borrar claims, rewards y hábitos del usuario; borrar un hábito no.

## 17. RLS/security

Para `public.habits` y `habit_logs` ya existe RLS por `auth.uid() = user_id` y grants de owner. `habit_currency_reward_ledger` tiene RLS de lectura propia y no tiene escritura directa para el cliente; los RPC security-definer son la superficie de mutación.

Para claims nuevos:

- `user_id` debe referenciar `auth.users` con cascade de account delete;
- RLS debe habilitarse;
- lectura, si se expone, solo con `auth.uid() = user_id`;
- insert/update/delete directos deben revocarse o limitarse a un RPC validado, para impedir que el cliente fabrique claims granted;
- la RPC debe fijar `search_path`, derivar usuario de `auth.uid()`, validar UUID, lunes local y ownership lógico;
- no se deben conceder accesos a `app_private` ni a tablas internas de report.

La columna `target_period` hereda la seguridad de `habits`; no necesita una policy propia. La RPC de reward no debe confiar en un `user_id` recibido del cliente.

## 18. Recommended remote data model

### `public.habits`

Añadir `target_period text not null default 'daily'`, CHECK `daily|weekly`. Para CHECK se persiste daily. `schedule` permanece independiente.

### `public.weekly_count_achievement_claims`

Representación recomendada mínima:

| Campo | Contrato |
|---|---|
| `id` | UUID PK |
| `user_id` | UUID owner, cascade solo en account delete |
| `habit_id` | UUID remoto lógico, sin cascade destructivo |
| `week_start_date` | DATE, siempre lunes |
| `achieved_at` | timestamptz |
| `target_at_eligibility` | integer positivo |
| `target_period` | `weekly` |
| `eligible_from_week_start` | DATE |
| `completion_event_id` | identidad estable del evento |
| `reward_status` | `pending`, `granted`, `not_applicable` o `reconciliation_required` |
| `reward_transaction_id` | referencia/ID lógico nullable |
| timestamps | created/updated/reconciled |

Unique obligatorio: `(user_id, habit_id, week_start_date)`. Debe existir además una protección contra reutilizar el mismo `completion_event_id` para otro claim.

### Reward ledger

Extenderlo o añadir una ruta weekly explícita con `period`, `claim_id/claim_key`, `week_start_date` y source type diferenciado. La autoridad económica es la fila de ledger; el claim es la historia semántica. No usar una columna de fecha diaria para guardar lunes sin indicar periodo.

## 19. Exact migrations required

No se escribe SQL en este pre-flight. El plan exacto es:

### Migration A — target period de hábitos y snapshots de configuración

- tablas: `public.habits`, `weekly_report_habit_config_versions` y, para no perderlo en el payload histórico, `weekly_report_habits`/envelopes de report;
- tipo: `text`;
- default: `daily`;
- nullability: `NOT NULL` después de normalizar legacy;
- CHECK: `daily|weekly`;
- backfill: todos los existentes a daily; sin tocar logs;
- trigger: incluir el cambio de target period como cambio efectivo;
- RPC/generator: transportar el campo, aunque Statistics/Weekly Report no se modifiquen en esta fase;
- índices: no hace falta índice aislado en habits; history puede conservar sus índices por user/habit/effective time;
- rollback: primero desactivar la dependencia funcional, luego revertir lectores; no eliminar la columna mientras existan apps que la escriban.

### Migration B — claim weekly remoto

- tabla nueva `public.weekly_count_achievement_claims`;
- unique `(user_id, habit_id, week_start_date)` y unique lógico de event ID por usuario;
- CHECK de lunes, target positivo, `target_period='weekly'` y estados cerrados;
- FK a `auth.users on delete cascade`; no FK cascade a `habits` para conservar claims históricos;
- RLS de owner para lectura y RPC-only para mutaciones económicas;
- backfill: ninguno; los claims locales existentes se importan de forma idempotente durante reconciliación, con `achieved_at` local y marca de procedencia;
- rollback: conservar tabla y detener writes; no borrar claims/rewards automáticamente.

### Migration C — identidad económica weekly

- añadir al ledger un periodo/source/claim identity explícito o crear una ruta ledger equivalente;
- aceptar `weekly_count_target` como source type sin alterar la semántica de filas daily existentes;
- unique que incluya usuario, hábito, periodo, semana/claim y operación apply;
- request ID UNIQUE se mantiene como idempotencia de transporte;
- eliminar el `on delete cascade` del FK económico a habits o sustituirlo por una referencia no destructiva;
- preservar filas existentes y no recomputar deltas;
- RLS/grants permanecen RPC-only para escritura;
- rollback: mantener lectura de filas existentes y pausar la activación weekly, sin borrar ledger.

Una sola migration grande sería posible, pero se recomienda separar A de B/C para poder validar round-trip de configuración antes de habilitar economía.

## 20. RPC/transaction assessment

**Sí hace falta una operación server-side nueva o una extensión transaccional explícita para weekly.** El repository local actual protege restart y pending retry, pero no puede resolver dos dispositivos con requests distintos. La RPC debe, en una transacción:

1. validar auth, claim key, owner, lunes y configuración elegible;
2. insertar/upsertar el claim bajo unique;
3. tomar lock por user/habit/week o por claim;
4. localizar reward apply existente por claim identity;
5. aplicar wallet/boost solo si no existe;
6. marcar claim granted y devolver la misma transacción en retries.

La RPC diaria existente puede seguir intacta para daily. No se debe simular weekly pasando lunes a la RPC diaria sin `period/source/claim` porque mezcla semánticas y hace ambiguos los conflictos daily↔weekly.

## 21. Observability

Añadir en la futura implementación logs estructurados y métricas sin nombre/email/texto libre:

- `weekly_target_period_sync_mismatch` con user scope hash/ID técnico, habit UUID, local period, remote period y mutation ID;
- `weekly_claim_duplicate`;
- `weekly_reward_transaction_already_exists`;
- `weekly_claim_reconciliation_required`;
- `weekly_claim_reward_divergence`;
- `weekly_reward_pending_retry`;
- `weekly_config_effective_date_conflict`;
- contador de remote legacy fallback a daily;
- latencia y resultado de ensure RPC.

Los IDs técnicos deben seguir los patrones de logging actuales y no incluir nombre, emoji, unidad libre o contenido de hábito.

## 22. Feature-gate/rollout

No se encontró un feature gate dedicado a “remote weekly count target”. Hay flags relacionados con cloud rewards/demo, pero no uno que garantice schema + hydration + economic convergence para esta feature.

**Recomendación: sí, añadir conceptualmente un gate de rollout, pero no implementarlo en este pre-flight.** El gate debe bloquear la creación/edición y reward weekly si la capacidad remota no está confirmada; readers pueden seguir tolerando daily/legacy. El rollout debe empezar en cohort interno, observar round-trip y reconciliación, y solo después abrirse al resto.

## 23. Test strategy

Suites de implementación requeridas:

- Remote mapper: ausencia/null→daily; daily round-trip; weekly round-trip; CHECK normaliza daily.
- Repository: `target_period` aparece en SELECT/upsert y el payload no mezcla schedule.
- Sync: local weekly→remote weekly; retry conserva mutation; remote weekly→local weekly; legacy remote no degrada local weekly pendiente.
- Reward transaction: weekly ID/period separados de daily; restart y save failure.
- Cloud dedupe: mismo claim con dos requests produce una fila/delta; request retry devuelve idempotent; boosts una sola vez.
- Claims: duplicate `(user,habit,week)` produce un claim; reward-without-claim repara sin pagar; claim-without-reward reconcilia.
- Config edits: target edit midweek no reward; next Monday sí; daily→weekly midweek no reward; weekly→daily no reverse; target post-reward no segundo pago.
- Delete/archive: archive conserva; delete conserva claim/ledger económico; account delete elimina scope personal.
- Retry/conflict: timeout, restart, logout/login, dos dispositivos y respuesta remota fuera de orden.

No se debe modificar Statistics, Weekly Report, Notifications, Auth, streak ni `timesPerWeek` como parte de estas pruebas.

## 24. Exact implementation phases

### Fase 4C-1 — Remote target persistence

Aplicar Migration A, extender DTO/mapper/repository, preservar fallback legacy y añadir round-trip tests. Sin activar reward weekly.

### Fase 4C-2 — Remote claim identity

Aplicar Migration B, importar claims locales de forma idempotente, definir estados y reconciliation job/sync path. El claim debe sobrevivir restart, logout/login y delete de habit.

### Fase 4C-3 — Economic convergence

Aplicar Migration C y la RPC ensure weekly. Conectar el coordinator/pending operations a la identidad remota de claim, conservar offline-first y hacer que el ledger remoto sea la autoridad económica.

### Fase 4C-4 — Eligibility hardening

Conectar effective configuration history, materializar `eligibleFromWeekStart`/target at eligibility y probar target/period edits, archive, delete y timezone.

### Fase 4C-5 — Controlled rollout

Activar gate en cohort, observar mismatch/reconciliation/idempotency, reparar divergencias sin re-pagar y ampliar progresivamente.

Statistics, Weekly Report, Notifications y weekly streak quedan fuera de estas fases y requieren sus propios contratos posteriores.

## 25. Risks

1. Mapper incompleto puede convertir weekly a daily después de login.
2. `target_period` dentro de schedule mezclaría disponibilidad y target.
3. El ledger actual no tiene una identidad period-aware explícita.
4. Dos request IDs distintos pueden duplicar economía si no existe unique por claim.
5. El FK cascade actual puede borrar rewards al borrar habit.
6. El cliente puede intentar pagar sin que el servidor haya validado la suma semanal.
7. Config history está activado solo para usuarios/report activation y no es un ledger global.
8. Editar target puede reabrir threshold si se usa solo `actual >= target`.
9. Una mutation offline tardía puede tener `effective_from` distinto de `updated_at` observado.
10. Daily y weekly con el mismo lunes pueden colisionar con la unique actual por fecha.
11. Un reward remoto sin claim puede quedar invisible semánticamente si no hay reparación.
12. Un claim sin reward puede reintentarse desde dos dispositivos sin lock.
13. `habit_id` local y UUID remoto no deben mezclarse en claim keys.
14. Cambiar timezone puede cambiar el lunes local si no se conserva la timezone efectiva.
15. Archive/delete y account delete tienen políticas de retención distintas.
16. El feature gate actual no cubre todo el round-trip remoto.
17. Cualquier backfill destructivo de logs rompería estadísticas históricas.
18. El baseline de `timesPerWeek` no debe confundirse con una regresión de weekly target.

## 26. Critical decisions

1. **¿Dónde persiste `targetPeriod`?** En `public.habits.target_period`, con copia en configuración histórica/report snapshots.
2. **¿Hace falta migration?** Sí, antes de que la app nueva escriba o dependa de weekly.
3. **¿Default legacy?** `daily`; null/ausente/inválido también resuelve daily en readers.
4. **¿Cómo se evita weekly→daily?** Migration primero, mapper bidireccional, presencia del campo durante transición y merge protegido por mutation/effective timestamp.
5. **¿Claim remoto separado?** Sí. El reward ledger actual no conserva suficientemente la semántica de achievement, elegibilidad ni estados pending/not-applicable.
6. **¿Fuente global económica?** Reward ledger remoto, asegurado por identidad de claim; nunca SharedPreferences ni transaction ID local aislado.
7. **¿Unique transaction actual suficiente?** No de forma explícita para weekly; request/source/date ofrecen dedupe parcial, pero falta periodo/claim identity.
8. **¿RPC nueva?** Sí, una ensure/apply weekly transaccional o extensión equivalente con lock y unique de claim.
9. **¿Dos dispositivos offline?** Mismo claim key remoto, unique `(user,habit,week)`, lock server-side y respuesta idempotente.
10. **¿Claim sin reward?** Reconciliación automática fuera de Home que llama ensure y marca granted/not-applicable.
11. **¿Reward sin claim?** Reparar claim desde ledger/identidad económica y no volver a pagar.
12. **¿Target-edit exploit?** Separar configuración visible de `eligibleFromWeekStart`; edición midweek no habilita reward esa semana.
13. **¿Estado mínimo?** Claim key, semana, target/period de elegibilidad, fecha de elegibilidad, achievedAt y reward status/transaction.
14. **¿Reutilizar config history?** Sí como fuente de effective dates y snapshot; no como sustituto del claim ni dependencia directa del runtime local.
15. **¿Delete habit?** Archive conserva todo; hard delete conserva claim/ledger económico y no debe usar cascade económico. Account delete sí elimina el scope personal.
16. **¿Migrations exactas?** A: target period/config history; B: claims; C: ledger period-aware/FK económico no destructivo.
17. **¿Rollout?** Schema/readers → claims/ledger → writers → reconciler/RPC → gate cohort → activación amplia.
18. **¿Feature gate?** Sí, recomendado para impedir UI/reward weekly antes de round-trip seguro; no se añade ahora.
19. **¿Siguiente fase?** Implementar Fase 4C-1, empezando por Migration A y tests de mapping/round-trip; detener reward remoto hasta cerrar B/C.

### Tests de inspección ejecutados

| Suite | Resultado |
|---|---|
| `test/data/mappers/habit_schedule_cloud_mapper_test.dart` | Passed |
| `test/data/repositories/habit_remote_fetch_repository_test.dart` | Passed |
| `test/stores/user_state_store_habits_remote_pull_test.dart` | Passed |
| `test/stores/user_state_store_habits_cloud_test.dart` | Passed |
| `test/stores/user_state_store_reward_persistence_test.dart` | Passed |
| `test/stores/user_state_store_reward_boosts_test.dart` | Passed |
| `test/features/habits/application/habit_currency_reward_coordinator_test.dart` | Passed |
| `test/supabase/add_habit_reward_logical_unique_index_migration_static_test.dart` | Passed |
| `test/features/weekly_report/data/weekly_report_history_rpc_migration_test.dart` | Passed |
| `test/supabase/weekly_report_history_sync_migration_static_test.dart` | Passed |

No se ejecutaron migrations reales ni RPCs contra Supabase. No existe una suite aislada para `LocalHabitRewardTransactionRepository`; sus garantías se inspeccionaron y se cubren indirectamente desde persistencia/coordinator.

### Alcance de cambios

En esta tarea solo se creó este documento. No se modificó production code, migrations, SQL, tests, Statistics, Weekly Report, Notifications, Auth, streak ni `timesPerWeek`.
