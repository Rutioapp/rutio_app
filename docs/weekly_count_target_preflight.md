# Weekly Count Target — Technical Preflight

> Pre-flight técnico de solo lectura. No se implementa la feature en este documento.

## 1. Executive summary

El repositorio no tiene una clase única `Habit` persistida. El contrato está repartido entre:

- mapas dinámicos en `UserStateStore.state.userState.activeHabits`;
- `HabitSnapshot`, `HabitKind` y `HabitSchedule` para métricas y Weekly Report;
- `OnboardingHabitConfiguration` para el formulario tipado de onboarding;
- `RemoteHabit`/`RemoteHabitLog` para Supabase.

Hoy un COUNT se representa con `type: 'count'`, `target` local, `unit` opcional y un `schedule` independiente. Su progreso es diario: `history.habitCountValues[YYYY-MM-DD][habitId]`. `doneToday` equivale, en la práctica, a alcanzar el target de ese día.

La frontera correcta para la nueva capacidad es añadir un dato de configuración de target, separado de `schedule`:

```text
kind        = count | check
target      = valor positivo
unit        = unidad opcional
targetPeriod = daily | weekly   // relevante solo para count; default daily
schedule    = disponibilidad/ocurrencia del hábito
```

Recomendación principal: `targetPeriod` debe ser independiente de `timesPerWeek`. `timesPerWeek` ya es una cuota de ocurrencias del schedule para CHECK y tiene un contrato semanal distinto.

Para un COUNT semanal, la suma semanal debe derivarse de los logs diarios de lunes a domingo usando la fecha local. Los logs no se borran al cambiar de semana. El target puede superarse y el progreso visual debe mostrar el valor real, por ejemplo `4 / 3 esta semana`.

La decisión semántica crítica recomendada es tratar el COUNT semanal como progreso semanal, no como una obligación diaria. Debe tener una señal separada de `dailyActivity`/`weeklyTargetMet`; no debe marcarse como “completed today” por llegar a `3/3` en un día ni quedar pendiente diariamente por no registrar cada día. Home, perfect day, streaks y recompensas diarias necesitan una clasificación neutral o específica de weekly count.

La persistencia local puede ser backward compatible con campo ausente => `daily`. Para Supabase, la solución arquitectónicamente correcta requiere una migración de esquema y de snapshots de Weekly Report, porque `target_period` pertenece a la configuración del hábito, no al JSON de schedule.

## 2. Current count habit model

### Fuentes reales

| Capa | Archivo / símbolo | Contrato actual |
|---|---|---|
| Dominio de métricas | `lib/features/habits/domain/metrics/habit_snapshot.dart` — `HabitKind`, `HabitSnapshot` | `HabitKind.check` o `HabitKind.count`; `HabitSnapshot.target` y `HabitSnapshot.schedule`; no existe target period. |
| Schedule | `habit_snapshot.dart` — `HabitScheduleType`, `HabitSchedule` | `daily`, `weekly`, `once`, `timesPerWeek`; contiene weekdays, date, timesPerWeek y `weekStartsOn`. |
| Estado local | `lib/stores/user_state_store_habits.dart` — `_addCustomHabit`, `_addHabitFromCatalog`, `_updateHabitDetailsFromEdit` | Mapa dinámico con `type`, `target`, `unit`, `unitLabel`, `schedule`, `progress`, `doneToday`, `skippedToday`. |
| Store/historial | `lib/stores/user_state_store_core.dart`, `user_state_store_habit_progress.dart` | JSON bajo `userState.activeHabits` y `userState.history`. |
| Onboarding | `lib/features/onboarding/domain/models/onboarding_habit_configuration.dart` | Modelo tipado con `kind`, `schedule`, `targetValue`, `unit`; tampoco existe target period. |
| Remote habit | `lib/data/models/remote/remote_habit.dart` — `RemoteHabit` | Columnas `habit_type`, `target_count`, `unit`, `schedule`; no existe `target_period`. |

No se encontró una clase de dominio persistida llamada `Habit`; el “habit real” de la app es un mapa local que atraviesa adaptadores.

### COUNT frente a CHECK

`HabitKindX.fromString` normaliza `count`, `counter` y `numeric` a `HabitKind.count`; cualquier otro valor cae en CHECK. En los mapas locales, `_normalizedHabitType` de `user_state_store_habits.dart` hace la misma normalización.

Para COUNT:

- `target` es el target local actual;
- `targetCount`/`goal`/`times` son aliases de lectura o payload remoto, no un contrato único;
- `unit` y `unitLabel` son aliases del mismo concepto;
- `familyId` identifica la familia/pilar;
- `schedule` define cuándo está previsto/visible el hábito, no el periodo del target.

Para CHECK el target se fuerza habitualmente a `1`; la completion procede de `habitCompletions[dateKey][habitId]`.

### Dónde vive el target diario

El target diario vive hoy en `activeHabits[*]['target']`. El progreso del día vive en `activeHabits[*]['progress']` durante la sesión y en `history.habitCountValues[dateKey][habitId]` como historial canónico local. `UserStateStorage` serializa todo el root con `jsonEncode` en `user_state_v1_<userId>` de SharedPreferences.

## 3. Current count logging/progress

La cadena actual es:

```text
HabitCardWidget +/- o edición de valor
  -> HomeScreen / UserStateStore.setCountHabitValueForDate
  -> _setCountHabitValue / _setCountHabitValueForDate
  -> _setCountHabitProgress
  -> activeHabits.progress + doneToday
  -> history.habitCountValues[dateKey][habitId]
  -> history.habitCompletions / habitSkips
  -> SharedPreferences save
  -> best-effort HabitLogSyncService
  -> Supabase habit_logs
```

### Registro y acumulación

- `habitCountValues` guarda una cantidad por hábito y fecha local; no guarda un total semanal precomputado.
- `_setHabitCountValueForDay` reemplaza el valor del día, no lo suma automáticamente.
- El botón `+` calcula `current + counterStep`; el botón `-` calcula `current - counterStep` y limita a cero.
- El diálogo de edición reemplaza el valor por el input introducido.
- Los valores negativos quedan limitados a cero.
- Se permite superar target: no existe cap al target en `_setCountHabitProgress` ni en `HabitCardWidget`; el ring visual actual sí limita el ratio a `1.0`.
- `doneToday` se establece a `safeValue >= target` para COUNT.
- `habitCompletions` se sincroniza desde `habit['doneToday']`; para COUNT también se persiste el valor en `habitCountValues`.

El sync remoto escribe una fila diaria mediante `HabitLogRemoteMapper.toRemoteHabitLog` y `HabitLogRepository.upsertDailyLog`. `RemoteHabitLog.value` es la cantidad del día; `is_completed` se calcula desde el flag o `value >= target`; `is_skipped` tiene precedencia.

El pull remoto aplica el valor a `habitCountValues[dateKey]` y marca completion si `remoteLog.isCompleted || remoteValue >= _habitTarget(localHabit)`. El merge preserva la granularidad diaria.

## 4. Current completion semantics

### Ocurrencia y progreso

`HabitOccurrenceEvaluator.evaluate` usa:

- `countCompleted = progress >= target` para COUNT no `timesPerWeek`;
- `completed = scheduled && !skipped && (completed flag || countCompleted)`;
- `HabitOccurrenceScope.dateBound` para COUNT normal.

Para `schedule.type == timesPerWeek`, la ocurrencia se modela como `HabitOccurrenceScope.weeklyQuota`, no como siete targets diarios. Esto es un contrato de schedule, no de target.

### Home y resumen diario

`buildHabitDaySummary` lee `habitCompletions`, `habitCountValues` y `habitSkips` de una fecha. Para COUNT normal, hace:

```text
doneToday = !skipped && (doneFromSelectedDay || value >= target)
```

Después clasifica el hábito en `pendingHabits`, `completedHabits` o `skippedHabits`.

La única excepción semanal existente es CHECK + `schedule.type == timesPerWeek`: se calcula `weeklyCompletedCount` y `isWeeklyTargetMet`; un hábito pasa a completed si la cuota semanal está alcanzada aunque ese día no tenga log.

### Porcentaje y día completado

- `HabitDaySummary.progressRatio = completedCount / totalCount`.
- `CompletedDayEligibility` cuenta los hábitos de `viewHabits`, excluye solo los `timesPerWeek` flexibles y exige `pending == 0`, `skipped == 0` y `completed == scheduled`.
- `completed_day_phrase` no usa el global streak como sustituto del día perfecto.
- Statistics V3 recalcula completion por día y usa `countValue >= target` para COUNT.

### Streaks y achievements

`_extractHabitStreakContinuityByDay` considera continuidad de COUNT cuando `countValue > 0`, no cuando alcanza target. En cambio, el rollover diario y varias métricas de achievements usan `progress >= target` o `_habitCompletedOnDate`; por tanto hay actualmente más de una noción de completion.

La racha actual es diaria: `_computeCurrentStreak` retrocede día por día mientras el mapa tenga valor positivo. Las estadísticas de achievements también calculan perfect days, completions, exact target hits, global streak y best habit streak desde buckets diarios.

### Rewards

`_setCountHabitProgress` concede el reward cuando el valor cruza el target y `HabitRewardTransaction.completionKey` es `habitId|localDateKey`. Esto protege contra duplicados dentro del día, pero no es suficiente para una completion semanal: el contrato futuro necesitaría una clave `habitId|weekStartKey` y una transición semanal idempotente.

## 5. Schedule architecture

`HabitSchedule` es un objeto separado de `HabitSnapshot.target`. `scheduledForDate` resuelve disponibilidad diaria, weekdays, once y devuelve false para `timesPerWeek` porque esa modalidad se evalúa mediante cuota.

La arquitectura permite conceptualmente:

```text
kind = count
target = 3
targetPeriod = weekly
schedule = daily
```

Pero hoy el guard de `_resolvedScheduleForHabitSave` trata COUNT + `timesPerWeek` como no soportado y devuelve el fallback. El formulario también fuerza COUNT lejos de `timesPerWeek`. Esto confirma que `timesPerWeek` no es el sitio adecuado para el nuevo periodo.

Contrato recomendado para V1:

- target period y schedule son independientes en el modelo;
- solo se expone COUNT weekly con disponibilidad `daily`;
- COUNT daily conserva schedule daily o specific weekdays existente;
- CHECK mantiene todas sus modalidades actuales, incluido `timesPerWeek`;
- COUNT weekly + weekdays específicos queda diferido hasta resolver claramente si los logs fuera de días seleccionados se aceptan y cómo se computa la obligación;
- COUNT weekly + `timesPerWeek` queda explícitamente prohibido en V1.

## 6. timesPerWeek relationship

**Respuesta: NO, weekly count target no debe reutilizar `timesPerWeek`.**

`timesPerWeek` describe una cuota de ocurrencias del schedule, normalmente para CHECK: por ejemplo “hacer este hábito tres veces esta semana”. El nuevo target describe la cantidad acumulada de un COUNT dentro del periodo: “correr 20 km esta semana”.

Diferencias relevantes:

| Concepto | `timesPerWeek` actual | COUNT weekly target |
|---|---|---|
| Unidad | ocurrencias/completions | cantidad medida (`value` + `unit`) |
| Fuente | `schedule.timesPerWeek` | `target` + `targetPeriod` |
| Log útil | `is_completed` por día | `value` por día, sumable |
| Completion | cuota de días/ocurrencias | suma semanal >= target |
| Superar objetivo | se limita la cuota computada | debe conservarse raw progress, p.ej. 4/3 |
| Streak actual | cuota semanal especial | requiere semántica semanal propia |

Sí existe código reutilizable de calendario y cuota (`TimesPerWeekQuotaPolicy`, `WeeklyReportWeek`), pero no debe reutilizarse para interpretar el valor numérico del COUNT weekly. El baseline conocido donde una combinación termina normalizada como daily se deja intacto.

## 7. Week/date architecture

El sistema ya tiene helper canónico en `lib/features/habits/domain/metrics/habit_date_utils.dart`:

- `dateOnly` elimina la hora usando fecha local del objeto;
- `dateKey` genera `YYYY-MM-DD`;
- `weekStartMonday` devuelve lunes local;
- `weekEndSunday` devuelve domingo local.

`WeeklyReportWeek.fromDate` usa esos helpers y fija lunes-domingo. Statistics V3 tiene helpers equivalentes (`_startOfWeek`, `_dateKey`) y el mapper del Weekly Report reconstruye fechas date-only locales para evitar desplazamientos UTC.

No debe crearse otro sistema de fechas. El cálculo recomendado es:

```text
weekStart = weekStartMonday(localDate)
weekEnd   = weekEndSunday(localDate)
weeklyValue(habit, date) = sum(habitCountValues[dateKey][habitId])
                           para date en [weekStart, min(weekEnd, today)]
```

Para un report histórico, el rango debe ser la semana completa y usar todos los logs existentes, respetando la configuración efectiva del hábito de esa semana. Timezone sigue siendo el local del usuario: Weekly Report ya persiste `effective_timezone_name` y `effective_local_date` para sus snapshots.

## 8. Home impact

Hoy `HabitCardWidget` recibe un único `progress` ratio y muestra `currentCount / targetCount`; el builder lee `habit.progress`, `habit.target` y usa `countToday >= target` para `isCompleted`.

COUNT daily debe conservar:

```text
5 / 8 hoy
```

COUNT weekly debería recibir un valor derivado de la semana y un periodo explícito:

```text
2 / 3 esta semana
3 / 3 esta semana
4 / 3 esta semana
```

Cambios necesarios, todavía no implementados:

- selector de Home que calcule `weeklyProgress` desde siete buckets diarios;
- separación entre `dailyActivity` y `weeklyTargetMet`;
- ring visual con ratio raw para texto y ratio clampado para pintura;
- no resetear la cantidad semanal al rollover diario; solo cambia el weekStart de la consulta;
- mantener `+`, `-` y edición funcionando después de alcanzar target;
- evitar que `isCompleted` del card dependa solo de `progress >= 1`;
- añadir una clasificación neutral/weekly a `HabitDaySummary`, porque hoy solo existen pending/completed/skipped.

Recomendación de filtros: COUNT weekly debe permanecer visible diariamente, pero no entrar en el denominador de “pendientes de hoy” ni en “día completado”. Puede tener una superficie/estado `weekly` propio con el progreso restante. Esto es más fiel que llamarlo pending cada día o completed cada día.

## 9. Create/edit form impact

Hay más de un flujo de configuración:

1. `CreateHabitScreen` mantiene state local (`_trackingType`, `_target`, `_unit`, `_frequencyMode`) y actualmente impide COUNT + `timesPerWeek`.
2. El editor reutilizable usa `EditHabitTabFormData`, `EditHabitCountSection` y `EditHabitFrequencySection`.
3. El catálogo usa `HabitTargetConfigSheet`, cuyo `HabitTargetConfigResult` ya serializa `type`, `target` y `scheduleType`.

La superficie correcta para la nueva opción es el editor reutilizable, junto al target COUNT y antes/independiente de frecuencia:

```text
Objetivo        [ 3 ] [ unidad ]
Periodo objetivo
  (•) Cada día
  ( ) Cada semana
Disponibilidad
  (•) Todos los días   // V1 para weekly count
```

No debe llamarse “frecuencia”, porque `frequencyMode`/`schedule` ya significa disponibilidad.

Modelo mínimo de form state:

```text
targetPeriod: daily | weekly
```

Defaults y validación:

- solo visible y serializado para COUNT;
- CHECK debe limpiar/ignorar el campo;
- valor ausente o inválido => daily;
- target positivo obligatorio para ambos periodos COUNT;
- cambiar daily/weekly no debe borrar logs existentes; solo cambia la interpretación futura del target y debe estampar una nueva configuración efectiva para reportes.

## 10. Onboarding impact

El onboarding ya comparte visuales y controles mediante:

```text
OnboardingHabitForm
  -> EditHabitTabFormData
  -> OnboardingHabitConfiguration
  -> OnboardingHabitDraftAdapter.encode
  -> draft.habit
```

`OnboardingHabitConfiguration` debe incorporar el mismo target period; `_formDataFrom`, `submit`, `_validateShape` y el adapter deben transportar el campo. El adapter es el único límite que conoce los nombres del mapa dinámico, por lo que no debe crearse una lógica paralela para onboarding.

El draft debe aceptar campo ausente como daily y conservarlo al re-encode. Las recomendaciones que no tengan el campo siguen siendo daily. La UI aparece solo cuando `kind == HabitKind.count`, con el mismo control compartido del editor.

## 11. Supabase persistence

### Estado actual

`public.habits` persiste:

- `habit_type`;
- `target_count integer`;
- `unit`;
- `schedule jsonb`;
- metadata, reminders, archive y ordering.

`RemoteHabit.toUpsertMap`, `RemoteHabit.fromMap`, `HabitRepository._habitColumns`, `HabitRemoteMapper` y el merge de `UserStateStore` cubren ese contrato.

`public.habit_logs` persiste una fila por `(user_id, habit_id, log_date)` con `value`, `is_completed`, `is_skipped`, `source` y timestamps. RLS limita acceso al usuario autenticado dueño; la unicidad soporta upsert idempotente diario.

### Weekly Report remoto

La configuración versionada de Weekly Report copia actualmente `habit_type`, `target_count`, `schedule`, etc. Sus funciones/generators (`20260901090000_create_weekly_report_foundation.sql`, `20260901130000_weekly_report_generator.sql`, `20260904100000_weekly_report_live_provisional.sql`) asumen que un COUNT se completa cuando `log.value >= target_count` para cada día.

### Evaluación

**Respuesta: YES, una migración es necesaria para el contrato recomendado.**

La opción correcta es añadir un campo de configuración separado, previsiblemente `target_period text not null default 'daily'` con constraint `daily|weekly`, y transportar ese valor también en los snapshots/versiones de Weekly Report y sus RPCs/generators. No es correcto esconderlo dentro de `schedule`: sería un atajo que mezcla disponibilidad con semántica del target y rompería la frontera que el dominio ya expresa.

No se ha creado SQL ni se ha tocado Supabase.

## 12. Sync/backward compatibility

### Local -> Supabase

El flujo es `UserStateStore` -> `HabitSyncService` -> `HabitRemoteMapper.toRemoteHabit` -> `RemoteHabit.toUpsertMap` -> `HabitRepository.upsertHabitForCurrentUser`. El nuevo campo debe recorrer las cuatro capas.

### Supabase -> local

`_mergeRemoteHabitIntoExistingLocal` actualizará `targetPeriod`; `_localHabitFromRemote` debe hidratarlo. Si la columna remota es null/ausente durante rollout, el mapper debe devolver daily.

### Logs

Los logs siguen siendo diarios y no necesitan cambiar de forma para acumular semanalmente. La suma se hace al leer. Al pasar de domingo a lunes, el historial anterior permanece y el selector cambia de rango.

### Usuarios antiguos

Contrato recomendado:

```text
campo targetPeriod ausente/null/invalid -> daily
```

No hace falta backfill de logs ni transformación histórica para que los hábitos antiguos sigan significando lo mismo. Sí hace falta que cualquier snapshot remoto antiguo y cualquier app anterior desconozcan el campo sin perder `target`, `unit` o `schedule`; por ello el rollout debe ser tolerante a columna ausente durante la transición.

La resolución de conflictos sigue siendo por configuración efectiva/timestamps para el hábito y por upsert diario para logs. Cambiar el periodo debe crear una nueva configuración efectiva; no debe reinterpretar silenciosamente semanas históricas ya cerradas.

## 13. Statistics V3 impact

Statistics V3 ya suma valores COUNT en un rango mediante `_sumCountHabitValueInRange` y usa `habitCountValues` como fuente histórica. Eso es reutilizable para el raw total semanal.

Pero el resto del contrato aún es diario:

- `_completedHabitIdsForDay` marca COUNT completo si `dayValue >= habit.target`;
- `_buildDayCompletionStats` usa esa lista en el porcentaje diario;
- la lista de hábitos de COUNT calcula una suma semanal parcial pero la presenta sin distinguir target period;
- `_isCurrentHabitDone` usa `habit.progress >= target`;
- el sistema mantiene estadísticas de actividad diaria, no un completion semanal de target.

Cambios necesarios:

1. COUNT daily conserva `valueDay >= target`.
2. COUNT weekly expone `weekValue` y `weekTarget`; no reparte el target entre siete días.
3. La métrica semanal puede ser `rawProgress = weekValue / target`, con visual clamp a 100% si el contrato lo exige.
4. Las métricas diarias deben usar solo `dailyActivity = dayValue > 0` como actividad, o excluir weekly count del denominador de completion diaria; no deben usar `dayValue >= weeklyTarget`.
5. El periodo week usa `weekStartMonday` y fecha local, no un total móvil de siete días.
6. Las pantallas de detalle deben decidir explícitamente si el chart conserva cantidades diarias y añade una línea/acumulado semanal.

## 14. Weekly Report impact

El contrato actual modela `WeeklyReportHabit` con `target`, `schedule`, `scheduledCount`, `completedCount`, `completionRate` y siete `HabitOccurrenceResult`. El SQL actual crea una ocurrencia diaria y para COUNT calcula completion con `log.value >= target_count`.

Para COUNT weekly no debe generarse:

```text
lunes 5/20, martes 0/20, miércoles 7/20...
```

Debe generarse una semántica de target semanal:

```text
logs: 5 + 7 + 8 = 20
weekly target = 20
raw progress = 100%
```

Propuesta de contrato:

- `targetPeriod` disponible en `WeeklyReportHabit` y en la configuración efectiva;
- `scheduledCount` para weekly count representa una obligación semanal (`1` unidad de target), o se mantiene neutral y se añade un campo específico `targetPeriod/weeklyTarget`; no debe contarse como siete obligaciones;
- `completedCount` vale `1` si la semana alcanza el target y `0` si no, para la clasificación agregada;
- `completionRate = min(rawProgress, 1)` para cap visual; conservar raw progress si el producto necesita `133%`;
- `highlighted/stable/needsAttention` debe clasificarse sobre cumplimiento semanal y tendencia semanal, no sobre siete comparaciones diarias de `value >= target`;
- los dots diarios muestran actividad (`value > 0`), no siete fallos de target;
- el breakdown conserva cada log diario y añade total semanal/target/remaining;
- `timesPerWeek` sigue usando `HabitOccurrenceScope.weeklyQuota` y su `TimesPerWeekQuotaPolicy`; no se mezcla con COUNT weekly.

Antes de implementación, deben versionarse el SQL generator, live provisional, mapper remoto, DTO y tests del contrato para no reinterpretar históricos sin una política explícita.

## 15. Completed day impact

El problema es real: si un weekly COUNT se deja en `doneToday = progress >= target`, aparecerá pendiente cada día hasta alcanzar la cuota y luego parecerá completado todos los días; ambas lecturas son engañosas para “todos los hábitos de hoy”.

### Opciones

**A. `completed today` si hay progreso > 0.**

- Ventaja: encaja con `habitCountValues` y mantiene una señal de actividad simple.
- Riesgo: convierte una actividad opcional en una completion diaria; puede inflar perfect day y streaks.
- Riesgo adicional: no representa que `3/3` sea un evento semanal único.

**B. No existe completion diaria; solo progreso semanal.**

- Ventaja: semántica de producto más exacta.
- Riesgo: requiere estado neutral en Home, filtros, notificaciones y componentes que hoy solo conocen pending/completed/skipped.
- Es la base correcta para perfect day y streaks.

**C. Recomendación híbrida: actividad diaria + logro semanal separados.**

- `dailyActivity = dayValue > 0` para dots y timeline.
- `weeklyTargetMet = weekValue >= weeklyTarget` para el objetivo.
- No se proyecta ninguna de las dos señales a “completion diaria obligatoria”.
- Home muestra una categoría weekly/neutral; perfect day y daily streaks excluyen el hábito.

Se recomienda C porque conserva observabilidad diaria sin falsear la semántica de obligación. El objetivo semanal se completa una vez por semana; una nueva suma posterior puede dar `4/3`, pero no debe conceder tres completions o tres rewards.

## 16. Streak/reward impact

### Streaks

El streak actual es por día. Un weekly COUNT no debería romperse por martes sin log ni crecer tres días solo por haber alcanzado `3/3` el viernes.

Propuesta:

- excluir COUNT weekly de `habit streak` diario, `global streak` diario, `perfect day` y “todos los hábitos de hoy” en V1;
- derivar un futuro `weeklyHabitStreak` por semanas completas alcanzadas, con clave weekStart, si se quiere gamificarlo;
- no adaptar silenciosamente el algoritmo diario para interpretar el mismo log como siete completions.

### XP/Amber/rewards

El reward debe dispararse una sola vez al cruzar el target semanal, no por cada incremento diario ni por superar el target. La clave idempotente recomendada es `habitId|weekStartKey`; el decremento que baja de target necesita una política explícita para reversión antes de implementar.

La política más segura para V1 es: reward de target weekly una vez cuando `previousWeekValue < target` y `nextWeekValue >= target`; incrementos posteriores son progreso sin reward adicional. Esta regla debe coordinarse con rewards cloud y con `HabitRewardTransaction`, que hoy está anclado a fecha.

## 17. Notification impact

Las notificaciones personalizadas construyen contexto desde `buildHabitDaySummary`; usan pending/completed count, progress ratio y riesgo de streak. `NotificationRules._pendingHabitsToday` además evalúa `doneToday` y schedule directamente. Los reminders base usan principalmente `reminderEnabled`, hora y schedule.

Impacto conceptual:

- un reminder diario puede seguir existiendo si el usuario lo activa, pero su copy debe hablar de progreso semanal/remaining, no de “fallaste hoy”;
- `pendingHabitsToday` no debe considerar un weekly COUNT como pending diario por no alcanzar target;
- los milestones deben detectar cruce semanal y deduplicarlo por `habitId|weekStart`;
- streak-risk diario no debe incluir weekly COUNT;
- el context builder necesita `weeklyCountProgress` o una señal equivalente;
- el evento `onHabitCompleted` no debe disparar tres veces durante una semana; debe existir un evento semanal idempotente o una deduplicación de dominio.

No se ha modificado la lógica de notificaciones.

## 18. Recommended data model

### Nombre

Recomiendo `HabitTargetPeriod` con valores `daily` y `weekly`. Es más preciso que `frequency`, `cadence` o `timesPerWeek`, y deja claro que pertenece al target.

```dart
enum HabitTargetPeriod { daily, weekly }
```

Añadir a `HabitSnapshot`:

```dart
final HabitTargetPeriod targetPeriod;
```

Contrato:

```text
CHECK:  targetPeriod irrelevante/null en el dominio, no se muestra ni se persiste como weekly.
COUNT:  target positivo, unit opcional, targetPeriod daily|weekly.
default: daily.
```

Serialización recomendada:

- local map: `targetPeriod: 'daily' | 'weekly'`;
- remote habit: `target_period`;
- onboarding draft: `targetPeriod`;
- Weekly Report config/version: `target_period`/`targetPeriod` según frontera SQL/DTO;
- parser tolerante: ausencia, null o valor desconocido => daily.

No se recomienda ponerlo dentro de `schedule`, porque `HabitScheduleNormalizer` ya canoniza y elimina campos que no pertenecen al schedule.

## 19. Allowed V1 combinations

| Kind | Target period | Schedule | V1 | Motivo |
|---|---|---|---|---|
| check | — | daily | yes | Contrato actual. |
| check | — | weekly weekdays | yes | Contrato actual de días específicos. |
| check | — | once | yes | Contrato actual fuera de onboarding. |
| check | — | timesPerWeek | yes | Cuota flexible existente; separada. |
| count | daily | daily | yes | COUNT actual. |
| count | daily | weekly weekdays | yes | Target diario aplicado solo en días disponibles, ya soportado. |
| count | daily | once | defer/legacy | Puede existir fuera de onboarding; no es parte de weekly target. |
| count | weekly | daily | yes | Caso principal: visible todos los días, suma semanal. |
| count | weekly | weekly weekdays | no V1 | Falta resolver si se acepta log fuera de días y cómo se muestra la obligación. |
| count | weekly | once | no V1 | Un target semanal necesita ventana semanal, no una ocurrencia única. |
| count | weekly | timesPerWeek | no | Mezcla cantidad target con cuota de ocurrencias; además el guard actual normaliza COUNT away from timesPerWeek. |

## 20. Proposed UX

En el formulario compartido, solo para COUNT:

```text
Tipo de seguimiento
  Check | Cantidad

Objetivo
  [ 3 ] [ unidad ]

Periodo del objetivo
  (•) Cada día
  ( ) Cada semana

Disponibilidad
  (•) Todos los días
  ( ) Días específicos   // solo daily en V1
```

Copy recomendado:

- daily: `3 minutos cada día`;
- weekly: `20 km acumulados esta semana`;
- Home daily: `5 / 8 hoy`;
- Home weekly: `2 / 3 esta semana`;
- sobrecumplimiento: `4 / 3 esta semana` sin bloquear el botón `+`.

“Periodo del objetivo” debe estar visualmente separado de “Disponibilidad/frecuencia”.

## 21. Migration assessment

### Supabase

Migración conceptual necesaria:

1. añadir `habits.target_period` con default daily y constraint de valores;
2. backfill implícito/default para todas las filas existentes;
3. añadir el campo a `weekly_report_habit_config_versions` y `weekly_report_habits`;
4. actualizar trigger/versionado, RPCs, generator, live provisional, read API y DTOs;
5. conservar RLS existente, que ya se basa en `user_id`; no se necesita una política nueva por el campo;
6. hacer rollout tolerante a entornos antiguos que todavía no tengan la columna;
7. rollback: eliminar el soporte nuevo solo después de convertir weekly a daily o de retirar filas/configuraciones weekly; no debe borrarse historial de logs.

No se ha escrito SQL.

### Local

No requiere migración destructiva. `UserStateStorage` guarda JSON versionado por key y el parser puede aplicar default daily al leer. Debe evitarse reescribir todos los hábitos antiguos solo por hidratar el default.

## 22. Exact implementation phases

1. **Domain contract**: `HabitTargetPeriod`, parser, default, `HabitSnapshot`, occurrence/result contracts y helpers para weekly value.
2. **Local serialization/sync DTO**: mapa local, `RemoteHabit`, mappers, hydration y tests de backward compatibility. Mantener logs diarios.
3. **Form create/edit**: `EditHabitTabFormData`, editor compartido, `CreateHabitScreen` y catálogo si sigue activo; separar target period de frequency.
4. **Onboarding adapter**: `OnboardingHabitConfiguration`, form state, validator, draft codec y adapter; sin duplicar lógica.
5. **Home/domain completion**: selector semanal, `HabitDaySummary` neutral/weekly classification, card progress, increment/decrement/edit y filters.
6. **Rewards/events**: transición semanal idempotente, reward key por weekStart, reverse policy y exclusión de daily streak rewards.
7. **Statistics V3**: target semanal, raw/clamped progress, activity dots y exclusión del denominator diario.
8. **Weekly Report**: snapshot schema, SQL/RPC/generator, mappers, classification, breakdown y dots.
9. **Streaks/perfect day/notifications**: period-aware policies, CompletedDayEligibility, context builder, pending rules y milestone deduplication.
10. **Supabase migration/rollout**: schema, RLS regression, old-client/new-client compatibility y remote pull/backfill.
11. **Regression QA**: daily COUNT, CHECK, `timesPerWeek`, legacy habits, over-target, week rollover, timezone/local date, edit/delete/sync and first partial week.

No fase de implementación se ha ejecutado en este pre-flight.

## 23. Tests inspected/executed

### Suites inspeccionadas

- `test/features/habits/domain/metrics/habit_occurrence_evaluator_test.dart`
- `test/features/habits/domain/metrics/habit_metrics_statistics_v3_parity_test.dart`
- `test/screens/home/home_selectors_schedule_test.dart`
- `test/screens/home/home_habit_status_filter_test.dart`
- `test/screens/habit_detail/edit_habit_tab_form_data_test.dart`
- `test/features/onboarding/onboarding_habit_configuration_test.dart`
- `test/features/completed_day_phrase/completed_day_phrase_test.dart`
- `test/features/notifications/application/notification_context_builder_test.dart`
- `test/features/weekly_report/domain/weekly_report_domain_test.dart`
- `test/stores/user_state_store_times_per_week_schedule_test.dart`
- `test/data/mappers/habit_schedule_cloud_mapper_test.dart`
- `test/data/habit_log_remote_mapper_history_test.dart`

### Comando ejecutado

```text
flutter test test/features/habits/domain/metrics/habit_occurrence_evaluator_test.dart test/features/habits/domain/metrics/habit_metrics_statistics_v3_parity_test.dart test/screens/home/home_selectors_schedule_test.dart test/screens/home/home_habit_status_filter_test.dart test/screens/habit_detail/edit_habit_tab_form_data_test.dart test/features/onboarding/onboarding_habit_configuration_test.dart test/features/completed_day_phrase/completed_day_phrase_test.dart test/features/notifications/application/notification_context_builder_test.dart test/features/weekly_report/domain/weekly_report_domain_test.dart test/stores/user_state_store_times_per_week_schedule_test.dart test/data/mappers/habit_schedule_cloud_mapper_test.dart test/data/habit_log_remote_mapper_history_test.dart
```

### Resultado

- 109 tests passed.
- 1 baseline failure, no corregido:
  - `UserStateStore timesPerWeek canonical schedule addCustomHabit normalizes invalid timesPerWeek payload values`;
  - expected schedule `{'type': 'timesPerWeek', 'timesPerWeek': 1, 'weekStartsOn': 1}`;
  - actual schedule `{'type': 'daily'}`.
- El fallo coincide con el baseline conocido de `timesPerWeek`; no se ha modificado producción ni el test.

## 24. Risks

1. **Semántica diaria ambigua**: reutilizar `doneToday` para weekly count produciría falsos pending/completed, perfect days y streaks.
2. **Rewards duplicados**: la clave actual es diaria; cruzar una cuota semanal varias veces puede premiar indebidamente.
3. **Weekly Report incorrecto**: SQL actual interpreta COUNT como target diario y debe versionarse antes de activar datos weekly.
4. **Configuración histórica**: editar target period sin `effectiveFrom` puede reinterpretar semanas cerradas.
5. **TimesPerWeek confusion**: aliases legacy (`goal`, `times`, `timesPerWeekTarget`) hacen fácil mezclar schedule quota y target period.
6. **Rollover local**: `_ensureDailyReset` pone `activeHabits.progress = 0`; weekly count debe derivar el total por fecha y no depender de ese campo diario.
7. **Timezone**: mezclar `DateTime.utc`, date-only y timezone del report puede mover logs de domingo/lunes.
8. **Filtros API**: añadir un estado neutral afecta selectors, notification context, CompletedDayPhrase y contratos de widgets.
9. **Over-target visual**: el ring actual clampa a 100%; el texto debe conservar raw value para `4/3`.
10. **Usuarios antiguos/entornos parcialmente migrados**: todo mapper debe tolerar ausencia de columna y default daily.
11. **Múltiples formularios**: editar solo onboarding o solo `CreateHabitScreen` dejaría superficies divergentes.
12. **Tests de baseline**: el fallo de `timesPerWeek` ya existe y no debe usarse como señal de regresión de esta feature.

## 25. Critical product decisions

1. **Nuevo field/type**: `HabitTargetPeriod` con `daily` y `weekly`; campo `targetPeriod` en modelo local/domain/remote.
2. **Default**: sí, daily debe seguir siendo el default; ausencia/null/invalid => daily.
3. **Independencia**: sí, weekly target y schedule son independientes conceptualmente.
4. **Reutilizar timesPerWeek**: no; es cuota de schedule para ocurrencias, no periodo de una cantidad.
5. **Progreso lunes-domingo**: sumar los logs diarios de `weekStartMonday(localDate)` a `weekEndSunday(localDate)`; nuevo lunes empieza en cero derivado, sin borrar history.
6. **Superar target**: sí; permitir `4/3`, `5/3`, preservar raw progress y clampar solo la visualización porcentual si procede.
7. **Completed today**: para weekly count no significa alcanzar target diario. Recomiendo estado híbrido: `dailyActivity` separado de `weeklyTargetMet`, sin completion diaria obligatoria.
8. **Perfect day**: excluir weekly count del denominador y de la elegibilidad de día perfecto; puede mostrar progreso semanal aparte.
9. **Streaks**: no usar daily streak para weekly count en V1; derivar futuro weekly streak por semana completa o mantenerlo fuera hasta tener modelo period-aware.
10. **Home pending/completed**: visible todos los días con estado weekly/neutral; no convertirlo en pending diario ni completed diario.
11. **Statistics**: total semanal contra target semanal; no siete denominadores diarios. Mantener actividad diaria solo como actividad.
12. **Weekly Report**: una obligación agregada semanal, `completedCount` 0/1 y rate cap visual; dots diarios son logs/actividad; no mezclar con quota.
13. **Supabase migration**: sí para el contrato correcto: `target_period` en habits y snapshots/versiones de Weekly Report, con RLS existente.
14. **Hábitos antiguos**: campo ausente => daily, sin alterar logs ni borrar history.
15. **Onboarding**: extender el mismo `OnboardingHabitForm`/`EditHabitTabFormData`/adapter; no crear un formulario alternativo.
16. **Combinaciones V1**: permitir COUNT weekly + daily; diferir weekly + specific weekdays; prohibir weekly + timesPerWeek; conservar CHECK/timesPerWeek existente.

**Conclusión:** la feature es viable, pero no es un cambio de etiqueta en `target`. Requiere una semántica de periodo que atraviese dominio, cálculo de progreso, Home, completion diaria, rewards, estadísticas, Weekly Report y sync. Este documento no implementa ninguno de esos cambios.
