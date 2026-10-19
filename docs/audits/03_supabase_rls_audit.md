# 03 — auditoría RLS

Estado: la matriz es del **contrato SQL fuente**. La base remota es **NO VERIFICABLE CON EL ACCESO ACTUAL**.

| Tabla/superficie | RLS fuente | SELECT | INSERT | UPDATE | DELETE | Observación |
|---|---|---|---|---|---|---|
| `profiles` | habilitado | propio | propio | propio | no evidenciado | id = auth.uid; validar columnas editables |
| `habits` | habilitado | propio | propio | propio | propio | políticas `*_own`, líneas 257-283 |
| `habit_logs` | habilitado | propio | propio | propio | propio | unicidad user/habit/date en líneas 337-376 |
| `journal_entries` | habilitado | propio | propio | propio | propio | contenido sensible; líneas 828-855 |
| `user_progress` | habilitado | propio | propio | propio | no evidenciado | P1 si es autoritativo; líneas 449-469 |
| `xp_events` | habilitado | propio | propio | no evidenciado | no evidenciado | escritura directa de eventos |
| `currency_events` | habilitado | propio | propio | no evidenciado | no evidenciado | escritura directa de eventos |
| `user_achievements` | habilitado | propio | propio | propio | no evidenciado | rewards mutables en contrato fuente |
| `weekly_report_*` | habilitado | activaciones propias; snapshots por RPC | RPC | RPC | no directo | API owner-scoped y límite 50 |
| `shop_items`/inventario/wallet | habilitado en migración | catálogo activo/propio | RPC | RPC | RPC | grants directos revocados en migración shop |
| `feedback_reports`/screenshots | habilitado | propio | propio | RPC | propio restringido | validar bucket remoto y path |

## Funciones

- **VERIFICADO:** muchas funciones `SECURITY DEFINER` usan `set search_path = ''` y se revocan a `public/anon/authenticated`; esto reduce riesgos de search path.
- **VERIFICADO:** las RPC semanales comprueban `auth.uid()` y filtran por `user_id` (`20260901150000_weekly_report_read_api.sql:52-119`).
- **NO VERIFICABLE:** owner, grants efectivos, vistas materializadas, políticas añadidas manualmente y estado de `FORCE ROW LEVEL SECURITY` en remoto.

## Pruebas requeridas antes de cambios

Crear dos usuarios sintéticos A/B y un anónimo en staging. Para cada tabla y RPC: A SELECT/UPDATE/DELETE de B debe devolver cero filas o rechazo; anónimo debe rechazar; A debe poder operar sus filas. Añadir casos de `user_id` manipulado, UUID ajeno, p_limit grande, fechas fuera de rango y reintentos concurrentes. No ejecutar contra producción.
