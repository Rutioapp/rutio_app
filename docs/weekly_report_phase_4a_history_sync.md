# Weekly Report Phase 4A — History Sync

Estado: **READY_TO_REVIEW**. Esta subfase prepara datos históricos; no implementa el generator, UI, repository/cache ni finalización semanal.

## 1. Initial blockers

Phase 4 encontró que skip no llegaba al servidor, que `habit_logs` se eliminaba en cascada, que los upserts de configuración no transportaban un instante lógico local y que no existe una cola server-side de mutaciones pendientes.

## 2. Existing sync architecture

El flujo productivo es local-first y best-effort:

```text
UserStateStore.activeHabits/history
  -> SharedPreferences (UserStateRepository)
  -> HabitSyncService / HabitLogSyncService
  -> HabitRepository / HabitLogRepository
  -> Supabase public.habits / public.habit_logs
```

Check y count se escriben mediante el mismo upsert diario. Check usa `is_completed`; count usa `value` y `is_completed` cuando alcanza `target`. Skip se calculaba en el store pero se perdía en el mapper/payload. No hay cola persistente general para hábitos: la operación se lanza con `unawaited`, y el próximo sync/reintento vuelve a escribir el estado.

## 3. Activity history source

La fuente server-side sigue siendo `public.habit_logs`, con una fila por `(user_id, habit_id, log_date)`. Se añadió `is_skipped`; `habit_id` continúa siendo el UUID lógico aunque el hábito live ya no exista. El upsert existente conserva la unicidad y es idempotente para la misma fecha.

## 4. Skip persistence strategy

Se extendió `habit_logs` en la migración forward `20260901110000_weekly_report_history_sync.sql`. `is_skipped=false` es compatible con filas antiguas. La semántica única es: `isSkipped(user, habit, localDate) = habit_logs.is_skipped` de la fila owned; si no hay fila, es false. Unskip escribe la misma fila con `is_skipped=false`. Skip gana frente a completion y el denominador no se reduce.

## 5. Check/count server semantics

CHECK: `completed = is_completed AND NOT is_skipped`.

COUNT: `progress = value`; `completed = value >= target_effective AND NOT is_skipped`. Por tanto 5/10 es parcial, 10/10 y 12/10 son completed, y skip gana incluso sobre 12/10. La configuración efectiva del target procede de `weekly_report_habit_config_versions`.

## 6. Hard delete retention strategy

La causa era la FK `habit_logs.habit_id REFERENCES habits(id) ON DELETE CASCADE`. La migración elimina únicamente esa FK; no introduce soft-delete global. `user_id` mantiene FK a `auth.users` y ownership/RLS. El log queda consultable por UUID lógico y por fecha después del delete. La captura de configuración `delete` de Phase 3 permanece activa.

## 7. Effective mutation metadata

Al modificar plan, target, schedule, nombre, archive o atributos equivalentes, el store persiste antes del sync:

- `source_mutation_id`: UUID nuevo y estable para esa mutación;
- `effective_from`: instante UTC producido por el reloj lógico local;
- `effective_timezone_name`: snapshot IANA cuando el proveedor del dispositivo lo devuelve.

El mapper los envía en el upsert canónico de `public.habits`; no existe una ruta paralela Weekly Report.

## 8. Mutation id/idempotency

No había operation/request UUID reutilizable para estas mutaciones. Se usa el UUID persistido en el mapa local de la mutación. El trigger escribe `source_mutation_id` y la historia tiene unique parcial `(user_id, habit_id, source_mutation_id)`. Retries/duplicados actualizan `observed_at` sin crear otra versión.

## 9. Config history integration

```text
local mutation
  -> HabitSyncService
  -> HabitRepository upsert public.habits + metadata
  -> Phase 3 AFTER trigger
  -> weekly_report_habit_config_versions
```

El cliente nunca escribe `app_private`. El trigger valida el timezone IANA y acepta el instante local únicamente si no está más de cinco minutos en el futuro respecto a la observación; si falta metadata o no es válida, usa `updated_at`/observación server-side como fallback explícito.

## 10. Archive/delete behavior

Archive y desarchive pasan por el mismo update; quedan versionados como `archive` o `update`, con `is_archived` y metadata efectiva. Delete mantiene la captura `delete` de Phase 3 y, desde esta migración, no destruye activity logs. No se implementa restore.

## 11. Pending sync analysis

La capacidad actual es B/C: el servidor no conoce todas las mutaciones pendientes en dispositivos. El cliente conoce indirectamente que la llamada best-effort falló, pero no existe un ledger persistente general de dirty state/last successful sync para hábitos.

## 12. V1 late-sync policy

Un refresh provisional solo usa filas recibidas server-side y puede ejecutarse después de un sync exitoso. Finalization usa la última información recibida; no promete conocer cambios que nunca llegaron al backend. Una mutación tardía posterior a final requiere una política futura de rebuild explícita y no se implementa aquí.

## 13. Security/RLS

`user_id` sigue siendo obligatorio en activity y deriva del usuario autenticado en los repositories existentes. Se conservan RLS/policies de `habit_logs` para select/insert/update/delete own; no hay grants sobre `app_private`. El trigger es `SECURITY DEFINER` con `search_path=''`, referencias schema-qualified y validación server-side. El UUID lógico no permite consultar datos de otro usuario porque todas las consultas filtran `user_id` y RLS lo exige.

## 14. Backwards compatibility

Rows antiguas obtienen `is_skipped=false` y metadata nullable. La app anterior que omita el campo sigue leyendo/escribiendo logs normales. La nueva metadata es fiable desde rollout; no se intenta backfill perfecto ni se reinterpretan históricos ambiguos.

## 15. Generator data-readiness matrix

| DATA | SERVER AUTHORITATIVE? |
| --- | --- |
| check completion | YES |
| count progress | YES |
| skip | YES |
| effective config | YES (desde activation/rollout; fallback observado queda identificado por ausencia de mutation id) |
| deleted habit logs | YES |
| activation | YES |
| timezone | YES |

## 16. Remaining risks

- Mutaciones antiguas o clientes que no envíen metadata pueden tener effective time de observación.
- No existe detección server-side de pending sync por dispositivo.
- La semántica `timesPerWeek` y el cálculo completo de occurrences siguen siendo responsabilidad de Phase 4B.
- El timestamp enviado por cliente tiene consistencia razonable, no garantías de seguridad financiera; el límite de futuro y la validación IANA reducen abuso.

## Server activity contract futuro

Para `(user_id, habit_id, local_date)`, Phase 4B leerá `habit_logs` por la clave única y resolverá la config efectiva vigente en esa fecha desde `weekly_report_habit_config_versions`: `is_completed`, `value` e `is_skipped`. La ausencia de log significa no completed, progress 0 y no skipped. El `habit_id` es texto/UUID lógico y no se une obligatoriamente a `habits`, permitiendo reconstrucción tras hard delete.

## Final sync regression review

`HabitLogRepository` consulta por `user_id` y `habit_id` directamente. Las únicas referencias productivas adicionales son los helpers de streak protection, que primero cargan un hábito live para una operación de continuidad y no son consumidores del histórico de Weekly Report. No hay una policy ni query de lectura de logs que dependa de que exista la fila en `habits`; los logs huérfanos no reaparecen en `activeHabits` porque el pull de hábitos sigue consultando `public.habits`.

## Tests y alcance

Se añadieron verificaciones estáticas de la migración y del mapper skip. Los tests de dominio existentes ya cubren estados check/count; esta fase no implementa ni prueba un generator.
