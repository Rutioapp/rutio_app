# Habit Card Progressive Skip - Phase 6B.4

## 1. Estado anterior

El rail izquierdo ya permitia `Saltar`, `Editar` y `Eliminar`. Al pulsar
`Saltar`, Home registraba una transicion skipped y entonces aparecia el feedback
camel debajo de la foreground.

## 2. Problema visual

Durante el drag izquierdo se veia el rail, pero no la misma card camel de estado
que luego aparecia tras pulsar `Saltar`. Eso podia sentirse como una segunda
aparicion posterior.

## 3. Nueva composicion

```text
Stack
  feedback skipped fijo debajo
  rail de tres acciones izquierdas
  foreground Habit Card
```

La foreground sigue siendo la unica card interactiva principal y se mueve con
`Transform.translate`.

## 4. Relacion entre rail y feedback

El feedback comunica el estado final "omitido". El rail mantiene las tres
acciones existentes, su orden, labels, iconos y callbacks. El fondo visual del
estado skipped vive debajo del rail para que se revele de forma continua.

## 5. Calculo de leftRevealProgress

```text
leftRevealProgress = clamp(abs(min(offsetX, 0)) / leftRevealExtent, 0, 1)
leftRevealExtent = leftActionsExtent
```

Actualmente `leftActionsExtent` es `234 px`.

## 6. Posicion del icono

El icono skipped queda alineado a la derecha, espejado respecto al tick completed:

```text
right inset = statusIconHorizontalInset = 24 px
```

El icono mide `32 px`, por lo que su centro queda en `right - 40 px`.

## 7. Opacidad y escala progresivas

El icono usa los mismos parametros que completed:

```text
progress <= 0.10 -> opacity 0
0.10 < progress < 0.75 -> Curves.easeOutCubic
progress >= 0.75 -> opacity 1
scale = 0.94 -> 1.00
```

No hay rebote, rotacion, overshoot ni zoom fuerte.

## 8. Cancelacion

Al volver hacia `offsetX == 0`, `leftRevealProgress` baja con el offset visual.
El feedback queda cubierto y el icono vuelve a `opacity 0`. No se crea transicion
ni se ejecuta callback.

## 9. Flujo de Saltar

Al pulsar `Saltar`, el shell captura `offsetX`, `cardWidth`, `velocityX`,
`revealProgress` y `leftRevealProgress`. Home registra la transicion skipped y
ejecuta inmediatamente el callback productivo.

## 10. Handoff shell -> Home

Home reconstruye `HabitCardStatusFeedback(kind: skipped)` usando los mismos
tokens, inset, curva, opacidad y escala. El primer frame de Home conserva la
geometria y el offset de la foreground.

## 11. Salida del foreground

La foreground continua desde su offset izquierdo actual hasta:

```text
-(cardWidth + 24)
```

La salida es monotona y no vuelve al centro.

## 12. Lifecycle autoritativo

La limpieza sigue dependiendo de:

```text
visualAnimationCompleted && pendingRemoved
```

## 13. Callback rapido/lento

Si el store elimina el pending rapido, la animacion sigue hasta terminar. Si el
store tarda, queda tombstone de altura cero suprimiendo la card pending real.

## 14. Error

Si el callback productivo falla, Home elimina la transicion temporal y repropaga
la excepcion. La UI no deja feedback ni tombstone huerfanos.

## 15. Guards

`_isInteractionLocked` conserva la proteccion contra dos taps rapidos. Solo
`Saltar` registra una transicion skipped; `Editar` y `Eliminar` no lo hacen.

## 16. Tombstones

Mientras existe transicion activa para un `habitId`, la pending real con el
mismo id queda suprimida.

## 17. Reorder y keys

Snapshots y feedback temporal siguen fuera de `SliverReorderableList`. Las keys
reales `habit_pending_$id`, `habit_done_$id` y `habit_skipped_$id` no cambian.

## 18. Tests

Se cubre:

- feedback skipped montado desde el inicio;
- reveal progresivo con offset negativo;
- opacidad y escala del icono;
- icono fijo a la derecha;
- cancelacion hacia el centro;
- right swipe sin skipped;
- left swipe sin completed;
- `Editar` y `Eliminar` sin callback skip;
- handoff skipped con posicion/opacidad/escala;
- tombstone y cleanup existentes.

## 19. Regresiones

Se mantienen completed progresivo, completed -> pending centrado, skip callback
unico, check/count, emoji, reorder y selectores.

## 20. Parametros pendientes

Validar en dispositivo si el rail necesita un refuerzo de contraste sobre camel
en Android medio y si `statusIconHorizontalInset = 24 px` es optimo para todos
los tamanos.

## 21. Checklist manual

Probar:

- drag izquierdo lento;
- drag izquierdo parcial y cancelacion;
- rail completamente abierto;
- pulsar `Saltar`;
- pulsar `Editar`;
- pulsar `Eliminar`;
- callback lento;
- callback rapido;
- dos skips seguidos;
- cruce izquierda -> centro -> derecha;
- primera/intermedia/ultima card;
- scroll activo;
- Android medio;
- iPhone 60 Hz;
- iPhone 120 Hz.

## 22. Preparacion para Fase 6C

Con completed y skipped ya estabilizados visualmente dentro de pending, 6C puede
introducir la lista filtrada sin mezclar cambios de gestos con cambios de
estructura.

## 23. Fase 6B.4.1 - Rail blanco y entrada skipped desde la derecha

La composicion progresiva camel durante el drag izquierdo queda descartada para
produccion. Mientras el usuario arrastra hacia la izquierda, la Habit Card debe
mostrar solo el rail original blanco con las tres acciones:

- `Saltar`
- `Editar`
- `Eliminar`

No se monta `HabitCardStatusFeedback(kind: skipped)` bajo el foreground durante
el drag. Por tanto, no aparece fondo camel, icono skipped, opacidad progresiva
ni transicion de estado hasta que el usuario pulsa `Saltar`.

Al pulsar `Saltar`, el shell captura el estado visual actual y Home registra una
transicion skipped temporal. La foreground empieza en el `offsetX` izquierdo
actual y continua hasta:

```text
-(cardWidth + 24)
```

En la misma secuencia, la card de feedback skipped empieza fuera por la derecha
en:

```text
cardWidth + 24
```

y entra hacia `offsetX = 0`. Cuando llega al centro, mantiene el
`skippedHoldDuration` existente y despues ejecuta el colapso vertical existente.
El icono skipped se muestra completo dentro de esta card de feedback; ya no
depende del `leftRevealProgress` del drag.

La regla autoritativa de limpieza no cambia:

```text
visualAnimationCompleted && pendingRemoved
```

Tampoco cambian callbacks, tombstones, keys reales, reorder, store, negocio,
persistencia, sync, Supabase ni recompensas. Completed conserva su flujo
progresivo independiente.

Tests actualizados:

- drag izquierdo en shell: solo rail blanco y tres acciones;
- no existe `habitCardLeftSkipFeedback` durante drag;
- handoff skipped: foreground sale a la izquierda desde su offset actual;
- feedback skipped: entra desde `cardWidth + 24` hasta `0`;
- hold y colapso skipped existentes se mantienen;
- right swipe no revela skipped;
- completed no cambia.

### Calibracion de entrada skipped

La entrada skipped usaba inicialmente el mismo spring horizontal que la salida de
la foreground:

```text
mass = 1.0
stiffness = 400
damping = 42
```

Ese spring era correcto para retirar la foreground, pero hacia que la card camel
entrara desde la derecha con demasiada rapidez perceptiva.

La entrada skipped pasa a usar un spring propio y localizado:

```text
mass = 1.0
stiffness = 280
damping = 38
```

El objetivo es que el recorrido `cardWidth + 24 -> 0` se perciba mas lento y
cuidado, manteniendo avance monotono, sin rebote y sin sobrepasar el centro. No
cambian `skippedHoldDuration`, `collapseDuration`, fade, colores, icono, rail,
callbacks ni el spring principal de completed/foreground.
