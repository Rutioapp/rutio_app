# Cloud Economy Rollout

## Objetivo

Preparar el corte final de la economÃ­a cloud de Rutio y retirar la economÃ­a legacy de forma progresiva, segura y reversible por fases.

La regla de oro de esta fase es:

- `public.user_wallets` es la fuente canÃ³nica de monedas.
- `public.user_progress.ambar_balance` sigue existiendo solo por compatibilidad y auditorÃ­a.
- Flutter no debe volver a escribir monedas en dos autoridades a la vez.

## Estado actual de la base

### Autoridad canÃ³nica

- `public.user_wallets`
- Escritura autoritativa de tienda cloud, recompensas cloud, utilidades, Mystery Box y equipamiento.

### Legacy compatible

- `public.user_progress.ambar_balance`
- Sigue siendo un snapshot legado de la economÃ­a global.
- Sigue alimentando el restore local-first y varias rutas de compatibilidad.

### Ledgers y colas

- `public.shop_ledger`
- `public.habit_currency_reward_ledger`
- `public.achievement_level_reward_ledger`
- `public.mystery_box_opening_ledger`
- `public.utility_consumption_ledger`
- Colas persistentes en `SharedPreferences` para:
  - compras pendientes
  - recompensas de hÃ¡bitos pendientes
  - claims de logros pendientes
  - Mystery Box pendiente

## AuditorÃ­a final de cÃ³digo legacy

### Lecturas de `ambar_balance`

Actualmente siguen existiendo solo en estas rutas:

- [`lib/data/repositories/user_progress_repository.dart`](../lib/data/repositories/user_progress_repository.dart)
- [`lib/data/models/remote/remote_user_progress.dart`](../lib/data/models/remote/remote_user_progress.dart)
- [`lib/data/services/user_progress_sync_service.dart`](../lib/data/services/user_progress_sync_service.dart) por el flujo de sincronizaciÃ³n del snapshot legacy
- tests de snapshot y restore que caracterizan el comportamiento legacy

### Escrituras locales de monedas

Las escrituras locales restantes estÃ¡n concentradas en:

- [`lib/stores/user_state_store_habits.dart`](../lib/stores/user_state_store_habits.dart)
- [`lib/stores/user_state_store_diary.dart`](../lib/stores/user_state_store_diary.dart)
- [`lib/stores/user_state_store_achievements.dart`](../lib/stores/user_state_store_achievements.dart)
- [`lib/stores/user_state_store_account.dart`](../lib/stores/user_state_store_account.dart)

En la prÃ¡ctica:

- hÃ¡bitos, diario, logros y algunas rutas de compatibilidad siguen actualizando `userState.wallet.coins`
- cuando los flags cloud estÃ¡n activos, la UI ya debe leer del controlador global y no de `UserStateStore`
- la escritura local sigue existiendo como compatibilidad hasta el apagado final

### Feature flags relevantes

Flags ya presentes en la base:

- `GLOBAL_CLOUD_WALLET_ENABLED`
- `CLOUD_HABIT_REWARDS_ENABLED`
- `GLOBAL_CLOUD_WALLET_UI_ENABLED`
- `CLOUD_ACHIEVEMENT_LEVEL_REWARDS_ENABLED`
- `CLOUD_UTILITY_CONSUMPTION_ENABLED`
- `CLOUD_MYSTERY_BOX_ENABLED`
- `CLOUD_COSMETICS_ENABLED`
- `SHOP_CLOUD_READ_ENABLED`
- `SHOP_CLOUD_PURCHASE_ENABLED`

## MigraciÃ³n final propuesta

La transiciÃ³n final no debe sobrescribir actividad cloud vÃ¡lida.

### 1. Usuarios sin wallet

- Crear `public.user_wallets` si no existe fila para el usuario.
- Usar el `ambar_balance` legacy solo como fuente inicial de arranque.
- Registrar el backfill en auditorÃ­a.

### 2. Usuarios con wallet ya activa

- No sobrescribir la wallet.
- No aplicar `max()` ni reconciliaciones silenciosas.
- Si hay diferencia entre `user_wallets.coins` y `ambar_balance`, registrar la divergencia para revisiÃ³n.

### 3. Diferencias entre balances

- Tratar `user_wallets` como autoridad.
- Tratar `ambar_balance` como snapshot legacy.
- No intentar "fusionar" ambos balances automÃ¡ticamente.

### 4. Inventario local pendiente y equipamiento

- No migrar desde una lista libre sin validar.
- La migraciÃ³n segura debe ser explÃ­cita y por usuario.
- El inventario y el equipamiento cloud ya viven en `public.user_inventory` y `public.user_equipped_cosmetics`.

### 5. Operaciones pendientes

- Las colas pendientes son locales y separadas por usuario.
- No se migran desde SQL.
- El rollout solo debe conservarlas y drenarlas de forma segura al recuperar conexiÃ³n.

### 6. Valores demo

- `demo` debe seguir siendo local-only.
- No debe usarse como fuente de producciÃ³n.
- Los datos demo se regeneran con `lib/devtools/demo_seed/*`.

### 7. Tabla de auditorÃ­a y snapshot de rollout

Se aÃ±adiÃ³ una migraciÃ³n segura e idempotente:

- [`supabase/migrations/20260720143000_prepare_cloud_economy_rollout_audit.sql`](../supabase/migrations/20260720143000_prepare_cloud_economy_rollout_audit.sql)

Incluye:

- `public.global_cloud_economy_rollout_audit`
- `public.global_cloud_economy_rollout_status`

PropÃ³sito:

- registrar backfill y discrepancias
- revisar wallets existentes
- comparar `ambar_balance` con `user_wallets.coins`
- auditar inventario y equipamiento

## Orden de rollout

### 1. Desarrollo

- Flags apagados por defecto.
- VerificaciÃ³n local con datos demo y tests unitarios/integraciÃ³n.
- No activar nada en producciÃ³n.

Rollback:

- desactivar flags
- limpiar cachÃ© local y colas persistentes

### 2. Usuarios internos

- activar solo en cuentas internas o entornos controlados
- monitorizar wallet missing, request conflicts y divergencias

Rollback:

- apagar flags por usuario/entorno
- mantener wallets y ledgers intactos

### 3. Porcentaje reducido

- habilitar wallet cloud y consumos cloud a un subconjunto pequeÃ±o
- mantener legacy como fallback de compatibilidad

Rollback:

- volver a legacy solo en UI/feature flags
- no revertir datos cloud vÃ¡lidos

### 4. Lectura cloud global

- la UI principal deja de leer saldo desde `UserStateStore`
- la wallet visible pasa a `GlobalWalletController`

Rollback:

- reactivar lectura legacy temporalmente

### 5. Escritura cloud global

- las recompensas y consumos autorizados escriben solo en Supabase
- no dual-write

Rollback:

- apagar flags cloud y rehidratar desde el snapshot local

### 6. DesactivaciÃ³n legacy

- dejar de depender de `ambar_balance` para UI y autoridad
- mantenerlo solo como columna histÃ³rica mientras haya consumidores

Rollback:

- volver a habilitar solo si hay una incidencia funcional grave

### 7. Limpieza posterior

- eliminar fallback legacy cuando no queden consumidores
- retirar columnas/campos solo con migraciÃ³n y test

Rollback:

- solo mediante migraciÃ³n inversa o restauraciÃ³n de backup

## Observabilidad segura

La observabilidad debe ser Ãºtil sin filtrar datos sensibles.

Eventos que conviene registrar:

- compra fallida
- reward pendiente
- wallet missing
- request conflict
- divergencia detectada
- cola pendiente
- error de sesiÃ³n
- operaciÃ³n idempotente recuperada

QuÃ© registrar:

- `userId` solo si ya es un contexto autenticado y necesario
- `requestId`
- `operationType`
- `sourceId`
- `failureCode`
- `walletVersion`
- `balanceAfter`

QuÃ© no registrar:

- tokens
- payloads completos
- tablas internas
- JSON sin redacciÃ³n

## Seguridad

RevisiÃ³n final requerida:

- `auth.uid()` en RPCs y policies
- RLS habilitado en tablas autoritativas
- grants mÃ­nimos
- ausencia de `service_role`
- `search_path = ''` en funciones `security definer`
- parÃ¡metros manipulables validados en servidor
- precios y rewards calculados por servidor
- locks transaccionales y unique constraints para idempotencia

## Tests y verificaciÃ³n

### SQL de verificaciÃ³n

- [`supabase/tests/cloud_economy_rollout_verification.sql`](../supabase/tests/cloud_economy_rollout_verification.sql)

### Cobertura funcional ya existente

- compra
- reward
- reverse
- claim
- utility
- Mystery Box
- equip
- cambio de usuario
- reintento/idempotencia
- migraciÃ³n/backfill
- rollback lÃ³gico

### ValidaciÃ³n manual recomendada

- ejecutar `flutter analyze`
- ejecutar los tests cloud relevantes
- correr el SQL de verificaciÃ³n local sobre la base preparada

## Checklist de lanzamiento

- [ ] Flags cloud apagados en producciÃ³n
- [ ] `user_wallets` poblada para usuarios existentes
- [ ] backfill auditable aplicado
- [ ] divergencias revisadas
- [ ] colas pendientes drenadas o monitoreadas
- [ ] RLS y grants verificados
- [ ] logs de error y conflicto revisados
- [ ] tests cloud ejecutados
- [ ] `flutter analyze` limpio
- [ ] plan de rollback por fase validado

## Riesgos pendientes

- consumers todavÃ­a leyendo `ambar_balance`
- pantallas o servicios que sigan usando `wallet.coins` local como autoridad visual
- divergencias antiguas entre wallets y snapshot legacy
- operaciones pendientes arrastradas durante cambio de usuario
- datos demo mezclados accidentalmente con un usuario autenticado real

## Siguiente paso recomendado

Mantener esta fase en modo "rollout controlado" hasta que:

- la UI principal no lea mÃ¡s saldo legacy
- no queden escrituras monetarias locales activas
- el equipo valide que los ledgers cloud cubren todas las rutas monetarias
