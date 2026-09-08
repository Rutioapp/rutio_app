# Onboarding V1 AUTH-2 — email flow

AUTH-2 connects the persisted Preview draft to the existing email/password
repository. The draft keeps the same `onboardingOperationId` and stores only
the normalized, trimmed email plus the `authIntent`; the password exists only
for the duration of one submit and is cleared by the screen afterwards.

## Signup outcomes

- A signup response with a session enters authenticated account resolution.
- A signup response with a user but no session enters
  `awaitingEmailConfirmation`. The draft remains available and the app shows
  the confirmation message.
- After confirming externally, the user selects “I have confirmed it”, returns
  to login with the email prefilled, and enters the password again.
- An already-registered email remains recoverable and offers the login mode.

## Resume and routing

The confirmation step persists as `emailConfirmation`. Restarting the app
reopens Phase 6 with the same draft and operation ID. A valid session callback
is passed to the AUTH-1 state machine; duplicate callbacks are coalesced.
Bootstrap routes a pending Phase 6 draft back to onboarding even if the normal
authoritative destination would otherwise be Home. Authenticated users without
an onboarding draft keep the normal bootstrap behavior.

## Account resolution

After authentication, `ProfileRepository.fetchCurrentProfile()` is used as a
read-only, scope-checked snapshot. Missing, completed, and incomplete profiles
map to the AUTH-1 classifications. AUTH-2 does not write a profile, habit,
reminder, completion flag, or remote operation record. AUTH-3 owns the
completion handoff and draft clearing.

