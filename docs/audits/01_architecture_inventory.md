# 01 — inventario y arquitectura

Estado de cada afirmación: **VERIFICADO** = leído del checkout; **RIESGO POTENCIAL** = requiere confirmar ejecución; **NO VERIFICABLE CON EL ACCESO ACTUAL** = requiere dashboard/entorno; **NO APLICA** = no se encontró.

## Stack y límites

- **VERIFICADO:** Flutter 3.44.6 / Dart 3.12.2 en la máquina; `pubspec.yaml` declara Supabase Flutter 2.9.1, RevenueCat 10.13.2, PostHog 5.41.0 y Firebase Crashlytics 5.4.0. El lock resuelve versiones transitorias distintas.
- **VERIFICADO:** `lib/main.dart` inicializa Crashlytics, PostHog, Supabase y crea `PremiumRepository`; AuthController coordina sesión, scope local, sync y RevenueCat.
- **VERIFICADO:** hay 99 SQL en `supabase/`, incluyendo 52 migraciones y funciones RPC; no hay Edge Functions aparte de `supabase/functions/delete-account/index.ts`.
- **VERIFICADO:** `supabase/config.toml` expone `public`/`graphql_public`, `max_rows=1000`, Realtime y Storage local.
- **NO VERIFICABLE:** qué migraciones están aplicadas en el proyecto hospedado, proveedor/plan, cuotas, backups, advisors, webhooks y secretos CI.

## Flujo de datos

```text
UI Flutter
  -> stores/controllers locales -> SharedPreferences / assets
  -> Supabase Auth -> JWT -> PostgREST/RPC/Storage/RealtIme
  -> RevenueCat (identidad Supabase user id -> entitlement premium)
  -> Firebase Crashlytics / PostHog (si las flags reales están activas)
```

| Dato | Local | Supabase | Operación | Coste/abuso |
|---|---|---|---|---|
| Sesión/tokens | SDK Supabase; almacenamiento gestionado por SDK | Auth | login, refresh, logout | Auth/IP limits |
| Perfil, hábitos, logs | cache por scope | `profiles`, `habits`, `habit_logs` | CRUD/restore | DB/egress |
| Diario/moods | repositorios y cache | `journal_entries`, `diary_entries`, `daily_moods` | CRUD/sync | datos sensibles, DB |
| Progreso/economía | `UserStateStore`, caches | progreso, eventos, wallet, ledgers | sync/RPC | fraude/escrituras |
| Reportes | cache semanal | `weekly_reports` y tablas hijas | RPC read/refresh | consultas costosas |
| Compras | estado en memoria/SDK | RevenueCat; webhooks no encontrados | purchase/restore | coste tienda/RC |
| Feedback/imágenes | local temporal | tablas/Storage feedback | submit/upload | Storage/abuso |

## Puntos de entrada y confianza

1. Cliente modificado: no es confiable para `user_id`, timestamps, rewards, Premium ni límites.
2. Auth/PostgREST/RPC/Storage: deben ser la frontera de autorización.
3. RevenueCat: fuente de verdad de compra; el cliente sólo consume estado.
4. Webhooks/automation: no confirmados en el repo; requieren inventario remoto.

## Entornos

- **VERIFICADO:** existen ejemplos `dart_defines/dev.example.json` y `release.example.json`; los valores son placeholders. `supabase/config.toml` es local.
- **NO VERIFICABLE:** separación real dev/staging/prod, configuración de builds CI y allowlists de redirect del hospedado.
