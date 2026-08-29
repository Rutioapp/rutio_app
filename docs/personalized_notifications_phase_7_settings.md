# Personalized Notifications Phase 7

## Goal

Add a dedicated settings surface for Rutio's personalized notifications without
changing the legacy habit-reminder experience.

## What Was Implemented

- A new personalized notifications settings section on the profile settings
  screen.
- A scoped settings controller backed by `NotificationPreferencesStore`.
- Immediate persistence for:
  - master enable / disable
  - intensity preset
  - reference anchor time
- Permission-aware enable flow with recovery-sheet handling when the OS blocks
  scheduling.
- A clean separation from the existing habit-reminder settings screen.
- Locale strings for English and Spanish.

## Product Decisions

- iOS-first behavior remains the priority.
- The feature stays behind `RUTIO_ENABLE_PERSONALIZED_NOTIFICATIONS_V2`.
- The new UI is hidden unless the feature gate is enabled.
- No Supabase or analytics work was introduced.
- Legacy habit-reminder behavior was left untouched.

## Orchestration

- Preference changes persist first.
- When the feature gate is enabled, the controller requests a reconciliation
  with `preferencesChanged` after successful updates.
- The store-backed preferences resolver now reads the personalized notification
  store directly instead of inheriting legacy notification toggles.

## Validation

Recommended checks for this phase:

- `dart format` on touched files.
- `flutter analyze --no-pub` on the modified notification and settings files.
- Targeted `flutter test --no-pub` coverage for the new controller tests.

