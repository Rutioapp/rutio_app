# Personalized Notifications Phase 6C

## Goal

This phase adds a single product orchestration layer for personalized notifications.
The orchestrator is the only place that decides when to reconcile, clean up, or skip
the personalized notification system.

## What Is Enabled

- Typed reconciliation reasons for bootstrap, foreground, mutation, permission, and logout flows.
- A typed activation policy that defaults to OFF.
- Single-flight coordination with reason coalescing per user scope.
- Stale-scope protection so work is discarded when the active user changes.
- Logout cleanup that removes owned personalized notification state before the local scope is cleared.

## Integration Points

- App bootstrap readiness.
- App foreground resume.
- Logout cleanup.
- Habit creation, habit updates, habit deletion, completion, and skip changes.
- Notification preference changes stored in user-scoped state.

## What Is Not Included

- Settings UI for personalized notification control.
- Remote config wiring.
- Supabase campaign logic.
- Firebase push orchestration.
- Any change to legacy habit reminder behavior.

## Default Behavior

Personalized notifications remain disabled unless the build explicitly enables them.
Legacy habit reminders stay unchanged.

## Verification

- Analyzer and formatter should pass after the 6C wiring is complete.
- Tests should cover disabled-by-default behavior, logout cleanup, coalescing, and mutation observer forwarding.
