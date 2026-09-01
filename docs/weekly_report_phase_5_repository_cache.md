# Weekly Report — Phase 5 repository and cache

Estado: **READY_TO_REVIEW** (migration creada, pendiente de dry-run; no aplicada).

## 1. Read API architecture

Postgres snapshot → owner-safe RPC → JSONB envelope → typed remote DTO → mapper → Phase 2 domain → repository. El cliente nunca consulta las tablas snapshot directamente.

RPCs: `get_my_weekly_report`, `get_my_latest_weekly_report`, `list_my_weekly_reports` y `refresh_my_weekly_report`. Todos derivan el usuario de `auth.uid()`, tienen grants solo para `authenticated`, y los helpers usan `SECURITY DEFINER`, `search_path = ''` y referencias calificadas.

## 2. Future Premium seam

`app_private.weekly_report_payload` es el único builder de payload. El wrapper público es el punto donde Phase 7 podrá seleccionar `summary` o `full` según entitlement. No acepta `detailLevel`, no hay entitlement falso ni RevenueCat.

## 3. Payload/version contract

El envelope expone `schemaVersion`, `metricsPolicyVersion` y `contentVersion`. El parser acepta schema 1 y rechaza cualquier versión superior con error tipado; las otras dos versiones se conservan como datos. Las tablas internas no exponen detalles de config history.

## 4. DTO/domain separation

`data/remote/remote_weekly_report.dart` valida ids, fechas, enums, arrays, counts, rates y ocurrencias. `weekly_report_mapper.dart` convierte `provisional`/`final` a `WeeklyReportStatus.provisional`/`finalized`, y no recalcula métricas.

## 5. Repository API and cache

`SupabaseWeeklyReportRepository` implementa latest, by-id, history y refresh. `SharedPreferencesWeeklyReportCache` persiste por `userId` y report id; `InMemoryWeeklyReportCache` permite tests. Se cachean latest y payloads abiertos. La cache persistente guarda el envelope completo y su timestamp de cache.

## 6. Scope and stale async protection

Cada operación captura `{userId, epoch}` mediante `WeeklyReportScopeProvider`. El resultado se descarta si cambia identidad o epoch antes de guardar/publicar. Esto evita que una respuesta tardía de A se publique en B. La invalidación de sesión debe incrementar el epoch usando el patrón de `UserStateStore`.

## 7. Fetch/offline policy

Latest/by-id intentan remoto y actualizan cache. Si falla la red, devuelven cache válida marcada `isStale`; un provisional cached conserva `refreshedAt`. Sin cache se devuelve error tipado. Un refresh fallido no elimina cache anterior. No se emiten dos valores desde un mismo Future.

## 8. Final/provisional integrity

Para el mismo report id, un `final` nunca se reemplaza por `provisional`. Entre provisionals prevalece el payload remoto aceptado por backend; la autoridad temporal es `refreshedAt` del snapshot, no la hora de escritura local. Final es inmutable en backend.

## 9. History pagination and errors

History usa cursor `beforeWeekStart`, orden descendente y límite server-side máximo 50; solo devuelve summaries. La taxonomy pública es `NotFound`, `Unavailable`, `Unauthorized`, `UnsupportedSchema`, `MalformedPayload`, `NetworkFailure`, `RefreshRejected` y `StaleScope`.

## 10. Security and tests

La migration añade static checks para ownership, auth derivation, grants, bounded limit, fixed search path, no grants directos y final refresh protection. Los tests Dart cubren parser/mapper y repository/cache (remote success, fallback, scope isolation, stale scope, final protection, refresh preservation y cursor).

## 11. Deferred Phase 6+

No se incluyen UI, Home, gráficos, navegación, Premium/RevenueCat, paywall, diary reflection, notifications, recommendations, copy, analytics, scheduling productivo ni feature exposure.

## Phase 5 Final Hardening

- Repository matrix A–K cubre éxito remoto, fallbacks final/provisional, ausencia de cache, aislamiento multiusuario, stale async en latest/refresh, refresh incremental, preservación ante error, reglas de overwrite, cursor history y schema incompatible.
- Un payload malformed o unsupported nunca entra en cache ni sustituye un valor válido.
- `final` siempre gana a provisional para el mismo report id; entre provisionals gana `refreshedAt` mayor; un final remoto reemplaza un provisional.
- Latest `null` representa “no report yet”; fallo de red representa error/fallback; payload inválido representa `MalformedPayload`.
- La persistencia incluye `cacheSchemaVersion = 1` además de `schemaVersion`; cualquier cambio incompatible invalida la entrada.
- La migration revoca `anon`, concede execute solo a `authenticated`, usa `auth.uid()`, `search_path = ''`, referencias schema-qualified y mantiene el builder interno inaccesible al cliente. El refresh solo acepta la semana local actual y delega en el generator, que protege snapshots final.
- El seam Premium futuro queda en `app_private.weekly_report_payload`: Phase 7 puede elegir summary/full y autorizarlo server-side sin parámetro de elevación del cliente ni cambios innecesarios en repository o DTO principal.
