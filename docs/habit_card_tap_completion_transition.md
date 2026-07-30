# Habit card tap completion transition

## Previous behavior

Pending check habits completed from the circle/check control called the
productive completion callback directly. The store rebuild removed the pending
card immediately, so the green completed feedback used by the right-swipe path
was not visible.

## Tap versus swipe

Right swipe still owns gesture capture, thresholds, drag velocity, and commit
decision. Tap completion is UI-only orchestration in Home: it creates the same
completed transition snapshot that a right commit hands off, but starts from the
center.

## Shared visual pipeline

Both paths render `HomeHabitCompletionTransition` inside `HomeHabitsSliver`.
The real pending card is suppressed by `habitId`, the snapshot foreground exits,
`HabitCardStatusFeedback(kind: completed)` remains underneath, the existing hold
runs, then the tile collapses and asks Home to mark the visual animation as
complete.

## Tap initial state

Tap completion creates a `HabitCardRightCommitVisualState` with:

- `offsetX: 0`
- `commitProgress: 0`
- `rightRevealProgress: 0`
- `cardWidth`: the measured card width, with a safe screen-width fallback
- `velocityX: homeHabitTapCompletionVelocityX`
- `useTapCompletionMotion: true`

`homeHabitTapCompletionVelocityX` was calibrated from `1000 px/s` to
`850 px/s`, then to `600 px/s`, `300 px/s`, `80 px/s`, and finally to
`0 px/s`. The tap transition now starts from rest and uses a softer spring
(`homeHabitTapCompletionSpringStiffness = 156.25`,
`homeHabitTapCompletionSpringDamping = 26.25`) scaled for the longer completed
travel so the foreground exit feels closer to skip in absolute movement speed.
Swipe velocity still comes from `DragEndDetails` and is unchanged; hold, fade,
collapse, feedback, thresholds, and skipped timings are unchanged.

## Foreground motion

The transition tile uses the same exit margin as swipe completion. For tap, the
foreground starts centered and moves monotonically to
`cardWidth + homeHabitStatusFeedbackExitMargin`, leaving the right side. The
tap-only spring is softer than the default completed spring so the larger
center-to-exit travel does not feel faster than the skip exit.

## Green reveal

The completed feedback is mounted underneath from the first frame. At offset
zero it is covered by the foreground. As the foreground moves right, the green
surface and left tick are progressively revealed; icon opacity and scale use the
existing `HabitCardStatusFeedback` progress intervals.

## Callback order

The tap callback performs:

1. Check existing local guards.
2. Register the UI-only transition.
3. Suppress the pending card through the active transition map.
4. Execute the same productive `setHabitCompletionForKey` callback immediately.

The transition is registered before the store mutation can rebuild the list.

## Guards

`HabitCardWidget` keeps its async check-tap guard. Home keeps the per-`habitId`
transition guard, transition generation/id cleanup, and pending-card suppression.
The swipe shell still owns `actionInFlight` for swipe and tray actions. A second
tap or competing tap/swipe for the same habit receives no second transition and
does not run the productive callback again.

## Fast and slow callbacks

If the store removes the pending habit immediately, the snapshot continues to
animate, hold, and collapse. If the callback is slow and the visual sequence
finishes first, the real pending card remains suppressed and cleanup waits for
both `visualAnimationCompleted` and `pendingRemoved`.

## Errors

If the productive callback throws after a tap transition was registered, Home
removes that transition snapshot and rethrows. The authoritative pending card can
render normally again, with no leftover green feedback or displaced foreground.

## Tombstone and cleanup

Active transitions act as tombstones in the pending list. Cleanup requires:

- `visualAnimationCompleted == true`
- `pendingRemoved == true`

Old dismissals include the transition id, so they cannot remove a newer
transition for the same habit.

## Filters and reorder

Tap completion transitions only start while the selected filter is `pending` and
the habit is a boolean check habit moving to completed. Changing filters marks
visible transitions complete through the existing lifecycle. Snapshots are
static list items, keep the original index, and disable pending reorder while
active.

## Tests

Focused coverage lives in:

- `test/screens/home/habit_completion_transition_test.dart`
- `test/screens/home/habit_card_widget_interaction_test.dart`
- `test/screens/home/habit_card_swipe_shell_test.dart`
