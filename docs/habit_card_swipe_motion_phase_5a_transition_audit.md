# Habit Card Swipe Motion - Phase 5A Transition Audit

## 1. Resumen ejecutivo

El salto visual al completar un habito no viene del gesto ni del spring. Viene
del cambio inmediato de clasificacion tras el commit productivo:

```text
pendingHabits -> completedHabits
```

`HabitCardSwipeShell` confirma `rightCommit`, llama al callback de Home y Home
ejecuta `UserStateStore.setHabitCompletionForKey`. Para el dia actual, ese
metodo delega en `completeHabit`, muta el habito, llama a `store.save(root)` y
`_saveStore` emite `notifyListeners()` antes de persistir. Como Home usa
`context.watch<UserStateStore>()`, reconstruye enseguida, recalcula
`pendingHabits` y `completedHabits`, desmonta la fila pendiente y monta otra
fila en la seccion completada.

Decision recomendada para Fase 5B: **ejecutar el callback productivo
inmediatamente y mantener una representacion visual temporal no interactiva en
la zona pending mientras el arbol real ya se actualiza**. El estado temporal
debe vivir en Home/UI, no en store, y la transicion debe ser propietaria de la
lista Home, no de `UserStateStore`.

## 2. Flujo exacto de rightCommit

1. `HabitCardSwipeShell._handleHorizontalEnd` recibe `DragEndDetails`.
2. Lee `details.velocity.pixelsPerSecond.dx`.
3. Llama al resolver puro `resolveSwipeDestination`.
4. Si el resultado es `HabitCardSwipeDestination.rightCommit`, llama a
   `_commitRight(rightVelocity)`.
5. `_commitRight` entra en estado `committingRight`, lanza un spring local hacia
   `0` y ejecuta `await widget.onSwipeRightComplete!.call()`.
6. Home pasa ese callback desde `_HomeScreenCardBuilders._habitCard`.
7. El callback de Home hace `IosFeedback.lightImpact()` y luego:

```dart
await context.read<UserStateStore>().setHabitCompletionForKey(
  habitId: id,
  dateKey: _dateKey(_selectedDay),
  done: !doneToday,
);
```

8. `UserStateStore.setHabitCompletionForKey` delega en
   `_setHabitCompletionForKey`.
9. Si `dateKey` es hoy y `done == true`, `_setHabitCompletionForKey` llama a
   `await store.completeHabit(habitId: habitId)` y retorna.
10. `completeHabit` delega en `_completeHabit`.
11. `_completeHabit` localiza el habito activo, aplica progreso/recompensa,
    sincroniza history y llama `await store.save(root)`.
12. `store.save(root)` delega en `_saveStore`.
13. `_saveStore` asigna `store._state = newState`, normaliza/hidrata y llama a
    `store._emitChanged()`.
14. `_emitChanged()` ejecuta `notifyListeners()`.
15. Home reconstruye por `context.watch<UserStateStore>()`.
16. `buildHomeViewData(root, _selectedDay)` recalcula `pendingHabits` y
    `completedHabits`.
17. La fila `habit_pending_$id` deja de existir.
18. Si `completedHabits` no esta vacio, aparece el header de completados.
19. Si `_showCompleted == true`, se monta la fila `habit_done_$id`; si esta
    plegado, solo aparece el header.

## 3. Linea temporal callback, rebuild y desmontaje

```text
t0  usuario suelta swipe derecho
t1  resolver devuelve rightCommit
t2  shell entra en committingRight y arranca spring local a closed
t3  shell llama y espera onSwipeRightComplete
t4  Home llama setHabitCompletionForKey
t5  _setHabitCompletionForKey delega en completeHabit si es hoy
t6  _completeHabit muta habit/progreso/recompensas/history
t7  store.save(root)
t8  _saveStore asigna _state y notifyListeners()
t9  Home rebuild por context.watch
t10 buildHomeViewData mueve el habito de pending a completed
t11 Flutter desmonta la rama con key habit_pending_$id
t12 Flutter monta header/completed y, si esta expandido, habit_done_$id
t13 repo.save termina despues del notify
t14 Future del callback termina cuando completeHabit/setHabitCompletionForKey acaba
t15 shell podria liberar committingRight si siguiera montado
```

El punto importante es que el rebuild ocurre en `t8/t9`, antes de que termine
necesariamente todo el `Future` productivo. `_saveStore` notifica antes de
`await store._repo.save(store._state!)`, asi que la UI se actualiza antes de la
persistencia final.

## 4. Estructura de pendingHabits

`buildHomeViewData` construye `viewHabits` a partir de `activeHabits`, filtra
archivados, aplica schedule y mezcla snapshot del dia seleccionado. Luego:

```dart
final pendingHabits = viewHabits.where((h) {
  final done = h['doneToday'] == true;
  final skipped = h['skippedToday'] == true;
  return !done && !skipped;
}).toList();
```

Para habitos `timesPerWeek`, pending exige que no este skipped, no este hecho
hoy y no se haya alcanzado el target semanal.

En UI:

- `HomeScreen.buildContent` obtiene `homeData = buildHomeViewData(...)`.
- `_HomeLoadedView` mete un `CustomScrollView`.
- `HomeScrollableContentSliver` aplica `SliverPadding`.
- `HomeHabitsSliver` pinta `pendingHabits` primero dentro de un
  `SliverMainAxisGroup`.
- Si hay menos de 2 pending, usa `SliverList`.
- Si hay 2 o mas pending, usa `SliverReorderableList`.

El orden conserva el orden de `viewHabits`; no hay sort adicional en la seccion.

## 5. Estructura de completedHabits

`completedHabits` sale del mismo `viewHabits`:

```dart
final completedHabits = viewHabits.where((h) {
  return h['doneToday'] == true;
}).toList();
```

Para `timesPerWeek`, completed si `doneToday == true` o si el target semanal ya
esta cumplido.

En UI:

- Se pinta despues de pending dentro del mismo `SliverMainAxisGroup`.
- Si `completedHabits.isNotEmpty`, aparece un `SliverToBoxAdapter` con header.
- Las cards completadas solo se montan si `showCompleted == true`.
- `_showCompleted` vive en `_HomeScreenState` y por defecto es `false`.
- Si hay menos de 2 completed visibles, usa `SliverList`.
- Si hay 2 o mas completed visibles, usa `SliverReorderableList`.
- Las cards completadas pasan `compact: true`.

Por defecto, al completar un pendiente, la card no aparece como card completada:
solo puede aparecer el header de completados si antes no habia completados.

## 6. Tabla de keys actuales

| Elemento | Key actual | Incluye seccion | Notas |
| --- | --- | --- | --- |
| Fila pending en `SliverList` | `ValueKey('habit_pending_$habitId')` | Si | Vive en `Padding` de `_buildStaticItem`. |
| Fila pending en `SliverReorderableList` | `ValueKey('habit_pending_$id')` | Si | Necesaria para reorder dentro de la seccion. |
| Fila completed | `ValueKey('habit_done_$habitId')` | Si | Identidad distinta aunque sea el mismo habitId. |
| Fila skipped | `ValueKey('habit_skipped_$habitId')` | Si | Identidad distinta por seccion. |
| `HabitCardSwipeShell` | Sin key explicita | No | Se identifica por posicion bajo la fila. |
| `HabitCardWidget` | Sin key explicita | No | Se identifica por posicion bajo el shell. |
| Superficie interna | `Key('habitCardSurface')` | No | Key constante dentro de cada card, no identifica habito. |
| Check done icon | `ValueKey('done')` | No | Solo para `AnimatedSwitcher` interno. |
| Check empty | `ValueKey('empty')` | No | Solo para `AnimatedSwitcher` interno. |

El mismo `habitId` podria conservar identidad entre secciones solo si se quitara
el prefijo de seccion. No conviene cambiarlo en 5B sin mucho cuidado: durante un
frame de transicion podria haber una representacion pending y otra completed del
mismo habito en ramas diferentes. Reutilizar la misma key en dos ramas hermanas
del arbol generaria conflicto de keys y comportamiento indefinido.

## 7. Animaciones visuales existentes

En `HabitCardSwipeShell`:

- drag 1:1 con `Transform.translate`;
- spring local al soltar hacia `closed` o `leftOpen`;
- right cue verde detras de la card durante desplazamiento derecho;
- guard `committingRight`.

En `HabitCardWidget`:

- `_fxController` dura `700 ms`;
- escala `1.0 -> 1.035 -> 1.0`;
- `completionBurstText` aparece con fade y slide hacia arriba;
- el check circular usa `AnimatedContainer` de `180 ms`;
- el icono check usa `AnimatedSwitcher` de `180 ms`;
- `_playCompleteFx()` empieza en `didUpdateWidget` cuando pasa de no completado
  a completado.

Problema: en rightCommit desde pending, la instancia pending normalmente se
desmonta. La instancia completed es nueva y, si se monta compacta en una seccion
expandida, nace ya con `isCompleted == true`; su `didUpdateWidget` no ve una
transicion `false -> true`. Por tanto, el FX interno no es una primera parte
fiable de la transicion pending -> completed.

## 8. Interaccion con SliverReorderableList

`pendingHabits` usa `SliverReorderableList` cuando tiene 2 o mas items. Con 0 o
1 usa `SliverList`.

El reorder necesita keys estables por item dentro de la lista:

```dart
ValueKey('${keyPrefix}_$id')
```

Tambien existe:

- `ReorderableDelayedDragStartListener(index: index)`;
- estado local `_preparedHabitId`;
- estado local `_draggingHabitId`;
- `proxyDecorator`;
- animaciones de scale/shadow mediante `_wrapHabitCard`.

Una transicion temporal no deberia insertarse como item reorderable real ni
deberia envolver drag handles. Si se mete un placeholder dentro de pending, debe
ser no interactivo y preferiblemente no reorderable, o debe deshabilitar reorder
para ese slot durante la salida. Cambiar indices de reorder mientras una salida
esta viva es uno de los riesgos principales.

Al desaparecer una card pending, la altura de la seccion se reduce y todos los
items posteriores suben inmediatamente. Si ademas aparece un header completed, el
layout cambia en otro punto del mismo `SliverMainAxisGroup`. Ese cambio brusco de
altura y montaje/desmontaje es la causa visual dominante.

## 9. Causa exacta del salto visual

La causa exacta es la combinacion de cuatro hechos:

1. El callback productivo actualiza el store inmediatamente.
2. `_saveStore` emite `notifyListeners()` antes de terminar la persistencia.
3. Home escucha con `context.watch<UserStateStore>()` y recalcula las secciones
   en el siguiente build.
4. Las filas tienen keys distintas por seccion (`habit_pending_$id` frente a
   `habit_done_$id`), por lo que Flutter desmonta una rama y monta otra, sin
   continuidad ni animacion de salida/entrada.

Si `showCompleted == false`, la card completada ni siquiera aparece como card:
la salida pending se percibe como desaparicion y compactacion de la lista.

## 10. Alternativas evaluadas

### 1. Retrasar callback de negocio hasta terminar animacion local

- Continuidad visual: alta para la card pendiente.
- Complejidad: baja-media.
- Impacto negocio: alto, porque retrasa recompensas, history y sync.
- Keys: sin cambios.
- Reorder: bajo impacto.
- Doble callback: requiere mantener guard mas tiempo.
- Callback async: facil, pero cambia semantica temporal.
- Tests: faciles.
- Reversion: facil.

No recomendado: cambia el momento productivo del commit.

### 2. Ejecutar negocio inmediatamente y mantener snapshot visual temporal

- Continuidad visual: alta si el snapshot ocupa/sale desde el lugar pending.
- Complejidad: media.
- Impacto negocio: bajo.
- Keys: no requiere cambiar keys reales.
- Reorder: controlable si el snapshot no es reorderable/interactivo.
- Doble callback: bajo, porque el snapshot no tiene callbacks.
- Callback async: bueno; la UI final ya refleja store.
- Tests: deterministas con estado temporal local.
- Reversion: buena.

Recomendado.

### 3. OverlayEntry o capa superpuesta animada

- Continuidad visual: alta para movimiento libre.
- Complejidad: alta por coordenadas globales, scroll y dispose.
- Impacto negocio: bajo.
- Keys: sin cambios.
- Reorder: no toca reorder, pero debe seguir scroll/viewport.
- Doble callback: bajo si `IgnorePointer`.
- Callback async: requiere limpieza robusta.
- Tests: mas dificiles.
- Reversion: media.

Puede ser util mas adelante, pero no es la primera opcion.

### 4. Placeholder temporal dentro de pendingHabits

- Continuidad visual: alta para evitar colapso inmediato de altura.
- Complejidad: media.
- Impacto negocio: bajo.
- Keys: requiere keys propias de placeholder, distintas.
- Reorder: riesgo si se mezcla con `SliverReorderableList`.
- Doble callback: bajo si no interactivo.
- Callback async: bueno con TTL/finally.
- Tests: buenos.
- Reversion: buena.

Recomendado como parte de la estrategia 2: placeholder/snapshot puramente visual.

### 5. AnimatedSize o AnimatedSwitcher local

- Continuidad visual: media.
- Complejidad: baja.
- Impacto negocio: bajo.
- Keys: bajo.
- Reorder: puede pelear con slivers/reorder.
- Doble callback: bajo.
- Callback async: bueno.
- Tests: faciles.
- Reversion: facil.

Insuficiente por si solo: anima altura, pero no preserva bien la card que se va.

### 6. AnimatedList o SliverAnimatedList

- Continuidad visual: alta.
- Complejidad: alta.
- Impacto negocio: bajo-medio por nueva capa de diff.
- Keys: importante.
- Reorder: alto riesgo con `SliverReorderableList`.
- Doble callback: controlable.
- Callback async: requiere cola de operaciones.
- Tests: mas amplios.
- Reversion: media-baja.

No recomendado para 5B por radio de cambio.

### 7. Animacion coordinada entre secciones

- Continuidad visual: potencialmente excelente.
- Complejidad: alta.
- Impacto negocio: bajo si es UI-only.
- Keys: complejo.
- Reorder: alto riesgo.
- Doble callback: controlable.
- Callback async: complejo con seccion completada plegada.
- Tests: amplios.
- Reversion: dificil.

Debe quedar para una fase posterior si la salida local no basta.

### 8. Combinacion de salida local mas placeholder

- Continuidad visual: alta en pending, media hacia completed.
- Complejidad: media.
- Impacto negocio: bajo.
- Keys: no cambia keys reales; usa key temporal propia.
- Reorder: controlable si el placeholder no es reorderable y no acepta drag.
- Doble callback: bajo.
- Callback async: bueno con limpieza por timer/finally/dispose.
- Tests: deterministas.
- Reversion: buena.

Recomendado para 5B como version inicial.

## 11. Tabla comparativa

| Alternativa | Continuidad | Complejidad | Negocio | Keys | Reorder | Async | Tests | Reversion |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Retrasar callback | Alta | Baja-media | Alto impacto | Sin cambios | Bajo | Cambia timing | Facil | Facil |
| Snapshot temporal | Alta | Media | Bajo | Sin cambiar reales | Medio-bajo | Bueno | Bueno | Buena |
| OverlayEntry | Alta | Alta | Bajo | Sin cambios | Medio | Requiere limpieza | Dificil | Media |
| Placeholder pending | Alta para altura | Media | Bajo | Key temporal | Medio | Bueno | Bueno | Buena |
| AnimatedSize/Switcher | Media | Baja | Bajo | Bajo | Medio | Bueno | Facil | Facil |
| SliverAnimatedList | Alta | Alta | Bajo-medio | Alto | Alto | Complejo | Medio | Media-baja |
| Coordinada secciones | Muy alta | Alta | Bajo | Alto | Alto | Complejo | Amplio | Dificil |
| Salida + placeholder | Alta | Media | Bajo | Key temporal | Medio-bajo | Bueno | Bueno | Buena |

## 12. Estrategia recomendada

Recomendacion: **ejecutar el callback productivo inmediatamente y crear una
transicion UI-only de salida en pending mediante snapshot/placeholder temporal
no interactivo**.

Respuestas obligatorias:

- El callback se ejecuta **antes** de la animacion de salida completa.
- Si, se mantiene una representacion visual temporal.
- El estado temporal vive en `_HomeScreenState` o en un controlador local UI de
  Home, no en `UserStateStore`.
- El propietario de la transicion debe ser `HomeHabitsSliver` coordinado por
  Home, porque ahi viven pending/completed/reorder.
- Las keys reales de las cards se conservan; el snapshot usa una key temporal
  propia, por ejemplo `habit_transition_out_$habitId`.
- Se evita segunda interaccion con `IgnorePointer`, sin callbacks y sin
  `ReorderableDelayedDragStartListener`.
- Si el callback falla, se limpia el snapshot por `finally`/timeout/dispose y el
  store conserva o recupera el estado real.
- Para no interferir con `SliverReorderableList`, el snapshot no debe formar
  parte de la lista reorderable activa o debe renderizarse como item visual
  separado no reorderable durante la salida.

## 13. Arquitectura UI propuesta

Fase 5B deberia introducir una pequena capa UI:

```text
_HomeScreenState
  Map<String, PendingCompletionTransition> _pendingCompletionTransitions

HabitCardSwipeShell.onSwipeRightComplete
  Home registra snapshot visual para habitId
  Home ejecuta setHabitCompletionForKey inmediatamente
  Home limpia transicion al completar animacion o al fallar/dispose

HomeHabitsSliver
  recibe transiciones pending visuales
  pinta placeholders no interactivos donde correspondan
  mantiene pending/completed reales desde buildHomeViewData
```

El snapshot minimo puede guardar:

- `habitId`;
- copia del `habit` antes del commit;
- timestamp/estado de animacion;
- altura aproximada o builder visual;
- flag `isCompletingOut`.

No debe guardar estado de negocio ni mutar el store.

## 14. Estado visual temporal necesario

Estado recomendado:

```text
PendingCompletionTransition
  habitId
  habitSnapshot
  startedAt
  phase: holding | exiting | done
```

Propiedades:

- puramente visual;
- no interactivo;
- no ejecuta callbacks;
- no participa en reorder;
- se elimina aunque el callback falle;
- se elimina en `dispose`;
- TTL defensivo para evitar placeholders permanentes.

## 15. Manejo de callback async

El callback debe ejecutarse inmediatamente para preservar semantica productiva.
La transicion visual no debe esperar a que la persistencia termine para empezar.

Flujo recomendado:

1. Registrar snapshot visual antes de llamar store.
2. Ejecutar `await setHabitCompletionForKey(...)`.
3. Si termina bien, dejar que la animacion visual complete su salida.
4. Si falla, limpiar snapshot y permitir que Home pinte el estado real actual.

No debe haber retry visual ni segundo commit desde el snapshot.

## 16. Manejo de error

Si `setHabitCompletionForKey` lanza:

- eliminar transicion temporal;
- no montar card duplicada;
- no reintentar automaticamente;
- dejar que el estado real del store determine la UI;
- opcionalmente, en fase posterior, mostrar feedback de error fuera del
  snapshot.

El documento no recomienda tocar rollback/store.

## 17. Manejo de dispose o cambio de pantalla

La transicion debe:

- cancelar timers/controllers en `dispose`;
- comprobar `mounted` antes de setState;
- no usar `OverlayEntry` global en 5B salvo que se agregue limpieza estricta;
- desaparecer al cambiar de fecha, salir de Home o reconstruir sin el habito.

Un `finally` en el callback no basta si la animacion sigue viva; se necesita
limpieza tambien desde ciclo de vida del widget propietario.

## 18. Tests necesarios

Tests recomendados para 5B:

- rightCommit registra una transicion visual local antes de mutar store.
- el callback productivo se ejecuta inmediatamente, no al final de la animacion.
- tras notify/rebuild, pending real ya no contiene el habito, pero el snapshot
  visual temporal sigue visible.
- el snapshot es `IgnorePointer` y no dispara callbacks.
- las keys reales `habit_pending_$id` y `habit_done_$id` no cambian.
- si completed esta plegado, el snapshot sale y solo queda el header.
- si completed esta expandido, no hay conflicto de keys con la card compacta.
- al fallar el callback, el snapshot se limpia.
- en `dispose`, timers/controllers de transicion se cancelan.
- reorder no se inicia desde el snapshot.
- scroll position no salta por colapso inmediato de altura mientras dura el
  placeholder.

## 19. Riesgos

- Medir altura exacta de una card pendiente puede requerir un enfoque simple
  inicial con altura natural del snapshot.
- Insertar placeholders dentro de una `SliverReorderableList` puede alterar
  indices; conviene mantenerlos fuera del reorder real o desactivar reorder para
  ese slot.
- Si hay completados plegados, no existe destino visual visible para una
  animacion entre secciones; la fase 5B debe centrarse en salida fluida, no en
  viaje completo.
- Si el usuario cambia de dia durante la transicion, el snapshot debe limpiarse.
- Si el callback falla despues de que el snapshot haya empezado a salir, la UI
  podria volver a mostrar la card pendiente real; debe aceptarse como reflejo
  del estado real.

## 20. Alcance concreto de la Fase 5B

Implementar solo una salida local reversible:

1. Crear estado UI temporal en Home para commits visuales pendientes.
2. Registrar snapshot antes de `setHabitCompletionForKey`.
3. Ejecutar el callback productivo inmediatamente.
4. Pintar un placeholder/snapshot no interactivo en la zona pending durante una
   salida corta.
5. Mantener keys reales actuales.
6. No tocar store, rewards, persistencia, sync, Supabase ni clasificacion.
7. No introducir `SliverAnimatedList`, `AnimatedList`, `Hero` ni paquetes.
8. Cubrir con tests focalizados de transicion, error, dispose y no interaccion.
