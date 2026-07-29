# 6A - Auditoria global

## Resumen ejecutivo

La persistencia local de Rutio esta concentrada principalmente en `SharedPreferences`, con un bloque adicional de archivos locales para avatares. No se han encontrado Hive, sqflite, isar, drift ni `flutter_secure_storage` en `pubspec.yaml` o en `lib/`.

El aislamiento principal de cuenta se basa en `UserStateStore.switchLocalScope(...)`, `UserStateRepository.setActiveUserScope(...)`, claves `SharedPreferences` por `userId`, y protecciones frente a resultados stale mediante `scopeEpoch`, `requestEpoch`, `requestId`, `operationId`, `bootstrapRunId` y validaciones de `currentUser`.

No se detecta un riesgo critico demostrado de que una cuenta B lea inmediatamente datos privados de A en los flujos principales revisados. Si hay riesgos altos que deben tratarse en fases posteriores: una clave legacy `local_user_v1` almacena credenciales en `SharedPreferences`; la app no declara reglas explicitas de backup en Android; varias claves privadas usan `userId.trim()` sin `safeKeyFragment`; y algunos flujos best-effort post-logout dependen de guards posteriores o de Supabase actual, no de cancelacion explicita.

El Punto 4 cubre bien bootstrap, decision autoritativa y cache v2; el resto de la app aun necesita validacion especifica de logout, cambio de cuenta, reinstalacion y operaciones diferidas.

## Alcance revisado

Se inspeccionaron:

- Dependencias y assets en `pubspec.yaml`.
- Plataforma Android: `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/rutio/app/MainActivity.kt`, `android/app/src/main/res/raw/com_rutio_app_keep.xml`.
- Plataforma iOS: `ios/Runner/Info.plist`.
- Persistencia local: `lib/data/local/user_state_storage.dart`, `lib/data/local/bootstrap_profile_decision_cache.dart`, `lib/data/local/authoritative_bootstrap_cache_v2.dart`.
- Sesion y logout: `lib/application/auth/auth_controller.dart`, `lib/stores/user_state_store_account.dart`, `lib/screens/profile/settings_screen.dart`, `lib/data/repositories/auth_repository.dart`.
- Store principal y extensiones: `lib/stores/user_state_store.dart`, `lib/stores/user_state_store_core.dart`, `lib/stores/user_state_store_habits.dart`, `lib/stores/user_state_store_diary.dart`, `lib/stores/user_state_store_streak_protection.dart`, `lib/stores/user_state_store_achievements.dart`.
- Repositories y caches privados: tienda, cosmeticos, wallet, operaciones pendientes, habitos, diario, perfil y achievements.
- Tests existentes por busqueda dirigida en `test/`.

No se inspeccionaron exhaustivamente todas las pantallas visuales ni HTML mockups en `lib/screens/Rutinas/`, por no ser persistencia de runtime.

## Arquitectura de persistencia actual

La app crea `UserStateRepository` y `UserStateStore` en `lib/main.dart`. El `UserStateRepository` recibe un scope activo inicial desde Supabase (`RutioSupabaseClient.instance.auth.currentUser?.id`) y escribe mediante `UserStateStorage`.

`UserStateStore.switchLocalScope(...)` incrementa `_scopeEpoch`, actualiza `_activeLocalScopeUserId`, llama a `UserStateRepository.setActiveUserScope(...)`, limpia estado en memoria cuando cambia el scope y recarga. `_loadStore(...)` descarta resultados stale si cambia `scopeEpoch` o scope durante la carga.

El logout desde Ajustes (`SettingsScreen._handleLogOut`) llama a `UserStateStore.clearAuthSessionState()`, no directamente a `AuthController.signOut()`. Esa rama ejecuta `_signOutSupabaseSessionIfPresent()` y cambia a scope guest con `_switchLocalScope(userId: null, forceReload: true)`.

`AuthController` tambien implementa `signOut()`, escucha `authStateChanges`, invalida memoria de bootstrap y limpia `GlobalWalletController`. En cambios de auth lanza tareas fire-and-forget para cambiar scope y sincronizar wallet.

## Tecnologias de almacenamiento

| Tecnologia | Uso encontrado | Evidencia | Clasificacion |
| --- | --- | --- | --- |
| `SharedPreferences` | Estado local, caches, operaciones pendientes, permisos, sesion legacy | `pubspec.yaml`, multiples repositorios | Principal |
| Supabase session persistida por SDK | Sesion auth restaurable por `supabase_flutter` | `RutioSupabaseClient.initialize()` sin overrides | Esperado de SDK, pendiente de prueba fisica |
| Archivos en documentos | Avatares locales persistidos | `AvatarService._persistAvatarFile()` usa `getApplicationDocumentsDirectory()/avatars` | Privado por usuario si referenciado desde perfil |
| Native SharedPreferences Android | Cache interna de notificaciones programadas del plugin | `MainActivity.clearScheduledNotificationsCache`, `scheduled_notifications` | Global/dispositivo |
| Assets empaquetados | Catalogos, plantillas, imagenes shop, config | `pubspec.yaml` assets | Global por version de app |
| Memoria/singletons | Stores, controllers, caches en mapas | `UserStateStore`, `ProfileRepository`, `GlobalWalletController`, `Shop*Controller` | Efimero, requiere invalidacion |

No encontrados: `flutter_secure_storage`, Hive, sqflite, isar, drift.

## Matriz global de datos

| Dominio | Dato | Sensibilidad | Propietario | Storage | Clave/namespace | Se limpia en logout | Cambio A->B seguro | Reinstalacion | Fuente remota | Riesgo |
| ------- | ---- | ------------ | ----------- | ------- | --------------- | ------------------: | ----------------: | ------------- | ------------- | ------ |
| Auth legacy | Email/pass locales | A | Usuario/dispositivo | SharedPreferences | `local_user_v1` | Solo por `SessionService.clear()`/cleanup, no en logout normal revisado | Dudoso si se usa | Puede restaurarse por backup | No | Alto |
| Auth Supabase | Sesion SDK | A | Usuario autenticado | Storage interno SDK | gestionado por Supabase | `signOut()` esperado | Esperado | Puede restaurarse segun plataforma/SDK | Supabase Auth | Alto pendiente prueba |
| User state | Perfil local, habits, logs, diario, wallet legacy, settings, achievements | A | Usuario | SharedPreferences | `user_state_v1_<userId>` | Logout conserva por usuario; clear local borra scope activo | Si, por `activeUserScope` y save guards | Puede restaurarse por backup | Supabase parcial | Medio |
| User state legacy | Estado no namespaced | A/legado | Desconocido | SharedPreferences | `user_state_v1` | No por defecto; auto migracion desactivada | No debe usarse en auth scope | Puede restaurarse | No | Medio |
| Bootstrap legacy v1 | Decision perfil shadow | E/A | Usuario+entorno | SharedPreferences | `rutio_bootstrap_profile_decision_v1_<env>_<userId>` | Invalidacion por profile repo/auth | Si, valida userId | Puede restaurarse pero shadow | Perfil Supabase | Bajo |
| Bootstrap v2 | Decision autoritativa cache shadow | E/A | Usuario+entorno+scope | SharedPreferences | `rutio_authoritative_bootstrap_cache_v2_<env>_<userId>` con `scopeKey` dentro | Se borra por usuario/clear cuando se llama | Si, valida user/env/scope/schema | Puede restaurarse pero no navega desde cache | RPC autoritativa | Bajo |
| Shop local | Inventario utilidades, compras legacy, backpack, equipped | A | Usuario o guest | SharedPreferences | `rutio_shop_state_v1_<scope>`, guest, legacy owner | Conserva scoped; clear borra scope actual | Si, salvo inconsistencia de key normalizer | Puede restaurarse | Cloud shop parcial | Medio |
| Shop cosmetics local | Owned/equipped cosmetics | A | Usuario o guest | SharedPreferences | `rutio_shop_cosmetics_v1_<scope>`, guest, legacy owner | Conserva scoped | Si, salvo inconsistencia de key normalizer | Puede restaurarse | Cloud cosmetics parcial | Medio |
| Cloud cosmetics cache | Snapshot cosmeticos remoto | E/A | Usuario | SharedPreferences | `rutio_cloud_cosmetics_v1_<userId>` | No en logout normal | UserId en snapshot | Puede restaurarse | Supabase | Bajo |
| Wallet cloud cache | Coins/version | E/A | Usuario | SharedPreferences | `global_cloud_wallet_cache_v1_<safeUserId>` | `clearSession` solo memoria, no cache | Si, `requestEpoch`+userId | Puede restaurarse | Supabase wallet | Bajo |
| Pending shop purchase | Compras pendientes | A/B | Usuario | SharedPreferences | `rutio_shop_pending_purchase_v1_<userId>` | No en logout normal | Depende de userId y controller guards | Puede restaurarse | RPC shop | Medio |
| Pending cloud cosmetics | Compras/equip pendientes | A/B | Usuario | SharedPreferences | `rutio_shop_cosmetics_pending_operations_v1_<userId>` | No en logout normal | Filtra `purchase.userId` | Puede restaurarse | RPC shop | Medio |
| Pending mystery box | Aperturas pendientes | A/B | Usuario | SharedPreferences | `rutio_mystery_box_pending_opening_v1_<userId>` | No en logout normal | Parcial; parsea userId pero no filtra en load | Puede restaurarse | RPC shop | Medio |
| Active utility effects | Boosts/shields activos | A | Usuario/scope | SharedPreferences | `rutio_active_utility_effects_v1_<safeScope>` | No en logout normal | Si scope correcto | Puede restaurarse | Supabase si cloud | Medio |
| Mystery box transactions | Ledger local de aperturas | A/E | Usuario/scope | SharedPreferences | `rutio_mystery_box_openings_v1_<safeScope>` | No en logout normal | Si scope correcto | Puede restaurarse | Supabase si cloud | Bajo |
| Habit reward tx | Idempotencia/recompensas locales | A/E | Usuario/scope | SharedPreferences | `rutio_habit_reward_transactions_v1_<safeScope>` | No en logout normal | Si scope correcto | Puede restaurarse | RPC rewards | Medio |
| Pending currency ops | Operaciones de reward pendientes | B | Usuario | SharedPreferences | `rutio_habit_pending_currency_operation_v1_<userId>` | No en logout normal | Por userId | Puede restaurarse | RPC rewards | Medio |
| Pending streak ops | Shield/recover pendientes | B | Usuario | SharedPreferences | `rutio_streak_shield_pending_v1_<userId>`, `rutio_streak_recover_pending_v1_<userId>` | No en logout normal | Por userId | Puede restaurarse | RPC streak | Medio |
| Pending achievement claims | Claims pendientes | B | Usuario | SharedPreferences | `rutio_pending_reward_claim_v1_<userId>` | No en logout normal | Por userId | Puede restaurarse | RPC achievements | Medio |
| Notification permission | Prompt/status interno | D | Dispositivo | SharedPreferences | `notificationPermissionPromptShown`, `notificationPermissionInternalStatus`, `notificationPermissionLastUpdatedAt` | No | Global legitimo/dudoso segun producto | Puede restaurarse | SO/permisos | Bajo |
| Notification settings | Horarios, flags | A/D mixto | Actualmente user state | SharedPreferences | Dentro de `user_state_v1_<userId>` | Conserva por usuario; idioma puede preservarse en cleanup | Si | Puede restaurarse | Perfil Supabase parcial | Bajo |
| Scheduled notifications plugin | Notificaciones programadas/cache plugin | D/A mixto | Dispositivo | Plugin/native prefs | `scheduled_notifications` interno Android | `cancelAllNotifications` en cleanup, no logout normal revisado | Pendiente | Puede restaurarse | SO/plugin | Medio |
| Avatar local | Imagen de perfil local | A | Usuario | Archivo documentos | `Documents/avatars/avatar_<millis>.<ext>` y path en perfil | Cleanup dedicado borra avatar actual; logout normal no | Si path queda en estado scoped | Puede restaurarse en backup | No/Perfil avatar_url | Medio |
| Catalogos shop/assets | Catalogo publico | C | Entorno/version | Assets/app bundle, remoto opcional | asset paths, Supabase catalog | No aplica | Si | Se reinstala con app | Assets/Supabase | Bajo |
| Estadisticas | Vistas calculadas | E | Usuario | Memoria sobre user state | Sin clave propia encontrada | Se recalcula al scope | Si | Se reconstruye | User state | Bajo |

## Inventario de claves

| Clave | Archivo | Storage | userId | Entorno | Version/scope | Lectores/escritores | Logout/cambio usuario | Clasificacion |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `local_user_v1` | `lib/services/session_service.dart` | SharedPreferences | No | No | v1 | `SessionService` | No integrado en logout normal; cleanup global lo borra | Riesgo alto/legacy |
| `user_state_v1` | `lib/data/local/user_state_storage.dart` | SharedPreferences | No | No | v1 legacy | `UserStateStorage`, `UserStateRepository` | Auto migracion desactivada; guest usa legacy si scope null | Legado/dudosa |
| `user_state_v1_<safeUserId>` | `lib/data/local/user_state_storage.dart` | SharedPreferences | Si | No | v1 | Store principal | Scope switch evita mezcla; logout conserva | Segura con deuda de entorno |
| `user_state_v1_legacy_claimed_by` | `lib/data/local/user_state_storage.dart` | SharedPreferences | Valor owner | No | Legacy migration marker | Migracion legacy | Solo si se activa migracion | Legado |
| `rutio_bootstrap_profile_decision_v1_<env>_<safeUserId>` | `lib/data/local/bootstrap_profile_decision_cache.dart` | SharedPreferences | Si | Si | schema v1 | ProfileRepository | Invalida por logout/userChanged | Segura/legacy shadow |
| `rutio_authoritative_bootstrap_cache_v2_<env>_<safeUserId>` | `lib/data/local/authoritative_bootstrap_cache_v2.dart` | SharedPreferences | Si | Si | schema v2 + `scopeKey` payload | Bootstrap/Profile | Valida user/env/scope; shadow | Segura |
| `rutio_shop_state_v1` | `lib/features/shop/data/shop_local_repository.dart` | SharedPreferences | No | No | Legacy + owner separado | ShopLocalRepository | Descarta si owner falta/mismatch | Legado |
| `rutio_shop_state_v1_owner` | idem | SharedPreferences | Valor owner | No | Legacy owner | ShopLocalRepository | Se elimina al migrar/descartar | Legado |
| `rutio_shop_state_v1_guest` | idem | SharedPreferences | Guest | No | v1 | ShopLocalRepository | Guest scope | Global guest legitima |
| `rutio_shop_state_v1_<scope>` | idem | SharedPreferences | Si, raw scope | No | v1 | ShopLocalRepository | Conserva por scope | Segura con deuda normalizacion |
| `rutio_shop_cosmetics_v1`, `_owner`, `_guest`, `_<scope>` | `lib/features/shop/data/shop_cosmetics_repository.dart` | SharedPreferences | Legacy/guest/user | No | v1 | ShopCosmeticsRepository | Similar tienda | Segura con deuda normalizacion |
| `global_cloud_wallet_cache_v1_<safeUserId>` | `lib/features/global_wallet/data/cloud/wallet_cache.dart` | SharedPreferences | Si | No | v1 | GlobalWalletController | Memoria se limpia; cache conserva | Segura con deuda entorno |
| `rutio_cloud_cosmetics_v1_<userId>` | `lib/features/shop/data/cloud/cloud_cosmetics_cache.dart` | SharedPreferences | Si, raw | No | v1 | ShopCosmeticsController | Conserva | Segura con deuda normalizacion |
| `rutio_shop_pending_purchase_v1_<userId>` | `lib/features/shop/data/pending_shop_operation_store.dart` | SharedPreferences | Si, raw | No | v1 | ShopController | Conserva | Dudosa por raw key/filter |
| `rutio_shop_cosmetics_pending_operations_v1_<userId>` | `lib/features/shop/data/cloud/pending_cloud_cosmetics_purchase_store.dart` | SharedPreferences | Si, raw | No | v1 | ShopCosmeticsController | Conserva | Segura con deuda normalizacion |
| `rutio_mystery_box_pending_opening_v1_<userId>` | `lib/features/shop/data/cloud/pending_mystery_box_operation_store.dart` | SharedPreferences | Si, raw | No | v1 | OpenMysteryBox use case/controller | Conserva | Dudosa por raw key/filter |
| `rutio_mystery_box_openings_v1_<safeScope>` | `lib/features/shop/data/local_mystery_box_opening_repository.dart` | SharedPreferences | Si | No | v1 | Local mystery box repo | Conserva | Segura |
| `rutio_active_utility_effects_v1_<safeScope>` | `lib/features/shop/data/local_active_utility_effects_repository.dart` | SharedPreferences | Si | No | v1 | ActiveUtilityEffectsRepository | Conserva | Segura |
| `rutio_habit_reward_transactions_v1_<safeScope>` | `lib/features/habits/data/local_habit_reward_transaction_repository.dart` | SharedPreferences | Si | No | v1 | Reward coordinator/store | Conserva | Segura |
| `rutio_habit_pending_currency_operation_v1_<userId>` | `lib/features/habits/data/cloud/shared_preferences_pending_currency_operation_store.dart` | SharedPreferences | Si, raw | No | v1 | HabitCurrencyRewardCoordinator | Conserva | Dudosa por raw key |
| `rutio_streak_shield_pending_v1_<userId>` | `lib/features/habits/data/cloud/streak_protection_pending_operation_store.dart` | SharedPreferences | Si, raw | No | v1 | Streak protection | Conserva | Dudosa por raw key |
| `rutio_streak_recover_pending_v1_<userId>` | idem | SharedPreferences | Si, raw | No | v1 | Streak protection | Conserva | Dudosa por raw key |
| `rutio_pending_reward_claim_v1_<userId>` | `lib/features/achievements/data/cloud/shared_preferences_pending_reward_claim_store.dart` | SharedPreferences | Si, raw | No | v1 | Achievement reward coordinator | Conserva | Dudosa por raw key |
| `notificationPermissionPromptShown` | `lib/features/notifications/data/notification_permission_preferences.dart` | SharedPreferences | No | No | No | Notification permission controller | Conserva | Global legitima/dudosa |
| `notificationPermissionInternalStatus` | idem | SharedPreferences | No | No | No | Notification permission controller | Conserva | Global legitima |
| `notificationPermissionLastUpdatedAt` | idem | SharedPreferences | No | No | No | Notification permission controller | Conserva | Global legitima |
| `scheduled_notifications` | `MainActivity.kt`/plugin | Android SharedPreferences | No claro | No | Plugin | `clearScheduledNotificationsCache` | Solo si se invoca | Pendiente |

## Stores y repositories

| Componente | Creacion/vida | Usuario contenido | Limpieza/reinicio | Riesgo |
| --- | --- | --- | --- | --- |
| `UserStateStore` | Provider global de app | `_state`, `_activeLocalScopeUserId`, `scopeEpoch` | `switchLocalScope`, `clearAuthSessionState`, `clearLocalAccountData` | Medio: muchos fire-and-forget; guards principales existen |
| `UserStateRepository` | Provider global | `_activeUserId` | `setActiveUserScope`, `clearActiveScopeState` | Bajo/medio: bloquea save cruzado si payload userId no coincide |
| `ProfileRepository` | Provider global | caches memoria bootstrap por usuario | invalidacion por logout/userChanged/session | Bajo en Punto 4; pendiente resto perfil |
| `AuthController` | Provider global, escucha Supabase | `_currentUser`, post-home tasks | `signOut`, auth stream dispose | Medio: Settings no lo llama directamente |
| `GlobalWalletController` | Provider global | `_state`, `_activeUserId`, request epoch | `clearSession` memoria; cache queda | Bajo: `requestEpoch` y userId |
| `ShopController` | Creado en pantallas/flows | cache local/cloud, operaciones activas | `dispose`, scope checks varios | Medio: operaciones pendientes persistentes |
| `ShopCosmeticsController` | Provider global | `_cachedState`, `_cachedScopeKey`, cloud state, operaciones activas | checks `_currentScope`, `_isDisposed` | Medio: complejo, tests dedicados |
| Sync services de habits/logs/journal/achievements | Inyectados en store | usan current Supabase user | best-effort y guards por userId | Medio |
| Notification services | Singleton | permisos y scheduled notifications | cancel en cleanup, init global | Medio para logout si quedan programadas |

## Logout

Flujo desde UI de Ajustes:

1. `SettingsScreen._handleLogOut` confirma.
2. Llama a `context.read<UserStateStore>().clearAuthSessionState()`.
3. `_clearAuthSessionState` suprime overlays.
4. `_signOutSupabaseSessionIfPresent` llama a `Supabase.instance.client.auth.signOut()` si hay sesion.
5. `_switchLocalScope(userId: null, forceReload: true)` incrementa `scopeEpoch`, pone repo en guest y carga plantilla/guest state.
6. Navegacion final a `/welcome`.

Flujo alternativo por `AuthController.signOut()`:

1. `_authRepository.signOut()`.
2. `_currentUser = null`, `_resolveSession(null)`.
3. Invalida cache/memoria bootstrap para usuario previo.
4. Suprime overlays, limpia wallet en memoria.
5. Cambia `UserStateStore` a guest.

Se limpia inmediatamente: estado en memoria si cambia scope, overlays, wallet en memoria, sesion Supabase esperada. Se conserva deliberadamente: `user_state_v1_<userId>`, caches privados por usuario, operaciones pendientes por usuario, caches cloud reconstruibles. No se borra en logout normal: avatar files, caches wallet/cosmetics, operaciones pendientes, notification permission prefs, probablemente scheduled notifications ya programadas.

Si falla `signOut()` en `_signOutSupabaseSessionIfPresent`, la excepcion se silencia. Esto evita bloquear UI, pero deja una conclusion pendiente: no hay garantia por codigo de que la sesion SDK haya sido invalidada si Supabase falla.

## Cambio de cuenta

### A -> logout -> B

El scope pasa A -> guest -> B. `switchLocalScope` limpia `_state` al cambiar scope, incrementa epoch y recarga clave scoped de B. La escritura cruzada principal esta bloqueada en `UserStateRepository.save` si payload `userId` no coincide con active scope.

### A -> logout -> A

El estado scoped de A permanece y se recarga. Esto es intencional para cache local por usuario. Debe validarse que no navega desde cache de bootstrap: cubierto por Punto 4.

### A -> B rapidamente

Los guards de `scopeEpoch` en `_loadStore`, `requestEpoch` en wallet y `bootstrapRunId/scopeKey` en bootstrap reducen el riesgo. Quedan operaciones best-effort en tienda, diario, rewards y notificaciones que deben validarse con tests especificos.

### A con operaciones en vuelo -> B

Riesgo medio. Hay protecciones parciales:

- `UserStateRepository.save` bloquea payload `userId` incompatible.
- `AuthController._isCurrentPostHomeContext` valida usuario, scope, epoch, runId e `isAuthenticated`.
- `GlobalWalletController._isCurrentSession` valida epoch de request, current user y active user.
- Repositorios cloud suelen leer `auth.currentUser` al ejecutar, lo que evita escribir con usuario viejo si Supabase ya cambio, pero no equivale a cancelacion.

### A con escritura local pendiente -> B

Los repositorios con colas por storage key serializan por clave. Si una instancia resolvio la clave de A antes del cambio, deberia escribir en A, no en B. Donde la key usa scope resolver en tiempo de ejecucion, debe validarse caso por caso.

### A con sincronizacion remota pendiente -> B

Pendiente de tests. Los services usan `RutioSupabaseClient.instance.auth.currentUser?.id` antes de operar. Si auth cambia durante la llamada, la respuesta remota puede llegar tarde; la aplicacion debe confirmar que callbacks que asignan remote ids verifican scope antes de guardar.

## Reinstalacion Android

`AndroidManifest.xml` no declara `android:allowBackup` ni `android:dataExtractionRules`/`fullBackupContent`. Por plataforma, si no se desactiva explicitamente, Android puede incluir datos de app en backup/restore segun version, configuracion del dispositivo y reglas por defecto.

Conclusiones:

- Garantizado por codigo: no hay regla explicita que excluya `SharedPreferences`, archivos de avatares o storage del SDK.
- Comportamiento esperado de plataforma: `pm clear` borra datos de app locales; reinstalacion limpia puede arrancar sin prefs locales, salvo restauracion automatica/backup.
- Pendiente de prueba fisica: reinstalacion con backup restore en Pixel 9 o dispositivo Android real.
- Limitacion conocida: la app no puede demostrar desde codigo que no reapareceran caches privados tras restore.

## Reinstalacion iOS

`Info.plist` no muestra uso directo de Keychain ni reglas de exclusiones de backup para documentos. No se encontro `flutter_secure_storage`.

Conclusiones:

- Garantizado por codigo: avatares se escriben bajo documentos de aplicacion; no hay atributo de exclusion de backup visible en `AvatarService`.
- Comportamiento esperado de plataforma: borrar app elimina sandbox de app, pero una restauracion desde backup puede recuperar documentos/preferencias segun politica de iOS/iCloud.
- Pendiente de prueba fisica: iPhone real o simulador con escenarios de backup/restauracion.
- Limitacion conocida: no se afirma garantia de borrado/reinstalacion mas alla de lo demostrado por codigo.

## Caches y datos derivados

Datos derivados/reconstruibles:

- Bootstrap v1/v2: reconstruible desde perfil/RPC.
- Wallet cache: reconstruible desde Supabase wallet.
- Cloud cosmetics cache: reconstruible desde Supabase.
- Estadisticas: calculadas desde `UserStateStore`.
- Catalogos/assets: bundle o remoto.

Datos privados persistentes fuente local/importante:

- `user_state_v1_<userId>` con habitos, logs, diario, progreso, wallet legacy, achievements.
- Operaciones pendientes/idempotencia.
- Avatares locales si no existe remoto equivalente.

## Corrupcion y versionado

Manejo observado:

- Bootstrap v2: distingue schema mismatch, user mismatch, environment mismatch, scope mismatch, corrupt, unknown enum y contract invalid; produce miss/error seguro y no navega desde cache.
- Bootstrap v1: valida schema, userId, onboarding status/version y coherencia de perfil; devuelve validaciones tipadas.
- `UserStateStorage._decodeMap`: `jsonDecode` sin try/catch local; `UserStateStore._loadStore` captura y deja error. No hay limpieza automatica de JSON corrupto.
- Shop local/cosmetics: JSON invalido o legacy inseguro produce estado inicial y descarta legacy inseguro si aplica.
- Wallet cache: JSON corrupto borra la clave de ese usuario.
- Cloud cosmetics cache: JSON corrupto devuelve null, no borra.
- Pending stores: JSON corrupto devuelve lista vacia; normalmente no borra.
- Avatares: path roto se resolvera como imagen fallida en UI; cleanup borra solo avatar actual si se invoca.

Riesgo: la mayoria evita mezcla de usuario; algunas fallan a estado vacio sin observabilidad o sin borrar payload corrupto.

## Operaciones asincronas

| Operacion | Propietario | Proteccion stale | Logout seguro | Cambio A->B seguro | Riesgo |
| --------- | ----------- | ---------------- | ------------: | ----------------: | ------ |
| Bootstrap autoritativo | `BootstrapController`/`ProfileRepository` | `bootstrapRunId`, expected user, scope, epoch | Si, Punto 4 | Si, Punto 4 | Bajo |
| Post-home metadata/backfills | `AuthController` | `_isCurrentPostHomeContext` | Parcial, descarta despues de awaits | Parcial | Medio |
| Scope load/save | `UserStateStore` | `scopeEpoch`, active scope, repo save guard | Si para load principal | Si | Bajo |
| Wallet sync | `GlobalWalletController` | `requestEpoch`, active/current user | Si memoria | Si | Bajo |
| Diary remote pull/upsert/delete | `UserStateStore`/sync service | flags running, current auth user, callbacks | Parcial | Pendiente | Medio |
| Habits remote pull/backfill | `UserStateStore`/sync service | flags, scope checks en varias rutas | Parcial | Pendiente | Medio |
| Habit rewards/currency | coordinators | pending operations + request ids | Parcial | Pendiente | Medio |
| Streak protection sync/close | store extension | shared futures, current user checks, operation ids | Parcial | Pendiente | Medio |
| Shop purchase/equip | Shop controllers/repos | operation maps, request ids, current scope checks | Parcial | Parcial | Medio |
| Notification scheduling | NotificationService/plugin | no scope visible en auditoria | No demostrado | Pendiente | Medio |

## Cobertura de tests

| Escenario | Tests encontrados | Estado |
| --- | --- | --- |
| Bootstrap cache v2 | `test/data/local/authoritative_bootstrap_cache_v2_test.dart` | Cubierto |
| Bootstrap controller/run stale | `test/application/bootstrap/bootstrap_controller_test.dart`, metrics, shadow | Cubierto en Punto 4 |
| Auth controller | `test/application/auth/auth_controller_test.dart` | Parcial |
| User state scope/habits remote | `test/stores/user_state_store_habits_remote_pull_test.dart`, cloud tests | Parcial |
| Shop local namespace/corrupcion | `test/features/shop/data/shop_local_repository_test.dart` | Cubierto |
| Shop cosmetics namespace/corrupcion | `test/features/shop/data/shop_cosmetics_repository_test.dart` | Cubierto |
| Shop account isolation | `test/features/shop/application/shop_account_isolation_test.dart` | Parcial/cubierto dominio tienda |
| Wallet stale/account | `test/features/global_wallet/application/global_wallet_controller_test.dart`, `test/screens/home/home_screen_refresh_test.dart` | Parcial |
| Pending shop ops | `test/features/shop/data/pending_shop_operation_store_test.dart`, pending cosmetics | Parcial |
| Reinstalacion Android/iOS | No test automatizado evidente | No cubierto, requiere fisico/simulacion |
| Backup restore | No test evidente | No cubierto |
| Logout UI Settings -> Supabase signOut -> guest | No test especifico evidente | No cubierto |
| Scheduled notifications en logout | No test evidente | No cubierto |
| Avatar file lifecycle | No test evidente | No cubierto |
| Corrupcion global user_state | No test especifico evidente | No cubierto |

No se ejecuto la suite. La fase pidio no ejecutar toda la suite y no habia duda critica que requiriera confirmacion puntual.

## Hallazgos por nivel de riesgo

### Criticos

No se ha demostrado un hallazgo critico durante 6A.

### Altos

1. `SessionService` persiste email y password en texto JSON bajo `local_user_v1` (`lib/services/session_service.dart`). Aunque parece legacy y no aparece como flujo principal Supabase, es almacenamiento sensible en `SharedPreferences`.
2. Android no define politica explicita de backup (`allowBackup`, `dataExtractionRules`, `fullBackupContent`). Datos privados en prefs/documentos podrian restaurarse por backup segun plataforma.
3. Logout por `UserStateStore.clearAuthSessionState` silencia fallos de `Supabase.auth.signOut()`. Si falla, el codigo no garantiza invalidacion de sesion aunque navegue a welcome.

### Medios

1. Varias claves privadas no incluyen entorno: `user_state_v1_<userId>`, wallet, shop, pending ops. Si dev/staging/prod comparten bundle/storage, podria haber contaminacion local.
2. Namespaces inconsistentes: algunas claves usan `_safeKeyFragment`, otras interpolan `userId.trim()` directamente.
3. Operaciones pendientes persistentes no se limpian en logout normal; es correcto si son por usuario, pero requiere matriz de reanudacion al volver a A y no ejecucion accidental en B.
4. Avatares locales en documentos no estan namespaced por userId en el path; el aislamiento depende del perfil scoped que referencia el path.
5. Notification scheduled cache/plugin no esta trazado por usuario; cancelacion en logout normal no quedo demostrada.
6. `UserStateStorage._decodeMap` no encapsula JSON corrupto; el store captura, pero no hay miss seguro ni limpieza automatica del payload corrupto.

### Bajos

1. Observabilidad irregular ante JSON corrupto: varios stores devuelven vacio/null sin registrar ni limpiar.
2. Claves legacy (`user_state_v1`, shop legacy, cosmetics legacy) permanecen para migracion o guest.
3. Falta inventario automatizado de claves para prevenir nuevas claves globales.
4. Settings de idioma se preservan como dato dentro de user state guest tras cleanup; requiere decision de producto si debe ser dispositivo o usuario.

## Riesgos criticos

No hay riesgos criticos confirmados. La subfase 6B no queda bloqueada por un bug critico reproducido, pero si debe abordar los hallazgos altos antes de declarar cierre total del Punto 6.

## Deuda tecnica

- Centralizar builder de claves con `environmentId`, `schemaVersion`, `scopeUserId` y normalizacion consistente.
- Documentar politica de logout: que se borra, que se conserva por usuario, y que se cancela.
- Añadir herramienta/test de snapshot de claves `SharedPreferences`.
- Definir politica de backup Android/iOS.
- Separar preferencias globales del dispositivo de preferencias privadas de usuario.

## Elementos ya resueltos por el Punto 4

- RPC autoritativa como fuente de navegacion de bootstrap.
- Una RPC autoritativa por bootstrap autenticado.
- `bootstrapRunId`, `expectedUserId`, `scopeUserId`, `scopeEpoch`, `scopeKey`, `environmentId`.
- Cache autoritativa v2 en shadow.
- No navegacion desde cache.
- Descarte de resultados stale en bootstrap.
- Trabajo post-Home solo tras decision `home`, con contexto validado.

## Elementos que pertenecen al futuro onboarding

- Pantallas/formularios de onboarding.
- Escrituras de `onboardingStatus`, version y completado fuera del contrato ya auditado.
- Migraciones de perfil especificas del nuevo proyecto de onboarding.
- Tests de UX de onboarding.

## Plan de siguientes subfases

### 6B - Correcciones altas de aislamiento y seguridad

Justificada por `local_user_v1`, politica de backup Android y fallo silenciado de signOut. Objetivo: eliminar/neutralizar credenciales legacy, declarar backup policy y definir comportamiento si falla signOut.

### 6C - Logout y cambio de cuenta

Justificada por flujos duales (`SettingsScreen` vs `AuthController`) y operaciones pendientes. Objetivo: tests unit/widget para logout UI, A->B, A->B con futures tardios, wallet/shop/diary/habits.

### 6D - Reinstalacion y recuperacion

Justificada por falta de evidencia Android/iOS. Objetivo: matriz fisica/simulador con app data clear, uninstall/reinstall, restore backup, sesion Supabase restaurada y storage vacio.

### 6E - Corrupcion, versionado e invalidacion

Justificada por corrupcion heterogenea en user state, pending stores y caches. Objetivo: tests de JSON corrupto, version futura/antigua, userId incorrecto y entorno incorrecto.

### 6F - Bateria final multiusuario

Justificada como cierre: tests automatizados y validacion fisica Pixel 9/iPhone.

## Criterio de cierre del Punto 6

El Punto 6 puede cerrarse cuando:

1. No exista persistencia sensible global sin justificacion.
2. Las claves privadas usen builder consistente con usuario, entorno y version cuando aplique.
3. Logout tenga test end-to-end de UI, Supabase signOut, scope guest y no visualizacion de datos previos.
4. Cambio A->B con operaciones tardias este cubierto en stores principales.
5. Reinstalacion/backup este documentado y validado en Android e iOS.
6. Corrupcion/versionado produzca miss seguro o limpieza explicita sin mezcla de usuarios.
7. Punto 4 siga sin navegacion desde cache.
