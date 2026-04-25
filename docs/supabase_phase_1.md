# Supabase Phase 1 - Auth Notes

- Logout is available from `Settings > Account` as `Cerrar sesión / Log out`.
- Logout uses the app auth session state sign-out flow and returns the user to `WelcomeScreen`.
- After logout, Home/Profile is not accessible until the user authenticates again.
- Delete account remains visible in Settings but is not implemented in this phase.
