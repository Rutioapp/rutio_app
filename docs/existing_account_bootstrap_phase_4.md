# Existing Account Bootstrap Phase 4A

## Objetivo

Medir el arranque de cuentas existentes sin introducir optimizaciones amplias todavia. Esta fase deja una linea base trazable para distinguir cache valida, carga remota completa, degradado recuperable, retries y resultados obsoletos.

## Estado inicial tras la Fase 3

- `BootstrapController` ya resolvia sesion, scope local, estado local, perfil remoto, esenciales de habitos, esenciales de cosmeticos y precarga de assets visibles.
- Habitos y cosmeticos ya se lanzaban en paralelo con `Future.wait`.
- El cold start ya mantenia `SplashScreen` y el in-app bootstrap ya usaba `BootstrapPreparationScreen`.
- El codigo ya tenia trazas funcionales, pero no una instrumentacion estructurada por run con metricas agregadas ni timeline verificable.

## Metricas añadidas

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

Tambien se añadio un sink inyectable de logs para tests, de forma que la instrumentacion se valida sin depender de `debugPrint` global.

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

La fase actual no añade delays ni cambia decisiones funcionales del bootstrap.

## Riesgos

- El contador `remote_queries` es exacto en perfil y en la mayor parte de habitos/cosmeticos, pero el cierre remoto de missed occurrences sigue siendo variable por numero de ocurrencias y merece medicion productiva real.
- El path de habitos continua acoplando logs y streak protection al readiness de Home.
- La duplicidad perfil bootstrap vs auth sync puede distorsionar percepcion de “arranque completo” aunque Home ya este lista.
- El refresh de cosmeticos post-cache puede enmascarar duplicidad como “background work” y consumir red en cada cold start cacheado.

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
