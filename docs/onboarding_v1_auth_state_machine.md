# Onboarding V1 AUTH-1 — Domain contract

AUTH-1 defines the application boundary after Preview. It contains no
Supabase, provider, migration, RPC, deep-link, or UI implementation.

## State machine

`idle → ready → authenticating → authenticated → resolvingAccount →`
`readyToComplete → completing → completed`.

Email confirmation branches to `awaitingEmailConfirmation` and resumes through
`onAuthenticatedSessionAvailable`. Existing accounts with a prepared habit
branch to `awaitingPreparedHabitDecision`. Failures are represented by
`failure`; only a retryable completion failure may retry the same intent.

Commands are `signUpWithEmail`, `signInWithEmail`,
`onAuthenticatedSessionAvailable`, `choosePreparedHabit`, and `complete`.
The auth method model already reserves `emailPassword`, `google`, and `apple`;
only email commands have an AUTH-1 adapter contract.

## Account resolution and remote-wins

Resolution consumes an authenticated user id and a scope-safe
`RemoteAccountSnapshot`, including profile/onboarding status and remote user
state availability. A missing profile is `newAccount`; a completed profile is
`existingAccountCompleted`; all other existing profiles are
`existingAccountIncomplete`. A user/scope mismatch or unavailable remote state
fails closed. No UI, email, local flag, or signup-vs-login heuristic classifies
the account.

For existing accounts the remote profile and all remote data remain authoritative.
The completion intent never contains a local name/profile overwrite. Goals and
pace remain draft-only and are intentionally ignored by AUTH-1's completion
intent; incomplete-account merge policy belongs to AUTH-3.

## Completion and idempotency

`OnboardingCompletionIntent` contains `operationId`, authenticated user,
account classification, profile application policy, prepared-habit decision,
prepared habit, and its reminder. New accounts apply draft profile data and
materialize the prepared habit/reminder. Existing accounts preserve remote data;
the prepared habit/reminder are included only after explicit `keep`.

The port contract requires the same `(authenticatedUserId, operationId,
payload)` to produce the same logical result without duplicate materialization.
Different user, operation id, or material payload is a conflict. A
`retryableFailure` retries with the unchanged intent; `completed` and
`alreadyCompletedSameOperation` are successful. The draft is cleared only
after either success result. Auth acceptance, session creation, confirmation,
account resolution, and ordinary errors never clear it.

The prepared habit remains the draft payload, so its identity is stable across
CTA retries/restarts. A future RPC/ledger must enforce uniqueness by operation
id; AUTH-1 intentionally does not add that storage.

## Restart/callback/bootstrap handoff

The persisted draft keeps `onboardingOperationId`, `authIntent`, and completion
state. On restart, construct the machine from that draft, current session, and
a fresh scope-safe remote snapshot, then send the session event; do not route to
Preview from scratch or Home before completion. Duplicate session callbacks are
coalesced by user id and cannot trigger a second resolution/completion.

Bootstrap must treat an authenticated but incomplete onboarding operation as a
Phase 6 handoff, not as permission to enter Home prematurely. AUTH-2 wires the
existing `AuthController` through an adapter; AUTH-3 supplies the transactional
completion port.
