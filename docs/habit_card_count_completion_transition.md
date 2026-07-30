# Habit card count completion transition

## Previous behavior

Count habits updated their numeric value immediately through the count callback.
When the new value met the target, HomeViewData moved the habit from pending to
completed, so the pending card could disappear without the completed green
handoff used by check habits.

## Count update paths

There are two Home paths:

- Direct increment from the plus control on `HabitCardWidget`.
- Manual value entry from the count popup opened by tapping the count value.

Both paths still call `UserStateStore.setCountHabitValueForDate`.

## Crossing Rule

The transition starts only when the update crosses from pending to completed:

- `currentValue < targetValue`
- `nextValue >= targetValue`
- selected filter is `HomeHabitStatusFilter.pending`

Updates below target, decrements, unchanged values, already-completed to
completed updates, and completed-to-pending updates do not animate.

## Shared Pipeline

Count completion reuses `HomeHabitCompletionTransition`, the synthetic
`HabitCardRightCommitVisualState`, tombstones, `HabitCardStatusFeedback(kind:
completed)`, hold, collapse, and authoritative cleanup used by check tap
completion.

## Direct Control

The increment callback computes the next value before touching the store. If the
value crosses the target, Home registers the transition first and then executes
the existing count callback immediately. If it does not cross, Home executes the
callback normally.

## Manual Popup

The popup collects and validates the integer value, then closes by returning the
value. It does not update the store internally. After the dialog future
completes, Home waits for the next frame, registers the transition if the value
crosses to completed, and then calls the count callback.

## Dialog Closure

The completion animation starts only after the popup route has returned and a
frame boundary has passed, so the modal barrier and keyboard are gone before the
card exits.

## Synthetic Visual State

Count completion uses the same synthetic state as check tap completion:

- `offsetX: 0`
- `velocityX: homeHabitTapCompletionVelocityX`
- `commitProgress: 0`
- `rightRevealProgress: 0`
- `cardWidth`: measured card width
- `useTapCompletionMotion: true`

The foreground exits to `cardWidth + homeHabitStatusFeedbackExitMargin`.
That tap/count-only motion starts from rest and uses the scaled soft spring
configured by `homeHabitTapCompletionSpringStiffness` and
`homeHabitTapCompletionSpringDamping`, so the longer completed travel feels
closer to skip.

## Guards

Home keeps the per-habit transition guard, transition id cleanup, and tombstone.
The popup submit button ignores repeated OK presses while closing. A second
completion request for the same habit cannot register a second transition or run
a duplicate productive callback.

## Fast And Slow Callbacks

If the store moves the habit to completed immediately, the snapshot continues
through foreground exit, green reveal, hold, and collapse. If the callback is
slow, the pending card stays suppressed and cleanup waits for
`visualAnimationCompleted && pendingRemoved`.

## Errors

If the count callback throws after a transition was registered, Home removes the
transition and tombstone, then rethrows. The authoritative pending card can
render again with its previous value. Invalid popup input keeps the popup open
and does not register a transition or call the store.

## Already Completed Habits

Count habits that are already completed do not animate when updated to another
completed value. Decreasing back to pending keeps the existing behavior and does
not add horizontal motion.

## Filters And Reorder

Count completion snapshots are pending-only. Changing filters uses the existing
transition lifecycle. Active snapshots are static list items, preserve their
original index, suppress the real pending card, and disable reorder while active.

## Tests

Coverage is focused in:

- `test/screens/home/habit_completion_transition_test.dart`
- `test/screens/home/habit_card_widget_interaction_test.dart`
- `test/screens/home/habit_card_swipe_shell_test.dart`
- `test/screens/home/home_habit_status_filter_test.dart`
- `test/screens/home/home_selectors_schedule_test.dart`

## Manual Checklist

Verify count values below, equal to, and above target from both direct increment
and popup. Confirm cancel and invalid popup values do not update. Confirm the
popup and keyboard are gone before the green transition starts. Check first,
middle, and last cards, double OK, double increment, slow callback, filter
changes, already-completed count habits, swipe completion, skip, and reorder.
