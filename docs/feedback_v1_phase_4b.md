# Rutio Feedback V1 - Phase 4B

Date: 2026-08-30

## Goal

Make the feedback detail flow authoritative and read-only from Supabase, with screenshot delivery coming from signed storage URLs.

## Implemented

- Added `getMyFeedbackById()` to the feedback repository contract.
- Updated the Supabase feedback repository to fetch a single feedback row by id for the current user.
- Added a dedicated `FeedbackDetailController` for loading, refreshing, and retrying screenshot access.
- Updated the feedback storage service to generate signed screenshot URLs from the private bucket.
- Reworked `FeedbackDetailScreen` to:
  - render authoritative detail state from the controller
  - show loading, error, and not-found states
  - isolate screenshot failures from the rest of the detail view
  - keep edit/delete actions visible only when the loaded report is still eligible
- Added and updated feedback tests for:
  - repository detail lookups
  - signed screenshot URL generation
  - detail controller state transitions
  - detail screen loading, error, not-found, refresh, and screenshot states

## Verification

- `flutter analyze`
- `flutter test test/features/feedback`
- `git diff --check`

## Out of Scope

- No update/delete mutations for feedback detail
- No realtime subscriptions
- No UI polish pass beyond the state handling needed for Phase 4B
