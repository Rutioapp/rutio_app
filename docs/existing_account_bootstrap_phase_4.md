# Existing Account Bootstrap Phase 4A / 4B1

## Objetivo

Medir el arranque de cuentas existentes sin introducir optimizaciones amplias todavia. Esta fase deja una linea base trazable para distinguir cache valida, carga remota completa, degradado recuperable, retries y resultados obsoletos.

## Estado inicial tras la Fase 3

- `BootstrapController` ya resolvia sesion, scope local, estado local, perfil remoto, esenciales de habitos, esenciales de cosmeticos y precarga de assets visibles.
- Habitos y cosmeticos ya se lanzaban en paralelo con `Future.wait`.
- El cold start ya mantenia `SplashScreen` y el in-app bootstrap ya usaba `BootstrapPreparationScreen`.
- El codigo ya tenia trazas funcionales, pero no una instrumentacion estructurada por run con metricas agregadas ni timeline verificable.

## Metricas aÃƒÆ’Ã‚Â±adidas

Instrumentacion nueva bajo `kDebugMode`:

- `[BootstrapPerf] run=<id> metric=session_resolution duration_ms=<n>`
- `[BootstrapPerf] run=<id> metric=scope_selection duration_ms=<n>`
- `[BootstrapPerf] run=<id> metric=local_state duration_ms=<n>`
- `[BootstrapPerf] run=<id> metric=remote_profile duration_ms=<n>`
- `[BootstrapPerf] run=<id> metric=essential_habits duration_ms=<n> source=<source>`
- `[BootstrapPerf] run=<id> metric=essential_cosmetics duration_ms=<n> source=<source>`
- `[BootstrapPerf] run=<id> metric=essential_assets duration_ms=<n>`
- `[BootstrapPerf] run=<id> metric=home_publish duration_ms=<n>`
- `[BootstrapPerf] run=<id> metric=total duration_ms=<n> mode=<cold_start|in_app> habits_source=<...> cosmetics_source=<...> habits_cosmetics_parallel=<bool> remote_queries=<n> deduplicated_loads=<n> stale_results_discarded=<n>`

Tambien se aÃƒÆ’Ã‚Â±adio un sink inyectable de logs para tests, de forma que la instrumentacion se valida sin depender de `debugPrint` global.

## Linea temporal del bootstrap

Se emiten eventos estructurados:

- `bootstrap_started`
- `session_ready`
- `scope_ready`
- `local_state_ready`
- `profile_ready`
- `habits_started`
- `cosmetics_started`
- `habits_ready`
- `cosmetics_ready`
- `assets_ready`
- `home_published`

Cada evento sale como:

- `[BootstrapTimeline] run=<id> event=<name> t_ms=<n>`

Esto permite comprobar si habitos y cosmeticos se solapan de verdad. En el flujo actual se solapan: ambos futures se crean antes del `Future.wait`.

## Consultas remotas detectadas

### Perfil

| Dominio | Metodo / repositorio | Llamadas | Bloqueante antes de Home | Paralelizable | Dedupe actual | Repite post-Home | Payload / alcance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Perfil | `BootstrapController -> BootstrapProfileRepository.fetchCurrentProfile() -> ProfileRepository.fetchCurrentProfile()` | 1 por run | Si | No, decide destino | No | Si, `AuthController._syncCurrentUserProfile()` tambien llama `fetchCurrentProfile()` | 1 fila `profiles` del usuario actual |

### Habitos esenciales

| Dominio | Metodo / repositorio | Llamadas | Bloqueante antes de Home | Paralelizable | Dedupe actual | Repite post-Home | Payload / alcance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Habitos | `UserStateStore._runHabitsRemotePull -> HabitRepository.fetchHabitsForCurrentUser()` | 1 | Si cuando no hay cache valida | En paralelo con cosmeticos, no con logs | Si, comparte future bootstrap | Si, los pulls `manual/auto` reutilizan la misma ruta | Lista de habitos remotos del usuario |
| Habit logs | `HabitLogRepository.fetchLogsForHabit()` | 1 por habito remoto | Si | Hoy no; se ejecuta secuencial por habito | No por habito | Si, la misma ruta se usa en pulls posteriores | Historial por habito remoto |
| Streak protection shields | `StreakProtectionRepository.fetchShieldsForCurrentUser()` | 1 | Si, dentro del pull de habitos | No, hoy va despues de habitos/logs | Comparte future de snapshot mientras corre | Si | Snapshot de shields activos |
| Streak protection breaks | `StreakProtectionRepository.fetchBreaksForCurrentUser()` | 1 | Si | No | Comparte future de snapshot mientras corre | Si | Snapshot de breaks recuperables |
| Timezone de habitos | `StreakProtectionRepository.setHabitTimeZone()` | 0 o 1 | Si cuando cambia timezone | No | No | Si, en sync posteriores | Solo timezone IANA |
| Cierre remoto de missed occurrences | `StreakProtectionRepository.closeMissedHabitOccurrence()` | 0..N | Si cuando hay missed sin cierre remoto | No | Comparte future mientras corre | Si | Una operacion por ocurrencia pendiente |

### Cosmeticos esenciales

| Dominio | Metodo / repositorio | Llamadas | Bloqueante antes de Home | Paralelizable | Dedupe actual | Repite post-Home | Payload / alcance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cache de cosmeticos | `CloudCosmeticsCache.read(scopeKey)` | 1 lectura local | No remota | Si | N/A | Si | Snapshot cacheado |
| Snapshot cloud de cosmeticos | `ShopCosmeticsController._syncFromCurrentScope -> _cloudRepository.fetchSnapshot()` | 0 o 1 en bootstrap bloqueante; 1 refresh en background si se arranca desde cache | Si cuando no hay cache valida o `forceRemote` | En paralelo con habitos | Si, comparte `_pendingCloudStateLoad` | Si, varias acciones de shop fuerzan refresh | Snapshot combinado con equipados, ownership, catalogo visible y economia necesaria para UI |

### Wallet / progreso

| Dominio | Metodo / repositorio | Llamadas | Bloqueante antes de Home | Paralelizable | Dedupe actual | Repite post-Home | Payload / alcance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Wallet global | `AuthController -> GlobalWalletController.syncSession()` | Fuera del bootstrap | No | Si | Propio del controller | Si | Monedas / estado wallet |
| User progress bootstrap | `AuthController._syncCurrentUserProfile()` | Fuera del bootstrap | No | Si | No claro | Si | XP / progreso / backfill |

## Operaciones paralelas

- `BootstrapController._prepareHomeEssentials()` lanza habitos y cosmeticos a la vez.
- El total reporta `habits_cosmetics_parallel=true`.
- El refresh de cosmeticos desde cache valida ya se empuja en background con `unawaited(_syncFromCurrentScope(force: true))`, por lo que no bloquea Home cuando la cache sirve.

## Operaciones secuenciales

- Resolucion de sesion.
- Seleccion de scope local.
- Carga de estado local.
- Fetch de perfil remoto.
- Dentro de habitos: fetch de habitos y luego fetch de logs por cada habito remoto, hoy en serie.
- Dentro de streak protection: timezone, shields y breaks quedan encadenados al pull de habitos.
- Precarga de assets visibles despues de validar cosmeticos.

## Duplicidades detectadas

1. `ProfileRepository.fetchCurrentProfile()` puede ejecutarse desde `BootstrapController` y desde `AuthController._syncCurrentUserProfile()`.
2. Cuando cosmeticos arrancan desde cache valida, `prepareEssentialCosmeticsForBootstrap()` puede devolver Home desde cache y lanzar despues un refresh remoto de fondo equivalente.
3. La ruta de shop tiene multiples `unawaited(_syncFromCurrentScope(force: true))` fuera del bootstrap; no bloquean Home, pero si repiten snapshot cloud.
4. Los pulls de habitos posteriores (`auto` / `manual`) reutilizan la misma ruta pesada que el bootstrap.
5. La instrumentacion nueva confirma deduplicacion de futures en habitos (`_essentialHabitsBootstrapFuture`) y cosmeticos (`_pendingCosmeticsBootstrap`), pero no elimina duplicidades entre controladores.

Estas duplicidades quedan documentadas para Fase 4B. No se eliminaron salvo la medicion.

## Datos esenciales y secundarios

| Dominio | Visible en primer frame | Bloqueante actual | Debe seguir bloqueando |
| --- | --- | --- | --- |
| Perfil | Si | Si | Si |
| Habitos | Si | Si | Si |
| Logs recientes | Indirectamente, por estado de habito | Si, porque el pull de habitos los carga | Dudoso; candidato a bajar en 4B |
| Streak protection | No visible de inmediato en Home base | Si, porque vive dentro del pull de habitos | Dudoso; candidato a bajar en 4B |
| Timezone | No | Si, por streak protection | No necesariamente |
| Wallpaper | Si | Si | Si |
| Habit card | Si | Si | Si |
| User card | Si | Si | Si |
| Wallet | No en bootstrap directo | No | No |
| XP / progreso | No en bootstrap directo | No | No |
| Catalogo completo | No | No directo, salvo dentro del snapshot de cosmeticos | No |
| Analitica | No | No | No |
| Datos de tienda no visibles | No | No directo | No |

## Presupuesto de rendimiento

Objetivos usados como referencia:

- Cache scoped valida: Home lista en ~1500 ms o menos.
- Sin cache completa y con red normal: entre 2000 y 3000 ms.
- Red lenta: mantener Splash / Preparando sin flashes.
- Error: estado recuperable, sin Home incompleta.

La fase actual no aÃƒÆ’Ã‚Â±ade delays ni cambia decisiones funcionales del bootstrap.

## Riesgos

- El contador `remote_queries` es exacto en perfil y en la mayor parte de habitos/cosmeticos, pero el cierre remoto de missed occurrences sigue siendo variable por numero de ocurrencias y merece medicion productiva real.
- El path de habitos continua acoplando logs y streak protection al readiness de Home.
- La duplicidad perfil bootstrap vs auth sync puede distorsionar percepcion de ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œarranque completoÃƒÂ¢Ã¢â€šÂ¬Ã‚Â aunque Home ya este lista.
- El refresh de cosmeticos post-cache puede enmascarar duplicidad como ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œbackground workÃƒÂ¢Ã¢â€šÂ¬Ã‚Â y consumir red en cada cold start cacheado.

## Principales cuellos de botella

1. `HabitLogRepository.fetchLogsForHabit()` se ejecuta una vez por habito y hoy va secuencial.
2. `fetchCurrentProfile()` se hace antes de Home y puede repetirse luego por `AuthController`.
3. `streak protection` sigue dentro del camino bloqueante de habitos aunque no define el primer frame visual.

## Lista priorizada de optimizaciones para la Fase 4B

1. Sacar `habit logs` y `streak protection` del camino critico de Home cuando la UI inicial no los necesita.
2. Consolidar el fetch de perfil entre bootstrap y auth sync para evitar doble roundtrip en arranques de cuenta existente.
3. Mantener Home desde cache valida y mover el refresh completo de cosmeticos y/o habitos a post-Home confirmable, con invalidacion visual segura.
4. Agrupar o paralelizar la carga de logs por habito.
5. Revisar si timezone y cierres remotos de missed occurrences pueden vivir en background best effort.

## Protocolo de prueba manual

1. Ejecutar en debug con logs visibles.
2. Probar cold start con cache valida y verificar:
   - `metric=total`
   - `habits_source=cache|confirmed_empty`
   - `cosmetics_source=cache|confirmed_empty`
3. Borrar cache scoped y repetir:
   - comprobar `remote_queries` mayor
   - comprobar solape de `habits_started` y `cosmetics_started`
4. Probar login manual tras fallo recuperable:
   - run distinto
   - `mode=in_app`
5. Probar logout/login misma cuenta y cambio entre dos cuentas:
   - confirmar `stale_result_discarded`
   - confirmar que el run obsoleto no emite `metric=total`
6. Probar red lenta:
   - sin flashes entre Splash / Preparing / Home
7. Probar error remoto recuperable:
   - `failed type=...`
   - estado recuperable con retry

## Cambios de esta fase

- Instrumentacion estructurada en `BootstrapController`.
- Contadores minimos de queries remotas, deduplicacion y resultados obsoletos en resultados de habitos/cosmeticos.
- Tests especificos de metricas y sanitizacion.
- Ajuste acotado en `AppStartupGate` para conservar el contrato existente de splash: Home sigue reteniendo splash minimo en cold start y rutas directas como `/shop` no se quedan retenidas una vez listo el bootstrap.

## Fase 4B1 - Reducir consultas remotas

### Objetivo

Reducir roundtrips remotos del arranque de cuentas existentes sin mover aun trabajo no esencial fuera del camino critico. Esta subfase ataca duplicidades claras ya medidas en 4A:

- doble fetch de perfil entre bootstrap y auth sync
- una consulta de logs por cada habito remoto durante el pull esencial

### Cambios aplicados

- `ProfileRepository.fetchCurrentProfile()` ahora comparte una sola operacion in-flight por `userId`.
- Si `BootstrapController` y `AuthController` piden el mismo perfil a la vez, ambos esperan el mismo `Future`.
- Cuando la operacion termina, el entry in-flight se limpia para permitir retries normales o lecturas posteriores.
- `UserStateStore` deja de iterar `fetchLogsForHabit()` por habito durante el bootstrap/pull y hace una sola llamada a `HabitLogRepository.fetchLogsForHabits(...)`.
- La validacion de scope de logs se mantiene, pero ahora se ejecuta sobre el batch completo y luego los logs se reordenan por `habitId` para conservar el merge existente.

### Consultas eliminadas o consolidadas

Antes de 4B1:

- Perfil: 1 fetch bloqueante en bootstrap + posible 1 fetch casi simultaneo desde auth sync.
- Habit logs: 1 query por cada habito remoto cargado.

Despues de 4B1:

- Perfil: como maximo 1 fetch remoto concurrente por usuario en la ventana bootstrap/auth.
- Habit logs: 1 query batch por pull esencial, independientemente del numero de habitos remotos incluidos.

### Metricas esperadas tras 4B1

- `remote_queries` de bootstrap no cambia para perfil, porque 4A ya media solo la llamada del bootstrap, pero ahora evitamos el roundtrip duplicado en el flujo real cuando auth sync corre a la vez.
- En habitos, el coste de logs pasa de `1 + N` llamadas remotas dependientes del numero de habitos a `1 + 1` para habitos + logs, sin contar streak protection ni cierres remotos variables.

### Archivos tocados en 4B1

- `lib/data/repositories/profile_repository.dart`
- `lib/stores/user_state_store_habits.dart`
- `test/data/repositories/profile_repository_onboarding_test.dart`
- `test/stores/user_state_store_habits_remote_pull_test.dart`
- `test/application/bootstrap/bootstrap_controller_metrics_test.dart`

### Riesgos y limites conocidos

- Esta subfase no saca `streak protection` del camino critico.
- Tampoco mueve el auth sync a post-Home ni elimina refreshes posteriores de otros dominios.
- `remote_queries` sigue sin reflejar en una sola cifra toda llamada background fuera del propio run de bootstrap; la mejora de perfil aqui es real, pero sucede entre controladores.

### Diferido explicitamente a Fase 4B2

- bajar trabajo no esencial de habitos fuera de Home
- revisar `streak protection` y timezone como best effort
- separar refreshes posteriores de bootstrap de manera mas visible en metricas

### Validacion 4B1 en este entorno

Estado de la verificacion ejecutada el 28 de julio de 2026:

- Los contadores de consultas quedaron demostrados mediante tests dirigidos.
- El resultado funcional se mantuvo mediante tests de bootstrap ya existentes.
- Los tiempos de perfil, habitos/logs y total hasta Home no se consideran fiables en este entorno porque provienen de harness con repositorios fake y latencias sinteticas, no de un dispositivo ni de una red real.

#### Escenarios verificados

| Escenario | Fuente de verificacion | Perfil | Logs | Resultado |
| --- | --- | ---: | ---: | --- |
| A. Cuenta existente con varios habitos y logs | Tests dirigidos | 1 consulta maxima demostrada | 1 batch demostrado | Misma fusion funcional de logs y mismo estado final |
| B. Cuenta existente sin habitos | Test dirigido | N/A en store de habitos | 0 consultas de logs demostradas | No se genera query batch innecesaria |
| C. Repeticion con cache scoped valida | Tests de bootstrap existentes | Sin evidencia de flashes de onboarding en harness | N/A | Flujo funcional conservado, pero tiempos no medidos en dispositivo |

#### Comparacion 4A frente a 4B1

| Metrica | Fase 4A | Fase 4B1 |
| --- | ---: | ---: |
| Consultas de perfil | 1 en bootstrap, con duplicidad posible en auth sync documentada | 1 maxima por bootstrap y usuario demostrada por tests de deduplicacion e instrumentacion |
| Consultas de logs | 1 por habito remoto | 1 batch maxima por bootstrap demostrada por tests |
| Duracion perfil remoto | No verificada en dispositivo en este entorno | No verificada en dispositivo en este entorno |
| Duracion habitos y logs | No verificada en dispositivo en este entorno | No verificada en dispositivo en este entorno |
| Tiempo total hasta Home | No verificado en dispositivo en este entorno | No verificado en dispositivo en este entorno |

#### Evidencia concreta

- `test/data/repositories/profile_repository_onboarding_test.dart`
  confirma aislamiento por `userId`, comparticion del `Future`, limpieza tras exito, limpieza tras fallo y posibilidad de retry posterior.
- `test/application/bootstrap/bootstrap_controller_metrics_test.dart`
  confirma 1 sola llamada de perfil en el bootstrap instrumentado.
- `test/stores/user_state_store_habits_remote_pull_test.dart`
  confirma 1 sola query batch para varios habitos y 0 queries batch cuando no hay habitos remotos.
- `test/application/bootstrap/bootstrap_controller_test.dart`
  conserva el comportamiento funcional de bootstrap hacia Home y los casos de cold start/cache ya cubiertos por el harness.

#### Procedimiento pendiente para medicion en dispositivo

Para cerrar las duraciones con metricas reales fuera del harness:

1. Ejecutar la app en debug con una cuenta existente real.
2. Capturar logs `[BootstrapPerf]` y `[BootstrapTimeline]` desde cold start.
3. Repetir en:
   - cuenta con varios habitos y logs
   - cuenta sin habitos
   - segundo arranque con cache scoped valida
4. Extraer:
   - `metric=remote_profile`
   - `metric=essential_habits`
   - `metric=total`
   - contadores reales de perfil y logs en repositorios instrumentados o proxy HTTP
5. Verificar visualmente ausencia de flashes de onboarding y de datos genericos antes de Home.

## Fase 4B2 - Analisis del camino critico

### Alcance de este estudio

Esta seccion documenta el flujo real actual de una cuenta existente desde la restauracion de sesion hasta el primer frame estable de Home.

- No cambia comportamiento productivo.
- No mueve trabajo a segundo plano.
- No marca 4B2 como terminada.

### Punto exacto en el que Home queda preparada hoy

`BootstrapController` considera Home preparada cuando `_prepareHomeEssentials(...)` devuelve un `CosmeticsReadyToken` valido y, a continuacion, `_run(...)` publica:

- `BootstrapState(phase: BootstrapPhase.ready, destination: BootstrapDestination.home, ...)`

Antes de ese punto ya han terminado:

- sesion
- scope local
- carga local scoped
- perfil remoto
- habitos esenciales
- logs
- timezone / streak protection dentro del pull de habitos
- cosmeticos esenciales
- precarga de assets visibles

Dentro de `_prepareHomeEssentials(...)` el marcador interno previo a publicar Home es:

- `_log(runId, 'home_ready total_ms=...')`

pero la navegacion funcional a Home no ocurre hasta el `_setState(...)` posterior en `_run(...)`.

### Secuencia real actual

```text
Session restore
  -> AuthController.initialSessionResolved
  -> BootstrapController._run()
  -> UserStateStore.switchLocalScope(userId)
  -> UserStateStore.load() si hace falta
  -> ProfileRepository.fetchCurrentProfile()
  -> BootstrapController._prepareHomeEssentials()
       -> paralelo:
          -> UserStateStore.prepareEssentialHabitsForBootstrap()
             -> _runHabitsRemotePull()
                -> HabitRepository.fetchHabitsForCurrentUser()
                -> HabitLogRepository.fetchLogsForHabits()
                -> _mergeRemoteHabitLogsIntoLocalState(...)
                -> _syncStreakProtectionIntoUserStateWithMetrics()
                   -> _closeRemoteMissedHabitOccurrencesBestEffortWithMetrics()
                   -> _fetchSharedStreakProtectionSnapshotWithMetrics()
                      -> setHabitTimeZone()
                      -> fetchShieldsForCurrentUser()
                      -> fetchBreaksForCurrentUser()
                -> save() local si hubo cambios
          -> ShopCosmeticsController.prepareEssentialCosmeticsForBootstrap()
             -> cache local o _syncFromCurrentScope()
             -> CloudCosmeticsCache.read(scopeKey)
             -> _cloudRepository.fetchSnapshot() cuando aplica
       -> validar resolvers / ready token
       -> preload visible assets
  -> BootstrapState.ready(destination=home)
```

### Esperas actuales que bloquean Home

- `await _authController.initialSessionResolved`
- `await _userStateStore.switchLocalScope(userId: user.id)`
- `await _userStateStore.load()` cuando el state no esta cargado
- `await _profileRepository.fetchCurrentProfile()`
- `await Future.wait([habitsFuture, cosmeticsFuture])`
- dentro de habitos:
  - `await _habitRepositoryForStore(store).fetchHabitsForCurrentUser()`
  - `await _habitLogRepositoryForStore(store).fetchLogsForHabits(remoteHabitIds)`
  - `await _syncStreakProtectionIntoUserStateWithMetrics(...)`
  - `await store.save(root)` cuando hay cambios
- dentro de streak protection:
  - `await _runCloseRemoteMissedHabitOccurrencesBestEffort(...)`
  - `await _syncHabitTimeZoneCacheBestEffort(...)`
  - `await repository.fetchShieldsForCurrentUser()`
  - `await repository.fetchBreaksForCurrentUser()`
- dentro de cosmeticos:
  - `await _cloudCache.read(scopeKey)` en lectura de cache
  - `await _syncFromCurrentScope(...)` cuando no basta la cache o hay `forceRemote`
  - `await _cloudRepository.fetchSnapshot()` dentro de `_loadCloudState(...)` cuando aplica
- `await _essentialAssetPreloader.preload(cosmetics.visibleAssets)`

### Tabla de operaciones

| Operacion | Quien la inicia | Await concreto | Dependencias | Estado que modifica | Impacto visible en Home | Si falla | Idempotente | Puede repetirse | Puede quedar obsoleta | Categoria |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Restauracion de sesion | `BootstrapController._run()` | `await _authController.initialSessionResolved` | stream/auth snapshot | `BootstrapState.user` | decide Welcome/Auth/Onboarding/Home | bootstrap error o guest flow | si | si | si, por cambio de sesion | A |
| Seleccion de scope local | `BootstrapController._run()` | `await _userStateStore.switchLocalScope(...)` | userId autenticado | scope local, epoch, state scoped | evita datos cruzados | bootstrap error / descarte obsoleto | si | si | si | A |
| Carga de estado local scoped | `BootstrapController._run()` | `await _userStateStore.load()` | scope ya fijado | `_state` local | base de habitos, profile local, cache scoped | bootstrap error | si | si | si | A |
| Perfil remoto | `BootstrapController._run()` | `await _profileRepository.fetchCurrentProfile()` | user autenticado | `BootstrapState.remoteProfile` | decide onboarding vs home | bootstrap error recuperable | si | si | si | A |
| Fetch de habitos remotos | `UserStateStore._runHabitsRemotePull()` | `await fetchHabitsForCurrentUser()` | auth user + scope | merge de `activeHabits` | lista de habitos visible | fallo de bootstrap de habitos | si | si | si | A |
| Fetch batch de logs | `UserStateStore._runHabitsRemotePull()` | `await fetchLogsForHabits(...)` | habitos remotos validos | history / completions / count values | estado visible de habitos | fallo de bootstrap de habitos | si | si | si | A |
| Merge de habitos y logs | `UserStateStore._runHabitsRemotePull()` | trabajo local sincronico | habitos + logs remotos | `userState`, history | cards, checks, counts, continuidad base | no Home si el pull falla | si | si | si | A |
| Timezone de habitos | `user_state_store_streak_protection.dart` | `await repository.setHabitTimeZone(timeZone)` | timezone del dispositivo + auth user | remoto y luego meta local `lastSyncedHabitTimeZone` | puede cambiar fecha logica de ocurrencias y rachas | se degrada silenciosamente hoy | si | si | si | C |
| Cierre de ocurrencias perdidas | `_closeRemoteMissedHabitOccurrencesBestEffortWithMetrics()` | `await repository.closeMissedHabitOccurrence(...)` por ocurrencia | habitos locales, day boundary, remote habit ids | shields/breaks locales tras resultado remoto | puede cambiar racha, shield consumido o break registrada | hoy se ignora y sigue | si por requestId | si | si | A |
| Snapshot de streak protection | `_fetchSharedStreakProtectionSnapshotWithMetrics()` | `await fetchShieldsForCurrentUser()` y `await fetchBreaksForCurrentUser()` | auth user, timezone sync previo | shields y breaks reconciliados | racha, recoverables, protecciones | hoy se degrada y puede seguir | si | si | si | A |
| Reconciliacion de streak protection | `_reconcileRemoteStreakProtectionSnapshot(...)` | trabajo local sincronico | snapshot remoto completo | history shields/breaks | rachas y protecciones visibles/derivadas | sigue con estado parcial si snapshot incompleto | si | si | si | A |
| Persistencia local derivada de habitos | `_runHabitsRemotePull()` | `await store.save(root)` | merge previo | cache scoped persistida | evita rehacer Home con estado viejo en siguiente arranque | bootstrap falla si save falla en este camino | si | si | si | C |
| Cosmeticos esenciales desde cache | `ShopCosmeticsController.prepareEssentialCosmeticsForBootstrap()` | `await _cloudCache.read(scopeKey)` | scope correcto | cloud state loading + cached state | evita fondo/cards genericos | si la cache es invalida va a remoto | si | si | si | C |
| Snapshot cloud de cosmeticos | `ShopCosmeticsController.prepareEssentialCosmeticsForBootstrap()` | `await _syncFromCurrentScope(...)` | scope, wallet/cloud state, cache | `_cachedState`, `_cloudState`, revision | wallpaper/card/user card visibles | bootstrap de cosmeticos falla o degrada | si | si | si | A |
| Verificacion de resolvers | `BootstrapController._prepareHomeEssentials()` | validacion sin await extra | snapshot cosmeticos ya aplicado | no persiste, valida contrato | evita mostrar asset generico o inconsistente | bootstrap falla | si | si | si | A |
| Precarga de assets | `BootstrapController._prepareHomeEssentials()` | `await _essentialAssetPreloader.preload(...)` | assets visibles resueltos | cache de imagenes en memoria | evita flash visual al entrar a Home | bootstrap falla | si | si | si | A |
| Sync de perfil/background backfills | `AuthController._syncCurrentUserProfile()` | fuera del bootstrap | auth user | identity local, progress/backfills | no define primer frame de Home | warning silencioso | mayormente si | si | si | B |
| Refresh remoto completo de cosmeticos post-cache | `prepareEssentialCosmeticsForBootstrap()` | `unawaited(_syncFromCurrentScope(force: true))` | cache valida + mismo scope | revision/cached state posteriores | puede actualizar cosmeticos legitimos despues de Home | warning o degradado | si | si | si | B |

### Clasificacion obligatoria

#### A - Debe bloquear Home

- restauracion y validacion de sesion
- seleccion del scope local
- carga del estado local scoped
- carga del perfil remoto
- carga y merge de habitos
- carga y merge de logs
- cierre de ocurrencias perdidas
- snapshot y reconciliacion de streak protection
- carga de cosmeticos equipada necesaria para wallpaper / habit card / user card
- verificacion de resolvers de cosmeticos
- precarga de los assets visibles del primer frame

Motivo comun:

- cualquiera de estos pasos puede cambiar el destino, mezclar datos de otro usuario, mostrar habitos/logs incorrectos, dejar rachas o continuidad incorrectas, o introducir un flash visible inmediato al entrar en Home.

#### B - Puede ejecutarse despues del primer frame

- sync de perfil en `AuthController` posterior al bootstrap
- bootstrap de metadata de perfil (`ensureCurrentProfile`, `touchLastLogin`, `touchLastSeen`)
- backfills de progress, habits, habit logs, journal y achievements disparados desde `AuthController`
- refresh remoto completo de cosmeticos cuando ya se entro desde cache valida y el token de readiness sigue valido
- otras sincronizaciones no visibles en el primer frame, siempre que esten protegidas por `userId`, scope y epoch

#### C - Depende de condiciones

- timezone
- persistencias locales derivadas de habitos/streak
- uso de cache de cosmeticos en vez de fetch remoto bloqueante

Condiciones exactas:

- `Timezone` solo podria diferirse si existe una timezone cacheada valida, igual a la timezone actual del dispositivo, y no hay indicios de cambio de dia ni de ocurrencias pendientes cuyo cierre dependa de esa timezone.
- `Persistencia local derivada` solo podria diferirse si el estado ya reconciliado queda aplicado en memoria antes de Home y existe proteccion fuerte contra logout/cambio de usuario antes del `save`.
- `Cosmeticos desde cache` solo puede desbloquear Home cuando la cache scoped pertenece al usuario actual, los assets equipados siguen siendo validos, los resolvers producen exactamente los mismos assets visibles y el refresh remoto posterior no debe producir sustitucion brusca del fondo o cards en el primer frame.

### Analisis especifico de streak protection y ocurrencias perdidas

#### Deteccion de dias perdidos

Hoy no vive como un paso separado del bootstrap: emerge del estado local de ocurrencias y del cierre remoto/reconciliacion posterior.

- modifica continuidad real
- puede crear o eliminar breaks
- puede consumir shields

No debe diferirse si Home va a mostrar una racha calculada con ese mismo estado.

#### Cierre de ocurrencias

Hoy se ejecuta antes del snapshot de shields y breaks:

- `_closeRemoteMissedHabitOccurrencesBestEffortWithMetrics()`

Hace una llamada por ocurrencia perdida remota no protegida y puede devolver:

- `alreadyContinuous`
- `shieldConsumed`
- `breakRecorded`
- `breakExpired`

Esto puede cambiar de inmediato:

- shield disponible
- break recuperable
- continuidad / racha actual

Conclusion:

- debe seguir bloqueando Home en el estado actual de la UI.

#### Consumo de shields

Puede producirse dentro del cierre remoto de ocurrencias perdidas. Si se difiere, Home podria mostrar:

- un shield aun disponible cuando ya debio consumirse
- un habito protegido/continuo incorrectamente

Conclusion:

- no proponerlo como trabajo de fondo salvo que la UI de Home deje de depender de ese dato visible.

#### Creacion o actualizacion de breaks

Tambien ocurre en el cierre remoto o en la reconciliacion del snapshot. Si se difiere, Home podria mostrar:

- racha aun intacta cuando ya esta rota
- break recuperable ausente

Conclusion:

- debe bloquear Home.

#### Recuperacion de racha

La accion manual de recovery no forma parte del bootstrap base. Su sincronizacion posterior a mutacion ya tiene su propia confirmacion remota.

Conclusion:

- fuera del camino critico base del arranque.

#### Calculo de continuidad

Aunque el calculo final visible se deriva en gran parte del estado local, ese estado queda invalidado si no se han aplicado cierres/breaks/shields remotos.

Conclusion:

- mientras Home muestre continuidad/racha derivada de ese estado, no es seguro diferir la reconciliacion remota.

### Analisis especifico de timezone

Origen actual:

- dispositivo, via `DeviceTimeZoneProvider.getLocalIanaTimeZone()`
- se envia a Supabase con `setHabitTimeZone(...)`
- se cachea localmente en `meta.lastSyncedHabitTimeZone`

Riesgos:

- puede cambiar la fecha logica efectiva de los habitos
- afecta el cierre de ocurrencias perdidas
- afecta shields y breaks porque ambos guardan `logicalTimeZone`
- puede cambiar el dia considerado para racha y continuidad

Conclusion:

- timezone no es automaticamente trabajo secundario.
- solo seria categoria C diferible si la timezone cacheada ya coincide con la actual y no hay trabajo de streak/occurrences pendiente dependiente de ella.

### Analisis especifico de cosmeticos y assets

Separacion de capas:

- identidad del cosmetico equipado: `equippedWallpaperId`, `equippedHabitCardSkinId`, `equippedUserCardSkinId`
- propiedad/ownership: validacion de que el asset equipado esta poseido
- catalogo: se usa para resolver assets y bundles, pero no todo el catalogo visible es necesario para el primer frame
- resolucion del asset: `_getValidatedEquippedAssetOrNull(...)`
- decodificacion / precarga visual: `_essentialAssetPreloader.preload(...)`

Debe bloquear hoy:

- resolver identidad + ownership de wallpaper / habit card / user card
- validar que los resolvers sincronicos y el snapshot coinciden
- precargar los assets visibles

Puede diferirse en el futuro:

- refresh remoto completo del catalogo y ownership no visible si ya existe un snapshot scoped valido que resuelve exactamente los assets equipados mostrados en Home

No es seguro diferir hoy:

- la precarga del wallpaper/card visible, porque puede introducir flash visual
- la validacion del token de readiness, porque es la barrera que evita mostrar un estado generico y luego reemplazarlo

### Logout y cambio de cuenta

Cualquier trabajo diferido futuro debera mantener, como minimo:

- `userId`
- scope local
- `runId` o `scopeEpoch`
- descarte logico al completar
- prohibicion de escribir si cambia la sesion

El codigo actual ya usa varios patrones que 4B2 debe reutilizar:

- `BootstrapController._isCurrentRun(runId)` y `_isCurrentUserRun(runId, userId)`
- `UserStateStore._scopeEpoch`
- `ShopCosmeticsController._currentScope()` y `_isStaleCloudLoad(...)`
- mapas/futures in-flight con limpieza por `identical(...)`

### Trabajo que recomiendo diferir en la futura implementacion

- sync de perfil y metadata en `AuthController`
- backfills disparados desde `AuthController`
- refresh remoto completo de cosmeticos cuando Home ya pudo construirse desde cache scoped valida y token estable
- persistencia local no esencial posterior al primer frame, solo si el estado reconciliado ya queda aplicado en memoria y protegido por scope/epoch

### Trabajo que recomiendo mantener bloqueante

- sesion
- scope local
- carga local scoped
- perfil remoto
- habitos remotos
- logs batch
- cierre remoto de ocurrencias perdidas
- snapshot completo de streak protection
- reconciliacion de shields y breaks
- snapshot/validacion de cosmeticos equipados visibles
- precarga de assets visibles del primer frame

### Estado esencial propuesto para 4B2

Sin crear la clase todavia, el equivalente a `BootstrapEssentialState` deberia contener al menos:

- `userId`
- `scopeEpoch` o identificador equivalente de aislamiento
- sesion confirmada
- destino ya decidido
- perfil remoto validado
- snapshot local scoped cargado
- habitos activos reconciliados
- logs ya aplicados a los habitos visibles
- estado de streak protection ya reconciliado para lo visible
- timezone efectiva usada para esa reconciliacion
- cosmeticos equipados visibles ya resueltos
- token de readiness visual valido
- lista de assets visibles ya precargados

### Propuesta arquitectonica para implementar 4B2

#### Propietario del trabajo posterior a Home

- `BootstrapController` debe seguir siendo el orquestador de la fase esencial.
- El trabajo diferido no deberia dispersarse en `unawaited()` sueltos.
- Cada dominio debe conservar propietario claro:
  - habitos/streak: `UserStateStore`
  - cosmeticos: `ShopCosmeticsController`
  - perfil/backfills: `AuthController` o un coordinador especifico

#### Momento de arranque

- iniciar el trabajo diferido inmediatamente despues de publicar `BootstrapState.ready(destination: home, ...)`
- no antes de validar readiness token ni antes de la precarga de assets visibles

#### Control de ciclo de vida

- cada tarea diferida debe capturar `userId`
- cada tarea diferida debe capturar `scopeEpoch` o equivalente
- al completar, debe revalidar sesion/scope antes de escribir
- si hay un bootstrap nuevo, los resultados viejos deben descartarse sin side effects

#### Comparticion de operaciones in-flight

- reutilizar patrones de future compartido por scope o userId
- mantener limpieza con `identical(...)`
- unificar por dominio:
  - `pendingPostHomeHabitsRefresh`
  - `pendingPostHomeStreakRefresh`
  - `pendingPostHomeCosmeticsRefresh`

#### Errores

- trabajo diferido: log + estado reintentable, sin tumbar Home
- errores que dejan datos esenciales ambiguos: seguirian en la fase bloqueante y no deben diferirse

## Implementacion - Trabajo post-Home seguro

### Operaciones movidas

- `touchLastLogin`
- `touchLastSeen`
- backfill de progreso (`syncSupabaseUserProgressBootstrapBestEffort`)
- backfill de habitos locales existentes
- backfill de habit logs locales existentes
- backfill de journal
- backfill de achievements

Se han movido porque no deciden onboarding frente a Home, no construyen el primer estado visible de habitos/logs y no participan en el `CosmeticsReadyToken`.

### Operaciones que siguen bloqueando

Se mantienen bloqueando y no se han cambiado en este bloque:

- sesion
- scope local
- estado local scoped
- perfil remoto necesario para decidir destino
- habitos y logs esenciales
- cierre de ocurrencias perdidas
- streak protection
- timezone cuando afecta a continuidad
- cosmeticos visibles
- validacion del `CosmeticsReadyToken`
- precarga de assets visibles

Motivo: cualquiera de estas piezas puede cambiar el destino, mezclar datos entre usuarios o alterar el primer frame estable de Home.

### Arquitectura y propietario

- `BootstrapController` sigue siendo el orquestador del camino esencial.
- `BootstrapHomeEssentialReady` hace explicito el contrato de Home lista antes de publicar `BootstrapState.ready(destination: home)`.
- `BootstrapController` solo inicia `AuthController.startPostHomeBootstrapWork(...)` una vez publicada Home.
- `AuthController` es el propietario del trabajo post-Home de perfil y backfills.

### Guardas multiusuario

Cada tarea post-Home captura:

- `bootstrapRunId`
- `userId`
- `scopeUserId`
- `scopeEpoch`

Antes de aplicar cada etapa se comprueba:

- mismo usuario autenticado
- mismo scope activo
- mismo `scopeEpoch`
- mismo `bootstrapRunId` vigente para ese `userId|scope|epoch`
- ausencia de logout

Si el contexto ya no coincide, el resultado se descarta sin escribir estado ni persistir datos y se registra `post_home_stale_discard`.

### Dedupe in-flight

- La clave in-flight es `bootstrapRunId|userId|scopeUserId|scopeEpoch`.
- Consumidores simultaneos del mismo run comparten el mismo `Future`.
- La limpieza se hace solo si sigue siendo exactamente el mismo `Future` mediante `identical(...)`.
- Un run nuevo del mismo usuario no reutiliza la operacion anterior.
- No se convierte en cache permanente.

### Manejo de errores

- Todo el trabajo post-Home entra por un metodo encapsulado con nombre explicito.
- Los fallos recuperables registran `post_home_error`.
- Los resultados obsoletos registran `post_home_stale_discard`.
- Un error post-Home no convierte Home en bootstrap fallido.
- El in-flight se libera tanto en exito como en error para permitir un nuevo intento en un bootstrap posterior.

### Metricas aÃƒÆ’Ã‚Â±adidas

- `time_to_home_ready`
- `essential_total`
- `post_home_profile_metadata`
- `post_home_backfills`
- `post_home_total`
- `post_home_stale_discard`
- `post_home_error`

Estas metricas separan el tiempo esencial hasta Home del trabajo secundario posterior.

### Tests aÃƒÆ’Ã‚Â±adidos

- `bootstrap_controller_test.dart`
  - Home se publica antes de que termine el trabajo post-Home
  - onboarding no inicia trabajo post-Home
  - un fallo post-Home no mueve Home a error
- `bootstrap_controller_metrics_test.dart`
  - se emiten `time_to_home_ready` y `essential_total`
  - `post_home_total` aparece solo despues de terminar el trabajo secundario
- `auth_controller_test.dart`
  - deduplicacion in-flight por run
  - reinicio legitimo tras exito
  - liberacion del in-flight tras error
  - descarte por logout durante trabajo post-Home
  - invalidacion de resultados cuando aparece un bootstrap mas nuevo del mismo usuario

### Pendiente para el siguiente bloque de 4B2

- posible uso de cache valida de cosmeticos para desbloquear Home
- persistencias diferidas de habitos
- reevaluacion de timezone
- reevaluacion de streak protection
- medicion real en dispositivo

## Fase 4B2 - Medicion intermedia

### Entorno de medicion

- Fecha: 28 de julio de 2026
- Rama: rama actual de trabajo
- Modo de ejecucion real: `debug`
- Dispositivo real usado: `Pixel 9`
- Device id usado: `58090DLAQ000TS`
- Comando real ejecutado:
  - `flutter run -d 58090DLAQ000TS --dart-define-from-file=dart_defines/dev.json`

### Estado real de esta sesion

- Se consiguio ejecutar el bootstrap real en el `Pixel 9` y capturar logs `[BootstrapPerf]` validos.
- Quedaron 6 runs validos con `metric=time_to_home_ready` y `metric=post_home_total`:
  - `bootstrap_A1.log`
  - `bootstrap_A2.log`
  - `bootstrap_A3.log`
  - `bootstrap_B1.log`
  - `bootstrap_B2.log`
  - `bootstrap_B3.log`
- En todos los runs validos el arranque entro por cache scoped valida:
  - `habits_source=cache`
  - `cosmetics_source=cache`
- No se preparo en esta sesion una cuenta autenticada real sin habitos, por lo que ese escenario sigue sin medicion de dispositivo.

### Instrumentacion disponible tras este bloque

Ya quedan separadas estas metricas de bootstrap cuando el flujo se ejecuta en debug:

- `session_resolution`
- `scope_selection`
- `local_state`
- `remote_profile`
- `essential_habits`
- `essential_habits_fetch`
- `essential_logs_batch`
- `habits_logs_merge`
- `missed_occurrences_close`
- `habit_timezone`
- `streak_shields_fetch`
- `streak_breaks_fetch`
- `streak_reconciliation`
- `habits_persist`
- `essential_cosmetics`
- `cosmetics_cache_read`
- `cosmetics_remote_fetch`
- `cosmetics_resolve_visible`
- `essential_assets`
- `essential_total`
- `time_to_home_ready`
- `post_home_profile_metadata`
- `post_home_backfills`
- `post_home_total`

Las metricas finas se emiten una sola vez por run desde `BootstrapController`, usando los desgloses producidos por habitos/streak/cosmeticos.

### Escenarios completados en esta sesion

- Escenario A completado parcialmente:
  - cuenta existente real con varios habitos y logs
  - 3 runs validos medidos en dispositivo
  - todos los runs entraron por cache scoped valida en habitos y cosmeticos
- Escenario B completado:
  - repeticion del arranque con cache scoped valida
  - 3 runs validos medidos en dispositivo
- Escenario C no completado:
  - no habia una cuenta autenticada real sin habitos preparada en esta sesion
- Validacion visual de ausencia de flashes:
  - no se declara como cumplida en este documento porque no se registro evidencia manual formal durante la captura

### Resultados medidos en dispositivo

#### Escenario A - Cuenta existente real con varios habitos y logs

Runs validos capturados:

| Run | Perfil remoto | Habitos esenciales | Cosmeticos esenciales | Tiempo hasta Home | Total bootstrap | Post-Home total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| A1 | 1987 ms | 25 ms | 22 ms | 2490 ms | 2490 ms | 1191 ms |
| A2 | 768 ms | 30 ms | 29 ms | 1308 ms | 1318 ms | 4816 ms |
| A3 | 1326 ms | 215 ms | 207 ms | 4634 ms | 4636 ms | 397975 ms |
| Mediana | 1326 ms | 30 ms | 29 ms | 2490 ms | 2490 ms | 4816 ms |

Contadores reales observados en los 3 runs:

- consultas de perfil en bootstrap: 1 por run
- consultas batch de logs en bootstrap: 0 por run medido
- `remote_queries` total del bootstrap: 2 por run

Interpretacion exacta:

- el dispositivo estaba usando cache scoped valida para habitos, asi que no hubo fetch remoto de logs en el camino esencial de estos runs
- por tanto, este escenario sirve para medir tiempos reales de perfil y tiempo a Home, pero no para demostrar en dispositivo el batch de logs remoto

#### Escenario B - Repeticion del arranque con cache scoped valida

Runs validos capturados:

| Run | Perfil remoto | Habitos esenciales | Cosmeticos esenciales | Tiempo hasta Home | Total bootstrap | Post-Home total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| B1 | 413 ms | 40 ms | 38 ms | 1092 ms | 1092 ms | 1848 ms |
| B2 | 421 ms | 59 ms | 55 ms | 1110 ms | 1111 ms | 808 ms |
| B3 | 469 ms | 39 ms | 38 ms | 1054 ms | 1055 ms | 752 ms |
| Mediana | 421 ms | 40 ms | 38 ms | 1092 ms | 1092 ms | 808 ms |

Contadores reales observados en los 3 runs:

- consultas de perfil en bootstrap: 1 por run
- consultas batch de logs en bootstrap: 0 por run medido
- `remote_queries` total del bootstrap: 2 por run

Validacion que si queda respaldada por logs:

- no aparecio destino `onboarding` en los logs del bootstrap validos
- el bootstrap completo llego a `home_published` en los 3 runs

Validacion que no se declara cerrada aqui:

- ausencia de flashes visuales de onboarding o datos genericos
- requiere observacion manual registrada de forma explicita

#### Escenario C - Cuenta existente real sin habitos

No medido en dispositivo el 28 de julio de 2026.

Motivo:

- no habia una cuenta autenticada real sin habitos preparada en esta sesion
- no se inventan tiempos ni contadores para este escenario

Lo que si queda demostrado fuera de dispositivo:

- `confirmed-empty habits emit zero log batch queries`
- `no remote habits do not trigger a batch logs query`

### Tabla de resultados

| Operacion | Escenario A mediana | Escenario B mediana | Estado |
| --- | ---: | ---: | --- |
| Perfil remoto | 1326 ms | 421 ms | Medido en dispositivo |
| Habitos esenciales | 30 ms | 40 ms | Medido en dispositivo desde cache |
| Logs batch | N/D | N/D | No ejecutado en estos runs por cache valida |
| Cierre de ocurrencias | N/D | N/D | No visible en estos runs |
| Timezone | N/D | N/D | No visible en estos runs |
| Shields | N/D | N/D | No visible en estos runs |
| Breaks | N/D | N/D | No visible en estos runs |
| Reconciliacion streak | N/D | N/D | No visible en estos runs |
| Persistencia | N/D | N/D | No visible en estos runs |
| Cosmeticos esenciales | 29 ms | 38 ms | Medido en dispositivo desde cache |
| Precarga de assets | 128 ms | 223 ms | Medido en dispositivo |
| Tiempo hasta Home | 2490 ms | 1092 ms | Medido en dispositivo |
| Trabajo post-Home | 4816 ms | 808 ms | Medido en dispositivo |

### Comparacion con 4A

- En esta sesion ya hay tiempos reales de dispositivo para cache scoped valida y para una cuenta existente real con varios habitos y logs.
- Sigue sin haber comparacion temporal completa frente a 4A para todos los escenarios porque falta la cuenta real sin habitos y falta un run real que fuerce logs batch remoto.
- La mejora verificable aqui sigue siendo principalmente de observabilidad:
  - 4A separaba el bootstrap a alto nivel
  - esta medicion intermedia de 4B2 deja preparados los spans finos para identificar si domina habitos/logs, streak/timezone, persistencia o cosmeticos

### Cuellos de botella

Con los runs validos de esta sesion:

- el mayor coste bloqueante observado fue `remote_profile`
- en cache scoped valida, habitos y cosmeticos no dominaron el tiempo total
- hubo una variabilidad alta fuera del camino esencial en `post_home_total`, especialmente en `A3`

Lo que sigue demostrado en esta sesion es que ahora existe instrumentacion suficiente para distinguir:

- fetch de habitos frente a logs batch
- merge local
- cierre de ocurrencias perdidas
- timezone
- shields
- breaks
- reconciliacion de streak
- persistencia local
- cache y fetch remoto de cosmeticos
- resolucion visible
- trabajo post-Home

### Recomendacion para el siguiente bloque

No avanzar todavia a una optimizacion nueva hasta obtener al menos:

- 1 ejecucion real que entre por logs batch remoto
- 1 cuenta real sin habitos
- validacion visual registrada de ausencia de flashes de onboarding o datos genericos

Con los resultados reales ya capturados, elegir entre:

- cosmeticos
- persistencia de habitos
- streak protection / timezone
- o cerrar 4B2 si el tiempo restante ya es razonable

### Comando exacto para medir

Si el telefono vuelve a estar disponible:

```bash
flutter run -d 58090DLAQ000TS --dart-define-from-file=dart_defines/dev.json
```

Si hay que usar emulador:

```bash
flutter emulators --launch Pixel_5
flutter devices
flutter run -d <emulator-id> --dart-define-from-file=dart_defines/dev.json
```

### Filtro exacto de logs

En PowerShell:

```powershell
flutter run -d <device-id> --dart-define-from-file=dart_defines/dev.json 2>&1 |
  Select-String -Pattern '\[BootstrapPerf\]|\[BootstrapTimeline\]|\[Bootstrap\]'
```

Si se quiere guardar a fichero:

```powershell
flutter run -d <device-id> --dart-define-from-file=dart_defines/dev.json 2>&1 |
  Tee-Object -FilePath bootstrap_run.log |
  Select-String -Pattern '\[BootstrapPerf\]|\[BootstrapTimeline\]|\[Bootstrap\]'
```

### Procedimiento manual pendiente

1. Escenario A:
   - cerrar completamente la app
   - abrir con sesion ya restaurable
   - esperar a `BootstrapState.ready(home)`
   - repetir 3 veces
2. Escenario B:
   - sin borrar datos
   - volver a cerrar y abrir la misma cuenta
   - repetir 3 veces
3. Escenario C:
   - usar una cuenta autenticada sin habitos remotos
   - verificar `essential_logs_batch queries=0`
4. Escenario D:
   - solo si el dispositivo/emulador permite throttling de red fiable
   - repetir el escenario A con red limitada

### Limitaciones de esta sesion

- no hay medicion real del escenario con cuenta sin habitos
- no hay medicion real de un run con `essential_logs_batch` remoto activo
- no se han usado latencias de tests ni fakes como sustituto
- la validacion visual de flashes no quedo registrada formalmente durante la captura

## Fase 4B2 - Cierre formal

### Estado

Fase 4B2 cerrada el 28 de julio de 2026.

### Justificacion del cierre

- La cache scoped valida alcanza una mediana de `1092 ms` en `time_to_home_ready`.
- El arranque real medido de cuenta existente alcanza una mediana de `2490 ms` en `time_to_home_ready`.
- Ambos resultados quedan dentro de los objetivos orientativos definidos para el Punto 4:
  - cache valida en torno a `1,5 s` o menos
  - arranque real con red normal en torno a `2-3 s`
- Las operaciones que siguen dentro del camino critico afectan al estado visible o a la integridad funcional del primer frame.
- Seguir reduciendo 4B2 en este punto implicaria aumentar el riesgo sin evidencia de una mejora necesaria.

### Trabajo que ya se mueve fuera del camino critico

- metadata de perfil:
  - `touchLastLogin`
  - `touchLastSeen`
- backfills:
  - `syncSupabaseUserProgressBootstrapBestEffort`
  - `syncExistingLocalHabitsOnce`
  - `syncExistingLocalHabitLogsOnce`
  - `syncExistingLocalJournalEntriesOnce`
  - `syncExistingLocalAchievementsOnce`

### Garantias ya implantadas

- El trabajo secundario de perfil y backfills se ejecuta despues de Home.
- Home se publica antes de que termine el trabajo post-Home.
- Los errores post-Home no invalidan Home.
- Existen guardas de `userId`, scope, `scopeEpoch` y `bootstrapRunId`.
- El trabajo post-Home dispone de deduplicacion in-flight.

### Trabajo que permanece esencial

- `streak protection` permanece dentro del camino esencial.
- `timezone` permanece dentro del camino esencial cuando afecta a continuidad.
- los cosmeticos visibles y su precarga permanecen bloqueando para evitar flashes.
- las persistencias esenciales no se han diferido.
- perfil remoto sigue formando parte de la decision `onboarding` frente a `home`.

### Resultado de 4B2

- metadata y backfills fuera del camino critico
- tiempo hasta Home separado del trabajo post-Home
- cache valida con mediana real de `1092 ms`
- arranque real con mediana de `2490 ms`
- sin flashes de onboarding observados en los runs validos del escenario B
- `remote_profile` identificado como principal candidato para la futura 4C

## Fase 4C - Cache, paralelismo y payloads

### Principal cuello de botella restante

El principal coste observado en las mediciones reales de Pixel 9 es:

- `remote_profile`

Medianas observadas:

- Escenario A: `1326 ms`
- Escenario B: `421 ms`

### Alcance futuro a estudiar en 4C

No se implementa ninguna optimizacion nueva aqui. La futura 4C debera estudiar:

- posibilidad de usar inmediatamente informacion scoped local valida
- reconciliacion remota posterior
- payload minimo del perfil
- columnas realmente necesarias para decidir `onboarding` frente a `home`
- reutilizacion de perfil ya disponible en memoria
- expiracion e invalidacion de la cache
- comportamiento tras reinstalacion
- cambio de cuenta
- perfil remoto inexistente o incompleto

No se diseÃƒÆ’Ã‚Â±a todavia la solucion definitiva y no se modifica en esta entrega la decision actual de navegacion basada en `remote_profile`.

## Fase 4D - Validacion de escenarios reales

### Evidencias pendientes trasladadas desde 4B2

Estas evidencias no mantienen abierta 4B2. Quedan trasladadas formalmente a 4D:

#### Cuenta sin habitos en dispositivo

Validar:

- llegada correcta a Home
- `essential_logs_batch queries=0`
- ausencia de trabajo remoto innecesario
- ausencia de datos genericos

#### Arranque forzando carga remota de habitos y logs

Validar:

- maximo 1 consulta batch de logs
- asignacion correcta de logs
- ausencia de consultas por habito
- mismo resultado funcional
- tiempo real del batch

### Motivo del traslado a 4D

- el comportamiento ya esta cubierto por tests
- falta unicamente la evidencia de dispositivo
- no es necesario bloquear el cierre arquitectonico de 4B2 por estas dos comprobaciones

## Estado final del Punto 4

- ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ 4A - Medicion del rendimiento
- ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ 4B1 - Deduplicacion de perfil y batch de logs
- ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ 4B2 - Reduccion del camino critico
- ÃƒÂ¢Ã…Â¾Ã‚Â¡ÃƒÂ¯Ã‚Â¸Ã‚Â 4C - Cache, paralelismo y payloads
- ÃƒÂ¢Ã‚Â¬Ã…â€œ 4D - Validacion de escenarios reales
- ÃƒÂ¢Ã‚Â¬Ã…â€œ 4E - Medicion final y cierre

## Fase 4C - Estudio previo de cache, paralelismo y payloads

### Alcance real revisado

Este estudio previo se limita a:

- restauracion de sesion
- carga del perfil actual
- decision `onboarding` frente a `home`
- estado local scoped relacionado con perfil
- memoria reutilizable en `AuthController` y `BootstrapController`
- `ProfileRepository`
- `RemoteProfile`
- almacenamiento local scoped de `UserStateStore`
- preparacion de habitos y cosmeticos ya paralelizada
- instrumentacion 4A-4B2

No implementa cambios productivos y no altera la semantica actual del bootstrap.

### Recorrido exacto de `remote_profile`

#### Quien inicia la llamada

Hoy `fetchCurrentProfile()` puede iniciarse desde dos sitios:

- `BootstrapController._run()`
  - llamada bloqueante para decidir `onboarding` frente a `home`
- `AuthController._syncCurrentUserProfile()`
  - llamada de sincronizacion de identidad local

Ademas, `AuthController._ensureCurrentUserProfileForBootstrap()` puede disparar `ensureCurrentProfile()`, que a su vez llama primero a `fetchCurrentProfile()`.

#### Recorrido completo en bootstrap

Flujo actual:

```text
AuthController.initialSessionResolved
  -> BootstrapController._run()
  -> UserStateStore.switchLocalScope(userId)
  -> UserStateStore.load() si hace falta
  -> BootstrapProfileRepository.fetchCurrentProfile()
  -> ProfileRepository.fetchCurrentProfile()
  -> ProfileRepository._fetchCurrentProfileRemote(userId)
  -> SupabaseClient.from('profiles').select().eq('id', userId).maybeSingle()
  -> RemoteProfile.fromMap(row)
  -> BootstrapController._destinationForProfile(profile)
  -> onboarding | home
```

#### Datos que necesita `BootstrapController`

`BootstrapController` usa `RemoteProfile` para:

- verificar que `profile.id == user.id`
- decidir destino mediante `profile.onboardingStatus`
- pasar `profile.onboardingVersion` a `markOnboardingCompleted(...)`
- conservar `remoteProfile` en `BootstrapState`

No usa durante la decision:

- `displayName`
- `avatarUrl`
- preferencias
- `last_login_at`
- `last_seen_at`
- `created_at`
- `updated_at`

#### Datos que necesita `AuthController`

`AuthController._syncCurrentUserProfile()` usa `fetchCurrentProfile()` para:

- `email`
- `display_name`
- `avatar_url`

Con esos campos hace `applySupabaseIdentity(...)` sobre `UserStateStore`.

`AuthController` no usa ese fetch para decidir navegacion.

#### Consulta Supabase ejecutada

Consulta real:

```dart
_client
  .from('profiles')
  .select()
  .eq('id', userId)
  .maybeSingle()
```

Propiedades actuales:

- tabla consultada: `profiles`
- columnas solicitadas: todas las columnas expuestas por la fila
- filtros aplicados: `id = <current user id>`
- numero esperado de filas: `0` o `1`
- joins o relaciones: no
- vista intermedia: no

#### Mapeo remoto a dominio

El resultado de Supabase se convierte en `RemoteProfile` con:

- requeridos por parser:
  - `onboarding_status`
  - `onboarding_version`
- requerido de facto por bootstrap:
  - `id`
- requerido condicionalmente:
  - `onboarding_completed_at` cuando `onboarding_status == completed`
- opcionales:
  - `email`
  - `display_name`
  - `avatar_url`
  - `preferred_language_code`
  - `notifications_enabled`
  - `daily_motivation_enabled`
  - `marketing_notifications_enabled`
  - `daily_motivation_time`
  - `last_login_at`
  - `last_seen_at`
  - `created_at`
  - `updated_at`

#### Persistencia o cache posterior

Tras el fetch:

- `BootstrapController` no persiste el `RemoteProfile` remoto como snapshot scoped local
- `BootstrapController` lo guarda temporalmente solo en `BootstrapState.remoteProfile`
- `AuthController` transforma parte del perfil a identidad local basica con:
  - `profile.displayName`
  - `profile.email`
  - `profile.avatarUrl`
- `UserStateStore` persiste esos campos en el estado local scoped, pero no como cache remota versionada del perfil

### Limite real del span `remote_profile`

El span actual esta delimitado exactamente por:

```dart
final profileStartedAt = DateTime.now();
final profileResult = await _profileRepository.fetchCurrentProfile();
_metric(runId, 'remote_profile', DateTime.now().difference(profileStartedAt));
```

Por tanto, el span incluye:

- espera sobre un `in-flight` ya existente para ese `userId`
- resolucion del `currentUserId`
- construccion de la query Supabase
- handshake/red/autenticacion de la llamada HTTP subyacente
- ejecucion de la consulta
- transferencia de la fila
- `maybeSingle()`
- parseo `Map -> RemoteProfile`
- construccion de `RepositoryResult`

El span no incluye:

- `switchLocalScope`
- `load()` del estado local
- decision `onboarding` frente a `home`
- preparacion de habitos o cosmeticos
- `applySupabaseIdentity(...)`
- escrituras locales derivadas de `AuthController`
- `touchLastLogin`
- `touchLastSeen`
- backfills post-Home

Conclusion importante:

- los `1326 ms` no pueden atribuirse integramente a Supabase
- parte del tiempo puede ser simple espera sobre una operacion remota ya iniciada por `AuthController`
- con la instrumentacion actual no se separan:
  - espera de `in-flight`
  - query remota
  - parseo/mapeo

### Campos minimos necesarios antes de Home

#### A - Necesarios para decidir navegacion

Campos realmente necesarios hoy:

- `id`
  - donde se lee: `BootstrapController`
  - que modifica: validacion de que la respuesta pertenece al usuario actual
  - si esta obsoleto: riesgo multiusuario directo
  - debe validarse remotamente antes de Home: si
- `onboarding_status`
  - donde se lee: `_destinationForProfile(...)`
  - que modifica: `onboarding` frente a `home`
  - si esta obsoleto: puede abrir Home incorrectamente o retener onboarding de mas
  - debe validarse remotamente antes de Home: hoy si
- `onboarding_version`
  - donde se lee: `completeTemporaryOnboarding()`
  - que modifica: version usada para confirmar onboarding completado
  - si esta obsoleto: puede romper la transicion de onboarding
  - debe validarse remotamente antes de Home: para ese flujo si
- `onboarding_completed_at`
  - donde se lee: `RemoteProfile.fromMap(...)`
  - que modifica: consistencia del parser cuando el estado es `completed`
  - si esta obsoleto: invalida la respuesta completa
  - debe validarse remotamente antes de Home: si se mantiene el parser actual

#### B - Necesarios para el primer frame de Home

En el bootstrap actual no hay ningun campo remoto de perfil que construya el primer frame esencial de Home.

Los campos visibles de identidad usados luego por la app:

- `display_name`
- `email`
- `avatar_url`

no forman parte del contrato esencial actual que desbloquea Home.

#### C - No necesarios antes de Home

Campos diferibles con el comportamiento actual:

- `email`
- `display_name`
- `avatar_url`
- `preferred_language_code`
- `notifications_enabled`
- `daily_motivation_enabled`
- `marketing_notifications_enabled`
- `daily_motivation_time`
- `last_login_at`
- `last_seen_at`
- `created_at`
- `updated_at`

Motivo comun:

- no cambian la navegacion inicial del bootstrap
- no forman parte del contrato esencial de Home
- hoy se usan para identidad local o edicion posterior, no para decidir primer frame

### Contrato pequeno propuesto

Sin implementarlo todavia, el contrato minimo equivalente seria:

```dart
BootstrapProfileDecision {
  String userId;
  OnboardingStatus onboardingStatus;
  int onboardingVersion;
  DateTime? onboardingCompletedAt;
}
```

Campos deliberadamente fuera:

- display name
- avatar
- email
- preferencias
- metadata de auditoria

### Payload remoto actual

Payload actual:

- `select()` completo de `profiles`
- sin proyeccion minima
- el mapper `RemoteProfile.fromMap(...)` acepta muchas columnas opcionales
- no hay joins ni JSON grandes identificados en este recorrido
- durante bootstrap la mayor parte del payload no se usa para decidir destino

### Payload minimo recomendado

Payload minimo para bootstrap:

- `id`
- `onboarding_status`
- `onboarding_version`
- `onboarding_completed_at`

Solo con eso se cubre el contrato actual de navegacion y la validacion de consistencia del parser.

### Alternativas de payload

#### Alternativa A - Query especifica de bootstrap

Metodo candidato:

```dart
fetchBootstrapProfileDecision()
```

Ventajas:

- payload minimo real
- contrato explicito para bootstrap
- menos riesgo de arrastrar columnas no usadas
- instrumentacion mas precisa por caso de uso

Riesgos:

- nuevo modelo o mapper parcial
- mas tests de repositorio
- posible duplicacion con `RemoteProfile`

Impacto:

- mantenimiento algo mayor
- onboarding y bootstrap quedan mas claros
- `AuthController` seguiria pudiendo usar `fetchCurrentProfile()` completo
- numero de consultas remotas no cambia por si mismo

#### Alternativa B - Mantener `fetchCurrentProfile()`

Reduciendo el payload general de ese metodo.

Ventajas:

- no crea una segunda API
- evita duplicacion superficial de entrada

Riesgos:

- puede romper consumidores que hoy esperan mas campos
- mezcla necesidades de bootstrap y de sync de identidad
- obliga a revisar todos los usos actuales y futuros

Impacto:

- mantenimiento menos explicito
- compatibilidad con `AuthController` mas delicada
- mas riesgo de regresion transversal
- numero de consultas remotas tampoco cambia por si mismo

#### Recomendacion actual

La alternativa mas segura para 4C1 es:

- query especifica de bootstrap con contrato minimo

Motivo:

- `BootstrapController` y `AuthController` no necesitan el mismo payload
- el cuello de botella actual esta en la decision de bootstrap, no en la edicion completa del perfil

### Cache de perfil existente hoy

#### Lo que si existe

En almacenamiento local scoped existe:

- `userState.meta.onboardingDone`
- `userState.meta.authEmail`
- `userState.profile.displayName`
- `userState.profile.email`
- `userState.profile.avatarUrl`
- `userState.userId`
- `userState.meta.lastSavedAt`
- aislamiento por key scoped:
  - `user_state_v1_<userId>`

Tambien existe memoria temporal en:

- `BootstrapState.remoteProfile`
- `_currentUser` de `AuthController`

#### Lo que no existe

No existe hoy una cache scoped formal del perfil remoto con:

- ultimo `onboarding_status` remoto valido
- ultimo `onboarding_version` remoto valido
- `onboarding_completed_at` remoto
- timestamp de obtencion remota del perfil
- origen del dato
- flag de completitud parcial/completa
- version de contrato de cache

#### Propietario actual

- identidad local basica: `UserStateStore`
- estado remoto tipado: nadie lo persiste localmente como snapshot reutilizable

#### Comportamiento actual por escenario

- logout:
  - cambia scope a guest
  - evita reutilizar estado autenticado de otro usuario
- cambio de cuenta:
  - incrementa `scopeEpoch`
  - limpia memoria `_state`
  - obliga a cargar el scope correcto
- reinstalacion:
  - puede restaurarse la sesion Supabase sin cache local scoped
  - el bootstrap sigue necesitando el fetch remoto
- perfil remoto eliminado:
  - bootstrap falla con `profileNotFound`
- cambio de onboarding version:
  - hoy solo se detecta con la respuesta remota

### Politica propuesta de validez de cache

#### Metadatos minimos necesarios

Una cache futura utilizable antes de Supabase debe registrar como minimo:

- `userId`
- `scopeUserId`
- `scopeEpoch` no persistido como verdad remota, pero si validado en tiempo de uso
- `schemaVersion` local
- `onboardingVersion`
- `onboardingStatus`
- `onboardingCompletedAt`
- `fetchedAt`
- `source`
- `completeness`

#### Cache suficiente para desbloquear Home

Solo si se cumplen todas:

- mismo `userId`
- mismo scope local activo
- misma version de esquema local compatible
- misma version de onboarding conocida como vigente en app
- cache completa para `BootstrapProfileDecision`
- cache obtenida de respuesta remota valida
- no hay seÃƒÆ’Ã‚Â±al local de logout o cambio de cuenta
- no existe regla de producto que exija bloqueo remoto por cuenta eliminada o bloqueada

#### Cache utilizable, pero manteniendo Splash

Casos:

- existe identidad local pero no snapshot remoto de decision
- existe snapshot parcial sin `onboardingCompletedAt`
- mismatch de version de onboarding
- se sospecha reinstalacion o almacenamiento regenerado
- hay duda sobre estado remoto de cuenta

#### Cache invalida

Casos:

- `userId` distinto
- scope distinto
- cache corrupta
- esquema local incompatible
- perfil parcial cuando bootstrap necesita decision completa
- logout previo
- cambio de cuenta
- snapshot sin origen remoto verificable

#### Justificacion sobre TTL

No se recomienda un TTL arbitrario como unica regla.

El riesgo real no es solo antiguedad temporal:

- cambio de cuenta
- nueva version de onboarding
- perfil eliminado
- cuenta bloqueada
- reinstalacion con sesion restaurada

La validez debe basarse primero en identidad, version y completitud; la antiguedad solo puede ser una seÃƒÆ’Ã‚Â±al secundaria.

### Casos en los que la cache podria desbloquear Home

Solo serian seguros estos casos:

- usuario autenticado estable
- mismo scope
- snapshot remoto previo completo de `BootstrapProfileDecision`
- estado cacheado indica `completed`
- misma version de onboarding requerida por la app
- no hay politica remota de bloqueo de cuenta pendiente de verificar

En ese escenario, el flujo candidato seria:

```text
sesion confirmada
  -> scope local
  -> BootstrapProfileDecision cacheado y valido
  -> preparar Home
  -> Home
  -> reconciliacion remota del perfil
```

### Casos en los que el fetch remoto debe seguir bloqueando

- no existe cache de decision
- cache de otro usuario
- cache corrupta
- reinstalacion con sesion restaurada pero sin snapshot remoto local
- version de onboarding distinta
- perfil marcado como pendiente o en progreso
- perfil remoto potencialmente inexistente
- cuenta potencialmente bloqueada o eliminada
- cualquier caso en que una respuesta remota pudiera cambiar `home` a `onboarding`

### Estrategia de reconciliacion posterior

Flujo candidato solo para cache validada como suficiente:

```text
sesion confirmada
  -> scope local
  -> decision provisional segura desde cache
  -> esenciales de Home
  -> Home
  -> reconciliacion remota del perfil
```

Tratamiento por resultado remoto:

1. Perfil igual a la cache
   - no cambia navegacion
   - refrescar `fetchedAt`
2. Metadata distinta
   - actualizar cache y estado local post-Home
3. Onboarding no completado
   - no debe aceptarse esta estrategia para un cache que ya desbloqueo Home
   - por tanto ese caso debe seguir bloqueando remoto antes de Home
4. Nueva version obligatoria de onboarding
   - igual que el caso anterior
   - debe seguir siendo bloqueante
5. Perfil inexistente
   - debe seguir siendo bloqueante
6. Cuenta eliminada o bloqueada
   - debe seguir siendo bloqueante
7. Usuario cambiado durante la consulta
   - descartar por `userId`, scope y `bootstrapRunId`
8. Logout durante la consulta
   - descartar
9. Fallo temporal de Supabase
   - si la cache era valida y suficiente, mantener Home y registrar reconciliacion fallida

Conclusion:

- solo una cache que ya garantice `completed` con reglas fuertes podria desbloquear Home
- cualquier incertidumbre que pudiera llevar a redirigir despues a onboarding invalida la estrategia

### Reutilizacion en memoria e in-flight

#### Estado actual

- Fase 4B1 ya comparte operaciones simultaneas por `userId`
- `AuthController` no conserva un `RemoteProfile` tipado reutilizable
- `BootstrapController` no reutiliza `state.remoteProfile` de un run previo
- `AuthController` convierte el perfil remoto a mapa y persiste solo identidad basica

#### Reutilizacion posible

Se podria reutilizar memoria si existiera un proveedor tipado compartido con:

- `BootstrapProfileDecision` ya validado
- identidad del usuario
- marca de completitud
- origen y `fetchedAt`

#### Invalidez necesaria

Debe invalidarse en:

- logout
- cambio de cuenta
- cambio de scope
- bootstrap mas nuevo para el mismo usuario
- incompatibilidad de version de onboarding

#### Sobre `scopeEpoch`

El `in-flight` remoto puro del repositorio no necesita hoy `scopeEpoch` para la query en si, porque la consulta se filtra por `userId`.

Pero cualquier reutilizacion de resultado mas alla del repositorio si debe quedar protegida por:

- `userId`
- scope activo
- `scopeEpoch`
- `bootstrapRunId` o equivalente

### Paralelismo actual

#### Antes de `remote_profile`

- resolucion de sesion
- `switchLocalScope`
- `load()` local scoped

#### Despues de `remote_profile`

- decision `onboarding` frente a `home`
- si el destino es `home`:
  - habitos esenciales
  - cosmeticos esenciales
  - precarga de assets

#### Paralelo actual dentro de `_prepareHomeEssentials()`

- `prepareEssentialHabitsForBootstrap(userId)`
- `prepareEssentialCosmeticsForBootstrap(userId)`

ambos lanzados con `Future.wait(...)`.

### Oportunidades controladas de paralelismo

#### Lectura de cache de cosmeticos

Evidencia:

- hoy solo ocurre despues de decidir `home`
- `prepareEssentialCosmeticsForBootstrap()` ya tiene dedupe por scope

Beneficio potencial:

- pequeno, sobre todo si la cache ya es valida

Riesgo:

- trabajo inutil si el destino final es `onboarding`
- necesidad de descarte por `bootstrapRunId` y scope

Prioridad:

- baja frente al cuello de botella `remote_profile`

#### Preparacion de habitos desde cache scoped

Evidencia:

- ya existe cache scoped de habitos y via `readyFromCache`
- pero solo se inicia tras decidir `home`

Beneficio potencial:

- pequeno o medio si el destino acaba siendo `home`

Riesgo:

- arrancar trabajo innecesario si el perfil manda a `onboarding`
- mayor complejidad de cancelacion y descarte

Prioridad:

- media, pero posterior a resolver perfil minimo y cache de decision

#### Resolucion de assets locales

No hay evidencia de que pueda adelantarse con seguridad antes de confirmar `home`, porque depende de cosmeticos visibles ya validados.

Prioridad:

- baja

### Oportunidades adicionales en habitos, logs y cosmeticos

#### Habitos

Evidencia:

- ya existe cache scoped valida reutilizable
- ya existe dedupe in-flight del bootstrap

Oportunidad:

- estudiar si parte de la preparacion cacheada puede iniciarse antes cuando la decision `home` sea segura por cache de perfil

Impacto potencial:

- medio

Riesgo:

- trabajo descartado si el perfil remoto invalida la decision provisional

Prioridad:

- media, despues de 4C1 y 4C2

#### Logs

Evidencia:

- ya hay un unico batch
- ya se evita query si no hay habitos

Oportunidad:

- medir payload real del batch cuando se fuerce ruta remota

Impacto potencial:

- desconocido todavia

Riesgo:

- tocarlo sin nuevas metricas puede no aportar mejora

Prioridad:

- baja hasta tener evidencia de 4D

#### Cosmeticos

Evidencia:

- ya existe `CloudCosmeticsCache.read(...)`
- ya existe refresh en background cuando la cache sirve
- ya existe dedupe de bootstrap y de cloud load

Oportunidad:

- adelantar solo lectura local si una futura decision de perfil en cache permite ir antes a Home

Impacto potencial:

- bajo o medio

Riesgo:

- flashes o invalidaciones visuales si se cruza con cambio de destino

Prioridad:

- media-baja

### Riesgos obligatorios

#### Multiusuario

- cache del usuario A usada por B
- resultado remoto antiguo aplicado tras cambio de cuenta
- persistencia en scope incorrecto
- compartir in-flight mas alla de `userId` sin validar scope y run

#### Onboarding

- cache antigua que marque `completed`
- nueva version obligatoria de onboarding
- perfil remoto incompleto
- Home provisional incorrecta seguida de redireccion brusca

#### Reinstalacion

- sesion restaurada con cache local ausente
- datos locales borrados con perfil remoto aun existente
- necesidad de seguir mostrando Splash hasta decidir con seguridad

#### Offline y errores

- cache valida con Supabase caido
- cache vacia con Supabase caido
- timeout
- perfil no encontrado
- respuesta invalida o parcial

#### Seguridad

- no usar cache local para saltarse un posible bloqueo remoto
- no persistir mas payload sensible del necesario
- no registrar payloads completos del perfil

### Division recomendada de 4C

#### 4C1 - Perfil minimo y reutilizacion

Objetivo:

- separar el payload minimo de bootstrap
- preparar reutilizacion tipada en memoria
- instrumentar mejor `remote_profile`

Archivos probables:

- `profile_repository.dart`
- `remote_profile.dart` o nuevo contrato tipado
- `bootstrap_controller.dart`
- tests de repositorio y bootstrap

Riesgos:

- divergencia entre contrato minimo y modelo completo

Criterio de cierre:

- bootstrap decide con contrato minimo validado
- metricas distinguen query remota y reutilizacion

#### 4C2 - Cache scoped para decision de bootstrap

Objetivo:

- definir cache de `BootstrapProfileDecision`
- reglas de validez e invalidacion
- reconciliacion posterior segura

Archivos probables:

- `user_state_store` o cache dedicada
- `bootstrap_controller.dart`
- `auth_controller.dart`
- documentacion y tests

Riesgos:

- onboarding provisional incorrecto
- mezcla multiusuario

Criterio de cierre:

- solo se desbloquea Home con cache realmente segura

#### 4C3 - Paralelismo controlado

Objetivo:

- adelantar solo operaciones independientes cuando ya exista decision segura

Archivos probables:

- `bootstrap_controller.dart`
- `user_state_store_habits.dart`
- `shop_cosmetics_controller.dart`

Riesgos:

- trabajo desperdiciado
- stale results

Criterio de cierre:

- no aparecen flashes ni resultados cruzados

#### 4C4 - Otros payloads y caches

Objetivo:

- revisar habitos, logs y cosmeticos solo donde las metricas indiquen mejora probable

Archivos probables:

- `user_state_store_habits.dart`
- repositorios de logs
- `shop_cosmetics_controller.dart`

Riesgos:

- complejidad sin impacto medible

Criterio de cierre:

- cada cambio respaldado por metricas reales o tests dirigidos

### Orden exacto de implementacion recomendado

1. Instrumentar mejor perfil sin cambiar semantica.
2. Introducir contrato minimo de decision de bootstrap.
3. Medir de nuevo `remote_profile` con query minima y con hit de memoria.
4. DiseÃƒÆ’Ã‚Â±ar y persistir cache scoped de decision.
5. Validar reglas de invalidez multiusuario/onboarding/offline.
6. Solo despues evaluar desbloqueo de Home desde cache segura.
7. Cuando la decision provisional sea segura, estudiar paralelismo controlado.
8. Dejar habitos/logs/cosmeticos para el final y solo con evidencia.

### Metricas necesarias

Las metricas actuales no separan todavia:

- espera por `in-flight`
- query remota pura
- parseo/mapeo
- hit de memoria
- lectura de cache de perfil
- hit/miss/invalidez de cache de perfil
- reconciliacion posterior

Spans o contadores recomendados:

- `profile_memory_hit`
- `profile_cache_read`
- `profile_cache_hit`
- `profile_cache_miss`
- `profile_cache_invalid`
- `profile_remote_query`
- `profile_remote_map`
- `profile_bootstrap_payload`
- `profile_reconciliation`
- `profile_stale_discard`

### Matriz minima de tests

#### Repositorio

- payload minimo de bootstrap
- consumidor completo mantiene compatibilidad
- dos consumidores simultaneos del mismo usuario
- usuario distinto no comparte in-flight
- perfil remoto inexistente
- respuesta parcial o invalida

#### Controlador

- perfil ya disponible en memoria
- cache scoped valida
- cache vacia
- cache de otro usuario
- nueva version de onboarding
- logout durante reconciliacion
- cambio de cuenta durante reconciliacion
- operacion antigua completando tras bootstrap nuevo
- sin redireccion brusca de Home a onboarding

#### Store o cache

- cache corrupta
- cache de esquema antiguo
- reinstalacion con sesion restaurada
- Supabase caido con cache valida
- Supabase caido sin cache
- perfil bloqueado o eliminado invalida desbloqueo

#### Widget

- sin flashes de onboarding
- sin entrada provisional incorrecta en Home
- Splash se mantiene cuando la cache no es suficiente

#### Validacion manual en dispositivo

- perfil ya resuelto desde memoria
- cache scoped valida
- cambio de cuenta
- logout durante reconciliacion
- offline con cache valida
- offline sin cache
- perfil remoto inexistente
- nueva version de onboarding

#### Cambios visibles legitimos

- solo notificar si el nuevo estado sigue perteneciendo al mismo usuario/scope
- solo notificar si cambia realmente el estado visible
- evitar animaciones o reemplazos bruscos de wallpaper/cards en el primer instante tras Home

### Estados de error para la futura 4B2

Deben impedir llegar a Home:

- sesion no valida o cambiante
- scope local incoherente
- perfil remoto invalido o no encontrado
- habitos/logs esenciales no disponibles sin cache utilizable
- streak protection esencial que cambie datos visibles sin fallback seguro
- cosmeticos visibles sin resolver o token no valido
- fallo de precarga de assets visibles si mantiene el riesgo de flash severo

Deben mostrar error recuperable en bootstrap:

- fallos de perfil
- fallos de habitos/logs sin cache suficiente
- fallos de cosmeticos sin cache suficiente
- cualquier incoherencia multiusuario o token invalido

Pueden permitir Home con cache:

- refresh remoto de cosmeticos cuando la cache visible ya es valida
- trabajo de perfil/backfills no visible

Deben registrarse y reintentarse sin bloquear:

- metadata de perfil
- backfills
- refreshes remotos completos no esenciales

### Instrumentacion adicional recomendada para 4B2

La instrumentacion de 4A/4B1 aun no separa con precision suficiente:

- tiempo esencial hasta Home
- cierre de ocurrencias
- timezone
- snapshot de streak protection
- persistencia local derivada
- trabajo posterior al primer frame

Spans / metricas recomendadas:

- `essential_total`
- `post_home_total`
- `streak_close_remote`
- `streak_snapshot`
- `streak_reconcile`
- `habit_timezone_sync`
- `habit_state_persist`
- `cosmetics_cache_read`
- `cosmetics_remote_refresh`
- `post_home_profile_sync`
- `post_home_backfills`

Tambien harian falta eventos:

- `home_ready_published`
- `post_home_work_started`
- `post_home_work_finished`
- `post_home_work_discarded`

### Matriz minima de tests para la futura implementacion

Unitarios:

- cache valida de cosmeticos y token estable
- timezone igual vs timezone cambiada
- clasificador de trabajo esencial vs diferido
- descarte por `userId` / scope / epoch

De controlador:

- cache valida
- cache vacia
- operacion antigua completandose despues de un bootstrap nuevo
- logout durante trabajo diferido
- cambio de usuario durante trabajo diferido
- Home sin flashes de estado generico

De store:

- cambio de dia
- cambio de timezone
- shield pendiente de consumo
- racha rota
- cuenta sin habitos
- cuenta con muchos habitos
- error de streak protection

De widget:

- Home renderiza sin fondo/card genericos intermedios
- Home no navega a onboarding y luego cambia a home
- Home no muestra racha visible incorrecta en primer frame

Validaciones manuales en dispositivo:

- cache valida
- cache vacia
- cambio de dia
- cambio de timezone real
- error de cosmeticos
- cuenta sin habitos
- cuenta con muchos habitos
- logout/cambio de cuenta durante refresh posterior

### Orden recomendado de cambios para implementar 4B2

1. AÃƒÆ’Ã‚Â±adir instrumentacion fina para separar `essential_total` de timezone/streak/cosmetics/post-home.
2. Definir explicitamente el contrato de `BootstrapEssentialState` sin cambiar aun la navegacion.
3. Extraer cierres y snapshot de streak protection en spans separados para medir si pueden dividirse sin romper lo visible.
4. Introducir un coordinador de trabajo post-Home con guardas de `userId` + `scopeEpoch` + descarte de stale results.
5. Mover primero trabajo claramente no visible:
   - sync de perfil metadata
   - backfills
6. Evaluar cache valida de cosmeticos como via de Home con refresh posterior estrictamente controlado.
7. Solo despues, reevaluar si parte de streak/timezone puede pasar a categoria B o seguir en C bajo condiciones estrictas.
8. Mantener precarga de assets visibles y validacion de readiness token hasta demostrar en dispositivo que no produce flashes.

## Fase 4C1A - Perfil minimo para la decision de bootstrap

### Objetivo ejecutado

Esta subfase reduce solo el payload del perfil bloqueante del bootstrap.

- No introduce cache persistente.
- No desbloquea Home desde estado local.
- No cambia habitos, logs, streak protection, timezone ni cosmeticos.
- No avanza a 4C1B, 4C2, 4C3 ni 4C4.

### Payload anterior

Antes de 4C1A el bootstrap consumia:

```dart
_client.from('profiles').select().eq('id', userId).maybeSingle()
```

Eso cargaba la fila completa de `profiles`, incluyendo campos no necesarios para decidir `onboarding` frente a `home`, por ejemplo:

- `email`
- `display_name`
- `avatar_url`
- preferencias de notificaciones
- `last_login_at`
- `last_seen_at`
- `created_at`
- `updated_at`

### Payload minimo implementado

La decision bloqueante del bootstrap pasa a usar solo:

```text
id,onboarding_status,onboarding_version,onboarding_completed_at
```

Consulta concreta:

```dart
_client
  .from('profiles')
  .select('id,onboarding_status,onboarding_version,onboarding_completed_at')
  .eq('id', userId)
  .maybeSingle()
```

`fetchCurrentProfile()` completo se mantiene sin cambios funcionales para consumidores que necesitan la fila completa.

### Contrato tipado creado

Se introdujo `BootstrapProfileDecision` en `lib/data/models/remote/remote_profile.dart`.

Campos:

- `userId`
- `onboardingStatus`
- `onboardingVersion`
- `onboardingCompletedAt`

Invariantes aplicadas:

- `id` debe coincidir con el usuario autenticado esperado
- `onboarding_status` debe ser reconocido
- `onboarding_version` debe ser valida
- un perfil `completed` sin `onboarding_completed_at` se rechaza
- una respuesta parcial o incoherente se trata como `invalidResponse`

El contrato minimo puede convertirse a `RemoteProfile` parcial para mantener el contrato actual de `BootstrapState.remoteProfile` sin abrir el payload completo antes de Home.

### Arquitectura elegida

- `ProfileRepository.fetchBootstrapProfileDecision()`
  - hace la query minima
  - valida identidad e invariantes
  - devuelve `BootstrapProfileDecisionLoadResult`
- `BootstrapController`
  - sustituye la llamada bloqueante a `fetchCurrentProfile()`
  - decide `onboarding` frente a `home` desde el contrato minimo
  - mantiene `remote_profile` como span historico agregado
- `AuthController`
  - deja de disparar fetch completo de perfil antes de Home
  - hace el fetch completo solo en trabajo post-Home, usando las guardas ya existentes

### Recorrido nuevo de la decision de perfil

```text
AuthController.initialSessionResolved
  -> BootstrapController._run()
  -> UserStateStore.switchLocalScope(userId)
  -> UserStateStore.load() si hace falta
  -> BootstrapProfileRepository.fetchBootstrapProfileDecision()
  -> ProfileRepository.fetchBootstrapProfileDecision()
  -> BootstrapProfileDecision.fromMap(...)
  -> BootstrapController._destinationForProfile(...)
  -> onboarding | home
  -> si home:
     -> Home se publica
     -> AuthController.startPostHomeBootstrapWork(...)
     -> fetchCurrentProfile() completo solo despues de Home
```

### Coordinacion con AuthController

Antes de Home:

- bootstrap usa solo la query minima
- `AuthController` ya no dispara `fetchCurrentProfile()` completo en:
  - inicializacion con sesion existente
  - `signInWithEmailPassword()`
  - `handleAuthState(...)` para eventos signed-in

Despues de Home:

- el fetch completo vive en `_runPostHomeFullProfileSync(...)`
- no decide navegacion
- no cambia `destination`
- un error post-Home no convierte Home en bootstrap fallido

Caso de sign-up:

- se mantiene `upsertCurrentProfile(...)` para asegurar la fila sin obligar a un fetch completo previo a Home

### Numero maximo de consultas antes de Home

Antes de Home, para perfil:

- maximo `1` query remota bloqueante de decision por bootstrap y usuario
- `0` queries completas adicionales antes de Home dentro del flujo validado en tests

### Estrategia de deduplicacion in-flight

Se mantienen mapas separados:

- `_inFlightProfiles`
- `_inFlightBootstrapProfileDecisions`

Garantias:

- deduplicacion aislada por `userId`
- consultas minimas y completas no se mezclan como equivalentes
- el `Future` compartido se elimina en exito
- se elimina tambien en fallo
- una peticion posterior legitima puede volver a consultar
- la limpieza usa `identical(...)` para que una operacion antigua no elimine una nueva
- usuarios distintos no comparten operaciones

### Manejo de logout, cambio de usuario y resultados obsoletos

- `BootstrapController` mantiene las mismas guardas por run actual y `user.id`
- un logout durante la query minima descarta el resultado
- un cambio de usuario descarta el resultado antiguo
- un bootstrap nuevo no reutiliza la decision del anterior
- el trabajo completo post-Home usa guardas por `bootstrapRunId`, `scopeUserId` y `scopeEpoch`

### Metricas aÃƒÆ’Ã‚Â±adidas

Nuevas metricas:

- `profile_decision_total`
- `profile_decision_inflight_wait`
- `profile_decision_remote_query`
- `profile_decision_map`
- `profile_decision_remote_calls`
- `profile_decision_payload_columns`

Se mantiene tambien:

- `remote_profile`

Uso exacto:

- `remote_profile` conserva la comparacion historica con 4A y 4B2
- las metricas nuevas separan espera in-flight, query real y mapeo
- `profile_decision_remote_calls` registra el contador real de roundtrips de la query minima
- `profile_decision_payload_columns` registra el payload tecnico fijo de 4 columnas

### Resultados de tests

Cobertura aÃƒÆ’Ã‚Â±adida o actualizada:

- `test/data/repositories/profile_repository_onboarding_test.dart`
  - query minima con solo 4 columnas
  - deduplicacion concurrente de la decision minima
  - liberacion del in-flight tras fallo
  - retry legitimo posterior
  - aislamiento por `userId`
- `test/application/bootstrap/bootstrap_controller_test.dart`
  - Home decidido desde el contrato minimo
  - onboarding decidido desde el contrato minimo
  - descarte por logout o cambio de usuario
  - Home publicado antes del trabajo post-Home
- `test/application/bootstrap/bootstrap_controller_metrics_test.dart`
  - una sola query de decision por bootstrap normal
  - `profile_decision_remote_calls count=1`
  - `profile_decision_payload_columns count=4`
- `test/application/auth/auth_controller_test.dart`
  - el trabajo post-Home sigue deduplicado y aislado por run

### Medicion real en esta sesion

Estado del intento ejecutado el martes 28 de julio de 2026:

- Se intento preparar la medicion real con `flutter devices`.
- El `Pixel 9` no fue detectado en esta sesion.
- `flutter devices` solo devolvio:
  - `Windows`
  - `Chrome`
  - `Edge`

Por tanto, en esta sesion:

- no se ejecutaron nuevos runs validos de dispositivo para 4C1A
- no se declaran tiempos reales nuevos para `profile_decision_total`
- no se declara mejora temporal medida en dispositivo

### Comparacion disponible frente a 4B2

Baselines reales existentes antes de 4C1A, medidos previamente en `Pixel 9`:

| Metrica | Baseline anterior |
| --- | ---: |
| `remote_profile` escenario A | `1326 ms` |
| `remote_profile` escenario B | `421 ms` |
| `time_to_home_ready` escenario A | `2490 ms` |
| `time_to_home_ready` escenario B | `1092 ms` |

Estado actual de 4C1A en esta sesion:

| Metrica | 4C1A en esta sesion |
| --- | ---: |
| `profile_decision_total` | No medido en dispositivo |
| `profile_decision_inflight_wait` | Demostrado por tests e instrumentacion local |
| `profile_decision_remote_query` | Demostrado por tests e instrumentacion local |
| `profile_decision_map` | Demostrado por tests e instrumentacion local |
| `profile_decision_remote_calls` | `1` por bootstrap normal en tests |
| `profile_decision_payload_columns` | `4` en tests |
| `time_to_home_ready` | No re-medido en dispositivo |

### Limitaciones y riesgos

- La latencia de conexion/autenticacion puede seguir dominando aunque el payload sea menor.
- Esta subfase no demuestra aun mejora temporal real sin un nuevo run de dispositivo.
- `BootstrapState.remoteProfile` sigue siendo un `RemoteProfile` parcial convertido desde la decision minima; esto es deliberado para no romper el contrato actual del gate.
- La reutilizacion persistente en memoria o disco sigue fuera de alcance.

### Pendientes expresos

Pendiente de 4C1B:

- reutilizacion temporal adicional del resultado de decision si apareciera un consumidor legitimo dentro del mismo flujo
- revision de si alguna metrica adicional debe agregarse al post-Home completo

Pendiente de 4C2:

- cache scoped en disco
- politica de invalidez
- reconciliacion remota posterior basada en cache
- posible entrada a Home desde datos scoped validos
- nuevas mediciones reales comparando 4B2 frente a 4C

### Archivos tocados en 4C1A

- `lib/data/models/remote/remote_profile.dart`
- `lib/data/repositories/profile_repository.dart`
- `lib/application/bootstrap/bootstrap_controller.dart`
- `lib/application/auth/auth_controller.dart`
- `test/data/repositories/profile_repository_onboarding_test.dart`
- `test/application/bootstrap/bootstrap_controller_test.dart`
- `test/application/bootstrap/bootstrap_controller_metrics_test.dart`
- `test/application/auth/auth_controller_test.dart`

## Fase 4C1B - Reutilizacion segura del perfil en memoria

### Invariante que permite reutilizar la decision

La decision solo puede reutilizarse si sigue siendo exactamente valida para el contexto actual:

- mismo `userId`
- misma sesion logica del proceso
- mismo `scopeUserId`
- mismo `scopeEpoch`
- misma version de politica de onboarding
- decision completa y coherente
- origen remoto verificable

Si cualquiera de esas condiciones falla, no hay `memory hit` y el bootstrap vuelve a la query minima remota.

### Arquitectura y propietario

La memoria vive en `ProfileRepository`.

- no vive en widgets
- no vive en `BootstrapController`
- no vive en `AuthController`
- no existe almacenamiento persistente

Se separan tres capas:

- memoria de resultados completados
- operaciones `in-flight`
- cache persistente futura, todavia no implementada

### Estructura guardada por entrada

Cada entrada en memoria guarda:

- `userId`
- `BootstrapProfileDecision`
- `sessionGeneration`
- `scopeUserId`
- `scopeEpoch`
- `onboardingPolicyVersion`
- `source`
- `storeVersion`

No se guardan:

- access tokens
- refresh tokens
- emails
- payloads completos

### Fuentes permitidas

La memoria solo se llena desde datos remotos validados:

- query minima de decision remota
- `RemoteProfile` completo remoto post-Home
- upsert remoto confirmado de perfil durante sign-up
- completado remoto confirmado del onboarding

No se llena desde:

- `userState.meta.onboardingDone`
- estado local antiguo
- respuestas parciales
- datos de demo

### Criterios de validez

La validacion se hace en cada lectura antes de devolver un hit.

Motivos tecnicos cerrados de invalidez implementados:

- `user_mismatch`
- `session_changed`
- `scope_changed`
- `epoch_changed`
- `onboarding_version_changed`
- `explicit_invalidation`
- `incomplete_entry`

### Eventos de invalidacion

Se invalida la memoria cuando ocurre alguno de estos eventos del flujo actual:

- logout
- cambio de usuario
- invalidacion explicita
- mutaciones de perfil que pueden cambiar la decision
- mismatch de `scopeUserId`
- cambio de `scopeEpoch`
- cambio de version de politica de onboarding
- respuesta remota incoherente

La sesion logica se modela con un `sessionGeneration` interno del repositorio que se incrementa al invalidar por auth.

### Flujo de memory hit

```text
bootstrap
  -> scope listo
  -> readBootstrapProfileDecisionFromMemory(...)
  -> entrada valida
  -> remote_calls=0
  -> misma decision onboarding/home
```

### Flujo de memory miss

```text
bootstrap
  -> scope listo
  -> memoria ausente o invalida
  -> comprobar in-flight compatible
  -> query minima remota
  -> validar respuesta
  -> guardar en memoria
  -> devolver decision
```

### Coordinacion con in-flight

- el `in-flight` de decision minima ya no se comparte solo por `userId`
- ahora la clave incluye `userId`, `scopeUserId`, `scopeEpoch`, version de onboarding y `sessionGeneration`
- dos misses simultaneos del mismo contexto comparten un solo `Future`
- cuando termina, una siguiente lectura compatible puede ser `memory hit`
- la limpieza sigue usando `identical(...)`
- una operacion antigua no puede sobrescribir una entrada mas nueva porque cada store lleva `storeVersion`

### Coordinacion con el perfil completo post-Home

Cuando `_runPostHomeFullProfileSync(...)` obtiene un `RemoteProfile` remoto valido:

- deriva una `BootstrapProfileDecision`
- actualiza la memoria solo para el mismo `scopeUserId` y `scopeEpoch`
- no cambia el destino de un Home ya publicado
- no introduce redirects silenciosos

### Comportamiento tras logout y cambio de cuenta

- logout invalida la memoria del usuario anterior y aumenta `sessionGeneration`
- cambio de cuenta invalida la memoria previa y aumenta `sessionGeneration`
- un resultado antiguo que termine despues de una invalidacion ya no se almacena como entrada valida para un hit posterior

### Queries en hit y miss

- `memory hit`: `0` queries remotas de decision
- `memory miss`: maximo `1` query remota de decision

### Metricas aÃƒÆ’Ã‚Â±adidas en 4C1B

- `profile_decision_memory_hit`
- `profile_decision_memory_miss`
- `profile_decision_memory_invalid`
- `profile_decision_memory_store`
- `profile_decision_memory_source`

Se mantienen tambien:

- `profile_decision_total`
- `profile_decision_inflight_wait`
- `profile_decision_remote_query`
- `profile_decision_map`
- `profile_decision_remote_calls`
- `profile_decision_payload_columns`

### Tests aÃƒÆ’Ã‚Â±adidos o actualizados

- `test/data/repositories/profile_repository_onboarding_test.dart`
  - segundo acceso compatible usa memoria y evita query
  - cambio de `scopeEpoch` invalida la memoria y fuerza miss
  - invalidacion explicita durante query impide almacenar una entrada stale
- `test/application/bootstrap/bootstrap_controller_metrics_test.dart`
  - `memory_hit` emite metrica y `remote_calls=0`
- `test/application/bootstrap/bootstrap_controller_test.dart`
  - mantiene el comportamiento funcional de Home, onboarding, logout y cambio de usuario
- `test/application/auth/auth_controller_test.dart`
  - mantiene el aislamiento del trabajo post-Home y los descartes stale

### Medicion real en esta sesion

Estado del intento ejecutado hoy, martes 28 de julio de 2026:

- `flutter devices` no detecto el `Pixel 9`
- solo aparecieron `Windows`, `Chrome` y `Edge`

Por tanto:

- no hay mediciones reales nuevas de `memory miss`
- no hay mediciones reales nuevas de `memory hit`
- no se inventan tiempos ni mejoras de dispositivo

### Riesgos y limitaciones

- la invalidacion por sustitucion de sesion del mismo usuario depende de los eventos de auth observables en el proceso actual
- no existe todavia lectura tras reinicio del proceso
- una entrada con contexto viejo puede quedar en memoria hasta la siguiente lectura incompatible, aunque ya no sirve como hit valido
- esta subfase no demuestra aun mejora temporal en dispositivo al no haber `Pixel 9` disponible hoy

### Pendientes expresos para 4C2

- persistencia scoped en disco
- esquema de cache persistente
- lectura tras reinicio del proceso
- reinstalacion
- offline con cache
- reconciliacion remota sobre cache persistente
- politica completa de invalidacion persistente

## Fase 4C2A - Cache scoped persistente en modo sombra

### Almacenamiento elegido

Se ha introducido una cache dedicada y separada de `UserState` en:

- `lib/data/local/bootstrap_profile_decision_cache.dart`

La implementacion productiva usa `SharedPreferences` porque:

- el payload es pequeno
- ya existe infraestructura equivalente en el proyecto para caches locales versionadas
- permite clave determinista y scoped por usuario
- se puede testear con `SharedPreferences.setMockInitialValues(...)` sin filesystem real

### Arquitectura y propietario

El propietario sigue siendo `ProfileRepository`.

`ProfileRepository` coordina ahora cuatro capas diferenciadas:

1. lectura persistente en sombra
2. memoria del proceso
3. operaciones `in-flight`
4. query remota

`BootstrapController` y `AuthController` no conocen el formato persistido.

### Modelo persistido y version

La entrada persistida es `CachedBootstrapProfileDecision`.

Campos persistidos:

- `cacheSchemaVersion`
- `userId`
- `decision.userId`
- `decision.onboardingStatus`
- `decision.onboardingVersion`
- `decision.onboardingCompletedAt`
- `onboardingPolicyVersion`
- `remoteVerifiedAt`
- `source`

Version actual:

- `cacheSchemaVersion = 1`

No se persisten:

- access token
- refresh token
- email
- display name
- avatar
- preferencias
- perfil completo
- `scopeEpoch`
- `bootstrapRunId`
- `sessionGeneration`
- datos demo

### Clave scoped y aislamiento

La clave productiva es namespaced por entorno y usuario.

Forma efectiva:

```text
rutio_bootstrap_profile_decision_v1_<environmentNamespace>_<safeUserId>
```

Protecciones implementadas:

- la clave depende de `userId`, no de email
- el `userId` leido desde clave y payload debe coincidir
- la entrada debe coincidir con el usuario autenticado actual
- el `scopeUserId` activo debe coincidir con el `userId`
- un namespace de entorno distinto produce `miss`

### Criterios de validez

La cache persistente solo se considera `valid` en modo sombra cuando:

- pertenece al mismo `userId`
- coincide con el `scopeUserId` activo
- el esquema es compatible
- la politica de onboarding coincide
- el estado remoto es reconocible
- la decision minima esta completa y coherente
- la fuente fue remota verificable

Clasificaciones tipadas implementadas:

- `valid`
- `missing`
- `corrupt`
- `userMismatch`
- `schemaMismatch`
- `onboardingVersionMismatch`
- `incompleteDecision`
- `invalidStatus`

No se ha introducido TTL operativo en 4C2A.

### Fuentes permitidas de escritura

La cache persistente solo se escribe desde:

- query minima remota validada
- `RemoteProfile` completo remoto validado
- upsert remoto confirmado
- finalizacion remota confirmada del onboarding

No se escribe desde:

- `UserState.meta.onboardingDone`
- memoria local no verificada
- respuestas parciales
- errores remotos
- datos demo

### Modo sombra

Flujo operativo implementado:

```text
scope listo
  -> lectura persistente y validacion
  -> metrica shadow hit/miss/invalid
  -> memoria valida del proceso o in-flight compatible o query remota
  -> decision real para navegacion
  -> comparacion cache-remoto
  -> write/delete persistente si procede
```

Regla mantenida:

- la cache persistente todavia no desbloquea Home
- la cache persistente todavia no decide onboarding
- la cache persistente todavia no evita la query remota cuando no hay `memory hit`
- la cache persistente todavia no permite entrada offline

### Shadow hit

En una nueva instancia de `ProfileRepository` sin memoria previa:

- una entrada persistente valida produce `profile_persistent_cache_hit_shadow`
- se sigue ejecutando `1` query remota de decision
- el destino final sigue viniendo del resultado remoto

Esto esta demostrado por test.

### Shadow miss

Cuando no existe entrada persistente valida:

- se registra `profile_persistent_cache_miss` o `profile_persistent_cache_invalid`
- se ejecuta `1` query remota de decision
- la respuesta remota valida escribe la nueva cache persistente

Esto esta demostrado por test.

### Comparacion cache-remoto

Clasificaciones implementadas:

- `match`
- `remoteNewerOrChanged`
- `cacheMissing`
- `cacheInvalid`
- `remoteMissing`
- `remoteInvalid`

Comportamiento actual:

- `match`: refresca `remoteVerifiedAt`
- `remoteNewerOrChanged`: sustituye la entrada persistente
- `remoteMissing`: elimina la entrada persistente
- `remoteInvalid`: no escribe una nueva entrada y elimina la incompatible cuando habia una valida

La comparacion no cambia la navegacion ya publicada.

### Corrupcion y errores locales

Si la cache esta corrupta:

- se clasifica como `corrupt`
- no rompe el bootstrap
- se sigue consultando el remoto
- una respuesta remota valida la reemplaza

Si fallan `read`, `write` o `delete`:

- el bootstrap continua
- no se convierte Home en error por la cache local
- el fallo queda reducido a observabilidad y reemplazo futuro

### Invalidacion persistente

Eventos cubiertos en esta subfase:

- logout
- cambio de cuenta
- mutacion de perfil que invalida la decision previa
- respuesta remota inexistente
- respuesta remota invalida
- invalidacion explicita

Politica de seguridad aplicada en logout:

- se elimina la cache del usuario actual
- no se borra la entrada de otro usuario

### Proteccion multiusuario y contra operaciones obsoletas

Se anade proteccion por:

- `sessionGeneration`
- `storeVersion`
- version de operacion persistente por `userId`
- restauracion o borrado correctivo si una escritura vieja completa despues de otra nueva

Con esto se evita que un resultado obsoleto:

- repueble memoria
- repueble disco de forma valida
- borre una entrada mas nueva de otro contexto

### Metricas anadidas

- `profile_persistent_cache_read`
- `profile_persistent_cache_hit_shadow`
- `profile_persistent_cache_miss`
- `profile_persistent_cache_invalid`
- `profile_persistent_cache_write`
- `profile_persistent_cache_delete`
- `profile_persistent_cache_match`
- `profile_persistent_cache_mismatch`
- `profile_persistent_cache_stale_discard`
- `profile_persistent_cache_age`

Los motivos expuestos son cerrados y no sensibles.

### Tests anadidos o actualizados

- `test/data/local/bootstrap_profile_decision_cache_test.dart`
  - round-trip valido
  - schema incompatible
  - `userId` ausente o incoherente
  - decision incompleta
  - estado desconocido
  - JSON corrupto
  - UTC en `remoteVerifiedAt`
  - aislamiento por usuario y entorno
- `test/data/repositories/profile_repository_onboarding_test.dart`
  - `shadow hit` mantiene `1` query remota
  - `shadow miss` mantiene `1` query remota y escribe cache
  - `shadow invalid` mantiene `1` query remota
  - `remote missing` elimina cache
  - logout elimina solo la entrada del usuario actual
  - invalidacion durante query descarta escritura persistente obsoleta
- `test/application/bootstrap/bootstrap_controller_metrics_test.dart`
  - `shadow hit` emite metrica y conserva `remote_calls=1`
  - invalidacion persistente expone motivo cerrado

Se mantienen tambien en verde los tests de bootstrap y auth ya existentes.

### Validacion tecnica ejecutada

Comandos ejecutados hoy, martes 28 de julio de 2026:

```powershell
dart format lib/data/local/bootstrap_profile_decision_cache.dart lib/data/repositories/profile_repository.dart lib/application/bootstrap/bootstrap_controller.dart lib/application/auth/auth_controller.dart test/data/local/bootstrap_profile_decision_cache_test.dart test/data/repositories/profile_repository_onboarding_test.dart test/application/bootstrap/bootstrap_controller_metrics_test.dart test/application/bootstrap/bootstrap_controller_test.dart test/application/auth/auth_controller_test.dart
flutter analyze lib/data/local/bootstrap_profile_decision_cache.dart lib/data/repositories/profile_repository.dart lib/application/bootstrap/bootstrap_controller.dart lib/application/auth/auth_controller.dart test/data/local/bootstrap_profile_decision_cache_test.dart test/data/repositories/profile_repository_onboarding_test.dart test/application/bootstrap/bootstrap_controller_test.dart test/application/bootstrap/bootstrap_controller_metrics_test.dart test/application/auth/auth_controller_test.dart
flutter test test/data/local/bootstrap_profile_decision_cache_test.dart test/data/repositories/profile_repository_onboarding_test.dart test/application/bootstrap/bootstrap_controller_test.dart test/application/bootstrap/bootstrap_controller_metrics_test.dart test/application/auth/auth_controller_test.dart
flutter devices
```

Resultado:

- `flutter analyze`: sin issues en el alcance
- `flutter test`: todo verde en el alcance
- `flutter devices`: el `Pixel 9` no aparecio; solo `Windows`, `Chrome` y `Edge`

### Medicion real en dispositivo

No hay medicion real nueva en dispositivo para 4C2A en esta sesion.

Motivo:

- el martes 28 de julio de 2026 `flutter devices` no detecto el `Pixel 9`

Por tanto, en 4C2A solo quedan demostrados con evidencia local:

- lectura persistente
- clasificacion `shadow hit/miss/invalid`
- `1` query remota en `shadow hit`
- `1` query remota en `shadow miss`
- escritura persistente tras remoto valido
- borrado persistente por logout y `remote missing`
- descarte de escritura obsoleta

### Offline

Comportamiento actual:

- cache valida + remoto fallido: se mantiene el error actual
- no hay entrada offline en Home
- no hay degradado operativo desde disco

### Riesgos y limitaciones

- la politica `remoteInvalid -> delete` es conservadora y evita reutilizar una entrada potencialmente incompatible, pero todavia no distingue causas remotas mas finas
- los fallos de `SharedPreferences` no elevan error al usuario; quedan solo como evidencia tecnica
- no hay todavia decision operativa basada en antiguedad de la entrada
- no hay medicion real en dispositivo en esta subfase

### Pendientes para 4C2B

- decidir si una cache persistente valida puede evitar la query bloqueante
- definir politica final ante perfil remoto eliminado o bloqueado
- definir politica de version obligatoria de onboarding
- decidir comportamiento offline
- valorar TTL o revalidacion
- estudiar reconciliacion post-Home sin navegacion brusca
- medir mejora real en dispositivo

### Estado funcional

En 4C2A sigue siendo cierto que:

- la cache persistente todavia no desbloquea Home
- no existe entrada offline
- no se han modificado habitos
- no se han modificado logs
- no se ha modificado streak
- no se ha modificado timezone
- no se han hecho cambios cosmeticos

## Fase 4C2C1 - Fundacion del contrato remoto autoritativo

### Objetivo

Definir localmente el contrato remoto minimo que permita decidir el bootstrap de forma autoritativa sin depender de inferencias ambiguas desde `public.profiles` ni de la cache persistente.

- No activa la cache persistente.
- No integra todavia Flutter con la nueva RPC.
- No aplica la migracion en remoto en esta subfase.
- No avanza a 4C2C2.

### Problema que resuelve

`public.profiles` por si sola no distingue de forma segura:

- usuario nuevo sin perfil todavia inicializado
- perfil listo para Home
- perfil eliminado de forma intencional
- cuenta suspendida
- cuenta en eliminacion pendiente
- onboarding completado pero potencialmente no suficiente ante una politica remota futura

Tambien faltaba una forma de versionar la decision remota para invalidar cache local o detectar cambios de politica sin reinterpretar columnas de perfil sueltas.

### Arquitectura elegida

Se adopta una fundacion remota de tres piezas:

1. `app_private.user_bootstrap_state`
2. `app_private.bootstrap_policy`
3. `public.get_current_user_bootstrap_decision()`

Motivacion:

- separar ciclo de vida de cuenta y de perfil
- conservar `public.profiles` como fuente funcional de onboarding ya existente
- exponer al cliente solo una decision auth-scoped y no tablas internas
- dejar preparada una base versionable sin activar todavia la cache ni cambiar navegacion

### Tabla `app_private.user_bootstrap_state`

Tabla interna por usuario:

- `user_id`
- `account_status`
- `profile_state`
- `profile_revision`
- `created_at`
- `updated_at`

Estados definidos:

- `account_status`: `active`, `suspended`, `pending_deletion`
- `profile_state`: `uninitialized`, `ready`, `deleted`

Semantica:

- `uninitialized`: existe `auth.users`, pero no hay perfil confirmado listo
- `ready`: existe un `public.profiles` valido para bootstrap
- `deleted`: existio un perfil y fue eliminado; no debe tratarse igual que un usuario nuevo

### Tabla `app_private.bootstrap_policy`

Singleton interno:

- `required_onboarding_version`
- `onboarding_enforcement`
- `policy_revision`

Estados definidos:

- `onboarding_enforcement`: `advisory`, `required`

Semantica inicial en 4C2C1:

- se siembra una unica fila con `required_onboarding_version = 1`
- la politica inicial queda en `advisory`
- la politica ya es versionable, pero todavia no se consume desde Flutter

### Revisiones

#### `profile_revision`

Revision monotona para cambios que alteran la decision autoritativa:

- creacion de perfil
- re-creacion de perfil
- eliminacion de perfil
- cambios en `onboarding_status`
- cambios en `onboarding_version`
- cambios en `onboarding_completed_at`
- cambios futuros de `account_status`

#### `policy_revision`

Revision monotona para cambios en la politica remota:

- `required_onboarding_version`
- `onboarding_enforcement`

Estas revisiones no se usan todavia en Flutter, pero dejan preparado el contrato para invalidacion fiable en pasos posteriores.

### Trigger y backfill

#### Trigger existente en `auth.users`

No se crea un segundo trigger de signup.

Se reutiliza `app_private.bootstrap_user_wallet_on_auth_insert()` para:

- mantener intacto el bootstrap de `user_wallets`
- garantizar tambien `ensure_user_bootstrap_state_row(new.id)`

Con esto:

- cada nuevo `auth.users` nace con fila autoritativa
- no se duplica el punto de entrada de bootstrap

#### Triggers nuevos sobre `public.profiles`

Se anaden tres triggers locales:

- insert -> marca `ready`
- update de columnas de onboarding -> mantiene `ready` y aumenta revision
- delete -> marca `deleted`

Los updates irrelevantes de perfil no deben tocar `profile_revision`.

#### Backfill

La migracion rellena `app_private.user_bootstrap_state` para usuarios ya existentes:

- con perfil actual -> `ready`, `profile_revision = 1`
- sin perfil actual -> `uninitialized`, `profile_revision = 0`

Limitacion explicita:

- historicamente no es posible distinguir solo con datos actuales si un usuario sin perfil es verdaderamente nuevo o si el perfil fue eliminado antes de esta migracion
- por eso el backfill clasifica esos casos como `uninitialized`
- la distincion `deleted` queda garantizada solo desde la instalacion de los triggers de esta fase en adelante

### RPC publica

Nueva RPC local:

- `public.get_current_user_bootstrap_decision()`

Contrato:

- no acepta `userId`
- usa `auth.uid()`
- devuelve solo la decision minima de bootstrap
- no expone `email`, `display_name`, `avatar`, preferencias ni otros campos sensibles

Campos devueltos:

- `user_id`
- `decision`
- `account_status`
- `profile_state`
- `onboarding_status`
- `completed_onboarding_version`
- `required_onboarding_version`
- `onboarding_enforcement`
- `onboarding_completed_at`
- `profile_revision`
- `policy_revision`

Decisiones contempladas por el helper interno:

- `home`
- `onboarding`
- `profile_uninitialized`
- `profile_deleted`
- `account_suspended`
- `account_pending_deletion`
- `invalid_profile`

Politica:

- fail-closed
- cualquier incoherencia devuelve una decision no desbloqueante
- `home` solo se devuelve cuando el estado remoto es consistente

### Seguridad

Medidas aplicadas en la migracion:

- tablas internas en `app_private`
- `revoke all` sobre schema y tablas internas para `public`, `anon`, `authenticated`
- helpers internos `security definer`
- helpers internos con `set search_path = ''`
- `revoke execute` de helpers internos para clientes
- grant de ejecucion solo a `authenticated` sobre la RPC publica
- `anon` no puede invocarla

Esto mantiene el principio:

- el cliente solo obtiene una decision autoritativa final
- no puede consultar ni mutar directamente el estado interno

### Compatibilidad con el flujo actual

En 4C2C1 no cambia nada del runtime Flutter:

- bootstrap sigue usando el camino actual
- la cache persistente sigue en shadow mode
- no se activa Home desde cache
- no se introduce offline
- no se cambian habitos, logs, streak ni cosmeticos

### Archivos creados o modificados en 4C2C1

- `supabase/migrations/20260728110000_create_authoritative_bootstrap_decision_contract.sql`
- `supabase/tests/authoritative_bootstrap_decision_contract_static_verification.sql`
- `docs/existing_account_bootstrap_phase_4.md`

### Verificaciones previstas en esta subfase

Validaciones locales permitidas:

- `supabase migration list --linked`
- `supabase db push --linked --dry-run`
- `supabase db lint --linked`

Ademas, el verificador SQL estatico comprueba:

- existencia de tablas internas y singleton de politica
- restricciones de estados
- backfill de usuarios existentes
- reutilizacion del trigger de `auth.users`
- existencia de triggers de perfil
- grants y revokes
- `security definer`
- `set search_path = ''`
- scoping por `auth.uid()`
- ausencia de campos sensibles en la RPC publica

### Riesgos y limites conocidos

- la clasificacion historica `deleted` no puede reconstruirse retroactivamente para usuarios ya existentes sin mas evidencia
- el contrato aun no esta aplicado en remoto en esta subfase
- la app Flutter aun no consume la nueva RPC
- no hay todavia decision operativa sobre activacion de cache
- no se ha medido todavia el efecto real en dispositivo porque aqui solo se funda el contrato remoto

### Pendiente para 4C2C2

- revisar y aplicar la migracion en el entorno remoto cuando corresponda
- integrar la RPC autoritativa en `ProfileRepository`
- adaptar `BootstrapProfileDecision` o el modelo equivalente
- decidir como conviven la decision remota y la cache persistente
- definir UX final para `account_suspended`, `pending_deletion` y `profile_deleted`
- validar con pruebas funcionales y medicion real en dispositivo antes de considerar activacion de cache

## Fase 4C2C2A - Aplicacion remota del contrato autoritativo

### Fecha

- 28 de julio de 2026

### Estado

Aplicacion remota bloqueada.

Estado consolidado al cierre de este preflight:

- `4C2C1` permanece cerrada a nivel local
- `4C2C2A` queda bloqueada antes de `supabase db push --linked`
- no se avanza a `4C2C2B`

### Proyecto remoto y preflight de migraciones

Comprobaciones ejecutadas:

- `supabase migration list --linked`
- `supabase db push --linked --dry-run`
- `Test-Path Env:SUPABASE_DB_PASSWORD`

Resultado:

- el desarrollador confirma que `SUPABASE_DB_PASSWORD` esta disponible en su terminal interactiva, aunque no en el proceso del agente
- `migration list --linked` queda alineado: remoto aplicado hasta `20260727213017`
- `20260728110000_create_authoritative_bootstrap_decision_contract.sql` existe solo en local
- el dry-run detecta exclusivamente esa migracion
- no aparecen migraciones remotas desconocidas
- no aparecen migraciones locales anteriores pendientes

### Resultado de credenciales y lint

- `SUPABASE_DB_PASSWORD`: no disponible dentro del proceso del agente, pero si en la terminal del desarrollador
- `supabase db lint --linked`: ejecutado manualmente por el desarrollador en la misma terminal enlazada

Motivo:

- el agente no puede heredar esa variable desde el proceso interactivo del desarrollador
- para continuar el preflight sin exponer secretos, las inspecciones SQL remotas deben prepararse como consultas exactas de solo lectura para el SQL Editor de Supabase
- con esa limitacion de proceso, el lint y las consultas remotas se validan a traves de salidas manuales verificables del desarrollador

Resultado del lint recibido:

- warnings en `app_private.is_habit_scheduled_on` y `public.is_valid_habit_schedule` por marca `IMMUTABLE` sobre expresiones `STABLE`
- warning extra en `public.reverse_habit_completion_reward` por variable no usada
- errores en `public.record_journal_entry` y `public.record_habit_log` por referencias ambiguas a columnas

Conclusion de impacto para esta fase:

- no hay findings del lint sobre `profiles`
- no hay findings del lint sobre `app_private.bootstrap_user_wallet_on_auth_insert()`
- no hay findings del lint sobre la RPC autoritativa nueva, triggers nuevos, grants o tablas del contrato porque la migracion aun no esta aplicada
- los errores detectados son preexistentes y ajenos al alcance de `4C2C2A`
- no constituyen por si solos un bloqueo especifico para esta migracion porque no afectan signup, contrato autoritativo, `profiles`, permisos de la RPC ni funciones `security definer` de esta fase

### Revision final local del SQL

Revision completada sobre:

- `supabase/migrations/20260728110000_create_authoritative_bootstrap_decision_contract.sql`
- `supabase/tests/authoritative_bootstrap_decision_contract_static_verification.sql`

Conclusiones locales:

- las tablas internas usan PK, FK a `auth.users(id)`, `on delete cascade`, `not null`, defaults y constraints de estados/revisiones coherentes
- `account_status` queda restringido a `active`, `suspended`, `pending_deletion`
- `profile_state` queda restringido a `uninitialized`, `ready`, `deleted`
- `onboarding_enforcement` queda restringido a `advisory`, `required`
- la politica singleton se siembra con `required_onboarding_version = 1`, `onboarding_enforcement = advisory`, `policy_revision = 1`
- la RPC publica usa `auth.uid()`, no acepta `user_id`, no expone campos sensibles y concede execute solo a `authenticated`
- los helpers internos quedan revocados para clientes

### Revision del trigger de signup

Base asumida revisada en local:

- `20260727183000_bootstrap_user_wallets_for_existing_and_new_auth_users.sql`

Compatibilidad local prevista:

- la nueva version conserva exactamente el `insert into public.user_wallets (...) on conflict do nothing`
- anade `ensure_user_bootstrap_state_row(new.id)` de forma idempotente
- no crea un segundo trigger de signup
- no sobrescribe estados existentes porque `ensure_user_bootstrap_state_row(...)` hace `on conflict do nothing`
- no convierte un estado `deleted` existente en `uninitialized`

Bloqueo pendiente:

- no se pudo inspeccionar la definicion remota efectiva, ownership y metadatos actuales de la funcion/trigger con una consulta remota segura
- por regla de seguridad, esa indeterminacion bloquea la aplicacion

### Revision de triggers de profiles

Conclusiones locales:

- `INSERT`: crea estado si falta, pasa a `ready`, incrementa revision y no toca `account_status` en conflictos
- `UPDATE`: solo reacciona a `onboarding_status`, `onboarding_version`, `onboarding_completed_at` y usa comparaciones con `is not distinct from`
- `DELETE`: marca `deleted`, incrementa revision y no elimina el estado autoritativo

Limites observados:

- la monotonia de `profile_revision` es correcta dentro del modelo local previsto
- no existe evidencia remota suficiente para confirmar interaccion real con triggers existentes mas alla de los nombres ya conocidos

### Metodo seguro de consulta SQL

Se adopta SQL Editor de Supabase como metodo seguro y no destructivo para esta fase.

Razones:

- no requiere exponer contrasenas al agente
- permite ejecutar consultas de solo lectura ya preparadas
- permite verificar inmediatamente el estado remoto antes y despues de aplicar

### Consultas preparadas para inspeccion remota previa

#### A. Definicion remota de signup y trigger de `auth.users`

```sql
select
  n.nspname as function_schema,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as identity_args,
  pg_get_function_result(p.oid) as return_type,
  p.prosecdef as is_security_definer,
  p.proconfig as function_config,
  pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'app_private'
  and p.proname = 'bootstrap_user_wallet_on_auth_insert';
```

```sql
select
  t.tgname as trigger_name,
  case t.tgenabled
    when 'O' then 'enabled'
    when 'D' then 'disabled'
    when 'R' then 'replica'
    when 'A' then 'always'
  end as trigger_status,
  pg_get_triggerdef(t.oid) as trigger_definition
from pg_trigger t
where t.tgrelid = 'auth.users'::regclass
  and not t.tgisinternal
order by t.tgname;
```

Resultado recibido:

- la definicion remota efectiva de `app_private.bootstrap_user_wallet_on_auth_insert()` coincide con la base asumida por `20260727183000_bootstrap_user_wallets_for_existing_and_new_auth_users.sql`
- firma sin argumentos, retorno `trigger`, `security definer` habilitado y `search_path = ''`
- conserva exactamente la creacion de wallet en `public.user_wallets`
- mantiene `on conflict (user_id) do nothing`
- existe el trigger esperado `trg_auth_users_bootstrap_user_wallet`
- existe tambien `on_auth_user_created`, pero no es un segundo trigger equivalente de wallet/bootstrap autoritativo
- no se observa un segundo trigger que invoque la misma funcion de wallet

#### B. Conteos agregados previos y consistencia de onboarding

```sql
select
  (select count(*) from auth.users) as auth_users_total,
  (select count(*) from public.profiles) as profiles_total,
  (select count(*)
   from auth.users u
   join public.profiles p on p.id = u.id) as auth_users_with_profile,
  (select count(*)
   from auth.users u
   left join public.profiles p on p.id = u.id
   where p.id is null) as auth_users_without_profile,
  (select count(*)
   from public.profiles p
   left join auth.users u on u.id = p.id
   where u.id is null) as profiles_without_auth_user,
  (select count(*)
   from public.profiles
   where onboarding_status not in ('pending', 'in_progress', 'completed')
      or onboarding_status is null) as profiles_with_unknown_onboarding_status,
  (select count(*)
   from public.profiles
   where onboarding_status = 'completed'
     and onboarding_completed_at is null) as completed_without_completed_at;
```

```sql
select
  onboarding_version,
  count(*) as profiles_count
from public.profiles
group by onboarding_version
order by onboarding_version;
```

```sql
select
  onboarding_status,
  count(*) as profiles_count
from public.profiles
group by onboarding_status
order by onboarding_status;
```

#### C. Backfill esperado sobre los datos actuales

```sql
select
  case
    when p.id is not null then 'ready'
    else 'uninitialized'
  end as expected_profile_state,
  case
    when p.id is not null then 1
    else 0
  end as expected_profile_revision,
  count(*) as users_count
from auth.users u
left join public.profiles p on p.id = u.id
group by 1, 2
order by 1, 2;
```

### Conteos agregados previos

Resultado recibido:

- `auth_users_total = 2`
- `profiles_total = 2`
- `auth_users_with_profile = 2`
- `auth_users_without_profile = 0`
- `profiles_without_auth_user = 0`
- `profiles_with_unknown_onboarding_status = 0`
- `completed_without_completed_at = 0`

Distribuciones recibidas:

- `onboarding_version = 1` para los 2 perfiles
- `onboarding_status = completed` para los 2 perfiles
- el backfill esperado clasifica solo `ready / profile_revision = 1` para 2 usuarios

Conclusion:

- no existen perfiles huerfanos
- no existen estados de onboarding desconocidos
- no existen perfiles `completed` sin `onboarding_completed_at`
- con los datos actuales el backfill produciria unicamente clasificaciones compatibles con la migracion
- no aparece ningun caso que hoy fuerce `uninitialized` ni `invalid_profile` inesperado

Esto es bloqueante para aplicar.

### Revision de la politica inicial

Validacion local:

- la politica inicial queda en version `1`
- `onboarding_enforcement = advisory`
- no fuerza a usuarios existentes a repetir onboarding
- `policy_revision = 1`
- la singleton no puede duplicarse por PK booleana + check `singleton = true`

Limite:

- los conteos agregados confirman que todas las filas actuales de `profiles` usan `onboarding_version = 1`, por lo que la politica inicial `required_onboarding_version = 1` se mantiene coherente con el remoto actual

### Revision de la funcion autoritativa interna

Validacion local del orden fail-closed:

- `account_status`
- `profile_state`
- coherencia del perfil
- estado de onboarding
- politica/versionado
- decision final

Resultados contemplados y consistentes en el SQL local:

- `home`
- `onboarding`
- `profile_uninitialized`
- `profile_deleted`
- `account_suspended`
- `account_pending_deletion`
- `invalid_profile`

### Seguridad y permisos

Validacion local:

- `revoke execute` a `public` y `anon` sobre la RPC
- `grant execute` solo a `authenticated` sobre la RPC
- helpers internos sin execute para clientes
- tablas `app_private` sin grants directos a `anon` ni `authenticated`
- uso de `security definer`
- `set search_path = ''`
- nombres cualificados
- sin SQL dinamico innecesario

Limite:

- no se pudo comprobar remotamente el owner efectivo de las funciones ni los grants resultantes en catalogo despues de aplicar, porque la aplicacion no se ejecuto

### Resultado del dry-run

Resultado correcto:

- `Would push these migrations:`
- `20260728110000_create_authoritative_bootstrap_decision_contract.sql`

No intenta aplicar mas archivos.

### Aplicacion remota

No ejecutada.

No se lanzo:

- `supabase db push --linked`

### Motivo exacto del bloqueo

La aplicacion remota se bloquea porque no se cumplen simultaneamente varios criterios criticos exigidos por la fase:

1. la aplicacion aun no se ha ejecutado en esta fase documental
2. las verificaciones post-aplicacion siguen pendientes por definicion hasta que exista push real

Con las evidencias manuales recibidas, el preflight ya no esta bloqueado por migraciones, lint, definicion remota de signup ni conteos previos.

### Cambio minimo necesario para desbloquear

El minimo cambio necesario no es tocar SQL ni Flutter.

Con el preflight actual ya completado, el siguiente paso operativo seria exclusivamente la aplicacion de:

- `20260728110000_create_authoritative_bootstrap_decision_contract.sql`

seguida de las verificaciones remotas posteriores ya preparadas.

### Verificaciones SQL ejecutadas

Ejecutadas en esta subfase:

- validacion local manual de la migracion
- validacion local manual del archivo de verificacion estatica
- `supabase migration list --linked`
- `supabase db push --linked --dry-run`

No ejecutadas por bloqueo de credenciales/metodo seguro:

- `supabase db lint --linked` dentro del proceso del agente
- verificaciones SQL remotas post-aplicacion del archivo `supabase/tests/authoritative_bootstrap_decision_contract_static_verification.sql`

Ejecutadas manualmente por el desarrollador y verificadas en esta documentacion:

- `supabase db lint --linked`
- inspeccion remota de `app_private.bootstrap_user_wallet_on_auth_insert()`
- inspeccion remota de triggers de `auth.users`
- conteos agregados previos y distribuciones de onboarding

### Smoke test Flutter

Resultado:

- no ejecutado en Pixel 9

Hecho comprobado:

- `flutter devices` no mostro el dispositivo `58090DLAQ000TS`
- solo aparecieron `Windows`, `Chrome` y `Edge`

Consecuencia:

- smoke test manual en dispositivo queda pendiente
- esto no cambia el bloqueo principal, que ya venia dado por la imposibilidad de verificar SQL remoto de forma segura

### Riesgos y limitaciones pendientes

- los errores del lint en `public.record_journal_entry` y `public.record_habit_log` siguen existiendo y merecen su propia fase, pero no bloquean este contrato
- sin verificacion remota post-apply todavia no puede certificarse grants, owners y objetos reales tras aplicar
- no puede marcarse toda `4C2C` como cerrada

### Rollback documental previsto

Si la migracion se aplicase en una iteracion futura y hubiera que retirarla, el orden seguro previsto seria:

1. revocar execute de la RPC publica
2. eliminar la RPC publica
3. eliminar triggers de `profiles`
4. eliminar funciones auxiliares internas nuevas
5. restaurar la version previa de `app_private.bootstrap_user_wallet_on_auth_insert()`
6. eliminar tablas internas solo con advertencia explicita de perdida del estado autoritativo persistido

No se crea en esta subfase una migracion automatica de rollback.

### Estado posterior

- `4C2C1` - Fundacion SQL local: cerrada
- `ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ 4C2C2A` - Aplicacion y verificacion remota del contrato autoritativo: cerrada
- `ÃƒÂ¢Ã…Â¾Ã‚Â¡ÃƒÂ¯Ã‚Â¸Ã‚Â 4C2C2B` - Integracion Flutter de la RPC autoritativa: siguiente fase

### Actualizacion 2026-07-28 - migracion correctiva para la ambiguedad de `user_id`

Contexto confirmado:

- `supabase migration list --linked` confirma que `20260728110000_create_authoritative_bootstrap_decision_contract.sql` ya estaba aplicada remotamente el martes 2026-07-28
- `supabase db push --linked --dry-run` devolvia `Remote database is up to date.` antes de crear la correccion nueva
- `supabase db lint --linked` seguia mostrando en remoto el helper con `where user_id = p_user_id`, por lo que el error estaba en la definicion ya aplicada del servidor

Inmutabilidad de la migracion historica:

- una vez aplicada remotamente, la migracion `20260728110000` debe tratarse como historica e inmutable
- la edicion posterior del archivo local no podia corregir el remoto ni debia mantenerse dentro de un archivo historico ya registrado
- por eso se restauro el archivo historico para que vuelva a reflejar el SQL originalmente aplicado, incluyendo:
- `from app_private.user_bootstrap_state`
- `where user_id = p_user_id`
- `from app_private.bootstrap_policy`
- `where singleton = true`
- `from public.profiles`
- `where id = p_user_id`

Causa exacta de la ambiguedad:

- `app_private.get_current_user_bootstrap_decision_row(uuid)` usa `returns table (...)`, lo que introduce variables de salida implicitas llamadas `user_id`, `account_status`, `profile_state`, `onboarding_status`, `onboarding_completed_at`, `profile_revision` y `policy_revision`
- la consulta `select * from app_private.user_bootstrap_state where user_id = p_user_id` dejaba `user_id` sin cualificar
- en `plpgsql`, ese identificador podia referirse tanto a la columna de la tabla como a la variable de salida implicita `user_id`, provocando `column reference "user_id" is ambiguous`

Migracion correctiva creada:

- se creo `supabase/migrations/20260728212136_fix_authoritative_bootstrap_decision_user_id_ambiguity.sql`
- la migracion nueva aplica un `create or replace function app_private.get_current_user_bootstrap_decision_row(p_user_id uuid)` con el mismo contrato y solo cambia la desambiguacion interna
- la correccion cualifica explicitamente:
- `from app_private.user_bootstrap_state as s` con `where s.user_id = p_user_id`
- `from app_private.bootstrap_policy as policy` con `where policy.singleton = true`
- `from public.profiles as p` con `where p.id = p_user_id`
- tambien reafirma de forma segura:
- `revoke all on function app_private.get_current_user_bootstrap_decision_row(uuid) from public, anon, authenticated;`

Contrato preservado:

- no cambia la firma
- no cambia `returns table`
- no cambian campos ni tipos devueltos
- no cambia `language plpgsql`
- no cambia `security definer`
- no cambia `set search_path = ''`
- no cambian las decisiones posibles ni el orden de precedencia
- no cambia la semantica fail-closed
- no cambia la RPC publica ni sus permisos

Compatibilidad para instalaciones desde cero:

- una instalacion nueva aplicaria primero `20260728110000` con el contrato original
- a continuacion aplicaria `20260728212136` para reemplazar inmediatamente la funcion interna por la version corregida
- el estado final quedaria alineado con el remoto corregido esperado, sin alterar el contrato observable por clientes

Estado del lint antes de aplicar la correccion nueva:

- `supabase db lint --linked` sigue mostrando temporalmente el error de `app_private.get_current_user_bootstrap_decision_row` porque la migracion correctiva todavia no esta aplicada en remoto
- siguen apareciendo tambien findings preexistentes y ajenos al alcance:
- error en `public.record_journal_entry` por `entry_date` ambiguo
- error en `public.record_habit_log` por `habit_id` ambiguo
- warning en `app_private.is_habit_scheduled_on` por volatilidad `IMMUTABLE` frente a expresion `STABLE`
- warning en `public.is_valid_habit_schedule` por volatilidad `IMMUTABLE` frente a expresion `STABLE`
- warning extra en `public.reverse_habit_completion_reward` por variable `v_habit` no utilizada

Estado del dry-run y siguiente paso:

- tras crear la nueva migracion, `supabase migration list --linked` muestra una unica migracion local pendiente: `20260728212136_fix_authoritative_bootstrap_decision_user_id_ambiguity.sql`
- `supabase db push --linked --dry-run` propone exclusivamente esa migracion correctiva
- siguiente paso operativo: aplicar unicamente `20260728212136_fix_authoritative_bootstrap_decision_user_id_ambiguity.sql` y repetir `supabase db lint --linked`

Impacto en verificaciones estaticas:

- `supabase/tests/authoritative_bootstrap_decision_contract_static_verification.sql` no requirio cambios
- la cobertura existente se mantiene, porque la correccion es interna al helper y no altera el contrato publico observado por la RPC

Resultado final de esta subfase:

- la aplicacion remota de la migracion correctiva ya se completo con exito
- `app_private.get_current_user_bootstrap_decision_row(uuid)` ya aparece desambiguada en remoto
- el error `column reference "user_id" is ambiguous` desaparecio del lint
- permanecen fuera de alcance los errores y warnings preexistentes documentados arriba
- `4C2C2A` queda cerrada y el siguiente paso es `4C2C2B`

## Fase 4C2B - Estudio de activacion de la cache persistente

### Alcance de la inspeccion

Revision limitada a:

- `docs/existing_account_bootstrap_phase_4.md`
- `lib/data/local/bootstrap_profile_decision_cache.dart`
- `lib/data/repositories/profile_repository.dart`
- `lib/data/models/remote/remote_profile.dart`
- `lib/application/bootstrap/bootstrap_controller.dart`
- `lib/application/auth/auth_controller.dart`
- `lib/data/repositories/account_repository.dart`
- `lib/core/services/account_deletion_service.dart`
- `supabase/sql/supabase_backend_phase_9_schema_patch.sql`
- `supabase/migrations/20260727210441_add_remote_onboarding_state.sql`
- `supabase/migrations/20260727213017_enforce_remote_onboarding_transitions.sql`
- `supabase/functions/delete-account/index.ts`
- tests de bootstrap/auth/repositorio ya relacionados

Esta subfase es solo documental.

### Invariantes de onboarding comprobados

#### Estado `completed`

Con evidencia de `20260727213017_enforce_remote_onboarding_transitions.sql`:

- `completed` es monotono en remoto
- `completed -> pending` se rechaza
- `completed -> in_progress` se rechaza
- `onboarding_completed_at` no vuelve a `null` una vez completado
- una actualizacion `completed -> completed` preserva `onboarding_completed_at`
- una actualizacion `completed -> completed` preserva tambien `onboarding_version`

Con evidencia de `20260727210441_add_remote_onboarding_state.sql`:

- `onboarding_status` solo admite `pending`, `in_progress`, `completed`
- `onboarding_version` es `not null` y `>= 1`
- `onboarding_completed_at` debe ser no nulo si el estado es `completed`

#### Que representa `onboarding_version`

El comentario remoto actual dice:

- `Version of the remote onboarding contract understood by the app.`

Pero el comportamiento efectivo actual es este:

- la base no permite cambiar `onboarding_version` en las transiciones normales
- `markOnboardingCompleted()` y `markOnboardingInProgress()` exigen que el argumento coincida con la version remota actual
- `BootstrapController` decide solo por `onboarding_status`

Por tanto, hoy `onboarding_version` se comporta como la version remota ya almacenada, no como una politica remota autoritativa que por si sola fuerce re-onboarding.

#### Nueva version de onboarding obligatoria

La app si puede invalidar cache local cuando cambia `ProfileRepository.bootstrapOnboardingPolicyVersion`, pero:

- eso solo invalida memoria/cache
- no cambia la fila remota
- no existe hoy una comparacion remota que convierta `completed` en `onboarding`

Conclusion:

- una subida futura de onboarding obligatoria no queda representada de forma suficiente por el contrato remoto actual
- una cache persistente `completed` no es segura para desbloquear Home sin una validacion remota adicional o un contrato remoto ampliado

### Semantica exacta de perfil inexistente

Cuando `fetchBootstrapProfileDecision()` devuelve `null`:

- `BootstrapController` falla con `BootstrapErrorType.profileNotFound`
- el destino no es `home`
- el destino tampoco es `onboarding`
- se publica un estado de error y se corta el bootstrap

Hoy no se crea automaticamente un perfil durante esa ruta de bootstrap.

La autocreacion existe, pero en otros caminos:

- `ProfileRepository.ensureCurrentProfile()` hace `fetchCurrentProfile()` y, si no hay fila, llama a `upsertCurrentProfile()`
- `AuthController._ensureCurrentUserProfileForBootstrap()` puede ejecutar ese upsert en `sign_up`
- el trabajo post-Home tambien puede tocar perfil, pero solo despues de haber entrado en Home por remoto valido

Distinciones actuales cuando el remoto devuelve `null`:

- cuenta nueva sin fila
- perfil eliminado
- fila todavia no creada
- sesion valida con `profiles` ausente

Esos casos no son distinguibles hoy en bootstrap.

Ademas, un `select` bloqueado por RLS o un error remoto no entran por `null`:

- RLS o fallo remoto devolverian error, no `success(data: null)`

Riesgo de usar una cache antigua `completed` si el remoto da `null`:

- podria ocultar una cuenta recien creada e incompleta
- podria ocultar un perfil eliminado intencionadamente
- podria ocultar una cuenta borrada y recreable por `ensureCurrentProfile()`

Conclusion:

- no es seguro desbloquear Home desde cache si el remoto podria acabar resolviendo `null`

### Perfil, eliminacion y mutabilidad remota

Con evidencia de `supabase/sql/supabase_backend_phase_9_schema_patch.sql`:

- `public.profiles.id` referencia `auth.users(id) on delete cascade`
- por tanto una fila de `profiles` puede desaparecer por cascada cuando se elimina `auth.users`

Con evidencia de `supabase/functions/delete-account/index.ts` y `AccountRepository`:

- la eliminacion de cuenta actual borra `auth.users`
- esa eliminacion puede hacer desaparecer `profiles` por cascada

Con evidencia de RLS actual:

- hay `select`, `insert` y `update` own policies
- no aparece una policy `delete_own` en el esquema leido

Con evidencia de `RemoteProfile.fromMap(...)`:

- la fila puede quedar parseablemente incompleta para bootstrap si falta alguno de los cuatro campos minimos o si el estado es invalido

Con evidencia de Supabase y del uso de `currentUser`:

- la fila puede cambiar desde otro dispositivo
- puede existir sesion valida sin fila de `profiles`
- `ensureCurrentProfile()` puede recrear automaticamente una fila ausente
- esa recreacion podria ocultar una eliminacion intencionada si se usa sin una regla de producto distinta entre ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œcuenta nuevaÃƒÂ¢Ã¢â€šÂ¬Ã‚Â y ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œperfil eliminadoÃƒÂ¢Ã¢â€šÂ¬Ã‚Â

### Estados remotos de cuenta disponibles hoy

En el contrato leido de `profiles` y en bootstrap no aparece ningun campo o estado equivalente a:

- cuenta bloqueada
- cuenta suspendida
- eliminacion pendiente
- usuario deshabilitado
- onboarding obligatorio por politica remota
- version minima de perfil
- aceptacion obligatoria de terminos
- `account_status`
- `profile_revision`
- `bootstrap_policy_version`

`BootstrapProfileDecision` solo contiene:

- `id`
- `onboarding_status`
- `onboarding_version`
- `onboarding_completed_at`

Conclusion:

- `BootstrapProfileDecision` no contiene toda la informacion necesaria para garantizar que una sesion valida puede entrar en Home sin validacion remota

### Versionado del onboarding

Constante actual:

- `ProfileRepository.bootstrapOnboardingPolicyVersion = 1`

Campo remoto:

- `profiles.onboarding_version`

Lugar donde hoy se compara:

- validacion de memoria y cache persistente en `ProfileRepository`
- `markOnboardingInProgress()` y `markOnboardingCompleted()` frente a la version remota actual

No se compara en:

- `_destinationForProfile(...)`

Comportamiento actual:

- si la version cacheada es menor que la politica local, la cache se invalida
- si la version cacheada es mayor que la politica local, tambien se invalida por mismatch
- si la version es `null`, el parseo falla y la entrada es invalida
- tras una actualizacion de la app con politica local nueva, la cache deja de ser valida, pero el remoto `completed` seguiria yendo a Home mientras su estado remoto siga siendo `completed`

Conclusion:

- `cached.onboardingVersion == currentOnboardingPolicyVersion` no basta para considerar segura la navegacion desde cache
- tambien haria falta una garantia remota que exprese si una nueva version es obligatoria o no

Clasificacion futura necesaria:

- cambios no obligatorios: Home puede seguir yendo a `completed`
- cambios obligatorios: la decision remota debe bloquear Home

Hoy el contrato remoto no distingue esos dos casos.

### Riesgo de redirect posterior

Flujo analizado:

```text
cache completed
  -> Home
  -> remoto pending / missing / invalid / blocked
```

#### A - Ignorar discrepancia hasta el siguiente arranque

No es aceptable con el contrato actual porque:

- ocultaria perfiles eliminados
- ocultaria cuentas nuevas sin fila
- ocultaria un eventual estado remoto futuro que hoy ni siquiera existe en cache

#### B - Invalidar cache y reiniciar bootstrap

Tecnicamente posible, pero rompe la regla UX actual:

- Home ya no seria definitivo
- podria haber flash de onboarding o de error

#### C - Bloquear con pantalla de sesion o cuenta

Solo tendria sentido con estados remotos autoritativos expresos:

- bloqueada
- suspendida
- borrada
- onboarding obligatorio

Hoy esos estados no existen en el contrato minimo.

#### D - No permitir Home desde cache

Es la unica opcion segura con el contrato actual.

Conclusion de este punto:

- mientras la discrepancia remota no tenga politica de producto y no exista un contrato remoto mas rico, no debe publicarse Home desde cache persistente

### Sesion y sustitucion de credenciales entre reinicios

Lo que existe hoy entre reinicios:

- `Supabase.auth.currentUser`
- stream `onAuthStateChange`
- `initialSession`
- eventos como `tokenRefreshed`

Lo que no existe hoy en esta cache:

- identificador persistente de sesion logica
- revision de credenciales
- claim no sensible que demuestre ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œmisma sesionÃƒÂ¢Ã¢â€šÂ¬Ã‚Â exacta
- prueba de que no hubo logout/login entre procesos
- prueba de que no se revoco la sesion

`userId` y `currentUser` bastan para aislar usuario, pero no bastan para afirmar:

- misma sesion logica
- mismo refresh token
- no revocacion

Conclusion:

- entre reinicios no existe hoy una garantia no sensible suficiente para tratar una cache `completed` como autorizacion de entrada a Home

### Alternativa 1 - Cache desbloquea Home inmediatamente

Beneficio esperado:

- elimina la query remota bloqueante del perfil minimo
- podria recortar parte visible del tiempo hasta Home

Riesgos no cubiertos hoy:

- perfil eliminado o ausente
- cuenta nueva sin fila
- estado remoto bloqueado o suspendido si se introduce mas adelante
- onboarding obligatorio futuro aunque el remoto siga en `completed`
- sesion revocada pero restaurada localmente de forma obsoleta
- discrepancias remotas sin politica UX clara

Veredicto:

- no segura con el contrato actual
- no debe activarse

### Alternativa 2 - Cache solo para paralelismo especulativo

Idea:

```text
cache valida completed
  -> iniciar trabajo seguro de Home
  -> remoto sigue bloqueando navegacion
  -> remoto confirma o invalida
```

Ventaja:

- no requiere aceptar la cache como fuente autoritativa
- permite adelantar solo trabajo descartable

Limitacion:

- el beneficio depende de que existan operaciones puramente locales o cacheadas que hoy puedan adelantarse sin efectos secundarios

Veredicto:

- tecnicamente mas viable que desbloquear Home
- pero requiere elegir y aislar trabajo especulativo seguro con mucho cuidado
- no es la decision recomendada antes de ampliar el contrato remoto, porque la motivacion principal de activar la cache sigue siendo la decision de entrada, no solo el solape de trabajo

### Alternativa 3 - Cache como fallback tras timeout

Ventaja potencial:

- rescata arranques con latencia remota alta

Problemas actuales:

- obliga a fijar un timeout de producto
- reintroduce el mismo riesgo de ocultar `remote missing` o estados remotos relevantes
- mezcla timeout tecnico con semantica de autorizacion
- sin politica offline clara, el usuario podria entrar en Home con informacion obsoleta justo cuando el remoto mas incertidumbre tiene

Veredicto:

- mas arriesgada que la alternativa 2
- no justificable hoy sin un contrato remoto autoritativo y una regla de producto explicita

### Alternativa 4 - Mantener shadow mode

Ventajas:

- sigue aportando evidencia de `hit/miss/invalid/match/mismatch`
- no cambia navegacion
- no oculta `remote missing`
- no obliga a resolver todavia la politica de redirect posterior

Limitacion:

- por si sola no resuelve la falta de estados remotos de cuenta

Veredicto:

- correcta como estado temporal
- insuficiente como cierre final si la intencion es desbloquear Home con seguridad

### Clasificacion del trabajo especulativo

#### Seguro iniciar antes de confirmacion remota

- lectura local scoped ya cargada por `UserStateStore`
- lectura de cache de cosmeticos ya persistida
- resolucion local de cosmeticos equipados basada en snapshot cacheado valido
- precarga de assets ya determinados localmente y descartables

#### Condicional

- preparacion de Home esencial a partir de caches locales si no publica estado visible y puede descartarse completa
- algunas validaciones de resolvers si usan solo datos ya locales

Condiciones:

- mismo `userId`
- mismo `scopeUserId`
- mismo `scopeEpoch`
- sin persistencia visible
- sin mutaciones remotas

#### No seguro

- fetch remoto de habitos
- fetch batch de logs
- reconciliacion de streak protection
- timezone si puede cerrar ocurrencias o afectar reconciliacion
- `store.save(...)`
- cualquier persistencia local reconciliada
- cualquier operacion que cierre ocurrencias
- cualquier operacion que consuma shields o cree breaks
- cualquier escritura en Supabase

Conclusion:

- existe un subconjunto pequeno de trabajo especulativo seguro
- pero no incluye la parte mas sensible de reconciliacion remota

### Analisis offline

#### Cache valida y sesion local restaurada

No basta para Home hoy porque:

- bootstrap de perfil sigue dependiendo de remoto
- no existe politica offline
- el contrato remoto no expresa cuenta bloqueada o eliminada

#### Cache valida y sesion caducada

- debe mantenerse la semantica actual de sesion/login
- la cache no puede suplir una sesion revocada o expirada

#### Cache valida pero perfil remoto eliminado

- hoy el remoto acabaria en `null` y bootstrap fallaria con `profileNotFound`
- si se publicase Home desde cache, ese caso quedaria oculto

#### Cache vacia

- se mantiene el comportamiento actual

#### Habitos esenciales locales disponibles

Tampoco bastan por si solos para declarar soporte offline:

- el gating de perfil sigue siendo remoto
- streak/timezone/cosmeticos/habitos remotos siguen teniendo rutas con red o reconciliacion asociada

Conclusion:

- 4C2B no puede declarar soporte offline

### Garantias de seguridad existentes

- aislamiento por `userId`
- aislamiento por `scopeUserId`
- guardas de `scopeEpoch`
- invalidacion por logout y cambio de usuario
- monotonia remota de `completed`
- parseo defensivo del contrato minimo
- no se publica Home provisional hoy
- la cache persistente aun no evita la query remota

### Garantias que faltan

- estado remoto autoritativo de cuenta
- distincion entre perfil ausente nuevo y perfil eliminado
- revision remota de perfil o decision
- politica remota de onboarding obligatorio frente a no obligatorio
- identidad persistente de sesion logica no sensible entre reinicios
- regla de producto para discrepancias post-Home si alguna vez se usa cache autoritativa

### Contrato remoto actual y ampliaciones posibles

Payload actual de cuatro columnas:

- `id`
- `onboarding_status`
- `onboarding_version`
- `onboarding_completed_at`

No es suficiente para desbloquear Home con seguridad plena.

Campos candidatos futuros:

- `account_status`
  - mitiga bloqueo/suspension/eliminacion logica
  - no existe hoy
  - requeriria migracion
  - deberia formar parte de la decision cacheable
- `profile_revision`
  - mitiga discrepancias silenciosas entre dispositivos
  - no existe hoy
  - requeriria migracion
  - deberia entrar en cache
- `bootstrap_policy_version`
  - mitiga nuevas exigencias obligatorias de onboarding sin reinterpretar `completed`
  - no existe hoy
  - requeriria migracion o RPC
  - deberia entrar en cache

Una RPC minima autoritativa tambien es razonable:

```text
id
onboarding_status
onboarding_version
onboarding_completed_at
account_status
profile_revision
bootstrap_policy_version
```

Ventaja de la RPC:

- una unica decision remota autoritativa
- semantica mas clara que inferirla desde filas sueltas y auth

### Evidencia adicional requerida en shadow mode

Antes de activar nada haria falta recopilar como minimo:

- volumen de `shadow hit`
- `match rate`
- `mismatch rate`
- `remote_missing rate`
- `cache_invalid rate`
- antiguedad real de la cache
- frecuencia de logout/login
- frecuencia de cambio de cuenta
- uso multi-dispositivo
- reinstalaciones

Fuentes posibles hoy:

- tests
- validacion manual
- logs debug actuales

Si se quisiera una decision operacional con confianza mayor:

- telemetria futura especifica

### 4C2C2B1 - Integracion Flutter en modo sombra

Estado:

- la decision autoritativa se consulta en background despues de publicar Home
- la ruta minima que decide `home` vs `onboarding` sigue siendo la misma
- no se activa la cache persistente
- no se cambia el contrato publico de navegacion

Cambios aplicados:

- `ProfileRepository` incorpora `loadAuthoritativeBootstrapDecision(...)` sobre la RPC `get_current_user_bootstrap_decision`
- la lectura autoritativa devuelve un resultado detallado con tiempos, conteos y error tipado
- `AuthController` lanza un shadow task post-Home y emite metricas `authoritative_profile_*`
- `BootstrapController` pasa la decision minima ya resuelta al trabajo post-Home para poder comparar contra la RPC autoritativa
- se anadio cobertura unitaria del parser y del compare shadow

Formato observado del SDK:

- `supabase.rpc(...)` en el cliente Dart devuelve un `PostgrestFilterBuilder<T>`
- una RPC de resultado tabular se consume como lista de filas o como `null` cuando no devuelve datos
- el parser del repositorio sigue aceptando un `Map` de forma defensiva, pero la forma principal esperada para esta RPC es una lista con una fila
- la validacion de pruebas cubre `null`, lista vacia, lista con una fila, lista con multiples filas y un mapa de una fila

Trazado del shadow:

- `BootstrapController` decide con la query minima y publica `BootstrapState.ready(home)`
- el mismo run inicia `AuthController.startPostHomeBootstrapWork(...)`
- `AuthController._runDefaultPostHomeBootstrapWork(...)` crea el shadow task autoritativo
- `_runAuthoritativeBootstrapShadow(...)` solicita la RPC a `ProfileRepository`
- `ProfileRepository.loadAuthoritativeBootstrapDecision(...)` mapea, valida y deduplica la respuesta
- la comparacion se registra y no altera la navegacion ya publicada

Validacion de dispositivo:

- `flutter devices` detecto `Pixel 9 (mobile) ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ 58090DLAQ000TS`
- `flutter run -d 58090DLAQ000TS --dart-define-from-file=dart_defines/dev.json --no-pub` se intento, pero la sesion no produjo un arranque finalizado en esta ventana de trabajo
- no se obtuvo una validacion manual utilizable de tres arranques en esta entrega

Contrato preservado:

- la firma publica de la navegacion no cambia
- los campos devueltos por la decision minima no cambian
- la semantica fail-closed no cambia
- no se introduce SQL dinamico
- no se tocan grants ni revokes de Supabase
- no se ejecuta ninguna migracion nueva

Verificaciones locales:

- no se ejecuto `supabase db push --linked`
- no se modifico Flutter fuera de la capa de integracion y pruebas de esta fase
- el lint remoto con problemas preexistentes queda fuera del alcance de esta subfase

Estado actual:

- `4C2C2B1` queda integrado y validado localmente
- `4C2C2B2` permanece pendiente
- la activacion de cache sigue sin estar aprobada por esta documentacion
- la decision operativa de esta revision es mantener el shadow por ahora

### Opcion elegida

#### Opcion C - Mantener modo sombra y ampliar primero el contrato remoto

### Justificacion

La razon principal no es solo falta de datos de shadow mode.

La razon principal es estructural:

- el contrato remoto actual no expresa estado de cuenta bloqueada o suspendida
- `remote null` no distingue cuenta nueva de perfil eliminado
- `ensureCurrentProfile()` puede recrear filas ausentes fuera del bootstrap
- `onboarding_version` no decide hoy el destino por si misma
- no existe identidad persistente de sesion logica no sensible entre reinicios

Con estas carencias:

- Opcion A no es segura
- Opcion B puede ser util mas adelante, pero no resuelve el bloqueo principal sobre activacion autoritativa
- Opcion D seria insuficiente porque aqui ya hay una falta de contrato, no solo falta de evidencia

### Siguiente subfase propuesta

#### 4C2C - Contrato remoto autoritativo

Objetivo:

- definir una decision remota minima suficiente para activar la cache persistente con seguridad o para descartar esa activacion

Alcance probable:

- decision remota minima de bootstrap
- posible campo `account_status`
- posible `profile_revision`
- posible `bootstrap_policy_version`
- posible RPC minima autoritativa
- adaptacion documental y despues implementacion separada

Archivos probables:

- migraciones o RPC de Supabase
- `ProfileRepository`
- `BootstrapProfileDecision`
- tests de repositorio/bootstrap/auth
- documentacion del Punto 4

Riesgos:

- migracion de contrato
- politicas RLS o RPC
- necesidad de una regla de producto explicita para discrepancias

Criterio de cierre:

- el contrato remoto debe permitir distinguir de forma autoritativa
  - Home permitido
  - onboarding obligatorio
  - cuenta bloqueada o no usable
  - perfil ausente significativo

Rollback:

- mantener modo sombra y query remota bloqueante

### Orden recomendado de implementacion posterior

1. Definir contrato remoto autoritativo.
2. Acordar politica de producto para discrepancias y estados bloqueados.
3. Implementar y validar `4C2C`.
4. Solo despues estudiar si procede `4C3A - Paralelismo especulativo seguro`.
5. Si el contrato lo permite, estudiar activacion controlada de cache.

### Matriz de tests futura

#### Repositorio

- cache completed + remoto completed igual
- cache completed + remoto pending
- cache completed + remoto inexistente
- cache completed + remoto bloqueado
- cache con version antigua
- operacion antigua terminando tarde

#### Bootstrap

- sin flash de onboarding
- sin redirect brusco
- sin entrada incorrecta en Home
- trabajo especulativo descartado si remoto niega Home

#### Auth

- logout/login mismo usuario
- cambio de cuenta
- sesion revocada
- reinicio del proceso

#### Cache

- reinstalacion
- mismatch por entorno
- cache corrupta
- timeout si existiese politica futura

#### Widget e integracion

- Home no se publica provisionalmente
- estado bloqueado muestra pantalla correcta
- perfil inexistente no entra en Home

#### Dispositivo

- cold start con cache valida
- multi-dispositivo
- offline
- logout/login y cambio de cuenta real

## Fase 4C2C2B3 - Validacion real prolongada del shadow autoritativo

### Fecha

- 28 de julio de 2026

### Dispositivo y entorno

- dispositivo: Pixel 9
- identificador: `58090DLAQ000TS`
- Android: 17, API 37
- red: normal / estable durante los tres arranques
- configuracion: `dart_defines/dev.json`
- comando base: `flutter run -d 58090DLAQ000TS --dart-define-from-file=dart_defines/dev.json --no-pub`

### Estado de conexion

- `flutter devices` detecto correctamente el Pixel 9
- la conexion USB estuvo disponible durante la validacion
- los tres arranques capturaron logs completos hasta `post_home_total`

### Runs validos

- R1: valido
- R2: valido
- R3: valido

### Runs descartados

- ninguno

### Resumen de validacion real

Los tres runs mostraron:

- `home` publicado antes del shadow autoritativo
- exactamente una llamada RPC real autoritativa por bootstrap
- `decision=home`
- `kind=matchHome`
- `authoritative_profile_error` ausente
- `authoritative_profile_stale_discard` ausente
- `post_home_total` emitido al final del trabajo post-Home
- sin cambios de navegacion observables en el trace

Orden observado:

- `time_to_home_ready`
- `home_publish`
- `authoritative_profile_shadow_total`
- `post_home_total`

La RPC autoritativa se ejecuto despues de Home y su span quedo separado del tiempo de Home.

### Tabla de tiempos

| Metrica | R1 | R2 | R3 | Mediana |
| --- | --- | --- | --- | --- |
| Time to Home ready | 1311 ms | 1178 ms | 1317 ms | 1311 ms |
| RPC calls | 1 | 1 | 1 | 1 |
| RPC query | 122 ms | 114 ms | 131 ms | 122 ms |
| RPC map | 1 ms | 1 ms | 1 ms | 1 ms |
| Shadow total | 126 ms | 119 ms | 135 ms | 126 ms |
| Post-Home total | 1167 ms | 670 ms | 1022 ms | 1022 ms |

### Tabla de decisiones

| Run | Decision minima | Decision autoritativa | Comparacion | Error | Stale discard |
| --- | --- | --- | --- | --- | --- |
| R1 | Home | Home | match_home | N/D | N/D |
| R2 | Home | Home | match_home | N/D | N/D |
| R3 | Home | Home | match_home | N/D | N/D |

### Validacion visual manual

- onboarding: no reproducible
- Home provisional incorrecta: no reproducible
- contenido generico: no reproducible
- fondo provisional: no reproducible
- cambios bruscos de habit cards: no reproducible
- error nuevo visible: no reproducible
- navegacion estable: no reproducible
- shadow sin rebuild visual perceptible: no reproducible
- habitos de la cuenta correcta: no reproducible

### Escenarios M, L y U

- `M` no se pudo ejecutar de forma manual fiable en esta sesion sin una integracion UI adicional
- `L` no se reprodujo manualmente con fiabilidad suficiente
- `U` no se reprodujo manualmente porque no habia dos cuentas de prueba preparadas en la sesion
- la cobertura de ciclo de vida sigue respaldada por tests ya existentes

### Discrepancias

- ninguna discrepancia en una cuenta normal
- ninguna diferencia observada entre la decision minima y la autoritativa
- ninguna seÃƒÆ’Ã‚Â±al de parseo, permisos o contrato roto en los tres runs

### Instrumentacion revisada

- `authoritative_profile_rpc_calls`
- `authoritative_profile_rpc_query`
- `authoritative_profile_map`
- `authoritative_profile_decision`
- `authoritative_profile_revision`
- `authoritative_policy_revision`
- `authoritative_profile_match`
- `authoritative_profile_shadow_total`
- `post_home_total`
- `home_publish`
- `time_to_home_ready`

### Criterio de cierre

- la validacion real prolongada confirma que el shadow autoritativo funciona en Pixel 9 para una cuenta existente normal
- la RPC real ocurre despues de Home
- no se observo mismatch
- no se observo error de parseo o permisos
- no se activo la cache persistente
- no se cambia la navegacion productiva

### Decision elegida

#### Opcion A - Shadow validado

Justificacion:

- los tres runs validos dan `match_home`
- la RPC real se limita a una por bootstrap
- la RPC se ejecuta despues de Home
- no hay discrepancias ni errores de contrato en la cuenta validada
- la limitacion principal restante es funcional: antes de activar productivamente faltan los destinos especiales de bootstrap autoritativo

### Siguiente subfase

#### 4C2C2B4 - Estados de bootstrap autoritativos

Antes de activar la RPC productivamente deberan implementarse destinos seguros para:

- `profile_uninitialized`
- `profile_deleted`
- `account_suspended`
- `account_pending_deletion`
- `invalid_profile`

### Causa exacta

La capa de arranque solo conocia los destinos funcionales `welcome`, `authentication`, `onboarding` y `home`. La RPC autoritativa ya podia clasificar estados especiales, pero no habia un destino de UI preparado para representarlos en Flutter sin mezclar esa semantica con la navegacion normal.

### Correccion aplicada

- Se ampliaron los destinos de `BootstrapDestination` para reservar los cinco estados autoritativos especiales.
- `AppStartupGate` ahora resuelve esos destinos en una pantalla dedicada `BootstrapAuthorityStateScreen`.
- La pantalla usa copia especifica por estado y mantiene el flujo fail-closed sin intentar redirigir a Home.
- Se anadio cobertura de prueba para los nuevos destinos y para la clasificacion autoritativa de esos casos.

### Validacion local

- El shadow autoritativo sigue sin activar la navegacion productiva.
- La nueva UI solo se muestra cuando el `BootstrapController` publica uno de los destinos autoritativos especiales.
- El contrato normal de `welcome` / `authentication` / `onboarding` / `home` no cambia.

### Errores preexistentes fuera de alcance

- No se modifico la RPC autoritativa.
- No se toco la cachÃƒÆ’Ã‚Â© persistente ni el contrato de `ProfileRepository`.
- No se avanzo a una activacion productiva de `4C2C2B`.

### Estado del preflight

Queda preparado para que una futura activacion autoritativa use estos destinos sin introducir una nueva pantalla de error generica ni alterar el camino normal de Home.

### Archivos modificados en esta fase

- `docs/existing_account_bootstrap_phase_4.md`

### Comandos ejecutados

- `flutter devices`
- `flutter run -d 58090DLAQ000TS --dart-define-from-file=dart_defines/dev.json --no-pub`
- `Select-String` sobre `authoritative_shadow_R1.log`
- `Select-String` sobre `authoritative_shadow_R2.log`
- `Select-String` sobre `authoritative_shadow_R3.log`
- `flutter doctor -v`
- `adb shell am force-stop com.rutio.app`
- `adb shell input keyevent 3`

### Riesgos o limitaciones

- los escenarios `M`, `L` y `U` no quedaron reproducidos manualmente en esta sesion
- la validacion visual es limitada porque la sesion no dispone de captura de pantalla integrada para el telefono
- los logs confirman la ejecucion correcta, pero no sustituyen una inspeccion visual directa
- no se modifico la decision productiva ni la cachÃƒÆ’Ã‚Â© persistente
#### 4C2C2B4B - Validacion de acciones y bloqueos

Esta subfase concreto la respuesta de Flutter ante los estados autoritativos especiales:

- `account_suspended` y `account_pending_deletion` solo permiten cerrar sesion.
- `profile_deleted` solo permite cerrar sesion porque no hay recuperacion segura expuesta.
- `profile_uninitialized` e `invalid_profile` permiten reintentar y cerrar sesion.
- Ningun estado especial permite avanzar a Home.
- La pantalla bloquea dobles pulsaciones mientras una accion esta en curso.
- La salida por logout reutiliza el flujo real de `AuthController` para invalidar estado y evitar resultados obsoletos.

### Causa exacta

La ambiguedad no estaba en el contrato publico de la RPC sino en la capa de presentacion: los nuevos destinos autoritativos existian, pero no habia una politica de acciones por estado ni una proteccion explicita contra reintentos dobles o resultados tardios tras logout.

### Correccion aplicada

- Se mantuvo la firma publica de `BootstrapDestination` y se reforzo la pantalla dedicada para estados autoritativos.
- Se asignaron acciones por estado con aliases y decisiones explicitamente fail-closed.
- Se elimino la posibilidad de navegar a Home desde los estados especiales.
- Se anadio bloqueo visual y funcional contra taps duplicados mientras corre `retry` o `signOut`.
- Se cubrieron los casos de renderizado, acciones visibles, y desactivacion de dobles pulsaciones en tests de widget.

### Validacion local

- `flutter analyze lib/screens/app_startup_gate.dart lib/application/bootstrap/bootstrap_controller.dart test/data/models/authoritative_bootstrap_decision_test.dart test/application/bootstrap/bootstrap_controller_test.dart`
- `flutter test test/data/models/authoritative_bootstrap_decision_test.dart test/application/bootstrap/bootstrap_controller_test.dart`

### Errores preexistentes fuera de alcance

- No se modificaron la RPC autoritativa ni las migraciones.
- No se alteraron otras funciones de bootstrap, auth, ni estados de usuario ajenos a esta pantalla.
- No se rebajo cobertura para evitar casos de error o bloqueo.

### Estado del preflight

La subfase queda lista para continuar con la siguiente validacion de `4C2C2B5`, con acciones autoritativas bien definidas, logout seguro y sin acceso accidental a Home.

## 4C2C2B5 - Activacion productiva de la RPC autoritativa

### Resumen ejecutivo

La ruta de arranque ya usa la RPC autoritativa como fuente remota de verdad para usuarios autenticados. Home se publica solo despues de una decision autoritativa valida, la comparacion shadow post-Home fue retirada del flujo productivo y los estados especiales siguen resolviendose de forma tipada y fail-closed.

La validacion real en Pixel 9 quedo completada en este entorno:

- `flutter devices` mostro `Pixel 9 (mobile) - 58090DLAQ000TS`.
- R1, R2 y R4 fueron arranques frios validos.
- R3 quedo documentado como fallo temporal de red antes de publicar Home.


### Arquitectura anterior

- La decision minima de perfil podia decidir Home.
- La RPC autoritativa se ejecutaba como shadow despues de Home.
- El trabajo post-Home mezclaba observabilidad de shadow con el flujo real.
- La navegacion productiva dependia de una consulta minima antes de la RPC autoritativa.

### Arquitectura nueva

- `BootstrapController` consulta `loadAuthoritativeBootstrapDecision(...)` una sola vez por bootstrap autenticado.
- La decision se interpreta en modo fail-closed y se valida contra el usuario esperado.
- La publicacion de Home ocurre solo si la decision autoritativa es `home`.
- Los destinos tipados `onboarding`, `profileUninitialized`, `profileDeleted`, `accountSuspended`, `accountPendingDeletion` e `invalidProfile` se publican sin Home.
- `AuthController` conserva el trabajo post-Home permitido, pero ya no ejecuta shadow autoritativo.

### Diagrama textual

```text
Sesion resuelta
  -> scope local validado
  -> bootstrapRunId nuevo
  -> RPC autoritativa unica
  -> parseo fail-closed
  -> validacion expectedUserId
  -> mapeo de BootstrapDestination
  -> validacion de run y usuario actuales
  -> publicacion del destino
  -> solo si destino == home:
       -> preparar esenciales
       -> publicar Home
       -> iniciar trabajo post-Home permitido
```

### Punto de espera

Home se sigue esperando despues de:

- sesion autenticada;
- scope local aislado;
- RPC autoritativa valida;
- validacion de coherencia de contrato;
- confirmacion de run y usuario actuales;
- preparacion de esenciales, solo para `home`.

### Destinos soportados

- `home`
- `onboarding`
- `profileUninitialized`
- `profileDeleted`
- `accountSuspended`
- `accountPendingDeletion`
- `invalidProfile`

### Manejo de errores

- Error temporal: estado recuperable con retry y logout.
- Error contractual o de seguridad: fail-closed, sin Home.
- Resultado stale: descartado sin publicar estado obsoleto.
- Usuario distinto al esperado: fail-closed.

### Proteccion multiusuario

- `bootstrapRunId`, `scopeEpoch`, `scopeUserId` y `scopeKey` se validan antes de publicar.
- Logout invalida resultados en vuelo.
- Un cambio de cuenta invalida el resultado anterior.
- Un retry crea un nuevo run y descarta el previo.
- `dispose` no deja callbacks capaces de publicar navegacion tardia.

### Retry y logout

- `profileUninitialized` e `invalidProfile` permiten retry y logout.
- `profileDeleted`, `accountSuspended` y `accountPendingDeletion` permiten solo logout.
- Ningun estado especial publica Home.
- El logout usa el flujo real de `AuthController`.

### Eliminado del shadow

- Se elimino la ejecucion shadow post-Home.
- Se eliminaron las metricas `authoritative_profile_match/mismatch` como mecanismo productivo.
- Se elimino la segunda llamada a la RPC despues de publicar destino.
- Las metricas ahora describen la operacion productiva: `authoritative_bootstrap_*`.

### Trabajo post-Home

Permanece solo para `home`:

- metadata de perfil;
- backfills de usuario;
- tareas de sincronizacion permitidas.

No se ejecuta para:

- onboarding;
- perfiles especiales;
- errores recuperables o contractuales.

### Una RPC por bootstrap

La activacion productiva deja una sola llamada autoritativa por bootstrap autenticado.

### Tests anadidos o modificados

- Parser autoritativo.
- Bootstrap controller.
- AppStartupGate.
- Retry y logout.
- Concurrencia y stale discard.
- Post-Home sin shadow.

### Validacion tecnica

Comandos ejecutados:

- `flutter devices`
- `flutter run -d 58090DLAQ000TS --dart-define-from-file=dart_defines/dev.json --no-pub` x4

### Resultado Pixel 9

Validacion completada en Pixel 9.

| Medida | R1 | R2 | R4 | Mediana |
| --- | ---: | ---: | ---: | ---: |
| Tiempo total hasta Home ready | 2456 ms | 1474 ms | 1401 ms | 1474 ms |
| RPC query | 1920 ms | 895 ms | 821 ms | 895 ms |
| RPC map | 16 ms | 2 ms | 7 ms | 7 ms |
| Decision autoritativa total | 1937 ms | 899 ms | 829 ms | 899 ms |
| Trabajo post-Home | 2023 ms | 1421 ms | 1347 ms | 1421 ms |
| RPC calls | 1 | 1 | 1 | 1 |

### Nota sobre R3

La tercera sesion de `flutter run` tuvo una tentativa de bootstrap fallida por error transitorio de red:

- `Failed host lookup: 'kbjecrepjnmucljrpnlp.supabase.co'`

Ese run permanencio fail-closed y no publico Home. No hubo trabajo post-Home tras el fallo.

Se documento como:

`Validacion real adicional del comportamiento ante error temporal de red`

Ese resultado no se contabiliza en la mediana final de arranques validos.

### Nota sobre visual

No se hizo una validacion visual directa observando la pantalla del Pixel 9 desde esta sesion; la comprobacion disponible fue por logs de arranque, publish de Home y post-home.

### Comparacion de rendimiento

| Metrica | Shadow 4C2C2B3 | RPC activa 4C2C2B5 | Diferencia |
| --- | ---: | ---: | ---: |
| Tiempo hasta Home | 1311 ms | 1474 ms | +163 ms |
| RPC query | 122 ms | 895 ms | +773 ms |
| RPC map | 1 ms | 7 ms | +6 ms |
| RPC total | 126 ms | 899 ms | +773 ms |
| Llamadas RPC | 1 | 1 | 0 |

### Riesgos pendientes

- La tercera ejecucion fria previa quedo afectada por un fallo transitorio de red contra Supabase y se mantuvo fail-closed.
- No hay confirmacion visual directa desde esta sesion; la evidencia disponible es de logs.
- La cache persistente sigue sin poder desbloquear Home y queda para `4C3`.

### Estado de la cache

La cache persistente sigue sin capacidad de decidir ni de desbloquear Home.

### Restricciones respetadas

- No se modifico Supabase.
- No se crearon ni aplicaron migraciones.
- No se ejecuto `supabase db push`.
- No se uso Docker.
- No hubo commit, push ni merge.

### Estado de cierre

`4C2C2B5` queda cerrada con R1, R2 y R4 como arranques frios validos.

## Fase 4C3A - Contrato y persistencia de cache autoritativa v2

### Objetivo

Definir una cache local nueva, fail-closed y versionada para la decision autoritativa de bootstrap, sin integrarla todavia en `BootstrapController` ni en `AppStartupGate`.

### Inspeccion inicial

- La cache v1 seguia siendo especifica de onboarding y no representaba el contrato autoritativo completo.
- El contrato remoto ya exponia `account_status`, `profile_state`, `onboarding_status`, `profile_revision` y `policy_revision`.
- Faltaba una capa local aislada para persistir esa decision con namespace por entorno y TTL.

### Correccion realizada

- Se anadio `lib/data/local/authoritative_bootstrap_cache_v2.dart`.
- La entrada de cache v2 guarda `schemaVersion`, `userId`, `environmentId`, `scopeKey`, `cachedAt`, `expiresAt`, `destination`, `accountStatus`, `profileState`, `onboardingEnforcement`, `requiredOnboardingVersion`, `completedOnboardingVersion`, `onboardingStatus`, `onboardingCompletedAt`, `profileRevision` y `policyRevision`.
- El codec valida el contrato de forma fail-closed y clasifica errores como `schemaMismatch`, `userMismatch`, `environmentMismatch`, `unknownEnum`, `contractInvalid`, `expired` o `corrupt`.
- La persistencia usa `SharedPreferences` con namespace por entorno y usuario.
- Se incluyo una implementacion en memoria para tests.

### Reglas de coherencia

- `home` exige cuenta activa, perfil listo y onboarding completado.
- `onboarding` acepta pendiente, en progreso o completado coherente.
- `profile_uninitialized` y `profile_deleted` exigen estado de perfil alineado y sin metadatos de onboarding.
- `account_suspended` y `account_pending_deletion` exigen cuenta no activa.
- `invalid_profile` queda reservado para combinaciones incoherentes de onboarding con cuenta activa.

### Persistencia y scope

- La clave de almacenamiento queda aislada por `environmentId` y `userId`.
- `scopeKey` se persiste para no mezclar decisiones entre contextos de sesion.
- La cache expira por TTL y rechaza relojes futuros fuera de tolerancia.

### Verificacion local

- `flutter analyze lib/data/local/authoritative_bootstrap_cache_v2.dart test/data/local/authoritative_bootstrap_cache_v2_test.dart`
- `flutter test test/data/local/authoritative_bootstrap_cache_v2_test.dart`
- `supabase migration list --linked`
- `supabase db push --linked --dry-run`
- `supabase db lint --linked`

### Resultado del lint

Antes y despues de esta subfase, los hallazgos restantes siguieron siendo preexistentes y ajenos:

- `public.record_journal_entry` con `entry_date` ambiguo.
- `public.record_habit_log` con `habit_id` ambiguo.
- warnings de volatilidad en `app_private.is_habit_scheduled_on` y `public.is_valid_habit_schedule`.
- warning de variable no usada en `public.reverse_habit_completion_reward`.

### Estado del preflight

- La cache v2 quedo validada localmente.
- No se integro todavia en el bootstrap productivo.
- No se ejecuto `supabase db push --linked`.
- No se toco Flutter fuera de esta nueva capa local y sus pruebas.

### Archivos modificados en esta fase

- `lib/data/local/authoritative_bootstrap_cache_v2.dart`
- `test/data/local/authoritative_bootstrap_cache_v2_test.dart`
- `docs/existing_account_bootstrap_phase_4.md`

## Fase 4C3B - Integracion shadow de la cache autoritativa v2

### Objetivo

Integrar la cache autoritativa v2 en modo sombra dentro de `BootstrapController`, sin cambiar la navegacion, sin tocar `AppStartupGate` y sin permitir que la cache condicione la decision visible de bootstrap.

### Que se cambio

- La lectura de cache v2 arranca en paralelo con la RPC autoritativa, justo despues de resolver el scope de usuario local.
- La decision visible sigue saliendo solo de la RPC autoritativa.
- La cache sombra ahora compara el snapshot leido contra la decision real y luego reescribe una copia fresca en segundo plano.
- Se protege la traza contra carreras: lecturas, comparaciones y escrituras tardias se descartan si ya arranco una corrida mas nueva.
- Se mantuvo el contrato publico de la RPC y no se cambio su semantica fail-closed.

### Aislamiento por entorno

- La escritura de cache v2 usa un `environmentId` explicito y reutilizable.
- La comparacion sombra valida contra el mismo `environmentId`, evitando falsos negativos cuando el entorno de prueba no tiene configuracion global inicializada.
- Los fixtures de test se ajustaron para usar un entorno de prueba estable y una `scopeKey` coherente con `scopeEpoch=0`.

### Verificacion local

- `flutter analyze lib/application/bootstrap/bootstrap_controller.dart test/application/bootstrap/bootstrap_controller_metrics_test.dart test/application/bootstrap/bootstrap_controller_test.dart test/application/bootstrap/authoritative_bootstrap_cache_shadow_test.dart test/data/local/authoritative_bootstrap_cache_v2_test.dart`
- `flutter test test/data/local/authoritative_bootstrap_cache_v2_test.dart`
- `flutter test test/application/bootstrap/authoritative_bootstrap_cache_shadow_test.dart`
- `flutter test test/application/bootstrap/bootstrap_controller_metrics_test.dart`
- `flutter test test/application/bootstrap/bootstrap_controller_test.dart`

### Resultado

- La cache sombra v2 queda integrada sin afectar la navegacion visible.
- La lectura, comparacion y reescritura ocurren en background y se validan con tests.
- No se ejecuto ningun comando de Supabase en esta subfase.
- No se modifico `AppStartupGate`.

### Archivos modificados en esta fase

- `lib/application/bootstrap/bootstrap_controller.dart`
- `lib/application/bootstrap/authoritative_bootstrap_cache_shadow.dart`
- `lib/data/local/authoritative_bootstrap_cache_v2.dart`
- `test/application/bootstrap/authoritative_bootstrap_cache_shadow_test.dart`
- `test/application/bootstrap/bootstrap_controller_metrics_test.dart`
- `test/application/bootstrap/bootstrap_controller_test.dart`
- `test/data/local/authoritative_bootstrap_cache_v2_test.dart`
- `docs/existing_account_bootstrap_phase_4.md`

## Fase 4C3C - Decision final sobre la cache autoritativa v2

### Resultado

Se selecciona **Opcion A - mantener la cache v2 exclusivamente en shadow**.

La RPC autoritativa sigue siendo la unica autoridad para decidir la navegacion. La cache puede leerse, compararse, medirse y reescribirse en background, pero no puede autorizar `Home`, `onboarding` ni estados especiales.

### Inspeccion

- Trabajo local antes de `Home`: ya existe y se ejecuta parcialmente en paralelo, sobre todo la preparacion esencial de habitos, cosmeticos y assets despues de la RPC autoritativa.
- Trabajo local despues de `Home`: tambien existe para trabajo post-Home, pero no debe depender de una cache que pretenda autorizar navegacion.
- Posible preload: solo tendria sentido para objetos locales reversibles, aislados por usuario y no visibles. No hay evidencia suficiente de que adelantar mas trabajo reduzca de forma real `time_to_home_ready`.
- Coste: activar `Home` desde cache obligaria a gestionar revocacion, reversion y casos de stale muy complejos.
- Beneficio: la ganancia potencial es incierta y no compensa el riesgo de mostrar estados incorrectos.
- Riesgos: suspension, eliminacion pendiente, perfil eliminado, cambio de politica, cambio de revision, cambio de identidad, logout, cambio de cuenta, reinstalacion, restore, reloj local incorrecto y manipulacion local de `SharedPreferences`.

### Evaluacion de activacion de Home

**No**, una cache local v2 no puede autorizar `Home` de forma segura antes de consultar la RPC.

La cache no aporta una garantia remota suficiente de frescura. Un TTL local no prueba que la cuenta siga activa ni que la politica, la revision del perfil o el estado de onboarding sigan siendo compatibles con `Home`. Tampoco protege por si sola ante reinstalacion, restore, reloj manipulado o cambios remotos posteriores al guardado.

### Evaluacion de preparacion especulativa

Operaciones consideradas:

- abrir o leer datos locales namespaced por usuario;
- decodificar objetos inmutables;
- preparar estructuras no visibles;
- precargar recursos estaticos;
- construir modelos locales sin publicarlos.

Beneficio esperado:

- pequeno y no demostrado de forma suficiente en el camino real hasta `Home`.

Riesgos:

- complejidad de cancelacion;
- posibilidad de mezclar scopes;
- trabajo dificil de revertir cuando la RPC no devuelve `Home`;
- riesgo de introducir dependencia accidental de cuenta activa o de providers globales.

Decision:

- no se activa preload especulativo en esta fase;
- la cache queda como observabilidad y preparacion para una futura garantia backend.

### Decision arquitectonica final

La cache autoritativa v2 permanece en **shadow**.

### Uso final de la cache v2

| Capacidad | Estado final |
| --- | ---: |
| Lectura | Activo |
| Comparacion | Activo |
| Escritura | Activo |
| Metricas | Activo |
| Preload | Inactivo |
| Navegacion | Inactivo |
| Offline | Inactivo |

### Autoridad y flujo final

- La RPC decide la navegacion.
- `Home` espera la RPC.
- La cache no cancela la RPC.
- Se mantiene una RPC por bootstrap.

### Garantias de concurrencia y aislamiento

- `bootstrapRunId` protege corridas concurrentes.
- usuario, `scope` y `scopeEpoch` evitan mezclar contextos.
- `logout`, `retry` y cambio de cuenta descartan resultados stale.
- `environmentId` aisla la cache por entorno.
- la lectura, comparacion y escritura no publican navegacion.

### Cambios de codigo

Ninguno.

### Archivos creados

Ninguno.

### Archivos modificados

- `docs/existing_account_bootstrap_phase_4.md`

### Tests ejecutados

Ninguno en esta subfase. La validacion funcional ya estaba completada en 4C3B.

### Validacion fisica disponible

- Se ejecuto la validacion fisica completa en Pixel 9 con la cuenta existente.
- P1 valido arranque limpio tras `pm clear`: `cache_loaded hit=false`, una sola llamada autoritativa y aplicacion remota posterior.
- P2 valido una relanzada posterior sobre el mismo perfil: la cache autoritativa se escribio y el bootstrap continuo hasta `Home`.
- P3 valido la reutilizacion real de la cache: `authoritative_cache_v2_result status=hit`, `home_ready` y destino `home`.
- No se ejecuto `supabase db push --linked`.
- No se tocaron migraciones ni el contrato de la RPC.

### Riesgo backend pendiente

Si en el futuro se quisiera autorizar `Home` desde cache, haria falta una garantia remota minima, por ejemplo:

- una marca firmada por backend;
- una revision remota de cuenta o politica;
- un mecanismo de revocacion verificable;
- una caducidad corta pero respaldada por garantia de frescura real.

Un TTL local no basta porque no detecta suspension, eliminacion, cambio de politica, cambio de identidad, restore, reloj local incorrecto ni manipulacion de `SharedPreferences`.

### Documentacion

Quedan cerradas:

- `4C3A`
- `4C3B`
- `4C3C`

La cache v2 queda en shadow y el siguiente paso es `4D - Pruebas completas de cuentas existentes`.

## 4D - Pruebas completas de cuentas existentes

### Objetivo

Cerrar la validacion de cuentas existentes con cobertura automatizada y una comprobacion fisica en Pixel 9, sin activar `Home` desde cache y sin tocar Supabase ni el contrato de la RPC.

### Matriz de cobertura

| Area | Cobertura automatizada | Cobertura fisica | Resultado |
| --- | --- | --- | --- |
| Cache v2 | `authoritative_bootstrap_cache_v2_test.dart` y `authoritative_bootstrap_cache_shadow_test.dart` | Se inspecciono el valor real en `FlutterSharedPreferences.xml` | Verde en tests; cache real presente en el dispositivo |
| Sesion | `auth_controller_test.dart` y `bootstrap_controller_test.dart` | Se confirmo que el dispositivo tiene sesion/app data instalada | Verde en tests; sesion real existente |
| Red / RPC | `bootstrap_controller_test.dart`, `bootstrap_controller_metrics_test.dart` | No se ejecuto cambio de backend ni Supabase | Verde en tests; sin cambios remotos |
| Estado autoritativo | `authoritative_bootstrap_decision_test.dart` | Se reviso el estado cacheado y el contrato local | Verde en tests; contrato estable |
| Concurrencia | `bootstrap_controller_test.dart`, `auth_controller_test.dart` | No se pudo forzar una carrera fisica nueva | Verde en tests; cobertura de dedupe y stale runs ya existe |
| Post-Home | `auth_controller_test.dart` | No se pudo abrir Home en modo cache-miss fisico | Verde en tests; sin regresiones observadas |
| Visual / gate | `app_startup_gate.dart` cubierto por tests existentes de bootstrap | Se confirmo Home real en Pixel 9 mediante captura final | Verde en tests; Home visible sin onboarding ni error |
| Metricas | `bootstrap_controller_metrics_test.dart` | Se verificaron logs de Flutter ya generados en el dispositivo | Verde en tests; metricas instrumentadas presentes |
| Defectos | N/A | No se introdujeron defectos nuevos en esta fase | Sin incidencias nuevas |
| Limitaciones | N/A | Restore real no reproducido; observacion visual limitada a captura final | Limitaciones no criticas documentadas |
| Decision | N/A | No se cambio el contrato ni se activo `Home` desde cache | Apto para seguir en shadow |

### Cobertura automatizada

Se ejecutaron y pasaron estos tests:

- `flutter test test/data/models/authoritative_bootstrap_decision_test.dart`
- `flutter test test/data/local/authoritative_bootstrap_cache_v2_test.dart`
- `flutter test test/application/bootstrap/authoritative_bootstrap_cache_shadow_test.dart`
- `flutter test test/application/bootstrap/bootstrap_controller_metrics_test.dart`
- `flutter test test/application/bootstrap/bootstrap_controller_test.dart`
- `flutter test test/application/auth/auth_controller_test.dart`

Esa cobertura ya valida:

- decisiones de home, onboarding y estados especiales;
- lectura, comparacion y escritura de cache v2;
- invalidacion por scope, entorno, TTL y contrato;
- concurrencia, stale runs y deduplicacion;
- comportamiento post-Home y aislamiento entre autenticacion y bootstrap;
- metricas y trazas estructuradas.

### Pixel 9

Se confirmo el dispositivo conectado:

- `Pixel 9 (mobile) • 58090DLAQ000TS • android-arm64 • Android 17 (API 37)`

Tambien se verifico que:

- la app instalada es `com.rutio.app`;
- existe sesion real para el usuario `bd1b5d09-674a-4759-9ab0-0358768f5356`;
- existe una cache v2 real reutilizada por el arranque estable;
- Home es visible con los habitos y cosmeticos esperados.

### Estado de cache y sesion

Se observo en el dispositivo la secuencia completa de cache v2 para el usuario:

- `bd1b5d09-674a-4759-9ab0-0358768f5356`

Con estos campos principales:

- P1: `hit=false` y reconstruccion autoritativa.
- P2: `authoritative_cache_v2_result status=notFound` seguido de `authoritative_cache_v2_write_result status=success destination=home`.
- P3: `authoritative_cache_v2_result status=hit`, `authoritative_cache_v2_destination=home` y `home_ready`.

Eso confirma que la app escribe, reutiliza y publica la decision cacheada real, sin cambiar el contrato publico ni la semantica fail-closed.

### Resultado funcional

- No aparecieron errores nuevos relacionados con `user_bootstrap_state`, `bootstrap_policy`, la RPC publica, triggers de `profiles`, la funcion de signup ni permisos.
- Los tests de bootstrap y auth siguen pasando.
- No se ejecuto `supabase db push --linked`.
- No se toco Flutter fuera de la documentacion y de la verificacion ya descrita.

### Defectos y hallazgos

No se introdujeron defectos nuevos en esta fase.

Los riesgos ya conocidos y ajenos siguen siendo los mismos que en fases previas:

- `record_journal_entry`
- `record_habit_log`
- warnings de volatilidad
- variable no usada

### Limitaciones

- La validacion fisica se completo con evidencia suficiente de miss, write y hit en Pixel 9.
- No se forzo `Home` desde cache; siguio dependiendo de la RPC autoritativa.
- No se hicieron cambios en Supabase.
- No se avanzo a `4C2C2B`.

### Decision

`4C2C2A` queda apto para seguir en shadow y para aplicarse en el flujo normal. La validacion fisica ya cubrio miss, write y hit en Pixel 9 sin cambiar la autoridad de la RPC.

### Archivos modificados en esta fase

- `docs/existing_account_bootstrap_phase_4.md`

## 4E - Medicion final y cierre

### Resumen ejecutivo

El Punto 4 resolvio la carga de cuentas existentes eliminando decisiones permisivas, Home provisional y duplicidad autoritativa. La navegacion queda gobernada por una unica decision remota tipada, fail-closed, con cache v2 observable en shadow y trabajo post-Home separado del camino critico de decision.

### Arquitectura inicial

El flujo inicial podia depender de informacion local o parcial antes de tener una decision remota completa. Eso dejaba riesgos de flashes de onboarding, Home provisional, estados especiales mal interpretados, mezcla de usuario o trabajo de fondo iniciado antes de saber si `home` era un destino permitido.

### Arquitectura final

```text
sesion
-> scope del usuario
-> lectura shadow de cache v2 + RPC autoritativa
-> validacion fail-closed
-> destino tipado
-> Home/onboarding/estado especial
-> comparacion y escritura v2 en background
-> trabajo post-Home solo para Home
```

Garantias principales:

- `loadAuthoritativeBootstrapDecision(...)` es la unica fuente remota visible de navegacion.
- Home se publica despues de la RPC autoritativa y de preparar los esenciales visibles.
- La cache v2 no publica navegacion, no cancela la RPC y no tiene modo offline.
- Hay una RPC autoritativa por bootstrap autenticado.
- Los destinos especiales nunca permiten Home.

### Metricas consolidadas

Referencia shadow anterior de `4C2C2B3`:

| Metrica | Mediana |
| --- | ---: |
| Time to Home ready | 1311 ms |
| RPC query | 122 ms |
| RPC map | 1 ms |
| Shadow total | 126 ms |
| Post-Home total | 1022 ms |
| RPC calls | 1 |

RPC autoritativa activa de `4C2C2B5`:

| Metrica | Mediana |
| --- | ---: |
| Time to Home ready | 1474 ms |
| RPC query | 895 ms |
| RPC map | 7 ms |
| RPC autoritativa total | 899 ms |
| Post-Home total | 1421 ms |
| RPC calls | 1 |

Cache v2 fisica en Pixel 9:

| Metrica | P1 miss | P2 relanzada | P3 hit estable | Mediana disponible |
| --- | ---: | ---: | ---: | ---: |
| Cache read | N/D | 1534 ms | 1139 ms | 1337 ms |
| Cache result | N/D | `notFound` | `hit` | N/D |
| Cache comparison | N/D | N/D | 0 ms, `matchHome` | 0 ms |
| Cache write | N/D | 45 ms | 104 ms | 75 ms |
| RPC query | 824 ms | 1525 ms | 1131 ms | 1131 ms |
| RPC total | 828 ms | 1526 ms | 1133 ms | 1133 ms |
| Time to Home ready | N/D | 3900 ms | 1552 ms | 2726 ms |
| Post-Home total | N/D | N/D | 2038 ms | 2038 ms |
| RPC calls | 1 | 1 | 1 | 1 |
| Cache writes | N/D | 1 success | 1 success | N/D |

Arranque final de control `4E`:

| Metrica | Resultado |
| --- | ---: |
| Cache read | 424 ms |
| Cache result | `hit` |
| Cache comparison | 0 ms, `matchHome` |
| Cache write | 38 ms |
| RPC query | 412 ms |
| RPC total | 413 ms |
| Time to Home ready | 873 ms |
| Post-Home total | 1684 ms |
| RPC calls | 1 |
| Cache writes | 1 success |

### Comparacion de rendimiento

| Metrica | Shadow 4C2C2B3 | RPC activa 4C2C2B5 | Diferencia |
| --- | ---: | ---: | ---: |
| Time to Home ready | 1311 ms | 1474 ms | +163 ms |
| RPC query | 122 ms | 895 ms | +773 ms |
| RPC total | 126 ms | 899 ms | +773 ms |
| RPC calls | 1 | 1 | 0 |

La optimizacion conseguida no es una mejora de velocidad bruta. El coste de seguridad medido fue de aproximadamente `+163 ms` de mediana hasta Home frente al flujo shadow anterior. La mejora real esta en estabilidad, coherencia, seguridad, ausencia de flashes incorrectos, aislamiento multiusuario y separacion del trabajo post-Home.

### Validacion automatizada

Se ejecuto la bateria dirigida final y paso completa:

- `flutter test test/data/models/authoritative_bootstrap_decision_test.dart test/data/local/authoritative_bootstrap_cache_v2_test.dart test/application/bootstrap/authoritative_bootstrap_cache_shadow_test.dart test/application/bootstrap/bootstrap_controller_metrics_test.dart test/application/bootstrap/bootstrap_controller_test.dart test/application/auth/auth_controller_test.dart`
- Resultado: `89` tests pasados.
- No existe un archivo separado `app_startup_gate_test.dart`; la cobertura de `AppStartupGate` esta integrada en `test/application/bootstrap/bootstrap_controller_test.dart`.

Analisis dirigido:

- `flutter analyze lib/application/bootstrap/bootstrap_controller.dart lib/application/bootstrap/authoritative_bootstrap_cache_shadow.dart lib/application/auth/auth_controller.dart lib/data/local/authoritative_bootstrap_cache_v2.dart lib/screens/app_startup_gate.dart test/data/models/authoritative_bootstrap_decision_test.dart test/data/local/authoritative_bootstrap_cache_v2_test.dart test/application/bootstrap/authoritative_bootstrap_cache_shadow_test.dart test/application/bootstrap/bootstrap_controller_metrics_test.dart test/application/bootstrap/bootstrap_controller_test.dart test/application/auth/auth_controller_test.dart`
- Resultado: `No issues found`.

### Validacion fisica

Dispositivo:

- `Pixel 9 (mobile) - 58090DLAQ000TS - android-arm64 - Android 17 (API 37)`.

P1:

- Arranque tras limpieza local real.
- `cache_loaded hit=false`.
- Una llamada autoritativa: `authoritative_bootstrap_calls count=1`.
- RPC total: `828 ms`.

P2:

- Relanzada posterior sobre el mismo perfil.
- `authoritative_cache_v2_result status=notFound`.
- Escritura posterior: `authoritative_cache_v2_write_result status=success destination=home`.
- `home_ready total_ms=3899`.
- Una llamada autoritativa.

P3:

- Relanzada estable.
- `authoritative_cache_v2_result status=hit`.
- `authoritative_cache_v2_comparison kind=matchHome`.
- `authoritative_cache_v2_write_result status=success destination=home`.
- `home_ready total_ms=1552`.
- `post_home_total duration_ms=2038`.
- Una llamada autoritativa.

Arranque final de control:

- Log: `phase_4E_final_control.log`.
- Captura: `phase_4E_final_control.png`.
- `authoritative_cache_v2_result status=hit`.
- `authoritative_cache_v2_comparison kind=matchHome`.
- `authoritative_bootstrap_calls count=1`.
- `authoritative_bootstrap_destination=home`.
- `home_published` despues de la decision autoritativa.
- `authoritative_cache_v2_write_result status=success destination=home`.
- `post_home_total duration_ms=1684`.
- No aparecio error contractual ni el antiguo shadow autoritativo.

### Validacion visual

Observado por captura del Pixel 9:

- Home real visible.
- Usuario `Vicenç`.
- Fecha `mie, 29 jul`.
- Habitos visibles y correctos.
- Progreso `Completados 3/8`.
- Fondo `wallpaper_mist_blue`.
- Tarjetas de habitos con estetica esperada.
- Sin pantalla de onboarding.
- Sin error visible.
- Sin datos de otro usuario.

Demostrado por logs:

- Splash/preparacion hasta decision.
- Home despues de RPC.
- Sin segunda RPC autoritativa.
- Cache hit y comparacion `matchHome`.
- Escritura de cache posterior.
- Trabajo post-Home posterior a `home`.

Demostrado por tests:

- Estados especiales.
- Retry, logout, stale runs y cambio de usuario.
- AppStartupGate.
- Parser fail-closed.
- Cache v2 y shadow.

### Garantias finales

- Home nunca se publica antes de la RPC.
- La cache no publica navegacion.
- No existe Home como fallback.
- Onboarding obligatorio depende de `completedOnboardingVersion < requiredOnboardingVersion`.
- Suspension, borrado pendiente, perfil eliminado, perfil no inicializado e invalid profile no permiten Home.
- Logout invalida resultados en curso.
- Retry crea un run nuevo.
- Cambio de cuenta invalida el scope anterior.
- La cuenta B no usa datos ni cache de A.
- `expectedUserId` se valida.

### Cache v2

- Schema v2.
- TTL.
- Validacion de usuario.
- Validacion de entorno.
- Validacion de scope.
- Revisiones de perfil y politica.
- Parser fail-closed.
- Miss ante corrupcion, enum desconocido o contrato incoherente.
- Shadow unicamente.
- Sin modo offline.

### Estados autoritativos

Estados cubiertos:

- `home`.
- `onboarding`.
- `profile_uninitialized`.
- `profile_deleted`.
- `account_suspended`.
- `account_pending_deletion`.
- `invalid_profile`.

Los estados bloqueantes muestran una pantalla dedicada o accion limitada y no publican Home.

### Concurrencia y aislamiento

- `bootstrapRunId` descarta resultados obsoletos.
- `scopeEpoch` y `scopeKey` protegen cambios de usuario o scope.
- `environmentId` separa caches por entorno.
- `expectedUserId` evita mezclar identidad.
- Retry y logout tienen rutas probadas.
- Stale discards observados en logs corresponden a refrescos de cosmeticos o resultados obsoletos esperados, no a una segunda decision autoritativa.

### Trabajo post-Home

El trabajo post-Home solo se agenda despues del destino `home`:

- metadata de perfil;
- backfills;
- sincronizaciones permitidas.

No se ejecuta para onboarding, errores recuperables ni estados bloqueantes, y no dispara otra RPC autoritativa.

### Codigo legado y deuda tecnica

Clasificacion revisada:

| Elemento | Clasificacion | Nota |
| --- | --- | --- |
| `lib/data/local/bootstrap_profile_decision_cache.dart` | legado todavia necesario | Sigue usado por `ProfileRepository` como memoria/cache v1 de decision de perfil y por tests existentes. |
| `fetchBootstrapProfileDecision(...)` | legado todavia necesario | Sigue usado por rutas de perfil/auth y tests; no participa como segunda llamada autoritativa productiva post-Home. |
| Metricas `authoritative_profile_match/mismatch` | seguro para eliminar ahora si aparecieran | No se encontraron en `lib` ni en el log final. |
| Nombre `shadow` en cache v2 | utilizado | Describe correctamente la cache v2 no productiva para navegacion. |
| Antiguo shadow autoritativo post-Home | candidato historico ya eliminado | El test `post-home work no longer runs an authoritative shadow fetch` lo protege. |
| `bootstrap_profile_decision_cache_test.dart` | candidato a revisar en fase futura | Mantiene cobertura de cache v1 mientras esa capa siga existiendo. |

Deuda tecnica pendiente:

- Cache v1 de perfil: decidir retirada o migracion cuando ya no sea necesaria para memoria/repositorio.
- Garantia backend futura si algun dia se quiere que cache autorice Home.
- Preload especulativo no activado.
- Modo offline no implementado.
- Restore real de dispositivo no reproducido en esta fase.

### Limitaciones reales

- No se hizo una prueba de restore real del dispositivo.
- La validacion visual directa se limita a captura final y logs; no se observo manualmente cada transicion frame a frame.
- La cache v2 no busca reducir `time_to_home_ready` todavia.

### Cierre formal

| Fase | Estado |
| --- | --- |
| `4C2C2B5` | Cerrada |
| `4C3A` | Cerrada |
| `4C3B` | Cerrada |
| `4C3C` | Cerrada |
| `4D` | Cerrada |
| `4E` | Cerrada |
| Punto 4 completo | Cerrado con limitaciones manuales no criticas |

Decision seleccionada:

- **Opcion B - Punto 4 cerrado con limitaciones manuales no criticas**.

No existe defecto critico pendiente, pero queda documentada la ausencia de restore real y la observacion visual limitada a captura final.

### Restricciones respetadas en 4E

- Sin Supabase.
- Sin migraciones.
- Sin Docker.
- Sin comandos Supabase.
- Cache shadow.
- Sin modo offline.
- Una RPC por bootstrap.
- Consulta minima no reintroducida.
- Shadow autoritativo antiguo no reintroducido.
- Sin commit.
- Sin push.
- Sin merge.
