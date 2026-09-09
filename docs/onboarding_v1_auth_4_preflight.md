# Rutio — Onboarding V1 — AUTH-4 preflight

Fecha de auditoría: 2026-09-08  
Rama auditada: `feature/onboarding-v1-auth-4-preflight`  
Alcance: auditoría y definición de arquitectura. Esta pasada no implementa AUTH-4A, no crea migrations, no modifica Supabase remoto, no añade providers sociales, Premium/RevenueCat ni AUTH-5.

## 1. Resultado ejecutivo

AUTH-3 ya proporciona el contrato de completion que AUTH-4 debe conservar: `OnboardingAuthStateMachine`, `onboardingOperationId`, intent congelado, envelope `remoteInProgress`, resolución remota, remote-wins, reconciliación, ledger/RPC idempotente, cleanup y ownership temporal de Auth.

AUTH-4 está **parcialmente preparado** para email confirmation: existe el estado `awaitingEmailConfirmation`, la pantalla “Revisa tu correo” y persistencia del draft. No existe todavía el puente externo que falta para que el enlace vuelva a Rutio: callback/deep-link, clasificación confirmation/recovery, resend, password recovery y coordinación de cold start. Por ello el flujo end-to-end confirmation → sesión → resolveAccount → completion → Home es **NO implementado**.

Decisiones de esta auditoría:

- Callback canónico de producción recomendado: `https://rutioapp.com/auth/callback`.
- La URL externa debe convertirse en estado de Auth; no debe hacer `Navigator.push` directamente.
- `AppStartupGate`/`BootstrapController` siguen siendo la autoridad global de destino.
- Un `AuthCallbackCoordinator` debe ser la única autoridad transitoria para parsear, clasificar y entregar callbacks.
- La máquina de onboarding conserva la autoridad de continuidad de su `operationId` y completion.
- No hacen falta migrations para AUTH-4 como está definido; sí hace falta configuración posterior de Supabase y cambios nativos para App/Universal Links.
- No modificar `rutioapp.com` en este preflight; será necesario en la fase de integración HTTPS.

## 2. Estado actual auditado

| Área | Estado real | Evidencia |
|---|---|---|
| Supabase init | Implementado | `RutioSupabaseClient.initialize()` en `lib/core/supabase/rutio_supabase_client.dart`, llamado desde `main()` antes de `runApp()`. |
| Auth global | Implementado | `AuthController` escucha `auth.onAuthStateChange`, resuelve sesión inicial, cambia scope local y distingue logout explícito. |
| Email/password | Implementado | `AuthRepository.signUpWithEmailPassword` y `signInWithEmailPassword`; validación actual de signup: mínimo 6 caracteres en controller. |
| Onboarding Auth | Implementado | `OnboardingAuthStateMachine` usa `OnboardingAuthAdapter`, resolución remota y completion. |
| Awaiting confirmation | Parcial real | `OnboardingConfirmationRequired` → `awaitingEmailConfirmation`; persiste `currentStep=emailConfirmation`; UI sólo ofrece “Ya lo he confirmado” que vuelve al modo login. |
| Completion | Implementado por AUTH-3 | `OnboardingCompletionIntent`, `remoteInProgress`, RPC/ledger y reconciliación ya existentes. AUTH-4 no debe rediseñarlos. |
| Ownership | Implementado | `BootstrapController.acquireOnboardingAuthOwnership()`/`release...()` alrededor de `OnboardingAuthStep`; eventos globales se suprimen/coordinan mientras dura la pantalla. |
| Deep links | No implementado | No hay listener Flutter, parser, callback handler ni integración de URL Auth. |
| Password recovery | No implementado | No hay `resetPasswordForEmail`, `updateUser(password)` ni pantalla de reset. |
| Resend | No implementado | No hay llamada a `auth.resend(type: OtpType.signup, email: ...)` ni cooldown. |

## 3. Comportamiento real de signup

La llamada real es:

```dart
Supabase.instance.client.auth.signUp(
  email: email.trim(),
  password: password,
  data: displayName == null ? null : {'display_name': displayName},
)
```

El repositorio rechaza sólo una respuesta sin `user` **y** sin `session`. Después:

1. `session != null`: `AuthRepository` devuelve la respuesta; el adapter devuelve `OnboardingAuthenticated`; la máquina resuelve la cuenta y continúa hacia completion.
2. `user != null && session == null`: el adapter devuelve `OnboardingConfirmationRequired`; la máquina conserva el mismo draft y `onboardingOperationId`, cambia a `currentStep=emailConfirmation` y persiste.
3. `user == null && session == null`: se lanza error de autenticación.

Por tanto, `awaitingEmailConfirmation` existe realmente y su transición está implementada. Lo que falta es comprobar/recibir la sesión posterior: hoy el CTA de confirmación cambia a login y no procesa un email link.

El password sólo vive en `OnboardingAuthRequest`/controllers efímeros; no aparece en `OnboardingDraft`, codec ni SharedPreferences. El signup global valida actualmente mínimo 6 caracteres; la pantalla muestra un hint de mínimo 8, pero no hay regla máxima ni complejidad adicional confirmada.

## 4. Arquitectura actual y límites de autoridad

### Supabase/Auth

- `main()` inicializa Supabase antes de crear providers.
- `AuthRepository` encapsula `currentUser`, `onAuthStateChange`, signup, signin y signout.
- `AuthController` es dueño de sesión global, `initialSessionResolved`, scope de `UserStateStore`, cleanup de logout y tareas post-Home.
- `OnboardingAuthAdapter` es el límite del onboarding y no llama directamente a Supabase.
- `OnboardingAuthStateMachine` conserva intención, draft, resolución de cuenta y completion.

### Bootstrap

`BootstrapController` espera la resolución inicial de sesión, carga el scope correcto, obtiene la decisión autoritativa remota y publica `welcome`, `onboarding` o `home`. `AppStartupGate` presenta esa decisión y mantiene splash durante cold start. Una ruta externa no debe saltarse este gate.

### Ownership

El ownership actual es temporal y ligado al `operationId` de la pantalla Auth:

```text
OnboardingAuthStep mounted
  → acquire(operationId)
  → auth_event global suprimido/coordinado
  → máquina procesa session available y completion
  → dispose/release(operationId)
```

AUTH-4 debe extender este mismo mecanismo al callback, pero nunca hacerlo global permanente. La adquisición debe ocurrir antes de entregar el callback a la máquina; la liberación debe ocurrir sólo después de completion/recovery terminal, logout explícito o desmontaje controlado.

## 5. Persistencia y resume

`SharedPreferencesOnboardingDraftStore` guarda JSON bajo claves namespaced:

- anónimo: `rutio_onboarding_draft_v1_<environment>_anonymous`;
- user-scoped: `rutio_onboarding_draft_v1_<environment>_user_<userId>`.

El draft actual contiene `authIntent`, `authEmail`, `currentStep`, `onboardingOperationId`, habit, reminder, `completionState`, decisión de resolución, `boundUserId` y timestamps. `DraftOnboardingAuthPersistence` guarda anónimo mientras no exista usuario y enlaza primero una copia user-scoped cuando aparece `boundUserId`.

Esto sobrevive normalmente a app kill. Sin embargo, Bootstrap guest hoy decide `Welcome` aunque encuentre un draft reanudable (`hasResumableOnboardingDraft` sólo se usa como razón/telemetría); la pantalla de destino no diferencia todavía `guest_draft` de Welcome. Para AUTH-4, un draft en `auth/emailConfirmation` debe reabrir onboarding Auth, no login genérico ni Welcome limpio.

Persistir en AUTH-4:

- email normalizado;
- `authIntent` y `currentStep`;
- `onboardingOperationId`;
- `boundUserId` sólo después de identidad verificada;
- recovery envelope y payload congelado de completion ya existente;
- timestamps/estado tipado.

Nunca persistir password, access token, refresh token, OTP ni el callback completo.

## 6. Deep-link audit

### Android

- package/applicationId: `com.rutio.app`.
- `MainActivity` exportada y `launchMode=singleTop`.
- Sólo existe intent-filter `MAIN`/`LAUNCHER`.
- No existe scheme, host, pathPrefix, App Link, `android:autoVerify` ni callback intent-filter.
- `singleTop` es compatible con entrega a una instancia existente, pero el handler futuro debe deduplicar `onNewIntent`/cold start.

Cambios futuros: intent-filter HTTPS con host/path de callback, `android:autoVerify=true`, asociación `assetlinks.json`, y pruebas de app abierta, background, cold start y host no verificado. No se hicieron en esta pasada.

### iOS

- bundle identifier de Runner: `com.rutio.app`.
- `Info.plist` no contiene `CFBundleURLTypes` ni `Associated Domains`.
- `AppDelegate.swift` sólo registra notificaciones y method channels; no implementa `openURL`, `continueUserActivity` ni callback Auth.
- No hay entitlements de Universal Links.

Cambios futuros: Associated Domains, entitlement, `apple-app-site-association` en el dominio y forwarding de URL/user activity al plugin/coordinator. No se hicieron en esta pasada.

### Flutter/dependencias

No hay código que consuma `app_links`, aunque el paquete aparece transitivamente en `pubspec.lock` (v7.0.0). `pubspec.yaml` no lo declara directamente. No hay `initialUri`, stream de URI ni router de callback. AUTH-4C debe decidir si se declara directamente para una API estable; no debe depender accidentalmente de una dependencia transitiva.

## 7. Estrategia de callback

### Comparación

| Criterio | Custom scheme (`rutio://`) | HTTPS App/Universal Link |
|---|---|---|
| Desarrollo local | Muy simple | Requiere dominio/entorno y asociación o fallback de QA |
| Producción iOS/Android | Registro nativo sencillo | Registro nativo + asociación de dominio |
| Seguridad | Puede ser reclamado por otra app | Asociación de dominio reduce hijacking |
| Supabase allow-list | URL exacta y simple | URL HTTPS exacta y auditable |
| QA | Fácil de invocar, menos representativo de producción | Más trabajo inicial, prueba el camino real |
| Google/Apple futuro | Válido pero añade otra forma de callback | Unifica email, recovery y social callback |

### Recomendación

Usar una única URL canónica de producción: `https://rutioapp.com/auth/callback`. La misma ruta lógica debe clasificar confirmation y recovery por parámetros/evento de Supabase; no se debe crear una URL distinta por proveedor. Para desarrollo se puede permitir una URL HTTPS de entorno explícitamente registrada, pero no convertir `rutio://` en el contrato productivo.

Flujo recomendado:

```text
OS URL
  → AuthCallbackCoordinator.parse/classify
  → Supabase SDK procesa código/tokens y emite AuthState
  → AuthController publica sesión/evento
  → onboarding ownership recibe session
  → state machine recupera draft/operation
  → resolveAccount
  → completion idempotente/reconciliación
  → Bootstrap/AppStartupGate decide Home u onboarding
```

El callback handler no navega directamente y no crea un `operationId`.

## 8. Confirmación de email

Contrato AUTH-4:

```text
signup sin session
  → awaitingEmailConfirmation
  → app kill/restart conserva draft y operationId
  → link abre Rutio
  → callback coordinator entrega URL al SDK
  → session/signedIn
  → ownership de onboarding
  → resolveAccount del mismo user
  → replay de completion con el mismo operationId
  → Home
```

La sesión recibida debe pertenecer al mismo `boundUserId` si el draft ya está ligado. Si no coincide, rechazar fail-closed, no cambiar scope y conservar el draft sin entregarlo a otra cuenta. El nombre, hábito y reminder preparados se mantienen porque viven en el draft; no se reinicia onboarding.

Para app abierta, el callback entra por el mismo coordinator y la máquina ya montada consume el evento. Para background/cold start, el callback se almacena como evento transitorio hasta que Supabase init, AuthController, providers y Bootstrap estén listos; la UI permanece en splash/preparing y no muestra Welcome flash.

Errores tipados previstos: `expiredConfirmationLink`, `invalidConfirmationLink`, `confirmationFailed`, `networkFailure`, `callbackUserMismatch`. Acciones: reintentar, reenviar correo, iniciar sesión o volver a la pantalla Auth; nunca crear un draft nuevo.

Resend debe usar la API `auth.resend(type: OtpType.signup, email: email)` del SDK, con cooldown local, loading, éxito visible y mapeo de rate-limit/network. No permitir cambio de email en V1: el botón “Usar otro correo” añade ambigüedad sobre signup previo, operación y callback; ofrecer volver al formulario conservando el draft sólo como decisión explícita de una fase posterior.

## 9. Password recovery

Hoy no existe entry point funcional de recovery, aunque el login tiene el string “¿Olvidaste tu contraseña?”. AUTH-4D debe introducirlo únicamente desde Login:

```text
Welcome → Iniciar sesión → Forgot password
  → email
  → auth.resetPasswordForEmail(email, redirectTo: canonicalCallback)
  → callback
  → AuthChangeEvent.passwordRecovery
  → pantalla Nueva contraseña
  → auth.updateUser(UserAttributes(password: ...))
  → signed out/controlled session cleanup
  → Bootstrap decide Home o onboarding según perfil remoto
```

La clasificación `passwordRecovery` es distinta de confirmation. En la versión bloqueada de `supabase_flutter` (`2.12.4`, que usa gotrue) están disponibles `AuthChangeEvent.passwordRecovery`, `exchangeCodeForSession`, `resetPasswordForEmail`, `updateUser` y `resend`; el código Rutio todavía no los usa. `userUpdated`/`signedIn` no deben interpretarse por sí solos como confirmation.

Validar password y confirmación sólo en memoria, conservar el mínimo actual sin inventar una política nueva, no registrar el valor y no persistirlo. Tras reset exitoso, invalidar/consumir recovery state, impedir back a la pantalla de reset y dejar que el destino lo decida remoto: perfil completed → Home; pending/incomplete → onboarding/recovery contract.

## 10. Callback security y deduplicación

Controles obligatorios:

- allow-list estricta de scheme/host/path y rechazo de URI malformada;
- no aceptar redirect arbitrario desde query parameters;
- no loguear URL completa, tokens, code, OTP o password;
- clasificar una sola vez por fingerprint no sensible del evento y consumir callbacks repetidos;
- validar user/session contra `boundUserId` y operation envelope;
- callback tras logout: ignorar/rechazar y no revivir una sesión explícitamente cerrada;
- callback de otra cuenta: fail-closed y limpiar sólo el estado de esa cuenta, nunca el draft de otra;
- token expirado: error tipado y reintento/login, sin nuevo onboarding;
- completion repetida: mismo operationId y RPC/ledger de AUTH-3; el resultado `alreadyCompletedSameOperation` reconcilia y limpia;
- cualquier operation conflict o mismatch: terminal/fail-closed, no merge.

Logs seguros permitidos:

```text
[AUTH_CALLBACK] event=classified authEvent=passwordRecovery callbackType=https hasSession=true result=accepted
[EMAIL_CONFIRMATION] event=session_received operationId=short user=short result=replay_started
[PASSWORD_RECOVERY] event=update_finished user=short result=success
```

Nunca incluir password, access/refresh token, OTP, code, secret ni callback completo.

## 11. Bootstrap decision table

| Session | Draft | Remote profile | Auth recovery | Resultado |
|---|---|---|---|---|
| no | no | n/a | no | Welcome |
| no | guest onboarding válido antes de Auth | n/a | no | Reanudar onboarding en el paso persistido; AUTH-4 debe evitar Welcome genérico |
| no | `currentStep=auth/emailConfirmation`, awaiting | n/a | confirmation pendiente | Auth step “Revisa tu correo” |
| sí | draft ligado/mismo user | completed | no | Home; remote wins; no repetir habit/reminder |
| sí | draft en Auth/completion | pending/incomplete | session de confirmation | Reanudar ownership → resolveAccount → completion |
| sí | no draft relevante | pending/incomplete | login normal | Contrato existing-account actual mediante Bootstrap |
| sí/recovery session | cualquiera | cualquiera | `passwordRecovery` | Pantalla Nueva contraseña; después Bootstrap decide destino |
| sí | stale local | completed remoto | no | Remote wins → Home; limpiar/reconciliar draft sin materializar habit |
| sí | `remoteInProgress` | cualquiera | signedIn | Reproducir envelope congelado con mismo operationId; nunca recalcular decisión |

## 12. Component ownership futuro

| Componente | Debe hacer | No debe hacer |
|---|---|---|
| `RutioSupabaseClient` | Inicializar SDK una vez | Parsear URL o navegar |
| `AuthRepository` | Exponer operaciones SDK y stream | Decidir onboarding/Home |
| `AuthController` | Sesión global, logout, recovery session base | Consumir draft o hacer completion |
| `AuthCallbackCoordinator` nuevo | Parsear/validar/clasificar/cue callbacks; coordinar cold start | `Navigator.push`, crear operationId, escribir perfil |
| `OnboardingAuthStateMachine` | Ownership funcional del draft, resolver cuenta, replay/completion | Interpretar cualquier URL arbitraria |
| `BootstrapController` | Decisión global session/profile/draft/destination | Competir con una máquina Auth activa |
| `AppStartupGate` | Presentar splash/preparing/destino | Procesar tokens |
| UI Auth | Mostrar estados, resend, recovery/reset | Persistir password o decidir Home directamente |

## 13. Other-device y app-kill

Si el usuario confirma en otro dispositivo, el dispositivo A no recibe callback. V1 no hará polling. La pantalla debe ofrecer “Ya lo he confirmado” para intentar una comprobación/reautenticación controlada o ir a Login con el email prellenado; el draft y operationId permanecen. Si el login posterior produce la misma cuenta, se continúa por el mismo resolver.

Si otro dispositivo completa la cuenta mientras A conserva draft local, Bootstrap/resolveAccount ve `completed` y gana el remoto: Home, sin hábito/reminder duplicados. Si la app muere después de que la RPC llegó al servidor, el `remoteInProgress` existente se reanuda con el mismo user/operation, recibe `alreadyCompletedSameOperation`, reconcilia y limpia.

## 14. Supabase Dashboard y dominio

Futuro, fuera de esta pasada:

- Authentication → URL Configuration: establecer Site URL por entorno, sin inventar el valor de desarrollo.
- Añadir exactamente `https://rutioapp.com/auth/callback` a Redirect URLs de producción.
- Añadir sólo URLs HTTPS de entornos de desarrollo/QA explícitamente controlados.
- Verificar Email confirmation, email templates, sender/SMTP y límites de signup/resend/recovery.
- No habilitar Google/Apple en AUTH-4.

Para la estrategia HTTPS será necesario modificar posteriormente `rutioapp.com` con `apple-app-site-association` y `assetlinks.json`; no hace falta un endpoint que redirija arbitrariamente. La web no se modificó.

## 15. Localización prevista

Ya existen varias strings ES/EN para crear cuenta, login y “Revisa tu correo”. Faltan o deben tiparse para AUTH-4: “Reenviar correo”, cooldown, “Ya lo he confirmado” con semántica de comprobación, enlace caducado, enlace inválido, reintentar, “¿Olvidaste tu contraseña?”, “Nueva contraseña”, “Confirmar contraseña”, reset exitoso, recovery expirado y error de cuenta distinta.

## 16. Matriz de tests previa a implementación

### Unit

- parser y allow-list de callback;
- classifier confirmation vs password recovery;
- malformed/expired/duplicate callback;
- persistencia/resume de emailConfirmation con operationId y sin password;
- resend cooldown/error mapping;
- transiciones de la máquina y rechazo cross-user;
- recovery envelope y replay `alreadyCompletedSameOperation`.

### Widget

- pantalla awaiting confirmation y email persistido;
- resend loading/success/cooldown/error;
- forgot password desde Login;
- nueva contraseña/confirmación, validación y back guard;
- no reiniciar onboarding tras callback.

### Integration/device

- confirmation con app abierta, background y cerrada;
- restart antes de confirmar;
- cold-start callback sin Welcome flash;
- callback duplicado;
- callback caducado/malformado;
- recovery abierta y cold start;
- killed after RPC;
- confirmación en otro dispositivo;
- draft local stale + remote completed;
- login normal, onboarding completion, logout y delete account sin regresión.

## 17. Fases recomendadas

- **AUTH-4A — contratos y callback architecture:** tipos de callback, coordinator, ownership handoff, decision table ejecutable y parser unit-test; sin UI nativa productiva.
- **AUTH-4B — email confirmation:** resend, pantalla completa, reanudación del draft, comprobación “ya confirmado” y errores tipados.
- **AUTH-4C — platform deep links:** Android intent-filter/App Link, iOS Universal Link, asociaciones de dominio y Supabase Redirect URLs.
- **AUTH-4D — password recovery:** entry point Login, callback `passwordRecovery`, reset seguro y destino remoto.
- **AUTH-4E — restart/cold-start hardening:** app abierta/background/killed, dedup, stale/cross-user/logout y splash sin flash.
- **AUTH-4F — QA/cleanup:** matriz física Pixel 9 + iOS, observabilidad segura, documentación y eliminación de paths provisionales.

Cada fase debe ser mergeable, tener tests propios y no cambiar el contrato de completion AUTH-3.

## 18. Riesgos

| Severidad | Riesgo | Mitigación |
|---|---|---|
| CRITICAL | callback procesado por dos autoridades; Welcome flash/carrera Bootstrap | coordinator único, splash cold-start, ownership antes de handoff |
| CRITICAL | callback de otra cuenta contamina draft | boundUserId, user match, fail-closed |
| CRITICAL | perder/recrear operationId | persistir antes de await y replay del mismo envelope |
| CRITICAL | duplicate completion/habit/reminder | RPC/ledger AUTH-3 y dedup por operationId |
| HIGH | app kill durante callback o completion | evento pendiente + `remoteInProgress` + replay |
| HIGH | password/token/URL secreta en logs o storage | contratos efímeros, redacción y logging whitelisted |
| HIGH | stale draft frente a remote completed | remote wins y cleanup controlado |
| HIGH | App/Universal Link mal configurado o hijacking | HTTPS asociado, allow-list exacta, QA por plataforma |
| MEDIUM | resend rate-limit/SMTP no disponible | error tipado, cooldown, verificación dashboard |
| MEDIUM | usuario confirma en otro dispositivo | CTA de comprobación/login, sin polling |
| LOW | divergencia de strings ES/EN | catálogo AUTH-4 antes de implementar UI final |

## 19. Archivos futuros probables

Probablemente se modificarán:

- `lib/data/repositories/auth_repository.dart`;
- `lib/application/auth/auth_controller.dart`;
- `lib/application/bootstrap/bootstrap_controller.dart` y `lib/screens/app_startup_gate.dart`;
- `lib/features/onboarding/application/auth/onboarding_auth_state_machine.dart` y contracts;
- `lib/features/onboarding/presentation/onboarding_auth_step.dart`;
- `lib/features/onboarding/data/onboarding_auth_adapter.dart` y persistence;
- `lib/main.dart`/providers;
- `android/app/src/main/AndroidManifest.xml` y posiblemente `MainActivity`;
- `ios/Runner/Info.plist`, `AppDelegate.swift` y entitlements;
- `lib/l10n/app_es.arb`, `app_en.arb` y generados.

Nuevos archivos previstos: `auth_callback_coordinator.dart`, parser/classifier y sus tests; recovery UI/controller; tests de integración; archivos de asociación web (`assetlinks.json`, `apple-app-site-association`) en la fase HTTPS. No se creó ninguno ahora.

## 20. Verificación de esta pasada

- Documento creado: **YES**, este archivo.
- Cambios de código: **NO**.
- Migrations: **NO** para AUTH-4 preflight/implementation plan; AUTH-3 completion/ledger existentes se conservan.
- Supabase Dashboard futuro: **YES** (Redirect URLs, Site URL por entorno, confirmation/email/SMTP/rate limits); **NO** realizado.
- Modificación de `rutioapp.com`: **NO** en preflight; **YES futuro** para asociaciones HTTPS.
- Google/Apple/Premium/AUTH-5: **NO**.
- `flutter analyze --no-pub`: iniciado, pero no produjo salida final tras más de 80 s y fue interrumpido; no se puede declarar PASS desde este entorno.
- Tests focalizados Auth/Bootstrap/Onboarding: **PASS — 215 tests**.
- `git diff --check`: **PASS**.

## 21. Ready para AUTH-4A

**Implementado y verificado: YES.** La implementación se limita a contratos,
classifier/coordinator, ownership y ajustes mínimos de Bootstrap. No incluye
email UI final, configuración nativa, migrations ni Dashboard.

## AUTH-4A implementation notes

Implementado el contrato de aplicación, sin deep-link platform wiring:

- `lib/features/auth/` contiene `AuthCallbackType`, `AuthCallbackIntent`,
  fallos tipados, `AuthCallbackClassifier`, `AuthCallbackCoordinator` y el
  vocabulario independiente de password recovery.
- El callback canónico queda centralizado en
  `RutioSupabaseConfig.authCallbackUri` (`https://rutioapp.com/auth/callback`).
  El classifier acepta únicamente scheme/host/path canónicos y sólo conserva
  tipo, ubicación segura, timestamp y `isColdStart`; no conserva URI completa,
  tokens, code, OTP, refresh/access token ni password.
- Cold start y app abierta convergen en el mismo coordinator. El coordinator
  mantiene callback pendiente de cold start, evita entregas duplicadas durante
  una ventana corta y ofrece interfaces para el puente AuthController y el
  consumer de `OnboardingAuthStateMachine`; nunca navega ni llama RPC.
- `BootstrapController` expone el ownership AUTH-3 existente como interfaz y
  los drafts reanudables guest (incluido `emailConfirmation`) vuelven a
  `BootstrapDestination.onboarding`. El ownership sigue siendo el guard de
  takeover prematuro; el mismatch de usuario se rechaza fail-closed.
- Password recovery sólo tiene contratos de estado para AUTH-4D; no se llaman
  `resetPasswordForEmail` ni `updateUser`, y no se añadió UI.
- Se añadieron tests de clasificación, allow-list, secretos no retenidos,
  convergencia cold/open, deduplicación y errores tipados. Los tests AUTH,
  onboarding y bootstrap focalizados pasan.

Queda para AUTH-4B la UI/resend/comprobación de confirmación; para AUTH-4C el
listener real, Android/iOS associations y Dashboard redirect configuration; y
para AUTH-4D el entry point y actualización real de password. No hubo cambios
de plataforma, Supabase Dashboard, backend, migrations ni RPC.
