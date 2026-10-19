# 02 — hallazgos de seguridad

## P1-S1 — escrituras directas de economía/progreso en contrato fuente

- Estado: **VERIFICADO en SQL fuente; despliegue NO VERIFICABLE**.
- Evidencia: `supabase/sql/supabase_backend_phase_9_schema_patch.sql:449-469` permite insert/update de `user_progress`; `527-541` insert de `xp_events`; `614-628` insert de `currency_events`; `725-745` insert/update de `user_achievements`, todos con ownership por `auth.uid()`.
- Impacto: un usuario autenticado que pueda invocar PostgREST podría modificar su propio XP, saldo o recompensas sin pasar por la lógica económica RPC. No permite cruzar usuarios por la condición `auth.uid()`, pero sí fraude de negocio si esos campos son autoritativos.
- Solución: hacer las tablas económicas RPC-only, separar campos derivados, validar invariantes en funciones SECURITY DEFINER con `search_path=''`, y probar grants efectivos.

## P1-S2 — Premium no está autorizado en servidor

- Estado: **VERIFICADO como ausencia en código fuente inspeccionado; explotación remota NO VERIFICABLE**.
- Evidencia: `lib/features/premium/domain/premium_access_policy.dart:14-19` decide acceso sólo en Flutter; `supabase/migrations/20260901150000_weekly_report_read_api.sql:121-122` dice que el shaping de entitlement es futuro.
- Impacto: cliente modificado puede ocultar el gate local y solicitar RPC/recursos si éstos sólo comprueban autenticación.
- Solución: validar entitlement en RPC/Edge Function con una fuente servidor (webhook/estado sincronizado), o limitar al servidor los datos Premium; añadir tests Free/Premium.

## P1-S3 — suite de regresión no verde

- Estado: **VERIFICADO**.
- Evidencia: `flutter test --reporter compact` terminó con 2.454 tests ejecutados y 35 fallos; `flutter analyze` terminó con 34 issues informativos/warnings.
- Impacto: cambios de auth, UI o sincronización pueden llegar sin señal fiable.
- Solución: guardar salida por test, aislar cada fallo, corregir o marcar explícitamente tests obsoletos y exigir cero fallos en CI.

## P2-S1 — credencial de firma local presente

- Estado: **VERIFICADO local; no confirmado como filtración Git**.
- Evidencia: existe `upload-keystore.jks`; `git ls-files` no lo lista y `.gitignore` lo ignora. Debe considerarse secreto operativo.
- Impacto: si se comparte/respaldó fuera del control, compromete releases Android y actualización de app.
- Solución: retirar copias no autorizadas, custodiar en secret manager, comprobar historial remoto y rotar sólo con procedimiento de release aprobado.

## P2-S2 — copias no versionadas de Firebase config

- Estado: **VERIFICADO local**: `android/app/google-services.json.backup-*` aparece sin track en `git status`.
- Impacto: exposición accidental en zip/backup; los identificadores Firebase no sustituyen una service key, pero revelan configuración del proyecto.
- Solución: limpiar/mover copias fuera del workspace y revisar artefactos/CI sin publicar su contenido.

## Riesgos potenciales

- **P1:** `supabase/config.toml` fija password mínimo 6, `enable_confirmations=false`, `secure_password_change=false`, `max_frequency=1s`; puede ser sólo local, por lo que el estado productivo es no verificable.
- **P1:** no se encontró enforcement general de rate limiting para PostgREST/RPC/Storage; los límites visibles cubren Auth local.
- **P2:** `SharedPreferences` almacena estado y borradores; no se encontró `flutter_secure_storage`. El SDK gestiona sesión, pero el contenido de diario/cache requiere clasificación y política de backup.
- **P2:** falta CI/CD visible bajo `.github`; controles de secret scanning y dependencias no están demostrados.
