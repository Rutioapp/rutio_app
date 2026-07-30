# Habit Card Swipe Motion - Phase 4

## 1. Mecanismo de asentamiento anterior

Hasta Fase 3, `HabitCardSwipeShell` asentaba la card con un `Tween<double>` y
`CurvedAnimation` (`easeOutCubic`) durante 220 ms. Ese mecanismo era temporal:
respetaba el target final, pero no conservaba la velocidad horizontal real del
gesto al soltar.

## 2. Nueva implementacion fisica

El asentamiento pasa a usar fisica nativa de Flutter:

- `AnimationController.unbounded`, cuyo valor representa directamente el offset
  horizontal.
- `SpringSimulation`, creada con `HabitCardSwipeMotionConfig.springSimulation`.
- `controller.animateWith(simulation)`.
- `AnimatedBuilder` local sobre el controller para reconstruir solo el shell.

El render sigue siendo:

```dart
Transform.translate(
  offset: Offset(offset, 0),
)
```

No se reintrodujo `AnimatedContainer` para mover la card.

## 3. Parametros del spring

Los parametros fisicos quedan centralizados en `HabitCardSwipeMotionConfig`:

| Parametro | Valor inicial |
| --- | ---: |
| `springMass` | `1.0` |
| `springStiffness` | `480.0` |
| `springDamping` | `42.0` |
| `springToleranceDistance` | `0.5` |
| `springToleranceVelocity` | `5.0` |

Se mantienen intactos los parametros de geometria de Fase 3:

- `leftActionsExtent = 234`
- `leftOpenThresholdFraction = 0.45`
- `rightCommitThresholdFraction = 0.50`
- `rightFlickVelocity = 700`
- `leftFlickVelocity = 700`
- `overdragResistance = 0.20`
- `rightVisualLimitFraction = 0.60`

## 4. Uso de la velocidad final

`DragEndDetails.velocity.pixelsPerSecond.dx` se pasa directamente a
`SpringSimulation` como velocidad inicial. No se inyecta una velocidad fija y no
se cambia el signo:

- velocidad positiva conserva empuje hacia la derecha;
- velocidad negativa conserva empuje hacia la izquierda;
- el destino ya resuelto sigue siendo el target estable de la simulacion.

La simulacion se crea con `snapToEnd: true` y tolerancias pequenas para terminar
exactamente en el target.

## 5. Interrupcion de una simulacion

Cuando empieza un nuevo drag durante un spring activo:

1. Se incrementa una generacion interna de settling.
2. Se lee el offset visual actual desde `controller.value`.
3. Se detiene el controller.
4. Se conserva ese valor como offset actual.
5. El estado pasa a `dragging`.
6. El nuevo gesto continua desde la posicion visible.

La generacion evita que un `whenComplete` de una simulacion anterior pueda cerrar
o cambiar estado despues de haber sido interrumpida.

## 6. Estados visuales implicados

La maquina existente se conserva:

- `idle`
- `dragging`
- `settlingClosed`
- `settlingLeftOpen`
- `committingRight`
- `actionInFlight`

Durante el spring:

- target `closed` usa `settlingClosed`;
- target `leftOpen` usa `settlingLeftOpen`;
- al completar, ambos vuelven a `idle`;
- `committingRight` mantiene el guard del commit mientras el callback productivo
  esta pendiente.

## 7. Sincronizacion con isOpen

Home sigue siendo propietario de `isOpen`. Si Home cambia `isOpen`, el shell
sincroniza el offset con un spring hacia:

- `closedOffset = 0`;
- `openOffset = -leftActionsExtent`.

El cambio se inicia en `didUpdateWidget`, no en cada build. El ancho de layout
solo recalcula limites derechos; el target izquierdo estable no depende del
ancho y permanece en `-234`.

## 8. RightCommit preservado

`rightCommit` sigue siendo una decision del resolver puro de Fase 3. El spring no
vuelve a decidir si abre, cierra o completa.

Comportamiento preservado:

- no hay callback durante `onHorizontalDragUpdate`;
- el callback se ejecuta una sola vez al terminar el gesto;
- se mantiene el estado `committingRight` como guard local;
- no se retrasa ni se cambia la llamada productiva al store;
- no se introduce continuidad visual entre `pendingHabits` y `completedHabits`.

## 9. Tests anadidos

`test/screens/home/habit_card_swipe_shell_test.dart` cubre ahora:

- targets exactos `closed` y `leftOpen`;
- parametros fisicos centralizados;
- thresholds y resistencia de Fase 3 intactos;
- signo y magnitud de la velocidad inicial en `SpringSimulation`;
- que crear el spring no modifica la decision del resolver;
- drag corto que asienta en `closed` sin callback;
- drag izquierdo suficiente que asienta en `leftOpen`;
- target `leftOpen == -leftActionsExtent`;
- influencia de velocidad en la evolucion inicial del spring;
- interrupcion de `settlingClosed`;
- interrupcion de `settlingLeftOpen`;
- acciones izquierdas fijas durante drag y spring;
- sincronizacion externa de `isOpen`;
- ausencia de `AnimatedContainer` como posicionador horizontal;
- guards async de acciones y `rightCommit`.

## 10. Checklist de validacion manual

Pendiente en dispositivo real:

- drag lento hacia la izquierda;
- drag lento hacia la derecha sin completar;
- flick rapido derecho;
- flick rapido izquierdo;
- apertura izquierda hasta rail completo;
- cierre desde rail abierto;
- inversion de direccion dentro del mismo gesto;
- interrupcion de spring al cerrar;
- interrupcion de spring al abrir;
- gestos repetidos con callback pendiente;
- iPhone 60 Hz;
- iPhone 120 Hz cuando este disponible;
- Android de gama media.

## 11. Parametros provisionales

Los valores del spring son una primera calibracion firme y amortiguada, no una
calibracion definitiva. Siguen pendientes de ajuste real:

- `springStiffness`;
- `springDamping`;
- `springToleranceDistance`;
- `springToleranceVelocity`;
- thresholds de commit/flick si la prueba en dispositivo lo exige;
- resistencia de overdrag si se percibe demasiado dura o permisiva.

## 12. Riesgos pendientes

Fuera de alcance y pendientes para fases posteriores:

- conflicto fino entre scroll vertical y swipe horizontal en dispositivo real;
- interaccion con `SliverReorderableList`;
- continuidad visual al mover la card de `pendingHabits` a `completedHabits`;
- keys por seccion;
- posible coordinacion futura con FX local de completado;
- haptics y accesibilidad de movimiento reducido.
