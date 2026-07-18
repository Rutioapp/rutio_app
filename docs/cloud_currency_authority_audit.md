# Cloud Currency Authority Audit

## 1. Conclusión ejecutiva

La autoridad remota canónica para la compra cloud de la tienda es `public.user_wallets`.

`public.user_progress.ambar_balance` sigue existiendo como proyeccion legacy de la economia global de Rutio y sigue alimentando la User Card por el camino local-first actual, pero no debe usarse para validar ni ejecutar compras cloud de utilidades.

`public.currency_events` no es un saldo. Es un ledger append-only de eventos monetarios.

## 2. Tablas remotas encontradas

| Tabla | Columna | Tipo | PK | FK a `auth.users` | RLS | Quién escribe | Quién lee | Papel |
|---|---|---:|---|---|---|---|---|---|
| `public.user_wallets` | `coins` | `bigint` | `user_id` | `user_id -> auth.users(id)` | `select` propio | `purchase_shop_item(text, text, uuid)` | `ShopCloudReadRepository.fetchWallet()` y la RPC de compra | Saldo canónico de la tienda cloud |
| `public.user_wallets` | `version` | `bigint` | `user_id` | `user_id -> auth.users(id)` | `select` propio | `purchase_shop_item(text, text, uuid)` | `ShopCloudReadRepository.fetchWallet()` | Versionado de wallet |
| `public.shop_ledger` | `coins_delta`, `quantity_delta`, `request_id` | `bigint`, `integer`, `text` | `id` | `user_id -> auth.users(id)` | sin acceso directo desde Flutter | RPC `purchase_shop_item` / `equip_shop_cosmetic` | no se usa desde Flutter | Ledger de auditoría e idempotencia |
| `public.user_progress` | `ambar_balance` | `integer` | `user_id` | `user_id -> auth.users(id)` | `select/update` propio | `UserProgressRepository`, `UserStateStore` via sync best-effort | `UserProgressRepository.fetchCurrentProgress()` y restore de `UserStateStore` | Proyección legacy de progreso/economia global |
| `public.user_progress` | `level`, `total_xp`, `current_level_xp`, `next_level_xp` | `integer` | `user_id` | `user_id -> auth.users(id)` | `select/update` propio | `UserProgressRepository`, `UserStateStore` via sync best-effort | restore de `UserStateStore` | Snapshot de progreso |
| `public.currency_events` | `amount`, `currency`, `source` | `integer`, `text`, `text` | `id` | `user_id -> auth.users(id)` | `select/insert` propio | `CurrencyEventRepository` via `UserProgressSyncService` | diagnostico y auditoria | Ledger append-only de eventos monetarios |
| `public.profiles` | no hay columna de monedas | n/a | `id` | `id -> auth.users(id)` | `select/insert/update` propio | `ProfileRepository` | UI de perfil | No almacena monedas |

## 3. Fuentes locales relevantes

| Fuente local | Dónde vive | Lectura | Escritura | Papel |
|---|---|---|---|---|
| `userState.wallet.coins` | `UserStateStore` | Home, User Card, Weekly, Monthly, Habits, Shop local | Rewards, shop local, level-up, restore de `user_progress` | Moneda legacy local-first de la app |
| `ShopState.coins` | `lib/features/shop/domain/shop_state.dart` | shop local legacy | persiste como snapshot local | Snapshot legado; no es la autoridad real |

## 4. Repositorios y servicios Flutter implicados

### Lectores de saldo

- `lib/data/repositories/user_progress_repository.dart`
  - `fetchCurrentProgress()`
  - Lee `public.user_progress`
- `lib/features/shop/data/cloud/shop_cloud_read_repository.dart`
  - `fetchWallet()`
  - Lee `public.user_wallets`
- `lib/stores/user_state_store_habit_progress.dart`
  - `_restoreSupabaseUserProgressBestEffort()`
  - Copia `user_progress.ambar_balance` al wallet local
- `lib/screens/home/logic/home_selectors.dart`
  - Lee `userState.wallet.coins`
- `lib/widgets/app_header/user_stats_card.dart`
  - Consume el saldo que le llega desde Home/Weekly/Monthly

### Escritores de saldo

- `lib/stores/user_state_store_account.dart`
  - `_buyItem()`
  - Compra local legacy y sincroniza best-effort a `user_progress` y `currency_events`
- `lib/stores/user_state_store_habit_progress.dart`
  - `_markLevelCelebrationAsCelebrated()`
  - Suma monedas de nivel y sincroniza best-effort
- `lib/stores/user_state_store_habits.dart`
  - Flujos de recompensa por hábito y rollback
- `lib/stores/user_state_store_diary.dart`
  - Recompensas de diario
- `lib/data/services/user_progress_sync_service.dart`
  - `syncCurrentProgressFromLocalState()`
  - `recordCurrencyEvent()`
- `lib/data/repositories/user_progress_repository.dart`
  - `upsertCurrentProgress()`
  - `touchProgressFromLocalState()`
- `lib/data/repositories/currency_event_repository.dart`
  - `insertCurrencyEvent()`
- `lib/features/shop/application/purchase_cloud_utility_use_case.dart`
  - Guarda operaciones pendientes y ejecuta la RPC cloud
- `lib/features/shop/application/shop_controller.dart`
  - En modo cloud usa `user_wallets` como saldo visible y no escribe en `user_progress`

## 5. Mapa de autoridad por flujo

| Flujo | Lectura local | Escritura local | Lectura remota | Escritura remota |
|---|---|---|---|---|
| User Card / Home / Weekly / Monthly | `userState.wallet.coins` | `UserStateStore` local | `user_progress.ambar_balance` solo en restore de bootstrap | `user_progress` y `currency_events` via sync best-effort |
| Compra tienda local | `userState.wallet.coins` | `userState.wallet.coins` + `ShopState` local | no aplica | `user_progress` y `currency_events` via sync best-effort |
| Compra tienda cloud | no usa saldo local para validar | no escribe saldo local | `user_wallets.coins` | `user_wallets` y `shop_ledger` via `purchase_shop_item` |
| Completar hábito | `userState.wallet.coins` | sí | no aplica directamente | `user_progress` y `currency_events` via sync best-effort |
| Descompletar hábito | `userState.wallet.coins` | sí | no aplica directamente | `user_progress` y `currency_events` via sync best-effort |
| Logro | `userState.wallet.coins` | sí | no aplica directamente | `user_progress` y `currency_events` via sync best-effort |
| Level-up | `userState.wallet.coins` | sí | no aplica directamente | `user_progress` y `currency_events` via sync best-effort |
| Mystery Box | `userState.wallet.coins` | sí | no aplica | no aplica en cloud |

## 6. Fuentes encontradas y clasificación

### `public.user_wallets`

- Tipo: saldo canónico de shop
- Estado: canónico para la tienda cloud
- Escritura: solo RPC `purchase_shop_item`
- Lectura: `ShopCloudReadRepository`
- Observación: esta tabla es la que la tienda debe usar cuando los dos flags cloud están activos

### `public.user_progress`

- Tipo: snapshot de progreso global
- Estado: legacy/proyeccion para la app general
- Escritura: `UserStateStore` y `UserProgressRepository` via sync
- Lectura: restore/bootstrap de `UserStateStore`
- Observación: no debe ser la autoridad de la compra cloud de shop

### `public.currency_events`

- Tipo: ledger de eventos
- Estado: audit log
- Escritura: `CurrencyEventRepository`
- Lectura: diagnostico y reconciliacion
- Observación: no representa saldo autoritativo

### `public.shop_ledger`

- Tipo: ledger de operaciones de shop
- Estado: audit log de compra/equip
- Escritura: RPC
- Lectura: no hay lectura Flutter directa
- Observación: asegura idempotencia por `request_id`

## 7. Divergencia detectada y riesgo

Hay dos dominios diferentes que contienen monedas:

- moneda global legacy: `userState.wallet.coins` -> `user_progress.ambar_balance` y `currency_events`
- moneda cloud de shop: `user_wallets.coins` -> `shop_ledger`

Eso no significa que la tienda deba mezclar saldos.

Riesgo actual:

- si otra pantalla intenta mostrar monedas cloud usando `user_progress`, reaparece una segunda autoridad visible
- si la User Card se migra sin plan, puede leer un valor distinto al de la tienda cloud

## 8. Recomendada fuente canonica

Recomendacion:

- `public.user_wallets` como autoridad canónica de la compra cloud de la tienda
- `public.user_progress.ambar_balance` como legacy/proyeccion de la economía global de la app
- `public.currency_events` como ledger histórico, no como saldo

Motivos:

- `purchase_shop_item` ya es atómico sobre `user_wallets`
- la compra cloud queda idempotente con `request_id` y `shop_ledger`
- no exige modificar el resto de la app en esta fase
- evita dual-write desde Flutter para la tienda
- mantiene separada la economía global legacy hasta la siguiente fase

## 9. Cambios Flutter realizados

- `ShopController` usa `ShopCloudReadRepository` y `PurchaseCloudUtilityUseCase` como capa de wallet cloud
- `ShopController.visibleCoinBalance` expone el saldo visible efectivo de la tienda
- `ShopFlowScreen` consume el saldo visible efectivo, no el local legacy cuando la economia cloud esta activa
- `ShopItemDetailContainer` usa el saldo efectivo para la confirmacion de compra
- `ShopScreen` mantiene una instancia estable del controlador
- `ShopCloudConfig` separa flags de lectura y compra

## 10. Cambios SQL necesarios

Para cerrar esta fase de compra cloud, no hacen falta cambios SQL adicionales.

El SQL que ya existe en la rama es consistente con la recomendacion:

- `public.user_wallets` es la autoridad de compra cloud
- `public.shop_ledger` es el ledger de compras
- `public.purchase_shop_item(text, text, uuid)` escribe en la wallet correcta

Si en una fase futura se quiere unificar la moneda global visible de toda la app con la wallet cloud de shop, entonces si haria falta una tarea SQL aparte para definir esa convergencia. Esa fase no entra en este alcance.

## 11. Estado de cierre

Estado de la fase para shop cloud purchase:

- completada para el alcance de tienda
- no modifica la economia global de la app
- no introduce dual-write desde Flutter para la compra cloud
- no mezcla saldo local y cloud en la UI de tienda

## 12. Siguiente fase recomendada

La siguiente fase recomendada es decidir si la User Card y el resto de superficies globales migran a la misma wallet canónica o si siguen con la economia legacy hasta una refactorizacion mayor.

Si se migra, el paso correcto no es copiar saldos. El paso correcto es introducir una abstraccion de wallet global compartida y definir una sola fuente visible para toda la app.
