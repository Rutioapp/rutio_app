# Cloud Habit Currency Rewards

## Objetivo

Esta fase migra las recompensas monetarias de hábitos desde la economía legacy local hacia la wallet cloud canónica en `public.user_wallets`.

## Arquitectura

- `HabitCurrencyRewardCoordinator`: orquesta apply/reverse, reintentos y cola pendiente.
- `HabitCurrencyRewardRepository`: abstrae la llamada remota.
- `HabitCurrencyRewardRemoteDataSource`: ejecuta `apply_habit_completion_reward` y `reverse_habit_completion_reward`.
- `PendingCurrencyOperationStore`: persiste operaciones pendientes por usuario.
- `HabitRewardTransactionRepository`: conserva una sombra local del último estado confirmado para idempotencia y UI local.

## Fuente canónica

- La fuente canónica de monedas para hábitos es `public.user_wallets`.
- La wallet se actualiza en servidor mediante RPC atómica.
- Flutter no escribe monedas en `user_wallets` ni en `currency_events` para esta fase.

## Papel de `ambar_balance`

- `user_progress.ambar_balance` sigue existiendo como legado.
- No se elimina todavía.
- No se sincroniza continuamente con la wallet cloud.
- Solo se usa como respaldo histórico mientras conviven sistemas anteriores.

## Caché y estado local

- La cola pendiente se separa por `userId`.
- Cada operación guarda `requestId`, `habitId`, `logicalDateKey`, `completionEventId`, tipo de operación, timestamps y número de intentos.
- El estado local conserva la última transacción confirmada para deduplicar y para reintentos tras reinicio.
- La UI puede mostrar estado pendiente o en sincronización, pero no inventa saldo confirmado.

## Sesión

- Al iniciar sesión, el coordinador usa el `userId` autenticado para resolver operaciones pendientes.
- Las respuestas tardías de otra sesión se descartan si el `userId` del ledger no coincide.
- Al cerrar sesión, la memoria reactiva queda limpia; la persistencia por usuario se conserva en disco.

## Estados

- `success`
- `pending`
- `skipped`
- `failure`

## Feature flag

- `CLOUD_HABIT_REWARDS_ENABLED`
- Valor por defecto: `false`
- Cuando está desactivado, el flujo legacy se mantiene.

## RPC propuestas

- `apply_habit_completion_reward`
- `reverse_habit_completion_reward`

Cada RPC recibe:

- `auth.uid()` como usuario efectivo.
- `habit_id`
- `logical_date`
- `completion_event_id`
- `request_id`
- `operation_type`

El servidor:

- Calcula o valida la recompensa.
- Usa bloqueos transaccionales.
- Aplica idempotencia por `request_id` y por evento lógico de hábito.
- Nunca confía en importes arbitrarios enviados por Flutter.

## Migración SQL propuesta

La migración añadida crea:

- `public.habit_currency_reward_ledger`
- `app_private.habit_completion_base_reward(...)`
- `public.apply_habit_completion_reward(...)`
- `public.reverse_habit_completion_reward(...)`

La reversión:

- Busca la recompensa original.
- Aplica exactamente el delta inverso.
- Falla si el saldo actual no soporta la reversión sin volver negativo.
- Devuelve la fila ya registrada si la misma operación llega otra vez.

## Qué pasa si el usuario ya gastó las monedas

- La reversión se rechaza.
- No se fuerza saldo negativo.
- No se emite una compensación automática todavía.
- La app debe mostrar el error como un estado controlado.

## Riesgos

- Si existían recompensas legacy ya guardadas sin `completion_event_id`, la fase cloud puede no tener trazabilidad completa para reversarlas en el mismo formato.
- El cambio de flag a nivel de compilación limita parte de la validación local de esta rama.
- La reversión con saldo insuficiente requiere una decisión de producto posterior si se quiere permitir deuda o compensación diferida.

## Siguiente fase

- Conectar la User Card y otras pantallas al estado cloud global.
- Migrar `Coin Boost` y otros multiplicadores al servidor.
- Definir la estrategia de backfill para completions legacy si hace falta.
- Unificar la visualización de moneda confirmada, pendiente y stale en la UI de hábitos.
