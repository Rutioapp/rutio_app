# Weekly Count Target — Rewards & Streaks Preflight

## 1. Executive summary

La Fase 3 deja correctamente separado el progreso semanal de COUNT de la
completion diaria: `weeklyTargetMet` se deriva de la suma de logs locales,
`doneToday` permanece en `false`, el hábito no entra en rewards diarios,
perfect day ni streak diario, y el valor puede superar el target.

La arquitectura actual de rewards es reutilizable, pero su identidad actual es
diaria. Tanto el ledger local como el coordinator cloud deduplican con
`habitId + localDateKey`; por tanto todavía no existe un contrato seguro para
recompensar una cuota semanal. Tampoco existe un evento de dominio genérico de
completion: la transición, la recompensa, el sync y el observer se disparan
directamente desde `UserStateStore`.

Contrato recomendado para V1:

- achievement inmediato al cruzar el target, solo ante
  `previousWeeklyActual < target` y `nextWeeklyActual >= target`;
- identidad estable `habitId + weekStartLocal` con lunes local como inicio;
- máximo un claim y un reward por hábito y semana;
- `weeklyTargetMet` siempre derivado del progreso actual;
- `weeklyAchievementClaimed` histórico e idempotente;
- un reward ya concedido nunca se revierte ni se vuelve a conceder al bajar y
  volver a subir;
- weekly COUNT queda fuera de los streaks diarios en V1;
- el reward debe reutilizar, si Producto lo aprueba, el cálculo normal de COUNT
  una sola vez, sin recompensa proporcional al over-target ni cantidades nuevas;
- el periodo y la configuración efectiva deben estabilizarse antes de activar
  rewards semanales y de ampliar Supabase.

No se ha modificado código de producción, economía, streaks, Home, Statistics,
Weekly Report ni Supabase.

## 2. Current reward architecture

### Cadena local actual

```text
UserStateStore.completeHabit / setCountHabitValue
  -> _setCountHabitProgress / _applyHabitProgressDelta
  -> _HabitProgressResult
  -> _applyHabitRewardCompletion
  -> wallet + progression + daily counters
  -> HabitRewardTransaction
  -> SharedPreferences + best-effort sync
```

Los puntos principales son:

| Responsabilidad | Archivo / símbolo | Naturaleza |
|---|---|---|
| Detectar cruce diario | `lib/stores/user_state_store_habit_progress.dart` — `_setCountHabitProgress`, `_applyHabitProgressDelta` | Derivada durante la mutación. |
| Resolver cantidad | `lib/constants/reward_constants.dart` — `habitCheckXpReward`, `habitCountXpReward`, `habitCountAmbarReward` | Regla de economía. |
| Aplicar boosts | `lib/features/habits/domain/habit_reward_calculator.dart` — `HabitRewardCalculator.calculate` | Derivada; consume un uso por boost aplicable. |
| Aplicar reward local | `lib/stores/user_state_store_habits.dart` — `_applyHabitRewardCompletion`, `_applyHabitRewardValues` | Mutación persistente de XP, Amber y contadores diarios. |
| Registrar reward local | `lib/features/habits/domain/models/habit_reward_transaction.dart` | Ledger persistido por transacción. |
| Persistir reward local | `lib/features/habits/data/local_habit_reward_transaction_repository.dart` | SharedPreferences, scope por usuario. |
| Reward cloud | `lib/features/habits/application/habit_currency_reward_coordinator.dart` | RPC, pending operations y reintentos. |
| Ledger cloud | `public.habit_currency_reward_ledger` y RPCs existentes | Dedupe remoto por request/source. |
| Sync de progreso | `lib/stores/user_state_store_habit_progress.dart` — `_queueBestEffortProgressAndRewardSync` | Best effort; usa `habit_completion` o `achievement_unlocked`. |

El reward derivado y el reward persistido no son lo mismo:

- `_HabitProgressResult` solo dice que debe concederse un reward y qué base
  calcular; no es historial.
- `HabitRewardResult` contiene base, bonus, total y consumo de boosts; tampoco
  es historial.
- `HabitRewardTransaction` sí es historial durable. Guarda XP, coins, boosts,
  `completionEventId`, request IDs cloud, fecha lógica y si está revertido.
- En modo local, la wallet y progression viven en el root de `UserStateStore`,
  mientras el transaction repository vive en otra key de SharedPreferences.
- En modo cloud, `HabitCurrencyRewardCoordinator` conserva pending operations
  y el ledger remoto es la autoridad de la operación monetaria confirmada.

### Identidad y códigos actuales

La identidad local actual es:

```text
HabitRewardTransaction.completionKey = habitId + "|" + localDateKey
```

La transacción local se serializa en
`rutio_habit_reward_transactions_v1[_scope]` y el repository deduplica por
`habitId + localDateKey`.

En cloud, el coordinator construye:

```text
habit_cloud_reward|remoteHabitId|logicalDateKey
habit_cloud_reward_apply|remoteHabitId|logicalDateKey
habit_cloud_reward_reverse|remoteHabitId|logicalDateKey
```

El SQL actual usa `source_type = 'habit_completion'`, el event ID como
`source_id`, `request_id` único y una restricción única por usuario, operación,
tipo de source y source ID. La función de base calcula el reward COUNT a partir
de `target_count`, no de `target_period` ni del total acumulado semanal.

Achievements de catálogo tienen otra vía: `_syncAchievementsFromCurrentHabits`
deriva snapshots, persiste `profile.achievements.unlocked`, y
`_applyAchievementRewardsForRecords` deduplica con
`rewardAppliedAchievementIds`/`achievementRewardsClaimed`. No es un buen
almacén directo para un achievement recurrente por semana porque sus IDs
actuales son achievements de catálogo, no instancias `habit + week`.

## 3. Current streak architecture

La racha de hábitos actual es diaria y se deriva principalmente desde
`userState.history`:

- `habitCompletions[YYYY-MM-DD][habitId]` guarda completion booleana;
- `habitCountValues[YYYY-MM-DD][habitId]` guarda el valor numérico diario;
- `habitOccurrenceStatuses`, `habitStreakBreaks` y
  `habitStreakShields` aportan estados de miss, recovery y protección;
- `_extractHabitStreakContinuityByDay` usa `countValue > 0` para COUNT diario,
  no necesariamente `countValue >= target`;
- `_computeHabitCurrentStreak` y `_computeHabitBestStreak` cuentan días
  consecutivos;
- `_computeCurrentStreak` retrocede día a día desde la fecha de referencia;
- el streak global se deriva de si existe al menos una completion diaria;
- los snapshots de `HabitStreakSnapshot` son derivados; los unlocks y breaks sí
  quedan persistidos.

El rollover diario llama a `_ensureDailyReset`. Para weekly COUNT, Fase 3
elimina la completion diaria, marca el occurrence status como
`notScheduled` y evita crear un break de streak. Además, las funciones de
achievements y estadísticas ya excluyen weekly COUNT de los conjuntos de
completions diarias.

Conclusión: weekly COUNT no puede reutilizar `completedToday` ni el algoritmo
diario. Hacerlo rompería la semántica: un log el viernes no debe producir siete
días de streak, y un miércoles sin log no debe romper una racha semanal en
curso.

## 4. Current completion event architecture

No existe un bus o entidad genérica `CompletionEvent` en el código auditado.
La completion actual es una operación de store con varios efectos coordinados:

1. se muta el mapa de hábito y el historial diario;
2. se evalúa el reward diario;
3. se persiste o sincroniza el `HabitRewardTransaction`;
4. se recalculan achievements derivados;
5. se notifican `onHabitCompleted`/`onHabitUncompleted` al observer;
6. Home mantiene además una transición visual independiente.

El equivalente existente más cercano a un evento durable es
`HabitRewardTransaction.completionEventId`, junto con los request IDs y el
ledger cloud. Para weekly COUNT se recomienda extender esta frontera con un
`source/period` explícito o con un record histórico de achievement semanal,
sin crear un segundo bus de eventos.

No debe reutilizarse `onHabitCompleted` como evento weekly sin añadir contexto:
el observer actual no recibe `weekStart` ni distingue daily de weekly.

## 5. Weekly achievement identity

La identidad de negocio recomendada es:

```text
weeklyAchievementKey = habitId + "|" + weekStartLocal
```

`weekStartLocal` debe ser la fecha local ISO del lunes calculada por el helper
canónico `weekStartMonday` de
`lib/features/habits/domain/metrics/habit_date_utils.dart`. Ejemplo:

```text
habitId = abc
weekStartLocal = 2026-09-07
key = abc|2026-09-07
```

Para cloud, la identidad externa debe usar el UUID remoto estable del hábito y
la misma fecha lógica:

```text
weekly_target|remoteHabitUuid|2026-09-07
```

El UUID remoto es necesario para que Pixel e iPhone compartan la identidad; el
ID local no es suficiente. El campo lógico puede viajar como `logical_date_key`
porque el SQL actual ya exige una fecha ISO, pero semánticamente debe
documentarse como `week_start_local`, no como día de completion.

No se implementa aquí ningún cambio de key.

## 6. Achievement timing

Recomendación: **A, achievement inmediato al cruce**.

La transición debe evaluarse sobre el total semanal antes y después de la
mutación:

```text
previousWeeklyActual < target
nextWeeklyActual >= target
claim semanal inexistente
=> weeklyAchievementReached ahora
```

Esto permite feedback útil el día en que el usuario alcanza el objetivo y no
obliga a esperar al domingo. El achievement es un evento histórico aunque el
estado visual pueda volver a `false` si después se edita o decrementa un log.

La semana no necesita estar cerrada para conceder el reward. El cierre de
domingo solo es relevante para consolidar un futuro weekly streak.

## 7. Decrement/re-entry semantics

Contrato recomendado:

- `weeklyTargetMet` sigue siendo una función del progreso actual:
  `weeklyActual >= target`;
- `weeklyAchievementClaimed` queda persistido por `habitId + weekStartLocal`;
- un reward confirmado no se revierte por decremento de logs ni por bajar de
  target;
- si el valor pasa de `3/3` a `2/3`, el estado visual vuelve a no alcanzado,
  pero el claim histórico permanece;
- si vuelve a `3/3`, no hay un segundo achievement ni reward;
- over-target (`4/3`, `5/3`) no crea eventos adicionales.

Esto coincide con la política ya usada por rewards diarios: los tests de
`UserStateStore` verifican que undo/re-complete no restaura ni vuelve a pagar el
reward. Para weekly, la diferencia es cambiar la clave de día a semana, no
introducir reversals de economía.

## 8. Idempotency

El `if (!alreadyRewarded)` actual no basta por sí solo para weekly, porque
`alreadyRewarded` se resuelve con la fecha diaria. El guard futuro debe tener
tres capas:

1. **Dominio:** detectar solamente la transición falsa → verdadera y no volver
   a emitirla si el claim persistido existe.
2. **Persistencia local:** consultar una clave única por
   `habitId|weekStartLocal`; el record debe sobrevivir restart, logout/login y
   rebuild de Home.
3. **Cloud:** usar request ID y completion event ID deterministas, con una
   constraint única remota sobre usuario + operación + source event.

La infraestructura cloud actual ya ofrece request idempotente, advisory locks,
pending operations y constraints únicas. Lo que falta es alimentarla con una
identidad semanal estable y garantizar que `logicalDateKey` represente el
lunes. La infraestructura local actual tiene dedupe por día y debe ser
ampliada o versionada para no mezclar una transacción daily con una weekly.

No se debe usar solo memoria ni usar el recálculo de Home como fuente de
idempotencia.

## 9. Offline/retry behavior

### Modo local

El cálculo del progreso es offline y los logs sobreviven en
`history.habitCountValues`. El reward debe registrarse junto con el claim
semanal y no volver a deducirse al recalcular Home.

Riesgo actual: `_applyHabitRewardValues` modifica wallet/progression dentro del
root, `store.save(root)` ocurre antes de `_saveHabitRewardTransactionForStore`,
y ambos datos viven en persistencias separadas. Una caída entre esas dos
operaciones podría dejar wallet incrementada sin ledger local y permitir un
doble pago posterior. Los tests cubren el flujo normal y rollback de errores,
pero no un crash entre writes.

### Modo cloud

`HabitCurrencyRewardCoordinator` persiste primero la pending operation, llama a
la RPC, guarda la transacción confirmada y permite resolver pending tras
restart. Un timeout deja la operación pendiente y no debe provocar un segundo
source event. Este patrón es adecuado para weekly si se cambia la identidad.

### Estado mínimo

El mínimo persistente es un claim semanal durable con estado de reward:

```text
claimKey
habitId
weekStartLocal
achievedAt
rewardStatus: pending | granted | not_applicable
completionEventId / rewardTransactionId
```

`weeklyTargetMet` no debe persistirse: se recalcula desde logs.

## 10. Reward policy

El código actual no contiene un reward específico semanal ni una tarifa
proporcional. Sí contiene una regla objetiva de COUNT:

```text
XP = RewardConstants.habitCountXpReward(target)
Amber = RewardConstants.habitCountAmbarReward(XP)
```

Recomendación V1: reutilizar esa misma recompensa normal de COUNT **una sola
vez al alcanzar el target semanal**, sin multiplicarla por días, cantidad
acumulada u over-target. Un boost de XP/Amber se consume una sola vez en ese
cruce, igual que en un COUNT diario.

Esto no inventa cantidades y es compatible con la función cloud actual, que
también calcula a partir de `target_count`. Aun así, debe quedar como decisión
de Producto explícitamente aprobada: el código no demuestra por sí solo que el
reward diario sea la tarifa final deseada para una cuota semanal. Si Producto
quiere una tarifa específica, debe definirla antes de Fase 4B y modificar
economía de forma deliberada; este preflight no la inventa.

## 11. Weekly streak semantics

Recomendación: introducir en el futuro un **weekly streak separado**, no
reutilizar `habitStreak` diario con otra interpretación.

Semántica propuesta:

- una semana cuenta si su achievement semanal quedó alcanzado antes del cierre
  local del domingo;
- la unidad de continuidad es `weekStartLocal`, no un día;
- una semana en curso todavía no alcanzada no rompe la racha;
- una semana en curso alcanzada puede mostrarse como provisional, pero la racha
  durable se consolida al cerrar la semana;
- las semanas cerradas no alcanzadas sí rompen la continuidad;
- con semanas alcanzadas 1, 2, no alcanzada 3, alcanzada 4, la racha actual es
  1 y la mejor racha conserva al menos 2.

No se debe derivar el weekly streak desde `habitCompletions`, porque Fase 3
intencionadamente no escribe completion diaria para weekly COUNT. Tampoco se
debe contar un incremento diario como una unidad de streak.

## 12. Current-week semantics

La evaluación debe distinguir:

- semanas cerradas: domingo local pasado; su achievement es definitivo para
  streak;
- semana actual: ventana Monday–Sunday todavía abierta; su target puede estar
  alcanzado para feedback y reward, pero una ausencia temporal no es un miss;
- semana futura: no tiene estado de achievement.

En miércoles, si la semana anterior fue alcanzada y la actual va `1/3`, la
racha no se rompe. El reward, si se cruza el target el jueves, ocurre el jueves;
el streak semanal se consolida al cierre según el contrato anterior.

## 13. Editing target/period

### Cambio de target durante la semana

Política V1 recomendada: cambiar el target modifica el estado derivado, pero el
cambio de configuración por sí solo no emite un achievement ni un reward.

- `3 -> 2` con actual `2`: `weeklyTargetMet` pasa a true, pero no se paga hasta
  una mutación de progreso posterior que confirme el cruce bajo la configuración
  vigente. Esto evita farmear rewards editando el target.
- `3 -> 5` después de reclamar: el claim y el reward permanecen; el estado
  visual puede volver a false y no se crea un segundo claim al alcanzar 5 esa
  misma semana.
- Subir o bajar target no revoca economía ni cambia la identidad semanal.
- Debe conservarse `targetAtClaim` en el record para explicar históricamente
  con qué objetivo se obtuvo el achievement.

### Cambio de target period

Política V1 recomendada: el cambio `daily ↔ weekly` es efectivo el siguiente
lunes local, no a mitad de una semana abierta.

- los logs ya existentes no se reinterpretan retroactivamente;
- rewards daily ya entregados permanecen;
- un reward weekly empieza a ser elegible en la primera semana que comienza con
  `targetPeriod=weekly`;
- pasar `weekly -> daily` conserva el ledger/achievement semanal y comienza el
  contrato diario en el siguiente lunes;
- no se convierte un reward diario en weekly ni al revés.

La implementación deberá estampar una configuración efectiva o, como mínimo,
guardar `effectiveFrom` para reportes futuros. No se implementa en este
preflight.

## 14. Historical log edits

La suma semanal debe seguir siendo derivada de los logs actuales. Por ello,
editar un log histórico puede hacer que `weeklyTargetMet` cambie visualmente.

El claim y el reward concedido son históricos: no se revierten, no se resta
wallet y no se vuelve a pagar si el log vuelve a restaurarse. El sistema debe
mostrar la diferencia entre “objetivo actualmente alcanzado” y “achievement ya
reclamado”.

La misma política aplica a editar un día anterior de la semana, importar un log
desde otro dispositivo o corregir el valor diario.

## 15. Archive/delete

Archivar un hábito debe ocultarlo de nuevas evaluaciones, pero conservar:

- logs diarios;
- claims weekly;
- transactions y ledger de rewards;
- información suficiente para reportes históricos.

Eliminar un hábito no debe borrar economía histórica accidentalmente. En local,
el transaction repository está separado del mapa de hábitos y no debe limpiarse
como efecto implícito de eliminar el hábito. En cloud existe un riesgo real: la
tabla `habit_currency_reward_ledger` referencia `public.habits(id) ON DELETE
CASCADE`, por lo que un delete remoto puede eliminar el ledger histórico.

Antes de activar rewards weekly, Supabase debe definir una política explícita:
soft delete/archive, `RESTRICT`, o una referencia histórica desacoplada. No se
modifica ahora porque la petición prohíbe migrations y Supabase.

## 16. Future multi-device/Supabase

Escenario requerido:

```text
Pixel: 3/3 offline
iPhone: sincroniza después
=> un único claim y un único reward
```

La solución futura debe ser server-authoritative para la operación monetaria:

1. ambos dispositivos calculan o reciben el mismo `remoteHabitUuid` y
   `weekStartLocal`;
2. ambos construyen el mismo `completionEventId` semanal;
3. ambos envían un request ID determinista;
4. la RPC toma un advisory lock y devuelve el ledger existente si el source ya
   fue aplicado;
5. el cliente guarda la confirmación y elimina la pending operation.

La constraint remota debe garantizar, como mínimo, un apply por
`user_id + source_type + source_id` y un request id único. Para evitar que una
edición de target cree dos claims del mismo periodo, la clave de achievement
debe seguir siendo `habit + weekStart`, no `habit + target`.

La futura implementación debe decidir si el servidor valida la suma de logs
sincronizados antes de aplicar el reward o si el cliente emite un evento
firmado/validado. No se debe confiar permanentemente en dos clientes que
recalculan de forma independiente la elegibilidad económica.

## 17. Statistics boundary

Statistics debe medir comportamiento y progreso real, no consultar el reward
ledger para saber si una semana se cumplió.

Boundary recomendado:

- fuente de `weeklyActual`: `history.habitCountValues` o su equivalente remoto;
- fuente de `weeklyTarget`: configuración efectiva del hábito;
- `weeklyTargetMet`: comparación de ambos;
- reward/claim: fuera de Statistics;
- actividad diaria/dots: `dayValue > 0`, separada del achievement semanal;
- COUNT daily conserva su cálculo diario actual.

No se ha modificado Statistics.

## 18. Weekly Report boundary

Weekly Report debe calcular cumplimiento a partir de logs y configuración
efectiva, nunca del reward ledger.

Para weekly COUNT, el futuro contrato debe contener total semanal, target,
remaining, raw progress y estado achieved. Los dots diarios representan
actividad (`value > 0`) y el breakdown debe conservar los valores de cada día.
No debe producir siete comparaciones independientes contra el target semanal.

La configuración versionada del report debe conocer `targetPeriod` y la fecha
efectiva para no reinterpretar semanas cerradas. No se ha modificado Weekly
Report ni su SQL.

## 19. Home feedback boundary

Home ya muestra progreso `actual/target` y permite continuar incrementando
weekly COUNT después de alcanzar el target. El cruce puede producir feedback
micro, por ejemplo una transición visual o mensaje ligero en el card, pero no
debe convertir el hábito en completion diaria ni lanzar una celebración grande.

El feedback de reward, si se añade en Fase 4B, debe dispararse una vez usando el
evento semanal confirmado, no cada vez que Home reconstruye selectors. El
feedback no debe ser la fuente de persistencia ni de dedupe.

No se ha modificado Home.

## 20. Recommended data model

### Estado derivado

No persistir `weeklyTargetMet`. Derivarlo como:

```text
weeklyActual = sum(habitCountValues[localDate][habitId])
               para lunes..domingo
weeklyTargetMet = weeklyActual >= target
```

### Evento histórico

La capacidad mínima que no cubre el transaction diario actual es un claim
semanal, conceptualmente:

```text
WeeklyHabitAchievementClaim {
  claimKey: habitId|weekStartLocal
  habitId
  weekStartLocal
  achievedAt
  targetAtClaim
  achievementReached: true
  rewardStatus: pending|granted|not_applicable
  completionEventId
  rewardTransactionId
}
```

Storage local recomendado: un mapa versionado bajo `history`, por ejemplo
`weeklyHabitAchievementClaims`, scoped al mismo usuario que UserStateStore.
El record debe serializarse de forma tolerante y no depender de que el hábito
continúe activo.

`HabitRewardTransaction` debe evolucionar para distinguir `period=weekly` y
`weekStartLocal` o para referenciar `claimKey`; no se debe guardar una fecha de
lunes en un campo que siga significando silenciosamente “día de completion”.
La fuente de verdad de “claimed” es el claim; la fuente de verdad de “granted”
es la transaction/ledger. Si la economía está deshabilitada, el claim sigue
siendo válido con `not_applicable`.

Mapping remoto futuro: una tabla/evento de achievement semanal o una extensión
del ledger con `period`, `week_start_local`, `claim_key` y `target_at_claim`,
con unique constraint por usuario + claim key. No se crea migration ahora.

## 21. Closed product decisions

| # | Decisión cerrada para V1 | Contrato |
|---:|---|---|
| 1 | Achievement inmediato o fin de semana | Inmediato al cruce false → true. |
| 2 | Cuándo reward | En el mismo cruce, tras persistir/confirmar el claim. |
| 3 | Máximo de rewards | Uno por `habitId + weekStartLocal`. |
| 4 | Decremento posterior | Estado derivado puede volver a false; reward no se revierte. |
| 5 | Re-entry | No crea segundo claim ni reward. |
| 6 | Cambio de target | No recompensa una edición por sí sola; claim existente no se revoca. |
| 7 | Cambio de targetPeriod | Efectivo el siguiente lunes; no convierte ni reinterpreta la semana abierta. |
| 8 | Semana actual para streak | No alcanzada aún no rompe; se consolida al cierre. |
| 9 | Significado de weekly streak | Streak separado de semanas cerradas alcanzadas. |
| 10 | Reward reutilizado o específico | Reutilizar provisionalmente reward COUNT normal una vez; requiere aprobación de Producto. |
| 11 | Persistencia | Claim semanal durable + transaction/ledger de reward; estado visual derivado de logs. |
| 12 | Idempotencia | Claim key local + event/request IDs deterministas + unique constraint remota futura. |
| 13 | Supabase futuro | UUID remoto del hábito + lunes local como identidad; operación server-authoritative. |

## 22. Exact implementation phases

### Fase 4A — Weekly achievement state + idempotency

- definir contrato `WeeklyHabitAchievementClaim` y version de serialización;
- introducir `claimKey = habitId|weekStartLocal` y helpers de fecha local;
- calcular transición con valores semanal anterior/posterior;
- guardar `targetAtClaim`, achievedAt y estado de reward;
- extender `HabitRewardTransaction` con periodo/source explícito o referencia al
  claim;
- resolver target edits, period edits, log edits, archive y delete;
- garantizar que Home solo consume el estado derivado;
- tests de cruce, over-target, decrement/re-entry, restart y rollover;
- no tocar wallet, XP, Amber ni RPC todavía.

### Fase 4B — Reward grant integration

- reutilizar la regla de COUNT aprobada por Producto;
- aplicar reward solo si Fase 4A confirma el claim nuevo;
- consumir boosts una vez y registrar sus IDs en la transaction;
- corregir la atomicidad local entre wallet/progression y transaction, o añadir
  recuperación segura antes de permitir el pago;
- construir event/request IDs semanales estables;
- conectar pending/retry cloud y ledger remoto sin duplicar fuente;
- tests offline, timeout, restart, multi-device simulado, delete y duplicate
  request.

### Fase 4C — Weekly streak semantics

- derivar semanas cerradas desde claims, no desde completion diaria;
- excluir la semana actual incompleta de breaks;
- definir provisional vs consolidado en UI/domain;
- añadir snapshot y achievements de weekly streak separados;
- tests de secuencias alcanzada/alcanzada/missed/alcanzada y timezone.

### Gate posterior

Statistics, Weekly Report, migración Supabase y rollout multi-device deben ser
fases posteriores e independientes. No deben activarse rewards weekly en
producción si sus límites de configuración efectiva y delete histórico no están
resueltos.

## 23. Tests inspected/executed

### Inspeccionados

- `test/stores/user_state_store_reward_persistence_test.dart`
- `test/stores/user_state_store_reward_boosts_test.dart`
- `test/stores/user_state_store_achievement_rewards_test.dart`
- `test/features/habits/application/habit_currency_reward_coordinator_test.dart`
- `test/features/achievements/application/achievement_level_reward_coordinator_test.dart`
- `test/features/habits/domain/metrics/weekly_count_progress_test.dart`
- `test/screens/home/weekly_count_target_home_test.dart`
- `test/stores/user_state_store_schedule_guards_test.dart`
- `test/features/completed_day_phrase/completed_day_phrase_test.dart`
- `test/screens/home/habit_card_swipe_shell_test.dart`
- `test/screens/home/habit_card_widget_interaction_test.dart`
- `test/features/habits/domain/metrics/habit_occurrence_evaluator_test.dart`
- `test/features/weekly_report/domain/weekly_report_domain_test.dart`

### Ejecutados en este preflight

```text
flutter test test/features/habits/application/habit_currency_reward_coordinator_test.dart test/stores/user_state_store_reward_persistence_test.dart test/stores/user_state_store_reward_boosts_test.dart test/stores/user_state_store_achievement_rewards_test.dart --reporter compact
```

Resultado: **48 tests passed**.

```text
flutter test test/features/habits/domain/metrics/weekly_count_progress_test.dart test/screens/home/weekly_count_target_home_test.dart test/screens/home/habit_card_swipe_shell_test.dart test/screens/home/habit_card_widget_interaction_test.dart test/features/completed_day_phrase/completed_day_phrase_test.dart test/stores/user_state_store_schedule_guards_test.dart --reporter compact
```

Resultado: **110 tests passed**.

El preflight técnico previo documenta además 109 tests focalizados pasados y un
fallo baseline conocido de `timesPerWeek`; no se ha corregido ni se ha usado
como señal de regresión de weekly COUNT. El comando aislado afectado es:

```text
flutter test test/stores/user_state_store_times_per_week_schedule_test.dart --plain-name "normalizes invalid timesPerWeek payload values" --reporter compact
```

Falla porque espera un schedule `timesPerWeek` canónico y la implementación
actual devuelve `daily`. Esta Fase 4 no modifica ese comportamiento.

No se ejecutaron migrations, RPCs reales ni pruebas contra Supabase.

## 24. Risks

1. **Clave diaria insuficiente:** reutilizar `localDateKey` permitiría pagar
   varias veces durante una semana.
2. **Crash entre writes locales:** wallet y transaction no son atómicos.
3. **Cambio de target retroactivo:** puede crear rewards por edición si no se
   aplica el guard de configuración.
4. **Cambio de periodo a mitad de semana:** puede reinterpretar logs históricos.
5. **Delete cloud en cascada:** el ledger actual puede desaparecer con el
   hábito remoto.
6. **Timezone:** un lunes UTC no siempre es un lunes local del usuario.
7. **Remote target authority:** el RPC actual no valida una suma semanal.
8. **Source type semántico:** `habit_completion` hoy significa evento diario.
9. **Cloud logical date:** el campo SQL acepta ISO date pero no expresa que sea
   `week_start`.
10. **Boosts duplicados:** un retry mal coordinado puede consumirlos más de una
    vez.
11. **Home como fuente de evento:** rebuilds no deben disparar rewards.
12. **Achievement catalog mismatch:** IDs de catálogo no representan claims
    recurrentes por semana.
13. **Streak diario:** reutilizarlo inflaría o rompería rachas.
14. **Pending operations antiguas:** cambiar la forma del ID puede dejar
    operaciones legacy sin reconciliar.
15. **Over-target:** el ring clampado no debe ocultar el valor raw usado para
    explicar el achievement.
16. **Logs editables:** estado visual actual y achievement histórico pueden
    divergir legítimamente.
17. **Archive/delete local:** limpiar el hábito sin limpiar ni perder su ledger
    requiere una política separada.
18. **Configuración efectiva ausente:** Weekly Report podría reinterpretar
    semanas cerradas.
19. **Multi-device race:** dos clientes pueden cruzar simultáneamente si no hay
    constraint remota.
20. **Economía sin tarifa semanal definida:** reutilizar la tarifa diaria debe
    ser una decisión, no una inferencia silenciosa.
21. **Notificaciones:** el observer actual carece de `weekStart` y periodo.
22. **Daily counters:** `xpEarnedToday` y `coinsEarnedToday` no deben ser la
    autoridad del reward weekly.
23. **Backward compatibility:** todos los mappers deben tolerar period ausente
    como daily.
24. **Baseline timesPerWeek:** el fallo existente no debe mezclarse con esta
    feature.

## 25. Critical unknowns

1. ¿Producto aprueba exactamente la tarifa normal de COUNT para el reward
   semanal, incluyendo el consumo de boosts?
2. ¿El reward weekly se valida localmente con logs o debe exigir confirmación
   server-side una vez que Supabase reciba todos los logs?
3. ¿La timezone canónica es la del dispositivo actual o una timezone de perfil
   persistida para toda la vida del hábito?
4. ¿Se permite editar target/period durante una semana abierta o se debe
   bloquear el cambio hasta el lunes?
5. ¿Archive y delete son realmente distintos en el producto, y cuál debe ser
   la política de conservación histórica del ledger cloud?
6. ¿Se necesita mostrar `weeklyAchievementClaimed` explícitamente cuando el
   progreso actual vuelve a estar por debajo del target?
7. ¿El weekly streak se muestra como provisional durante la semana actual o
   solo después del cierre del domingo?
8. ¿El claim semanal debe vivir en `history` o se prefiere una tabla/ledger
   local independiente para separar métricas de economía?
9. ¿La fecha de lunes puede reutilizar temporalmente `logical_date_key` en el
   RPC actual o se requiere un nuevo campo remoto antes de Fase 4B?
10. ¿Qué política de recuperación se usará para el crash entre wallet y
    transaction local?

