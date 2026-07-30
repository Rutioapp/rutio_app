# Habit Card Status Filter - Phase 6A Audit

## 1. Resumen ejecutivo

La Home actual ya tiene los datos necesarios para una lista filtrada sin tocar
`UserStateStore`: `buildHomeViewData` produce `viewHabits`, `pendingHabits`,
`completedHabits` y `skippedHabits` desde el estado raw y la fecha seleccionada.
El cambio futuro debe ser una reestructuracion de presentacion: sustituir los
bloques verticales de pending/completed/skipped por una lista visible controlada
por un filtro UI local.

Decision recomendada: **B. Lista unica filtrada**.

El filtro debe vivir en `_HomeScreenState` como estado de presentacion, no
persistido inicialmente. La primera version deberia mostrar `pending` por defecto
y permitir `pending`, `completed` y `skipped`. El filtro `all` no se recomienda
en la primera implementacion: aporta valor exploratorio, pero complica orden,
acciones por estado, transiciones y expectativas de reorder.

## 2. Estructura actual de Home

`HomeScreen.buildContent` obtiene `UserStateStore` con `context.watch`, calcula
`HomeViewData` mediante `buildHomeViewData(root, _selectedDay)` y construye
`_HomeLoadedView`.

La lista vive en:

- `HomeScrollableContentSliver`: aplica padding y decide empty state vs lista.
- `HomeHabitsSliver`: pinta pending, completed y skipped dentro de un
  `SliverMainAxisGroup`.

Pending se pinta siempre primero. Completed y skipped se pintan despues como
secciones inferiores con header y contenido plegable.

Si `viewHabits` esta vacio, se muestra `HomeEmptyStateCard`. Si una seccion
concreta esta vacia, su header/contenido no se pinta, salvo pending que puede
ser una lista vacia si existen completed/skipped.

## 3. Arbol simplificado de widgets

```text
HomeScreen
  _HomeScreenState
    _HomeScreenBuild.buildContent()
      buildHomeViewData(root, _selectedDay)
      _HomeLoadedView
        Scaffold
          Stack
            HomeBackground
            SafeArea
              Column
                _HomeHeroTopArea / AppHeader
                _weekStrip
                _dayProgressMini
                RefreshIndicator.adaptive
                  CustomScrollView
                    HomeScrollableContentSliver
                      SliverPadding
                        HomeHabitsSliver
                          SliverMainAxisGroup
                            pending SliverList/SliverReorderableList
                            completed header SliverToBoxAdapter
                            completed SliverList/SliverReorderableList when expanded
                            skipped header SliverToBoxAdapter
                            skipped SliverList/SliverReorderableList when expanded
```

Cada card real se construye por `habitCardBuilder`, que llama a
`_HomeScreenCardBuilders._habitCard`, crea `HabitCardWidget` y lo envuelve en
`HabitCardSwipeShell`.

## 4. Clasificacion actual de habitos

La clasificacion vive en `lib/screens/home/logic/home_selectors.dart`.

`buildHomeViewData`:

- lee `activeHabits`;
- excluye archivados;
- filtra habitos esperados para `_selectedDay` con `isHabitExpectedForDate`;
- aplica snapshot de fecha seleccionada desde history;
- calcula informacion especial de `timesPerWeek`;
- devuelve `viewHabits`, `pendingHabits`, `completedHabits` y `skippedHabits`.

Reglas actuales:

- `pendingHabits`: no done, no skipped; para `timesPerWeek`, no skipped, no done
  hoy y target semanal no cumplido.
- `completedHabits`: `doneToday == true`; para `timesPerWeek`, done hoy o target
  semanal cumplido.
- `skippedHabits`: `skippedToday == true`; para `timesPerWeek`, skipped solo si
  no esta done hoy y no cumplio target semanal.

La clasificacion depende de la fecha. El orden de cada lista conserva el orden
de `viewHabits`, que deriva de `activeHabits`. En las reglas actuales normales,
un habito no deberia aparecer en mas de un grupo visible; en `timesPerWeek`, las
condiciones evitan skipped cuando ya esta completed por target.

Conclusion: `HomeViewData` ya proporciona suficiente informacion para una lista
filtrada sin cambiar store ni repositorios.

## 5. Estado de presentacion actual

Estado UI relevante en `_HomeScreenState`:

- `_selectedDay` y `_lastToday`;
- `_showCompleted`;
- `_showSkipped`;
- `_revealedHomeSwipeHabitId`;
- `_habitCompletionTransitions`;
- `_habitCompletionTransitionSequence`;
- `_countControllers`;
- controladores y flags de prompts/notificaciones;
- `_didSyncViewDate`.

Estado local dentro de `HomeHabitsSliver`:

- `_preparedHabitId`;
- `_draggingHabitId`;
- `_didFireDragHaptic`.

Estado local dentro de `HabitCardSwipeShell`:

- offset horizontal;
- ancho de card;
- generacion de settling;
- `HabitCardSwipeVisualState`;
- inicio desde rail abierto.

`HomeHabitStatusFilter` debe vivir en `_HomeScreenState`, junto a
`_showCompleted`, `_showSkipped` y `_revealedHomeSwipeHabitId`. Debe ser UI-only,
no persistido inicialmente y normalizable al cambiar fecha/scope si el filtro
actual queda vacio o si se decide volver a pending.

## 6. Secciones y headers actuales

Pending no tiene header propio dentro de `HomeHabitsSliver`; el contexto general
lo da `_dayProgressMini`, que muestra fecha y contador `done/total`.

Completed usa `_completedHeader`, definido en `home_header_builders.dart`, con
`_HomeSectionToggle`, icono `check_mark_circled_solid`, contador
`homeCompletedCount` y chevron expand/collapse.

Skipped usa `_skippedHeader`, definido en `home_state.dart`, tambien con
`_HomeSectionToggle`, icono `forward_end_alt_fill`, contador
`homeSkippedCount` y chevron. Si no hay items, su onTap queda inerte, aunque el
header solo se monta cuando hay skipped.

Los contadores visibles actuales:

- `_dayProgressMini`: done/total del dia;
- completed header: numero de completados;
- skipped header: numero de omitidos.

## 7. Funcionamiento de expand/collapse

`_showCompleted` y `_showSkipped` controlan si se monta el contenido de sus
secciones. Los headers se muestran si la lista correspondiente no esta vacia.

Expand/collapse no toca `UserStateStore`, no cambia orden y no altera
clasificacion. Es estado puramente local. En una lista filtrada, estos flags
quedarian obsoletos porque solo habria una coleccion visible.

## 8. Integracion actual con SliverReorderableList

`HomeHabitsSliver._buildHabitSection` usa `SliverReorderableList` cuando una
seccion visible tiene 2 o mas items. Si hay menos de 2, usa `SliverList`.

Hoy reorder puede aplicarse a pending, completed y skipped porque se pasan:

- `onPendingReorder`;
- `onCompletedReorder`;
- `onSkippedReorder`.

Todos llaman a `_reorderHabitSection`, que recibe `sectionHabits` y `viewHabits`.
El algoritmo reordena solo los ids de la seccion y los reinserta dentro del orden
global de `viewHabits`, luego llama a `reorderVisibleHabits`.

Para la arquitectura futura, reorder deberia usarse solo cuando
`filter == pending` y no existan snapshots temporales activos. Completed y
skipped deben usar `SliverList`.

## 9. Estrategia actual de keys

Keys reales actuales:

- pending: `ValueKey('habit_pending_$id')`;
- completed: `ValueKey('habit_done_$id')`;
- skipped: `ValueKey('habit_skipped_$id')`.

`HabitCardSwipeShell` no tiene key propia explicita; se identifica por posicion
bajo la fila. `HabitCardWidget` tampoco tiene key de habit propia; su superficie
interna usa `Key('habitCardSurface')`.

Snapshots/tombstones de completion usan:

```text
habit_completion_transition_${transitionId}_$habitId
```

El cue derecho verde del shell tiene key `habitCardRightCommitCue`.

Recomendacion: conservar las keys reales por estado en la primera migracion.
Reducen riesgo y evitan conflictos si durante transiciones hay una
representacion real y una temporal del mismo habitId. Normalizarlas puede quedar
para una fase posterior si la lista unica estabiliza el modelo.

## 10. Scroll y viewport

La Home usa un `CustomScrollView` sin `ScrollController` explicito. El cambio de
filtro compartiria de entrada el mismo scroll position del `CustomScrollView`.

Riesgos:

- pasar de una lista larga a una corta puede dejar una posicion demasiado abajo;
- una transicion activa podria terminar fuera de viewport;
- filtros vacios pueden parecer pantalla rota si no hay empty state contextual.

Politica inicial recomendada: al cambiar filtro, cerrar rail abierto,
cancelar/prevenir reorder activo y volver al inicio de la lista. Para hacerlo de
forma controlada en 6C probablemente convenga introducir un `ScrollController`
local de Home o una key/notification coordinada por el sliver. No se recomienda
conservar posiciones independientes por filtro en la primera version.

## 11. Tests existentes

Tests relevantes actuales:

- `home_selectors_schedule_test.dart`: cubre `isHabitExpectedForDate`,
  `buildHomeViewData`, pending/completed/skipped, snapshots por fecha y
  `timesPerWeek`.
- `habit_card_swipe_shell_test.dart`: cubre geometria, thresholds, rails,
  callbacks, guards, rightCommit y ausencia de offset derecho cuando no aplica.
- `habit_card_widget_interaction_test.dart`: cubre taps, check/count, guard de
  check, tonos visuales y que uncomplete no desplaza dentro del shell.
- `habit_completion_transition_test.dart`: cubre snapshot 5B, tombstone,
  reorder deshabilitado durante snapshot y continuidad horizontal.
- `home_screen_refresh_test.dart`: cubre Home con providers, refresh, lifecycle y
  cosmeticos.

No hay todavia tests de filtro de estado, menu de tres puntos ni lista unica.

## 12. Problemas UX actuales

- Completed y skipped quedan como bloques inferiores que compiten con la lista
  principal.
- El usuario debe expandir secciones para revisar estados secundarios.
- No hay header unico de "vista actual" con contador y accion de filtro.
- Reorder existe tecnicamente en completed/skipped, aunque conceptualmente el
  orden que conviene preservar es el de pendientes reales.
- Las transiciones entre estados estan repartidas entre secciones, lo que
  complica continuidad visual.

## 13. Alternativas evaluadas

### Opcion A: mantener secciones y anadir menu que expanda/oculte

- UX: mejora baja; conserva complejidad visual.
- Swipe: bajo riesgo.
- Reorder: conserva ambiguedad en completed/skipped.
- Scroll: sin grandes cambios.
- Transiciones: sigue cruzando secciones.
- Accesibilidad: mas estados expand/collapse que anunciar.
- Reversion: facil.

### Opcion B: lista unica filtrada

- UX: clara; una lista visible y un estado seleccionado.
- Swipe: compatible si cada card recibe capacidades segun estado.
- Reorder: simple si se limita a `pending`.
- Scroll: requiere politica al cambiar filtro.
- Transiciones: mas controlables dentro de una lista visible.
- Accesibilidad: menu con opciones y contadores es anunciable.
- Riesgo: medio, pero acotable por fases.
- Reversion: buena si se mantiene codigo antiguo temporalmente.

### Opcion C: PageView o swipe horizontal entre estados

- UX: descubribilidad media; compite con swipe horizontal de cards.
- Swipe: alto conflicto conceptual y gestual.
- Reorder: mas complejo por paginas.
- Scroll: posiciones por pagina posibles pero costosas.
- Accesibilidad: requiere tabs/pages bien anunciadas.
- Riesgo: alto.

### Opcion D: mantener todas las listas montadas y cambiar visibilidad

- UX: similar a filtro.
- Rendimiento: peor en listas largas.
- Reorder: riesgo por listas ocultas montadas.
- Transiciones: puede evitar reconstrucciones, pero aumenta duplicados y estado
  oculto.
- Accesibilidad: riesgo de contenido oculto mal excluido de semantics.
- Riesgo: medio-alto.

Decision: **Opcion B**.

## 14. Decision arquitectonica recomendada

Implementar una lista unica cuyo contenido dependa de
`HomeHabitStatusFilter`. El filtro vive en `_HomeScreenState` y se pasa a
`HomeScrollableContentSliver`/`HomeHabitsSliver`.

Mantener temporalmente builders y flags antiguos durante la migracion para
reducir riesgo, pero renderizar por la nueva ruta cuando el filtro exista.

## 15. Contrato propuesto de HomeHabitStatusFilter

```dart
enum HomeHabitStatusFilter {
  pending,
  completed,
  skipped,
  all,
}
```

Primera version: implementar enum con `all` opcionalmente reservado, pero no
exponer `all` en UI hasta validar. Si se prefiere minimo absoluto, omitir `all`
del enum inicial y anadirlo luego.

Propiedades derivadas recomendadas:

- label localizado;
- contador;
- lista visible;
- empty state label;
- `canReorder`;
- `allowsRightCommit`.

## 16. Comportamiento propuesto de cada filtro

### Pending

- Muestra `homeData.pendingHabits`.
- Swipe derecho habilitado para checks no completados.
- Acciones izquierdas actuales: skip, edit, delete.
- Reorder habilitado si hay 2 o mas items y no hay transiciones activas.
- Usa snapshots 5B para `pending -> completed`.

### Completed

- Muestra `homeData.completedHabits`.
- Swipe derecho deshabilitado.
- Check ejecuta uncomplete.
- No reorder.
- Acciones izquierdas deben revisarse: skip desde completed podria existir por
  API actual, pero no debe confundirse con rightCommit. Recomendacion inicial:
  conservar rail izquierdo solo si el flujo actual ya es seguro; si no, limitar
  acciones a edit/delete en una fase posterior.

### Skipped

- Muestra `homeData.skippedHabits`.
- Swipe derecho deshabilitado.
- Recuperar omitido debe pasar por `setHabitSkipForKey(... skipped: false)` a
  traves de accion explicita o check/CTA futuro.
- No reorder.
- No reutilizar visual de completion.

### All

No recomendado en primera implementacion. Si se implementa despues, debe
preservar orden de `viewHabits` y resolver capacidades por estado de cada card.
Riesgos: mezcla estados, reorder parcial ambiguo, contadores menos claros y
transiciones con destino visible/invisible mas dificiles de explicar.

## 17. Recomendacion sobre el filtro Todos

No incluir `Todos` en 6C/primera version. Reservarlo como mejora posterior solo
si usuarios necesitan revision global. El valor por defecto debe ser
`pending`.

## 18. Contrato del boton de tres puntos y selector

Header futuro:

- titulo del filtro actual: Pendientes, Completados u Omitidos;
- contador visible, por ejemplo `3` o `3/8` si conviene;
- boton de tres puntos de 44x44 minimo;
- semantic label claro: "Filtrar habitos";
- estado seleccionado anunciado;
- opciones con contador: "Pendientes, 4", "Completados, 2", "Omitidos, 1";
- no depender de swipe horizontal para cambiar filtros.

Patron UI recomendado: bottom sheet o modal popup estilo iOS, similar a patrones
existentes de Home/add habit/emoji picker. No implementar como PageView.

## 19. Arquitectura de una unica lista

Propuesta:

```text
HomeScreen state
  HomeHabitStatusFilter _habitStatusFilter

buildContent
  homeData
  visibleHabits = selectVisibleHabits(homeData, _habitStatusFilter)

HomeScrollableContentSliver
  filter
  filteredHabits
  counts

HomeHabitsSliver
  render one section
    if filter == pending && canReorder -> SliverReorderableList
    else -> SliverList
```

El selector filtrado puede vivir como helper puro cerca de `home_selectors.dart`
o como funcion privada de build UI. No debe mutar `HomeViewData`.

## 20. Integracion con reorder

Usar `SliverReorderableList` solo cuando:

- `filter == pending`;
- `visibleHabits.length >= 2`;
- no hay transiciones temporales activas;
- no hay reorder activo.

`onReorder` debe recibir `homeData.pendingHabits` y `homeData.viewHabits`, como
hoy. Completed/skipped deben ser `SliverList`, no reorderables.

Snapshots temporales siguen fuera del reorder. Si hay snapshot de completion,
pending usa ruta visual no reorderable como en 5B.

## 21. Politica de scroll al cambiar de filtro

Politica inicial recomendada:

- cerrar cualquier rail abierto;
- cancelar estado preparado/dragging si existe;
- limpiar o dejar terminar transiciones visibles segun tipo;
- volver al inicio del `CustomScrollView`;
- no conservar posicion por filtro.

Esta politica es simple, predecible y evita posiciones invalidas al pasar de una
lista larga a una corta.

## 22. Integracion con transiciones 5B existentes

`HomeHabitCompletionTransition` sigue aplicando solo a `pending -> completed`.
En filtro pending, el snapshot permanece en la lista visible aunque el store ya
haya movido el habito a completed. En filtro completed, no debe mostrarse ese
snapshot: el destino real puede aparecer despues si el usuario esta viendo
completed, pero no debe duplicarse con la transicion pending.

Si se cambia de filtro durante una transicion, recomendacion inicial: limpiar
transiciones o dejar que terminen sin render si ya no pertenecen al filtro
visible. Debe evitarse que un tombstone suprima una card real fuera de pending.

## 23. Futuro estado verde con tick

El estado verde de completado debe integrarse en el snapshot de
`HomeHabitCompletionTransition`:

1. rightCommit confirma y entrega `HabitCardRightCommitVisualState`;
2. Home registra snapshot;
3. callback productivo se ejecuta inmediatamente;
4. el snapshot mantiene posicion/altura;
5. durante un breve holding state, la card muestra fondo verde y tick;
6. luego empieza salida horizontal y colapso vertical;
7. cleanup sigue siendo `visualAnimationCompleted && pendingRemoved`.

Modelo temporal futuro:

- phase: `holdingFeedback`, `exiting`, `collapsed`;
- feedbackKind: `completed`;
- holdDuration aproximada: 180-260 ms;
- color verde diferenciado del family stripe;
- contenido original puede atenuarse u ocultarse para que el tick sea claro.

No debe tocar rewards, store ni sync.

## 24. Futuro feedback visual de skip

Skip necesita feedback equivalente pero no verde:

- feedbackKind: `skipped`;
- color diferenciado, por ejemplo gris/amber suave;
- icono distinto, por ejemplo `forward_end_alt_fill`;
- no usar check ni lenguaje visual de completado;
- callback productivo inmediato con `setHabitSkipForKey`;
- snapshot/tombstone UI-only si el item sale de pending.

Puede reutilizar infraestructura conceptual de transicion, pero conviene evitar
mezclar nombres de completion si el modelo se vuelve confuso. Una abstraccion
futura podria llamarse `HomeHabitStatusTransition`.

## 25. Estrategia futura completed -> pending

Primera mejora: mantener la correccion 5B.3. Al desmarcar completed:

- no rightCommit;
- no offset positivo;
- no cue verde;
- callback inmediato;
- card centrada hasta que el store la retire de completed.

Si el salto vertical sigue siendo brusco, anadir transicion UI-only minima:
`FadeTransition`/`SizeTransition`, sin desplazamiento horizontal, con
`IgnorePointer` y key temporal propia. No reutilizar
`HomeHabitCompletionTransition` si eso mezcla sentidos.

## 26. Estrategia futura skipped -> pending

Debe comportarse como recuperacion, no como completion:

- accion explicita para "recuperar" o check/CTA definido;
- callback inmediato `setHabitSkipForKey(... skipped: false)`;
- feedback local diferenciado;
- si el filtro activo es skipped, salida con fade/size sin movimiento
  horizontal;
- si el filtro activo es pending, puede aparecer como entrada simple posterior;
- errores dejan una unica card skipped centrada.

## 27. Codigo que quedaria obsoleto

Potencialmente obsoleto tras 6D/6F:

- `_showCompleted`;
- `_showSkipped`;
- `_completedHeader`;
- `_skippedHeader`;
- `_HomeSectionToggle`;
- `completedHeaderBuilder`;
- `skippedHeaderBuilder`;
- `showCompleted`;
- `showSkipped`;
- rutas de `onCompletedReorder` y `onSkippedReorder`;
- tests que esperan headers desplegables o reorder en secciones no pending.

Debe mantenerse temporalmente durante la migracion para comparar comportamiento
y facilitar reversion.

## 28. Riesgos

- Reorder accidental de completed/skipped si se reutiliza `_buildHabitSection`
  sin filtrar.
- Duplicados visuales si snapshots se muestran fuera del filtro correcto.
- Scroll raro al cambiar de filtro sin volver al inicio.
- Filtro `all` mezclando acciones por estado y expectativas de reorder.
- Empty states por filtro no definidos.
- Accesibilidad del menu si el boton de tres puntos no anuncia contador/estado.
- Transiciones antiguas 5B suprimiendo pending cuando el usuario cambio de
  filtro.

## 29. Matriz de pruebas futura

| Area | Mantener | Actualizar | Anadir |
| --- | --- | --- | --- |
| Selectores | `home_selectors_schedule_test` | No deberia cambiar | Selector visible por filtro |
| Swipe | `habit_card_swipe_shell_test` | Capacidades por filtro | rightCommit solo pending |
| Card | `habit_card_widget_interaction_test` | Uncomplete/skip feedback | semantics de feedback |
| Transicion 5B | `habit_completion_transition_test` | Integrar feedback verde | hold verde antes de collapse |
| Sliver/reorder | Test actual de reorder durante snapshot | Solo pending reorderable | completed/skipped usan SliverList |
| Header/menu | No existe | N/A | boton tres puntos, opciones, contadores |
| Scroll | No existe | N/A | cambio de filtro vuelve arriba |
| Empty state | Home empty global | Diferenciar empty por filtro | pending/completed/skipped vacios |
| Accesibilidad | Parcial | Labels actuales | menu, selected filter, feedback |

## 30. Plan recomendado por fases

### 6B. Estado verde de completado y feedback de skip

Antes de cambiar la lista, estabilizar feedback local de cambios de estado:
completion verde con tick sobre snapshot 5B y feedback skip diferenciado. Esto
reduce variables antes de cambiar estructura.

### 6C. Filtro y lista unica sin eliminar codigo antiguo

Introducir `HomeHabitStatusFilter` en `_HomeScreenState`, selector visible,
header provisional y ruta de render de una sola lista. Mantener codigo antiguo
en paralelo o facilmente reversible.

### 6D. Menu de tres puntos y eliminacion de secciones desplegables

Implementar selector UI con contadores, retirar `_showCompleted/_showSkipped` y
builders de headers cuando la ruta filtrada sea estable.

### 6E. Transiciones completed/skipped -> pending

Anadir transiciones suaves no horizontales para recuperaciones y uncomplete si
el salto vertical restante lo justifica.

### 6F. Accesibilidad, calibracion y limpieza final

Pulir semantics, empty states, scroll, tests de regresion y eliminar codigo
obsoleto.

## Decision final obligatoria

- Opcion seleccionada: **B. Lista unica filtrada**.
- `HomeHabitStatusFilter` vive en `_HomeScreenState`.
- `Todos` no se incluye en la primera version.
- Filtro por defecto: `pending`.
- Al cambiar fecha: conservar `pending` como politica inicial; si se decide
  conservar filtro, normalizar a `pending` cuando el filtro quede vacio de forma
  confusa.
- Al cambiar filtro: cerrar rails y volver al inicio del scroll.
- `SliverReorderableList` se usa solo en `filter == pending`, con 2 o mas
  pending reales y sin transiciones activas.
- Keys conservadas: `habit_pending_$id`, `habit_done_$id`,
  `habit_skipped_$id`, y keys temporales de snapshots.
- Builders a eliminar posteriormente: completed/skipped headers, toggles,
  expanded flags y reorder callbacks de secciones no pending.
- Estado verde: se integra en `HomeHabitCompletionTransition` como fase previa
  al colapso.
- Feedback skip: transicion UI-only diferenciada por color/icono, no check verde.
- Primero implementar 6B para estabilizar feedback antes de cambiar la
  arquitectura de lista.
