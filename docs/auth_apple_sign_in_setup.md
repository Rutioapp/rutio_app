# AUTH-6 — Sign in with Apple (native iOS)

## Implemented contract

- Native iOS only; Android Apple CTA and Apple web/OAuth are intentionally absent.
- `sign_in_with_apple: ^8.2.0`, Supabase `signInWithIdToken` with `OAuthProvider.apple`.
- A fresh raw nonce is generated per attempt, SHA-256 hashed for Apple, and the raw nonce is sent to Supabase. Neither is persisted or logged.
- Apple name is not copied into Rutio profiles. The onboarding draft name and remote profile remain authoritative. Private relay emails are accepted unchanged.
- Existing onboarding ownership, account resolution, remote-wins behavior, idempotent completion, Bootstrap routing, logout, and delete-account flows are reused.
- Services ID: NONE for this native-only flow. Apple client secret/P8: NONE. Secret rotation: NONE. No Apple secrets belong in this repository.

## Apple Developer setup

1. Open Apple Developer → Certificates, Identifiers & Profiles → Identifiers → App IDs.
2. Open the existing App ID `com.rutio.app` (do not create a duplicate).
3. Enable **Sign in with Apple** and save. Team ID is `7LKQG9DY6W`; expected App ID is `7LKQG9DY6W.com.rutio.app`.
4. Refresh provisioning profiles, or let Xcode Automatic Signing regenerate them. No certificates or keys are committed.
5. In Supabase Dashboard → Authentication → Providers → Apple, enable Apple and configure the native iOS App ID/audience as `com.rutio.app`. Do not configure a web Services ID or OAuth callback for this native flow unless the dashboard explicitly requires it.
6. Preserve the existing Associated Domains entitlement (`applinks:www.rutioapp.com`). The native token exchange does not use the deep-link callback.

## iPhone QA

Test login, logout/login again, new onboarding, cancellation, Hide My Email, kill/reopen, and an existing Rutio account used from onboarding. Verify one completion/operation and no duplicate prepared habit. To repeat first authorization, revoke Rutio in the Apple ID device settings under **Sign in with Apple**, then retry; this is optional QA only.

Before Apple Developer configuration and real iPhone QA, **Ready for production Apple = NO**. Static Windows validation and code readiness do not replace device/provider QA.
