# Fase 1 - Auditoria del arranque actual de Rutio

## 1. Resumen ejecutivo

El arranque actual ya tiene una compuerta inicial (`AppStartupGate`) que intenta evitar entrar en Home antes de cargar estado local, comprobar sesion y preparar el fondo equipado. Aun asi, no existe un "Bootstrap Gate" completo que espere a que el estado remoto de Supabase, el perfil, los habitos remotos, la wallet global y todos los cosmeticos confirmados esten coherentes para el usuario activo.

Las causas confirmadas del flash son:

- La decision Welcome/Auth/Home se toma con `AuthController.currentUser` y `UserStateStore.onboardingDone`, pero `AuthController` marca `isCheckingSession=false` inmediatamente despues de suscribirse al stream de auth. Si `currentUser` aun no esta restaurado en ese instante, `AppStartupGate` puede decidir `welcome`.
- `onboardingDone` es un flag local dentro de `userState.meta`. En reinstalacion o cache local vacia vale `false` porque se crea una plantilla local nueva.
- Home se puede construir con estado local/cache/template antes de que terminen las sincronizaciones remotas lanzadas en segundo plano por `AuthController` y `HomeScreen.initState`.
- Los cosmeticos usan fallbacks visuales cuando `ShopCosmeticsController` aun no tiene snapshot/cached state para el scope actual, cuando el catalogo cloud esta vacio, cuando el item equipado no esta validado como owned o cuando falla la carga remota sin cache.
- El fondo generico esta implementado como fallback real de `HomeBackground`; no es solo una pantalla de carga.

No se han anadido logs nuevos en esta fase. El codigo ya contiene trazas utiles en `[startup]`, `[auth]`, `[user_state_store]`, `[user_state_repository]`, `[user_state_storage]`, `[habit_pull]`/`[habit_sync]`, `[ShopCosmetics]`, `[shop_cloud_cosmetics]`, `[cosmetic_trace]` y `[global_wallet]`.

## 2. Archivos y componentes implicados

### Entrada, raiz y navegacion

- `lib/main.dart`
  - `main()`
  - `MyApp`
  - `MultiProvider`
  - `MaterialApp`
  - rutas `/splash`, `/welcome`, `/auth`, `/auth-signup`, `/root`, `/home`, `/shop`
- `lib/screens/app_startup_gate.dart`
  - `AppStartupGate`
  - `_initializeStartup`
  - `_ensureLocalStateReady`
  - `_waitForAuthSessionCheck`
  - `_fallbackResultForCurrentState`
- `lib/application/bootstrap/async_bootstrap_gate.dart`
  - `AsyncBootstrapGate`
- `lib/screens/auth/auth_gate.dart`
  - `AuthGate`
- `lib/screens/root_gate.dart`
  - `RootGate`
- `lib/screens/splash_screen.dart`
- `lib/screens/welcome_screen.dart`
- `lib/screens/auth/sign_in_screen.dart`
- `lib/screens/auth/sign_up_screen.dart`
- `lib/screens/home/home_screen.dart`

### Supabase y autenticacion

- `lib/core/supabase/rutio_supabase_client.dart`
  - `RutioSupabaseClient.initialize`
  - `RutioSupabaseClient.instance`
- `lib/data/repositories/auth_repository.dart`
  - `currentUser`
  - `authStateChanges`
  - `signInWithEmailPassword`
  - `signUpWithEmailPassword`
  - `signOut`
- `lib/application/auth/auth_controller.dart`
  - constructor
  - `_handleAuthState`
  - `_finishSessionCheck`
  - `_syncCurrentUserProfile`
  - `_bootstrapCurrentUserProfileMetadata`

### Estado local, habitos y sincronizacion

- `lib/stores/user_state_store.dart`
- `lib/stores/user_state_store_core.dart`
  - `_loadStore`
  - `_switchLocalScope`
  - `_setOnboardingDone`
  - `_onboardingDone`
- `lib/stores/user_state_store_habits.dart`
  - `_maybeSyncHabitsFromRemoteBestEffort`
  - `_runHabitsRemotePull`
  - `_syncExistingLocalHabitsOnce`
  - `_mergeRemoteHabitsIntoLocalState`
  - `_mergeRemoteHabitLogsIntoLocalState`
- `lib/data/repositories/user_state_repository.dart`
  - `loadOrCreate`
  - `save`
  - `setActiveUserScope`
- `lib/data/local/user_state_storage.dart`
  - `read`
  - `write`
  - scoped SharedPreferences keys
- `lib/data/repositories/habit_repository.dart`
  - `fetchHabitsForCurrentUser`
  - `upsertHabitForCurrentUser`
- `lib/data/services/habit_sync_service.dart`
  - `backfillLocalHabitsWithoutRemoteId`

### Inventario, tienda y cosmeticos

- `lib/features/shop/application/shop_cosmetics_controller.dart`
  - constructor
  - `hydrate`
  - `getState`
  - `refreshCloudState`
  - `_syncFromCurrentScope`
  - `_loadCloudState`
  - `_applyConfirmedCloudSnapshot`
  - `getEquippedWallpaperAssetOrNullSync`
  - `getEquippedHabitCardAssetOrNullSync`
  - `getEquippedUserCardAssetOrNullSync`
- `lib/features/shop/data/shop_cosmetics_repository.dart`
  - estado local de cosmeticos en SharedPreferences
- `lib/features/shop/domain/models/shop_cosmetics_state.dart`
  - `ShopCosmeticsState.initial`
- `lib/features/shop/data/cloud/cloud_cosmetics_cache.dart`
- `lib/features/shop/data/cloud/shop_cosmetics_cloud_repository.dart`
- `lib/features/shop/data/shop_assets_catalog.dart`
- `lib/features/global_wallet/application/global_wallet_controller.dart`

### Home, fondos, cards y datos visibles

- `lib/widgets/backgrounds/home_landscape_background.dart`
  - `HomeBackground`
  - `_ReactiveHomeBackgroundScene`
  - `_DefaultHomeBackgroundVisual`
  - `_CustomWallpaperBackgroundVisual`
- `lib/screens/home/state/home_state.dart`
  - `HomeScreen.initState`
- `lib/screens/home/build/home_build.dart`
  - `buildContent`
  - `_HomeLoadedView`
  - `_HomeCosmeticsTraceListener`
- `lib/screens/home/logic/home_selectors.dart`
  - `buildHomeViewData`
- `lib/screens/home/logic/home_shop_cosmetics.dart`
  - `_equippedHabitCardAsset`
- `lib/screens/home/ui/home_card_builders.dart`
  - `_habitCard`
- `lib/widgets/home/user_identity_row.dart`
  - `UserIdentityRow`
  - `UserCardThemeBackground`

## 3. Flujo actual paso a paso

1. `main()` llama `WidgetsFlutterBinding.ensureInitialized()`.
2. Se resuelve `ShopCloudRuntimeConfig.compiled()` y se valida.
3. `RutioSupabaseClient.initialize()` ejecuta `Supabase.initialize(...)`. Este es el punto donde Supabase queda disponible para `auth.currentUser` y `auth.onAuthStateChange`.
4. Se crea un `UserStateRepository` temporal y `DemoSeedRunner.prepare()` puede preparar estado demo/local.
5. Se inicializa `NotificationService.instance.init()` en best effort.
6. `runApp(MyApp(...))`.
7. `MyApp.build()` crea providers globales:
   - `UserStateStorage`
   - `AssetJsonLoader`
   - `AuthRepository`
   - `ProfileRepository`
   - `UserStateRepository`
   - `GlobalWalletController`
   - `UserStateStore`
   - `ShopCosmeticsController`
   - `AuthController`
8. Al crear `UserStateStore`, se calcula `initialUserId` desde `RutioSupabaseClient.instance.auth.currentUser?.id` y se llama `userStateRepository.setActiveUserScope(initialUserId)`. Despues se lanza `store.load()`.
9. Al crear `ShopCosmeticsController`, se registra como listener de `UserStateStore` y `GlobalWalletController`. Si cloud cosmetics esta activo, lanza `_syncFromCurrentScope(force:false)` sin esperarlo.
10. Al crear `AuthController`, se lee `_authRepository.currentUser`, se suscribe a `authStateChanges`, se llama `_finishSessionCheck()` y, si habia usuario, lanza tareas de scope/profile/wallet/backfill en segundo plano.
11. `MaterialApp.home` es `AppStartupGate`.
12. `AppStartupGate` muestra `SplashScreen` al menos 900 ms y ejecuta `_initializeStartup`.
13. `_initializeStartup` espera estado local (`UserStateStore.load`) y espera a que `authController.isCheckingSession` sea false.
14. Decide:
    - Home si `authController.currentUser != null` o demo.
    - Auth si no hay usuario y `userStateStore.onboardingDone == true`.
    - Welcome si no hay usuario y `onboardingDone == false`.
15. Si va a Home, llama `HomeBackgroundBootstrapper.prepare`, que ejecuta `ShopCosmeticsController.hydrate()` y precachea el wallpaper equipado si existe.
16. `RootGate` vuelve a esperar solo `UserStateStore.isLoading`; si no hay error, devuelve `HomeScreen`.
17. `HomeScreen.initState` programa post-frame:
    - `s.load()` si no hay estado.
    - `s.maybeSyncHabitsFromRemoteBestEffort()`.
18. `HomeScreen.buildContent` observa `UserStateStore` y `GlobalWalletController`, y construye Home con `buildHomeViewData(root, selectedDay)`.
19. `HomeBackground`, `_equippedHabitCardAsset` y `UserIdentityRow` resuelven cosmeticos sincronicamente contra `ShopCosmeticsController`. Si no hay asset validado, pintan fallback.
20. Sincronizaciones remotas posteriores (`auth`, wallet, user progress, habitos, logs, cosmeticos) notifican controllers/stores y provocan rebuilds.

## 4. Linea temporal del arranque

```text
main()
-> WidgetsFlutterBinding.ensureInitialized()
-> ShopCloudRuntimeConfig.compiled/validate
-> RutioSupabaseClient.initialize()
-> DemoSeedRunner.prepare()
-> NotificationService.init()
-> runApp(MyApp)
-> MultiProvider crea UserStateStore y lanza store.load()
-> MultiProvider crea ShopCosmeticsController y puede lanzar sync cloud
-> MultiProvider crea AuthController
-> MaterialApp(home: AppStartupGate)
-> AsyncBootstrapGate muestra SplashScreen
-> AppStartupGate._initializeStartup()
-> espera UserStateStore local
-> espera AuthController.isCheckingSession
-> decide Welcome/Auth/Home
-> si Home: hydrate/precache cosmeticos de fondo
-> RootGate
-> HomeScreen.initState()
-> HomeScreen primer build
-> post-frame: sync habitos remotos
-> auth/profile/wallet/backfill/cosmeticos notifican cambios
```

| Paso | Sync/async | Estado mientras espera | UI posible | Dependencias | Riesgo de orden |
| --- | --- | --- | --- | --- | --- |
| `WidgetsFlutterBinding.ensureInitialized` | Sincrono | Ninguno | Ninguna | Flutter | Bajo |
| `RutioSupabaseClient.initialize` | Asincrono | App aun no montada | Ninguna | Supabase config | Medio: restauracion interna de sesion puede no estar reflejada en `currentUser` si se consulta demasiado pronto |
| `UserStateStore.load` en provider | Asincrono, no esperado por `runApp` | `_loading=true`, `_state` previo/null | Splash o loading de Root/Home | `UserStateRepository` | Medio |
| `AuthController` constructor | Mixto | `_isCheckingSession=true` solo hasta `_finishSessionCheck()` | AppStartupGate sigue esperando | `AuthRepository.currentUser`, stream auth | Alto: `_finishSessionCheck()` ocurre inmediatamente, no despues de perfil/scope |
| `AppStartupGate._ensureLocalStateReady` | Asincrono | Splash | Splash | `UserStateStore` | Bajo para local, no cubre remoto |
| `AppStartupGate._waitForAuthSessionCheck` | Asincrono polling | Splash | Splash | `AuthController` | Alto si check termina antes de `initialSession` real |
| Decision de ruta | Sincrono | Resultado congelado en `AsyncBootstrapGate` | Welcome/Auth/Home | `currentUser`, `onboardingDone` local | Alto |
| `HomeBackgroundBootstrapper.prepare` | Asincrono | Splash | Splash | `ShopCosmeticsController.hydrate` | Medio: fallback si timeout/fallo/sin snapshot |
| `RootGate` | Sincrono/reactivo | `store.isLoading` | loader o Home | `UserStateStore` | Bajo para local |
| `HomeScreen.initState` | Sincrono + post-frame async | Home ya puede pintar | Home fallback/local | `UserStateStore` | Alto: sync remoto arranca despues del primer frame |
| `maybeSyncHabitsFromRemoteBestEffort` | Asincrono | Home con estado local actual | Habitos vacios/locales | Supabase habits/logs | Alto con conexion lenta |
| `ShopCosmeticsController._syncFromCurrentScope` | Asincrono | fallback, cache stale o initial | Fondo/cards genericos | cache, Supabase cloud cosmetics | Alto |
| `GlobalWalletController.syncSession` | Asincrono | wallet loading/cache/failure | monedas locales o 0 | Supabase wallet | Medio |
| `AuthController._syncCurrentUserProfile` | Asincrono en segundo plano | nombre/avatar locales/fallback | nombre fallback | profiles Supabase | Medio |

## 5. Decision actual de onboarding

La condicion exacta vive en `AppStartupGate._initializeStartup`:

```dart
final shouldOpenHome =
    authController.currentUser != null || RutioRuntimeProfile.isDemo;
final destination = shouldOpenHome
    ? _StartupDestination.home
    : userStateStore.onboardingDone
        ? _StartupDestination.auth
        : _StartupDestination.welcome;
```

`userStateStore.onboardingDone` viene de `UserStateStore._state.userState.meta.onboardingDone`. Si `_state == null`, `_onboardingDone` devuelve `false`. Si la app se reinstala, SharedPreferences se pierden y `UserStateRepository.loadOrCreate()` crea estado desde `AppAssets.userStateTemplate`; en una cache local vacia el indicador vuelve a valor de plantilla, normalmente `false`.

La navegacion no consulta Supabase para saber si una cuenta existente ya hizo onboarding. Tampoco hay `onboarding_status` remoto. Por tanto:

- Usuario sin sesion + cache nueva: `Welcome`.
- Usuario sin sesion + `onboardingDone=true` local: `SignInScreen`.
- Usuario con sesion ya visible en `currentUser`: `Home`.
- Usuario existente en reinstalacion pero sesion no restaurada o no disponible en el instante de decision: `Welcome`.

La cuenta existente puede ser interpretada temporalmente como nueva no porque Supabase diga que es nueva, sino porque aun se ve como "sin usuario" y el flag local se perdio o aun no cargo un scope autenticado.

## 6. Carga actual de habitos

La fuente primaria para el primer frame de Home es `UserStateStore.state.userState.activeHabits`, cargado desde SharedPreferences por `UserStateRepository.loadOrCreate()`.

`loadOrCreate()`:

- Lee `UserStateStorage.read(userId: activeUserId)`.
- Si existe estado scoped, lo devuelve.
- Si no existe, no migra legacy porque `_autoMigrateLegacyIntoScoped=false`.
- Carga `AppAssets.userStateTemplate`.
- Escribe la plantilla en el scope actual.

Home transforma `activeHabits` con `buildHomeViewData`. Si `activeHabits` esta vacio porque el scope esta vacio o se acaba de inicializar desde plantilla, Home pinta empty state.

La sincronizacion remota de habitos no bloquea la construccion inicial de Home:

- `AuthController._syncCurrentUserProfile` lanza despues una cadena de backfills: user progress, habitos locales, logs, journal, achievements.
- `HomeScreen.initState` lanza `maybeSyncHabitsFromRemoteBestEffort()` en post-frame.
- `_runHabitsRemotePull` consulta `HabitRepository.fetchHabitsForCurrentUser()`, luego logs por cada habit, valida scope y mezcla remoto en local.
- Si hay cambios, llama `store.save(root)`, lo que notifica a Home.

Riesgo confirmado: Home puede mostrar lista vacia/local antes de que `fetchHabitsForCurrentUser` y los logs remotos se apliquen.

## 7. Carga actual de Supabase

`RutioSupabaseClient.initialize()` encapsula `Supabase.initialize(url, anonKey)`. A partir de ahi:

- `AuthRepository.currentUser` lee `Supabase.instance.client.auth.currentUser`.
- `AuthRepository.authStateChanges` lee `client.auth.onAuthStateChange`.
- `AuthController` se inicializa leyendo `currentUser` una vez y escuchando el stream.

El problema de arranque esta en el contrato local de `AuthController`: `_finishSessionCheck()` se llama inmediatamente despues de suscribirse al stream, no despues de que hayan terminado:

- cambio inicial `initialSession`,
- cambio de scope local,
- fetch/ensure de profile,
- restore de user progress,
- backfill de habitos/logs,
- sync de wallet,
- sync de cosmeticos.

Por tanto, `AppStartupGate` espera un "session check" muy estrecho, no el bootstrap completo de cuenta.

## 8. Carga de inventario y cosmeticos

### Estado inicial

`ShopCosmeticsState.initial()` equivale a:

- `ownedAssetIds=[]`
- `ownedBundleIds=[]`
- `equippedWallpaperId=null`
- `equippedHabitCardSkinId=null`
- `equippedUserCardSkinId=null`

Con ese estado, todos los resolvers sincronos de Home devuelven `null` y las vistas usan fallback.

### Local

`ShopCosmeticsRepository.load()` lee:

- estado guest en `rutio_shop_cosmetics_v1_guest`, si no hay scope,
- estado scoped en `rutio_shop_cosmetics_v1_<userId>`, si hay scope,
- legacy solo si tiene owner seguro.

Si no hay entrada o hay mismatch de owner, devuelve `ShopCosmeticsState.initial()`.

### Cloud

Si `cloudCosmeticsEnabled` esta activo:

- `ShopCosmeticsController` lanza `_syncFromCurrentScope(force:false)` en el constructor.
- Si no hay scope, deja `_cloudState=unauthenticated`, `_cachedState=null`.
- Si hay cache cloud, aplica `ShopCosmeticsCloudState.loading(userId, cache)` y puede usar snapshot cache.
- Despues consulta `CloudCosmeticsRepository.fetchSnapshot()`.
- Si falla y hay cache, usa `stale`.
- Si falla sin cache, aplica fallback `ShopCosmeticsState.initial()`.
- Si llega snapshot remoto, `_applyConfirmedCloudSnapshot` actualiza `_cachedState`, `_cloudState=ready`, incrementa revision y `notifyListeners()`.

### Fondos y cards

- Fondo generico: `lib/widgets/backgrounds/home_landscape_background.dart`, `_DefaultHomeBackgroundVisual`.
- Sustitucion por fondo equipado: `HomeBackground` usa `controller.getEquippedWallpaperAssetOrNullSync()?.assetPath`; `_ReactiveHomeBackgroundScene.didUpdateWidget` cambia `_displayedWallpaperAssetPath`.
- Habit cards: `HomeScreen._equippedHabitCardAsset()` usa `getEquippedHabitCardAssetOrNullSync()`. Si `null`, `HabitCardWidget` recibe `backgroundImageAssetPath=null`.
- User cards: `UserIdentityRow` usa `getEquippedUserCardAssetOrNullSync()?.assetPath`. Si `null`, `UserCardThemeBackground` usa `fallbackDecoration`.

Riesgo confirmado: si el primer build llega antes del snapshot/cached state valido, los tres slots pueden pintar fallback. Cuando `ShopCosmeticsController` notifica, se reconstruyen fondo, habit cards y user card.

## 9. Momento exacto de construccion de Home

Home se construye cuando:

1. `AppStartupGate` devuelve `_StartupDestination.home`.
2. `_buildDestination` retorna `RootGate`.
3. `RootGate` ve `store.isLoading == false`, `store.error == null` y devuelve `HomeScreen`.
4. `HomeScreen.buildContent` ve `root != null` y construye `_HomeLoadedView`.

La condicion que permite Home es local y parcial:

```text
authController.currentUser != null
AND UserStateStore.isLoading == false
AND UserStateStore.state != null
```

Mas el preload de background de `AppStartupGate` si entro por `MaterialApp.home`. No espera:

- `AuthController._syncCurrentUserProfile`
- `ProfileRepository.fetchCurrentProfile`
- `syncSupabaseUserProgressBootstrapBestEffort`
- `syncExistingLocalHabitsOnce`
- `syncExistingLocalHabitLogsOnce`
- `HomeScreen.maybeSyncHabitsFromRemoteBestEffort`
- `GlobalWalletController.syncSession`
- todas las resoluciones cloud de cosmeticos si fallan/timeout/sin cache

En rutas directas `/home` se usa `AuthGate(authenticatedBuilder: HomeScreen)`, por lo que se evita `AppStartupGate` y no se ejecuta el preload de fondo inicial.

## 10. Causas confirmadas del flash

1. **Onboarding/Welcome temporal**
   - `onboardingDone` es local.
   - Reinstalar borra SharedPreferences.
   - `AuthController.isCheckingSession` puede terminar antes de una restauracion efectiva observada por la UI.
   - `AppStartupGate` decide `Welcome` si ve `currentUser == null` y `onboardingDone == false`.

2. **Fondo generico**
   - `HomeBackground` usa `_DefaultHomeBackgroundVisual` cuando `getEquippedWallpaperAssetOrNullSync()` devuelve `null`.
   - `ShopCosmeticsState.initial()` no tiene wallpaper equipado.
   - Si cloud no tiene cache local o tarda/falla, se pinta fallback.

3. **Habit cards genericas**
   - `_equippedHabitCardAsset()` devuelve `null` hasta que `ShopCosmeticsController` tenga estado validado.
   - `HabitCardWidget` recibe `backgroundImageAssetPath=null`.

4. **User card generica**
   - `UserIdentityRow` resuelve user card desde `ShopCosmeticsController`.
   - Si devuelve `null`, usa `fallbackDecoration`.

5. **Habitos vacios**
   - El primer Home usa `activeHabits` local.
   - La pull remota ocurre post-frame.
   - Cache scoped nueva o vacia produce plantilla/local vacio antes del merge remoto.

6. **Datos por defecto**
   - Nombre puede caer a `homeFallbackUsername`.
   - XP/progreso/monedas pueden venir de local/template mientras wallet/progress remoto se sincroniza.

## 11. Causas probables que necesitan validacion dinamica

- Si `Supabase.initialize()` garantiza siempre `auth.currentUser` antes de que se construya `AuthController` en todos los targets. El codigo local no lo asegura explicitamente.
- Si el stream `authStateChanges` emite `initialSession` despues de que `AppStartupGate` ya decidio `Welcome` en reinstalacion.
- Si `ShopCosmeticsController._syncFromCurrentScope` arranca antes de que `UserStateStore.activeLocalScopeUserId` sea el usuario autenticado, quedando inicialmente `unauthenticated` o en scope guest.
- Si el timeout de `HomeBackgroundBootstrapper` de 3 segundos se alcanza con frecuencia en dispositivos lentos.
- Cuantos rebuilds exactos ocurren en dispositivo real con Supabase lento: se puede estimar estaticamente, pero contar frames requiere logs temporales o perfilado.

## 12. Riesgos de reinstalacion

- Se pierde `user_state_v1` y `user_state_v1_<userId>`.
- Se pierde `meta.onboardingDone`.
- Se pierde `rutio_shop_cosmetics_v1_<userId>` y caches cloud de wallet/cosmeticos.
- Si Supabase no restaura sesion automaticamente despues de reinstalar, el arranque cae a usuario sin sesion y `Welcome`.
- Aunque el usuario inicie sesion con cuenta existente, mientras no se pullen habitos/progreso/cosmeticos remotos, la app puede mostrar estado de plantilla o vacio.
- No existe indicador remoto de onboarding para distinguir "cuenta existente que reinstalo" de "usuario nuevo sin onboarding local".

## 13. Riesgos de cambio de cuenta

Hay protecciones importantes:

- `UserStateStore.switchLocalScope` incrementa `_scopeEpoch`, limpia `_state` si cambia el scope y descarta cargas obsoletas.
- `UserStateRepository.save` bloquea guardados si `payloadUserId` no coincide con `activeScopeUserId`.
- `ShopCosmeticsRepository` usa estado scoped y descarta legacy sin owner o con owner mismatch.
- `GlobalWalletController` usa request epoch y userId para ignorar respuestas obsoletas.
- `ShopCosmeticsController` revisa scope/mutation version en cargas cloud.

Riesgos restantes:

- Mientras cambia el scope, puede haber frames con loader o fallback.
- Si una decision de ruta ya quedo en `Welcome`, un auth event posterior no redirige automaticamente desde `Welcome`.
- Las tareas fire-and-forget de `AuthController` pueden notificar en orden distinto y producir varios estados transitorios.

## 14. Riesgos de datos cruzados entre usuarios

Los riesgos mas graves estan mitigados por scope y epoch, pero no desaparecen por completo en UX:

- `UserStateRepository.save` bloquea stale writes autenticadas contra scope incorrecto.
- `_runHabitsRemotePull` valida que todos los `RemoteHabit.userId` y logs pertenezcan al usuario autenticado.
- `_pruneForeignRemoteHabitsFromLocalState` elimina habitos con metadata remota claramente ajena.
- `ShopCosmeticsRepository` descarta legacy con owner mismatch.
- `ShopCosmeticsController` ignora cargas stale si el scope o mutation version cambiaron.

Riesgo residual: durante arranque/cambio de cuenta se puede mostrar fallback o vacio antes de que el estado scoped correcto termine de cargar. No he encontrado evidencia estatica de que se pinte contenido de otro usuario autenticado despues de un cambio de scope; el riesgo observado es mas de "estado incompleto" que de cruce confirmado.

## 15. Logs anadidos

No se han anadido logs nuevos en esta fase.

Logs existentes utiles:

- `[startup] bootstrap started`
- `[startup] bootstrap ready destination=...`
- `[startup] bootstrap failed`
- `[auth] initial auth state`
- `[auth] auth state changed`
- `[auth] profile fetch started/succeeded`
- `[auth] user progress restore status`
- `[auth] habit backfill summary`
- `[user_state_store] switching local scope`
- `[user_state_store] discarded stale load result`
- `[user_state_repository] load source=...`
- `[user_state_storage] read/write key=...`
- `[ShopCosmetics] HomeBackground ... fallback=...`
- `[ShopCosmetics] HomeHabitCard ... fallback=...`
- `[cosmetic_trace] stage=...`
- `[shop_cloud_cosmetics] refresh_started/refresh_applied`
- `[global_wallet] ...`

Para Fase 2 conviene unificarlos con prefijo `[BootstrapAudit]` y timestamps relativos.

## 16. Recomendaciones para Fase 2 y Fase 3

### Fase 2

- Crear instrumentacion temporal `[BootstrapAudit]` con cronometro desde `main()`.
- Registrar decision de ruta con motivo exacto:
  - `currentUserPresent`
  - `isCheckingSession`
  - `onboardingDone`
  - `stateSource`
  - `activeScope`
- Registrar inicio/fin de:
  - Supabase initialize
  - lectura local
  - auth initial session
  - profile fetch
  - user progress restore
  - habits remote pull
  - cosmetics hydrate
  - wallet sync
  - Home first build
- Validar en dispositivo o emulador con conexion lenta/reinstalacion.

### Fase 3

- Implementar un Bootstrap Gate real que modele fases de preparacion:
  - Supabase initialized
  - auth session resolved
  - user scope selected
  - local state loaded for selected scope
  - account metadata/profile resolved or timed out with policy explicita
  - remote bootstrap pulls completados o degradados conscientemente
  - cosmetics ready/cache/fallback decidido
- Mover la decision de onboarding a una fuente remota o hibrida, no solo local.
- Diferenciar "no hay sesion" de "sesion aun restaurandose".
- Evitar que Home se pinte con plantilla si hay una cuenta autenticada y falta pull remota inicial.
- Definir una politica offline: cache scoped valida puede abrir Home; cache vacia autenticada deberia mostrar estado de recuperacion/sync, no datos por defecto.

## 17. Lista priorizada de cambios futuros

1. Separar `AuthController.isCheckingSession` de "suscripcion lista"; debe representar "initial auth session resuelta".
2. Anadir `onboarding_status` remoto o equivalente en perfil/account metadata.
3. Crear Bootstrap Gate con estado explicito y reason codes.
4. Hacer que `AppStartupGate` reaccione a un `initialSession` tardio antes de fijar `Welcome`.
5. Bloquear Home autenticada si el estado local scoped acaba de ser creado desde template y aun no se ha intentado pull remota inicial.
6. Convertir `HomeScreen.initState` remote pull post-frame en parte del bootstrap inicial cuando el usuario esta autenticado.
7. Tratar cosmeticos con estado tri-state: `unknown/loading`, `ready`, `fallbackPolicyApplied`, en lugar de usar `null` como ausencia y como loading.
8. Unificar logs temporales `[BootstrapAudit]`.
9. Anadir tests de reinstalacion/cache vacia con cuenta existente.
10. Anadir tests de `initialSession` tardio.

## Escenarios revisados

| Escenario | Comportamiento esperado actual | Riesgo |
| --- | --- | --- |
| Usuario sin sesion | `Welcome` si `onboardingDone=false`, `SignInScreen` si `true` | Correcto segun estado local, no remoto |
| Usuario autenticado existente | `Home` si `currentUser` esta listo | Home puede abrir antes de pulls remotas |
| Usuario nuevo | `Home` tras sign-up con sesion; Welcome/Auth antes | Sin remoto de onboarding |
| Reinstalacion con cuenta existente | Puede caer en `Welcome` si no hay sesion local restaurada o `currentUser` tarda | Alto |
| Logout y otra cuenta | Scope cambia, estado se limpia/carga | Fallback/loading transitorio |
| Conexion lenta | Splash espera minimo/local/auth estrecho, no todas las remotas | Alto |
| Sin conexion | Cache local puede abrir; sin cache se ven templates/fallbacks | Alto |
| Error Supabase | Best effort; muchos fallos degradan a local/fallback | Medio-alto |
| Cache local vacia | Se crea plantilla | Alto para vacios/defaults |
| Cache local de otro usuario | Guardas de scope bloquean/descartan bastante | Bajo para cruce, medio para fallback |

## Tabla final

| Problema | Causa | Evidencia | Severidad | Fase que lo resolvera |
| -------- | ----- | --------- | --------- | --------------------- |
| Welcome/onboarding temporal en reinstalacion | `onboardingDone` es local y `currentUser` puede no estar listo al decidir | `AppStartupGate._initializeStartup`, `UserStateStore._onboardingDone`, `UserStateRepository.loadOrCreate` | Alta | Fase 2 instrumenta, Fase 3 cambia decision/bootstrap |
| Home con habitos vacios | Primer frame usa `activeHabits` local/template; pull remota va post-frame | `HomeScreen.initState`, `_runHabitsRemotePull`, `buildHomeViewData` | Alta | Fase 3 |
| Fondo generico antes del equipado | `HomeBackground` usa fallback cuando wallpaper sync devuelve `null` | `HomeBackground`, `ShopCosmeticsState.initial`, `ShopCosmeticsController.getEquippedWallpaperAssetOrNullSync` | Alta | Fase 3 |
| Habit cards genericas | Asset de habit card se resuelve sincronicamente y puede ser `null` | `home_shop_cosmetics.dart`, `_habitCard` | Media-alta | Fase 3 |
| User card generica | User card equipada aun no validada/cargada | `UserIdentityRow`, `getEquippedUserCardAssetOrNullSync` | Media | Fase 3 |
| Datos de perfil por defecto | Profile remoto se sincroniza en segundo plano | `AuthController._syncCurrentUserProfile`, `HomeScreen.buildContent` username fallback | Media | Fase 3 |
| Monedas/progreso inconsistentes al inicio | Wallet/progress remoto no bloquean Home | `GlobalWalletController.syncSession`, `syncSupabaseUserProgressBootstrapBestEffort` fire-and-forget | Media | Fase 3 |
| Decision de ruta congelada | `AsyncBootstrapGate` guarda resultado ready; Welcome no redirige por auth event tardio | `AsyncBootstrapGate`, `AppStartupGate._buildDestination` | Alta | Fase 3 |
| Rebuilds multiples en primer arranque | Varios controllers notifican despues de Home | `notifyListeners` en `AuthController`, `UserStateStore`, `ShopCosmeticsController`, `GlobalWalletController` | Media | Fase 2 mide, Fase 3 ordena |
| `setState/markNeedsBuild during build` | No se ha confirmado como causa principal; Home usa post-frame para algunas mutaciones, pero hay `notifyListeners` durante inicializaciones asincronas | `HomeScreen.buildContent`, `AsyncBootstrapGate`, controllers | Baja-media | Fase 2 valida dinamicamente |

## 18. Cierre de validaciones de la Fase 1

### HomeBackgroundBootstrapper

El fallo `Expected: usedFallback=false / Actual: usedFallback=true` no era una regresion productiva confirmada. Era una expectativa de test construida con un entorno incompleto para el comportamiento actual:

- El test guardaba `ShopCosmeticsState` con `ShopCosmeticsRepository().save(...)` antes de crear el store scoped. Eso escribe en el scope guest (`rutio_shop_cosmetics_v1_guest`).
- Despues `_createStore()` fija `activeUserScope='bootstrap-test-user'`.
- `ShopCosmeticsController` resuelve su estado desde el scope actual del `UserStateStore`, no desde guest.
- Ademas, el controller se construia con `cloudEnabled` por defecto, por lo que en el entorno de test entraba en flujo cloud y aplicaba fallback al no tener snapshot remoto valido.

El test esperaba correctamente que un wallpaper local, owned y equipado se precacheara sin fallback, pero no estaba configurando el mismo scope ni fijando explicitamente el modo local. El cambio minimo fue guardar el estado cosmetico con `scopeResolver: () => 'bootstrap-test-user'` y construir `ShopCosmeticsController(cloudEnabled: false)` en este test local. No se modifico codigo productivo.

Resultado: `flutter test test/application/bootstrap/home_background_bootstrapper_test.dart` pasa completo.

### Habitos remotos

El fallo `Supabase client requested before initialization` no venia de `HabitRepository` ni de `HabitLogRepository`: ambos ya estaban inyectados como fakes. La ruta real era colateral:

```text
UserStateStore.syncHabitsFromRemoteBestEffort()
-> _runHabitsRemotePull()
-> _syncStreakProtectionIntoUserState()
-> _streakProtectionRepositoryForStore()
-> SupabaseStreakProtectionRepository()
-> RutioSupabaseClient.instance
```

El pull de habitos ahora tambien intenta reconciliar proteccion de rachas. El test de habitos no inyectaba `StreakProtectionRepository`, asi que el store creaba el repositorio Supabase real y accedia al singleton sin inicializar. Es un mock/fake incompleto del test, no una regresion productiva de la pull de habitos.

El cambio minimo fue inyectar `_FakeStreakProtectionRepository` en `_buildStore()`, devolviendo listas vacias para shields/breaks y success para timezone. No se inicializo Supabase real y no se cambio comportamiento productivo. Durante los tests sigue apareciendo un `MissingPluginException` best-effort del timezone provider de Flutter, pero esta capturado por el codigo productivo y no afecta al resultado.

Resultado: `flutter test test/stores/user_state_store_habits_remote_pull_test.dart` pasa completo.

### Riesgos que se conservan para Fase 2 y Fase 3

- El preload local de wallpaper solo evita fallback si el estado del scope correcto ya esta hidratado y el modo local/cloud esta claro.
- En modo cloud, HomeBackgroundBootstrapper sigue pudiendo caer a fallback si no hay snapshot/cache valido o si falla la resolucion remota.
- La pull de habitos tiene dependencias colaterales: logs, streak protection, timezone y guardas de scope. La Fase 2 deberia instrumentar esas subfases por separado para distinguir "habits loaded" de "habit ecosystem fully reconciled".
- La ausencia de un fake en tests revelo un riesgo arquitectonico real para el Bootstrap Gate futuro: una fase aparentemente de habitos puede tocar otros subsistemas remotos y retrasar o degradar el arranque.
