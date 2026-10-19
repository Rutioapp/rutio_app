# 05 — base de datos y escalabilidad

## Hallazgos

- **VERIFICADO:** índices por `(user_id, updated_at/date/created_at)` y unicidad de `habit_logs` están definidos en `supabase_backend_phase_9_schema_patch.sql`; los reportes limitan historial a 50 en `20260901150000_weekly_report_read_api.sql:77-97`.
- **VERIFICADO:** RPC de rewards/shop usa ledger, `request_id` y funciones idempotentes en migraciones de julio; es una buena base contra reintentos.
- **RIESGO POTENCIAL:** tablas de eventos (`xp_events`, `currency_events`, logs, reportes) crecen indefinidamente; no hay política de retención/particionado evidenciada.
- **NO VERIFICABLE:** cardinalidades, `EXPLAIN ANALYZE`, bloat, locks, conexiones, pool y latencias remotas.

## Modelo de capacidad (supuestos explícitos)

No son métricas reales. Para planificación, supongo 1/5/10 acciones sincronizadas por DAU/día y 10 lecturas de app por DAU/día; pico 10x de la media diaria distribuida en 8 horas.

| DAU | operaciones/día aproximadas | media en 8h | pico 10x | riesgo dominante |
|---:|---:|---:|---:|---|
| 1.000 | 11.000 | 0,38 req/s | 3,8 req/s | límites Auth/RPC y observabilidad |
| 10.000 | 110.000 | 3,8 req/s | 38 req/s | conexiones, egress, tablas de eventos |
| 100.000 | 1.100.000 | 38 req/s | 382 req/s | plan Supabase, pool, agregados y cuotas |

Medir por endpoint y payload antes de dimensionar. Reportes deben evitar recalcular historial completo por petición; el backend ya usa snapshots, pero falta `EXPLAIN` remoto.

## Costes a revisar

Database compute/storage, egress, Auth MAU, Realtime, Storage/transformaciones, logs, backups, Edge Functions, RevenueCat y PostHog. **NO VERIFICABLE** sin plan y facturación.
