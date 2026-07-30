# Habit Card Swipe Motion - Phase 2

## 1. Estructura interna anterior

Tras Fase 1, `HabitCardSwipeShell` ya era reusable, pero sus internals seguian
replicando el motor antiguo:

- `_offset` local mutado con `setState`;
- `AnimatedContainer` aplicando `Matrix4.translationValues`;
- dragFactor derecho `0.72` y `0.42`;
- constantes privadas dispersas;
- booleanos `_isDragging` y `_startedFromOpenTray`;
- sin guard local contra callbacks async duplicados.

## 2. Nuevo modelo de movimiento

El contrato publico de `HabitCardSwipeShell` se mantiene. La sustitucion ocurre
dentro del shell:

- `Transform.translate` mueve la card.
- El offset se actualiza de forma directa durante `onHorizontalDragUpdate`.
- `AnimationController` queda limitado al asentamiento tras soltar.
- `RepaintBoundary` envuelve la capa movil.
- `HabitCardSwipeMotionConfig` centraliza los parametros provisionales.

No se actualiza Home, store ni providers durante cada frame de drag.

## 3. Maquina de estados visual

Estados introducidos:

- `idle`
- `dragging`
- `settlingClosed`
- `settlingLeftOpen`
- `committingRight`
- `actionInFlight`

`committingRight` y `actionInFlight` bloquean nuevas acciones o commits de esa
card hasta que el callback pendiente termina.

## 4. Actualizacion del offset

Durante el recorrido normal:

```text
offsetX = offsetX + delta.dx
```

Esto permite:

- seguir el dedo 1:1 dentro de limites;
- invertir direccion dentro del mismo gesto;
- cruzar el centro sin reiniciar el gesto;
- evitar logica de negocio durante `onHorizontalDragUpdate`.

La lista completa no se reconstruye por el drag; el cambio de offset vive dentro
del shell activo.

## 5. Limites y resistencia

La resistencia solo aparece despues de superar los limites normales:

- limite izquierdo normal: `-revealWidth`;
- limite derecho normal: `rightVisualLimit` si el commit derecho esta habilitado;
- si el commit derecho no esta habilitado, el limite derecho normal es `0`.

El sobrearrastre usa resistencia provisional:

```text
resisted = excess * overscrollResistance
```

con maximo `maxOverscroll`.

## 6. Decision de destinos

La decision funcional conserva los thresholds actuales:

- `rightCommit` si se supera distancia derecha o flick derecho;
- `leftOpen` si se supera distancia izquierda o flick izquierdo;
- `closed` para drags cortos o offsets derechos sin commit.

El asentamiento siempre anima desde el offset visual actual. Si empieza un nuevo
drag durante el asentamiento, se cancela la animacion activa y se continua desde
ese offset.

## 7. Guard anti doble ejecucion

El guard vive solo en `HabitCardSwipeShell`.

Protege:

- commit hacia la derecha;
- Saltar;
- Editar;
- Eliminar.

El flujo es:

1. Si el shell esta en `committingRight` o `actionInFlight`, ignora la nueva
   interaccion.
2. Al iniciar accion/commit, entra en el estado bloqueante correspondiente.
3. Ejecuta el callback existente.
4. Libera el estado con `try/finally`.

No se cambia `UserStateStore` ni se depende solo de idempotencia de negocio.

## 8. Callbacks preservados

Home sigue conectando los mismos callbacks:

- Swipe derecho: `UserStateStore.setHabitCompletionForKey(...)`.
- Saltar: `UserStateStore.setHabitSkipForKey(...)`.
- Editar: `openHabitDetails(mode: HabitDetailScreenMode.editOnly)`.
- Eliminar: `_confirmAndDeleteHabitFromHome(...)`.

No se tocaron economia, monedas, XP, rachas, logs, repositorios, Supabase ni sync.

## 9. Tests anadidos

`test/screens/home/habit_card_swipe_shell_test.dart` ahora cubre:

- calculos puros de offset directo;
- resistencia despues de limites;
- decision de destinos;
- normalizacion de progreso;
- estados visuales esperados;
- drag proporcional;
- inversion izquierda -> derecha;
- inversion derecha -> izquierda;
- drag corto a closed;
- drag izquierdo suficiente a rail abierto;
- callback derecho solo al finalizar;
- nuevo drag durante asentamiento desde offset actual;
- acciones fijas bajo la card;
- guard async en acciones;
- guard async en commit derecho;
- liberacion del guard;
- labels, iconos, orden y child unico.

## 10. Parametros provisionales

Centralizados en `HabitCardSwipeMotionConfig`:

| Parametro | Valor inicial |
| --- | ---: |
| `actionWidth` | `78` |
| `openThresholdRatio` | `0.30` |
| `rightVisualLimit` | `84` |
| `rightCompleteThreshold` | `54` |
| `rightFlingMinOffset` | `26` |
| `rightFlingVelocity` | `520` |
| `leftFlingVelocity` | `-320` |
| `overscrollResistance` | `0.28` |
| `maxOverscroll` | `36` |
| `settleDuration` | `220 ms` |
| `settleCurve` | `Curves.easeOutCubic` |

## 11. Pendiente de calibracion

- Threshold futuro del 50% para commit derecho.
- Mezcla final distancia/velocidad en dispositivos reales.
- Curva o spring definitivo de asentamiento.
- Resistencia y maximo de sobrearrastre.
- Haptics y feedback fino al confirmar commit.

## 12. Riesgos para pending -> completed

La transicion de lista sigue fuera de alcance. Al completar, el store reconstruye
Home y `buildHomeViewData` mueve la card entre `pendingHabits` y
`completedHabits`. Las keys por seccion siguen cambiando y no existe aun una
capa de transicion coordinada. La siguiente fase debe tratar esa continuidad sin
tocar recompensas ni persistencia.
