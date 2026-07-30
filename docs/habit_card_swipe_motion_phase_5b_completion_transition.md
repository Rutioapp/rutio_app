# Habit Card Swipe Motion - Phase 5B Completion Transition

## 1. Problema anterior

Al confirmar `rightCommit`, Home ejecutaba el callback productivo y el store
notificaba antes de terminar la persistencia. Home reconstruia inmediatamente,
`buildHomeViewData` movia el habito de `pendingHabits` a `completedHabits` y la
fila `habit_pending_$id` se desmontaba sin salida visual.

## 2. Arquitectura implementada

La solucion es UI-only:

- Home registra un snapshot visual antes del callback productivo.
- El callback productivo se ejecuta inmediatamente.
- Tras el rebuild del store, `HomeHabitsSliver` pinta el snapshot temporal en la
  zona pending.
- El snapshot sale con una animacion corta de opacidad y altura.
- Al terminar, el snapshot se elimina del estado local de Home.

No se tocaron store, negocio, rewards, persistencia, sync, Supabase ni
clasificacion funcional.

## 3. Propietario del estado temporal

El estado vive en `_HomeScreenState`:

```text
Map<String, HomeHabitCompletionTransition> _habitCompletionTransitions
```

La key del mapa es `habitId`, para evitar dos transiciones simultaneas del mismo
habito.

## 4. Modelo de transicion

`HomeHabitCompletionTransition` contiene:

- `transitionId`
- `habitId`
- `originalIndex`
- `dateKey`
- `habitSnapshot`
- `startedAt`
- `widgetKey`

No contiene callbacks, store, repositorios ni `BuildContext`.

## 5. Orden exacto snapshot -> callback -> rebuild -> salida

```text
1. HabitCardSwipeShell confirma rightCommit.
2. Home registra HomeHabitCompletionTransition.
3. Home limpia _revealedHomeSwipeHabitId si apuntaba a ese habito.
4. Home ejecuta IosFeedback.lightImpact().
5. Home llama inmediatamente setHabitCompletionForKey.
6. Store muta y notifyListeners provoca rebuild.
7. pendingHabits real ya no contiene el habito.
8. HomeHabitsSliver recibe completionTransitions.
9. El snapshot se pinta en la zona pending.
10. El snapshot anima salida.
11. onDismissed elimina solo esa transicion por habitId + transitionId.
```

## 6. Representacion visual utilizada

El snapshot usa `HabitCardWidget` configurado como visual-only:

- sin `HabitCardSwipeShell`;
- sin callbacks de tap;
- sin callbacks de check/count;
- envuelto por `IgnorePointer`;
- con `isCompleted: true` para checks;
- con la misma resolucion basica de titulo, familia, fondo, badges y XP text.

No reutiliza widgets desmontados ni `GlobalKey`.

## 7. Animacion y duracion

`_HomeHabitCompletionTransitionTile` usa:

- `AnimationController` local de `220 ms`;
- `SizeTransition` de `1 -> 0`;
- `FadeTransition` de `0.92 -> 0`;
- `SlideTransition` horizontal minimo `0 -> 0.035`;
- curva `Curves.easeOutCubic`;
- sin rebote, `elasticOut`, `bounceOut` ni decoracion prolongada.

La prioridad es mantener altura al inicio y permitir que el contenido suba de
forma suave.

## 8. Tratamiento de callback async

El callback y la animacion pueden terminar en distinto orden:

- si el callback termina primero, la animacion sigue y limpia al finalizar;
- si la animacion termina primero, el snapshot desaparece y el callback sigue;
- si el callback falla, Home elimina el snapshot y repropaga la excepcion.

No se bloquea la UI esperando la persistencia.

## 9. Tratamiento de error

En `catch`, si existe una transicion registrada, se elimina por
`habitId + transitionId` y se hace `rethrow`. La UI no simula rollback; el estado
real del store decide que se pinta despues.

## 10. Limpieza en dispose y cambio de vista

Home limpia transiciones:

- al cambiar de fecha desde el week strip;
- cuando el dia cambia por lifecycle;
- en `dispose`.

Cada tile tambien dispone su `AnimationController`. Las limpiezas tardias usan
`transitionId` para no eliminar una transicion nueva por accidente.

## 11. Integracion con SliverReorderableList

Cuando no hay transiciones, pending usa exactamente el flujo anterior:

- `SliverList` si hay menos de 2 pending;
- `SliverReorderableList` si hay 2 o mas pending.

Cuando hay transiciones activas, pending se pinta temporalmente como un
`SliverList` visual mezclado con snapshots. Esto evita introducir items falsos
en `SliverReorderableList`, no cambia `onReorder` y no contamina el orden
persistido. Durante esos 220 ms, reorder de pending queda fuera de esa capa
visual.

## 12. Estrategia de keys

Se conservan keys reales:

- `habit_pending_$id`
- `habit_done_$id`
- `habit_skipped_$id`

El snapshot usa:

```text
habit_completion_transition_${transitionId}_$habitId
```

No hay `Hero` ni reutilizacion de key entre secciones.

## 13. Coordinacion con card abierta

Al registrar la transicion, si `_revealedHomeSwipeHabitId` apunta al habito que
se completa, Home lo limpia. La coordinacion de apertura sigue viviendo en Home.

## 14. Soporte de multiples transiciones

El estado permite varias transiciones simultaneas para habitos distintos. Cada
una se ordena por `originalIndex` y se limpia por `habitId + transitionId`.

Para el mismo `habitId`, un segundo registro se ignora mientras la transicion
actual exista.

## 15. Tests anadidos

Nuevo test:

- `test/screens/home/habit_completion_transition_test.dart`

Cubre:

- snapshot visual-only bajo `IgnorePointer`;
- ausencia de `HabitCardSwipeShell`;
- ausencia de drag listener de reorder en el snapshot;
- key temporal distinta de pending/done;
- mantenimiento inicial de espacio;
- eliminacion al terminar la animacion;
- dos transiciones simultaneas;
- `SliverReorderableList` intacto cuando no hay snapshot y fuera de la ruta
  temporal cuando si lo hay.

## 16. Checklist manual

Validar en dispositivo:

- completar una card arriba;
- completar una card en medio;
- completar la ultima card pending;
- completed expandido;
- completed plegado;
- varias cards completadas seguidas;
- scroll activo;
- card abierta a la izquierda antes de completar;
- habito count;
- habito check;
- callback lento;
- error simulado;
- pantalla con pocos habitos;
- pantalla con muchos habitos;
- Android;
- iPhone 60 Hz;
- iPhone 120 Hz cuando este disponible.

## 17. Limitaciones conocidas

- No anima entrada en `completedHabits`.
- No conecta visualmente pending con completed; solo suaviza la salida pending.
- Durante una transicion activa, pending no usa reorder real por 220 ms.
- La altura es la natural del snapshot, no una medicion exacta del render
  anterior.
- La limpieza por cambio de usuario/scope no introduce logica de store; se apoya
  en lifecycle y cambio de vista local.

## 18. Riesgos pendientes

- Ajustar si la salida desde cards con fondos cosméticos muy pesados genera
  coste visual.
- Validar en listas largas con scroll activo.
- Revisar si conviene una coordinacion futura con el header de completados.
- Decidir si una fase posterior debe animar entrada compacta cuando completed
  esta expandido.

## 19. Siguiente fase

Fase siguiente recomendada: validar en dispositivo real y, si la salida local ya
se siente estable, disenar una entrada opcional en `completedHabits` solo para
cuando la seccion completada este expandida, manteniendo store y keys reales sin
cambios.

## 20. Fase 5B.1 - Correccion del handoff de rightCommit

### Causa concreta del retorno al centro

La primera version de 5B registraba un snapshot visual, pero
`HabitCardSwipeShell._commitRight` seguia llamando:

```dart
_settleTo(0, HabitCardSwipeVisualState.committingRight, velocity: velocity);
```

Eso iniciaba un spring local hacia `offsetX = 0` antes de que el snapshot pudiera
continuar la salida. Ademas, el snapshot no guardaba offset horizontal inicial,
asi que su primer frame se pintaba centrado. El resultado en dispositivo era:

```text
swipe derecho -> vuelve al centro -> aparece/desaparece snapshot centrado
```

### Cambio realizado en el contrato UI

`HabitCardSwipeShell` entrega ahora un estado visual de commit:

```dart
HabitCardRightCommitVisualState
  offsetX
  velocityX
  cardWidth
  commitProgress
```

El callback de right commit pasa a recibir ese objeto de presentacion. El modelo
es UI-only: no conoce `Habit`, store, repositorios, callbacks ni `BuildContext`.

### Datos visuales entregados por el shell

Al resolver `rightCommit`, el shell:

1. detiene cualquier animacion local;
2. lee `controller.value` como offset visible real;
3. calcula progreso de commit;
4. entra en `committingRight`;
5. llama inmediatamente al callback con `HabitCardRightCommitVisualState`;
6. no llama a `_settleTo(0)`;
7. no pone `controller.value = 0`.

### Offset inicial del snapshot

`HomeHabitCompletionTransition` guarda ahora:

- `initialOffsetX`;
- `velocityX`;
- `cardWidth`;
- `commitProgress`.

El tile de transicion envuelve el snapshot con:

```dart
Transform.translate(
  offset: Offset(horizontalOffset, 0),
)
```

`horizontalOffset` empieza en `initialOffsetX`. El primer frame del snapshot ya
no nace en `0`.

### Secuencia horizontal y vertical

La transicion dura `280 ms`:

- salida horizontal: `initialOffsetX -> cardWidth + 24` durante el primer 48% de
  la animacion;
- colapso vertical: `heightFactor 1 -> 0` desde el 34% hasta el final;
- opacidad: `0.96 -> 0`;
- curva: `Curves.easeOutCubic`;
- sin rebote ni elasticidad decorativa.

Esto mantiene la fila con altura completa al principio, permite que la card
continue hacia la derecha y retrasa el colapso hasta que la salida horizontal ya
esta en marcha.

### Comportamiento de las cards inferiores

Las cards inferiores no suben en el primer frame posterior al rebuild. La altura
del snapshot se mantiene inicialmente y luego disminuye de forma progresiva con
`SizeTransition`, de modo que las posiciones Y avanzan hacia su posicion final
durante el colapso.

### Impacto del cambio de sliver

La integracion de 5B sigue evitando meter snapshots dentro de
`SliverReorderableList`: durante transiciones activas, pending se pinta como
`SliverList` visual temporal. Esta limitacion se mantiene porque protege el
orden persistido y evita que snapshots entren en `onReorder`. La correccion del
bug se centra en preservar geometria inicial y continuidad horizontal para que
el cambio temporal de sliver no produzca el salto visual principal.

### Tests anadidos

Se ampliaron:

- `test/screens/home/habit_card_swipe_shell_test.dart`
- `test/screens/home/habit_completion_transition_test.dart`

Cobertura nueva:

- rightCommit entrega offset visible exacto a Home;
- rightCommit no asienta hacia `0`;
- snapshot empieza con el mismo offset visual;
- snapshot no aparece centrado;
- salida horizontal avanza hacia la derecha antes del colapso;
- la card inferior no sube en el primer tramo;
- a mitad de colapso la card inferior esta en posicion intermedia;
- el snapshot desaparece solo tras terminar la animacion.

### Parametros provisionales

- duracion total: `280 ms`;
- fase horizontal: `0.0 -> 0.48`;
- fase vertical: `0.34 -> 1.0`;
- margen de salida: `24 px` despues del ancho de card.

Pendiente calibrar en dispositivo real.

### Validacion manual pendiente

Reprobar en dispositivo:

- completar primera, intermedia y ultima card;
- completed plegado y expandido;
- dos completados rapidos;
- scroll activo;
- card abierta a la izquierda antes de completar;
- iPhone 60 Hz;
- iPhone 120 Hz cuando este disponible;
- Android de gama media.

## 21. Fase 5B.2 - Lifecycle autoritativo y continuidad de velocidad

### Bugs corregidos

Quedaban dos fallos criticos en la transicion de completado:

- si la animacion visual terminaba antes de que `setHabitCompletionForKey`
  quitase el habito de `pendingHabits`, Home eliminaba el snapshot y la card
  real reaparecia centrada hasta el siguiente notify del store;
- `velocityX` se guardaba en `HomeHabitCompletionTransition`, pero la salida
  horizontal usaba un tween con curva fija y no aprovechaba la velocidad del
  swipe real.

### Lifecycle nuevo

`HomeHabitCompletionTransition` distingue ahora dos hechos independientes:

- `visualAnimationCompleted`: el snapshot ya termino su salida/collapse visual;
- `pendingRemoved`: el estado actual de Home ya no contiene ese `habitId` en
  `pendingHabits`.

La transicion solo se limpia cuando ambas condiciones son verdaderas. Si la
animacion termina primero, queda un tombstone sin altura visible que sigue
suprimiendo la card real pending. Si el store termina primero, el snapshot sigue
animando hasta completar su salida. En error del callback productivo, Home borra
la transicion por `habitId + transitionId` y repropaga la excepcion para que el
estado real pueda restaurar la card sin duplicados.

La deteccion de `pendingRemoved` se hace exclusivamente desde los datos de Home
ya calculados por `buildHomeViewData`. No se anaden consultas a store, repos,
Supabase ni sync. La reconciliacion se agenda post-frame para no mutar estado
durante build.

### Supresion de la card real

Mientras existe una transicion activa para un `habitId`, `HomeHabitsSliver`
omite la card pending real con ese mismo id. Esto cubre tanto el tramo visible
del snapshot como el estado tombstone de altura cero cuando el callback/store va
mas lento que la animacion.

### Continuidad horizontal con velocidad

La salida horizontal del snapshot usa ahora:

- `AnimationController.unbounded`;
- `SpringSimulation`;
- posicion inicial `initialOffsetX`;
- objetivo `cardWidth + 24`;
- velocidad inicial derivada de `velocityX`.

La simulacion esta sobreamortiguada y el offset pintado se clampa entre
`initialOffsetX` y `exitOffsetX`, de modo que la salida conserva inercia hacia la
derecha sin volver a `0` ni retroceder visualmente.

### Tests de regresion

Se amplio `test/screens/home/habit_completion_transition_test.dart` para cubrir:

- snapshot activo suprimiendo la card pending real como tombstone;
- callback visual completado sin borrar por si solo el snapshot en una lista
  estatica de prueba;
- diferencias observables entre salida lenta y salida con `velocityX` alto;
- offset horizontal monotono y acotado hasta `exitOffsetX`.

## 22. Fase 5B.3 - Correccion del flujo completed -> pending

### Glitch observado

En dispositivo real, al pulsar el check de una card dentro de
`completedHabits`, la card podia desplazarse unos frames hacia la derecha,
mostrar una zona verde en el lado izquierdo y quedar visualmente superpuesta
antes de desaparecer de completed y reaparecer centrada en pending.

La accion real era `true -> false`, por lo que no debia activar ningun efecto
visual de completar.

### Causa exacta

`HabitCardWidget` no era el responsable del desplazamiento horizontal: su FX
interno solo escala la card y muestra el burst cuando detecta `false -> true` en
`didUpdateWidget`.

El responsable era `HabitCardSwipeShell`:

- las cards completadas tambien estaban envueltas por el shell;
- Home pasaba `canSwipeRightComplete: !isCounting`;
- por tanto una card completada seguia aceptando la ruta visual derecha;
- aunque no se ejecutase `rightCommit`, `applyBounds` permitia overdrag positivo
  resistido cuando `canSwipeRightComplete == false`;
- ese offset se pintaba con `Transform.translate`;
- la zona verde salia de `habitCardRightCommitCue`, el cue derecho del shell.

### Intenciones visuales separadas

Se introdujo una distincion UI-only:

```dart
HabitCompletionVisualIntent.complete
HabitCompletionVisualIntent.uncomplete
```

Home calcula la intencion desde el estado actual:

- `doneToday == false` -> `complete`;
- `doneToday == true` -> `uncomplete`.

Solo `complete` habilita `rightCommit`, `HabitCardRightCommitVisualState`,
snapshot, `velocityX`, spring horizontal y `HomeHabitCompletionTransition`.

### Cambio aplicado

Para `completed -> pending`:

- `canSwipeRightComplete` pasa a `false`;
- `onSwipeRightComplete` pasa a `null`;
- `applyBounds` clampa cualquier offset positivo a `0` cuando no hay complete
  derecho;
- el cue verde tiene key `habitCardRightCommitCue` y no se renderiza durante
  uncomplete;
- el check tap ejecuta el callback productivo directamente, sin snapshot ni
  spring horizontal.

Para `pending -> completed`:

- se conserva el flujo 5B.2 completo;
- `rightCommit` sigue entregando offset, velocidad, ancho y progreso;
- el snapshot sigue usando `SpringSimulation` horizontal y cleanup autoritativo.

### Callback y doble tap

`HabitCardWidget.onCheckTap` acepta ahora callbacks sync o async mediante
`FutureOr<void>`. El widget mantiene un guard local mientras el callback esta
pendiente:

- el primer tap ejecuta el callback inmediatamente;
- un segundo tap durante el Future pendiente se ignora;
- el guard se libera en `finally`;
- si el callback falla, la excepcion sigue el flujo async actual y la card real
  permanece centrada segun el estado del store.

No se toco `UserStateStore`, negocio, recompensas, persistencia, sync ni
Supabase.

### Interaccion con transiciones anteriores

`HomeHabitCompletionTransition` no se usa en `uncomplete`. Una transicion antigua
de `pending -> completed` solo puede seguir viva por su `habitId + transitionId`
y no se reutiliza para `completed -> pending`.

La limpieza tardia de 5B.2 sigue protegida por `transitionId`, por lo que no
borra una transicion nueva ni altera el estado visual actual.

### Keys, duplicados y reorder

Las keys reales no cambian:

- `habit_done_$id`;
- `habit_pending_$id`;
- `habit_skipped_$id`.

No se crea key temporal ni snapshot para `uncomplete`. Mientras el callback
lento esta pendiente, sigue existiendo una sola representacion interactiva: la
card completed centrada. Cuando el store notifica el cambio, la card se desmonta
de completed y aparece una sola vez en pending. Reorder no recibe elementos
temporales.

### Tests anadidos

Se ampliaron:

- `test/screens/home/habit_card_widget_interaction_test.dart`;
- `test/screens/home/habit_card_swipe_shell_test.dart`.

Cobertura nueva:

- doble tap de check queda protegido mientras el callback esta pendiente;
- `uncomplete` no reproduce completion burst;
- `complete` conserva el burst `false -> true`;
- una card completed dentro de `HabitCardSwipeShell` permanece con `offsetX == 0`
  durante varios frames de callback lento;
- no aparece `habitCardRightCommitCue`;
- no se crea `HabitCardRightCommitVisualState`;
- no se llama `rightCommit`;
- no hay offset positivo cuando `canSwipeRightComplete == false`;
- la ruta 5B.2 de rightCommit sigue pasando.

### Limitacion vertical pendiente

Esta fase prioriza eliminar el glitch horizontal. El cambio vertical
`completedHabits -> pendingHabits` sigue dependiendo del rebuild real del store
y puede sentirse brusco, pero ya no debe aparecer con desplazamiento horizontal,
cue verde, overlay ni duplicado interactivo.

### Validacion manual pendiente

Reprobar en dispositivo:

- desmarcar primera, intermedia y ultima card completed;
- callback lento simulado;
- dos taps rapidos sobre el check;
- completed expandido;
- completed con una y varias cards;
- completar desde pending mediante rightCommit despues de desmarcar;
- confirmar que no aparece zona verde ni desplazamiento a la derecha.
