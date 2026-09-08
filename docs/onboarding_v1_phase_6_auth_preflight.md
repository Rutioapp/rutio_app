# Onboarding V1 Phase 6 — Auth Preflight

Fecha de auditoría: 2026-09-07  
Rama auditada: `feature/onboarding-v1-phase-6-auth-preflight`  
Alcance: auditoría y diseño técnico únicamente. No se implementó Auth, no se modificó producción, Supabase, configuración de providers, deep links, UI, Home ni onboarding.

## 1. Executive summary

Rutio tiene una base real de Auth email/password y un bootstrap de sesión sólido, pero no tiene todavía el puente Phase 6 `Preview → Auth → confirmación → resolución de cuenta → completion`. El código actual permite crear una cuenta y muestra un aviso cuando Supabase devuelve usuario sin sesión; no existe una pantalla/estado de espera con reanudación, callback email/OAuth, recovery ni materialización del onboarding.

La separación local por usuario y el bootstrap autoritativo remoto reducen el riesgo de contaminación entre cuentas. Sin embargo, la regla de negocio “remote profile wins” no está garantizada dentro de un completion de onboarding porque aún no existe ese completion. Tampoco existe persistencia remota de `onboardingOperationId`, registro de operaciones ni constraint que haga idempotente el alta del perfil, hábito y reminder.

Conclusión: Auth email/password es `PARTIAL`, no production-ready para el contrato V1. Google y Apple son `NOT IMPLEMENTED`. La recomendación para QA iOS es implementar primero email/password con confirmación/reanudación y completion idempotente; añadir social login sólo después de cerrar callback y account resolution, con Apple requerido como opción de producto si se ofrece Google en iOS.

## 2. Approved functional contract

El contrato aprobado se conserva: Auth ocurre al final, después de Preview; la cuenta es obligatoria; el draft sobrevive Auth; para una cuenta existente prevalece el remoto; el hábito preparado no se inserta sin consentimiento explícito; completion es idempotente; no hay paywall, trial, premium ni desvío intermedio antes de Home.

El CTA real de Preview es actualmente “Guardar mi Rutio”/equivalente localizado. Su efecto esperado por contrato es entrar en Auth, no crear todavía datos remotos.

## 3. Current Auth architecture

| Área | Código real | Responsabilidad actual |
|---|---|---|
| Application | `lib/application/auth/auth_controller.dart` | Estado de sesión, sign-in/sign-up/sign-out, listener de Supabase, scope local y tareas de bootstrap. |
| Data | `lib/data/repositories/auth_repository.dart` | Adaptador mínimo a `Supabase.instance.client.auth`. |
| Profile | `lib/data/repositories/profile_repository.dart` | Lectura/upsert de `profiles`, estado/versionado de onboarding y cache de decisión autoritativa. |
| Local account | `lib/stores/user_state_store.dart` + `lib/data/repositories/user_state_repository.dart` | Estado por usuario, cambio de scope, persistencia local y carga de hábitos. |
| Bootstrap | `lib/application/bootstrap/bootstrap_controller.dart` | Espera resolución de sesión, cambia scope, consulta perfil remoto autoritativo y decide Home/onboarding/Auth/welcome. |
| UI Auth | `lib/screens/auth/sign_in_screen.dart`, `sign_up_screen.dart`, `auth_gate.dart` | Formularios email/password y navegación legacy a `/root`. |
| UI onboarding | `lib/features/onboarding/presentation/onboarding_v1_screen.dart` | Shell V1; Preview termina en la frontera Auth. |

No hay otra capa de Auth application, ni `AuthService` activo separado: `lib/services/auth.service.dart` es legacy/local y no es el adaptador de Supabase usado por los formularios actuales.

## 4. Current AuthController

`AuthController` mantiene:

- `currentUser`, `isLoading`, `isCheckingSession`, `sessionResolution`, `sessionSnapshot`, `errorMessage` y `noticeMessage`.
- Suscripción a `AuthRepository.authStateChanges` desde el constructor.
- Resolución inicial mediante `initialSessionResolved` y `_resolveSession`.
- `signInWithEmailPassword`, `signUpWithEmailPassword` y `signOut`.
- Cambio de `UserStateStore` a scope user/guest, limpieza de cache de decisión de perfil y sincronización de wallet.
- Guardas de eventos stale tras logout, deduplicación de sign-out y guardas de tareas asíncronas/background.
- `upsertCurrentProfile` únicamente para asegurar perfil de bootstrap, no para materializar onboarding.

No tiene comandos para `refreshSession`, `verifyOTP`, `resetPasswordForEmail`, OAuth, Apple, exchange de callback, email confirmation, account resolution, completion ni consentimiento del hábito preparado. El error se transforma a strings mediante `_mapAuthError`; no existe un modelo tipado Phase 6 para los estados de Auth.

El controller no navega directamente, aunque sus cambios son observados por `BootstrapController`; las pantallas de login navegan a `/root` sólo después de una sesión.

## 5. Current Supabase Auth flows

El único uso productivo encontrado es:

```text
AuthRepository.signUpWithEmailPassword
  → Supabase.auth.signUp(email, password, data: display_name)

AuthRepository.signInWithEmailPassword
  → Supabase.auth.signInWithPassword(email, password)

AuthRepository.authStateChanges
  → Supabase.auth.onAuthStateChange

AuthRepository.signOut
  → Supabase.auth.signOut()
```

No aparecen llamadas reales a `signInWithOAuth`, `signInWithIdToken`, `verifyOTP`, `resetPasswordForEmail`, `exchangeCodeForSession` ni métodos equivalentes.

## 6. Email/password current state

### Sign-up

El formulario requiere email, password y display name opcional. `AuthController` hace `trim()` del email, valida una forma básica de email y exige password de al menos 6 caracteres. `AuthRepository` vuelve a normalizar el email y envía `display_name` en user metadata cuando existe.

Pipeline actual:

```text
SignUpScreen
  → AuthController.signUpWithEmailPassword
  → AuthRepository.signUpWithEmailPassword
  → Supabase.auth.signUp
  → session/user si Supabase lo permite
  → upsert de perfil sólo si ya hay sesión
  → pantalla navega a /root
```

Si `response.user != null` pero no hay sesión, el controller conserva `currentUser == null` y expone un notice de “check your email”. La pantalla no tiene waiting state ni acción de resend/refresh/callback. Si email ya existe, se mapea a un error string y el draft no se toca explícitamente.

### Sign-in

Valida email y password no vacío; usa `signInWithPassword`. Tras éxito cambia el scope local al user, invalida cache de decisión de perfil y deja el bootstrap decidir el destino. Password incorrecta y errores de red no resetean explícitamente el `OnboardingCoordinator`, por lo que el draft anónimo sigue separado, pero no existe integración que lo reanude después del login.

### Production readiness

**Email/password: NO, `PARTIAL`.** Hay conexión real, manejo básico de errores y tests del controller, pero faltan confirmación end-to-end, recovery, preservación/reanudación explícita del draft al completar Auth, completion idempotente, account resolution y QA de dispositivo.

## 7. Email confirmation

Estado comprobado:

- Supabase puede devolver usuario sin sesión cuando la confirmación está habilitada; el código reconoce este caso y muestra un notice.
- No existe `awaitingEmailConfirmation` en una pantalla o controlador de Phase 6.
- No hay polling de `getUser`, `refreshSession` o verificación de OTP.
- No hay `exchangeCodeForSession` ni handler de callback.
- No hay deep-link listener de email confirmation.
- No hay estado persistente de email pendiente/intended operation fuera del draft genérico.
- Si la app muere, el draft anónimo puede seguir en `SharedPreferences`, pero no hay mecanismo que lo conecte a una confirmación posterior.
- Si el email se confirma en otro dispositivo, el camino disponible es volver a abrir la app e iniciar sesión manualmente; no existe recovery automático del operation.

**Email confirmation end-to-end: NO.** La implementación actual termina en un notice, no en `confirmation callback → session → resolver → completion → Home`.

## 8. Google current state

**NOT IMPLEMENTED.** No hay llamada `signInWithOAuth`, package específico, client ID, redirect, callback, provider UI ni pruebas. No se encontró configuración Google nativa en iOS/Android ni `GoogleService-Info.plist`.

## 9. Apple current state

**NOT IMPLEMENTED.** No hay package/native capability, `signInWithIdToken`, nonce, entitlement, callback, first-login name/email handling ni tests. `ios/Runner` no contiene entitlements de Sign in with Apple.

## 10. Deep links/callbacks

**No funcionales para Auth.**

- iOS `Info.plist` no declara `CFBundleURLTypes` ni associated domains.
- `AppDelegate.swift` sólo registra notificaciones y channels locales; no procesa URLs entrantes.
- AndroidManifest sólo tiene launcher y receivers de notificaciones; no tiene intent-filter de Auth/OAuth.
- `MaterialApp` usa rutas nombradas, pero no existe listener de URL/callback ni parser de Supabase Auth.
- `url_launcher` está instalado, pero eso no constituye callback handling.

Email confirmation, OAuth y recovery necesitan configuración externa en Supabase y handlers nativos/Flutter que hoy faltan.

## 11. Startup/session bootstrap

`main.dart` inicializa Supabase, crea providers y monta `AppStartupGate`. `BootstrapController` espera `AuthController.initialSessionResolved`, cambia el `UserStateStore` al scope del user, carga estado local, consulta la decisión autoritativa de `ProfileRepository` y resuelve:

| Caso | Ruta actual |
|---|---|
| Sin sesión, onboarding local no hecho | `WelcomeScreen`. |
| Sin sesión, `userState.meta.onboardingDone == true` | `SignInScreen` (`authentication`). |
| Sesión válida, perfil pending/in_progress | `OnboardingV1Screen`. |
| Sesión válida, perfil completed | Home/root tras cargar hábitos y assets. |
| Sesión expirada/stale | Error/bootstrap retry o estado guest según el evento; no existe recovery específico de confirmation. |
| Email pendiente sin sesión | Igual que guest; no se distingue en routing. |

El perfil remoto autoritativo tiene precedencia para el destino autenticado, pero el guest onboarding draft no se consume en ese bootstrap autenticado.

## 12. Onboarding coordinator integration

`OnboardingCoordinator.internalSteps` contiene exactamente `name`, `goals`, `pace`, `recommendations`, `habit`, `reminder`, `preview`. Los enums ya reservan `auth`, `emailConfirmation`, `resolvingAccount` y `finalizing`, y el draft ya tiene estados `authPending`, `remoteInProgress`, `finalizing`, `completed` y `recoverableError`, pero el coordinator no implementa esas fases.

`continueFromPreview()` valida y persiste el draft, publica la frontera Auth y no hace efectos externos. No llama AuthController, no cambia sesión, no crea perfil/hábito/reminder y no marca completion. Back sólo opera dentro de `internalSteps`; Auth aún no está integrado como paso reanudable.

## 13. Draft persistence

`OnboardingDraft` contiene `draftId`, `onboardingOperationId`, versiones, paso actual, nombre, goals, pace, habit, reminder, recommendation metadata, `authIntent`, `completionState`, `boundUserId` y `completedAt`.

`SharedPreferencesOnboardingDraftStore` guarda:

- anónimo: `rutio_onboarding_draft_v1_<environment>_anonymous`;
- por usuario: `rutio_onboarding_draft_v1_<environment>_user_<id>`.

`OnboardingDraftService.bindToUser` persiste primero la copia user-scoped y elimina después la anónima. El coordinator actual sólo usa el scope anónimo. Auth normal no borra ese key, pero tampoco lo vincula automáticamente al usuario autenticado. `signOut` limpia `UserStateStore`/cache de perfil, no el draft anónimo de onboarding.

Resultado: **el payload sobrevive normalmente al login/restart**, pero **la continuidad funcional Auth → completion no está implementada**. El cambio de usuario sí está protegido para el user-scoped draft mediante `boundUserId` y el scope local.

## 14. Preview → Auth

En `OnboardingV1Screen`, Preview muestra el resumen read-only y su CTA llama `coordinator.continueFromPreview()`. El coordinator sólo publica el límite previsto para la siguiente fase. No navega a `/auth` ni `/auth-signup`; los botones de login/signup visibles en Welcome son rutas legacy directas y no transportan el draft como intent explícito.

Estado actual: **Auth screen existe, integración Preview → Auth no existe**. No hay transporte tipado de `draftId`, `onboardingOperationId` o intención `new-account/existing-account`.

## 15. New-account flow

La única inicialización observada tras sign-up con sesión es `ProfileRepository.upsertCurrentProfile` para bootstrap. No existe pipeline Phase 6 que haga, en orden idempotente, profile initialization → habit materialization → reminder materialization → remote onboarding completed → Home.

El camino de hábito existente en Home es local-first (`UserStateStore.addCustomHabit`/`addHabitFromCatalog`) y sincroniza best-effort mediante `HabitSyncService`/`HabitRepository`. No es todavía una operación de completion de onboarding y no está ligada a `onboardingOperationId`.

## 16. Existing-account flow

Después de login, `AuthController` cambia el scope a la cuenta y `BootstrapController` carga la decisión remota y los hábitos remotos. Esto protege el estado normal de Home, pero no resuelve el draft de onboarding ni pregunta por el hábito preparado.

No hay hoy una distinción explícita Phase 6 entre `newAccount`, `existingAccountCompleted` y `existingAccountIncomplete` ni una pantalla de decisión. Para una cuenta existente completed, el riesgo principal es que el bootstrap lleve al Home remoto y deje el draft anónimo sin resolución; no hay inserción automática del hábito en el código auditado.

## 17. Remote-wins contract

**PARTIALLY guaranteed.**

Sí está implementado para el bootstrap normal: `BootstrapController` consulta `loadAuthoritativeBootstrapDecision`, `ProfileRepository` valida user/scope/version, y `UserStateStore.switchLocalScope` descarta el estado en memoria de otra cuenta antes de cargar el scope correcto. Los hábitos remotos se hidratan hacia el scope autenticado.

No está garantizado para Phase 6 porque aún falta el punto de account resolution. No existe una regla que compare explícitamente el draft guest con el perfil remoto y bloquee toda escritura de nombre, hábitos, progreso, estadísticas, rewards, diary, shop o profile durante completion.

Contrato recomendado: resolver primero remoto; nunca hacer merge silencioso; aplicar el nombre sólo en cuenta nueva; en cuenta existente dejar intactos profile/habits/progress y tratar el draft sólo como propuesta de hábito pendiente de consentimiento.

## 18. Prepared-habit resolution

Hoy el hábito preparado vive como `draft.habit`; Preview no lo crea. No hay código que lo inserte automáticamente al autenticarse desde onboarding, ni infraestructura de consentimiento.

Recomendación: después de cargar el perfil remoto y antes de completion, mostrar una decisión explícita sólo si la cuenta ya existe y tiene datos remotos: “Añadir el hábito preparado a mi cuenta”. `No` descarta sólo la propuesta del draft; no toca datos remotos. `Sí` llama al mismo dominio de creación de hábitos y debe ser idempotente por `(user_id, onboardingOperationId, habit intent)`.

## 19. Account resolution state machine

Estados recomendados, no implementados:

```text
preview
  → authForm
  → submitting
  → awaitingEmailConfirmation        (email/password only when required)
  → authenticated
  → accountResolution
       ├─ newAccount
       ├─ existingAccountCompleted
       ├─ existingAccountIncomplete
       └─ unknown/error
  → consentForPreparedHabit           (existing account only, if draft has habit)
  → completingOnboarding
  → completed → Home
```

La resolución debe usar la respuesta remota de `profiles`/bootstrap, no heurísticas de UI. `completed` implica conservar remoto. `incomplete` requiere política explícita para continuar sin inventar datos remotos.

## 20. Onboarding operation id / idempotency

`onboardingOperationId`: **YES en draft, NO como operación remota**. Se genera con UUID al crear `OnboardingDraft` y se conserva al avanzar/reanudar; no aparece en `profiles`, `habits`, settings, RPC, operation log ni unique constraint.

Idempotencia actual: **INSUFFICIENT**. Hay guardas de doble tap para varias operaciones de UI y tests del coordinator, pero no hay protección cruzada cliente/repositorio/base de datos para repetir completion después de retry, reconnect, restart o callback duplicado.

Contrato requerido:

- el mismo `(user_id, onboardingOperationId)` devuelve el mismo resultado lógico;
- profile initialization no duplica ni sobreescribe remoto;
- habit preparado se inserta como máximo una vez y sólo con consentimiento;
- reminder/config se materializa como máximo una vez;
- completion flag sólo avanza, nunca vuelve de completed a in_progress;
- callback repetido es un read/return del resultado ya aplicado.

## 21. Atomic completion strategy

**RPC transaccional: YES, recomendado.** La arquitectura actual usa varias escrituras client-side y sync best-effort; eso no es suficiente para el caso profile creado + habit fallido. El completion debería enviar `operation_id`, versión de onboarding, payload mínimo validado, decisión de account resolution y consentimiento explícito del hábito a una RPC transaccional.

La RPC debería validar `auth.uid()`, consultar el perfil remoto actual, bloquear la sobrescritura de una cuenta existing, crear/actualizar recursos en una transacción, registrar la operación y devolver estado/resultados. El cliente debe poder reintentar con el mismo ID y recuperar `completed`, `in_progress` o `retryable_error`.

## 22. Profile/user-state initialization

`profiles` es la fuente remota de identidad/onboarding. `AuthController._ensureCurrentUserProfileForBootstrap` hace upsert de email/display name/avatar sólo cuando hay sesión y el repositorio está disponible; no es un initializer completo de onboarding.

`UserStateStore` crea/carga un estado local desde `assets/templates/user_state_template.json`, con claves por usuario. `meta.onboardingDone` se persiste localmente, mientras `profiles.onboarding_status`, `onboarding_version` y `onboarding_completed_at` se leen remotamente. No encontré trigger/RPC de creación de `profiles` ligado a `auth.users`; el cliente hace upsert. La existencia exacta del perfil debe verificarse también en el dashboard/proyecto Supabase vinculado.

## 23. Reminder materialization

Reminder de onboarding es actualmente un snapshot en `draft.reminder` con estados de permiso/scheduling. El permiso OS se solicita en el onboarding reminder step; el draft no se convierte todavía en una configuración persistente de hábito/remote.

La creación normal de hábitos soporta `reminderEnabled`/`reminderTime` y el runtime de notificaciones programa desde el `UserStateStore`. Phase 6 debe reutilizar ese contrato, no volver a pedir permiso si ya está resuelto, y hacer la escritura/scheduling idempotente. No hay hoy una operación de completion que lo haga.

## 24. Failure/retry/restart

Hay buenas guardas de scope, stale result y retry en bootstrap; también existe `OnboardingCompletionState.recoverableError` en el modelo. No existe recuperación Phase 6 para:

- network failure después de Auth;
- profile escrito y habit fallido;
- callback repetido;
- app killed esperando email;
- logout entre sesión y completion.

Estrategia recomendada: conservar draft y operation ID hasta recibir confirmación remota de completion; marcar `remoteInProgress`/`recoverableError`; retry del mismo operation; nunca generar otro ID para un retry; después de logout limpiar la sesión y mantener el draft sin vincularlo a otro user.

## 25. Cache/local/remote precedence

Precedencia actual:

1. Supabase Auth session/user para identidad.
2. `profiles`/authoritative bootstrap para destino y estado de onboarding autenticado.
3. `UserStateStore` scoped local para el contenido operativo de la cuenta.
4. caches de decisión remota sólo como aceleración validada por user/scope/version.
5. draft anónimo SharedPreferences para onboarding pre-Auth.

Contrato canónico recomendado: el draft anónimo es intención pendiente, no fuente de verdad de la cuenta; el perfil remoto decide estado y nombre existente; hábitos/progreso remotos ganan; el draft sólo materializa recursos nuevos cuando la cuenta es nueva o el usuario consiente explícitamente.

## 26. Navigation

La app usa `MaterialApp` con rutas nombradas y `AppStartupGate`, no GoRouter. Rutas Auth actuales: `/auth`, `/auth-signup`, `SignInScreen.route`, `SignUpScreen.route`; `/root` vuelve a `AppStartupGate` autenticado.

Riesgos para Phase 6: login actual puede ir directamente a Home/onboarding antes de consumir el draft; callback podría duplicar bootstrap; la ruta guest y la ruta autenticada pueden competir durante la carrera de `onAuthStateChange`; no hay back contract desde confirmation ni loop guard Preview/Auth/Home.

## 27. Security/RLS

Hallazgos positivos:

- No se observó almacenamiento productivo de passwords; `SessionService` limpia payloads legacy y los tests verifican que no se expongan.
- Los logs de Auth imprimen estado y user ID, no password/token.
- El cliente usa anon/publishable Supabase config; no se encontró service-role key en Flutter.
- Las policies auditadas de `profiles` y `habits` restringen select/insert/update/delete al `auth.uid()` correspondiente.

Limitaciones Phase 6:

- RLS actual permite operaciones propias, pero no aporta idempotencia ni atomicidad.
- No existe una policy/tabla de operation ledger.
- Debe evitarse aceptar `user_id` arbitrario desde cliente; la futura RPC debe derivarlo de `auth.uid()`.
- OAuth secrets, provider credentials, redirect URLs, SMTP y templates no pueden confirmarse desde el repo.

## 28. iOS configuration

Estado: **incompleto para Auth social/callback**. `ios/Runner/Info.plist` sólo contiene permisos y configuración Flutter; no URL schemes ni associated domains. `AppDelegate.swift` no maneja URLs. No hay entitlements de Apple Sign In y no hay configuración Google nativa.

Camino mínimo iOS para V1: email/password + confirmation/recovery callback usando una URL universal/app scheme verificada, completion RPC idempotente y QA real en un iPhone. Si se ofrece Google en iOS, incorporar Apple Sign In como opción de producto/técnica antes de release y gestionar nonce, first-login data y callback. No se recomienda empezar por ambos providers sociales.

## 29. Android configuration

Email/password no requiere configuración nativa adicional. `AndroidManifest.xml` no tiene intent-filters OAuth/deep-link. Google no tiene client IDs ni callback configurados. La compatibilidad futura requiere registrar el scheme/intent-filter y validar SHA/configuración del provider, pero queda fuera de este preflight y no se modificó.

## 30. Supabase dashboard dependencies

Verificación externa obligatoria antes de producción:

- Email confirmation enabled/disabled por entorno.
- Auth providers Google y Apple habilitados y credentials válidas.
- Site URL y redirect allow-list.
- Email templates, sender y SMTP de producción.
- Apple Services ID/key/team configuration.
- Google OAuth client IDs y redirect URIs.
- Rate limits/abuse controls de signup, login y recovery.
- Estado real de triggers/functions del proyecto vinculado.

El repo no demuestra que el email por defecto de Supabase sea suficiente para producción; SMTP/template deben marcarse `external verification required`.

## 31. Existing tests

Existen tests relevantes para `AuthController`, bootstrap/session, onboarding coordinator, draft codec/store, Preview, reminder, profile repository, remote profile mapping, user-state scope e integración de hábitos. No existen tests de email confirmation, callback, OAuth, account resolution, completion idempotente, prepared-habit consent, recovery ni deep links.

## 32. Missing tests

Matriz mínima futura:

| ID | Caso |
|---|---|
| A | Cuenta email nueva con sesión inmediata cuando confirmation está desactivada. |
| B | Cuenta email nueva con confirmation requerida. |
| C | Restart/app killed esperando confirmation conserva draft + operation. |
| D | Callback confirmation crea/recupera sesión y no duplica completion. |
| E | Login con cuenta email existente. |
| F | Password incorrecta conserva draft/coordinator. |
| G | Remote profile wins frente a nombre/hábitos locales. |
| H | Prepared habit no se inserta automáticamente en cuenta existente. |
| I | Consentimiento explícito inserta una vez. |
| J | Cuenta nueva inserta hábito una vez. |
| K/L | Doble tap y retry con mismo operation ID. |
| M/N | Network failure y fallo entre profile/habit son retryables. |
| O/P | Google new/existing account. |
| Q/R | Apple new/existing account. |
| S/T | OAuth cancel y error desconocido. |
| U | Logout/restart recovery y cambio de usuario. |

## 33. Migration/RPC assessment

**¿Hace falta migration? YES para una implementación Phase 6 robusta; NO se ejecutó en este preflight.** Los campos de onboarding del perfil ya existen, pero faltan almacenamiento/constraint de idempotencia y probablemente una tabla de operation result/ledger o una clave lógica equivalente. Provider setup y callback config son cambios de dashboard/nativos, no migration SQL.

**¿Hace falta RPC? YES, recomendada.** Sin una RPC transaccional, la finalización distribuida entre profile/habit/reminder no puede garantizar atomicidad ni recuperación determinista.

## 34. Recommended implementation phases

- **AUTH-1:** Contratos de dominio/state machine, intents de draft y account resolution; sin providers sociales.
- **AUTH-2:** Email/password, waiting confirmation, refresh/resume, existing email handling y navegación Preview/Auth.
- **AUTH-3:** RPC/ledger/constraint de completion idempotente; new vs existing; remote wins; consentimiento del hábito; reminder materialization.
- **AUTH-4:** Deep-link/callback hardening y recovery de app killed/other device; password recovery si el release lo exige.
- **AUTH-5:** Google con configuración iOS/Android, callback, cancel/error y existing-account rules.
- **AUTH-6:** Apple con nonce, entitlement, first-login name/email y resolución de cuentas.
- **AUTH-7:** Regression, QA físico iPhone primero y compatibilidad Android.

Recovery password debe entrar antes de producción si la cuenta depende de email/password; no debe bloquear el primer spike de email confirmation si se trata como subfase separada.

## 35. Risks

Riesgos máximos: perder el draft al navegar a `/root`; sobrescribir profile remoto con nombre local; insertar el hábito preparado en una cuenta existente; duplicar hábito/profile/reminder ante retry; callback loop; confirmation dead-end; carrera session/bootstrap; stale `UserStateStore` de otro usuario; operation ID sólo local; fallo parcial profile→habit; provider/redirect mismatch; ausencia de SMTP; y ofrecer Google en iOS sin cerrar el camino Apple.

## 36. Critical decisions

1. Email/password production-ready: **NO, PARTIAL**.
2. Email confirmation end-to-end: **NO**.
3. Callback/deep-link funcional: **NO**.
4. Google: **NO IMPLEMENTED**.
5. Apple: **NO IMPLEMENTED**.
6. Provider V1 iOS: **email/password primero**; Apple antes o junto a cualquier social login ofrecido en iOS.
7. Cuenta nueva/existente: **todavía no se detecta en un resolver Phase 6**; debe derivarse de perfil/bootstrap remoto.
8. Remote profile wins: **PARTIAL**, garantizado en bootstrap normal, no en completion inexistente.
9. Prepared habit accidental en existing: **no se inserta hoy**, pero no existe una barrera de completion porque completion no existe.
10. Consentimiento: después de autenticación y lectura del perfil remoto, antes de materializar el hábito.
11. Draft Auth/restart: **payload sí sobrevive**, integración/reanudación funcional **NO**.
12. Onboarding completed: remoto `profiles.onboarding_status/completed_at`; local `userState.meta.onboardingDone`; están duplicados y pueden divergir.
13. `onboardingOperationId`: **sí en draft, no remoto**.
14. Idempotency actual: **NO suficiente**.
15. Completion RPC: **YES**.
16. Migration: **YES para ledger/constraint de Phase 6; ninguna ahora**.
17. Nueva tabla/constraint: **probablemente YES** para operation result/unique logical key.
18. Deep-link config: **YES**, iOS primero; email/OAuth/recovery lo requieren.
19. Email ya existe: hoy error string; debe ofrecer Login conservando draft.
20. App muere esperando confirmation: draft puede quedar local, pero hoy no se recupera; futuro: pending intent + refresh/login.
21. Callback dos veces: hoy no hay handler; futuro: mismo operation ID devuelve resultado idempotente.
22. Profile write succeeds/habit fails: hoy no hay completion; futuro: transacción o estado retryable con rollback/ledger.
23. Existing completed: remoto prevalece; hábito local sólo con consentimiento.
24. Existing incomplete: continuar con resolución controlada usando remoto; no inventar merge silencioso.
25. Pasos exactos: AUTH-1 → AUTH-2 → AUTH-3 → callback/recovery → Google → Apple → QA.
26. QA iPhone más corto: email/password, confirmation callback, RPC idempotente y remote/existing tests antes de Google/Apple.

### Verification performed

- `flutter test --no-pub` sobre AuthController, BootstrapController, onboarding coordinator/draft/store/Preview y SessionService: **109 tests passed**.
- `flutter analyze --no-pub` focalizado sobre Auth/bootstrap/onboarding/Auth UI: ejecución iniciada; el resultado final debe quedar confirmado en CI/local si el proceso del analyzer excede el tiempo del preflight.
- `git diff --check`: pendiente de ejecutar después de crear este documento.

### Scope confirmation

Sólo debe crearse/modificarse `docs/onboarding_v1_phase_6_auth_preflight.md`. No se implementó AUTH-1 ni ninguna escritura de producción, migration, RPC, provider, deep link, ARB, UI, Home, Statistics, Weekly Report, rewards o premium.

**Ready to start AUTH-1: NO**, hasta aceptar las decisiones de RPC/ledger, account resolution, callback y política iOS descritas aquí.
