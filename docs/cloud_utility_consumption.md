# Cloud Utility Consumption

Fecha: 2026-07-19

## Alcance

Esta fase prepara el consumo cloud de:

- XP Boost
- Coin Boost
- Streak Shield
- Streak Recover

Mystery Box queda fuera.

## Modelo remoto

La base de esta fase es un contrato remoto para utilidades activas y su auditoria:

- estado activo de la utilidad
- usos restantes
- fecha de activacion
- request id idempotente
- tipo de operacion
- fuente del evento
- ledger de consumo

La implementacion Flutter queda en:

- `SupabaseUtilityConsumptionRepository`
- `UtilityConsumptionLedgerEntry`
- `UtilityConsumptionConfig`

## Activacion

La activacion cloud se hace mediante un repositorio remoto que:

1. Valida usuario autenticado.
2. Consulta y bloquea inventario.
3. Reduce una unidad.
4. Crea el efecto activo.
5. Registra ledger.
6. Devuelve la operacion confirmada.

`ShopController` usa el repositorio cloud cuando el flag esta activo.

## Consumo de usos

XP Boost y Coin Boost se consumen en cloud al resolver una recompensa de habito.
La UI local no calcula ni duplica el bono.
La recompensa de habito sigue entrando por el flujo cloud existente y el servidor es quien debe aplicar el bono y reducir usos.

## Streak Shield

El shield usa el mismo repositorio cloud para registrar la activacion y conservar el estado activo.
La logica local de rachas sigue validando elegibilidad, pero la activacion de inventario queda confirmada en cloud.

## Streak Recover

Streak Recover consume inventario de forma cloud antes de confirmar la aplicacion local de la recuperacion.
El estado local de la racha sigue existiendo por compatibilidad, pero el uso del item deja auditoria en cloud.

## Feature Flag

- `CLOUD_UTILITY_CONSUMPTION_ENABLED`
- default: `false`

## Sesion

La implementacion evita mezclar cuentas:

- repositorios por usuario
- request ids estables
- bloqueo por usuario/sesion en el servidor
- rechazo de respuestas tardias de otra sesion

## Riesgos

- Falta ejecutar la migracion SQL en Supabase.
- El consumo de bono en habit reward depende de que el backend aplique la logica de multipliers.
- Streak Shield y Recover conservan parte del estado en local por compatibilidad.

## Siguiente fase

- Verificar la migracion SQL remota.
- Añadir tests de integracion contra repositorios cloud.
- Si el backend lo permite, reforzar la respuesta del RPC de habitos con `bonusXp`, `bonusCoins` y `appliedEffectIds`.
