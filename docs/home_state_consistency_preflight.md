# Home State Consistency Preflight

Auditoría estática y regresión focalizada. Esta fase no implementa fixes de
producción.

## 1. Executive summary

Se reconstruyeron los pipelines de Complete y Skip desde Home hasta el store,
persistencia local, sincronización cloud, selectors y render. No se demuestra
con inspección estática que el caso manual concreto pierda siempre la
completion; sí se demuestra un camino de riesgo: Home registra una transición
antes de la mutación, mientras varias salidas del store son `return` silencioso
(`root == null`, hábito inexistente, fecha no elegible o guard de estado), y la
transición solo se retira explícitamente ante excepción o cuando el estado
canónico deja de ser pending.

El bug fantasma es compatible con ese camino. `pendingCount` y
`pendingHabits` comparten fuente, pero una transición retenida puede reemplazar
visualmente la card por un tile colapsado mientras el hábito continúa en
pending.

## 2. Bug A reproduction

Caso observado: CHECK `timesPerWeek`, objetivo 4, semana ya en 5/4, día actual
pending. El contrato esperado es completar hoy y conservar 6/4.

La reproducción futura exacta está definida en la sección 27. La suite actual
confirma que un flexible CHECK sigue siendo normal/actionable después de la
cuota y que el store conserva la completion local; no existe todavía una
prueba Home end-to-end que fuerce simultáneamente 5/4, transición, rebuild,
reload y fallo/no-op.

## 3. Bug B reproduction

Caso observado: contador/filtro indica un pending pero no hay card visible.

El caso estático más concreto es:

```text
pendingHabits = [A]
→ Home registra transición para A
→ canonical state sigue pending por un no-op silencioso
→ la animación termina
→ pendingRemoved sigue false
→ el transition tile colapsado conserva A como ID activo
→ pendingCount = 1, card normal visible = 0
```

No se encontró un segundo selector independiente que recalculase el contador.

## 4. Completion pipeline

Diagrama exacto para el tap del CHECK en Home:

```text
HabitCardWidget._handleCheckTap()
→ _habitCard.onCheckTap
→ _registerHabitCompletionTransition()
→ IosFeedback.success()
→ UserStateStore.setHabitCompletionForKey(
     habitId, dateKey: _dateKey(_selectedDay), done: ...)
→ _enqueueHabitMutation()
→ _setHabitCompletionForKey()
→ _ensureDailyReset()
→ _activeHabitIndex()
→ _isHabitExpectedForDate()
→ si hoy: _completeHabit()
→ guard check: habit['doneToday'] == true
→ _applyHabitProgressDelta()
→ _setHabitCompletionTimeState()
→ _syncHabitHistoryFromState()
→ UserStateStore.save()
→ _saveStore()
→ _emitChanged()
→ UserStateRepository.save()
→ UserStateStorage.write()
→ best-effort HabitLogSyncService.syncDailyLogForHabit()
→ best-effort progress/reward/achievement sync
→ selectors se recalculan en el rebuild de Home
→ _reconcileHabitCompletionTransitions()
→ _HomeHabitCompletionTransitionTile finaliza y llama cleanup
```

El swipe derecho usa el mismo store path, pero registra transición con el
estado visual del swipe. `completeHabit()` y `toggleHabitDoneForDate()` son
entradas alternativas del store; para hoy convergen en `_completeHabit()`.

## 5. Skip pipeline

```text
HabitCardSwipeShell._handleSkipAction()
→ Home _habitCard.onSkip(visualState)
→ _registerHabitSkipTransition()
→ UserStateStore.setHabitSkipForKey(
     habitId, dateKey: _dateKey(_selectedDay), skipped: ...)
→ _enqueueHabitMutation()
→ _setHabitSkipForKey()
→ _ensureDailyReset()
→ _activeHabitIndex()
→ _isHabitExpectedForDate()
→ actualiza activeHabits si hoy
→ _setHabitSkipForDay()
→ si skipped: borra completion/count/time del día
→ UserStateStore.save()
→ local storage
→ best-effort habit-log sync
→ notificationMutationObserver.onHabitSkipped()
→ rebuild/selectors/transition reconciliation
```

Skip no pasa por `_completeHabit()` ni por el reward completion path. Comparte
cola, persistencia local, transición y habit-log sync.

## 6. Mutation queue

La cola es `Future<void> _habitMutationQueue` en `UserStateStore`.
`_enqueueHabitMutation` encadena FIFO con `_habitMutationQueue.then(...)` y
reemplaza la cola por `next.catchError((_) {})`. La operación que llama el
usuario recibe `next`, por lo que el error puede propagarse al caller, mientras
la cola queda habilitada para la siguiente mutación.

Las mutaciones de Complete, Skip y count pasan por la cola. El remote pull no
usa esta cola; tiene únicamente `_isHabitsRemotePullRunning`, por lo que puede
competir temporalmente con una mutación local. No se encontró adelantamiento
entre dos mutaciones de la cola, pero sí una frontera no serializada con pull.

## 7. Optimistic state

Home usa estado optimista visual, no un store optimista separado: la transición
se inserta inmediatamente en `_habitCompletionTransitions` y el tile normal se
oculta del listado mientras el store sigue siendo la fuente canónica.

La confirmación real es el cambio de `pendingHabits` tras `notifyListeners()`.
Si `save()` lanza, Home elimina la transición en el `catch`. Si el store
termina con `return` silencioso, el callback no sabe que fue no-op y no ejecuta
rollback.

## 8. Store mutation

La completion CHECK de hoy muta `habit.doneToday`, `habit.skippedToday`, la
historia (`habitCompletions`, `habitSkips`, `habitCompletionTimes`) y snapshots
de rewards antes de `save()`. `save()` asigna `_state`, normaliza raíces,
emite `notifyListeners()` y después espera `_repo.save()`.

Un `return` temprano no cambia el canonical state. Los guards relevantes son
estado nulo, índice inexistente, fecha no elegible y CHECK ya done hoy.

## 9. Idempotency

La idempotencia de completion es diaria y semántica: `habitId + localDateKey`.
No hay `operationId` ni `mutationId` propio para la completion del hábito.

La idempotencia de reward usa `HabitRewardTransaction.completionKey`, formada
por `habitId|localDateKey`, y el ledger cloud usa un `requestId` generado para
la operación de reward. Es una protección del grant, no del estado de
completion.

Por tanto, el mismo hábito en otro día debe poder completarse aunque la cuota
semanal esté cumplida. El guard `habit['doneToday'] == true` solo bloquea una
segunda completion del mismo día.

## 10. timesPerWeek / over-target guards

No se encontró en `_completeHabit`, `_applyHabitProgressDelta` ni en los
callbacks de Home un guard `weeklyCompletedDays >= timesPerWeek` que bloquee la
completion. `weeklyQuotaMet` se calcula para presentación.

`canRightCommitComplete` depende de que sea CHECK y no esté done hoy; no
depende de la cuota. Los tests existentes cubren que el hábito flexible sigue
siendo normal después de cuota y que muestra over-completion.

## 11. Local date handling

Home genera `dateKey` con `_dateKey(_selectedDay)`, normalizando año/mes/día
locales. El store convierte la clave con `_dateFromKey`, compara con
`_nowProvider()` mediante `_isSameDay`, y vuelve a generar claves locales.

Remote logs usan `remoteLog.logDate.toLocal()` antes de crear la clave.
Completion times se guardan en epoch local y se convierten a local al comparar.

Existe una diferencia de disciplina: `HabitLogSyncService.syncTodayLogForHabit`
usa `DateTime.now()`, aunque el path Home pasa explícitamente la fecha. El
riesgo de mismatch para este path es bajo pero debe cubrirse con un test de
medianoche/zona horaria.

## 12. Local persistence

`UserStateStore.save()` cambia primero `_state`, normaliza y notifica; luego
`UserStateRepository.save()` valida el scope y llama a
`UserStateStorage.write()`. La completion queda en memoria antes de la
persistencia. Si el write falla, `_setHabitCompletionForKey` intenta rollback
de reward persistence y relanza; `_completeHabit` hace lo mismo.

La cola no hace rollback automático del estado canónico en todos los no-op; un
caller Home solo retira la transición cuando recibe excepción.

## 13. Cloud persistence/reconciliation

El habit log cloud es best-effort y sus excepciones se absorben en
`HabitLogSyncService`. La completion local no depende de que exista sesión,
remoteId ni de que el upsert cloud tenga éxito.

`maybeSyncHabitsFromRemoteBestEffort()` se dispara desde Home y puede hacer
pull automático/manual. El pull combina hábitos y logs y posteriormente puede
llamar a `store.save(root)`.

Para logs existentes, `_shouldReplaceLocalProgressWithRemote` solo reemplaza un
estado local cuando el log remoto está completado, tiene `updatedAt` y es más
nuevo que el `habitCompletionTimes` local. Si no hay timestamp local positivo,
no reemplaza. No hay version vector global.

## 14. Reward coupling

Rewards se calculan dentro de `_completeHabit`, pero el estado de completion se
actualiza antes y se persiste junto con el snapshot. El reward guard
`rewardAlreadyGranted` solo evita duplicar XP/coins; no bloquea la completion.

Un fallo de reward cloud se maneja best-effort o mediante ledger/pending
operation según configuración. Un fallo de `store.save()` sí puede devolver la
operación completa con excepción y ejecutar rollback de reward persistence.

## 15. Home selectors

`buildHomeViewData()` llama a `buildHabitDaySummary()` con
`userState.activeHabits`, `userState.history`, `_selectedDay` y `today` local.

`buildHabitDaySummary()`:

- excluye archivados;
- calcula `expectedHabits` por schedule/createdAt;
- resuelve `doneToday`/`skippedToday` desde el snapshot diario;
- clasifica `pendingHabits` cuando no done y no skipped;
- clasifica `completedHabits` cuando done;
- clasifica `skippedHabits` cuando skipped.

`habitsForFilter()` devuelve directamente una de esas tres listas.

## 16. Pending count vs visible list

El header recibe `homeData.pendingCount`, cuyo getter es
`pendingHabits.length`. El listado recibe `habitsForFilter(homeData,
HomeHabitStatusFilter.pending)`, que devuelve la misma lista.

La invariante canónica, sin transición activa, es:

```text
pendingCount == pendingHabits.length
rendered pending IDs == pendingHabits IDs
```

La única excepción deliberada es durante una transición: el renderer sustituye
una card por su transition tile.

## 17. Transition state

El estado es `_habitCompletionTransitions`, map por `habitId`.
`HomeHabitCompletionTransition` contiene `transitionId`, `habitId`,
`dateKey`, snapshot, índice original, offsets, animación visual y
`pendingRemoved`.

El listado pending calcula `activeTransitionHabitIds` y omite esos hábitos del
listado normal, insertando el transition tile en su posición.

## 18. Transition cleanup

Hay cuatro caminos:

- excepción del callback Home: `_removeHabitCompletionTransition()`;
- cambio de scope: limpia el map;
- cambio de día: limpia el map;
- reconciliación: marca `pendingRemoved` cuando el ID ya no está pending y
  elimina cuando también terminó la animación.

El tile llama `_markHabitCompletionTransitionVisualCompleted()` al finalizar.
`isReadyForCleanup` exige `visualAnimationCompleted && pendingRemoved`.

Hueco: un no-op silencioso deja `pendingRemoved == false`; después de la
animación el transition tile puede permanecer colapsado indefinidamente.

## 19. Stable keys

Las cards usan `ValueKey('habit_card_$id')`; swipe shell usa
`ValueKey('habit_swipe_$id')`; los items de lista usan
`ValueKey('${keyPrefix}_$id')`; el transition tile usa
`ValueKey('habit_completion_transition_${transitionId}_$habitId')`.

No se encontró `UniqueKey` ni key de índice para las cards normales. El índice
solo se usa como posición de inserción y fallback de datos sin ID. Las keys son
estables para hábitos con ID válido.

## 20. Filter interactions

Al cambiar de filtro se cierra el swipe abierto, se marcan las transiciones
visibles como finalizadas y se cambia el filtro. El renderer solo usa
transiciones cuando el filtro es pending, por lo que una transición no se pinta
en completed/skipped.

Riesgo: volver rápidamente a pending antes de que el canonical state cambie
puede reactivar la misma transición retenida. El cambio de filtro no limpia
siempre el map completo; depende de que la transición quede visualmente lista.

## 21. Async timeline

```text
T0 tap
T1 _registerHabitCompletionTransition + setState
T2 espera IosFeedback.success
T3 enqueue FIFO
T4 mutation muta memoria/historia
T5 store.save emite notifyListeners
T6 local repository write await
T7 habit-log/reward/progress sync best-effort
T8 Home rebuild recalcula pending
T9 reconcile marca pendingRemoved
T10 animación finaliza y cleanup
```

El pull remoto puede iniciarse desde `initState`/refresh sin esperar la cola de
habit mutations. La protección por timestamp existe para logs, pero no hay
serialización común ni un operation ID de completion que permita correlacionar
el timeline completo.

## 22. Existing test coverage

La cobertura encontrada incluye:

- callbacks y doble tap de `HabitCardWidget`;
- swipe complete/skip, umbral y callbacks únicos;
- snapshots, offsets y cleanup visual de transiciones;
- filtros pending/completed/skipped y keys;
- selectors de schedules, flexible pending, quota reached y over-completion;
- FIFO/rapid completions y último hábito en `user_state_store_schedule_guards_test`;
- persistencia local y rewards CHECK/flexible;
- pulls remotos, scope, logs y protección contra reemplazo stale;
- fecha esperada y guards de schedule.

## 23. Bug A root cause

Clasificación: **H — combinación potencial de UI optimistic state + no-op/guard
del store; posible contribución de reconciliación cloud**.

Lo demostrado:

- Home oculta visualmente antes de tener confirmación canónica.
- Existen `return` silenciosos en el mutation path.
- Home solo revierte transición en excepción.
- La completion local se persiste antes del sync cloud.
- `timesPerWeek` no bloquea directamente una completion por cuota.

Lo no demostrado sin instrumentación/repro end-to-end: cuál de esos no-op,
fallo local o pull remoto stale ocurrió en el vídeo concreto. No se debe
atribuir definitivamente BUG A a cloud ni a rewards todavía.

## 24. Bug B root cause

Clasificación: **B — transition cleanup**, con posible interacción de rollback/no-op.

No parece selector divergence: contador y pending list comparten
`pendingHabits`. El camino demostrado es que una transición permanece cuando la
card canónica continúa pending, el renderer omite el ID y el tile colapsado no
es una card visible.

## 25. Relationship between both bugs

**PARTIALLY.**

Un mismo flujo puede producir ambos: Complete optimista, mutation no-op o
fallida, canonical pending y transición sin cleanup. Eso explica completion que
no se consolida y `pendingCount = 1` con cero cards normales.

Pero también pueden ser independientes: BUG A puede venir de persistencia o
reconciliación remota; BUG B puede venir de cleanup incluso si la completion
local sí fue correcta.

## 26. Recommended fix

No se implementa en esta fase.

Para BUG A, el primer fix recomendado es hacer que el mutation path devuelva un
resultado explícito (`applied`, `alreadyApplied`, `notApplicable`, `failed`) o
lance un error de no-op, y que Home confirme/revierta la transición según ese
resultado. Mantener el guard diario y no introducir guard de cuota semanal.

Para BUG B, cleanup debe ocurrir en todo resultado no aplicado, excepción,
cambio de día/scope/filtro y dispose; además debe existir una reconciliación
defensiva que no deje un ID pending oculto por un transition tile colapsado.

## 27. Required regression tests

Añadir, sin cambiar el contrato:

1. `timesPerWeek=4`, historial actual 5 completions, hoy pending; completar y
   verificar store 6/4, historia de hoy, queue drenada, rebuild/reload y card
   fuera de pending.
2. El mismo caso con 2 completions; verificar 3/4 persistente.
3. Completion que devuelve no-op/error después de registrar transición; la card
   vuelve visible y el map de hidden/transition IDs queda vacío.
4. `[A]` pending sin transición: count 1 y rendered `[A]`.
5. `[A]` pending, optimistic complete, rollback: count 1 y rendered `[A]`.
6. A/B/C rápidos: tras A y B, pending count 1 y rendered `[C]`.
7. Último hábito: success y skip producen 0/0; rollback produce 1/[A].
8. Cambiar pending/completed/pending durante una transición y comprobar
   canonical IDs.
9. Completion en cambio de medianoche/timezone para verificar exactamente el
   `localDateKey`.
10. Pull remoto stale después de completion local; comprobar que no reinyecta
    pending cuando el timestamp local es más nuevo.

## 28. Logging plan if needed

**YES**, para cerrar la causa del vídeo concreto.

Añadir temporalmente, sin persistir datos sensibles:

- en `_registerHabitCompletionTransition`, `_remove...` y
  `_reconcile...`: `habitId`, `transitionId`, `dateKey`, pending IDs y motivo;
- en `_enqueueHabitMutation` y cada mutation: queue depth/sequence, start,
  end, result (`applied/no-op/error`), habitId y dateKey;
- justo antes/después de `_setHabitCompletionForDay` y `store.save`: done,
  skipped, completion time, local scope;
- en `_mergeRemoteHabitLogsIntoLocalState`: local timestamp, remote timestamp,
  decision replace/skip;
- en `buildContent`/`HomeHabitsSliver`: pending IDs, filter IDs,
  transition IDs y rendered entry IDs.

## 29. Risks

- Cambiar cleanup sin respetar animación puede mostrar dos cards.
- Cambiar guards diarios puede permitir duplicados del mismo día.
- Serializar pull y mutation podría aumentar latencia de refresh.
- Un remote log sin timestamp no puede probar recencia.
- Datos legacy sin `habitCompletionTimes` reducen la certeza de reconciliación.
- Filtros y cambio de fecha durante animación pueden exponer estados
  intermedios.

## 30. Implementation plan

### HOME-FIX-1 — completion/no-op root cause

Instrumentar primero y añadir los tests 1, 2, 3, 9 y 10. Corregir el contrato
de resultado/no-op del store sin tocar cuota semanal ni rewards como fuente de
verdad.

### HOME-FIX-2 — transition/ghost cleanup

Añadir los tests 4–8. Centralizar cleanup por éxito, no-op, excepción, rollback,
filter/date/scope change y dispose. Verificar la invariante count/list/render.

### HOME-FIX-3 — regression + device QA

Ejecutar Home, store, persistence/sync y reward suites, después probar el caso
5/4 en dispositivo y observar logs temporales antes de retirarlos.

## Verification

- Tests Home/store/persistence/sync relevantes: **204 passed**.
- `git diff --check`: **sin errores**; solo avisos normales LF/CRLF.
- Esta auditoría añadió únicamente este documento.
- No se implementó ningún fix de producción.
- No se inició Weekly Report.
