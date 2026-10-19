# 09 — estrategia de pruebas

## Estado actual

- **VERIFICADO:** 294 archivos bajo `test/`; cubren auth, bootstrap, repositorios, migraciones estáticas, rewards/shop, weekly report, estadísticas y UI.
- **VERIFICADO:** `flutter analyze` sin errores de compilación; 34 infos/warnings.
- **VERIFICADO:** `flutter test --reporter compact` terminó con 2.454 ejecutados y 35 fallos. La salida mostró fallos al menos en feedback y otros tests de integración/UI; deben aislarse desde el log completo.
- **NO VERIFICADO:** integración real con Supabase A/B/anónimo, staging de Auth, RLS efectiva, RevenueCat sandbox, dispositivos físicos, profile/release y carga.

## Batería obligatoria

1. RLS A/B/anónimo para todas las tablas y RPC.
2. Auth: enumeración, recovery, deep links allowlist, refresh rotation, logout fallido y cambio de cuenta.
3. Integridad: doble completion, retry, offline, conflicto y timestamps.
4. Premium: free, active, expired, refund, grace, restore, account switch y cliente modificado.
5. Abuso: burst, concurrencia, payload, Retry-After, idempotency y retry storms.
6. Rendimiento: cold start, 5/50/200 hábitos, historial de años, memoria y reconexión.

Fixtures sintéticos, staging aislado y cero pruebas agresivas contra producción.
