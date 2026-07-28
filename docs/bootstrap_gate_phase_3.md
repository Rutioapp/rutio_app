# Bootstrap Gate Phase 3A

## 1. Objetivo

La Fase 3A introduce un Bootstrap Gate explícito para decidir la ruta inicial de Rutio solo cuando la sesión, el scope local, el estado local y el perfil remoto del usuario autenticado están resueltos.

## 2. Arquitectura del Bootstrap Gate

```text
App
└── BootstrapGate
    ├── sesión no resuelta → Preparando tu espacio…
    ├── sin sesión → Welcome/Auth
    └── con sesión
        ├── seleccionar scope
        ├── cargar estado local
        ├── cargar perfil remoto
        └── decidir
            ├── pending/in_progress → Onboarding
            └── completed → Home
```

`BootstrapController` contiene el estado tipado y la ejecución con epoch. `AppStartupGate` solo renderiza preparación, error recuperable o el destino final.

## 3. Estados y transiciones

Estados:

- `idle`
- `resolvingSession`
- `selectingUserScope`
- `loadingLocalState`
- `loadingRemoteProfile`
- `decidingDestination`
- `ready`
- `failed`

Cada ejecución incrementa `runId`. Un resultado solo puede escribir estado si su `runId` sigue vigente.

## 4. Responsabilidades

`AuthController` expone la resolución observable de sesión.

`UserStateStore` selecciona y carga el scope local.

`ProfileRepository` lee y actualiza el contrato remoto de onboarding.

`BootstrapController` coordina la decisión.

`AppStartupGate` renderiza la pantalla adecuada.

## 5. Resolución de sesión

`AuthController` distingue `unresolved`, `resolvedWithoutUser` y `resolvedWithUser`. El bootstrap espera `initialSessionResolved` en lugar de usar polling o delays arbitrarios.

## 6. Selección de scope

Para usuarios autenticados, el bootstrap llama a `switchLocalScope(userId)` y espera a que el scope local quede cargado. Después comprueba que el scope y el usuario local pertenecen al usuario de la ejecución vigente.

## 7. Perfil remoto

Para cuentas autenticadas se llama a `ProfileRepository.fetchCurrentProfile()`. Se tratan de forma explícita perfil ausente, error de red, RLS, respuesta inválida, sesión obsoleta y errores desconocidos. Ningún error se convierte en `completed`.

## 8. Matriz de decisión

```text
Sin sesión + onboardingDone=false → welcome
Sin sesión + onboardingDone=true  → authentication
Con sesión + pending              → onboarding
Con sesión + in_progress          → onboarding
Con sesión + completed            → home
Con sesión + perfil ausente/error → failed recuperable
```

Para usuarios autenticados, `UserStateStore.onboardingDone` no decide la ruta.

## 9. Pantalla de preparación

Mientras el destino no está listo se muestra una pantalla propia con `Preparando tu espacio…`, safe areas, soporte claro/oscuro, indicador indeterminado y sin contenido de Home, Welcome u onboarding detrás.

## 10. Onboarding temporal

`TemporaryOnboardingScreen` permite validar el destino `onboarding`. El botón `Continuar` llama a `markOnboardingCompleted`, espera la respuesta, confirma `completed` y deja el bootstrap en `home`.

## 11. Errores y reintentos

Los errores remotos muestran un mensaje amigable y acción `Reintentar`. El retry inicia una nueva ejecución vigente. No hay política offline definitiva en esta fase.

## 12. Cambios de cuenta

Un cambio de usuario o logout dispara una nueva ejecución. Los resultados antiguos se descartan por `runId` y por comparación del usuario actual.

## 13. Navegación

`/root`, `/home`, `/shop` y la ruta antigua de `AuthGate` pasan por `AppStartupGate`. Una entrada directa no construye Home o Shop hasta que el bootstrap esté `ready`.

## 14. Tests añadidos

Se añadió `test/application/bootstrap/bootstrap_controller_test.dart` con cobertura de sesión no resuelta, guest, estados remotos, errores, retry, cambio de cuenta, logout durante carga, onboarding temporal, doble pulsación, ruta directa y no construcción prematura de Home.

## 15. Limitaciones de la Fase 3A

No se coordina todavía la carga remota completa de hábitos, wallet, cosméticos, logs, timezone, streak protection ni política offline permanente.

## 16. Trabajo previsto para Fase 3B

La Fase 3B deberá añadir coordinación de datos remotos completos antes de Home, definir política offline contractual, integrar cargas de hábitos, wallet y cosméticos, y revisar precargas visuales del Home sin permitir flashes.
