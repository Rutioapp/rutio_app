# Feedback V1 Phase 2B

Fecha: 2026-08-29

## 1. Resumen

Se creó la foundation Supabase de Feedback V1 sin tocar Flutter, sin modificar `lib/`, sin aplicar nada al remoto y sin crear Edge Functions.

La fase deja listo el contrato de base de datos para:

- enums de feedback,
- tabla `public.feedback_reports`,
- trigger autoritativo,
- RLS y grants mínimos,
- RPCs `update_my_feedback` y `delete_my_feedback`,
- bucket privado `feedback-screenshots`,
- policies de Storage para select/insert/delete,
- tests SQL de contrato, transiciones y Storage.

## 2. Archivo de migración creado

- [`supabase/migrations/20260829153540_create_feedback_v1_foundation.sql`](/D:/dev/alpha/rutio_app/supabase/migrations/20260829153540_create_feedback_v1_foundation.sql)

## 3. Tests creados

- [`supabase/tests/feedback_reports_contract_verification.sql`](/D:/dev/alpha/rutio_app/supabase/tests/feedback_reports_contract_verification.sql)
- [`supabase/tests/feedback_reports_transitions_verification.sql`](/D:/dev/alpha/rutio_app/supabase/tests/feedback_reports_transitions_verification.sql)
- [`supabase/tests/feedback_reports_storage_verification.sql`](/D:/dev/alpha/rutio_app/supabase/tests/feedback_reports_storage_verification.sql)

## 4. Modelo final de permisos

### `public.feedback_reports`

- `authenticated`
  - `SELECT`: sí, solo propias filas.
  - `INSERT`: sí, solo propias filas y con estado inicial válido.
  - `UPDATE`: no.
  - `DELETE`: no.
- `anon`
  - sin acceso.

### RPCs

- `public.update_my_feedback`
  - `EXECUTE` para `authenticated`.
  - sin `EXECUTE` para `anon` y `public`.
- `public.delete_my_feedback`
  - `EXECUTE` para `authenticated`.
  - sin `EXECUTE` para `anon` y `public`.

### `storage.objects`

- `authenticated`
  - `SELECT`: sí, solo objetos de `feedback-screenshots` dentro de su namespace y con `owner_id` propio.
  - `INSERT`: sí, solo objetos con estructura canonical de screenshot en su namespace.
  - `DELETE`: sí, solo objetos del bucket, de su namespace, `owner_id` propio, y no referenciados por `public.feedback_reports`.
  - `UPDATE`: no policy creada.
- `anon`
  - sin acceso.

## 5. Implementación del trigger

Se creó `app_private.enforce_feedback_report_contract()` como trigger `BEFORE INSERT OR UPDATE` para `public.feedback_reports`.

### Inserción

- fuerza `status = submitted`,
- rechaza `team_response` no nulo,
- rechaza `review_started_at` y `closed_at` no nulos,
- normaliza `description` con `btrim()`,
- valida longitud 20..5000,
- valida `technical_context` como objeto JSON,
- valida `screenshot_path` contra `user_id` + `feedback_id`,
- asigna timestamps autoritativos.

### Actualización

- bloquea cualquier cambio en filas terminales,
- protege `id`, `user_id`, `category`, `created_at` y `technical_context`,
- permite edición de usuario solo mientras está `submitted`,
- permite transición `submitted -> in_review`,
- permite transición `in_review -> resolved/dismissed` solo con `team_response` real,
- normaliza `team_response` con `btrim()` cuando se escribe,
- asigna `review_started_at` y `closed_at` desde PostgreSQL,
- actualiza `updated_at` en cada modificación válida.

### Decisión de estado final

- `resolved` y `dismissed` son terminales e inmutables.
- `submitted` no puede saltar directamente a cerrado.
- `in_review -> submitted` está bloqueado.

## 6. Implementación de RPC

### `update_my_feedback`

- `SECURITY DEFINER`,
- `search_path` cerrado,
- requiere `auth.uid()`,
- bloquea con `FOR UPDATE`,
- no filtra entre inexistente y no propio,
- solo permite editar filas `submitted`,
- cambia únicamente `description`, `screenshot_path` y `contact_allowed`,
- devuelve la fila actualizada canonicalizada.

### `delete_my_feedback`

- `SECURITY DEFINER`,
- `search_path` cerrado,
- requiere `auth.uid()`,
- bloquea con `FOR UPDATE`,
- solo permite borrar filas `submitted`,
- borra solo `public.feedback_reports`,
- devuelve `screenshot_path` para limpieza posterior de Storage.

## 7. Implementación de Storage policies

### Bucket

- `feedback-screenshots`
- privado
- límite: 5 MB
- MIME permitidos:
  - `image/jpeg`
  - `image/png`
  - `image/webp`

### `SELECT`

- bucket correcto,
- `owner_id = auth.uid()`,
- primer folder igual a `auth.uid()`.

### `INSERT`

- bucket correcto,
- `owner_id = auth.uid()`,
- primer folder igual a `auth.uid()`,
- exactamente dos folders,
- segundo folder UUID válido,
- filename `screenshot_<uuid>.<ext>`,
- extensiones permitidas:
  - `jpg`
  - `jpeg`
  - `png`
  - `webp`

### `DELETE`

- bucket correcto,
- `owner_id = auth.uid()`,
- primer folder igual a `auth.uid()`,
- el `name` no puede estar actualmente referenciado como `screenshot_path` por `public.feedback_reports`.

## 8. Estrategia de DELETE Storage

Se eligió la estrategia pedida:

- no hay `DELETE FROM storage.objects` en la migración,
- no hay helper de borrado de metadata de Storage,
- la eliminación real de objetos se hará después vía API de Supabase Storage,
- una captura actual no puede borrarse directamente si sigue referenciada,
- una captura reemplazada o huérfana sí puede borrarse,
- borrar un feedback primero libera su captura para que luego sea eliminable.

## 9. Tests ejecutados

### Ejecutados realmente

- `git diff --check` sobre los archivos nuevos: sin errores.
- `supabase db push --dry-run`

### Resultado exacto del dry-run

```
DRY RUN: migrations will *not* be pushed to the database.
Connecting to remote database...
Finished supabase db push.
Would push these migrations:
 • 20260829153540_create_feedback_v1_foundation.sql
```

### No ejecutados aquí

- los tests SQL de contrato/transiciones/Storage,
- porque `supabase status` no pudo conectar al daemon de Docker local.

### Error local encontrado

- `supabase status` falló con:
  - `the system cannot find the file specified`
  - falta el pipe `docker_engine`

## 10. Problemas detectados

- No hay Docker local disponible en esta máquina, así que no pude levantar Supabase local ni correr los SQL tests contra una base real.
- Por ese motivo, la validación quedó en:
  - revisión estática,
  - `git diff --check`,
  - `supabase db push --dry-run`.

## 11. Riesgos o dudas restantes

- Falta correr la suite SQL contra una base real para confirmar detalles finos de `storage.objects` y de la firma exacta de algunas funciones del schema de Storage.
- Si Supabase Storage en este entorno expone alguna variación de esquema respecto a `owner_id` o columnas auxiliares, habrá que ajustar los tests o la policy.
- El contrato de Storage queda deliberadamente estricto para `INSERT` y deliberadamente más amplio para `DELETE`, tal como pidió la fase.

## 12. Archivos creados o modificados

- [`supabase/migrations/20260829153540_create_feedback_v1_foundation.sql`](/D:/dev/alpha/rutio_app/supabase/migrations/20260829153540_create_feedback_v1_foundation.sql)
- [`supabase/tests/feedback_reports_contract_verification.sql`](/D:/dev/alpha/rutio_app/supabase/tests/feedback_reports_contract_verification.sql)
- [`supabase/tests/feedback_reports_transitions_verification.sql`](/D:/dev/alpha/rutio_app/supabase/tests/feedback_reports_transitions_verification.sql)
- [`supabase/tests/feedback_reports_storage_verification.sql`](/D:/dev/alpha/rutio_app/supabase/tests/feedback_reports_storage_verification.sql)
- [`docs/feedback_v1_phase_2b.md`](/D:/dev/alpha/rutio_app/docs/feedback_v1_phase_2b.md)
