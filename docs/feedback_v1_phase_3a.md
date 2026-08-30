# Rutio Feedback V1 - Phase 3A

## Scope

This phase connects the Feedback form to a real submit path against Supabase while keeping the existing mock inbox views intact.

## Implemented

- Added `FeedbackRepository` as the domain-facing contract for creating feedback reports.
- Added `SupabaseFeedbackRepository` for inserts into `public.feedback_reports`.
- Generated a UUID client-side before each insert.
- Built and stored a technical context payload with:
  - app version
  - build number
  - platform
  - OS version
  - device model
  - app locale
  - source route
- Updated `FeedbackFormController` to submit through the repository and return the created `FeedbackReport`.
- Updated the form screen to navigate to the success screen with the real report on success.
- Kept `MyFeedbackScreen` mock-only and removed the temporary merge of submitted data into the mock list.
- Added localized submit error messages for:
  - session expired
  - network issues
  - rejected payloads
  - generic failures

## Validation

- Added tests for:
  - technical context assembly
  - Supabase repository insert mapping
  - controller submit flow
  - form widget success and error behavior
  - report mapping from a Supabase row
- Planned verification:
  - `flutter analyze`
  - `git diff --check`

## Notes

- Screenshot upload and image picker work are intentionally not part of this phase.
- The inbox/detail views still use mock data until the later phases wire read/list/delete/update flows.
