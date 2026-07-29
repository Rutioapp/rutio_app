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
