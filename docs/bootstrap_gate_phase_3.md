# Bootstrap Gate Phase 3

## Fase 3A - Bootstrap Gate

La Fase 3A introdujo un `BootstrapController` tipado y un `AppStartupGate` para decidir la ruta inicial solo cuando la sesion, el scope local, el estado local y el perfil remoto estan resueltos.

```text
App
`-- BootstrapGate
    |-- sesion no resuelta -> Preparando tu espacio...
    |-- sin sesion -> Welcome/Auth
    `-- con sesion
        |-- seleccionar scope
        |-- cargar estado local
        |-- cargar perfil remoto
        `-- decidir
            |-- pending/in_progress -> Onboarding temporal
            `-- completed -> Home
```

Estados 3A: `idle`, `resolvingSession`, `selectingUserScope`, `loadingLocalState`, `loadingRemoteProfile`, `decidingDestination`, `ready`, `failed`.

Cada ejecucion incrementa `runId`; los resultados tardios solo pueden escribir si el run sigue vigente. Para usuarios autenticados, `UserStateStore.onboardingDone` no decide la ruta: manda el perfil remoto.

Rutas protegidas por `AppStartupGate`: `/root`, `/home`, `/shop` y la ruta antigua de `AuthGate`.

## Fase 3B - Preparacion de datos esenciales

Home solo se construye para cuentas autenticadas con perfil remoto `completed` cuando las barreras esenciales del usuario vigente tienen un resultado definitivo.

## Arquitectura

```text
Bootstrap
|-- resolver sesion
|-- seleccionar scope
|-- cargar estado local
|-- cargar perfil remoto
`-- preparar cuenta
    |-- habitos + logs + continuidad
    |-- cosmeticos scoped
    |-- precache de assets
    `-- datos visibles adicionales
        |
      Home ready
```

Despues de sesion, scope, estado local y perfil remoto, el bootstrap lanza en paralelo:

- Habitos esenciales.
- Cosmeticos esenciales.

La carga de assets se ejecuta despues porque depende de los cosmeticos resueltos.

## Dominios Esenciales

- Scope local autenticado correcto.
- Estado local scoped.
- Perfil remoto.
- Habitos visibles del dia.
- Habit logs necesarios para el merge remoto/local.
- Streak protection y timezone cuando forman parte del pull de habitos.
- Wallpaper equipado.
- Habit card equipada.
- User card equipada.
- Asset paths visibles ya cargados.

Wallet, XP y progreso se aceptan desde cache scoped local para el primer frame. Home sigue usando `GlobalWalletController` si tiene estado confirmado o fallback local scoped.

## Dominios Secundarios

- Analitica.
- Precarga de catalogos completos.
- Contenido de pantallas no abiertas.
- Prompt de permisos de notificaciones.
- Backfills no visibles.
- Refreshes posteriores que no cambian el primer frame.

## Contratos de Readiness

`EssentialHabitsBootstrapResult`:

- `unknown`
- `loading`
- `readyFromCache`
- `readyFromRemote`
- `confirmedEmpty`
- `degraded`
- `failed`
- `emptyFromTemplate`

`CosmeticsBootstrapResult`:

- `unknown`
- `loading`
- `readyFromCache`
- `readyFromRemote`
- `confirmedEmpty`
- `degraded`
- `failed`

Cada resultado incluye userId/scope, fuente, request id, duracion, error recuperable y `canBuildHome`.

## Politica de Cache

La cache scoped valida puede abrir Home si pertenece al usuario actual.

En habitos, una cache con habitos activos es valida. Una lista vacia solo es valida si existe marca persistida de remoto vacio confirmado. Una lista vacia de template se trata como `emptyFromTemplate` y requiere remoto.

En cosmeticos, la cache debe resolver ownership y assets equipados. Si es valida, Home puede abrir sin flash y el refresh remoto posterior continua fuera de la barrera.

## Vacio Temporal y Vacio Confirmado

`emptyFromTemplate` significa que el estado local fue creado desde plantilla y todavia no confirma los datos reales del usuario.

`confirmedEmpty` significa que Supabase confirmo que no hay habitos o cosmeticos equipados. En ese caso una lista vacia o fallback visual son legitimos.

## Bootstrap de Habitos

`UserStateStore.prepareEssentialHabitsForBootstrap(userId:)` coordina:

- Cache scoped.
- `fetchHabitsForCurrentUser`.
- Descarga de logs por habit remoto.
- Validacion de user id.
- Merge con estado local.
- Streak protection.
- Timezone cuando pertenece al mismo flujo.
- Guardado local final.
- Marca de vacio remoto confirmado.
- Descarte por `scopeEpoch`.

El pull inicial ya no depende de `HomeScreen.initState`; Home conserva refresh manual y refresh al volver a foreground.

## Bootstrap de Cosmeticos

`ShopCosmeticsController.prepareEssentialCosmeticsForBootstrap(userId:)` coordina:

- Cambio efectivo al scope autenticado.
- Invalidacion de guest u otra cuenta.
- Cache cloud scoped.
- Snapshot remoto cuando no hay cache usable.
- Validacion de ownership.
- Resolucion de wallpaper, habit card y user card.
- Notificacion final a widgets.
- Descarte por scope y version de mutacion cloud.

Si remoto falla sin cache, el resultado es `failed`. Si existe cache scoped valida, el resultado puede ser `degraded`.

## Precache de Assets

`BootstrapController` recibe los `ShopAsset` visibles desde cosmeticos y usa `BootstrapEssentialAssetPreloader` para cargar los asset paths con `rootBundle`. Los paths ya cargados no se repiten. No se precarga el catalogo completo.

## Cancelacion Logica

- `BootstrapController`: `runId` y usuario vigente.
- `UserStateStore`: `scopeEpoch`.
- `ShopCosmeticsController`: scope actual y version de mutacion cloud.

Logout, cambio de cuenta y retry invalidan resultados antiguos.

## Politica de Errores

El gate muestra error recuperable si una barrera esencial falla sin cache usable:

```text
No hemos podido preparar tu espacio.

Comprueba tu conexion e intentalo de nuevo.

[Reintentar]
```

Errores distinguidos internamente: habitos esenciales, cosmeticos esenciales, assets esenciales, scope cambiado, sesion obsoleta y respuesta de otro usuario.

## Matriz Home

```text
Perfil pending/in_progress                  -> onboarding
Perfil completed + habitos cache valida     -> continuar barreras
Perfil completed + habitos remoto ready     -> continuar barreras
Perfil completed + habitos vacio confirmado -> continuar barreras
Perfil completed + habitos fallo sin cache  -> failed
Cosmeticos cache valida                     -> Home permitido + refresh posterior
Cosmeticos remoto ready                     -> Home permitido
Cosmeticos vacio confirmado                 -> Home permitido con fallback legitimo
Cosmeticos fallo sin cache                  -> failed
Assets esenciales cargados                  -> destination=home
Cambio de usuario/logout durante carga      -> descartar resultado
```

## Logs y Metricas

```text
[Bootstrap] run=<id> essential_habits_started
[Bootstrap] run=<id> essential_habits_ready source=cache|remote|confirmed_empty|degraded duration_ms=<n>
[Bootstrap] run=<id> essential_cosmetics_started
[Bootstrap] run=<id> essential_cosmetics_ready source=cache|remote|confirmed_empty|degraded duration_ms=<n>
[Bootstrap] run=<id> essential_assets_preloaded duration_ms=<n>
[Bootstrap] run=<id> home_ready total_ms=<n>
[Bootstrap] run=<id> stale_result_discarded domain=<domain>
```

Los logs de tienda obfuscan scopes y no registran correos, tokens ni IDs completos.

## Tests

Se ampliaron:

- `test/application/bootstrap/bootstrap_controller_test.dart`: barreras paralelas, fallo esencial, retry, logout, rutas directas y widget test sin frame generico.
- `test/stores/user_state_store_habits_remote_pull_test.dart`: cache scoped valida, template vacio no listo, remoto vacio confirmado, pull remoto antes de Home e in-flight compartido.
- `test/features/shop/application/shop_cosmetics_controller_cloud_test.dart`: cache scoped sin flash, espera remota sin cache, ausencia remota confirmada, fallo sin cache y degradado con cache.

## Datos Post-Home

Siguen despues de Home:

- Refresh remoto de cosmeticos cuando se abrio con cache.
- Pulls manuales o de foreground.
- Prompt de permisos.
- Analitica.
- Backfills.
- Datos de pantallas no abiertas.

## Pendiente Fase 4 y Fase 6

Fase 4 deberia formalizar una politica offline completa, mensajes de error por dominio y observabilidad persistente. Fase 6 deberia revisar prefetch visual avanzado, contrato remoto explicito para wallet/progreso si deja de bastar cache scoped, y reduccion del refresh duplicado historico de cosmeticos sin cambiar reglas de compra/equip.

## Fase 3B - Correccion del cold start y primer frame

### Cold start e in-app bootstrap

El primer run creado por `BootstrapController` al iniciar el proceso se marca como `coldStart`. No se persiste en disco: pertenece solo al ciclo de vida actual de la app. Cualquier run posterior se marca como `inAppBootstrap`, incluyendo retry, login manual, logout/login, cambio de cuenta y finalizacion de onboarding.

Durante `coldStart`, `AppStartupGate` conserva `SplashScreen` mientras el bootstrap no este listo o fallido. Durante `inAppBootstrap`, el gate muestra `BootstrapPreparationScreen` con `Preparando tu espacio...`.

### Politica visual

| Escenario                       | Pantalla durante bootstrap   | Destino            |
| ------------------------------- | ---------------------------- | ------------------ |
| Cold start con sesion completed | Splash                       | Home personalizada |
| Cold start sin sesion           | Splash                       | Welcome/Auth       |
| Login manual completed          | Preparando tu espacio...     | Home personalizada |
| Registro nuevo pending          | Preparacion minima necesaria | Onboarding         |
| Cambio de cuenta                | Preparando tu espacio...     | Destino remoto     |
| Error remoto                    | Error recuperable            | Reintentar         |

La splash no recibe una duracion minima nueva. Solo permanece porque el bootstrap real sigue pendiente.

### Causa del frame generico

El frame generico venia de dos fuentes combinadas:

- `AppStartupGate` sustituia el primer run frio por `Preparando tu espacio...`, dejando ver una pantalla intermedia aunque el usuario venia de una sesion restaurada.
- `HomeBackgroundBootstrapper` seguia llamando `hydrate()` por su cuenta, creando una segunda fuente de preparacion visual capaz de observar o aplicar estado anterior justo al entrar en Home.

Ademas, el contrato de cosmeticos no exponia explicitamente que los resolvers sincronicos ya estuvieran verificados para la revision aplicada.

### Orden final de cosmeticos

El orden requerido antes de publicar Home queda:

```text
snapshot recibido
-> snapshot validado
-> snapshot aplicado al ShopCosmeticsController
-> cache/state/revision actualizados
-> listeners notificados
-> resolvers sincronicos verificados
-> assets visibles precargados
-> publishing_home
```

`CosmeticsBootstrapResult` incluye `appliedRevision`, `resolversVerified` y `controllerIdentity`. El bootstrap falla de forma recuperable si el resultado permite Home pero los resolvers no estan verificados.

### Verificacion previa a Home

La verificacion confirma que:

- El scope actual coincide con el usuario del bootstrap.
- El controller no esta resolviendo estado guest.
- El snapshot cloud, cuando existe, pertenece al mismo scope.
- La cache interna pertenece al scope vigente.
- Wallpaper, habit card y user card equipados coinciden con lo que devuelven los resolvers sincronicos.
- La revision aplicada queda registrada antes de `destination=home`.

### Precache y cargas duplicadas

`BootstrapController` conserva la responsabilidad de precargar los assets visibles resueltos. `HomeBackgroundBootstrapper` ya no hidrata el controller; solo precarga el wallpaper que el controller ya expone sincronicamente. Asi queda una sola fuente de preparacion esencial.

El refresh cloud automatico inicial se comparte cuando sigue pendiente para el mismo scope, evitando que el bootstrap esencial dispare una segunda hidratacion equivalente. Los refresh posteriores legitimos siguen permitidos cuando se abre con cache scoped valida o tras operaciones de tienda.

### Tests anadidos/reforzados

- Cold start conserva `SplashScreen` y no muestra `Preparando tu espacio...`.
- Home no aparece mientras los cosmeticos estan pendientes.
- Login/retry interno conserva `Preparando tu espacio...`.
- `/shop` directo no evita las barreras esenciales.
- Bootstrap no publica Home si los resolvers cosméticos no estan verificados.
- El resultado cosmético registra revision aplicada antes de Home.
- `HomeBackgroundBootstrapper` no hidrata por su cuenta.
- Shop cloud ajusta las expectativas de refresh/RPC al nuevo contrato deduplicado.

### Flujo final esperado

```text
Cold start autenticado
-> Splash
-> sesion + scope + estado local + perfil remoto
-> habitos esenciales y cosmeticos esenciales
-> resolvers sincronicos verificados
-> assets visibles precargados
-> Home personalizada
```

### Diagnostico diferencial: cold start frente a login manual

Secuencia real del cold start autenticado:

```text
providers creados con currentUser restaurado
-> ShopCosmeticsController inicia refresh cloud inicial
-> AuthController recibe initialSession del mismo usuario
-> Bootstrap cold_start resuelve sesion y scope
-> bootstrap aplica snapshot cosmetico revision N
-> Bootstrap crea CosmeticsReadyToken
-> assets visibles precargados
-> token revalidado
-> publishing_home
-> home_first_build valida la misma instancia/scope/revision
```

Secuencia real del login manual:

```text
providers creados sin currentUser
-> no hay refresh cloud autenticado inicial compitiendo
-> signIn resuelve usuario y scope
-> Bootstrap in_app prepara habitos y cosmeticos
-> publishing_home
```

El evento exacto que causaba la perdida temporal era un refresh cloud del mismo usuario iniciado antes o alrededor del bootstrap. El metodo afectado era `ShopCosmeticsController._loadCloudState`: al entrar en `loading` sin cache local se perdia el snapshot confirmado del controller; si ese refresh fallaba despues de que el bootstrap ya habia aplicado la revision N, la rama de error no encontraba `currentSnapshot` y podia aplicar `ShopCosmeticsState.initial()` como fallback visible.

Antes del evento:

```text
scope = usuario A
revision = N
snapshot confirmado con wallpaper/habit card/user card equipados
```

Despues del evento antiguo:

```text
scope = usuario A
revision = N, pero cloudState = failed sin snapshot
cachedState = initial()
resolvers sincronicos = fallback temporal
```

Solo ocurria en cold start porque el provider de cosmeticos podia arrancar un refresh cloud con la sesion restaurada antes de que el bootstrap terminara. En login manual, el controller nace sin usuario autenticado y el refresh autenticado no queda compitiendo por delante del bootstrap de entrada.

La correccion minima mantiene el ultimo snapshot confirmado durante `loading` y durante fallos de refresh del mismo usuario. Un evento redundante de auth para el mismo usuario se ignora en `BootstrapController` aunque el bootstrap aun no este `ready`; solo logout o cambio real de usuario invalidan. Un cambio real de scope invalida el `CosmeticsReadyToken`.

`CosmeticsReadyToken` fija:

- identidad del `ShopCosmeticsController`;
- usuario y scope;
- revision aplicada;
- IDs equipados de wallpaper, habit card y user card;
- estado de resolucion sincronica de los tres slots.

Bootstrap crea el token despues de aplicar/verificar cosmeticos, precarga los assets asociados y lo revalida antes de publicar Home. En el primer build, Home registra `home_first_build` y `home_cosmetics_resolved`; si observa otra instancia, otro scope, una revision inferior o resolvers en fallback temporal, registra `home_readiness_contract_violated` y falla en debug.

Tests anadidos:

- Cold start restaurado ignora `initialSession` redundante del mismo usuario antes del primer Home.
- Refresh fallido del mismo usuario sin cache conserva el snapshot visible y la revision autorizada.
- El token sobrevive a notificacion redundante del mismo scope y se invalida ante cambio real de usuario.

## Correccion del primer frame visual de Home

El ultimo flash visual no estaba en la decision remota ni en el gate. `publishing_home` y `home_first_build` ya observaban el mismo usuario, scope, controller, revision y resolvers cosmeticos. La causa restante era local al primer paint de los widgets:

- `RootBundleEssentialAssetPreloader` solo cargaba bytes con `rootBundle.load(path)`, pero no esperaba el primer frame decodificado del `ImageProvider` que usarian los widgets.
- `_CustomWallpaperBackgroundVisual` mantenia `_DefaultHomeBackgroundVisual` montado debajo de un wallpaper valido.
- `UserCardThemeBackground` mantenia `userIdentityRowFallbackBackground` montado debajo de una skin valida.
- `HabitCardWidget` mantenia la superficie blanca generica aunque existiera `backgroundImageProvider`.

La correccion minima es que `assets_preloaded` signifique imagen lista para pintar, no solo bytes disponibles. Bootstrap precarga los assets visibles resolviendo el `ImageStream` hasta el primer frame, usando el mismo helper compartido `buildShopAssetImageProvider(assetPath)` que usan Home background, habit card y user card.

El primer mount de cada componente queda inicializado directamente desde el asset recibido:

- `HomeBackground` inicializa `_displayedWallpaperAssetPath` y `_preparedWallpaperProvider` desde `widget.wallpaperAssetPath` en `initState`.
- `HabitCardWidget` construye el provider desde `backgroundImageProvider` o desde `backgroundImageAssetPath` antes de pintar la superficie.
- `UserCardThemeBackground` construye el provider compartido desde `backgroundImageAssetPath` en el mismo build.

Cuando un asset valido esta presente, no se monta la decoracion fallback de ese componente en el primer frame. El fallback sigue existiendo para el caso legitimo de ausencia de asset y para error real de carga. Las transiciones de cambio de wallpaper se preservan con `AnimatedSwitcher`, y las animaciones propias de la habit card se mantienen; `gaplessPlayback` evita huecos durante reemplazos de imagen.

Logs de primer frame:

```text
[HomeFirstFrame] component=background inputAsset=<present|null> displayedAsset=<present|null> fallback=<true|false>
[HomeFirstFrame] component=habit_card inputAsset=<present|null> displayedAsset=<present|null> fallback=<true|false>
[HomeFirstFrame] component=user_card inputAsset=<present|null> displayedAsset=<present|null> fallback=<true|false>
```

Interpretacion esperada en cold start autenticado con cosmeticos equipados:

```text
component=background inputAsset=present displayedAsset=present fallback=false
component=habit_card inputAsset=present displayedAsset=present fallback=false
component=user_card inputAsset=present displayedAsset=present fallback=false
```

Esto explica la diferencia con login manual: el login manual suele llegar a Home tras mas frames internos y rebuilds, por lo que la decodificacion de imagen ya podia estar lista antes del paint inspeccionado. En cold start autenticado se pasa directamente de Splash al primer Home real, asi que una capa fallback persistente o una imagen aun sin primer frame se hacia visible.

No se anaden delays, capas de espera, fades artificiales, cambios de duracion de Splash, migraciones ni cambios en Supabase. La correccion vive en la preparacion visual y en el contrato de widgets del primer frame.

Tests anadidos/reforzados:

- `test/widgets/shop_equipped_cosmetics_ui_test.dart`: primer pump de background, habit card y user card con asset equipado sin fallback visual montado.
- `test/screens/home/home_screen_refresh_test.dart`: primer pump de Home con wallpaper, habit card y user card preparados antes de `pumpAndSettle`.
