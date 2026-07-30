# Habit Card Swipe Motion - Phase 3

## 1. Geometria final de esta fase

La geometria del gesto queda centralizada en `HabitCardSwipeMotionConfig` y en
el resolver puro `resolveSwipeDestination`.

Posiciones:

- `closed`: `0`.
- `leftOpen`: `-leftActionsExtent`.
- `rightCommit`: destino logico; el shell ejecuta el callback y asienta la card
  visualmente hacia `closed`.

El movimiento durante drag sigue siendo directo dentro de limites:

```text
offsetX = offsetX + delta.dx
```

## 2. Decision sobre el ancho del rail

Decision: **B. Utilizar un token de diseno centralizado**.

Motivo: el rail actual tiene tres acciones estables, controladas por el propio
shell, y cada accion conserva una anchura efectiva fija. No hace falta introducir
`GlobalKey`, mediciones post-frame ni estado adicional.

El valor queda en:

```text
leftActionsExtent = 234
```

Por tanto:

```text
leftOpenOffset = -234
```

## 3. Configuracion centralizada

`HabitCardSwipeMotionConfig` centraliza:

| Parametro | Valor provisional |
| --- | ---: |
| `leftActionsExtent` | `234` |
| `leftOpenThresholdFraction` | `0.45` |
| `rightCommitThresholdFraction` | `0.50` |
| `rightFlickMinDistanceFraction` | `0.08` |
| `rightFlickVelocity` | `700 px/s` |
| `leftFlickVelocity` | `700 px/s` |
| `rightVisualLimitFraction` | `0.60` |
| `overdragResistance` | `0.20` |
| `maxOverscroll` | `36` |
| `settleTolerance` | `0.5` |
| `settleDuration` | `220 ms` |
| `settleCurve` | `Curves.easeOutCubic` |

El ancho de card se obtiene con `LayoutBuilder` dentro del shell, sin cambiar el
contrato publico de Home.

## 4. Destinos posibles

Modelo explicito:

```dart
enum HabitCardSwipeDestination {
  closed,
  leftOpen,
  rightCommit,
}
```

El resolver no conoce `Habit`, `UserStateStore`, Supabase, monedas, XP,
recompensas ni sincronizacion.

## 5. Algoritmo distancia/velocidad

Al finalizar el gesto:

1. Si la card no empezo abierta, el swipe derecho esta habilitado y existe
   callback:
   - `offset >= cardWidth * 0.50` confirma `rightCommit`.
   - `velocity >= 700` y `offset >= cardWidth * 0.08` confirma `rightCommit`.
2. Si `offset > 0` y no hay commit, el destino es `closed`.
3. Si `offset.abs() >= leftActionsExtent * 0.45`, el destino es `leftOpen`.
4. Si `velocity <= -700`, el destino es `leftOpen`.
5. En cualquier otro caso, el destino es `closed`.

La velocidad respeta direccion: una velocidad negativa no confirma commit
derecho; una velocidad positiva no abre el rail izquierdo.

## 6. Hysteresis

No se anadio hysteresis adicional. Una card que empezo abierta se resuelve con el
offset y velocidad finales, pero el commit derecho queda bloqueado por
`startedOpen`. Esto permite cerrar la card arrastrando hacia la derecha sin
arriesgar un completado accidental desde el rail abierto.

## 7. Sobrearrastre

La resistencia se aplica solo al exceso fuera de limites:

```text
visualOffset = limit + ((rawOffset - limit) * overdragResistance)
```

Limites:

- izquierda: `-leftActionsExtent`;
- derecha: `cardWidth * rightVisualLimitFraction`, si el commit esta habilitado;
- derecha: `0`, si el commit no esta habilitado.

No hay resistencia antes de llegar al limite.

## 8. Tests anadidos

`test/screens/home/habit_card_swipe_shell_test.dart` cubre ahora:

- offset 1:1 dentro de limites;
- sobrearrastre izquierdo y derecho;
- destino closed con drag derecho bajo 50%;
- destino rightCommit con drag derecho >= 50%;
- flick derecho con menor recorrido;
- flick izquierdo sin commit derecho;
- drag izquierdo corto y suficiente;
- flick izquierdo a `leftOpen`;
- card abierta que puede cerrar;
- inversion antes de soltar;
- destinos closed/leftOpen sin callback de negocio;
- rightCommit bloqueado mientras hay Future pendiente;
- rail completo en `leftOpen`;
- acciones, labels, iconos, orden y child visual preservados.

## 9. Comportamiento no modificado

Sigue fuera de alcance:

- transicion pending -> completed;
- keys entre secciones;
- `AnimatedList`, `SliverAnimatedList`, `AnimatedSize`;
- `SliverReorderableList`;
- `HabitCardWidget`;
- spring definitivo;
- hapticos;
- store, negocio, economia, Supabase, repositorios y sync.

## 10. Pendiente de calibracion real

- `rightCommitThresholdFraction`.
- `rightFlickVelocity`.
- `rightFlickMinDistanceFraction`.
- `leftOpenThresholdFraction`.
- `leftFlickVelocity`.
- `rightVisualLimitFraction`.
- `overdragResistance` y `maxOverscroll`.
- Curva/spring definitivo de asentamiento.

## 11. Riesgos para pending -> completed

La card ya confirma el destino derecho de forma clara, pero al completar el store
sigue reconstruyendo Home y moviendo la card entre secciones. La continuidad
visual entre `pendingHabits` y `completedHabits` sigue siendo el principal riesgo
pendiente: las keys por seccion cambian y no hay aun capa de transicion dedicada.
