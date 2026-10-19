# 07 — Premium y RevenueCat

## Estado

- **VERIFICADO:** `PremiumRepository` inicializa RevenueCat, enlaza/desenlaza el user id Supabase, escucha CustomerInfo, bloquea compra/restore sin identidad autenticada y deriva acceso del entitlement.
- **VERIFICADO:** `PremiumAccessPolicy` es exclusivamente local; las pantallas semanal/reportes también aplican el gate en Flutter.
- **VERIFICADO:** entitlement esperado en el dominio es `premium` según configuración/documentación del feature.
- **NO VERIFICABLE:** API keys reales por plataforma, productos/ofertas del dashboard, Trusted Entitlements, webhooks, eventos duplicados/desordenados y estado de reembolso/grace period.
- **NO ENCONTRADO:** webhook RevenueCat en `supabase/functions` o migraciones que materialicen entitlement Premium en una tabla server-side.

## Riesgo

El cliente no es autoridad. Aunque manipular `PremiumAccessState` no crea una compra válida, sí puede desbloquear UI o invocar endpoints si el servidor no valida entitlement. El API semanal está owner-scoped pero su comentario deja entitlement para futuro (`20260901150000_weekly_report_read_api.sql:121`).

## Validación requerida

Free/Premium/expired/refunded/grace/offline/cambio de cuenta; cliente modificado; RPC directa sin UI. Decidir si basta RevenueCat SDK para funciones locales o si los reportes requieren webhook + tabla de grants. Añadir idempotencia por event id si aparecen webhooks.
