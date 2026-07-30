# Habit Card Swipe Motion - Phase 0 Audit

## 1. Resumen ejecutivo

La Habit Card principal de Rutio esta concentrada en `HabitCardWidget`, pero el comportamiento de swipe no vive dentro de esa card: se envuelve en Home mediante `_HomeSwipeActionTray`, una implementacion propia con `GestureDetector`, `_offset`, `AnimationController` y `AnimatedContainer`.

El contenido visual, los callbacks actuales y la logica de negocio pueden conservarse. La capa que conviene sustituir es la capa gestual/animacion de `_HomeSwipeActionTray`: ahi estan el seguimiento del dedo, los umbrales, la apertura del rail izquierdo, el completado por swipe derecho y la coordinacion con una unica card abierta.

No se encontraron implementaciones paralelas de Habit Cards productivas en Home, semanal, rutinas u otras vistas. Hay usos de `HabitCardWidget` para previews/test, pero no otro motor equivalente de swipe. La transicion brusca al completar viene de la actualizacion global del `UserStateStore`, el recalculo de `buildHomeViewData` y el movimiento inmediato de la card entre secciones `pendingHabits` y `completedHabits`, sin animacion explicita de insercion/salida.

## 2. Mapa de archivos y clases

| Archivo | Clase / funcion | Rol |
| --- | --- | --- |
| `lib/screens/home/widgets/habit/habit_card_widget.dart` | `HabitCardWidget`, `_HabitCardWidgetState` | Renderiza la superficie principal de la Habit Card, contenido, controles check/count y FX local de completado. |
| `lib/screens/home/ui/home_card_builders.dart` | `_HomeScreenCardBuilders._habitCard` | Adapta el mapa raw del habito a `HabitCardWidget` y conecta callbacks de Home/store. |
| `lib/screens/home/ui/home_card_builders.dart` | `_HomeSwipeActionTray`, `_HomeSwipeActionTrayState` | Motor actual de swipe izquierdo/derecho y rail de acciones. |
| `lib/screens/home/ui/home_card_builders.dart` | `_SwipeTrayActionButton` | Botones del rail izquierdo: Saltar, Editar, Eliminar. |
| `lib/screens/home/build/sections/home_habits_sliver.dart` | `HomeHabitsSliver` | Pinta secciones pendientes/completadas/saltadas con `SliverList` o `SliverReorderableList`. |
| `lib/screens/home/logic/home_selectors.dart` | `buildHomeViewData` | Deriva `pendingHabits`, `completedHabits`, `skippedHabits` desde estado e historial. |
| `lib/screens/home/state/home_state.dart` | `_revealedHomeSwipeHabitId`, `_applyHomeState` | Estado local de Home para saber que card tiene rail abierto. |
| `lib/stores/user_state_store.dart` | `setHabitCompletionForKey`, `setHabitSkipForKey`, `setCountHabitValueForDate` | API publica usada por Home. |
| `lib/stores/user_state_store_habits.dart` | `_setHabitCompletionForKey`, `_completeHabit`, `_setHabitSkipForKey` | Mutacion real de habitos, recompensas, historial, log y sync best-effort. |
| `lib/stores/user_state_store_core.dart` | `_saveStore` | Actualiza `_state`, emite `notifyListeners()` y persiste. |

## 3. Arbol simplificado de widgets

```text
HomeScreen
  _HomeScreenBuild.buildContent()
    context.watch<UserStateStore>()
    buildHomeViewData(root, _selectedDay)
    _HomeLoadedView
      Scaffold
        RefreshIndicator.adaptive
          CustomScrollView
            HomeScrollableContentSliver
              SliverPadding
                HomeHabitsSliver
                  SliverList / SliverReorderableList por seccion
                    GestureDetector long-press reorder wrapper
                      _HomeSwipeActionTray
                        Stack
                          right completion cue fijo
                          left action rail fijo
                          AnimatedContainer(transform: translateX(_offset))
                            GestureDetector(horizontal drag)
                              HabitCardWidget
                                Material/InkWell
                                  Container habitCardSurface
                                    Stack background/scrim/content/family stripe/burst
```

## 4. Motor de gestos actual

No usa `Dismissible`, `flutter_slidable`, `RawGestureDetector` ni `Dismissible`. Usa:

- `GestureDetector` con `onHorizontalDragStart`, `onHorizontalDragUpdate`, `onHorizontalDragEnd`.
- `double _offset` como offset horizontal local dentro de `_HomeSwipeActionTrayState`.
- `AnimationController` + `Tween<double>` + `Curves.easeOutCubic` para asentarse.
- `AnimatedContainer` de 220 ms que aplica `Matrix4.translationValues(_offset, 0, 0)`.

Constantes actuales:

| Constante | Valor | Uso |
| --- | ---: | --- |
| `_actionWidth` | `78` | Ancho de cada accion izquierda. |
| `_revealWidth` | `234` | `78 * 3`, ancho total del rail izquierdo. |
| `_openThresholdRatio` | `0.30` | Abre si offset izquierdo supera `70.2 px`. |
| `_rightVisualLimit` | `84` | Limite visual del swipe derecho. |
| `_rightCompleteThreshold` | `54` | Completa por distancia. |
| `_rightFlingMinOffset` | `26` | Distancia minima para completar por flick. |
| `_rightFlingVelocity` | `520 px/s` | Velocidad minima para completar por flick. |
| Fling izquierdo | `dx < -320 px/s` | Abre rail izquierdo. |

El movimiento es horizontal porque solo se cambia `dx` en `Matrix4.translationValues`. El conflicto horizontal/vertical se delega al gesture arena de Flutter: la card registra drag horizontal y el scroll padre `CustomScrollView` mantiene el vertical. No hay `GestureArenaTeam`, `RawGestureDetector` ni bloqueo manual del scroll.

Se puede invertir direccion dentro del mismo gesto en parte: si el offset esta negativo y llega `dx > 0`, la card cierra hacia `0`; si luego sigue hacia la derecha, entra en el tramo de completado. Si esta positivo y llega `dx < 0`, el calculo actual clampa a `0.0` y no cruza directamente al rail izquierdo hasta updates posteriores.

Si empieza un gesto durante una animacion activa, `_handleHorizontalStart` hace `_controller.stop()`, conserva el `_offset` actual y sigue desde ahi.

## 5. Flujo actual del swipe izquierdo

Las tres acciones se construyen en `_HomeSwipeActionTray.build`, dentro de un rail fijo alineado a la derecha:

1. `CupertinoIcons.forward_end_fill`, label `Saltar`/`Skip`, callback `onSkip`.
2. `CupertinoIcons.pencil`, label `Editar`/`Edit`, callback `onEdit`.
3. `CupertinoIcons.delete`, label `Eliminar`/`Delete`, callback `onDelete`, color destructivo.

El ancho es fijo: `78 px` por accion, `234 px` total. No se mide segun layout ni contenido.

El rail inferior no se traslada con la card: vive como `Positioned.fill` detras del foreground. Aparece/desaparece por reconstruccion condicional con `showTray = revealProgress > 0.001`; no escala. Los botones son interactivos en cuanto el rail esta en el arbol, incluso durante revelado parcial.

Al tocar una accion:

- Saltar y eliminar pasan por `_handleAction`, que llama `widget.onClose()` antes del callback.
- Editar llama `widget.onClose()` y luego `widget.onEdit`.
- Eliminar abre dialogo de confirmacion antes de mutar store.

## 6. Flujo actual del swipe derecho y completado

El swipe derecho solo esta habilitado para habitos check: `_habitCard` pasa `canSwipeRightComplete: !isCounting`.

Durante `onHorizontalDragUpdate` no se ejecuta logica de negocio. Solo se actualiza `_offset` local con `setState`.

En `onHorizontalDragEnd`:

1. Calcula `rightVelocity`.
2. Requiere `!_startedFromOpenTray`, `canSwipeRightComplete` y callback no nulo.
3. Completa si `_offset >= 54` o si `velocity >= 520 px/s` y `_offset >= 26`.
4. Llama `_animateTo(0)`.
5. Ejecuta `await widget.onSwipeRightComplete!.call()`.

El callback conectado en Home llama:

```dart
await context.read<UserStateStore>().setHabitCompletionForKey(
  habitId: id,
  dateKey: _dateKey(_selectedDay),
  done: !doneToday,
);
```

Para el dia actual, `_setHabitCompletionForKey` delega en `store.completeHabit(habitId: habitId)` cuando `done == true`. `_completeHabit` aplica progreso, historial, recompensas, logros, guardado y sync. Para check habits ya completados existe guard interno: `if (habit['doneToday'] == true) return;`.

Estado visual posterior: al guardarse el store, Home reconstruye. `buildHomeViewData` mueve el habito de `pendingHabits` a `completedHabits`; si la seccion completada esta colapsada, la card deja de ser visible. `HabitCardWidget.didUpdateWidget` dispara `_playCompleteFx()` cuando pasa de no completada a completada, pero si la card se desmonta/reaparece en otra seccion, esa continuidad puede perderse.

## 7. Tabla de callbacks actuales

| Accion | Firma | Propietario | Punto de ejecucion | Protecciones frente a duplicados |
| --- | --- | --- | --- | --- |
| Tap check circular | `VoidCallback? onCheckTap` en `HabitCardWidget` | `_HomeScreenCardBuilders._habitCard` | `HabitCardWidget`, tap en control check | Store decide estado con `done: !(doneToday && !skippedToday)`; check completado actual termina en guard `habit['doneToday'] == true` si intenta completar otra vez. |
| Swipe derecho completar | `Future<void> Function()? onSwipeRightComplete` | `_HomeSwipeActionTray` recibe callback desde `_habitCard` | `_handleHorizontalEnd`, tras superar umbral/flick | `_startedFromOpenTray` evita completar desde rail abierto; `_completeHabit` retorna si check ya esta done; transaccion de reward por fecha evita recompensa duplicada. No hay flag local anti doble mientras el `await` esta pendiente. |
| Saltar | `Future<void> Function() onSkip` | `_HomeSwipeActionTray` recibe callback desde `_habitCard` | `_SwipeTrayActionButton.onPressed` -> `_handleAction` | `setHabitSkipForKey` escribe estado idempotente por fecha; al saltar revoca recompensa si existia. No hay flag local anti doble tap en boton. |
| Editar | `VoidCallback? onEdit` | `_HomeSwipeActionTray` recibe `openHabitDetails(mode: editOnly)` | Boton Editar del rail | Cierra rail antes de navegar. No hay deduplicacion local de navegacion. |
| Eliminar | `Future<void> Function() onDelete` | `_HomeSwipeActionTray` recibe `_confirmAndDeleteHabitFromHome` | Boton Eliminar del rail -> dialogo confirmacion | Dialogo confirma antes de mutar. Eliminacion intenta varias APIs de store; sin lock local contra doble apertura/tap. |
| Incrementar count | `VoidCallback? onIncrement` | `HabitCardWidget` desde `_habitCard` | Boton `+` en card count | Solo para `isCounting`; store aplica guard de fecha esperada. |
| Decrementar count | `VoidCallback? onDecrement` | `HabitCardWidget` desde `_habitCard` | Boton `-` en card count | Clamp visual/llamada a `0`; store aplica guard de fecha esperada. |
| Editar valor count | `VoidCallback? onCountTap` | `HabitCardWidget` desde `_habitCard` | Tap en anillo de progreso | Dialogo devuelve valor; store aplica guard de fecha esperada. |
| Abrir detalles | `void Function(int initialTab)? onOpenDetails` / `VoidCallback? onTap` | `HabitCardWidget` | Tap en superficie/card | Si el rail esta abierto, `onTap` cierra rail en lugar de abrir detalles. |

## 8. Estado y reconstrucciones durante el drag

Durante `onHorizontalDragUpdate`, solo `_HomeSwipeActionTrayState.setState` cambia `_offset`. No se actualiza `UserStateStore`, provider, notifier global ni dominio.

Widgets reconstruidos por frame de drag:

- `_HomeSwipeActionTray.build`.
- Stack del rail/cue.
- `AnimatedContainer` que envuelve el child.
- El `child` ya construido se mantiene como referencia de widget, pero al reconstruir el padre Flutter vuelve a procesar esa rama; el coste real depende del subtree y reconciliacion.

Ademas, `AnimatedContainer` tiene duracion fija de 220 ms incluso durante drag, por lo que el foreground puede ir interpolando hacia cada nuevo offset en vez de quedar estrictamente pegado al dedo. Esto es un candidato claro a sensacion de retraso.

## 9. Funcionamiento actual de la transicion de lista

Home observa `UserStateStore` con `context.watch<UserStateStore>()`. `store.save()` asigna `_state`, normaliza/hidrata y llama `notifyListeners()` antes de persistir.

Tras completar:

1. `UserStateStore` muta `doneToday`, historial y recompensas.
2. `_saveStore` emite `notifyListeners()`.
3. `HomeScreen.buildContent` reconstruye y recalcula `buildHomeViewData`.
4. El habito sale de `pendingHabits` y entra en `completedHabits`.
5. `HomeHabitsSliver` pinta la nueva composicion con `SliverList`/`SliverReorderableList`.

No hay `AnimatedList`, `AnimatedSize` de secciones de habitos ni animacion de reparenting entre secciones. Las keys son distintas por seccion (`habit_pending_$id`, `habit_done_$id`, `habit_skipped_$id`), por lo que Flutter trata el item como salida de una lista y entrada en otra. Esa es la causa probable de desaparicion/salto al completar.

## 10. Implementaciones duplicadas o inconsistentes

- No se encontro una segunda Habit Card productiva para semanal, mensual, rutinas u otra vista.
- `HabitCardWidget` se reutiliza en tests y en preview de tienda (`shop_item_asset_preview.dart`), sin swipe.
- El swipe esta acoplado a Home y es privado (`_HomeSwipeActionTray`), por lo que no es reutilizable fuera de `home_screen.dart`.
- Hay dos rutas de completado desde UI: tap check y swipe derecho. Ambas terminan en `setHabitCompletionForKey`, pero el tap usa `done: !(doneToday && !skippedToday)` y el swipe usa `done: !doneToday`.
- El rail izquierdo depende de labels manuales en Home en vez de l10n generada.

## 11. Tests existentes y huecos de cobertura

Tests relevantes encontrados:

- `test/screens/home/habit_card_widget_interaction_test.dart`: taps de `HabitCardWidget`, callbacks separados, borde, tonos/scrim. No cubre swipe.
- `test/widgets/shop_equipped_cosmetics_ui_test.dart`: visuales de skins en `HabitCardWidget`. No cubre swipe.
- `test/screens/home/home_selectors_schedule_test.dart`: `buildHomeViewData`, secciones pending/completed/skipped y times-per-week. Cubre la clasificacion posterior a cambios de estado.
- `test/stores/user_state_store_schedule_guards_test.dart`: guards de mutacion por fecha esperada para completion/skip/count.
- Tests de store de recompensas/logros/cloud en `test/stores/...`: cubren partes de economia y persistencia, pero no el gesto.

Huecos:

- No hay widget test del rail izquierdo, orden/iconos/labels/callbacks.
- No hay test del swipe derecho por distancia/flick.
- No hay test de inversion de direccion dentro de un gesto.
- No hay test de una sola card abierta.
- No hay test de animacion/transicion al pasar de pending a completed.
- No hay test anti doble ejecucion del callback visual mientras un completado async sigue pendiente.

## 12. Problemas concretos detectados

1. `AnimatedContainer` se usa tambien durante drag, lo que puede impedir que la card permanezca estrictamente unida al dedo.
2. El swipe derecho aplica un `dragFactor` de `0.72` y luego `0.42`, por lo que el recorrido visual no equivale a la distancia del dedo.
3. La transicion de lista no esta animada: la card cambia de seccion por reconstruccion global.
4. Las keys cambian por seccion, lo que dificulta continuidad visual entre pending/completed/skipped.
5. `_HomeSwipeActionTray` mezcla gesto, thresholds, rail visual, callbacks y coordinacion con Home.
6. No hay lock local para impedir doble ejecucion de botones o completado si hay taps/gestos rapidos durante callbacks async.
7. El rail aparece por condicion `showTray`; durante aperturas minimas se inserta/desinserta en el arbol.
8. La coordinacion de card abierta vive en Home, correcto para UI, pero acoplada al builder privado.

## 13. Elementos que pueden conservarse

- `HabitCardWidget` como contenido visual principal.
- Los callbacks publicos actuales de la card y los callbacks conectados desde Home.
- Las tres acciones izquierdas, en el mismo orden, con mismos iconos, textos, colores y semantica.
- `buildHomeViewData` como clasificador funcional de secciones.
- `UserStateStore.setHabitCompletionForKey`, `setHabitSkipForKey` y rutas de store/reward/sync.
- `_revealedHomeSwipeHabitId` como concepto de estado UI, aunque conviene encapsular su manejo.

## 14. Elementos que conviene normalizar

- Extraer `_HomeSwipeActionTray` a un widget reusable de presentacion, por ejemplo `HabitCardSwipeShell`.
- Definir un modelo UI para acciones izquierdas que preserve los tres callbacks actuales.
- Separar controller gestual visual de callbacks de negocio.
- Centralizar thresholds en una configuracion local de UI, no en constantes privadas dispersas.
- Normalizar keys/transicion de seccion para permitir continuidad visual.
- Mantener un identificador de card abierta en una capa de UI/Home, no en dominio ni store.

## 15. Elementos que deberian sustituirse

- La capa gestual/animacion de `_HomeSwipeActionTrayState`.
- El uso de `AnimatedContainer` como mecanismo de movimiento durante drag.
- Los factores de drag que desacoplan dedo y card durante swipe derecho.
- La transicion inmediata pending -> completed sin animacion coordinada.

## 16. Propuesta de arquitectura adaptada al repositorio real

Crear una capa UI reusable alrededor de `HabitCardWidget`:

```text
HabitCardSwipeShell
  props:
    cardId
    isOpen
    leftActions: [skip, edit, delete]
    canSwipeRightComplete
    onRequestOpen(cardId)
    onRequestClose()
    onRightCommit()
    child

  internals:
    AnimationController / Simulation o animateWith
    ValueNotifier<double> o setState local para offset
    drag state local: idle, dragging, settling, committing
    callback guard local para commit/action in flight
```

Home seguiria siendo propietario del `openedCardId`, porque es estado de coordinacion visual. El dominio/store no debe conocerlo.

La lista deberia introducir una fase de transicion visual antes de dejar que la clasificacion final mueva el item, o una capa de animacion de cambio de seccion. Para Fase 1 basta encapsular el gesto sin cambiar comportamiento; la animacion de lista puede quedar como fase posterior.

## 17. Riesgos tecnicos

- Cambiar el gesto puede alterar callbacks de negocio si no se bloquea explicitamente que `onDragUpdate` ejecute logica.
- Si se modifica la clasificacion de lista junto con el gesto, aumenta el riesgo de duplicar recompensas o mover items dos veces.
- El completado actual hace trabajo async de store/rewards/sync; cualquier animacion de commit debe tolerar latencia.
- La card visual tiene FX propio de completado; al mejorar transicion de lista hay que coordinarlo para no duplicar efectos.
- `SliverReorderableList` y swipe horizontal pueden competir en gestos si se toca long-press/reorder.

## 18. Plan recomendado de implementacion por fases

Fase 1: Extraer y cubrir el shell actual sin cambiar comportamiento.

- Mover `_HomeSwipeActionTray` a un widget reusable en la capa de Home/widgets.
- Mantener constantes, acciones, callbacks y comportamiento actuales.
- Agregar widget tests de rail izquierdo, callbacks, una card abierta y completado por umbral/flick.

Fase 2: Sustituir internals gestuales.

- Reemplazar `AnimatedContainer` durante drag por transform controlado directamente.
- Mantener rail fijo y card pegada al dedo.
- Introducir estado `settling/committing` y guard anti doble ejecucion.
- Calibrar distancia/velocidad con constantes configurables.

Fase 3: Transicion de lista.

- Coordinar commit visual con el update de store.
- Evitar desmontaje brusco entre pending/completed, usando animacion local o capa de transicion de secciones.
- Revisar keys para preservar continuidad cuando sea viable.

Fase 4: Ajuste en dispositivo real.

- Calibrar umbrales de distancia/velocidad y sensacion de fisica firme.
- Validar conflicto scroll vertical/swipe horizontal y reorder.

## Decision final obligatoria

Decision recomendada: **B. Sustituir unicamente la capa gestual conservando contenido y callbacks.**

Justificacion: la card visual principal esta bien localizada y no hay duplicacion productiva que obligue a extraer una estructura comun antes de actuar. Los callbacks y el flujo de negocio ya terminan en rutas de store con protecciones importantes contra duplicados de completado/recompensa. El problema central esta en la capa gestual y de movimiento de `_HomeSwipeActionTray`: usa offset local, factores de drag, `AnimatedContainer` durante el gesto y una transicion de lista no coordinada. Por eso la siguiente fase debe preservar `HabitCardWidget`, acciones y callbacks, y sustituir primero el motor gestual visual.
