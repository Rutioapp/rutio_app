# Shop Supabase Persistence Audit

Fecha de auditoria: 2026-07-23
Rama: `audit/shop-supabase-persistence`

## Alcance

Se auditaron los flujos de tienda en:

- `D:/dev/alpha/rutio_app/lib/features/shop/`
- `D:/dev/alpha/rutio_app/supabase/migrations/`
- `D:/dev/alpha/rutio_app/test/features/shop/`
- `D:/dev/alpha/rutio_app/lib/stores/`
- flags de build y arranque en `dart_defines` / `ShopCloudRuntimeConfig`

Tambien se reviso la relacion con:

- wallet global
- inventario
- cosmeticos
- packs / bundles
- utilities / boosts
- mystery box
- streak recovery / streak shield
- persistencia local
- auth y cambio de cuenta
- activacion de modo cloud

Restriccion respetada: no se cambio logica, migraciones ni codigo de negocio. El unico archivo creado es este informe.

## Resumen Ejecutivo

Estado general:

- No se detecto un P0.
- El riesgo P1 de fuga entre cuentas por persistencia local legacy compartida fue corregido en `fix/shop-account-isolation`.
- Hay un P1 adicional sobre `recoverStreakBreak`, ya corregido en `fix/shop-cloud-streak-recovery`.
- Hay un P2 de drift / cobertura incompleta entre el catalogo local y el contrato remoto.
- Hay un P3 menor por un helper sin uso que ya aparece en `flutter analyze`.

Lectura rapida:

- La wallet real ya es cloud-first cuando el modo cloud esta activo, pero el codigo sigue manteniendo snapshots legacy locales.
- Los cosmeticos siguen dependiendo en gran parte del catalogo local para metadata y assets, mientras que Supabase aporta ownership/equip state.
- Los utilities y el mystery box tienen una division mas clara entre modo local y modo cloud, pero el flujo de streak recovery cloud no esta estabilizado.
- Los cambios de usuario limpian estado en memoria, pero no se ve una limpieza equivalente y obligatoria de las claves legacy compartidas de tienda.

## Mapa de Fuente de Verdad

| Dominio | Fuente de verdad actual | Persistencia local | Persistencia cloud / Supabase | Riesgo principal |
|---|---|---|---|---|
| Wallet global | `GlobalWalletController` / `user_wallets` | cache por usuario | `public.user_wallets`, `wallet_cache` | divergence si el snapshot local queda stale |
| Inventory de utilities | `ShopState.backpackItems` en local legacy; `user_inventory` en cloud | `ShopLocalRepository`, `pending_shop_operation_store` | `purchase_shop_item`, `user_inventory`, `utility_consumption_ledger` | doble fuente mientras el modo mixto exista |
| Inventario cosmeticos | `ShopCosmeticsState` local / cloud snapshot | `ShopCosmeticsRepository`, `cloud_cosmetics_cache` | `user_inventory`, `user_owned_bundles`, `user_equipped_cosmetics` | drift entre catalogo local y tablas remotas |
| Packs / bundles | catalogo local + `shop_bundles` remoto | `ShopAssetsCatalog` | `shop_bundles`, `shop_bundle_items`, `user_owned_bundles` | partial coverage y reglas de completado |
| Boosts / utilities activas | `user_utility_effects` / local snapshot | `local_active_utility_effects_repository` | RPCs de `activate_utility_effect`, `consume_utility_use`, `apply_streak_recover` | idempotencia y sincronizacion post-commit |
| Mystery box | modo local: cliente; modo cloud: RPC | `local_mystery_box_opening_repository`, `pending_mystery_box_operation_store` | `open_mystery_box`, `mystery_box_opening_ledger` | dualidad de generacion de reward |
| Streak recovery / shield | `userStateStore` + repos de utility consumption | repos locales legacy y estado en memoria | RPC / ledger cloud de utility consumption | area con tests fallando |
| Auth / cambio de cuenta | `UserStateStore` al cambiar scope | limpia estado en memoria y user-state root | no veo una purga obligatoria de shop legacy keys | leakage cross-user |
| Flags cloud | `ShopCloudRuntimeConfig` | `dart_defines` / compiled env | validacion de arranque | mezcla accidental de modos |

## Flujos Revisados

### 1) Compra

`ShopController.purchaseItem()` decide por item y por flags. Los utilities soportados usan camino cloud; cosmeticos y items no soportados siguen en local.

Evidencia:

- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart:366`
- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart:639`
- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart:735`
- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart:1419`

Observacion:

- El flujo cloud de utilities ya usa request ids y snapshot confirmados.
- El flujo local sigue siendo la via de respaldo para cosmeticos y para utilidades no cubiertas por el contract cloud.

### 2) Equip de cosmeticos

`ShopCosmeticsController` usa repositorio local o cloud segun flags.

Evidencia:

- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_cosmetics_controller.dart:223`
- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_cosmetics_controller.dart:570`
- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_cosmetics_controller.dart:1711`

Observacion:

- El estado cloud se reconcilia con cache local por usuario.
- El `cloud_cosmetics_snapshot` sanitiza equipamiento contra el catalogo local, asi que el cliente sigue siendo parte del contrato de validacion.

### 3) Mystery box

El modo local resuelve el reward en cliente. El modo cloud delega la seleccion del reward al RPC.

Evidencia:

- `D:/dev/alpha/rutio_app/lib/features/shop/application/open_mystery_box_use_case.dart:53`
- `D:/dev/alpha/rutio_app/lib/features/shop/application/open_mystery_box_use_case.dart:64`
- `D:/dev/alpha/rutio_app/supabase/migrations/20260719193000_create_mystery_box_opening_ledger_and_rpc.sql:320`

Observacion:

- La version cloud ya no depende del random source local para decidir el reward.
- Esto reduce manipulación del cliente, pero exige consistencia fuerte en pending queue, ledger y replay.

### 4) Streak recovery / streak shield

`recoverStreakBreak()` tiene bifurcacion local/cloud segun `CLOUD_UTILITY_CONSUMPTION_ENABLED`.

Evidencia:

- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart:976`
- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart:1013`
- `D:/dev/alpha/rutio_app/supabase/migrations/20260721160000_create_cloud_utility_consumption.sql:1`

Observacion:

- El tramo cloud depende de `hydrateVisibleEconomy()`, del inventario visible y luego del RPC en `UserStateStore`.
- Es la zona mas fragil del audit porque la suite ya no esta verde.

### 5) Cambio de usuario / logout

`UserStateStore` limpia scope en memoria y resetea estado transitorio al cambiar usuario.

Evidencia:

- `D:/dev/alpha/rutio_app/lib/stores/user_state_store_account.dart:51`
- `D:/dev/alpha/rutio_app/lib/stores/user_state_store_account.dart:90`
- `D:/dev/alpha/rutio_app/lib/stores/user_state_store_account.dart:110`
- `D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart:166`

Observacion:

- El cambio de scope evita estado stale en memoria.
- No vi una purga equivalente y obligatoria de las claves legacy compartidas de shop.

## Hallazgos

### P1 - Riesgo de fuga entre cuentas por persistencia legacy global compartida

Estado:

- Corregido en `fix/shop-account-isolation` el 2026-07-23.

Nueva politica aplicada:

- claves scopeadas por usuario como unica fuente de verdad local;
- clave guest explicita para sesiones no autenticadas;
- migracion legacy solo con `legacyOwner == scope` exacto;
- descarte seguro de legacy ambiguo o de otra cuenta;
- tests añadidos para aislamiento, migracion, guest y cambio de cuenta.

Impacto:

- Un usuario que cierra sesion o cambia de cuenta puede acabar leyendo la persistencia legacy global de la tienda si el scope actual es `null` o si el owner legacy coincide / esta vacio.
- Como `save()` escribe tambien en la clave legacy global, los datos quedan compartidos entre identidades salvo que alguien llame a `clear()`.

Evidencia:

- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_local_repository.dart:25`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_local_repository.dart:34`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_local_repository.dart:77`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_local_repository.dart:92`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_cosmetics_repository.dart:23`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_cosmetics_repository.dart:32`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_cosmetics_repository.dart:107`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_cosmetics_repository.dart:127`
- `D:/dev/alpha/rutio_app/lib/stores/user_state_store_account.dart:90`
- `D:/dev/alpha/rutio_app/lib/stores/user_state_store_account.dart:164`

Por que lo considero P1:

- Es un riesgo de exposicion de datos entre cuentas.
- No depende de acciones raras; se activa justo en un flujo normal de logout / cambio de usuario si las claves legacy quedan presentes.

### P1 - La ruta cloud de `recoverStreakBreak` no esta estable

Impacto:

- Corregido en `fix/shop-cloud-streak-recovery`.
- La suite de `test/features/shop` ya no falla en la zona de streak recovery cloud por este motivo.
- Se recupero la confianza en la idempotencia, en la cantidad consumida y en la continuidad entre reintentos.

Evidencia:

- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart:976`
- `D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart:1013`
- `D:/dev/alpha/rutio_app/test/features/shop/application/shop_controller_test.dart:704`
- `D:/dev/alpha/rutio_app/test/features/shop/application/shop_controller_test.dart:795`
- `D:/dev/alpha/rutio_app/test/features/shop/application/shop_controller_test.dart:920`

Causa corregida:

- El problema no era un fallo confirmado del RPC ni de Supabase.
- Los fixtures de test eran invalidos:
  - `brokenAtMillis: 1` representaba `1970-01-01T00:00:00.001Z`.
  - el helper `_createController` recibia `nowProvider`, pero no lo pasaba al `ShopController` ni al `UserStateStore`.
- Se añadieron timestamps explicitos para casos recientes y expirados.
- El test concurrente ahora tiene un timeout explicito de 2 segundos en `waitForApplyStarted`.

Resultado observado:

- `recoverStreakBreak` paso en local, cloud y concurrencia con reloj fijo.
- `flutter analyze lib/features/shop/application/shop_controller.dart test/features/shop/application/shop_controller_test.dart` quedo limpio.

Por que lo considero P1:

- La feature ya esta expuesta al usuario final en cloud mode.
- El fallo afectaba a una accion monetizable / de inventario y tocaba el camino que debe ser mas determinista.

### P2 - Drift / cobertura incompleta entre catalogo local y contrato remoto

Impacto:

- El catalogo local contiene utilities, cosmeticos y bundles, pero el seed remoto de `shop_items` sigue siendo conservador y solo carga utilities.
- Los bundles ya tienen tablas remotas propias, pero parte del metadata y de los assets sigue viviendo en catalogo Dart.

Evidencia:

- `D:/dev/alpha/rutio_app/supabase/migrations/20260718101000_seed_shop_catalog_v1.sql:3`
- `D:/dev/alpha/rutio_app/supabase/migrations/20260718101000_seed_shop_catalog_v1.sql:5`
- `D:/dev/alpha/rutio_app/supabase/migrations/20260722120000_create_shop_bundle_catalog_and_purchase_rpc.sql:8`
- `D:/dev/alpha/rutio_app/supabase/migrations/20260722120000_create_shop_bundle_catalog_and_purchase_rpc.sql:141`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_catalog.dart`
- `D:/dev/alpha/rutio_app/lib/features/shop/data/shop_assets_catalog.dart`

Lectura:

- No veo una incompatibilidad rotunda del esquema, pero si una frontera incompleta entre catalogo cliente y catalogo remoto.
- Eso obliga a mantener dobles contratos y aumenta el costo de cambiar precios, slots o items activos.

### P3 - Warning de analisis por helper sin usar

Impacto:

- `flutter analyze` reporta un warning de elemento no referenciado.

Evidencia:

- `D:/dev/alpha/rutio_app/lib/features/shop/data/cloud/shop_cloud_dtos.dart:498`

Resultado observado:

- `flutter analyze lib/features/shop` devolvio `1 issue found` por `_nullableBool` no usado.

## Estado de Persistencia Local

Repositorios locales encontrados:

- `ShopLocalRepository` persiste `ShopState` por scope y tambien escribe una clave legacy global.
- `ShopCosmeticsRepository` persiste `ShopCosmeticsState` por scope y tambien escribe una clave legacy global.
- `LocalActiveUtilityEffectsRepository` y `LocalMysteryBoxOpeningRepository` ya estan scopeados por usuario.
- `PendingShopOperationStore` y `PendingMysteryBoxOperationStore` tambien estan scopeados.
- `CloudCosmeticsCache` y `WalletCache` usan cache por usuario.

Conclusiones:

- La persistencia local no es uniformemente segura respecto a cambio de cuenta.
- Los stores de pending y cache estan mejor aislados que los repos legacy de tienda.
- El mayor riesgo no esta en los caches cloud, sino en las claves legacy compartidas que siguen siendo leidas y escritas.

## Estado de Supabase

Migrations revisadas:

- `20260717130000_create_shop_foundation.sql`
- `20260718100000_create_shop_transactional_operations.sql`
- `20260718101000_seed_shop_catalog_v1.sql`
- `20260719193000_create_mystery_box_opening_ledger_and_rpc.sql`
- `20260721160000_create_cloud_utility_consumption.sql`
- `20260722120000_create_shop_bundle_catalog_and_purchase_rpc.sql`
- `20260722220000_allow_partial_shop_bundle_completion.sql`
- `20260722214500_fix_equip_shop_cosmetic_coalesce.sql`

Lectura de contrato:

- `purchase_shop_item` y `equip_shop_cosmetic` usan `request_id` y estan pensados para idempotencia.
- `open_mystery_box` mueve la decision del reward al servidor.
- `purchase_shop_bundle` evoluciono a completado parcial, lo que es bueno para experiencia de usuario pero sube la complejidad de consistencia.
- Los tablespaces de catalogo y ledger ya existen, pero la tienda sigue teniendo una mezcla de data model local y remoto.

## Verificacion Ejecutada

### `flutter analyze lib/features/shop`

Resultado:

- Exit code 0.
- No issues found.

### `flutter test test/features/shop`

Resultado:

- `recoverStreakBreak` paso correctamente en:
  - recuperacion local;
  - recuperacion expirada;
  - recuperacion cloud;
  - expiracion cloud;
  - bloqueo concurrente con una sola llamada al repositorio.
- El test concurrente usa un timeout explicito de 2 segundos.

### `git diff --check`

Resultado:

- Limpio, sin errores de whitespace ni parches rotos.

### `git status --short`

Resultado:

- Limpio antes de crear este informe.

## Plan de Correccion Recomendado

### Fase 1: cortar la fuga entre cuentas

- Eliminar la lectura desde clave legacy global cuando no haya scope, o hacerla opt-in solo para migracion puntual.
- Dejar de escribir doblemente a la clave legacy global una vez que el scope exista.
- Asegurar que logout / cambio de usuario purga la persistencia legacy de tienda de forma obligatoria.
- Añadir tests de cambio de cuenta para `ShopLocalRepository` y `ShopCosmeticsRepository`.

### Fase 2: estabilizar streak recovery cloud

- Reproducir el timeout y los tres fallos en un entorno reducido.
- Verificar si el problema esta en `hydrateVisibleEconomy()`, en el RPC remoto o en el sync del inventario visible.
- Alinear la expectativa de idempotencia entre el repositorio de utility consumption y el controller.
- Añadir un test de reintento concurrente con usuario cambiante.

### Fase 3: cerrar drift de catalogo

- Definir que datos viven solo en Dart y cuales deben existir tambien en Supabase.
- Crear tests de paridad de catalogo entre `ShopCatalog` / `ShopAssetsCatalog` y las seeds remotas.
- Revisar si bundles y cosmeticos deberian seguir con metadata local o migrar a un catalogo remoto completo.

### Fase 4: hygiene

- Eliminar `_nullableBool` si ya no se usa.
- Repetir `flutter analyze` y `flutter test test/features/shop`.
- Re-ejecutar `git diff --check`.

## Criterios Para Considerar La Tienda "Completamente Cloud"

Se podria considerar que la tienda esta realmente cloud-first cuando:

- no exista lectura de datos legacy compartidos entre cuentas
- la wallet sea siempre confirmada por Supabase y cacheada por usuario sin ambiguedad
- utilities, mystery box, bundles y streak recovery tengan idempotencia probada
- los tests de `test/features/shop` esten verdes
- el catalogo remoto y el cliente no dependan de supuestos distintos para los mismos IDs

