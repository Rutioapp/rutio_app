# Habit Card Swipe Motion - Phase 1

## Estructura anterior

Antes de esta fase, Home concentraba dos responsabilidades en
`lib/screens/home/ui/home_card_builders.dart`:

- convertir el mapa raw del habito en `HabitCardWidget`;
- envolver esa card en `_HomeSwipeActionTray`, el motor privado de swipe.

`_HomeSwipeActionTray` contenia a la vez el rail izquierdo, el gesto horizontal,
los offsets, los thresholds, la animacion de settling, el cue de completado
derecho y la coordinacion con la card abierta en Home.

## Estructura resultante

La composicion queda separada asi:

```text
HomeScreen
  _revealedHomeSwipeHabitId sigue viviendo en UI/Home
  _HomeScreenCardBuilders._habitCard()
    crea HabitCardWidget
    crea HabitCardSwipeShell
      recibe cardId, child, estado open y callbacks
      conserva gesto y rail actuales
```

Nuevo archivo:

- `lib/screens/home/widgets/habit/habit_card_swipe_shell.dart`

Home importa ese shell y ya no declara la clase privada `_HomeSwipeActionTray`.

## Responsabilidades del nuevo shell

`HabitCardSwipeShell` es un componente de presentacion. Sus responsabilidades son:

- pintar el rail izquierdo fijo con las tres acciones actuales;
- envolver un `child`, normalmente `HabitCardWidget`;
- mantener el offset horizontal local durante el gesto;
- conservar `GestureDetector`, `AnimationController` y `AnimatedContainer`;
- solicitar a Home apertura, cierre o cierre de otras cards;
- ejecutar el callback de completado derecho solo al finalizar el gesto actual.

No conoce `Habit`, `UserStateStore`, economia, XP, Supabase, logs ni sync.

## Contrato de propiedades

| Propiedad | Rol |
| --- | --- |
| `cardId` | Identificador estable de la card para coordinar apertura en Home. |
| `child` | Contenido visual de la card. |
| `isOpen` | Estado externo de apertura, propiedad de Home. |
| `compact` | Mantiene radios/insets compactos actuales. |
| `canSwipeRightComplete` | Habilita o no completado derecho. |
| `skipLabel`, `editLabel`, `deleteLabel` | Textos actuales del rail. |
| `onRequestCloseOtherCards(cardId)` | Pide a Home cerrar otra card abierta al iniciar drag. |
| `onRequestOpen(cardId)` | Pide a Home marcar esta card como abierta. |
| `onRequestClose()` | Pide a Home limpiar/cerrar la card abierta. |
| `onSwipeRightComplete()` | Callback productivo actual de completado derecho. |
| `onSkip()` | Callback productivo actual de saltar. |
| `onEdit()` | Callback productivo actual de editar. |
| `onDelete()` | Callback productivo actual de eliminar. |

## Callbacks preservados

Home sigue conectando los mismos callbacks:

- Swipe derecho: `UserStateStore.setHabitCompletionForKey(...)`.
- Tap check interno de `HabitCardWidget`: `UserStateStore.setHabitCompletionForKey(...)`.
- Saltar: `UserStateStore.setHabitSkipForKey(...)`.
- Editar: `openHabitDetails(mode: HabitDetailScreenMode.editOnly)`.
- Eliminar: `_confirmAndDeleteHabitFromHome(...)`.
- Count habits: increment/decrement/count dialog siguen dentro de `HabitCardWidget`.

## Comportamiento deliberadamente no modificado

Esta fase no cambia la fisica visible ni los parametros existentes:

- `GestureDetector` sigue siendo el recognizer.
- `_offset` sigue siendo estado local del shell.
- `AnimationController` mantiene `220 ms`.
- `AnimatedContainer` sigue aplicando `Matrix4.translationValues`.
- El rail mantiene `78 px` por accion y `234 px` total.
- `_openThresholdRatio` sigue en `0.30`.
- `_rightVisualLimit` sigue en `84`.
- `_rightCompleteThreshold` sigue en `54`.
- `_rightFlingMinOffset` sigue en `26`.
- `_rightFlingVelocity` sigue en `520`.
- El dragFactor derecho sigue siendo `0.72` y `0.42`.
- Las keys de pending/completed/skipped no cambian.
- No se introduce `AnimatedList`, `AnimatedSize`, `Hero` ni nueva transicion.
- No se toca `SliverReorderableList`.

## Tests añadidos

Nuevo test:

- `test/screens/home/habit_card_swipe_shell_test.dart`

Cobertura:

- render de las tres acciones izquierdas en orden;
- una ejecucion de callback por pulsacion;
- apertura con `cardId` correcto;
- cierre de la card abierta;
- rail visible cuando `isOpen == true`;
- callback actual de completado por swipe derecho;
- child unico preservado;
- labels e iconos actuales preservados.

## Riesgos pendientes para Fase 2

- `AnimatedContainer` durante drag puede seguir generando retraso respecto al dedo.
- El swipe derecho mantiene dragFactor no lineal.
- No existe aun lock local anti doble callback async.
- La card sigue saltando entre secciones al completar porque la lista no tiene transicion coordinada.
- La interaccion entre swipe horizontal y `SliverReorderableList` debe validarse en dispositivo.

## Propuesta de Fase 2

Sustituir los internals gestuales de `HabitCardSwipeShell` sin tocar contenido ni negocio:

1. Separar estado `idle`, `dragging`, `settling`, `committing`.
2. Reemplazar `AnimatedContainer` durante drag por transform directo.
3. Mantener rail fijo y movimiento horizontal estricto.
4. Introducir guard visual anti doble ejecucion del commit/action async.
5. Mantener thresholds configurables para calibracion posterior.
6. Dejar la transicion de lista para una fase independiente si hace falta.
