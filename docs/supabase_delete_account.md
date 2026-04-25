# Supabase delete account

## Flow

Rutio deletes accounts through a Supabase Edge Function named
`delete-account`.

The Flutter app calls:

```dart
Supabase.instance.client.functions.invoke(
  'delete-account',
  method: HttpMethod.post,
);
```

The app does not send a user id. The Edge Function reads the authenticated user
from the request JWT with `auth.getUser()`, deletes user-owned rows, then deletes
the Supabase Auth user with `admin.auth.admin.deleteUser(user.id)`.

After the function returns `{ "success": true }`, Flutter signs out, clears the
existing local user state, and routes through the existing `/root` auth gate so
the user lands on `WelcomeScreen`.

## Why service_role only lives in the Edge Function

Supabase Auth admin APIs require `SUPABASE_SERVICE_ROLE_KEY`. That key bypasses
Row Level Security and must never be embedded in Flutter, committed to the repo,
or shipped to a client device.

Only the Edge Function receives `SUPABASE_SERVICE_ROLE_KEY` as a Supabase secret.
Flutter only uses the normal anon/publishable key and the current user session.

## Deploy

Set the required secret:

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...
```

Deploy the function:

```bash
supabase functions deploy delete-account
```

## Notes

The current code references `profiles` and `user_progress` as user-owned remote
tables. Future user-owned tables should be deleted in
`supabase/functions/delete-account/index.ts` before deleting the Auth user.
