# Habit Card Progressive Completion - Phase 6B.2

## 1. Comportamiento anterior

El shell pintaba un cue verde local durante el swipe derecho, con
`CupertinoColors.systemGreen` y alpha bajo. Tras confirmar `rightCommit`, Home
montaba otro feedback completo mediante `HabitCardStatusFeedback`.

## 2. Problema observado

Aunque el lifecycle era correcto, visualmente habia dos fuentes de verde: una
franja/cue durante el gesto y una card de feedback despues del commit. Eso podia
sentirse como una aparicion posterior o un cambio de card verde.

## 3. Referencia visual objetivo

La composicion objetivo es una card de completado fija debajo desde el inicio,
revelada por la card frontal al desplazarse hacia la derecha.

## 4. Nueva composicion Stack

```text
Stack
  completed feedback fijo debajo
  left action rail
  foreground Habit Card
```

La foreground sigue usando `Transform.translate(offset: Offset(offsetX, 0))` y
es la unica capa interactiva.

## 5. Feedback fijo debajo

El shell monta `HabitCardStatusFeedback(kind: completed)` cuando
`canSwipeRightComplete` y `onSwipeRightComplete` estan activos. La transicion de
Home usa el mismo widget y los mismos tokens.

## 6. Reveal progresivo

La card frontal cubre naturalmente el feedback cuando `offsetX == 0`. Al moverla
a la derecha, el feedback queda descubierto sin relayout ni cambio de ancho.

## 7. Calculo de rightRevealProgress

```text
rightRevealProgress = clamp(offsetX / rightRevealExtent, 0, 1)
rightRevealExtent = rightCommitThreshold(cardWidth)
```

Asi el feedback esta completo al llegar al umbral de commit.

## 8. Cancelacion

Si el usuario vuelve hacia el centro, `rightRevealProgress` baja con el offset.
Al soltar antes del commit, la card vuelve a closed, el feedback queda cubierto y
no se ejecuta callback ni se crea transicion.

## 9. Cruce por el centro

Para `offsetX <= 0`, la capa completed sigue montada pero opaca a `0`. El rail
izquierdo sigue siendo el unico feedback visible en swipe negativo. Al cruzar a
positivo, el feedback completed empieza a revelarse sin salto.

## 10. Emoji a la izquierda

`HabitCardWidget` mantiene la estructura principal:

```text
[emoji] [contenido principal expandido] [control derecho]
```

El emoji se mueve con la foreground y no existe dentro del feedback completed.

## 11. Layout de HabitCardWidget

El layout conserva titulo, descripcion, badges, cosmeticos, check y count. Se
anadieron keys de presentacion para tests, sin cambiar API publica ni callbacks.

## 12. Handoff shell -> Home

Al confirmar completion, el shell captura offset, velocidad, ancho, commit
progress y right reveal progress. Home registra la transicion temporal y
reconstruye el mismo feedback desde los mismos tokens.

## 13. Datos visuales transportados

`HabitCardRightCommitVisualState` transporta:

- `offsetX`;
- `velocityX`;
- `cardWidth`;
- `commitProgress`;
- `rightRevealProgress`.

No transporta widgets, context, controllers, store ni callbacks productivos.

## 14. Fuente unica de tokens

Los colores, bordes, iconos y progresion del icono viven en
`habit_card_status_feedback.dart`. Shell y Home importan esa misma fuente.

## 15. Lifecycle posterior al commit

Se mantiene la secuencia de 6B.1:

```text
foreground sale -> feedback visible -> hold -> fade tardio -> collapse -> tombstone -> cleanup autoritativo
```

La limpieza sigue dependiendo de `visualAnimationCompleted && pendingRemoved`.

## 16. Callbacks preservados

`rightCommit`, `skip`, check, count, guards async y callbacks productivos no
cambian. El callback de completion sigue ejecutandose inmediatamente y una sola
vez.

## 17. Tests anadidos

Se actualizan tests para cubrir:

- feedback completed montado bajo foreground;
- reveal progresivo y reversible;
- left swipe sin completed feedback visible;
- icono con opacidad progresiva;
- emoji moviendose con foreground;
- feedback sin emoji;
- layout emoji/titulo/control;
- handoff con `rightRevealProgress`.

## 18. Regresiones verificadas

Se mantienen las rutas de skip, completed -> pending centrado, tombstone,
callbacks, reorder temporal y continuidad horizontal.

## 19. Limitaciones conocidas

El feedback progresivo de skip queda fuera de esta fase. El progreso visual del
handoff se reconstruye deterministicamente, no mueve el mismo widget con
`GlobalKey`.

## 20. Preparacion para 6B.3 y 6B.4

6B.3 puede calibrar microdetalles del handoff en dispositivo real. 6B.4 puede
aplicar un modelo progresivo equivalente al lado izquierdo para skip.

## 21. Checklist manual

Probar:

- swipe derecho lento;
- swipe derecho rapido;
- reveal parcial y cancelacion;
- cambio de direccion varias veces;
- cruce desde rail izquierdo a derecha;
- commit al 50%;
- commit por flick;
- primera, intermedia y ultima card;
- habito check;
- habito count;
- titulo largo;
- emoji ancho;
- callback lento;
- dos commits seguidos;
- completed -> pending;
- skip;
- scroll durante transicion;
- Android medio;
- iPhone 60 Hz;
- iPhone 120 Hz.

Criterios:

- el verde aparece gradualmente;
- no aparece de golpe;
- el tick evoluciona con el progreso;
- cancelar cubre de nuevo el feedback;
- el emoji esta a la izquierda;
- el handoff parece continuacion exacta del gesto;
- no hay doble card verde ni parpadeos.

## Fase 6B.3 - Tick izquierdo y revelado progresivo

### Problema observado

En dispositivo real, el fondo verde se revelaba correctamente, pero el tick de
completed aparecia centrado y su transparencia no se leia como una continuacion
directa del desplazamiento.

### Posicion anterior

`HabitCardStatusFeedback` centraba el icono en la card de feedback.

### Nueva posicion

Para `completed`, el tick queda fijo en la zona izquierda, alineado con la zona
visual donde vive el emoji de la card frontal. `skipped` mantiene su icono
centrado por ahora.

### Inset elegido

`statusIconHorizontalInset = 24 px`.

El icono mide `32 px`, por lo que su centro queda en `left + 40 px`, estable
para cards de distintas alturas y sin depender del titulo.

### Opacity

La opacidad depende solo de `rightRevealProgress`:

```text
progress <= 0.10 -> opacity 0
0.10 < progress < 0.75 -> Curves.easeOutCubic
progress >= 0.75 -> opacity 1
```

### Scale

La escala usa el mismo intervalo visual que la opacidad:

```text
scale = 0.94 -> 1.00
```

No hay rebote, rotacion, overshoot ni elasticidad.

### Cancelacion

Al volver hacia `offsetX == 0`, `rightRevealProgress` baja frame a frame y el
tick vuelve a `opacity 0`. No queda un frame residual visible.

### Handoff shell -> Home

El shell entrega `rightRevealProgress` en `HabitCardRightCommitVisualState`.
Home reconstruye `HabitCardStatusFeedback` con el mismo inset, la misma curva, la
misma opacidad y la misma escala. No hay salto de tick izquierdo a tick centrado.

### Tests anadidos

Se cubre:

- opacity `0` en offset `0`;
- opacity parcial en drag pequeno;
- opacity mayor con offset mayor;
- opacity `1` con progreso suficiente;
- opacidad decreciente al cancelar;
- tick fijo a la izquierda y no centrado;
- posicion horizontal estable durante drag;
- handoff manteniendo inset, opacity y scale;
- ausencia de doble tick centrado en Home.

### Pendiente de calibracion real

Validar en dispositivo si `24 px` coincide visualmente con la posicion del emoji
en todos los tamanos compactos/no compactos, y si el intervalo `0.10 -> 0.75`
conviene abrirlo o cerrarlo en pantallas de 60 Hz.
