# Shop Cloud Migration Audit

Fecha: 2026-07-22

## 1. Resumen ejecutivo

Conclusion: **migracion casi completa, pero todavia no segura para produccion**.

La tienda ya tiene rutas cloud reales para lectura, compra, equipamiento, consumo de utilidades y Mystery Box. Los tests relevantes pasan y la mayoria de los flujos criticos ya usan Supabase como fuente de verdad cuando los flags estan activos.

El problema no es la ausencia total de cloud, sino la mezcla restante:

- los flags de shop siguen pudiendo caer a local por defecto si no se inyectan defines;
- los packs/bundles de cosmeticos siguen en ruta local aunque el resto de cosmeticos ya tenga soporte cloud;
- hay caches y stores locales intencionales que siguen siendo utiles como respaldo, pero que no deben confundirse con la autoridad real.

En resumen:

- cloud ya esta funcionando;
- la migracion no esta cerrada del todo;
- el mayor riesgo ahora es de configuracion y de bundles/packs, no de compilacion.

## 2. Matriz de funcionalidades

| Funcionalidad | Lectura | Escritura | Fuente de verdad | Estado | Riesgo |
| ------------- | ------- | --------- | ---------------- | ------ | ------ |
| Monedas | Cloud desde `public.user_wallets` cuando `SHOP_CLOUD_READ_ENABLED` y `SHOP_CLOUD_PURCHASE_ENABLED` estan activos; local en modo legado | RPC `purchase_shop_item` y sincronizacion posterior de wallet | Cloud en modo shop cloud; local solo en modo legacy | Cloud con mirror local | Alto si faltan defines; medio en ejecucion normal |
| Compras | Cloud para utilidades soportadas; lectura de wallet/catalogo/inventario remoto | RPC `purchase_shop_item` | `public.user_wallets` + `public.user_inventory` + `public.shop_ledger` | Cloud | Medio |
| Cosmeticos | Cloud cuando `CLOUD_COSMETICS_ENABLED` esta activo | RPC `purchase_shop_item` para asset purchase y `equip_shop_cosmetic` para equip | `public.user_inventory` + `public.user_equipped_cosmetics` | Cloud con cache local | Medio |
| Packs | Local | Local | `ShopCosmeticsRepository` / `ShopState.ownedBundleIds` | Local only | Alto |
| Inventario | Cloud para utilidades soportadas; local en modo legado | RPC de compra o consumo segun el flujo | `public.user_inventory` para cloud; `ShopState.backpackItems` para legacy | Hibrido | Medio |
| Equipamiento | Cloud cuando `CLOUD_COSMETICS_ENABLED` esta activo | RPC `equip_shop_cosmetic` | `public.user_equipped_cosmetics` | Cloud con cache local | Medio |
| XP Boost | Cloud cuando `CLOUD_UTILITY_CONSUMPTION_ENABLED` esta activo | RPC `activate_utility_effect` y `consume_utility_use` | `public.user_utility_effects` + `public.utility_consumption_ledger` | Cloud con fallback local si se desactiva el flag | Medio |
| Coin Boost | Cloud cuando `CLOUD_UTILITY_CONSUMPTION_ENABLED` esta activo | RPC `activate_utility_effect` y `consume_utility_use` | `public.user_utility_effects` + `public.utility_consumption_ledger` | Cloud con fallback local si se desactiva el flag | Medio |
| Mystery Box | Cloud cuando `CLOUD_MYSTERY_BOX_ENABLED` esta activo | RPC `open_mystery_box` | `public.mystery_box_opening_ledger` | Cloud con ledger/cache local | Medio |
| Streak Shield | Cloud cuando `CLOUD_UTILITY_CONSUMPTION_ENABLED` esta activo | RPC `activate_utility_effect` | `public.user_utility_effects` + `public.utility_consumption_ledger` | Cloud | Medio |
| Streak Recover | Cloud cuando `CLOUD_UTILITY_CONSUMPTION_ENABLED` esta activo | RPC `apply_streak_recover` | `public.user_utility_effects` + `public.utility_consumption_ledger` | Cloud | Medio |
| Efectos activos | Cloud con cache de lectura y fallback local cuando el flag esta apagado | Alta/baja de efectos via RPC o repo local | `public.user_utility_effects` | Cloud con cache local | Medio |
| Historial de consumos | Cloud en ledger remoto; local solo como respaldo historico o pending store | Inserciones en `utility_consumption_ledger` y stores de pendientes | `public.utility_consumption_ledger` | Cloud con ledger local de apoyo | Medio |

## 3. Dependencias locales restantes

### Catalogo estatica

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\shop_catalog.dart`
- Funcion: definicion de items, precios, rarezas, categorias y algunos metadatos de compatibilidad
- Comportamiento: catalogo estatica para la UI y para el reconciliador
- Motivo: el catalogo visual esta intencionalmente fijado en la app y ademas se usa como referencia de reconciliacion
- Intencion o residuo: intencional
- Impacto: bajo en runtime, medio en mantenimiento de contenidos

### Catalogo de assets y packs

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\shop_assets_catalog.dart`
- Funcion: assets, bundles y packs
- Comportamiento: definicion local de assets y bundles
- Motivo: la presentacion necesita paths locales y el catalogo de packs aun no tiene contrato cloud completo
- Intencion o residuo: mixto, pero hoy es un residuo de migracion parcial para packs
- Impacto: alto para bundles, bajo para el render

### Shop state legacy

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\shop_local_repository.dart`
- Funcion: `load`, `save`, `clear`
- Comportamiento: persistencia local con scope por usuario y sanitizacion
- Motivo: respaldo legacy y modo local cuando los flags cloud no estan activos
- Intencion o residuo: intencional como fallback, pero sigue siendo la autoridad en modo local
- Impacto: medio

### Cosmetic state legacy

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\shop_cosmetics_repository.dart`
- Funcion: `load`, `save`, `clear`
- Comportamiento: persistencia local de ownership y equipamiento de cosmeticos
- Motivo: fallback legacy y migracion por scope
- Intencion o residuo: intencional como fallback
- Impacto: medio

### Cache de cosmeticos cloud

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\cloud\cloud_cosmetics_cache.dart`
- Funcion: `SharedPreferencesCloudCosmeticsCache.read/save/clear*`
- Comportamiento: cache por usuario de snapshots cloud
- Motivo: acelerar lectura y sobrevivir recargas sin perder el ultimo snapshot confirmado
- Intencion o residuo: intencional
- Impacto: medio

### Pendientes de compra cloud

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\pending_shop_operation_store.dart`
- Funcion: store de compras pendientes
- Comportamiento: cola local por usuario con `requestId`
- Motivo: idempotencia y reintentos tras errores de red o cambio de sesion
- Intencion o residuo: intencional
- Impacto: medio

### Pendientes de Mystery Box

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\cloud\pending_mystery_box_operation_store.dart`
- Funcion: store de aperturas pendientes
- Comportamiento: cola local por usuario con `requestId`
- Motivo: reintentos e idempotencia de apertura cloud
- Intencion o residuo: intencional
- Impacto: medio

### Efectos activos legacy

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\local_active_utility_effects_repository.dart`
- Funcion: `loadEffects`, `saveEffects`
- Comportamiento: fallback local de efectos activos
- Motivo: modo local o compatibilidad cuando el flag cloud esta apagado
- Intencion o residuo: intencional como fallback
- Impacto: medio

### Mystery Box legacy

- Archivo: `D:\dev\alpha\rutio_app\lib\features\shop\data\local_mystery_box_opening_repository.dart`
- Funcion: `loadTransactions`, `saveTransactions`
- Comportamiento: historial local de aperturas
- Motivo: fallback local y respaldo historico
- Intencion o residuo: intencional como fallback
- Impacto: medio

## 4. Problemas encontrados

### Alto

1. **Los flags cloud de shop pueden caer a local por defecto en release si no se inyectan defines**
   - `D:\dev\alpha\rutio_app\lib\features\shop\data\cloud\shop_cloud_config.dart:4-11`
   - `D:\dev\alpha\rutio_app\lib\features\shop\data\cloud\cloud_cosmetics_config.dart:4-11`
   - `D:\dev\alpha\rutio_app\lib\features\shop\data\cloud\mystery_box_cloud_config.dart:4-11`
   - `D:\dev\alpha\rutio_app\lib\features\shop\data\cloud\utility_consumption_config.dart:4-11`
   - `D:\dev\alpha\rutio_app\dart_defines\dev.json:1-7`
   - Riesgo: si la build de produccion no pasa defines, la tienda vuelve a rutas locales sin avisar.

2. **Los packs/bundles siguen siendo local-first aunque el resto de cosmeticos ya soporte cloud**
   - `D:\dev\alpha\rutio_app\lib\features\shop\application\shop_cosmetics_controller.dart:384-402`
   - `D:\dev\alpha\rutio_app\lib\features\shop\application\shop_cosmetics_controller.dart:307-314`
   - `D:\dev\alpha\rutio_app\lib\features\shop\application\shop_cosmetics_service.dart:92-121`
   - `D:\dev\alpha\rutio_app\lib\features\shop\data\cloud\cloud_cosmetics_snapshot.dart:52-61`
   - Riesgo: el ownership de bundle no viaja en el snapshot cloud actual, asi que un pack comprado en un dispositivo puede no verse en otro y la logica de ownership por bundle queda fuera de la fuente de verdad cloud.

### Medio

1. **La combinacion de flags permite modos mixtos no seguros**
   - `D:\dev\alpha\rutio_app\lib\features\shop\application\shop_controller.dart:147-181`
   - `D:\dev\alpha\rutio_app\lib\features\shop\application\shop_controller.dart:617-620`
   - `D:\dev\alpha\rutio_app\lib\features\shop\application\shop_controller.dart:626-720`
   - Riesgo: se puede tener lectura/compra cloud activas con consumo de utilidades local, lo que divide la autoridad entre dos repositorios.

### Informativo

1. **La documentacion de inventario del catalogo no coincide exactamente con el catalogo local actual**
   - `D:\dev\alpha\rutio_app\docs\shop_cloud_catalog_inventory.md`
   - `D:\dev\alpha\rutio_app\docs\shop_cloud_catalog_snapshot.json`
   - `D:\dev\alpha\rutio_app\lib\features\shop\data\shop_catalog.dart`
   - Riesgo: bajo para runtime, pero puede confundir auditorias y sincronizaciones futuras.

## 5. Riesgos de perdida o duplicacion

- Si la build de produccion se genera sin `--dart-define` adecuados, la tienda puede volver a local y dejar de leer/escribir en Supabase.
- Si un usuario compra un pack en modo cloud, el ownership de bundle sigue pudiendo quedarse solo en local; al cambiar de dispositivo o limpiar cache, ese bundle puede desaparecer de la vista cloud.
- Si `CLOUD_UTILITY_CONSUMPTION_ENABLED` se desactiva mientras `SHOP_CLOUD_READ_ENABLED` y `SHOP_CLOUD_PURCHASE_ENABLED` siguen activos, la compra de utilidades y su consumo dejan de compartir autoridad.
- En los flujos cloud ya auditados, los `requestId` y los RPC transaccionales reducen bastante el riesgo de duplicado, pero el riesgo residual sigue en la integracion entre cache local y snapshot confirmado, no en la base RPC en si.
- El escenario multiusuario esta bien cubierto para las rutas cloud principales, pero cualquier dependencia de `SharedPreferences` sin scope correcto sigue siendo un punto sensible si se introduce un nuevo flujo sin aislamiento por usuario.

## 6. Cobertura de tests

### Ejecutado

- `flutter analyze`
- `flutter test test/features/shop`
- `flutter test test/stores`

### Resultado

- `flutter analyze`: OK, sin issues
- `flutter test test/features/shop`: OK, todos los tests pasaron
- `flutter test test/stores`: OK, todos los tests pasaron

### Cobertura fuerte ya existente

- compras cloud
- inventario cloud
- boosts
- streak shield
- streak recover
- Mystery Box
- cosmeticos
- equipamiento
- wallet
- multiusuario
- idempotencia
- session change / pending resolution

### Huecos que siguen abiertos

- no hay una prueba que valide el modo release sin defines y confirme que no cae a local por accidente
- no hay una prueba que cubra el caso `SHOP_CLOUD_READ_ENABLED=true`, `SHOP_CLOUD_PURCHASE_ENABLED=true` y `CLOUD_UTILITY_CONSUMPTION_ENABLED=false`
- no hay una prueba que cubra compra de packs/bundles con `CLOUD_COSMETICS_ENABLED=true`
- no hay una prueba que verifique que `ownedBundleIds` viaja de forma cloud o que, en ausencia de ese soporte, el UI bloquea esos flujos

## 7. Plan de cierre

1. Cerrar problemas criticos y de configuracion
   - fijar un modo seguro de produccion para los flags cloud
   - impedir que una build release se quede sin defines de shop

2. Eliminar inventarios paralelos
   - mover packs/bundles a la fuente cloud o bloquear su compra en cloud mode hasta tener contrato remoto
   - asegurar que `ownedBundleIds` forme parte del snapshot cloud o deje de exponerse como ownership local

3. Unificar equipamiento
   - revisar que el equipamiento cloud y el legacy no convivan como dos autoridades
   - decidir si `SharedPreferences` queda solo como cache o desaparece del path funcional

4. Revisar fallbacks y flags
   - dejar una combinacion unica y segura para produccion
   - documentar claramente que combinaciones estan prohibidas

5. Cerrar multiusuario
   - reforzar migraciones entre scopes y logout
   - validar que ningun cache global sobreviva a cambio de cuenta

6. Limpiar codigo local
   - eliminar repositorios legacy que ya no sean necesarios
   - conservar solo caches y mecanismos de pending si siguen aportando valor

7. Anadir tests finales
   - matrix de flags
   - packs/bundles cloud
   - cambios de sesion con ownership de bundle
   - arranque de produccion sin defines
