# Supabase Phase 1 (Rutio)

Phase 1 introduces Supabase auth foundation and startup/auth gates while
keeping existing app features (achievements, diary, habits, notifications,
localized Settings actions) unchanged.

## Required env variables

The app expects compile-time Dart defines:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Recommended local run setup

Use a local Dart define file for daily development instead of typing both
values every run.

1. Copy the example file:

```bash
cp .env/dev.example.json .env/dev.json
```

PowerShell equivalent:

```powershell
Copy-Item .env/dev.example.json .env/dev.json
```

2. Fill `.env/dev.json` with your real project values.
3. Run the app with:

```bash
flutter run --dart-define-from-file=.env/dev.json
```

Real Supabase credentials must never be committed to Git.

### Why `SUPABASE_ANON_KEY`

Supabase currently calls this key "publishable" in some places, but this app
still reads it from `SUPABASE_ANON_KEY`. Keep using that variable name in your
local define file so no runtime code changes are needed.

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
