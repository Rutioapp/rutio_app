# Supabase Phase 1 (Rutio)

This phase adds Supabase bootstrap and a clean authentication foundation
without changing the current local app flow.

## Run with Supabase env vars

Use `--dart-define` values when running:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxx
```

## Files added

- `lib/core/supabase/rutio_supabase_config.dart`
- `lib/core/supabase/rutio_supabase_client.dart`
- `lib/data/repositories/auth_repository.dart`
- `lib/data/repositories/profile_repository.dart`
- `lib/application/auth/auth_controller.dart`
- `lib/screens/auth/auth_gate.dart`
- `lib/screens/auth/sign_in_screen.dart`
- `lib/screens/auth/sign_up_screen.dart`
- `lib/screens/auth/widgets/auth_text_field.dart`
- `lib/screens/app_startup_gate.dart`
- `docs/supabase_phase_1.md`

## Files updated

- `lib/main.dart` (Supabase init + provider wiring + startup/auth routes)
- `lib/screens/splash_screen.dart` (Splash delegates the post-splash decision)
- `lib/screens/welcome_screen.dart` (Welcome completion routes to auth)
- `lib/screens/root_gate.dart` (authenticated app loading/error/Home shell)
- `lib/screens/auth/widgets/auth_primary_button.dart` (optional loading state)
- `pubspec.yaml` (`supabase_flutter` dependency)

## What this phase does

- Initializes Supabase before `runApp`.
- Reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from
  compile-time env variables.
- Adds runtime validation with a readable debug error if values are missing.
- Provides a modular auth layer:
  - `AuthRepository` for sign-up, sign-in, sign-out and auth stream.
  - `AuthController` for provider-friendly auth state and errors.
- Adds minimal iOS-first auth UI screens (`SignIn`, `SignUp`) and an `AuthGate`
  integrated at `/root` so the authenticated app is only revealed when
  Supabase has a real current user.
- Restores the startup coordinator so auth no longer bypasses Splash or the
  first-launch Welcome screen.
- Adds `ProfileRepository` for basic post-auth verification reads from
  `profiles` and `user_progress`.
- Sends `display_name` in `AuthRepository.signUpWithEmailPassword(...)`
  user metadata when the value is not empty.
- Uses `public.profiles.display_name` as the preferred display name source
  during auth/session profile sync.
- Applies the resolved display name into the existing `UserStateStore`,
  and Home reads that state reactively (no direct Supabase calls in Home UI).

## Startup flow

- Fresh install: `Splash -> Welcome -> Auth -> Home`.
- Returning unauthenticated user who has completed Welcome: `Splash -> Auth`.
- Returning authenticated user with a valid Supabase session: `Splash -> Home`.
- Sign out: `Auth`.

Welcome completion is persisted in the existing local user-state metadata, and
Home is still only shown when Supabase reports a real current user/session.

## What this phase does NOT do

- Does not migrate existing local app data or feature data to Supabase.
- Does not connect habits, journal, achievements, XP, currency, or gamification.
- Does not change Supabase schema, SQL, policies, or migrations.
- Does not connect auth data to habits, journal, achievements, XP, currency,
  or gamification.

## Recommended next phase

Phase 2: profile bootstrap sync.

- On successful auth, fetch `profiles` and `user_progress` and map them into
  existing local store boundaries.
- Keep habits/journal/achievements sync deferred until dedicated phases.

## Manual tests

- Invalid login stays on the auth screen and shows a safe error.
- Valid login creates a Supabase session and goes to the existing Home flow.
- New signup creates a user in Supabase Authentication.
- New signup goes to Home when Supabase returns a session.
- If email confirmation is enabled and Supabase returns no session, the auth
  screen shows: `Account created. Please check your email to confirm your account.`
- Sign out returns to the auth screen when `AuthController.signOut()` is used.
- App relaunch keeps a valid Supabase session and opens through `/root`.
- Fresh install without a session shows Splash, then Welcome, then Auth after
  the Welcome CTA.
- Relaunch without a session after Welcome is completed shows Splash, then Auth.

## Troubleshooting

- If login with a non-existing user still enters the app:
  - verify the app is going through `AuthGate` and that the authenticated area
    is rendered only when `Supabase.instance.client.auth.currentUser != null`.
  - confirm sign-in/sign-up handlers only reset navigation to `/root` after a
    real Supabase session/current user exists.
- If signup appears to succeed but no user is visible in Supabase:
  - verify `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` are passed with
    `--dart-define`.
  - verify `AuthRepository` is calling
    `Supabase.instance.client.auth.signUp(...)` and not local auth code.
- If signup creates a user but stays on auth:
  - email confirmation may be enabled. Confirm the account by email, then sign in.
- If auth succeeds but the screen looks stuck:
  - check debug logs for `AuthGate decision: showing app`.
  - make sure there is no old auth route left on top of `/root`.
- Run command with env values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxx
```

- In Supabase Dashboard:
  - check `Authentication -> Users` for the new account.
  - check table rows in `public.profiles` and `public.user_progress` for the
    same `user_id` (created by your existing trigger).
