# Supabase Phase 1 (Rutio)

Phase 1 introduces Supabase auth foundation and startup/auth gates while
keeping existing app features (achievements, diary, habits, notifications,
localized Settings actions) unchanged.

## Required env variables

The app expects compile-time Dart defines:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Run example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxxx
```

Do not commit real project keys.

## Current behavior

- Supabase is initialized at startup before `runApp`.
- Startup flow remains: `Splash -> Welcome/Auth/Home` depending on onboarding
  and active Supabase session.
- Settings logout stays in `Settings > Account` and keeps the existing local UX
  (confirm dialog + return to Welcome) while clearing Supabase/local session data.
- Delete account flow remains available from Settings and uses the existing
  account deletion service path.

## Scope of this phase

- Adds auth controller/repositories and auth screens (`SignIn` / `SignUp`).
- Integrates auth-aware startup and app gates.
- Syncs basic Supabase identity fields into `UserStateStore` for app usage.

Not included in this phase:

- Migrating habits/diary/achievements or other feature data to Supabase.
- Supabase schema/policy migration changes.
