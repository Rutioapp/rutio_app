# 04 — rate limiting y abuso

## Estado actual

- **VERIFICADO:** `supabase/config.toml:129-159` define límites locales de Auth: refresh 150/5 min/IP, sign-in/sign-up 30/5 min/IP, verificaciones 30/5 min/IP, email 2/h y SMS 30/h.
- **VERIFICADO:** `api.max_rows=1000` limita respuestas locales.
- **NO VERIFICABLE:** límites hospedados de Supabase, PostgREST, Storage, Edge Functions, CDN, proveedor Auth real, cuotas y observabilidad de 429.
- **NO ENCONTRADO:** enforcement explícito por usuario para CRUD, RPC, refresh de reportes o compras en el repositorio.

## Matriz recomendada inicial

| Operación | Límite inicial a validar en staging | Identidad | Enforcement | Respuesta |
|---|---|---|---|---|
| login/registro/OTP | usar límites Auth del proyecto + CAPTCHA adaptativo si hay abuso | IP + cuenta | Supabase Auth | error genérico, Retry-After |
| crear/editar hábito | 60/min, burst 10 | user id | DB/RPC o gateway nativo si disponible | 429 |
| logs/sync | 120/min, payload acotado, upsert idempotente | user+device | RPC/DB | 429 + backoff |
| diario/feedback | 30/min; tamaño de texto/imagen limitado | user+IP | RPC/Storage policy | 429/413 |
| estadísticas | 30/min; cache cliente y server-side si procede | user id | RPC | 429/cache |
| refresh report | 5/min y 20/día | user id | RPC con ledger/ventana | 429 + Retry-After |
| webhooks | sólo si aparecen | emisor/event id | endpoint firmado + idempotencia | 401/409 |

Los números son hipótesis de staging, no métricas reales. Ajustar con p95, patrón de uso y cuotas antes de producción. No añadir Redis/gateway sin demostrar insuficiencia de Supabase/RPC.

## Pruebas

Normal, burst, concurrencia, Retry-After, backoff con jitter, cliente modificado, payload grande, reintento duplicado y pérdida de conexión. Cargar sólo staging con fixtures sintéticos.
