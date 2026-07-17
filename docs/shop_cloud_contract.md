# Shop Cloud Contract - Phase 1

Fecha: 2026-07-17

## Objetivo

Definir el contrato objetivo para una futura migracion de la tienda local de Rutio a Supabase sin cambiar comportamiento, UI ni modelos en esta fase.

Este documento deja separadas tres cosas:

- catalogo estatico de tienda
- estado de usuario de shop
- reglas de sincronizacion / idempotencia / saneamiento

La implementacion sigue siendo local-first por ahora.

## Alcance Auditado

Componentes revisados:

- `lib/features/shop/data/shop_catalog.dart`
- `lib/features/shop/data/shop_assets_catalog.dart`
- `lib/features/shop/data/shop_local_repository.dart`
- `lib/features/shop/data/shop_cosmetics_repository.dart`
- `lib/features/shop/data/local_active_utility_effects_repository.dart`
- `lib/features/shop/data/local_mystery_box_opening_repository.dart`
- `lib/features/shop/application/shop_service.dart`
- `lib/features/shop/application/shop_controller.dart`
- `lib/features/shop/application/shop_cosmetics_controller.dart`
- `lib/features/shop/application/open_mystery_box_use_case.dart`
- `lib/stores/user_state_store_account.dart`
- `lib/stores/user_state_store_habits.dart`
- `lib/stores/user_state_store_habit_progress.dart`
- `lib/stores/user_state_store_diary.dart`
- `lib/stores/user_state_store_achievements.dart`
- `lib/services/claims_service.dart`
- `lib/services/shop_service.dart`
- `lib/widgets/backgrounds/home_landscape_background.dart`
- `lib/widgets/home/user_identity_row.dart`
- `lib/features/shop/presentation/screens/shop_flow_screen.dart`
- `lib/features/shop/presentation/screens/shop_cosmetics_screen.dart`
- `lib/features/shop/presentation/screens/shop_customization_screen.dart`

## Inventario Actual

La fuente canonicamente auditable queda congelada en:

- `docs/shop_cloud_catalog_snapshot.json`
- `docs/shop_cloud_catalog_inventory.md`

Conteos actuales:

- 62 cosmeticos
- 5 utilities
- 22 bundles
- 89 entradas totales

## Catalogo: Contrato Futuro

El catalogo debe seguir siendo una definicion estatico-versionada, no un estado mutable por usuario.

### Reglas

- Los IDs de catalogo deben ser estables y legibles.
- Un item catalogado no debe cambiar de significado entre versiones sin una migracion explicita.
- Los assets referenciados deben existir en el paquete local antes de publicar la version del catalogo.
- Los bundles deben referenciar solo assets ya existentes y precios derivados de items vigentes.
- Los utilities deben conservar semantica de tipo, duracion y cargas.

### Claves canonicas

Para la fase cloud, conviene considerar canonicos estos grupos:

- cosmeticos
- utilities
- bundles
- rewards de mystery box
- efectos activos de utilities
- apertura de mystery box

## Modelo De Estado A Migrar

### 1) Shop state de usuario

El estado de usuario de shop hoy vive en repositorios locales y se sanitiza al cargar.

Debe representarse en Supabase como una entidad de usuario con estos bloques logicos:

- wallet o saldo de monedas
- backpack de utilities
- items comprados
- cosmeticos poseidos
- cosmeticos equipados
- metadatos de version y propietario

### 2) Cosmetics state de usuario

El estado de cosmeticos es independiente del inventario general.

Debe conservar:

- wallpaper equipado
- habit card equipado
- user card equipado
- ownership por asset
- ownership por bundle

### 3) Utility effects activos

Debe persistirse el estado de boosts activados y sus usos restantes.

### 4) Mystery box openings

Debe persistirse el historial de aperturas con:

- box consumida
- reward resuelta
- estado de transaccion
- timestamps
- idempotency keys

## Contrato De Datos Propuesto

La primera fase de migracion no requiere cambiar el catalogo, pero si conviene preparar el contrato de estado con estas piezas conceptuales.

### `shop_states`

Proposito:

- snapshot principal del estado de shop por usuario

Campos conceptuales:

- `user_id`
- `wallet_coins`
- `inventory_json`
- `backpack_json`
- `equipped_cosmetics_json`
- `schema_version`
- `updated_at`
- `created_at`

### `shop_cosmetics_states`

Proposito:

- estado especifico de cosmeticos y equipamiento por usuario

Campos conceptuales:

- `user_id`
- `owned_asset_ids_json`
- `owned_bundle_ids_json`
- `equipped_wallpaper_id`
- `equipped_habit_card_skin_id`
- `equipped_user_card_skin_id`
- `schema_version`
- `updated_at`

### `shop_active_utility_effects`

Proposito:

- boosts activos e independientes del inventario base

Campos conceptuales:

- `id`
- `user_id`
- `utility_id`
- `started_at`
- `expires_at`
- `remaining_uses`
- `total_uses`
- `schema_version`

### `shop_mystery_box_openings`

Proposito:

- auditoria e idempotencia de aperturas de cajas

Campos conceptuales:

- `id`
- `user_id`
- `box_utility_id`
- `reward_id`
- `reward_payload_json`
- `status`
- `presented_at`
- `created_at`
- `updated_at`

### `shop_catalog_versions`

Proposito:

- versionado del contrato de catalogo si en el futuro se publica desde backend

Campos conceptuales:

- `version`
- `published_at`
- `checksum`
- `entry_count`
- `notes`

## Source Of Truth

### Hoy

- El wallet real de monedas vive en `userState.wallet.coins`.
- `ShopState.coins` es un snapshot legado para la capa de shop.
- Los repositorios locales siguen siendo la fuente de verdad operativa.

### En la migracion

El contrato debe decidir una sola fuente de verdad por dominio:

- moneda de usuario
- ownership de items
- cosmeticos equipados
- boosts activos
- aperturas de mystery box

No deben coexistir dos fuentes autoritativas incompatibles para el mismo dato.

## Claves Locales A Preservar Durante La Transicion

Mientras la nube no reemplace el guardado local, estas claves siguen siendo relevantes:

- `user_state_v1`
- `user_state_v1_<scope>`
- `user_state_v1_legacy_claimed_by`
- `rutio_shop_state_v1`
- `rutio_shop_state_v1_<scope>`
- `rutio_shop_state_v1_owner`
- `rutio_shop_cosmetics_v1`
- `rutio_shop_cosmetics_v1_<scope>`
- `rutio_shop_cosmetics_v1_owner`
- `rutio_active_utility_effects_v1`
- `rutio_active_utility_effects_v1_<scope>`
- `rutio_mystery_box_openings_v1`
- `rutio_mystery_box_openings_v1_<scope>`

## Puntos Donde Cambia La Moneda

La migracion cloud debe contemplar todas las rutas que alteran monedas, porque hoy la economia no vive solo dentro de shop.

### Rutas de shop

- compra de item en `lib/features/shop/application/shop_service.dart`
- `addCoins`, `spendCoins`, `addToBackpack`, `consumeBackpackItem`
- compra y equipamiento en `lib/features/shop/application/shop_controller.dart`
- compra y equipamiento de cosmeticos en `lib/features/shop/application/shop_cosmetics_controller.dart`
- apertura de mystery box en `lib/features/shop/application/open_mystery_box_use_case.dart`

### Rutas externas al shop

- recompensas de habitos en `lib/stores/user_state_store_habits.dart`
- recompensas de progreso de habitos en `lib/stores/user_state_store_habit_progress.dart`
- recompensas diarias en `lib/stores/user_state_store_diary.dart`
- recompensas de achievements en `lib/stores/user_state_store_achievements.dart`
- recompensas legacy de claims en `lib/services/claims_service.dart`

## Invariantes Que Debe Respetar La Nube

- No duplicar grants por reintentos.
- No perder ownership cuando se sincroniza cosmeticos.
- No eliminar items desconocidos sin una regla de migracion clara.
- No equipar un asset que no exista o que no sea owned.
- No aceptar bundles con assets fuera de catalogo.
- No dejar utilidades activas con `remainingUses` mayor que `totalUses`.
- No permitir mystery box openings con rewards invalidas.

## Riesgos Criticos

### 1) Doble fuente de verdad monetaria

Hoy el ecosistema mezcla `userState.wallet.coins` y snapshots de shop. Si la nube se integra sin una decision unica, apareceran desincronizaciones y grants dobles.

### 2) UI potencialmente desfasada

`ShopFlowScreen` y `ShopCosmeticsScreen` trabajan en modo snapshot/reload, no como listeners continuos en todas sus ramas.

### 3) Saneamiento destructivo silencioso

Los repositorios locales ya eliminan ids desconocidos o invalidos al cargar. Eso es bueno para robustez, pero en nube puede ocultar bugs de migracion si no se registran eventos o warnings.

### 4) Boosts y mystery boxes como flujo transaccional

Son las piezas mas delicadas porque combinan inventario, gasto, grant y persistencia de estado derivado.

### 5) Reglas de streaks no resueltas funcionalmente

`streakShield` y `streakRecover` estan implementadas de forma local hoy, pero el contrato cloud todavia no debe asumir su modelo final sin una decision de producto.

## Decisiones Pendientes

- Si `ShopState.coins` se mantiene solo como snapshot o se elimina cuando la nube sea autoritativa.
- Si `shop_states` y `shop_cosmetics_states` deben unificarse o quedar separados.
- Si los bundles se persisten como ownership derivado o como items comprados independientes.
- Si las aperturas de mystery box deben vivir en una tabla de eventos o en una tabla de estado mas compacta.
- Si streak shield y streak recovery se migran en esta fase o se dejan en local hasta tener reglas definitivas.
- Si el catalogo se publicara desde Supabase o seguira versionado en repo.

## Recomendacion Para La Siguiente Fase

1. Elegir una unica fuente de verdad para monedas y ownership.
2. Crear contratos tipados para `shop_state`, `shop_cosmetics_state`, `active_utility_effects` y `mystery_box_openings`.
3. Mantener el catalogo estatico local hasta que exista un esquema de versionado de backend.
4. Añadir idempotencia fuerte antes de mover grants o consumos a red.
5. Separar primero lecturas, luego escrituras, y dejar la reconciliacion como ultimo paso.

## Validacion De Esta Fase

Esta fase solo documenta el contrato y el inventario.

- No se modifico comportamiento de shop.
- No se conecto Supabase.
- No se cambio UI.
- No se cambiaron reglas de economia.

