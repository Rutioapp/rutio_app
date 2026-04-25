# Supabase Account Deletion Flow

## Why this uses an Edge Function

Deleting a Supabase Auth user with `auth.admin.deleteUser()` requires the
`service_role` key, which is highly privileged.

That key must never be shipped in Flutter/mobile code. Flutter should only use
the public anon/publishable key and call a trusted backend endpoint.

For this reason, account deletion is implemented as:

Flutter app -> Supabase Edge Function (`delete-account`) -> Admin delete user

## Security model

- Flutter calls `supabase.functions.invoke('delete-account')`.
- Edge Function reads the JWT from `Authorization` header.
- Edge Function validates the caller with `auth.getUser()` using the caller JWT.
- Edge Function deletes only the authenticated user (`user.id`).
- No arbitrary user id is accepted from request body.
- `SUPABASE_SERVICE_ROLE_KEY` is read from Edge Function secrets only.

## Data deletion strategy

- Primary strategy: delete from `auth.users`.
- User-owned data should be removed by FK `ON DELETE CASCADE`.
- Known user-owned tables:
  - `profiles`
  - `habits`
  - `habit_logs`
  - `journal_entries`
  - `user_progress`
  - `xp_events`
  - `currency_events`
  - `user_achievements`
- Global table not to delete:
  - `achievement_definitions`

## Deploy

1. Authenticate Supabase CLI and link project if needed.
2. Set secret:

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...
```

3. Deploy function:

```bash
supabase functions deploy delete-account
```

## Flutter integration summary

- `AccountRepository.deleteCurrentAccount()` invokes:
  - `supabase.functions.invoke('delete-account')`
- `UserStateStore.deleteAccount()`:
  - sets deletion/loading state
  - calls repository/service deletion flow
  - clears local state/session only after backend success
  - routes user back to Welcome flow (`/root`)
- If backend deletion fails, the app keeps the user logged in and shows:
  - EN: `Could not delete your account. Please try again.`
  - ES: `No se ha podido eliminar la cuenta. Inténtalo de nuevo.`

## Manual test checklist

### Test 1: Cancel confirmation

- Logged-in user taps Delete account.
- User cancels confirmation.
- Expected:
  - Account remains active.
  - User stays on Settings/Profile.

### Test 2: Confirm deletion

- Logged-in user confirms deletion.
- Expected:
  - Edge Function returns success.
  - User disappears from Supabase Authentication -> Users.
  - `profiles` row disappears.
  - `user_progress` row disappears.
  - App routes to WelcomeScreen.

### Test 3: Login after deletion

- Try to log in again with deleted account.
- Expected:
  - Login fails.

### Test 4: Global table integrity

- Verify `achievement_definitions` after user deletion.
- Expected:
  - Global achievements remain untouched.
