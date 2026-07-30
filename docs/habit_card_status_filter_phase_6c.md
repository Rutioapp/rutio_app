# Habit Card Status Filter - Phase 6C

## 1. Arquitectura anterior

Home renderizaba pendientes, completados y omitidos a la vez. Pendientes era la
lista principal; completados y omitidos vivian como secciones inferiores
desplegables controladas por `_showCompleted` y `_showSkipped`.

## 2. HomeHabitStatusFilter

Se introduce `HomeHabitStatusFilter` con tres valores UI-only:

- `pending`
- `completed`
- `skipped`

No existe `all` en esta fase.

## 3. Propietario del estado

El filtro seleccionado vive en `_HomeScreenState` como `_habitStatusFilter`.
El valor inicial es `HomeHabitStatusFilter.pending`. No se guarda en
`UserStateStore`, dominio, repositorios, Supabase ni `SharedPreferences`.

## 4. Lista unica

`HomeScrollableContentSliver` resuelve una sola coleccion visible mediante
`habitsForFilter(homeData, selectedFilter)` y `HomeHabitsSliver` renderiza solo
esa coleccion. No se usan `Offstage`, `Visibility`, `IndexedStack`, `Opacity` ni
listas ocultas para mantener las otras secciones montadas.

## 5. Fila de fecha

La correccion de composicion retira el header dinamico creado inicialmente en
6C. Ya no se renderiza ninguna fila con:

- `Pendientes · N`
- `Completados · N`
- `Omitidos/Saltados · N`

Home reutiliza la fila superior existente de fecha. La fecha permanece alineada
a la izquierda con el mismo estilo, padding y posicion vertical. El boton de tres
puntos ocupa el espacio derecho donde antes se mostraba visualmente
`Completados n/total`.

El resumen `Completados n/total` deja de renderizarse en esa posicion. Sus
calculos siguen existiendo en `HomeViewData` para otros usos y para los
contadores del menu.

## 6. Selector

El boton de la fila de fecha abre un menu compacto anclado al propio boton con
`showMenu`. Se descarta el bottom sheet porque oscurecia y separaba visualmente
Home para una decision muy pequena. El popup queda alineado junto al icono de
tres puntos, se cierra al tocar fuera y devuelve el filtro seleccionado al
cerrarse.

El menu muestra exactamente tres filas pulsables con contador: `Pendientes`,
`Completados` y `Saltados`. La opcion actual usa check y estado semantico
seleccionado.

## 7. Comportamiento por filtro

Pending renderiza `pendingHabits`, conserva `HabitCardSwipeShell`, right swipe,
rail izquierdo, feedback completed/skipped, snapshots, transiciones y
tombstones.

Completed renderiza `completedHabits` en `SliverList`, sin reorder. Las cards
siguen centradas, sin right commit ni offset positivo, y el check conserva el
callback actual de desmarcado.

Skipped renderiza `skippedHabits` en `SliverList`, sin reorder ni right commit.
El callback actual de recuperar el habito se mantiene por la accion de skip. En
UI visible el filtro skipped se presenta como `Saltados`.

## 8. Contadores

Los contadores siguen saliendo de `HomeViewData`: pending, completed y skipped.
El filtro no reclasifica habitos dentro del widget. Los contadores solo se
muestran dentro del menu de filtro.

## 9. Reorder

`SliverReorderableList` solo se usa cuando el filtro es `pending`, hay al menos
dos pendientes reales y no hay transiciones temporales activas. Completed y
skipped usan siempre `SliverList`.

## 10. Scroll

Home tiene un `ScrollController` local. Al cambiar de filtro se agenda un
post-frame y se vuelve al inicio si el controller esta montado y tiene clientes.
Tambien se clampa la posicion tras rebuilds para evitar offsets invalidos en
cambios de fecha o listas de distinta longitud.

## 11. Empty states

El selector permanece disponible en la fila de fecha. Los textos por filtro son:

- Pending: `No tienes hábitos pendientes.`
- Completed: `Aún no has completado hábitos hoy.`
- Skipped: `No has saltado hábitos hoy.`

Si no hay ningun habito esperado en el dia, se conserva la empty card global
debajo del bloque superior existente.

## 12. Cambio de fecha

El filtro seleccionado se conserva al cambiar de fecha. La nueva fecha actualiza
listas y contadores desde `buildHomeViewData`. La posicion de scroll se mantiene
en un rango valido.

## 13. Cambio de usuario o scope

Home compara `activeLocalScopeUserId`, `userId` y `scopeEpoch`. Cuando cambia la
identidad o el scope, resetea el filtro a `pending`, cierra rails y limpia estado
UI efimero mediante el lifecycle local existente.

## 14. Keys

Se conservan las keys reales por estado:

- `habit_pending_$id`
- `habit_done_$id`
- `habit_skipped_$id`

Tambien se conservan las keys temporales de transitions, feedback, foreground y
tombstones. El boton de filtro mantiene `homeHabitStatusFilterButton`.

## 15. Transiciones y tombstones

Las transiciones pending -> completed y pending -> skipped siguen siendo
autoridad de Home. Los snapshots se renderizan solo en pending. Al cambiar de
filtro se cierra cualquier rail y se marca como finalizada la parte visual de
transiciones activas sin borrar tombstones que aun esperan `pendingRemoved`.

## 16. Codigo antiguo obsoleto

Quedan temporalmente sin uso `_showCompleted`, `_showSkipped`,
`_completedHeader`, `_skippedHeader`, `_HomeSectionToggle` y
`HomeHabitStatusFilterHeader`. Estan documentados como obsoletos para retirada
posterior y no se renderizan en Home.

## 17. Accesibilidad

El boton anuncia `Cambiar filtro de hábitos`. Cada opcion del menu anuncia
`Pendientes, N hábitos`, `Completados, N hábitos` o `Saltados, N hábitos`, y la
opcion actual se marca como seleccionada. La seleccion no depende solo del color.

## 18. Tests

Se anaden o actualizan tests para:

- enum sin `all`;
- `habitsForFilter`;
- fila de fecha con boton de tres puntos;
- ausencia del resumen visual `Completados n/total`;
- ausencia del header dinamico `Filtro · N`;
- boton de tres puntos y semantica;
- selector anclado con tres opciones y sin `Todos`;
- cierre del selector por seleccion y por toque exterior;
- lista unica por filtro;
- reorder solo en pending;
- snapshots/tombstones solo en pending;
- empty states por filtro.

## 19. Limitaciones

No se implementan filtro `Todos`, persistencia, posiciones de scroll por filtro,
PageView, tabs, retorno animado desde completed/skipped, Hero, overlays globales
ni cambios de store, negocio, recompensas, sync o Supabase.

## 20. Preparacion para 6D

La siguiente fase puede retirar definitivamente los flags y builders obsoletos,
anadir tests integrados especificos de cambio de filtro sobre `HomeScreen`
completo y, si se aprueba, disenar transiciones suaves de retorno a pending sin
reutilizar la animacion horizontal de completion.
