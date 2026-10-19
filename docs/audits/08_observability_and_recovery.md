# 08 — observabilidad y recuperación

- **VERIFICADO:** Crashlytics tiene wrapper, handlers globales y claves permitidas; `firebase_crash_reporting_service.dart` evita user id y acepta sólo custom keys saneadas.
- **VERIFICADO:** PostHog desactiva session replay, usa perfiles identificados y sanitiza propiedades; reset de identidad existe.
- **RIESGO POTENCIAL:** `release.example.json` deja Crashlytics collection desactivado y PostHog apagado; el estado real de builds productivas es no verificable.
- **RIESGO POTENCIAL:** no hay dashboard/alertas/SLIs definidos en el repo para 4xx/5xx, p95, 429, SQL lento, conexiones, sync o compras.
- **NO VERIFICABLE:** backups, retención, restauración, RPO/RTO, Storage recovery, incident response y rollback.

## SLIs mínimos

Latencia p50/p95/p99 por RPC; 4xx/5xx/429; auth failures; refresh failures; sync conflict/error rate; slow queries; pool saturation; webhook/purchase reconciliation; egress/storage/MAU/ingestión.

## Requisitos de recovery

Definir RPO/RTO por datos de diario/progreso/economía, probar restore en proyecto aislado, validar objetos Storage, documentar migración rollback y borrado de cuenta. Una política de backup no se marca validada sin restore exitoso.
