# RevenueCat Hybrid D — decisión e implementación local

## Contrato

La unidad de sincronización es `(user_id, revenuecat_app_id, environment)` y
la cola usa una clave derivada de esos tres campos. En staging solamente se
aceptan identidades ficticias presentes en `REVENUECAT_ALLOWED_USER_IDS`.
El reconciliador recibe un `user_id` explícito; no enumera clientes ni ejecuta
backfill global.

El webhook es una señal at-least-once. Una compra o renovación puede aplicar
una extensión positiva si la expiración futura es posterior; nunca reduce una
expiración. Cancelaciones, expiraciones, refunds, transferencias y payloads
ambiguos encolan reconciliación. Refund, expiración y revocación bloquean
nuevas extensiones positivas para ese scope. El acceso vigente durante una cancelación se
conserva hasta `expires_at`; la expiración real se decide con una lectura v2
completa.

La conciliación sustituye atómicamente las filas de suscripción del scope,
calcula el agregado y libera el lease. Los leases llevan token de fencing,
caducan y reintentan. Una señal negativa marca el scope para reconciliar y
bloquea extensiones positivas posteriores hasta que una lectura completa tenga
éxito. La extensión provisional además queda limitada por `provisional_until`
(24 horas como máximo desde la primera extensión), aunque la expiración
original sea posterior. Los errores 401/403 dejan la tarea para intervención
manual; 429, 5xx y timeout usan backoff exponencial.

## Archivos

- `supabase/migrations/20261013110000_revenuecat_hybrid_premium_sync.sql`
- `supabase/functions/revenuecat-webhook/index.ts`
- `supabase/functions/revenuecat-webhook/logic.ts`
- `supabase/functions/revenuecat-reconcile/index.ts`
- `supabase/functions/_shared/database.types.ts`
- `supabase/tests/revenuecat_hybrid_premium_sync_integration.sql`
- `scripts/revenuecat_hybrid_premium_sync_two_connection_test.py`

La migración `20261013100000_revenuecat_temporal_precedence_hardening.sql` queda
rechazada y no forma parte del plan de aplicación. Su contenido se conserva en
`supabase/migrations_rejected/*.sql.rejected`, fuera del directorio que
selecciona las migraciones ejecutables.

## Límites conocidos

RevenueCat v1 `request_date` es la fecha de servidor de la respuesta
CustomerInfo, no una versión de mutación. Webhooks son at-least-once y
`event_timestamp_ms` es el momento de generación del evento. Por ello Hybrid D
ofrece consistencia eventual, deduplicación local, extensión monotónica y
recuperación por scope, pero no puede demostrar un orden remoto total entre
dos lecturas concurrentes de RevenueCat. Una lectura v2 se considera válida
solo tras consumir toda su paginación.

La tabla histórica `revenuecat_entitlement_state` sigue siendo una fila por
usuario por compatibilidad con la migración 153000; el SQL rechaza mezclar app o
environment en esa fila. Es una limitación segura que debe eliminarse en una
revisión posterior si se requieren simultáneamente Sandbox y Production para
el mismo UUID.

## Verificación y staging manual

Validaciones locales: `deno check` de webhook/reconciler, tests Deno de la
lógica, tests Flutter estáticos y `git diff --check`. La integración SQL no se
ejecuta aquí por diseño. La prueba de carreras preparada usa dos conexiones
independientes y tampoco se ejecuta.

Antes de staging: revisar el diff, aplicar solamente esta migración posterior a
153000, usar un usuario Sandbox ficticio allowlisted, probar compra,
renovación, cancelación vigente, expiración, refund/transferencia, duplicado,
timeout, lease vencido y token obsoleto, y confirmar que anon/authenticated no
pueden ejecutar RPCs.
