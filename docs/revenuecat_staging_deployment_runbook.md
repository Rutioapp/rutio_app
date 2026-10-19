# RevenueCat — runbook de despliegue controlado en Supabase Staging

Fecha de revisión: 2026-10-14
Rama: `security/economy-event-write-hardening`
Destino exclusivo: Supabase Staging `fuibgptjhsjvenjdxtqt`
Proyecto RevenueCat compartido: `projf42bbcd1`

## Veredicto

**BLOCKED** para el despliegue inmediato de las Edge Functions.

El código de las tres funciones está implementado y preparado para un piloto Sandbox aislado, pero faltan comprobaciones remotas de preflight, configuración exclusiva de Staging y una decisión operativa para ejecutar el reconciliador. No se ejecutó ningún comando remoto, migración, despliegue ni backfill.

## 1. Estado real

### Webhook

`supabase/functions/revenuecat-webhook/index.ts` implementa:

- POST autenticado mediante `REVENUECAT_WEBHOOK_AUTHORIZATION`, comparado en tiempo constante.
- Validación de `api_version`, evento, `app_id`, entorno Sandbox, tipo conocido y límite de payload.
- Allowlist obligatoria de identidades UUID ficticias mediante `REVENUECAT_ALLOWED_USER_IDS`.
- Asociación directa `RevenueCat app_user_id == UUID de Supabase`; transferencias se clasifican y se rechazan si contienen identidades no permitidas.
- Ledger idempotente mediante `claim_revenuecat_webhook_event` y finalización con estados `processed`, `ignored` o `failed`.
- Cola Hybrid D mediante `enqueue_revenuecat_premium_sync`.
- Extensión positiva provisional para eventos de compra/renovación, con expiración remota y reconciliación obligatoria.
- Rechazo de producción: la función exige `REVENUECAT_ENVIRONMENT=SANDBOX` y valida `event.environment` y `app_id`.
- Respuestas 401/403/422/500/503 que permiten a RevenueCat reintentar cuando el evento está en curso o el ledger/procesamiento falla.

Los eventos negativos no escriben directamente Free: se encolan con prioridad elevada para que el reconciliador consulte el estado autoritativo. Esto cubre cancelación, expiración, reembolso, billing issue y pausa cuando el evento está en la lista conocida.

### Reconciliador

`supabase/functions/revenuecat-reconcile/index.ts` implementa:

- POST autenticado con secreto propio y allowlist de UUIDs.
- Claim de una entrada concreta de `revenuecat_premium_sync_queue` con lease/fencing mediante `claim_revenuecat_premium_sync`.
- Consulta de suscripciones Sandbox en API v2 usando `REVENUECAT_API_V2_KEY` y `REVENUECAT_PROJECT_ID`.
- Paginación de clientes, suscripciones, entitlements y productos, con límites, detección de ciclos y validación de origen `api.revenuecat.com`.
- Aplicación transaccional mediante `apply_revenuecat_v2_reconciliation` y liberación del lease mediante `complete_revenuecat_premium_sync`.
- 401/403 como error permanente; otros errores, incluidos 429/5xx, se devuelven como reintentables y quedan en la cola con backoff SQL.

No existe un worker batch ni un job que descubra automáticamente todas las entradas pendientes. La función necesita recibir un `user_id`; por tanto, la reconciliación automática no está configurada todavía.

### Backfill

`supabase/functions/revenuecat-backfill/index.ts` implementa un proceso manual reanudable con cursor, lease, API v2 de clientes y API v1 de subscriber details. Sólo actualiza clientes cuyo ID sea un UUID existente en Supabase Auth. No es necesario para el piloto Staging si se usa un UUID ficticio con evento Sandbox; debe permanecer sin invocar hasta que exista una necesidad concreta.

### Configuración local

- `supabase/config.toml` fija Deno 2, pero no contiene bloques `[functions.*]` ni `verify_jwt`.
- El destino del CLI no está fijado por el repositorio; los comandos de este documento incluyen siempre `--project-ref fuibgptjhsjvenjdxtqt`.
- Como las funciones validan su propio `Authorization`, el despliegue debe usar `--no-verify-jwt` para las tres funciones. No confiar en una configuración implícita.

## 2. Migraciones y dependencias

La cadena relevante que el preflight remoto debe confirmar es:

1. `20261012145000_revenuecat_premium_projection_stage_a.sql` — tablas, ledger y backfill base.
2. `20261012152000_revenuecat_sync_concurrency_hardening.sql` — leases del ledger/backfill.
3. `20261012153000_revenuecat_lease_guarded_projection.sql` — fencing, reconciliación y proyección protegida.
4. `20261013110000_revenuecat_hybrid_premium_sync.sql` — Hybrid D: cola por identidad, señal webhook y reconciliación v2.
5. `20261013120000_revenuecat_hybrid_premium_sync_renewal_fix.sql` — corrección de expiración y ventana provisional.

La migración `20261012150000_weekly_report_premium_gate_and_rate_limit.sql` es una etapa separada. Declara dependencias de la etapa A y cambia la autorización de Weekly Report; no debe aplicarse junto con el despliegue de funciones sin comprobar primero que el esquema de Weekly Report y sus funciones existen en Staging. Su aplicación no es necesaria para probar la tubería de webhook/cola/reconciliación, aunque sí es necesaria para activar el gate Premium del producto.

`supabase/migrations_rejected/20261013100000_revenuecat_temporal_precedence_hardening.sql.rejected` queda fuera de cualquier plan y no debe aplicarse.

## 3. Secretos y variables

No se muestran valores. Todos deben configurarse sólo en el proyecto Staging.

| Secreto | Función | Origen | Esperado en código | Obligatorio piloto |
|---|---|---|---|---|
| `REVENUECAT_WEBHOOK_AUTHORIZATION` | webhook | secreto del webhook Sandbox de RevenueCat | sí | sí |
| `REVENUECAT_RECONCILE_AUTHORIZATION` | reconcile | secreto operativo independiente generado para Staging | sí | sí |
| `REVENUECAT_BACKFILL_AUTHORIZATION` | backfill | secreto manual independiente | sí | no |
| `REVENUECAT_API_V2_KEY` | reconcile | RevenueCat API v2, permiso de lectura de suscripciones | sí | sí |
| `REVENUECAT_API_KEY` | backfill | RevenueCat API v1/v2 según endpoint utilizado | sí | no |
| `REVENUECAT_PROJECT_ID` | reconcile/backfill | RevenueCat | sí | reconcile sí |
| `REVENUECAT_APP_ID` | las tres | App de Staging en el proyecto RevenueCat compartido | sí | sí |
| `REVENUECAT_ENVIRONMENT` | las tres | valor literal `SANDBOX` | sí | sí |
| `REVENUECAT_ALLOWED_USER_IDS` | webhook/reconcile | UUIDs ficticios de Staging, separados por espacios o comas | sí | sí |
| `SUPABASE_URL` | las tres | URL interna proporcionada por Supabase Edge Runtime | sí | sí |
| `SUPABASE_SERVICE_ROLE_KEY` | las tres | secreto gestionado por Supabase | sí | sí |

Comando preparado, no ejecutado:

```powershell
supabase secrets set --project-ref fuibgptjhsjvenjdxtqt `
  REVENUECAT_WEBHOOK_AUTHORIZATION="<STAGING_WEBHOOK_SECRET>" `
  REVENUECAT_RECONCILE_AUTHORIZATION="<STAGING_RECONCILE_SECRET>" `
  REVENUECAT_BACKFILL_AUTHORIZATION="<STAGING_BACKFILL_SECRET>" `
  REVENUECAT_API_V2_KEY="<STAGING_RC_V2_READ_KEY>" `
  REVENUECAT_API_KEY="<STAGING_RC_API_KEY>" `
  REVENUECAT_PROJECT_ID="projf42bbcd1" `
  REVENUECAT_APP_ID="<STAGING_REVENUECAT_APP_ID>" `
  REVENUECAT_ENVIRONMENT="SANDBOX" `
  REVENUECAT_ALLOWED_USER_IDS="<FICTIONAL_STAGING_UUIDS>"
```

`SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` son variables reservadas disponibles en Edge Functions; no se deben imprimir ni copiar al documento.

## 4. Configuración del webhook compartido

RevenueCat usa un proyecto compartido, por lo que el aislamiento se basa en cuatro barreras simultáneas:

1. URL apuntando sólo al proyecto Staging.
2. `REVENUECAT_APP_ID` igual al App ID de Staging.
3. `REVENUECAT_ENVIRONMENT=SANDBOX`; cualquier evento Production se rechaza.
4. `REVENUECAT_ALLOWED_USER_IDS` limitado a UUIDs ficticios.

El webhook de Staging no debe configurarse como destino de eventos Production. Si la configuración compartida de RevenueCat no permite seleccionar exclusivamente Sandbox y el App de Staging, no hay GO: hay que mantener el endpoint sin activar hasta disponer de esa separación. No se debe reutilizar el secreto ni la URL de Producción.

Para el webhook externo, `verify_jwt=false` es necesario porque la autenticación es el header propio de RevenueCat. La validación propia sigue siendo obligatoria. Para reconcile y backfill también se necesita desactivar el JWT gestionado por Supabase, ya que ambos usan secretos `Authorization` propios.

## 5. Comandos de despliegue preparados

No ejecutar hasta cerrar el GO/NO-GO y completar el preflight remoto.

```powershell
supabase functions deploy revenuecat-webhook --project-ref fuibgptjhsjvenjdxtqt --no-verify-jwt
supabase functions deploy revenuecat-reconcile --project-ref fuibgptjhsjvenjdxtqt --no-verify-jwt
supabase functions deploy revenuecat-backfill --project-ref fuibgptjhsjvenjdxtqt --no-verify-jwt
```

Orden operativo:

1. Confirmar manualmente en Dashboard/SQL Editor que el proyecto es Staging y que el marcador de Staging está presente.
2. Ejecutar sólo el SQL read-only `supabase/tests/revenuecat_hybrid_premium_sync_staging_preflight.sql` con el nombre de base de datos esperado; no usar `db push`, `link`, `reset` ni `migration repair`.
3. Verificar que la cadena Hybrid D y los privilegios `service_role` están completos.
4. Configurar secretos de Staging.
5. Desplegar webhook y reconciliador; dejar backfill sin desplegar o desplegarlo sin invocarlo según la política operativa del piloto.
6. Configurar el webhook Sandbox sólo después de validar URL, App ID, entorno y allowlist.
7. Ejecutar la prueba sintética y después la prueba Sandbox real, si existe una suscripción Sandbox.

## 6. Reconciliación programada

La solución actualmente implementada no ofrece un endpoint batch: `revenuecat-reconcile` recibe un UUID. Para el piloto más pequeño y seguro, ejecutar el reconciliador manualmente para el UUID ficticio recién encolado:

```powershell
$headers = @{ Authorization = "Bearer <STAGING_RECONCILE_SECRET>" }
$body = @{ user_id = "<FICTIONAL_STAGING_UUID>" } | ConvertTo-Json
Invoke-RestMethod `
  -Method Post `
  -Uri "https://fuibgptjhsjvenjdxtqt.supabase.co/functions/v1/revenuecat-reconcile" `
  -Headers $headers -ContentType 'application/json' -Body $body
```

Para automatizarlo sin un servicio adicional, la opción compatible con Supabase es un job `pg_cron`/`pg_net` que invoque el endpoint para una lista cerrada de UUIDs ficticios y mantenga sus credenciales en Vault. Eso aún no está implementado ni validado en este repositorio; no debe activarse como parte de este despliegue. Un job global no es seguro porque la cola Hybrid D es identity-scoped y el reconciliador no reclama un lote.

## 7. Pruebas de aceptación

### Sintéticas, sin suscripción activa

1. Generar un `event.id` ficticio, `app_id` de Staging, `environment=sandbox`, `app_user_id` igual a un UUID allowlisted y entitlement `premium`.
2. POST autenticado al webhook y verificar respuesta aceptada.
3. Verificar en SQL Editor que existe un ledger del evento y una entrada de `revenuecat_premium_sync_queue` para el scope correcto.
4. Repetir el mismo evento y comprobar respuesta duplicada sin segunda aplicación.
5. Invocar manualmente reconcile para el UUID y observar el resultado de API v2. Esta prueba requiere que RevenueCat devuelva una respuesta válida; no se debe asumir que existe una suscripción.
6. Verificar `revenuecat_entitlement_state`, `revenuecat_premium_subscription_state` y estado de cola sin exponer datos privados.
7. Simular o probar un fallo temporal y comprobar lease, `attempt_count`, `next_at` y retry.
8. Limpiar sólo filas y UUIDs ficticios de Staging, dejando cero residuos.

### Sandbox real

Requiere una suscripción Sandbox creada deliberadamente para el App de Staging y un UUID ficticio allowlisted. Debe cubrir compra inicial/renovación, expiración o cancelación y reembolso si RevenueCat permite generarlos en el entorno Sandbox. La verificación Premium final debe hacerse desde Supabase, no sólo desde el cliente.

## 8. Rollback

- Desactivar el webhook Sandbox en RevenueCat o sustituirlo por una configuración inactiva de Staging.
- Quitar los tres deployments de Staging mediante la operación de gestión de funciones aprobada por el operador; no tocar Producción.
- Revocar/rotar únicamente los secretos de Staging.
- No borrar tablas ni aplicar migraciones inversas automáticamente.
- Marcar o limpiar entradas ficticias fallidas sólo en Staging, conservando el ledger necesario para diagnóstico.
- Si el gate Weekly Report aún no se ha aplicado, no hay rollback de producto. Si se aplica después, su rollback requiere un script SQL revisado y un GO separado.

## 9. GO / NO-GO

### GO sólo si

- El SQL preflight remoto confirma todos los objetos Hybrid D, RLS y privilegios service-only.
- Se confirma que el proyecto ref y la URL son Staging.
- RevenueCat permite dirigir únicamente Sandbox/App de Staging al endpoint.
- Todos los secretos obligatorios están configurados sólo en Staging.
- Existe al menos un UUID ficticio en Supabase Auth y en la allowlist.
- Se acepta explícitamente la reconciliación manual del piloto o se implementa y valida el job Supabase Cron/pg_net.
- Las pruebas locales y el `git diff --check` pasan.

### NO-GO si

- El endpoint puede recibir y procesar Production, o se pretende reutilizar la URL/secreto de Producción.
- Falta cualquier barrera `app_id`, `SANDBOX` o allowlist.
- El preflight muestra migraciones Hybrid D parciales, funciones ausentes o privilegios de cliente.
- Se pretende ejecutar backfill sobre usuarios reales.
- Se intenta aplicar la migración rechazada `20261013100000`.
- No existe un mecanismo operativo para ejecutar reconcile después de encolar eventos.

## Resultado de validaciones locales

- `git diff --check`: **PASS**.
- Tests Flutter estáticos de Hybrid D, leases, respuestas, migraciones staged y gate Premium: **PASS**.
- `revenuecat_webhook_static_test.dart`: **FAIL** en dos expectativas heredadas que buscan `/v2/projects/` y `getUserById`; el webhook actual es signal-only y la asociación UUID/allowlist se realiza en `logic.ts` y en las RPCs. No se modificaron los tests porque reflejan un contrato anterior incompatible con Hybrid D.
- `revenuecat_sync_concurrency_static_test.dart`: **FAIL** en una expectativa de nombre de variable (`claimStatus`) que no coincide con la implementación actual (`claimMap`); la ruta sí comprueba `in_progress` y devuelve 503.
- `deno test supabase/functions/revenuecat-webhook/logic_test.ts`: omitido porque Deno no está instalado.
- No se dispone de PostgreSQL/`psql`/Docker y no se ejecutó SQL remoto ni Edge Runtime local.

Estos tres fallos estáticos heredados deben resolverse o aceptarse explícitamente antes del GO; mientras existan, el veredicto operativo permanece **BLOCKED**.
