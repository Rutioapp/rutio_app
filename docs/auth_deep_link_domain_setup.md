# AUTH-4C — producción de deep links

## Contrato

Callback canónico único: `https://www.rutioapp.com/auth/callback`.

Rutio acepta únicamente `https`, host `www.rutioapp.com` y path exacto
`/auth/callback`. La URI completa sólo vive en memoria durante el handoff;
no se registra ni se persiste.

## Supabase Dashboard (manual)

En Authentication → URL Configuration: Site URL `https://www.rutioapp.com` y
Redirect URLs con `https://www.rutioapp.com/auth/callback`. Confirmar Email
confirmation y revisar templates de confirmation/recovery/resend para que no
sustituyan el redirect. No se modifica el Dashboard desde este repositorio.

### Requisito de lanzamiento V1

Email provider: `enabled`. Confirm Email: **OFF**. La confirmación está
preparada como capability dormida y no bloquea signup, login, Bootstrap,
completion ni entrada a Home. Mantener como Redirect URL permitida
`https://www.rutioapp.com/auth/callback` para futuros Auth flows.

## Android App Links

El paquete es `com.rutio.app`. `MainActivity` es la única Activity, permanece
`singleTop` y tiene un intent filter HTTPS con `autoVerify=true`.

Publicar en `https://www.rutioapp.com/.well-known/assetlinks.json`, sin redirect,
HTTPS y `Content-Type: application/json`:

```json
[{"relation":["delegate_permission/common.handle_all_urls"],"target":{"namespace":"android_app","package_name":"com.rutio.app","sha256_cert_fingerprints":["RELEASE_OR_PLAY_APP_SIGNING_SHA256"]}}]
```

El fingerprint debug disponible en esta máquina es
`96:F2:B6:8C:36:90:87:3A:D8:48:11:A8:FC:9E:C3:B9:13:EC:39:8E:DA:45:CB:B2:B9:0C:DE:0C:47:9A:9D:F5`.
No se debe publicar como producción salvo que corresponda al certificado
instalado. El fingerprint release/Play App Signing sigue pendiente. Obtenerlo:

```powershell
keytool -list -v -keystore <release-keystore> -alias <alias> | Select-String SHA256
```

Para Play App Signing, copiar el SHA-256 de Play Console → App integrity.

```powershell
adb shell pm get-app-links com.rutio.app
adb shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://www.rutioapp.com/auth/callback?type=signup"
```

Usar callbacks sanitizados en QA; nunca tokens reales en comandos o logs.

## iOS Universal Links

El bundle ID es `com.rutio.app`, Team ID actual: `7LKQG9DY6W`. Associated
Domains está configurado como `applinks:www.rutioapp.com` en
`Runner/Runner.entitlements`.

Publicar `https://www.rutioapp.com/.well-known/apple-app-site-association` sin
extensión `.json`, sin redirect y con `Content-Type: application/json`:

```json
{"applinks":{"details":[{"appIDs":["7LKQG9DY6W.com.rutio.app"],"components":[{"/":"/auth/callback"}]}]}}
```

Instalar en dispositivo real y abrir un enlace sanitizado desde Mail, Notes o
Safari. Confirmar Associated Domains y validar la respuesta AASA pública. No
se afirma soporte de validación Universal Links en Simulator.

## Estado de producción y QA

Los endpoints ya están desplegados y validados en producción:

- `https://www.rutioapp.com/.well-known/assetlinks.json` → HTTP 200,
  `application/json`, sin redirect.
- `https://www.rutioapp.com/.well-known/apple-app-site-association` → HTTP
  200, `application/json`, sin redirect.

## QA, observabilidad y bloqueos

Probar app abierta, background y cold start, sin Welcome flash. El receiver
registra `[AUTH_DEEP_LINK]` y `[AUTH_CALLBACK]` con tipo, estado, operation ID
y usuario abreviados; nunca URI, query, fragment, code, access token, refresh
token u OTP. Casos: confirmation, recovery, allowlist, duplicado
initial+runtime, expirado, cross-user, logout+callback viejo y arranque normal.

Los fingerprints release/Play y la configuración del Dashboard son pasos
externos pendientes. AUTH-4D implementará la UI/reset; aquí sólo queda preparada la
clasificación `passwordRecovery`. Google, Apple y custom schemes quedan fuera.
