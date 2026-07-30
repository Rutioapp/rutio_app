# Habit Card Status Feedback - Phase 6B

## Scope

Phase 6B adds UI-only status feedback for two pending-card transitions:

- Pending to completed, triggered by the right swipe commit.
- Pending to skipped, triggered by tapping `Saltar` in the left action rail.

This phase does not add the single filtered list, the three-dot menu, new store state, repository changes, global overlays, `AnimatedList`, or `SliverAnimatedList`.

## Shared Transition Model

Home keeps the transition authority inside `_HomeScreenState` by extending the existing temporary transition model with `HomeHabitStatusFeedbackKind`.

The model still stores the snapshot, original pending index, initial horizontal offset, card width, velocity, `visualAnimationCompleted`, and `pendingRemoved`. The cleanup rule remains:

```text
visualAnimationCompleted && pendingRemoved
```

While a transition exists for a habit id, the real pending card with that id is suppressed. This tombstone behavior is shared by completed and skipped transitions.

## Completed Flow

The completed flow preserves Phase 5B behavior:

```text
right drag commit -> foreground card continues right -> fixed green completed feedback underneath -> hold -> vertical collapse -> authoritative cleanup
```

The foreground card starts from the right commit offset reported by `HabitCardRightCommitVisualState` and exits to `cardWidth + 24`.

## Skipped Flow

The skip action now reports `HabitCardSkipVisualState` before the product callback runs:

- `offsetX`
- `velocityX`
- `cardWidth`
- `revealProgress`

The shell does not close the card back to center before invoking `onSkip`. The foreground card starts from the open rail offset and exits left to `-(cardWidth + 24)`.

```text
left rail open -> tap Saltar -> foreground card exits left -> fixed skipped feedback underneath -> hold -> vertical collapse -> authoritative cleanup
```

Skipped feedback intentionally uses a separate amber/camel visual treatment and the skip icon, not the completed green treatment.

## Feedback Widget

`HabitCardStatusFeedback` is visual-only and reusable. It is wrapped with `IgnorePointer`, exposes one controlled semantic label, and does not include callbacks, swipe shells, reorder listeners, or data mutations.

## Regression Guardrails

Completed to pending remains unchanged: unchecking a completed card does not create a status transition, does not generate a snapshot, and stays centered because right commit completion is disabled for completed cards.

Callback errors remove the temporary transition and rethrow so the UI does not leave a stale tombstone behind.

## Fase 6B.1 - Calibracion pastel y ritmo visual

### Objetivo

La fase 6B.1 es un pulido exclusivamente visual y temporal. No cambia callbacks,
lifecycle, tombstones, store, negocio, rewards, persistencia, sync ni Supabase.

### Colores anteriores

- Completed background: `CupertinoColors.systemGreen`.
- Skipped background: `#C28A2B`.
- Icono/texto: blanco.

Estos tonos eran correctos semanticamente, pero demasiado saturados para un
feedback breve dentro de la Home.

### Colores nuevos

Completed:

- background: `#BCD8C0`;
- border: `#94B89D`;
- icon: `#284A32`.

Skipped:

- background: `#D0BAA2`;
- border: `#B58F6D`;
- icon: `#503B2B`.

Los colores se centralizan en `HabitCardStatusFeedback`. Se reutilizan
`IosCornerRadius.card` e `IosSpacing` para forma y espaciado. No se anaden tokens
globales porque el ajuste pertenece al feedback local de presentacion.

### Contraste y accesibilidad

Completed y skipped no dependen solo del color: cada estado mantiene un icono
distinto. La palabra visible se elimina para que el feedback sea mas limpio; la
semantica sigue exponiendo una sola etiqueta controlada por feedback y el widget
permanece bajo `IgnorePointer`. Los tonos de foreground son oscuros y apagados
para conservar legibilidad sobre fondos pastel algo mas presentes.

### Timings anteriores

- Hold compartido: `160 ms`.
- Collapse compartido: `220 ms`.
- Spring de salida: mass `1`, stiffness `720`, damping `64`.
- Fade: desde el `55%` final del collapse.

### Timings nuevos

Completed:

- hold: `100 ms` (antes `230 ms`, calibrado despues a `160 ms`);
- collapse: `300 ms`.

Skipped:

- hold: `210 ms`;
- collapse: `290 ms`.

El spring de salida conserva `velocityX`, pero se suaviza solo para la
transicion de estado:

- mass: `1`;
- stiffness: `400`;
- damping: `42`.

El spring principal del swipe no cambia.

### Hold, collapse y fade

El hold empieza cuando el foreground ya ha salido segun la simulacion horizontal.
Durante el hold, el feedback conserva altura completa y opacidad completa. El
collapse usa `Curves.easeInOutCubic`, de `heightFactor 1 -> 0`, para que las
cards inferiores asciendan de forma progresiva.

El fade empieza tarde, en el `62%` del collapse, y termina junto con
`heightFactor 0`. Esto evita que el feedback se perciba como un flash.

### Diferencias completed/skipped

Completed usa verde pastel con tick oscuro. Skipped usa camel pastel con icono
de skip oscuro. Comparten lenguaje visual, pero se diferencian por color, borde,
icono y direccion de salida del foreground.

### Tests actualizados

`test/screens/home/habit_completion_transition_test.dart` cubre:

- colores pastel nuevos;
- ausencia de los fondos intensos anteriores;
- foreground de icono/texto con contraste;
- timings 6B.1 centralizados;
- hold con altura y opacidad completas;
- collapse progresivo;
- fade tardio;
- salida izquierda de skipped sin volver al centro;
- tombstone y cleanup existentes.

### Reduce Motion futuro

Cuando exista una politica de Reduce Motion, esta transicion deberia evitar el
spring prolongado y sustituirse por feedback breve, fade simple y cambio de
estado directo, manteniendo callbacks y tombstones.

### Checklist manual

Completed:

- swipe lento;
- flick rapido;
- primera card;
- card intermedia;
- ultima card;
- callback lento;
- dos completados seguidos;
- iPhone 60 Hz;
- iPhone 120 Hz;
- Android medio.

Skipped:

- rail recien abierto;
- rail completamente abierto;
- dos skips seguidos;
- callback lento;
- lista con scroll;
- card primera/intermedia/ultima.

Preguntas de calibracion en dispositivo:

- el color se ve suficientemente suave;
- el feedback se distingue del fondo general;
- el tick/icono se entiende;
- la salida no parece demasiado lenta;
- el hold se percibe sin detener el ritmo;
- el colapso se siente fluido;
- la transicion completa no se hace pesada.
