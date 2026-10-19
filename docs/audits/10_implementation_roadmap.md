# 10 — roadmap de implementación

La ejecución está bloqueada hasta aprobación del propietario. No se han aplicado cambios.

| PR | Objetivo | Archivos/superficie | Pruebas | Rollback |
|---|---|---|---|---|
| 1 | baseline y tests rojos | `test/`, CI | reproducir 35 fallos, analyzer | revert commit |
| 2 | snapshot RLS/grants | Supabase staging, SQL de pruebas | A/B/anónimo, anon | no aplicar remoto hasta aprobar |
| 3 | economía RPC-only | migración mínima + repositorios | fraude de campos, concurrencia, idempotencia | migración compensatoria |
| 4 | Premium server-side | RPC/webhook/tabla si se justifica | free/premium/refund/offline | desactivar gate con feature flag |
| 5 | abuso | RPC/DB/edge sólo donde mida | 429/Retry-After/carga staging | retirar límites nuevos |
| 6 | performance | consultas y arranque | profile/release, EXPLAIN remoto | revert localizado |
| 7 | observabilidad/recovery | dashboards, CI, runbooks | alerta y restore aislado | rollback config |

Antes de cada PR: matriz de acceso, migración dry-run, pruebas iOS/Android, coste y plan de rollback. No crear Redis/gateway hasta evidencia.
