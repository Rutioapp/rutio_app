# Weekly Report: Premium server-side y rate limiting

## Implementación preparada

- `20261012145000_revenuecat_premium_projection_stage_a.sql` crea la proyección privada, el ledger de webhooks y el registro de backfill reanudable. No cambia el acceso a Weekly Report.
- `20261012152000_revenuecat_sync_concurrency_hardening.sql` añade leases atómicos para webhook y backfill, recuperación de eventos abandonados y funciones service-only de finalización/progreso. Tampoco activa el gate.
- `20261012150000_weekly_report_premium_gate_and_rate_limit.sql` aplica el gate Premium, el límite transaccional y la protección del worker. Es ETAPA B y depende de ETAPA A.
- `supabase/functions/revenuecat-webhook/index.ts` autentica el `Authorization` header configurado en RevenueCat y consulta `GET /v1/subscribers/{app_user_id}` para obtener el estado actual del entitlement `premium`.
- `supabase/functions/revenuecat-backfill/index.ts` pagina la lista server-side de clientes RevenueCat mediante API v2, mantiene un cursor por `run_id` y sólo reconcilia IDs UUID existentes en Supabase Auth.
- La vinculación sólo acepta App User IDs que sean UUIDs canónicos y que existan en Supabase Auth. No se usan aliases arbitrarios ni valores declarados por Flutter.
- `TRANSFER` reconcilia los IDs de origen y destino sólo cuando son UUIDs válidos; cada estado se vuelve a consultar en RevenueCat.
- No se registran secretos ni payloads. La tabla de eventos guarda sólo metadatos e idempotencia.
- Una respuesta incorrecta, incompleta o temporalmente no disponible de RevenueCat falla la entrega y no se convierte silenciosamente en Free. Un 404 requiere reintento o revisión manual.
- Los webhooks duplicados procesados se aceptan sin repetir trabajo; los `failed` se pueden reclamar de nuevo; un `processing` con lease vigente devuelve HTTP 503 para conservar el reintento de RevenueCat; un lease caducado se recupera.
- El backfill conserva el cursor anterior hasta completar toda la página. Un fallo intermedio repite esa página de forma segura y no avanza el cursor parcialmente.

## Política aplicada

- Lecturas normales: sin cuota específica.
- Activación: idempotente y Premium-only.
- Refresh: tres regeneraciones exitosas por usuario y semana, con cooldown de 15 minutos.
- La fila de cuota se bloquea con `FOR UPDATE`; la cuota se incrementa después del generador. Una excepción del generador revierte la transacción y no consume cupo.
- El worker `process_weekly_report_automation` también comprueba Premium, por lo que no constituye una ruta alternativa para usuarios Free.
- Los snapshots históricos no se eliminan al expirar; el gate sólo impide leerlos mientras el entitlement no esté activo.

## Configuración manual pendiente

Configurar como secretos de las Edge Functions:

- `REVENUECAT_WEBHOOK_AUTHORIZATION`: valor exacto del Authorization header configurado en RevenueCat.
- `REVENUECAT_API_KEY`: API key secreta de RevenueCat para `GET /v1/subscribers/...`.
- `REVENUECAT_API_V2_KEY`: clave secreta RevenueCat API v2 con `customer_information:subscriptions:read`, usada únicamente por el webhook Sandbox.
- `REVENUECAT_ALLOWED_USER_IDS`: lista server-side obligatoria de UUIDs ficticios autorizados para el webhook Sandbox.
- `REVENUECAT_APP_ID`: App ID exacto enviado en el webhook.
- `REVENUECAT_ENVIRONMENT`: `PRODUCTION` o `SANDBOX`.
- `REVENUECAT_PROJECT_ID`: Project ID para el backfill API v2.
- `REVENUECAT_BACKFILL_AUTHORIZATION`: secreto independiente para invocar manualmente el backfill.

Configurar en RevenueCat un webhook HTTPS hacia `revenuecat-webhook`, seleccionando producción o sandbox según el entorno y los eventos de ciclo de vida, transferencia, expiración y restauración. Configurar `verify_jwt=false` exclusivamente para este webhook externo; la función valida su propio Authorization header. El backfill también requiere autenticación propia y una configuración equivalente para su endpoint manual. No se requiere HMAC para esta implementación; si se activa posteriormente, debe añadirse explícitamente y validarse sobre el cuerpo bruto.

## Despliegue, verificación y rollback

1. Aplicar ETAPA A y después `20261012152000` sólo en un entorno autorizado.
2. Configurar secretos, `verify_jwt=false` y comprobar manualmente App ID, Project ID y entorno.
3. Ejecutar el backfill por páginas conservando el `run_id`; repetir una página debe ser idempotente.
4. Verificar compra, restauración, expiración, transferencia, 404 y error temporal sin activar aún las RPC.
5. Aplicar ETAPA B sólo después de cerrar esas verificaciones.
6. Ejecutar pruebas negativas con Free, Premium, expirado, dos usuarios, concurrencia y refresh excesivo.
7. Observar el ledger sin exportar payloads.

Rollback ETAPA B: detener el webhook si procede y desplegar una migración posterior que retire el gate/rate limit restaurando las definiciones RPC anteriores; conservar snapshots y ledger. Rollback ETAPA A: deshabilitar funciones y revocar el RPC service-only en una migración posterior; no borrar estados, eventos ni ejecuciones de backfill.

## Limitaciones conocidas

Las pruebas Flutter estáticas pasan y se añadió `logic_test.ts` para ejecución con Deno, pero Deno no está instalado en este entorno. También se preparó `supabase/tests/revenuecat_sync_concurrency_integration.sql` para PostgreSQL aislado; no se ejecutó porque no hay PostgreSQL, `psql` ni Docker disponibles. No se ejecutaron SQL remoto, staging ni Edge Functions. La semántica transaccional de leases/concurrencia debe validarse en un entorno aislado antes de producción. La migración no modifica migraciones históricas ni las cuatro migraciones pendientes de economía/analítica.
