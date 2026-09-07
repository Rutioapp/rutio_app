# Flexible Weekly Check — Weekly Report Preflight

Estado: auditoría y diseño técnico únicamente. Rama auditada: `feature/weekly-count-target`.

No se modifica producción en esta fase. No se modifican Statistics V3, Home,
`CompletedDayPhrase`, rewards, Auth, ARB, Supabase, RPCs ni migrations.

## 1. Executive summary

Weekly Report ya tiene una arquitectura propia y un generador backend
transaccional. La fuente actual es:

```text
weekly_report_activations
  + weekly_report_habit_config_versions
  + habit_logs
  → app_private.generate_or_refresh_weekly_report
  → public.weekly_reports / weekly_report_days / weekly_report_habits
  → owner-scoped RPC payload
  → RemoteWeeklyReport
  → mapper
  → WeeklyReport domain
  → WeeklyReportController
  → WeeklyReportScreen / copy / groups
```

El resultado de la auditoría es `PARTIALLY` respecto al contrato flexible final:

- `timesPerWeek` sí se trata como cuota semanal; no se expande a siete
  obligaciones diarias.
- La cuota usa una fórmula ponderada por días elegibles y una sola operación
  de redondeo para varios segmentos.
- La configuración histórica, el rango lunes-domingo y el timezone IANA están
  materializados en backend.
- `completedCount` se calcula desde `habit_logs` y se deduplica de facto por el
  índice único `(user_id, habit_id, log_date)`, pero se limita a la cuota.
- `4/3` no puede conservarse: el generador usa `least(...)` y la base de datos
  impone `completed_count <= scheduled_count`.
- El skip flexible no reduce cuota ni suma completion, pero actualmente se
  descarta del campo `skipped` de la ocurrencia y de `skippedCount`, porque la
  ocurrencia flexible no está marcada como `scheduled`.
- El provisional actual prorratea la cuota sobre los días observados hasta hoy.
  Eso es correcto para una creación/elegibilidad parcial, pero no para una
  configuración que ya existía el lunes: el contrato Statistics requiere cuota
  completa desde el inicio de la semana y solo restringe los días contados.

La recomendación es la opción **C**: mantener el backend/RPC como cálculo
canónico, adaptar el contrato de snapshot para transportar valores raw y capped,
y añadir contract tests de paridad con Statistics. No se recomienda que Weekly
Report ejecute directamente el helper Dart como segundo cálculo canónico.

## 2. Current Weekly Report architecture

### Aplicación y dominio

- `lib/features/weekly_report/application/weekly_report_controller.dart`
  - `WeeklyReportController.load()` resuelve latest, id o semana actual.
  - `_loadCurrentWeek()` obtiene timezone local, resuelve lunes, lee el reporte
    exacto y solicita `refreshProvisional()` si falta o es provisional.
  - `refreshCurrentWeek()` solo refresca reportes provisionales de la semana
    actual.
- `lib/features/weekly_report/application/weekly_report_activation_service.dart`
  - `WeeklyReportActivationService.ensureActivated()` es idempotente por
    `userId|scopeEpoch`.
  - Envía la fecha local de hoy y el timezone IANA a `activate()`.
- `lib/features/weekly_report/domain/weekly_report.dart`
  - Modela `WeeklyReport`, `WeeklyReportSummary`, `WeeklyReportDay`,
    `WeeklyReportHabit`, `WeeklyReportTrend`, recomendaciones, historial,
    snapshot/cache y estados de UI.
  - Los contadores actuales son `scheduledCount`, `completedCount`,
    `skippedCount` y `completionRate`; no existe un par separado raw/capped.
- `lib/features/weekly_report/data/remote/remote_weekly_report.dart`
  - Valida schema/versiones, rangos de rate, fechas, estados, schedules y
    occurrences remotas.
- `lib/features/weekly_report/data/remote/weekly_report_mapper.dart`
  - Convierte el payload a los modelos de dominio.
  - Reconstruye fechas del reporte como fechas locales date-only.
  - Reconoce `HabitOccurrenceScope.weeklyQuota` y
    `HabitScheduleType.timesPerWeek`.
- `lib/features/weekly_report/data/weekly_report_repository.dart`
  - `SupabaseWeeklyReportRemoteDataSource` consume los RPCs.
  - `SupabaseWeeklyReportRepository` aplica scope de usuario, cache, fallback
    offline, refresh, historial y protección contra resultados stale.
- `lib/features/weekly_report/presentation/weekly_report_copy_resolver.dart`
  - Solo resuelve keys persistidas por backend a localización Flutter. No
    calcula ratios ni remaining.
- `lib/features/weekly_report/presentation/screens/weekly_report_screen.dart`
  - `WeeklyReportScreen` y `_ReportContent` muestran rango, banners, resumen,
    gráficos, hábitos, recomendaciones y reflexión.
- `lib/features/weekly_report/presentation/screens/weekly_report_history_screen.dart`
  - Lee páginas de historial y abre un reporte por id; no recalcula métricas.
- `lib/features/weekly_report/presentation/widgets/weekly_report_habits_section.dart`
  - Agrupa por clasificación backend y muestra filas, ratio, porcentaje, dots y
    estado diario de occurrences.
- `lib/features/weekly_report/presentation/widgets/weekly_report_recommendation.dart`
  - Renderiza la recomendación backend; reconoce `timesPerWeek` al preparar la
    revisión de configuración.
- `lib/features/weekly_report/presentation/widgets/weekly_report_reflection.dart`
  - Persistencia de reflexión vinculada al `reportId`; no es fuente de métricas.
- `lib/features/weekly_report/presentation/weekly_report_visuals.dart`
  - Solo colores, barras y decoración visual.

### Backend/RPC y snapshot

La implementación está repartida cronológicamente entre:

- `supabase/migrations/20260901090000_create_weekly_report_foundation.sql`
  - tablas de activación, configuración histórica, reportes, días, hábitos y
    recomendaciones; RLS, ownership, constraints de fechas e inmutabilidad.
- `supabase/migrations/20260901110000_weekly_report_history_sync.sql`
  - `is_skipped`, captura de `effective_from`, timezone y mutation metadata.
- `supabase/migrations/20260901130000_weekly_report_generator.sql`
  - `weekly_report_week_bounds`, `weekly_report_effective_config`,
    `weekly_report_schedule_matches`, `weekly_report_prorated_quota`,
    `generate_or_refresh_weekly_report` y `finalize_weekly_report`.
- `supabase/migrations/20260904100000_weekly_report_live_provisional.sql`
  - versión efectiva más reciente del generador; limita provisional al día
    local actual y conserva finales inmutables.
- `supabase/migrations/20260901150000_weekly_report_read_api.sql`
  - `get_my_weekly_report`, `get_my_latest_weekly_report`,
    `list_my_weekly_reports` y `refresh_my_weekly_report`.
- `supabase/migrations/20260902100000_weekly_report_habit_classification.sql`
  - clasificación basada en rate y trigger de snapshot.
- `supabase/migrations/20260903120000_weekly_report_contextual_copy.sql`
  - familias de copy y keys persistidas.
- `supabase/migrations/20260903150000_weekly_report_phase_12_automation.sql`
  - automatización Sunday provisional / Monday final y exact-week read.
- `supabase/migrations/20260902120000_weekly_report_recommendation_v1.sql`
  - recomendación histórica para reducción de frecuencia.

## 3. Current data pipeline

```text
user + habits + habit_logs
  → habit config trigger / activation snapshot
  → weekly_report_habit_config_versions
  → backend effective config per local date
  → pg_temp.wr_days + pg_temp.wr_occurrences + pg_temp.wr_habits
  → weekly_reports, weekly_report_days, weekly_report_habits
  → weekly_report_payload JSONB
  → SupabaseWeeklyReportRemoteDataSource
  → RemoteWeeklyReport.fromJson
  → mapRemoteWeeklyReport
  → WeeklyReportController state
  → WeeklyReportScreen and widgets
```

La distribución actual de responsabilidades es:

| Métrica | Capa que calcula hoy | Observación |
|---|---|---|
| Semana, fechas y timezone | Backend | Lunes-domingo y timezone de activación. |
| `scheduledCount` | Backend generator | Días diarios/fixed weekdays + cuota flexible. |
| `completedCount` | Backend generator | `habit_logs`, con cap al scheduled actual. |
| `skippedCount` | Backend generator | Días scheduled; flexible actualmente queda en cero. |
| `completionRate` | Backend | `completed / scheduled`, limitado a 0..1. |
| estado/grupo del hábito | Backend trigger | `highlighted`, `stable`, `needs_attention`, `unavailable`. |
| trend | Backend generator | Compara rates contra el último reporte final. |
| highlights/recommendations | Backend | Keys/clasificación y recommendation snapshot. |
| unavailable | Backend + mapper/UI | `scheduled=0`, rate nulo/invalid o clasificación unavailable. |
| copy localizada | Flutter resolver | No vuelve a calcular la métrica. |
| barras/porcentajes visuales | Flutter | También hace clamp visual del rate a 0..1. |

No hay un `WeeklyReportMapper` que lea el store local y reconstruya el reporte.
El mapper existente es `mapRemoteWeeklyReport`; la materialización es backend.

## 4. Current `timesPerWeek` handling

La decisión explícita del generador es:

```sql
v_scheduled := case when v_cfg.schedule->>'type' = 'timesPerWeek'
  then false
  else weekly_report_schedule_matches(...)
end;
```

Por tanto, el flexible no crea siete obligations diarias. Cada fecha elegible
puede tener una occurrence informativa, pero el scheduled denominator flexible
se añade como una cuota semanal en `q.weekly_quota`.

Hay, sin embargo, tres problemas de contrato:

1. `wr_habits.completed_count` usa `least(..., weekly_quota)`: conserva solo el
   valor capado.
2. Las constraints de `weekly_reports`, `weekly_report_days` y
   `weekly_report_habits` rechazan `completed_count > scheduled_count`.
3. `skipped` se pone en la occurrence solo cuando `o.scheduled` es true; como
   flexible es `scheduled=false`, el skip no aparece en el snapshot flexible.

Conclusión de las tres preguntas de auditoría:

- A) ¿Cuota semanal? **Sí**, en el generador backend.
- B) ¿Expansión diaria incorrecta? **No** en el denominator; sí existe una
  representación por fecha que debe mantenerse claramente como activity,
  nunca como obligación.
- C) ¿Política igual a Statistics? **Parcialmente**: misma idea de cuota
  ponderada, distinta semántica de current partial, raw/over-target y skip.

## 5. Comparison with Statistics V3

Statistics V3 usa `FlexibleWeeklyQuotaEvaluator`,
`FlexibleWeeklyQuotaPeriodAggregator` y `TimesPerWeekQuotaPolicy` en:

- `lib/features/habits/domain/metrics/flexible_weekly_quota.dart`
- `lib/features/habits/domain/metrics/flexible_weekly_quota_period_aggregator.dart`
- `lib/features/habits/domain/metrics/times_per_week_quota_policy.dart`

La evaluación Dart cuenta fechas locales distintas de completion, excluye
skips, calcula `scheduledQuota`, conserva `rawRatio` y expone `cappedRatio`.
El aggregator evita duplicar una cuota al cruzar periodos.

Resultado: **PARTIALLY equivalent**.

| Concept | Statistics V3 | Weekly Report current | Recommended canonical |
|---|---|---|---|
| `completedDays` | Fechas locales distintas, excluyendo skip | Logs por fecha única, luego capped | Raw distinct `habitId + localDateKey`. |
| quota | `TimesPerWeekQuotaPolicy.proratedCeil` | `ceil(sum(quota_i * eligibleDays_i) / 7)` | Una fórmula canónica de segmentos; mismo resultado en full week. |
| skip | No completion, no quota reduction | No completion, no quota reduction; no se expone bien en flexible occurrence | No completion, no quota reduction y snapshot visible si se muestra. |
| pending | No es miss semanal | No se usa como completion; futuro debe no inferir miss | No obligación diaria para flexible. |
| over-target | Raw `4/3`, capped visual 100% | Imposible: `least` + DB constraint | Raw `4/3`, capped score solo visual/classification. |
| raw ratio | Expuesto | No existe; rate capado | Exponer raw ratio y capped ratio. |
| capped ratio | Expuesto explícitamente | Único `completionRate` | Mantener ambos. |
| partial week | Current week conserva quota completa si la config cubre lunes; range limita completions | Provisional limita días a hoy y prorratea sobre esos días | Separar eligibility de elapsed observation. |
| `createdAt` | Segment/default activeFrom | Config effective date desde activation | Usar effective config history y creation boundary. |
| archive | `archivedAt`/segment boundary si se entrega | Config version `is_archived` desde activation | Archive effective local date, sin inventar pre-activation history. |
| config change | Segmentos explícitos | Historial backend efectivo por fecha | Backend history como autoridad. |
| timezone | Local date utilities | `timezone_name` de activation + local date SQL | Mismo IANA timezone y date-only contract. |
| data quality | verified/fallback/unverifiable | Sin quality field equivalente | Propagar verified/partial/unverifiable. |

No se debe “reutilizar” un DTO de Statistics en la pantalla. La reutilización
debe ser conceptual y de fórmula/contract tests.

## 6. Canonical weekly contract

Para `check + schedule.type=timesPerWeek + timesPerWeek=N`:

- el hábito está disponible cada día elegible;
- cada fecha puede ser pending, completed o skipped;
- `completedDays` es el número de fechas locales distintas completadas;
- una fecha skipped no suma completion y no reduce quota;
- pending no equivale a missed obligation;
- `scheduledQuota` es `N` en una semana completa elegible, o la cuota
  `proratedCeil` de los días realmente elegibles de un segmento parcial;
- la interacción sigue permitiendo completar después de alcanzar cuota;
- `completedDays` raw puede superar quota: `4/3`, `5/3`;
- `rawRatio = completedDays / scheduledQuota`;
- `cappedRatio = clamp(rawRatio, 0, 1)` solo donde una score/barra/threshold lo
  necesite;
- no hay weekly bonus, reward ledger, weekly COUNT ni `targetPeriod`;
- ninguna métrica depende de `CompletedDayPhrase` o reward transactions.

## 7. Backend calculation

El backend es la capa que actualmente calcula y materializa todas las métricas.
Para cada día obtiene el `effective_config` más reciente antes del límite local,
lee el log exacto de `habit_id + log_date`, y produce occurrences con clave
`(habit_id, local_date)`.

Para flexible:

```text
weeklyQuota = ceil(sum(configuredTimesPerWeek_i * eligibleDays_i) / 7)
scheduledCount = dateBoundScheduledCount + weeklyQuota
completedCount = dateBoundCompletedCount
                 + min(flexibleCompletedDays, weeklyQuota)
```

La fórmula de cuota es conceptualmente equivalente a la policy compartida para
una semana completa y para segmentos unidos, pero no es equivalente en el
provisional actual porque `wr_days` solo contiene días hasta `v_local_today`.

El backend no usa reward transactions ni `count` weekly para completion de un
CHECK. Para CHECK se consulta `habit_logs.is_completed`; para COUNT se consulta
`value >= target_count`.

## 8. Client calculation

El cliente no calcula hoy el Weekly Report desde `UserStateStore`:

- `RemoteWeeklyReport.fromJson` valida tipos y límites.
- `mapRemoteWeeklyReport` convierte schedules, occurrences y snapshots.
- `WeeklyReportController` orquesta carga/refresh/cache.
- la pantalla consume los números ya materializados.

El helper Dart `weeklyReportHabitFromMetrics` existe en el dominio, pero no es
el camino usado por `SupabaseWeeklyReportRepository`; tampoco hay integración
del `FlexibleWeeklyQuotaPeriodAggregator` en Weekly Report.

Esto evita una doble fuente de cálculo, pero también significa que no puede
corregirse `4/3` solo en UI: el payload y las constraints actuales ya lo han
perdido.

## 9. Source of truth decision

Decisión recomendada: **C — backend mantiene cálculo canónico y cliente
reutiliza modelos/contract tests**.

Razones:

- Weekly Report ya es un snapshot histórico, protegido por ownership y
  finalización inmutable.
- El backend tiene la configuración histórica y el timezone necesarios para
  reproducir periodos anteriores.
- El cliente no recibe actualmente toda la información para reconstruir
  segmentos, archive intervals y target changes.
- Duplicar el cálculo completo en Dart produciría divergencia entre Statistics y
  Weekly Report.

El helper compartido debe servir como especificación ejecutable de fórmula y
como fuente de casos de contrato. El backend debe tener pruebas equivalentes,
no una segunda llamada en runtime al helper Dart.

## 10. Completed days

Fuente actual: `public.habit_logs`, consultado por `user_id`, `habit_id` y
`log_date`. `habit_logs` tiene índice único
`(user_id, habit_id, log_date)`, por lo que el backend recibe un único estado
por fecha y el `primary key (habit_id, local_date)` de la tabla temporal evita
duplicar occurrences.

Esto equivale a contar fechas distintas bajo el schema actual, pero la intención
debe hacerse explícita en una prueba de idempotencia. No se usan rewards,
transactions, `value` para CHECK ni registros de sync como fuente alternativa.

Problema actual: después de contar, el backend capea el resultado. El contrato
futuro debe transportar al menos:

```text
completedDaysRaw
scheduledQuotaRaw
rawRatio
cappedRatio
```

La deduplicación lógica recomendada sigue siendo `habitId + localDateKey`; una
segunda escritura de la misma fecha debe ser un upsert idempotente, no una
segunda completion.

## 11. Skip and pending semantics

### Skip

El backend sí calcula `v_completed = false` cuando `v_skipped` es true, por lo
que un skip no incrementa completion. Tampoco participa en la fórmula de cuota.
Eso cumple la parte matemática.

No cumple completamente la observabilidad: para flexible, `v_scheduled=false`
y el insert de occurrence usa `case when v_scheduled then v_skipped else false
end`; además `skipped_count` cuenta solo `scheduled and skipped`. El row de
flexible puede perder el skip aunque el log lo tenga.

Plan recomendado: conservar `skipped` como estado diario de actividad para
flexible, pero nunca incluirlo en `completedDays` ni restarlo de quota.

### Pending

El backend no genera una métrica `missedDays` ni `expectedDaily` para flexible.
Una fecha no completada aparece como una occurrence no scheduled, no como una
obligación fallida. No se encontró una expansión `failureDays` aplicable al
flexible.

La regla debe conservarse: no convertir pending diario en miss semanal.

## 12. Over-target

Actualmente `4/3` es imposible en el Weekly Report:

- el `least(..., weekly_quota)` capea `completed_count`;
- las constraints de report, day y habit exigen `completed_count <= scheduled_count`;
- `completion_rate` está restringido a `0..1`.

El contrato recomendado conserva raw `4/3` en el modelo y en el snapshot. Una
barra, ring, percentage label o threshold puede usar `cappedRatio=1.0`; la fila
de hábito debe mantener `4/3` y no mostrar texto negativo o “remaining -1”.

## 13. Raw vs capped

Hoy `WeeklyReportSummary` y `WeeklyReportHabit` guardan solo
`completedCount`, `scheduledCount` y `completionRate`, y el schema SQL refuerza
la versión capada.

Diseño aditivo recomendado, sin mezclar responsabilidades:

```text
completedCount       = raw completed days
scheduledCount       = raw scheduled quota
completionRate       = rawRatio (si el nombre se mantiene por compatibilidad)
completedScoreRate   = cappedRatio
```

Preferiblemente usar nombres explícitos `rawCompletedCount`,
`rawScheduledCount`, `rawCompletionRate` y `cappedCompletionRate` en una nueva
versión de payload/modelo. Durante compatibilidad, el mapper puede tratar el
campo antiguo como capped/legacy y marcar la calidad como legacy, pero no debe
inventar raw.

## 14. Partial week

El reporte representa una semana calendario completa lunes-domingo, con una
vista provisional que solo observa hasta el día local actual.

Actualmente:

- `week_start_date` debe ser lunes y `week_end_date` domingo;
- el generador provisional incluye días `activation_local_date..local_today`;
- el final solo se finaliza después del siguiente lunes local;
- `first_partial_week` es true cuando la activación cae después del lunes.

El problema es que el mismo recorte se reutiliza para quota. Una habit flexible
existente desde lunes termina provisionalmente con quota menor el martes,
miércoles, etc. La policy recomendada es:

```text
completion observation range = eligible dates through local today
quota range for an already eligible current-week config = full eligible week
quota range for a midweek-created config = dates from effective creation onward
```

No usar días transcurridos como sustituto de eligibility.

## 15. Created midweek

El backend tiene soporte mejor que un simple `currentConfig`:

- `weekly_report_habit_config_versions` guarda `effective_from` y
  `effective_local_date`;
- la captura de INSERT registra el evento desde la fecha efectiva;
- el generador ignora fechas anteriores a `v_cfg.effective_local_date`;
- la quota puede prorratearse con los días elegibles posteriores a la creación.

Por tanto, con `target=3` creado el miércoles y cuatro días elegibles
miércoles-domingo, la policy esperada es `ceil(3*4/7)=2` para esa primera semana,
no obligaciones lunes/martes.

La exactitud depende de que la creación esté registrada después de la activación
y de que `effective_from/effective_timezone_name` sean válidos. Si no hay esa
historia, la salida debe ser partial/unverifiable, no una reconstrucción
retrospectiva.

## 16. Archived midweek

Después de la activación, el trigger captura `is_archived` como nueva versión,
con `source_event='archive'`, `effective_from` y fecha local. El generador
selecciona la configuración efectiva para cada fecha y omite la fecha desde la
que la configuración archivada es efectiva.

El comportamiento por fecha es coherente con la regla de granularidad local del
generador: una configuración efectiva en un día local gobierna ese día completo.
La fecha de archive debe quedar definida en el contrato futuro para evitar
ambigüedad de cambios a mitad del día.

Limitación: el historial es feature-scoped y empieza en activation; no es
event-sourcing global. Archive ocurrido antes de activar Weekly Report no puede
reconstruirse como intervalo histórico a partir de esta tabla.

## 17. Configuration history

La respuesta es **YES desde activation; PARTIALLY como historia global**.

Existe:

- append-only-like `weekly_report_habit_config_versions`;
- `effective_from`, `effective_local_date`, timezone, schedule, target y
  `is_archived`;
- captura automática de insert/update/archive/delete;
- `source_mutation_id` único por `(user_id, habit_id)` cuando se proporciona;
- `weekly_report_effective_config()` con orden determinista;
- seam privada `record_weekly_report_habit_config_version()` para sincronización
  tardía.

No existe un event log global anterior a la activación. No debe degradarse esta
infraestructura a `currentConfigFallback` cuando el snapshot backend sí tiene
history suficiente. La calidad futura debe diferenciar `verified` desde
activation de `unverifiable` fuera de ese alcance.

## 18. Target changes

El generador resuelve la configuración efectiva por fecha, por lo que el caso
`Mon-Tue target=3`, `Wed-Sun target=4` se divide en segmentos y calcula una
cuota ponderada:

```text
ceil((3 * eligibleDaysSegmentA + 4 * eligibleDaysSegmentB) / 7)
```

La implementación usa un único `ceil` para la suma y evita inflar el resultado
redondeando cada segmento por separado. La captura histórica es suficiente para
cambios posteriores a activation.

La policy recomendada es no aplicar el target actual retrospectivamente. Si
falta el segmento histórico o hay conflicto de effective metadata, reportar
partial/unverifiable; no sustituir silenciosamente por la configuración actual.

## 19. Global denominator

El denominator actual es schedule-native para una semana completa:

```text
daily scheduled days
+ fixed weekday scheduled days
+ flexible weekly quotas
```

Así, `daily=7`, `weekdays=3`, `flexible=3` da `13`, no `17`. El generador suma
la quota flexible a nivel de hábito y evita sumar sus occurrences no-scheduled
como siete obligations.

La limitación provisional es de rango: antes del domingo el componente diario y
la quota se construyen solo con el conjunto observado hasta hoy. La futura
implementación debe conservar el denominator schedule-native y separar el
periodo de observación de la elegibilidad de quota.

## 20. Grouping

La clasificación backend es:

```text
scheduled = 0 o rate null/invalid → unavailable
rate >= 0.80                  → highlighted
rate < 0.50                   → needs_attention
resto                         → stable
```

Aplicado a quota flexible con rate capado:

| Caso | Rate capado | Grupo actual esperado |
|---|---:|---|
| 0/3 | 0.00 | needs attention |
| 1/3 | 0.33 | needs attention |
| 2/3 | 0.67 | stable |
| 3/3 | 1.00 | highlighted |
| 4/3 | 1.00 | highlighted, si se soporta raw |

`4/3` no debe caer por debajo de `3/3`. No existe una señal separada de
overachievement; no se recomienda crearla en esta fase.

## 21. Trend/improvement

El backend compara `completion_rate` actual con el rate del último reporte final
anterior. Es comparación por ratio, no por count. Si no hay anterior, es first
partial o algún denominator es cero, el trend queda unavailable.

Consecuencias del contrato:

- `2/3 → 3/3`: mejora.
- `3/3 → 4/3`: neutral si ambos usan capped ratio.
- `2/2 → 3/4`: empeora aunque el count suba.

La recomendación es calcular trend con `cappedRatio` comparable y conservar raw
para explicación. No comparar counts entre quotas distintas.

## 22. Copy resolver

`WeeklyReportCopyResolver` no contiene fórmulas de `remaining`; resuelve keys
como `summary_*` y `habit_*`. Las familias se eligen backend con status,
partial, trend, scheduled y rate. Por eso no hay actualmente un string que
produzca “-1 pending”.

El riesgo para `4/3` está en que el snapshot no puede llegar a la UI raw y en
que el row hoy concatena `completedCount/scheduledCount` con `completionRate`.
El ajuste futuro debe:

- mostrar `4/3` desde raw counts;
- usar capped rate en percentage/ring y clasificación;
- evitar cualquier copy basada en `scheduled - completed` sin `max(0, ...)`;
- mantener keys backend y no introducir copy de Statistics.

## 23. Screen impact

| Componente | Decisión | Motivo |
|---|---|---|
| Overall summary | ADAPT | Añadir raw/capped sin rediseñar el card. |
| Summary percentage/ring | ADAPT | Ring clamp a capped ratio; accesibilidad debe conservar raw. |
| Habit rows/cards | ADAPT | Mostrar `2/3`, `3/3`, `4/3`; no usar solo rate legacy. |
| Day dots/occurrences | ADAPT | Mantener actividad flexible por fecha y hacer visible skip si el producto lo muestra. |
| Groups | KEEP + ADAPT | Seguir clasificación backend; soportar raw over-target. |
| Unavailable | KEEP | Respetar falta de schedule/history/quality. |
| Highlights | KEEP | Keys y clasificación siguen siendo backend-owned. |
| History | ADAPT contrato | Renderizar raw/capped desde snapshot versionado. |
| Refresh/cache | KEEP + ADAPT versioning | No romper final immutability ni cache ordering. |
| Monthly/other periods | NO CHANGE | Fuera de alcance; solo helpers de contrato si se necesitan. |

No hay motivo para rediseñar pantalla ni para cambiar rutas, deep links o
notifications por esta adaptación semántica.

## 24. Data quality

La calidad actual es alta para datos posteriores a activation porque el backend
conserva effective metadata. No es una garantía global: la tabla se documenta
como “not global event sourcing”.

El payload actual no transporta `verified`, `currentConfigFallback` o
`unverifiable`. El siguiente contrato debería propagar una calidad por hábito y
posiblemente por summary. Si history no cubre todo el intervalo, el reporte
debe decir partial/unavailable y no afirmar una quota exacta.

Los datos legacy sin `is_skipped` o sin metadata histórica no deben convertirse
en skip/completion inventado. La fuente continua siendo el log canónico y la
calidad debe reflejar sus límites.

## 25. Timezone/week boundaries

La policy actual es local y consistente en lo principal:

- el backend usa `weekly_report_activations.timezone_name`;
- `weekly_report_week_bounds()` crea lunes 00:00 a lunes siguiente 00:00 en
  timezone IANA, con DST-safe `at time zone`;
- provisional calcula `v_local_today` en ese timezone;
- el cliente obtiene el timezone desde `UserStateStore` para resolver la semana
  actual;
- occurrences y days se reconstruyen como fechas date-only locales;
- notification deep link usa el `dateKey` de lunes y abre la semana exacta.

El invariant futuro es que Home, Statistics y Weekly Report compartan la misma
semántica `habitId + localDateKey` y el mismo Monday-Sunday local. Deben cubrirse
midnight, DST y límites Sunday/Monday. No debe usarse timestamp UTC convertido
de forma distinta en una capa.

## 26. Backend/client duplication

La duplicación relevante es matemática, no de runtime: Statistics tiene helper
Dart detallado; Weekly Report tiene SQL propio. Hoy divergen en:

- raw vs capped;
- quota provisional de config existente desde lunes;
- visibilidad de skips flexibles;
- quality metadata expuesta.

Estrategia recomendada:

1. fijar ejemplos contractuales comunes;
2. ejecutar esos ejemplos contra helper Dart y fixtures/SQL backend;
3. versionar la policy con `metricsPolicyVersion`;
4. mantener mapper assertions para no perder raw/capped/quality;
5. evitar que UI o reward ledger se conviertan en fuentes de cálculo.

No eliminar ni reescribir la implementación duplicada en este preflight.

## 27. Supabase change assessment

Respuesta: **YES, probablemente hace falta un cambio backend/RPC/migration
aditivo para cumplir el contrato completo**.

Motivo: el backend actual no puede entregar raw `4/3`; lo elimina mediante
`least(...)` y lo impiden constraints y validación de rates. Además, el snapshot
flexible no conserva correctamente `skipped`.

Si el equipo decide mantener `completedCount` como capped por compatibilidad,
se necesitarían campos raw nuevos en tablas/payload y versionado de RPC. Si se
renombra el contrato existente, se requerirá una versión de schema. En ambos
casos no es una migración que deba hacerse ahora.

No se recomienda mover todo el cálculo al cliente para evitar la migration:
faltaría config history completa, el backend seguiría siendo inconsistente y
los reportes finales perderían autoridad histórica.

## 28. Versioning/cache implications

El modelo ya tiene `schemaVersion`, `metricsPolicyVersion` y `contentVersion`.
Actualmente todos parten de versión 1; el cache local es schema 1.

Recomendación:

- bump de `metricsPolicyVersion` cuando cambie la semántica de quota/raw/capped;
- bump de `schemaVersion` solo si cambia de forma incompatible el payload;
- `contentVersion` solo si cambian pools/keys de copy;
- no mutar silenciosamente reportes finales ya finalizados;
- no usar un report legacy capado como si tuviera raw verificable.

`SupabaseWeeklyReportRepository` conserva snapshots finales y no los sobrescribe;
los provisionales solo avanzan si `refreshedAt` es posterior. Una nueva policy
debe afectar nuevos refreshes/reportes o tener una operación explícita de
regeneración/backfill, con decisión de producto sobre la historia visible.

## 29. Existing test coverage

Suites localizadas:

- `test/features/weekly_report/domain/weekly_report_domain_test.dart`
- `test/features/weekly_report/data/weekly_report_repository_test.dart`
- `test/features/weekly_report/data/weekly_report_history_rpc_migration_test.dart`
- `test/features/weekly_report/application/weekly_report_controller_test.dart`
- `test/features/weekly_report/presentation/weekly_report_copy_resolver_test.dart`
- `test/features/weekly_report/presentation/weekly_report_copy_catalog_integrity_test.dart`
- `test/features/weekly_report/presentation/weekly_report_habits_section_test.dart`
- `test/features/weekly_report/presentation/weekly_report_recommendation_test.dart`
- `test/features/weekly_report/presentation/weekly_report_visuals_test.dart`
- `test/features/weekly_report/presentation/weekly_report_screen_composition_test.dart`
- tests de reflection y composition asociados.

Verificaciones SQL estáticas relevantes:

- `supabase/tests/weekly_report_foundation_static_verification.sql`
- `supabase/tests/weekly_report_generator_static_verification.sql`
- `supabase/tests/weekly_report_live_provisional_static_verification.sql`
- tests de read API, history sync, classification, recommendation y copy.

La cobertura existente sí verifica schemas, RLS, function signatures, formula
de proration, Monday boundary, history seams, refresh provisional y render
legacy. No cubre aún el contrato completo raw/capped, 4/3 persistido, skip
flexible visible, current-week full quota ni paridad SQL/Dart ejecutada sobre
los mismos fixtures.

## 30. Required tests

Tests futuros obligatorios, sin cambiar Home/Statistics/rewards en esta fase:

1. `target=3`, Mon/Wed/Fri complete → `3/3`.
2. Añadir Sat complete → raw `4/3`, capped `100%`.
3. Mon complete, Tue skip, Wed/Fri complete → `3/3`; skip no cambia quota.
4. `target=3`, dos completions → `2/3`.
5. Denominator mixto daily 7 + weekdays 3 + flexible 3 → `13`.
6. Habit creada Wednesday: no contar Mon/Tue; aplicar `proratedCeil`.
7. Habit archived midweek: no contar fechas posteriores y validar fecha de
   archive según la policy local elegida.
8. Target cambia midweek: usar segmentos históricos, no current target
   retrospectivo.
9. Dos registros lógicos de la misma fecha/upsert → un solo completed day.
10. DST y transición Sunday/Monday en el timezone del reporte.
11. Previous/current trend por ratios: `2/3→3/3`, `3/3→4/3` neutral con cap,
    `2/2→3/4` declined.
12. History incompleta o metadata conflictiva → partial/unverifiable, sin
    inventar quota.
13. Pending flexible no produce `missedDays`.
14. Skip flexible queda separable de completion y visible en occurrence si la
    UI lo expone.
15. Contract parity: mismos fixtures contra SQL generator y
    `FlexibleWeeklyQuotaEvaluator`/`PeriodAggregator`.
16. Version/cache: final legacy no se sobrescribe implícitamente y provisional
    refresca solo con policy/payload compatible.
17. Notification/deep link con `weekStart` Monday abre la semana exacta; si no
    existe, cae a history sin alterar el rango.

## 31. Implementation phases

### WR-FLEX-1 — canonical calculation/backend alignment

- decidir si la fórmula SQL será la autoridad definitiva;
- corregir la separación current observation vs full-week eligibility;
- conservar skip flexible como estado de actividad;
- añadir SQL/fixture contract tests contra la policy acordada;
- definir la migración de raw/capped y quality.

### WR-FLEX-2 — mapper/domain snapshot contract

- añadir raw/capped/quality de forma versionada;
- conservar compatibilidad con snapshots legacy sin inventar raw;
- adaptar remote validation, cache serialization y history item;
- afirmar que `weeklyQuota` no se interpreta como siete daily schedules.

### WR-FLEX-3 — screen/groups/copy

- mostrar `completed/quota` raw en summary y habit rows;
- usar capped ratio para ring, percentage, thresholds y trend;
- revisar copy con over-target y skip flexible;
- mantener los grupos y el layout actuales.

### WR-FLEX-4 — regression + QA

- ejecutar casos 1–17;
- probar final/provisional, cache offline, DST, activation boundary y deep link;
- validar historical snapshots y decision de regeneración/backfill;
- QA manual solo después de cerrar el contrato backend.

Si se decide que el backend ya es correcto tras una revisión de producción, WR-FLEX-1
se puede reducir a mapper/contract tests. La auditoría del código local no
permite tomar esa decisión hoy porque `4/3` está explícitamente capado.

## 32. Risks

- Añadir raw sin revisar constraints puede provocar rechazo SQL antes de llegar
  al mapper.
- Usar el rate raw para ring o classification puede hacer que `4/3` dibuje más
  de 100% o caiga en un grupo incorrecto.
- Cambiar provisional a quota completa puede confundirse con contar futuras
  completions; son conceptos distintos.
- Tratar skip flexible como scheduled volvería a introducir miss diario.
- Falta de history anterior a activation no se puede reparar con current config.
- Regenerar finales puede romper la expectativa de snapshot inmutable.
- Cambios de timezone en activation requieren distinguir boundary histórica de
  timezone de futuras automatizaciones.
- Los logs pueden llegar tarde; effective metadata y observed metadata deben
  mantenerse separados.

## 33. Critical decisions

1. ¿Weekly Report trata `timesPerWeek` como cuota semanal? **Sí**.
2. ¿Existe expansión diaria incorrecta? **No en denominator; la occurrence
   diaria debe seguir siendo informativa, no obligation**.
3. ¿Cómo calcula `completedDays`? **Desde `habit_logs` por local date única,
   pero hoy lo capea al quota**.
4. ¿Cómo calcula quota? **Suma ponderada de `configuredQuota * eligibleDays`
   con un `ceil` global y denominator 7**.
5. ¿Skip reduce quota? **No; el cálculo matemático cumple, aunque la visibilidad
   flexible del skip debe adaptarse**.
6. ¿Pending diario cuenta como miss? **No debe**.
7. ¿Se conserva o capea `4/3`? **Debe conservarse raw; hoy se capea**.
8. ¿Dónde capear visualmente? **Solo score, ring, porcentaje y thresholds; no
   raw counts ni supporting copy**.
9. ¿Cómo partial weeks? **Hoy por días observados; debe separar observación de
   elegibilidad y mantener cuota completa para config existente desde lunes**.
10. ¿Created midweek correcto? **Correcto si existe history post-activation;
    partial/unverifiable si falta**.
11. ¿Archived midweek correcto? **Correcto post-activation mediante effective
    config y granularidad local; no verificable pre-activation**.
12. ¿Hay config history suficiente? **Sí desde activation; no como global
    history**.
13. ¿Target changes? **Se segmentan por effective config; no usar current target
    retrospectivamente**.
14. ¿Global denominator schedule-native? **Sí en semana completa: daily + fixed
    weekdays + flexible quota; provisional necesita corrección de rango**.
15. ¿Trend usa ratios o counts? **Ratios**; recomendado capped ratios.
16. ¿Grouping soporta over-target? **Solo indirectamente por cap; raw 4/3 aún no
    atraviesa el backend actual**.
17. ¿Copy soporta 4/3? **No hay copy negativa hoy, pero el payload/UI no puede
    mostrar raw 4/3 aún**.
18. ¿Backend y Statistics misma policy? **Partially**.
19. ¿Source of truth? **Backend/RPC, con contract tests contra Statistics**.
20. ¿Reutilizar directamente `FlexibleWeeklyQuotaPeriodAggregator`? **No en
    runtime; sí como referencia y parity test**.
21. ¿Supabase/RPC change? **YES, probablemente**, por raw/capped, constraints y
    skip flexible.
22. ¿metricsPolicyVersion bump? **Sí al cambiar la semántica; no hacerlo ahora**.
23. ¿Reportes ya generados? **Finales permanecen inmutables; nuevos contratos
    requieren versionado y decisión explícita de backfill/regeneration**.
24. ¿Fases? **WR-FLEX-1 backend, WR-FLEX-2 mapper/domain, WR-FLEX-3 UI/copy,
    WR-FLEX-4 regression/QA**.

## Verification

Esta fase solo crea este documento. No se ejecutó ninguna modificación de
producción ni se cambiaron migrations/RPCs. Se ejecutó:

- `flutter test test/features/weekly_report`: 50 tests passed y 1 fallo
  preexistente en `preserves a valid provisional report when refresh fails`.
  El fixture no inyecta `now` y `_isCurrentWeek()` usa la fecha real, por lo que
  el reporte fijo de 2026-08-31 deja de ser la semana actual cuando el reloj del
  entorno avanza; el fallo se reprodujo también aisladamente.
- Tests estáticos focalizados `test/supabase/weekly_report*_test.dart`: 9 tests
  pasaron y 1 fallo preexistente en la aserción de recommendation migration,
  que espera saltos de línea LF mientras el archivo SQL auditado está en CRLF.
- `git diff --check`: sin errores; solo warnings normales de conversión
  LF/CRLF en archivos ya modificados del worktree.

El único archivo añadido por esta tarea es este documento. Se preservan todos
los cambios preexistentes del worktree.

## WR-FLEX-4 closure addendum — 2026-09-07

La implementación posterior mantuvo la migración preparada como cambio local
y añadió raw/capped, quality, actividad flexible y compatibilidad legacy en las
capas ya previstas. Durante la regresión de tres segmentos se encontró un
desvío concreto: el evaluator Dart redondeaba cada segmento por separado,
mientras el contrato backend suma la cuota ponderada y aplica un único `ceil`.
Se corrigió en `FlexibleWeeklyQuotaEvaluator` y se añadió el caso H3; ahora el
resultado coincide con el backend y conserva el exceso raw.

Resultado disponible localmente:

- Weekly Report: 82/82.
- Dominio relacionado y routing de notificaciones: 35/35.
- Migración canónica estática: 6/6.
- Análisis focalizado: sin incidencias.
- Supabase local/RPC real: no disponible porque no hay daemon/contenedor local.
- Despliegue remoto: no ejecutado.

La limitación restante es de infraestructura y validación manual: ejecutar la
matriz backend real, DST en dispositivos y smoke QA requiere un entorno
Supabase/dispositivo habilitado. No se cambia la conclusión de inmutabilidad ni
se autoriza backfill de reportes finales.
