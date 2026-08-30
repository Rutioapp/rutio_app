# Rutio Feedback V1 - Phase 4C

Date: 2026-08-30

## Goal

Complete the functional follow-up layer for feedback submitted entries: real edit, screenshot replacement/removal, real delete, and authoritative refresh behavior in detail and my feedback views.

## Implemented

- Extended the feedback repository contract with real mutation methods:
  - `updateMyFeedback(...)`
  - `deleteMyFeedback(feedbackId)`
- Implemented the Supabase RPC-backed mutation flow in `SupabaseFeedbackRepository`:
  - `public.update_my_feedback`
  - `public.delete_my_feedback`
  - mapped no-auth, not-found, permission/no-longer-editable, network, invalid-response, and unknown failures
- Added a dedicated `FeedbackEditController` for edit-only state:
  - description
  - contactAllowed
  - current screenshot reference
  - local screenshot replacement
  - screenshot removal
  - dirty tracking
  - save locking
- Added `FeedbackEditScreen` as a static route at `/feedback/edit`.
- Updated `FeedbackDetailScreen` to:
  - open edit flow
  - confirm delete
  - execute delete through the repository
  - clean up storage best effort after successful RPCs
  - refresh authoritative state after stale/race failures
- Updated `MyFeedbackScreen` to refresh after successful edit/delete results returned from navigation.
- Kept screenshot handling authoritative through the existing signed URL infrastructure.
- Added and updated tests for repository, controllers, and widget flows covering:
  - update payloads
  - delete payloads
  - edit validation
  - keep/add/replace/remove screenshot flows
  - delete confirmation and result handling
  - stale/race behavior
  - refresh propagation to detail and my feedback

## Repository Update

- `updateMyFeedback(...)` sends only the editable fields:
  - `feedbackId`
  - `description`
  - `screenshotPath`
  - `contactAllowed`
- It does not mutate category, status, user ownership, or timestamps.
- The RPC result is mapped back into a real `FeedbackReport`.
- Functional backend errors are translated into app-level repository errors.

## Repository Delete

- `deleteMyFeedback(feedbackId)` invokes the delete RPC only.
- The RPC returns `screenshot_path` so the UI can clean storage after the authoritative delete succeeds.
- The repository maps:
  - no-auth
  - not-found
  - no-longer-editable / permission-denied
  - network
  - invalid response
  - unknown failures

## Edit Controller

- Introduced a dedicated controller instead of forcing create and edit into one state machine.
- Initial state comes from the authoritative `FeedbackReport`.
- Category is visible but not editable.
- Dirty state tracks:
  - description changes
  - contact switch changes
  - screenshot selection/removal
- Save flow respects the required ordering:
  - keep existing screenshot path when unchanged
  - upload new screenshot first when needed
  - call the update RPC
  - clean up the new upload on RPC failure
  - clean up the old screenshot after a successful replace/remove when possible

## Keep Screenshot

- If the user only edits text or contact permission, the existing screenshot path is preserved.
- No storage upload or delete is performed in that case.

## Add Screenshot

- When there is no existing screenshot and the user selects one:
  - the image is processed
  - uploaded to private storage
  - referenced by the update RPC
- If the RPC fails, the newly uploaded object is removed best effort.

## Replace Screenshot

- The replacement flow follows the required contract:
  - upload new
  - update RPC with new path
  - clean up old path after success
- If the RPC fails after the upload succeeds, the new object is cleaned up and the old screenshot remains referenced.
- If the old cleanup fails after a successful save, the mutation still counts as success.

## Remove Screenshot

- Removal is handled by sending `screenshotPath = null` to the update RPC.
- Only after the RPC succeeds is the old screenshot removed from storage.
- If storage cleanup fails, the DB state remains authoritative and successful.

## Compensations

- New upload succeeds but RPC fails:
  - remove new upload best effort
  - keep old screenshot untouched
- RPC succeeds but old cleanup fails:
  - keep the successful DB change
  - log the cleanup issue only
- Delete RPC succeeds but storage cleanup fails:
  - feedback remains deleted
  - storage issue is best-effort only

## Delete Flow

- The user must confirm deletion explicitly.
- Delete is only available for authoritative `submitted` reports.
- Flow:
  - confirm
  - call `delete_my_feedback`
  - remove screenshot from storage if the RPC returned a path
  - close detail and return a delete result to the parent flow
- If the report became non-editable before delete, the screen refreshes authoritative state and does not pretend success.

## Race Handling

- The detail and edit screens treat stale `submitted` state as a real race.
- On a no-longer-editable response:
  - the report is refreshed authoritatively
  - edit/delete actions are cleared by the refreshed state
  - the UI shows the localized no-longer-editable message
- No automatic retry is performed.

## Refresh Detail / My Feedback

- Successful edit returns the authoritative `FeedbackReport` from the RPC and refreshes detail state.
- Successful edit/delete results are propagated back to `MyFeedbackScreen`.
- `MyFeedbackController.refresh()` is triggered after mutation results so the list remains current without realtime.

## Tests

- Added repository coverage for update and delete RPC flows.
- Added controller and widget coverage for the new edit screen and delete flow.
- Updated existing feedback tests so they can exercise the new mutation contract.

## Verification

- `flutter analyze`
- `flutter test test/features/feedback`
- `git diff --check`

## Manual Checklist

- Edit submitted description and confirm the saved text matches Supabase.
- Edit contact permission and confirm the saved flag matches Supabase.
- Add a screenshot to a submitted report without a screenshot and verify the new storage path.
- Replace an existing screenshot and verify the old object is removed after success.
- Remove an existing screenshot and verify the DB path becomes null.
- Delete a submitted report with screenshot and confirm the row disappears and the object is cleaned up.
- Reproduce a submitted -> in_review race from Supabase Studio and confirm edit/delete are blocked after refresh.

## Risks

- Storage cleanup after a successful DB mutation is best effort by design, so orphaned objects can still exist if a cleanup call fails.
- The UI intentionally favors authoritative DB state over optimistic local reconstruction.
- No backend migrations were added in this phase.

## Boundary With Phase 5

- Phase 4C ends at functional edit/delete and authoritative synchronization.
- No UI polish pass was added.
- No realtime, email, admin, analytics, or new V1 scope was introduced.
- Phase 5 should start from the stabilized mutation flows and focus only on the next agreed scope.
