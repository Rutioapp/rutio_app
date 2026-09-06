# Onboarding V1 — Fase 0: auditoría técnica y baseline

**Fecha de auditoría:** 2026-09-06  
**Alcance:** repositorio Flutter actual y SQL versionado en `supabase/`; no se consultó ni modificó un proyecto Supabase remoto.  
**Regla de esta fase:** este documento es el único entregable. No se implementa Onboarding V1, no se crean migraciones y no se cambia producción.

## 1. Executive summary

La aplicación ya tiene una base sólida para el arranque autenticado: `AppStartupGate` delega la decisión a `BootstrapController`, el perfil remoto tiene estado de onboarding (`pending`, `in_progress`, `completed`) y Supabase expone una decisión autoritativa mediante `get_current_user_bootstrap_decision()`.

La base no está preparada todavía para el contrato completo de Onboarding V1:

- El onboarding visible actual es `TemporaryOnboardingScreen`, un placeholder de tres textos hardcoded.
- El estado anónimo actual se reduce a `UserStateStore.meta.onboardingDone`; no existe un `HabitDraft` versionado, con paso actual, objetivos, ritmo, recomendación y reanudación.
- El modelo remoto ya soporta un hábito real y horarios canónicos, pero la creación actual usa IDs locales `custom_<timestamp>` o IDs de catálogo y sincronización best-effort. No hay `operationId` ni una operación de completion transaccional de onboarding.
- Email/password funciona; Google, Apple, recuperación, deep links, confirmación completa y resolución de conflictos de proveedor no están implementados en el cliente inspeccionado.
- Notificaciones tienen una infraestructura reutilizable y robusta, pero deben activarse solo después de disponer de un ID canónico de hábito; la creación actual notifica antes de que termine la asignación del remoto.
- ES/EN existe en ARB y en `AppLocalizations`; quedan pantallas del bootstrap y el placeholder con strings hardcoded.
- No se encontró proveedor de analytics de producto ni adaptador de eventos en `lib/` o `pubspec.yaml`.

Conclusión: V1 puede arrancar sin una migración para el borrador anónimo si se mantiene local, pero requiere una adaptación coordinada de bootstrap/auth/profile/habits/notifications y una política explícita para la finalización idempotente. Si objetivos, ritmo, recomendaciones o `operationId` deben persistir en servidor, hará falta una decisión de esquema antes de cerrar la implementación.

## 2. Current bootstrap and session flow

### Hechos observados

`lib/main.dart` hace, en orden:

1. Inicializa bindings Flutter y handlers de interacción de notificaciones.
2. Valida la configuración de shop y carga `RutioSupabaseClient.initialize()`.
3. Crea `SharedPreferences`, `UserStateStorage` y repositorios de estado.
4. Ejecuta `DemoSeedRunner.prepare()`.
5. Inicializa `NotificationService`; un fallo se registra y no impide arrancar.
6. Construye `Provider`s para estado, auth, perfiles, bootstrap, wallet, shop y notificaciones.
7. Monta `MaterialApp` con `home: AppStartupGate()`.

`AppStartupGate` mantiene un splash de cold start de al menos dos segundos y consume `BootstrapController`. El controlador:

- resuelve primero la sesión auth;
- cambia el scope local a `user.id` antes de cargar estado;
- valida que resultados async siguen perteneciendo al mismo `runId`, usuario y scope;
- para usuario autenticado consulta la decisión autoritativa de bootstrap;
- para usuario anónimo usa el estado local y decide `Welcome` o `Authentication`;
- para cuentas listas prepara hábitos/cosméticos y publica Home;
- para onboarding pendiente publica la ruta de onboarding;
- ante estados especiales o inconsistencias falla cerrado con `BootstrapAuthorityStateScreen`.

### Flujo actual resumido

`main.dart` → `AppStartupGate` → `BootstrapController` → sesión Supabase → scope `UserStateStore` → decisión RPC/perfil → `Welcome`, auth, placeholder onboarding o `HomeScreen`.

### Implicación para V1

El punto correcto de integración es `BootstrapController`/`AppStartupGate`, no una segunda decisión de navegación dentro de una pantalla. La pantalla V1 debe poder devolver un resultado de completion al controlador sin duplicar la autoridad remota.

## 3. Current onboarding flow

El flujo visible vigente no es el de la especificación:

- `WelcomeScreen` muestra bienvenida y ofrece login/signup. `completeWelcomeAndGo()` escribe `meta.onboardingDone = true` y navega a auth.
- `SignInScreen` solo ofrece email/password y, tras autenticar, navega a `/root`; el bootstrap vuelve a decidir según el perfil remoto.
- `SignUpScreen` ofrece nombre, email y contraseña. Guarda `displayName` localmente después del registro y navega a `/root`.
- `TemporaryOnboardingScreen` muestra “Tu espacio está listo”, explica que el onboarding personalizado se añadirá próximamente y llama a `BootstrapController.completeTemporaryOnboarding()`.
- La completion temporal ejecuta `ProfileRepository.markOnboardingCompleted()` y, si la respuesta es válida, publica Home.

No existe actualmente la secuencia Welcome → nombre → objetivos → ritmo → recomendaciones → hábito → recordatorio → preview → auth → resolución de cuenta → completion idempotente.

La especificación V1 exige que el borrador anónimo sobreviva a cierre, offline, error de auth y reintentos. La implementación actual no cubre ese contrato: solo persiste un flag de onboarding ya iniciado/terminado, no los datos de la sesión de onboarding.

## 4. Current onboarding inventory

| Path | Symbol | Current responsibility | KEEP/ADAPT/REMOVE LATER | Reason |
|---|---|---|---|---|
| `lib/screens/welcome_screen.dart` | `WelcomeScreen`, `completeWelcomeAndGo` | Entrada pública y transición a auth | ADAPT | Debe abrir el nuevo flujo y dejar de marcar completion antes de auth. |
| `lib/screens/welcome/widgets/welcome_content.dart` | `WelcomeContent` | Copy y acciones de bienvenida | KEEP/ADAPT | Reutilizable, pero el contrato de navegación cambia. |
| `lib/screens/onboarding/temporary_onboarding_screen.dart` | `TemporaryOnboardingScreen` | Placeholder y completion temporal | REMOVE LATER | Es deuda explícita; mantener solo mientras exista una transición controlada. |
| `lib/application/bootstrap/bootstrap_controller.dart` | `BootstrapController` | Sesión, scope, decisión remota y Home | ADAPT | Es la autoridad de destino actual; V1 debe conectarse aquí. |
| `lib/screens/app_startup_gate.dart` | `AppStartupGate` | Splash, preparación y destino | ADAPT | Debe dirigir al nuevo flujo y conservar fail-closed. |
| `lib/data/repositories/auth_repository.dart` | `AuthRepository` | Supabase email/password y stream de sesión | KEEP/ADAPT | Es la base auth a reutilizar; faltan providers y recuperación. |
| `lib/application/auth/auth_controller.dart` | `AuthController` | Auth lifecycle, scope y errores | ADAPT | Debe aceptar completion post-auth y estados de confirmación. |
| `lib/data/repositories/profile_repository.dart` | `ProfileRepository` | Perfil, idioma, settings y estado onboarding | KEEP/ADAPT | Debe evitar sobrescribir datos existentes y soportar la política V1. |
| `lib/data/models/remote/remote_profile.dart` | `RemoteProfile` | DTO y validación de bootstrap | KEEP/ADAPT | Reutilizar identidad/estado; evaluar campos V1 persistentes. |
| `lib/stores/user_state_store.dart` / `user_state_store_core.dart` | `onboardingDone`, scopes | Estado local legacy y datos de usuario | ADAPT | No usar `onboardingDone` como borrador; conservar compatibilidad. |
| `lib/services/session_service.dart` | `SessionService` | Auth local legacy `local_user_v1` | REMOVE LATER | No forma parte del flujo Supabase actual; retirar tras auditar consumidores. |
| `lib/screens/auth/auth_gate.dart` | `AuthGate` | Gate legacy/backcompat | KEEP TEMPORARILY | Evita romper rutas antiguas; no debe ser nueva autoridad. |
| `lib/screens/auth/auth_screen.dart` | `AuthScreen` | Wrapper de compatibilidad | KEEP TEMPORARILY | Mantener mientras haya deep links/rutas antiguas. |
| `lib/stores/user_state_store_habits.dart` | `addHabitFromCatalog`, `addCustomHabit` | Materializa el hábito local y dispara sync | ADAPT | Puede ser la salida final de `HabitDraft`, pero necesita ID/operación seguros. |
| `lib/data/services/habit_sync_service.dart` | `HabitSyncService` | Sync best-effort local→Supabase | ADAPT | No sirve por sí solo como completion transaccional/idempotente. |
| `lib/data/repositories/habit_repository.dart` | `HabitRepository` | CRUD de `public.habits` | KEEP/ADAPT | Reutilizar RLS, DTO y schedule; añadir operación específica si procede. |
| `lib/features/notifications/application/notification_permission_controller.dart` | permission flow | Solicitud no bloqueante | KEEP/ADAPT | Reutilizable para el paso Reminder. |
| `lib/features/notifications/application/personalized_notification_orchestrator.dart` | orchestrator | Manifest, reconciliación y scope | KEEP/ADAPT | Reutilizar después de tener ID canónico. |
| `lib/widgets/home/add_habit/home_add_habit_sheet.dart` | catalog UI | Catálogo local y configuración | KEEP/ADAPT | Puede compartir loader/modelos; V1 necesita resolución remota/cache/bundled. |
| `lib/screens/home/home_screen.dart` y `lib/screens/home/state/home_state.dart` | `HomeScreen` | Lista, acciones, scroll y refresh | KEEP/ADAPT | Es destino final; no tiene checklist V1 ni highlight específico hoy. |
| `lib/screens/shop_screen.dart` / `features/shop` | `ShopScreen`, controllers | Shop/cosméticos y estado scoped | KEEP | No forma parte del onboarding; bootstrap ya prepara cosméticos. |

## 5. Authentication architecture

La autenticación real es Supabase Auth, con el `User.id` UUID como identidad canónica. `AuthRepository` encapsula:

- `authStateChanges`/`onAuthStateChange`;
- `currentUser`;
- `signUpWithEmailPassword`, pasando `display_name` en metadata;
- `signInWithEmailPassword`;
- `signOut`.

`AuthController` escucha el stream, evita aplicar eventos stale y coordina logout con scopes locales, wallet, caches de perfil y notificaciones. Tras signup intenta asegurar el perfil mediante `ProfileRepository.upsertCurrentProfile()`.

La UI actual no tiene Google, Apple, recuperación de contraseña, resend de email, deep-link de confirmación ni recuperación de sesión desde un callback OAuth. Tampoco se encontró lógica para account linking, provider conflict o Apple Private Relay.

El signup contempla `user != null` sin sesión y muestra aviso de confirmación por email, pero no existe el ciclo completo de “email pendiente → abrir enlace → reanudar draft → completar”.

## 6. Profile/user state architecture

### Remoto

`RemoteProfile` modela identidad, `onboardingStatus`, `onboardingVersion`, `onboardingCompletedAt`, nombre/email/avatar, idioma, `pillarHabitIds`, settings de notificaciones, horas y timestamps. La lectura del bootstrap usa un RPC autoritativo y cache versionada por usuario, epoch, generación de sesión y policy version.

`ProfileRepository` protege el scope, valida el `id` devuelto y hace upsert solo cuando falta el perfil en `ensureCurrentProfile()`. Las mutaciones de onboarding respetan las transiciones del servidor y no permiten cambiar arbitrariamente la versión.

### Local

`UserStateStore` contiene el estado completo serializado bajo SharedPreferences. El almacenamiento puede ser guest/legacy o scoped por usuario (`user_state_v1_<userId>`). `switchLocalScope()` limpia el estado en memoria al cambiar de usuario y usa un `scopeEpoch` para descartar resultados stale.

`meta.onboardingDone` es un marcador booleano legacy. `hasSession` depende de él, lo cual no representa una sesión V1 anónima reanudable. No se encontró almacenamiento específico, versionado y validado de draft.

Recomendación: introducir un store separado para `OnboardingDraft`, scoped por instalación mientras sea anónimo y con política explícita al enlazarlo a un usuario. No mezclarlo con el JSON completo de hábitos ni usar `onboardingDone` como fuente de verdad.

## 7. Habit creation architecture

El hábito real actual se representa de dos formas compatibles:

- mapa local en `UserStateStore.userState.activeHabits`;
- `RemoteHabit` en `lib/data/models/remote/remote_habit.dart`.

El DTO remoto cubre `id`, `user_id`, `name`, `family_id`, `emoji`, `habit_type`, `target_count`, `unit`, `color_id`, reminder, `schedule`, archive/order, timestamps y campos de reporte (`source_mutation_id`, `effective_from`, `effective_timezone_name`).

`UserStateStore.addHabitFromCatalog()` materializa un mapa local, guarda estado, emite el observer y lanza `HabitSyncService.syncHabitCreated()`. `addCustomHabit()` sigue una ruta equivalente. La pantalla actual de creación usa `custom_<milliseconds>`; el catálogo conserva IDs de definición, no una clave de operación.

`HabitSyncService` hace upsert remoto best-effort, recuerda IDs remotos solo en memoria y hace backfill por fingerprint. Ese fingerprint no incluye schedule y puede confundir hábitos duplicados. Un insert concurrente o un retry sin ID remoto puede duplicar el hábito.

Para V1, `HabitDraft` debe transformarse en un único hábito real con un UUID generado antes de cualquier side effect, conservar ese ID en draft y enviarlo a una operación de completion. La API pública actual puede reutilizarse solo si el retry y la asociación con el completion quedan resueltos.

## 8. Schedule model

El modelo canónico compartido por Flutter y SQL es JSONB con estos tipos:

- `daily`: `{ "type": "daily" }`;
- `weekly`: `{ "type": "weekly", "weekdays": [1..7] }`;
- `once`: `{ "type": "once", "date": "YYYY-MM-DD" }`;
- `timesPerWeek`: `{ "type": "timesPerWeek", "timesPerWeek": n, "weekStartsOn": 1..7 }`.

`HabitScheduleNormalizer` y `HabitSnapshot` validan/normalizan estos valores. El servidor tiene validación y `schedule not null`; `weekly` exige días, `once` exige fecha ISO y `timesPerWeek` exige cuota positiva. La semántica de cuota semanal usa lunes como default.

V1 debe elegir un schedule concreto en el paso de hábito/reminder y no inventar un formato paralelo. La principal incompatibilidad actual es la creación de `count`: ciertas rutas degradan `timesPerWeek` a daily. Esto debe cubrirse antes de permitir ese caso en recomendaciones.

## 9. Notification architecture

La infraestructura existe y debe aprovecharse:

- `NotificationPermissionService` conoce estados iOS/Android y `ensurePermission`;
- `NotificationPermissionController` permite soft decline y recovery;
- `NotificationScheduler` agenda/cancela notificaciones diarias, one-shot y zoned;
- `NotificationService` sincroniza notificaciones de fase 1 y reminders de hábitos;
- `NotificationRuntime` reacciona a lifecycle/store changes;
- `PersonalizedNotificationOrchestrator` mantiene manifest, IDs de plataforma, historial y scope por instalación/usuario/epoch/locale.

El permission prompt puede ser no bloqueante, que coincide con V1. El riesgo está en el timing: el observer de creación de hábitos puede dispararse con un ID local antes de tener el UUID remoto. V1 debe programar después de la confirmación de la operación o soportar un remap explícito y una reconciliación segura. Nunca debe bloquear la creación del hábito por una denegación de permisos.

## 10. Local persistence architecture

La persistencia disponible es SharedPreferences. `UserStateStorage` serializa JSON y permite scope guest o user; `UserStateRepository` coordina load/save. Hay stores adicionales para caches de perfil, notificaciones, shop, recompensas y catálogo de frases.

No hay `flutter_secure_storage` en `pubspec.yaml`. SharedPreferences sirve para un draft no secreto, pero no para contraseñas, tokens ni datos que deban considerarse secretos. `SessionService` conserva una key legacy `local_user_v1` y limpia algunas keys antiguas.

Capacidad actual para V1:

- cierre de app: posible si se crea un store específico;
- offline: posible para el draft y catálogo bundled;
- reanudación por paso: no existe;
- restart explícito: no existe política ni UI;
- logout/otro usuario: scope seguro para estado de usuario, pero el destino del draft anónimo todavía no está definido;
- migración de draft a cuenta: no existe.

## 11. Home/checklist/shop integration points

`BootstrapController` prepara hábitos y cosméticos antes de publicar Home. `HomeScreen` consume el estado scoped, muestra hábitos por fecha/schedule, permite completion, skip, edición y borrado, y ya tiene `ScrollController` y lógica de refresh.

No se encontró un componente de onboarding checklist V1, estado persistente de checklist, barra de progreso de siete días, ni una API específica de highlight/scroll a un hábito recién creado. Existen `GlobalKey` y scroll en Home/add-habit para familias y refresh, pero no un contrato de “focus first habit”.

La integración mínima recomendada es una señal one-shot de destino Home con `firstHabitId` y checklist derivado localmente, consumida por Home sin introducir una segunda fuente de hábitos. El checklist debe ser una capa de UI/estado de onboarding, no una mutación artificial del historial del hábito.

Shop: `ShopScreen` es wrapper legacy sobre `ShopFlowScreen`; `ShopController`, `ShopCosmeticsController`, `GlobalWalletController` y caches están registrados globalmente y scopeados. No hay dependencia de onboarding que haya que reescribir. El requisito V1 es no mostrar shop/paywall/trial durante el onboarding y no alterar cosméticos o wallet del usuario existente.

## 12. Localization

Hay dos ARB, `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`, y clases generadas en `lib/l10n/gen/`. `AppLocalizations.supportedLocales` contiene `en` y `es`; `main.dart` usa el locale preferido del store.

El catálogo de hábitos también tiene resolver de nombres localizados para las definiciones conocidas. Esto es reutilizable para recomendaciones.

Gaps observados:

- `BootstrapPreparationScreen` contiene strings en español hardcoded;
- `BootstrapAuthorityStateScreen` contiene strings en español hardcoded;
- `TemporaryOnboardingScreen` está hardcoded en español;
- cualquier copy nuevo de V1 debe entrar en ambos ARB, incluidos errores, confirmación, permiso, existing account, restart y accesibilidad.

No hay evidencia de que los textos libres de nombre o email deban entrar en analytics; la instrumentación nueva debe evitarlo explícitamente.

## 13. Analytics

No se encontró SDK/proveedor de analytics de producto ni llamadas `track`, `identify` o un adapter equivalente en `lib/`/`pubspec.yaml`. Sí existe telemetría de debug de bootstrap (`BootstrapTrace`, métricas de duración y logs) y SQL de reportes/admin, pero no es un contrato de analytics de onboarding.

Por tanto, el requisito de privacidad no puede cumplirse “reutilizando” un pipeline de producto ya presente. Antes de implementar eventos debe decidirse un adaptador. El esquema recomendado debe enviar solo enums/booleanos y versión, por ejemplo `onboarding_step_viewed`, `goal_selected`, `recommendation_shown`, `habit_confirmed`, `auth_started`, `completion_succeeded`; nunca nombre, email, texto libre ni payload completo del draft.

## 14. Supabase current state

La siguiente lectura es del SQL versionado en el repositorio, no una inspección del proyecto remoto.

### `public.profiles`

Según `supabase/sql/supabase_backend_phase_9_schema_patch.sql` y migraciones posteriores: `id` referencia `auth.users(id)` con cascade; email, display name, avatar, idioma, `pillar_habit_ids uuid[]`, settings de notificaciones, horas y timestamps. Las migraciones `20260727210441_add_remote_onboarding_state.sql` añaden `onboarding_status`, `onboarding_version`, `onboarding_completed_at`, con defaults/backfill y constraints de consistencia.

RLS/policies del schema patch limitan select/insert/update al propio `auth.uid() = id`. Hay trigger de `updated_at`, validación de máximo tres pillar habits y trigger de ownership.

### `public.habits`

Campos relevantes: `id uuid`, `user_id uuid`, nombre, family/emoji, `habit_type`, target/unit/color, reminder, `schedule jsonb`, archive/order, timestamps y campos de reportes/mutación. RLS limita las operaciones al propio `user_id = auth.uid()`.

El schedule tiene default/validación canónica y migraciones de reportes agregan `source_mutation_id`, `effective_from` y `effective_timezone_name`. No se encontró un unique index de `source_mutation_id` que convierta por sí solo el completion de onboarding en idempotente.

### Estado de onboarding y bootstrap

`20260727213017_enforce_remote_onboarding_transitions.sql` instala un trigger `SECURITY DEFINER` que prohíbe regresar desde `completed` y preserva timestamp/version en completion idempotente. `20260728110000_create_authoritative_bootstrap_decision_contract.sql` crea:

- `app_private.user_bootstrap_state`: `user_id`, `account_status`, `profile_state`, `profile_revision`, timestamps;
- `app_private.bootstrap_policy`: singleton con required version, enforcement y policy revision;
- helpers internos para asegurar/actualizar estado;
- RPC pública autenticada `get_current_user_bootstrap_decision()` con decisión, estado de cuenta/perfil, onboarding, revisions y policy.

Las funciones usan `auth.uid()`, `SECURITY DEFINER` y `search_path` vacío; los helpers internos no se conceden al cliente. El fix `20260728212136_fix_authoritative_bootstrap_decision_user_id_ambiguity.sql` endurece la coherencia y falla cerrado ante mismatches.

### Auth/config

`supabase/config.toml` configura el proyecto local, API, DB y auth base, pero el código auditado no demuestra configuración cliente para Google/Apple ni redirect URI. Debe verificarse en el entorno remoto antes de comprometer el alcance de V1.

## 15. Idempotency capabilities

### Lo que sí existe

- transición remota `completed → completed` preservando el timestamp;
- guard `_isCompletingTemporaryOnboarding` para doble tap dentro de una instancia;
- `runId`, scope epoch y stale guards en bootstrap/auth;
- `upsert` de perfiles con `onConflict id`;
- ledger/rewards con idempotencia lógica para otras operaciones del producto.

### Lo que falta para V1

- `operationId` estable desde el draft hasta completion;
- tabla/registro o RPC de completion que asocie operación, usuario y hábito;
- garantía server-side de “un solo hábito nuevo por completion” bajo retry/concurrencia;
- reconciliación de un resultado ambiguo (timeout después de insert);
- contrato para conservar un hábito ya existente y no sobrescribir nombre, goals, idioma o settings;
- idempotencia específica para programación de reminder.

La generación de `uuid` está disponible como dependencia, pero eso no crea idempotencia por sí solo: el UUID debe persistirse y ser reconocido por el backend.

## 16. Gap matrix

| Requirement | Current state | Gap | Proposed minimal adaptation |
|---|---|---|---|
| Anonymous draft | Solo `meta.onboardingDone` y estado general | No hay draft V1 | Store separado, JSON versionado, validación y save tras cada paso. |
| Resume | Scope guest/local existe | No hay currentStep ni restauración de UI | `OnboardingDraftStore.load()` al entrar; step enum estable. |
| Restart | No hay restart | No existe política de descarte | Acción explícita que borre draft y vuelva a Welcome; no borrar datos de cuenta. |
| Goals 1–3 | `pillar_habit_ids` remoto admite hasta 3 IDs | No hay selección V1 ni catálogo de goals | Goals como enums locales/remote catalog; persistir en draft y mapear al final sin sobrescribir existentes. |
| Pace | No hay campo en profile | Falta modelo/persistencia | Mantener en draft si es solo recomendación; migrar solo si debe ser atributo remoto. |
| Recommendations | Catálogo bundled y helpers por familias | No existe ranking V1 ni fallback remoto | Resolver remoto válido → cache válido → bundled; versionar y validar payload. |
| Real `HabitDraft` | Mapas locales y `RemoteHabit` | No existe entidad V1 | Crear modelo tipado, normalizador y mapper al DTO real. |
| Reminder | Permission/scheduler existentes | Timing e ID canónico no están ligados a completion | Permiso soft/non-blocking; agendar solo después de completion/ID estable. |
| Auth | Email/password y stream Supabase | Faltan Google, Apple, recovery, deep links | Reutilizar `AuthRepository`/`AuthController`; ampliar solo con contratos verificados. |
| Email confirmation | Signup muestra aviso sin sesión | Falta resend/deep-link/resume | Estado `awaitingConfirmation` y reanudación del draft; configurar redirect externo. |
| Existing account | Bootstrap conserva profile/habits | No hay consentimiento para añadir hábito preparado | Pantalla/decisión explícita; no upsert masivo ni overwrite. |
| Idempotent completion | Profile completion es idempotente | Habit insert y operationId no | RPC/transacción o constraint de operación; retry seguro. |
| Catalog cache fallback | Catálogo bundled de 91 definiciones | No existe remote habits catalog/cache V1 | Reutilizar loader y añadir capa solo si backend lo requiere. |
| Home first habit | Home consume active habits | No hay checklist/focus one-shot | Contrato de navegación `firstHabitId`; Home renderiza con estado normal. |
| Checklist max 7 days | No existe | Falta estado/fecha | Estado local por `operationId`/user; TTL máximo siete días. |
| l10n ES/EN | ARB ES/EN generado | Pantallas antiguas hardcoded | Nuevas claves en ambos ARB; corregir strings tocados. |
| Analytics privacy | No hay adapter de producto | No se puede instrumentar aún | Definir adapter de enums/versiones; no PII/free text. |
| Accessibility | Flutter controls y algunos labels existen | No hay auditoría V1 ni semantics contract | Semantics, focus order, labels y tests de tamaño/focus iOS. |

## 17. Migration assessment

| Decision | Scope | Assessment | Why / missing capability / reuse |
|---|---|---|---|
| Anonymous draft | SharedPreferences local | **NO** | El requisito permite persistencia local hasta Preview; no necesita tabla. Reutilizar SharedPreferences solo mediante un store versionado nuevo. |
| Goals/pace/recommendations | Solo recomendación durante onboarding | **NO** inicialmente | Pueden vivir en draft y desaparecer o derivarse al crear el hábito. Reutilizar `pillar_habit_ids` solo con consentimiento y semántica definida. |
| Goals/pace as account profile | Persistencia posterior y sync multi-device | **PROBABLY** | `profiles` no tiene goals/pace/start/pending_step; faltaría migración, DTO, RLS, RPC/cache y compatibilidad. |
| Completion idempotente | Un solo hábito + perfil | **PROBABLY/YES** | Estado de perfil no cubre operationId/habit association. Se necesita RPC/transacción o estructura con unique `(user_id, operation_id)`; debe decidirse antes de producción. |
| Remote recommendation catalog | Catálogo administrable | **PROBABLY** | No hay tabla de hábitos de onboarding en el SQL auditado; hoy existe bundled catalog. Mantener fallback bundled. |
| Existing remote users | Solo añadir el hábito consentido | **NO** si operación server-side existente | RLS/DTO actuales bastan para un insert con UUID client-generated; aun así falta idempotencia formal. |

Recomendación de Fase 1: no crear migración por anticipado. Primero fijar el contrato de `HabitDraft`, `operationId` y destino de cada dato. Si el contrato exige garantizar unicidad server-side o guardar pace/goals, detener la implementación Flutter y diseñar la migración correspondiente.

## 18. Removal plan for legacy onboarding

### SAFE TO REMOVE LATER

- `TemporaryOnboardingScreen` y su ruta, después de que el nuevo flujo cubra cuentas `pending/in_progress` y exista rollback de navegación.
- `BootstrapController.completeTemporaryOnboarding()`, tras sustituirlo por completion V1 y mantener compatibilidad con perfiles ya `completed`.
- UI/copy hardcoded exclusivo del placeholder.

### MUST REUSE

- `AppStartupGate` y la decisión autoritativa de `BootstrapController`.
- `AuthRepository`, `AuthController`, `ProfileRepository` y el identity model de Supabase.
- `RemoteProfile`, `RemoteHabit`, `HabitScheduleNormalizer`, `HabitRepository`.
- `UserStateStorage`/scope guards como infraestructura, sin convertir `onboardingDone` en draft.
- Permission controller, scheduler y personalized notification orchestrator.
- `HomeScreen`, `HomeState`, catálogo bundled, `AppLocalizations` y scope de shop/cosméticos.

### MUST ADAPT

- `WelcomeScreen`: no marcar onboarding completo al entrar en auth.
- `SignInScreen`/`SignUpScreen`: volver a la sesión de onboarding tras auth y manejar confirmación.
- `BootstrapController`: aceptar completion V1 e invalidar caches/re-evaluar autoridad.
- `HabitSyncService`/`HabitRepository`: ID y operación idempotentes.
- Home: primer hábito y checklist.

### UNCERTAIN

- `SessionService`, `AuthGate` y `AuthScreen`: aún pueden tener consumidores legacy; no retirarlos hasta una búsqueda de rutas/deep links y una prueba de regresión.
- `pillar_habit_ids`: puede ser un campo de perfil ya usado por recomendaciones; no reutilizarlo como goals sin confirmar semántica.
- Cualquier configuración remota de Google/Apple/email: el repositorio no prueba el estado del dashboard.

El onboarding legacy no puede eliminarse completamente hoy. Deben conservarse bootstrap, auth, profile, modelos de hábito, schedule, notificaciones y Home; el único candidato claro a retirar después de V1 es el placeholder temporal.

## 19. Risks

- **Draft loss:** guardar solo al final o limpiar guest scope al auth puede perder el progreso.
- **Wrong account:** aplicar un draft anónimo a la cuenta equivocada si cambia la sesión durante un callback.
- **Duplicated habits:** retry/timeout concurrente sin operationId o sin UUID persistente.
- **Profile overwrite:** copiar goals/nombre/settings a un perfil existente sin consentimiento.
- **Provider conflict:** email ya existente, Google/Apple con otro provider o Apple Relay sin linking definido.
- **Confirmation:** signup sin sesión; el draft debe sobrevivir hasta confirmación y deep link.
- **Stale callbacks:** respuesta de auth, catalog, notification o sync perteneciente a un run/scope anterior.
- **Schedule incompatibility:** degradación inesperada de `timesPerWeek` o diferencia entre normalizadores Dart/SQL.
- **Orphan notifications:** reminder creado con ID local, cancelación incompleta o permiso denegado a mitad del flujo.
- **RLS:** insert/update de profile/habit debe ejecutarse bajo `auth.uid()` real y validar el usuario devuelto.
- **Backwards compatibility:** cuentas ya `completed`, rutas `/root`/`/auth`, demo y deep links legacy.
- **Privacy:** analytics con nombre/email/texto libre; logs de debug no deben convertirse en eventos de producto.

## 20. Rollback/compatibility

El rollback inicial debe ser de aplicación y navegación:

1. Mantener el destino remoto existente como autoridad.
2. Conservar la ruta placeholder como fallback temporal para perfiles `pending/in_progress` si el flag de rollout V1 está desactivado.
3. No cambiar ni borrar perfiles/hábitos existentes al desactivar V1.
4. El draft local debe llevar `schemaVersion` y poder descartarse sin tocar `UserStateStore` del usuario.
5. Cualquier hábito que ya haya pasado completion debe ser válido en Home aunque se desactive la UI V1.
6. Los IDs de notificación deben cancelarse/reconciliarse por el hábito confirmado, no por el flujo que lo creó.

No se recomienda un dual-write de dos contratos remotos sin una estrategia de reconciliación. Si se introduce un RPC V1, debe ser backward-compatible con perfiles ya completos y devolver un resultado estable para reintentos.

## 21. Focused tests executed

Se ejecutó:

```text
flutter test test/application/bootstrap/bootstrap_controller_test.dart \
  test/application/auth/auth_controller_test.dart \
  test/data/models/remote_profile_onboarding_test.dart \
  test/data/repositories/profile_repository_onboarding_test.dart \
  test/data/mappers/habit_schedule_cloud_mapper_test.dart \
  test/stores/user_state_store_times_per_week_schedule_test.dart \
  test/services/notification_service_test.dart
```

Resultado: **116 tests passed, 1 failed**. El fallo preexistente/observado está en `test/stores/user_state_store_times_per_week_schedule_test.dart`, caso `addCustomHabit normalizes invalid timesPerWeek payload values`: esperaba `{type: timesPerWeek, timesPerWeek: 1, weekStartsOn: 1}` y recibió `{type: daily}`. No se modificó código para corregirlo porque esta fase es solo auditoría.

También se aisló el mismo caso con `flutter test ... --plain-name`; reprodujo el fallo. La resolución de dependencias descargó/actualizó el cache local de paquetes, pero no cambió archivos de producción del repositorio.

## 22. Missing tests recommended

Antes de llamar completado a V1, faltan como mínimo:

- widget tests de cada paso V1, back navigation, close/resume y restart;
- persistencia versionada del draft con JSON corrupto, schema futuro y datos incompletos;
- auth success/error/timeout, email confirmation y callback que llega dos veces;
- existing account con hábitos/perfil no vacío y consentimiento explícito;
- doble tap, retry tras timeout y dos dispositivos con el mismo `operationId`;
- prueba de que no se sobrescriben nombre, goals, idioma, settings ni hábitos existentes;
- property/contract tests Dart↔SQL para schedule, especialmente `timesPerWeek`;
- catalog remote inválido → cache válido → bundled, incluyendo locale ES/EN;
- notification denied/soft decline/permanently denied y remap de ID local→canónico;
- Home renderiza primer hábito una sola vez y checklist expira a los siete días;
- RLS/ownership y account switching durante cada operación async;
- semantics, focus order, Dynamic Type y labels de VoiceOver/TalkBack;
- analytics contract test que rechace nombre/email/free text.

## 23. Proposed minimal implementation plan

Adaptación de las fases de la especificación a la arquitectura real, sin implementarlas en esta auditoría:

1. **Contrato y draft:** añadir modelo/store V1 separado; definir `schemaVersion`, `currentStep`, `operationId`, goals, pace, recommendation, habit, reminder y timestamps.
2. **Bootstrap bridge:** hacer que `AppStartupGate`/`BootstrapController` enruten a V1 para perfil pendiente/in-progress y mantengan el fallback legacy durante rollout.
3. **UI iOS-first:** crear pasos como widgets/presentación V1 con l10n ES/EN y accesibilidad; reutilizar tokens existentes, sin carousel/paywall/skip.
4. **Recommendations/catalog:** reutilizar `AssetJsonLoader`/`HomeCatalogService` y añadir una resolución remote/cache solo si se confirma un backend; validar contratos antes de mostrar.
5. **Auth continuation:** adaptar `AuthController` y pantallas email; definir providers Google/Apple/recovery/deep links solo cuando sus configuraciones externas estén confirmadas.
6. **First real habit:** mapear el draft a `RemoteHabit`/mapa local con UUID persistente y schedule canónico; conservar datos remotos existentes.
7. **Completion:** implementar una sola operación con `operationId`, autorización por usuario y resultado retry-safe. Si no cabe con el schema actual, diseñar migración/RPC antes de código UI final.
8. **Reminder:** pedir permiso de forma no bloqueante y reconciliar mediante `PersonalizedNotificationOrchestrator` tras conocer el ID final.
9. **Home/checklist:** extender Home con `firstHabitId` y checklist local de máximo siete días, sin inventar una segunda lista de hábitos.
10. **Hardening:** l10n completa, analytics privacy-safe, pruebas de concurrencia/RLS, rollback flag y pruebas iOS.

## 24. Critical unknowns only blockers

Estos puntos no son simples mejoras: bloquean decisiones de implementación o de contrato.

1. ¿La cuenta de Supabase remota tiene Google y Apple habilitados? ¿Cuáles son sus redirect URIs, bundle IDs, Team ID/Service ID y política de linking?
2. ¿Email confirmation está habilitado en producción y cuál es el redirect de confirmación/recovery para iOS?
3. ¿Goals, pace y recommendation deben persistir como datos de cuenta multi-dispositivo o solo servir para crear el primer hábito?
4. ¿El backend acepta una migración/RPC/tabla para `operationId`, o V1 debe componerse estrictamente con inserts actuales?
5. ¿El catálogo de recomendaciones debe ser administrable remotamente en V1 o basta el catálogo bundled versionado?
6. ¿Qué debe ocurrir con un draft anónimo al hacer logout, cambiar de usuario o confirmar un email en otro dispositivo?
7. ¿“Existing account” permite añadir el hábito preparado automáticamente tras consentimiento, o exige revisión/edición adicional?

No bloquean la arquitectura: ES/EN local, permiso no bloqueante, reuse del schedule existente, Home directo y no mostrar shop/paywall.

## 25. Recommended Phase 1 scope

Fase 1 debería limitarse a contrato local, entrada y navegación; no debe implementar todavía completion remoto ni migraciones.

### Crear

- `lib/features/onboarding_v1/domain/onboarding_step.dart`
- `lib/features/onboarding_v1/domain/onboarding_draft.dart`
- `lib/features/onboarding_v1/data/onboarding_draft_store.dart`
- `lib/features/onboarding_v1/application/onboarding_controller.dart`
- `lib/features/onboarding_v1/presentation/onboarding_v1_screen.dart`
- widgets/presentación de Welcome, Name, Goals, Pace y Recommendations solo si el contrato de diseño ya está cerrado.
- tests unitarios del modelo/store/controller para save/load/resume/restart y cambio de locale.

### Modificar

- `lib/screens/welcome_screen.dart`: abrir V1 sin escribir `onboardingDone`.
- `lib/screens/welcome/widgets/welcome_content.dart`: conservar copy/branding y adaptar callbacks.
- `lib/screens/app_startup_gate.dart`: nueva ruta V1 para `pending/in_progress`, con fallback temporal controlado.
- `lib/application/bootstrap/bootstrap_controller.dart`: exponer el handoff a V1 sin duplicar la decisión autoritativa.
- `lib/main.dart`: registrar el provider/controller/store y ruta V1, sin alterar auth remoto ni SQL.
- `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`: añadir solo strings de los pasos incluidos; regenerar clases.
- `test/application/bootstrap/bootstrap_controller_test.dart` y nuevos tests de navegación: verificar compatibilidad con perfiles `completed`, `pending` e `in_progress`.

### Explícitamente fuera de Phase 1

`supabase/migrations`, `supabase/sql`, `AuthRepository` social providers, completion del hábito, reminder scheduling, checklist de Home, analytics de producto y eliminación de `TemporaryOnboardingScreen`. Esos puntos requieren resolver primero los unknowns de la sección 24.

