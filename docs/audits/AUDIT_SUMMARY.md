# Rutio — resumen ejecutivo de auditoría

Fecha: 2026-10-12. Alcance: auditoría local, read-only, sobre el checkout actual. No se aplicaron migraciones, cambios remotos, rotaciones ni commits.

## Estado

**NO LISTO PARA DECLARAR PRODUCCIÓN SEGURA.** Hay controles sólidos en varias rutas de sesión, RLS y operaciones idempotentes, pero no existe acceso al proyecto Supabase/RevenueCat/Firebase productivo para comprobar que el estado desplegado coincide con el repositorio. Además, el suite completo de Flutter terminó con 2.454 casos ejecutados y 35 fallos; `flutter analyze` termina sin errores, con 34 infos/warnings.

## Hallazgos por prioridad

| Prioridad | Confirmados localmente | Riesgos potenciales | No verificables remotamente |
|---|---:|---:|---:|
| P0 | 0 | 0 | 0 |
| P1 | 2 | 4 | 4 |
| P2 | 2 | 6 | 5 |
| P3 | 0 | 4 | 3 |

Los conteos son agrupaciones de hallazgos, no CVEs. El detalle y la evidencia están en `02_security_findings.md`.

## Cinco acciones prioritarias

1. Obtener un snapshot de metadatos del proyecto Supabase desplegado y ejecutar una matriz A/B/anónimo contra RLS; no confiar sólo en SQL fuente.
2. Cerrar las escrituras directas de progreso/economía (`user_progress`, `xp_events`, `currency_events`, `user_achievements`) o demostrar que están protegidas en el entorno real por RPC/privilegios.
3. Implementar un gate de Premium en servidor para cualquier recurso Premium; el gate actual es de cliente y la propia migración lo describe como futuro.
4. Aislar y corregir los 35 fallos del suite antes de release; conservar una prueba de regresión para logout, scopes, sincronización y UI.
5. Verificar material de firma/configuración fuera del repositorio, activar observabilidad de release con consentimiento y definir backup restore/RPO/RTO.

## Evidencia principal

- `pubspec.yaml`: Flutter/Dart, Supabase, RevenueCat, PostHog y Crashlytics están integrados como dependencias.
- `lib/core/supabase/rutio_supabase_client.dart:35-42`: Supabase usa URL y clave pública por `--dart-define` y desactiva autodetección de sesión en URI.
- `supabase/sql/supabase_backend_phase_9_schema_patch.sql:449-469,527-541,614-628,725-745`: el contrato fuente permite a `authenticated` insertar/actualizar varias entidades de progreso/economía propias.
- `lib/features/premium/domain/premium_access_policy.dart:14-19`: autorización Premium local basada sólo en `state.isPremium`.
- `supabase/migrations/20260901150000_weekly_report_read_api.sql:121-122`: el límite de entitlement en el servidor queda descrito como futuro.
- `supabase/config.toml:129-159`: límites Auth locales; no prueban límites del proyecto hospedado ni de tablas/RPC.
- `git status --short`: existen copias no versionadas de `google-services.json`; `upload-keystore.jks` existe localmente y está ignorado, no aparece como tracked.

## Coste y complejidad

El primer lote puede resolverse con SQL/RLS/RPC y pruebas aisladas, sin Redis ni gateway adicional. Coste de infraestructura: indeterminado hasta conocer plan/cuotas Supabase, volumen y uso RevenueCat/PostHog. No se recomienda añadir infraestructura de rate limiting antes de medir.

## Revisión manual del propietario

Confirmar proyecto/entorno desplegado, políticas y grants efectivos, Security Advisor/Performance Advisor, proveedores Auth, claves y rotación, RevenueCat webhooks/entitlement, Crashlytics/PostHog release flags, backups restaurables, CI/CD y firma de apps. No pegar secretos en el chat.
