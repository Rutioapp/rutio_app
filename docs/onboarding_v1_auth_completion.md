# Onboarding V1 AUTH-3 — completion

AUTH-3 closes the persisted Phase 6 intent after AUTH-1/AUTH-2 have reached
`readyToComplete`. The remote completion is one PostgreSQL transaction. The
client only clears the draft after `completed` or
`alreadyCompletedSameOperation`.

## Schema audit

The repository's effective schema was audited from the backend patch and
forward migrations. `profiles` is keyed by `id = auth.users.id` and contains
`display_name`, `onboarding_status`, `onboarding_version`, and
`onboarding_completed_at`. `habits` is keyed by UUID and owned by `user_id`;
its canonical writable fields include `habit_type`, `target_count`,
`unit`, `reminder_enabled`, `reminder_time`, and `schedule`. The existing
schedule check accepts `daily`, `weekly`, and `timesPerWeek` (with
`weekStartsOn`), so AUTH-3 reuses that representation. No prior migration was
edited.

## Operation identity and transaction boundary

`app_private.onboarding_completion_operations` is the private ledger. Its
primary key is `operation_id`; `user_id` is also stored and constrained by the
auth user foreign key. A canonical JSONB payload contains only:

- account resolution claim;
- prepared-habit decision;
- approved profile name;
- canonical habit fields and schedule;
- remote reminder intent.

The fingerprint is `md5(canonical_jsonb::text)`, using PostgreSQL's stable
JSONB object-key ordering. Passwords, sessions, tokens, goals, pace, and UI
metadata are never sent or stored. Reservation happens before profile/habit
materialization, so concurrent calls serialize on the operation primary key.
The profile update/insert, optional habit insert, completion state, and ledger
result commit or roll back together.

The public RPC is:

```text
complete_onboarding_v1(
  p_operation_id uuid,
  p_account_resolution text,
  p_prepared_habit_decision text,
  p_profile jsonb,
  p_prepared_habit jsonb,
  p_reminder jsonb
) returns jsonb
```

It accepts no `user_id`; `auth.uid()` is the sole owner source. It is
`SECURITY DEFINER` because it must write the private ledger atomically with
public profile/habit rows. Its `search_path` is explicitly empty and all
objects are schema-qualified. Execute is revoked from `public` and `anon` and
granted only to `authenticated`; the ledger has no client grants.

## Account policy

For a missing profile, AUTH-3 creates the profile with only the approved name
and marks onboarding completed. If a profile appears after client resolution,
the backend reclassifies it as existing and never overwrites its name or
other remote data. An existing completed or incomplete profile keeps its
remote fields; AUTH-3 only advances onboarding state to completed. No generic
merge, progress/reward/statistics/diary/shop write, or reward grant occurs.

`keep` with a valid prepared habit creates exactly one owned habit. `discard`
creates zero habits and no reminder. The habit uses the real `habits` schema;
`timesPerWeek` and `weekStartsOn: 1` are passed through unchanged. Count habits
use `target_count`; check habits do not receive count configuration.

Reminder configuration has two parts. The persisted remote part is the
habit's `reminder_enabled`/`reminder_time`, written inside the transaction.
OS notification scheduling remains local and non-transactional: after a
successful result, `LocalOnboardingCompletionReconciler` uses the existing
`NotificationService`/`NotificationScheduler` with the stable returned
`habitId`. The existing deterministic notification ID and `habit:<id>`
payload make replay an upsert (cancel + schedule), not a second logical
notification. AUTH-3 does not request permission again and never schedules a
discarded habit. Granted permission schedules; denied/restricted/unknown
permission is a successful no-op. A technical scheduler failure keeps local
cleanup retryable without rolling back the remote transaction.

## Replay and recovery

The response includes `status`, `operationId`, `userId`, `habitId`,
`preparedHabitApplied`, `accountResolution`, and `completedAt`. A retry with
the same user, operation, and fingerprint returns the same result with
`alreadyCompletedSameOperation`; a changed payload or different user returns
`operation_conflict`. A failed transaction leaves no completed ledger result,
profile mutation, habit, or completion flag.

`SupabaseOnboardingCompletionAdapter` maps RPC responses and PostgREST/network
failures to the existing typed completion errors. The state machine preserves
the intent and operation ID for retryable failures, enters `completed` only on
definitive success, persists the completed draft state, and then clears it.
If the app crashes after the remote commit but before local cleanup, restart
retries the same operation and finishes local cleanup from the replay result.

The manual PostgreSQL validation plan is in
`supabase/manual_checks/onboarding_v1_auth_completion_validation.sql`. It is
not a migration and is not executed automatically.

## Verification and limits

The migration is prepared locally only; it was not pushed to a linked or
production Supabase project. Static migration assertions and focused Dart
tests cover operation identity, auth derivation, remote-wins intent shaping,
keep/discard behavior, retry state, and canonical schedules. A local
Supabase/Postgres E2E run is only valid when a local instance is available; no
remote project is used as a substitute.

Retention cleanup for the private ledger is intentionally deferred. AUTH-4 is
outside this change: no password recovery, providers, deep links, premium, or
analytics were added.
