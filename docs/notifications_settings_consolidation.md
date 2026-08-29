# Notifications Settings Consolidation

## Before
- `ProfileScreen` exposed a direct notifications entry.
- `SettingsScreen` contained the personalized notifications block for Rutio notifications v2.
- `NotificationSettingsScreen` contained the legacy reminders and type toggles.

## After
- `SettingsScreen` now acts as the launcher for a single canonical notifications screen.
- `NotificationSettingsScreen` is the canonical screen.
- `ProfileScreen` no longer exposes a separate notifications shortcut.

## Canonical Screen
- `Perfil -> Cuenta y ajustes -> Notificaciones`
- The screen now groups:
  - `Notificaciones de Rutio` when the feature gate is enabled.
  - `Recordatorios` and the existing legacy notification toggles.

## Kept
- `NotificationService`
- `NotificationScheduler`
- `NotificationPermissionController`
- legacy notification preferences and scheduling behavior
- personalized notification controller and architecture

## Removed
- Redundant notifications block from `SettingsScreen`
- Redundant direct notifications access from `ProfileScreen`

## Feature Gate
- `RUTIO_ENABLE_PERSONALIZED_NOTIFICATIONS_V2` only hides or shows the `Notificaciones de Rutio` block.
- It does not hide the canonical notifications screen.
- Legacy reminders remain visible regardless of gate state.

## Tests
- Settings opens the canonical notifications screen.
- Gate off hides the personalized block.
- Gate on shows the personalized block.
- Legacy toggle still updates store state and sync callback.
- Personalized toggle still updates controller state.
- Back navigation returns to Settings.
