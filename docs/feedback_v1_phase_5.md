# Rutio Feedback V1 - Phase 5

Fecha: 2026-08-30

## Objetivo

Cerrar el flujo administrativo real de Feedback V1 usando Supabase Studio como herramienta operativa, sin crear panel administrativo, sin Edge Functions, sin Realtime y sin emails.

## Alcance real de la fase

El flujo canónico de Feedback V1 es:

- `submitted`
- `in_review`
- `resolved`
- `dismissed`

No existe reapertura en V1.

## Flujo de estados

### Estados permitidos

- `submitted`
- `in_review`
- `resolved`
- `dismissed`

### Transiciones válidas

- `submitted -> in_review`
- `in_review -> resolved`
- `in_review -> dismissed`

### Transiciones prohibidas

- `submitted -> resolved`
- `submitted -> dismissed`
- `in_review -> submitted`
- `resolved -> cualquier cambio`
- `dismissed -> cualquier cambio`

Si una fila ya es terminal, debe permanecer terminal.

## Flujo administrativo en Supabase Studio

### Paso 1: localizar feedback pendiente

Abrir:

1. `Table Editor`
2. `public.feedback_reports`
3. filtrar `status = submitted`

### Paso 2: pasar a revisin

Cambiar:

- `submitted -> in_review`

Al guardar, la base de datos debe fijar:

- `review_started_at = now()`
- `closed_at = null`

### Paso 3: investigar

Revisar el feedback fuera de la tabla, usando el detalle del caso.

### Paso 4: escribir respuesta

Con `status = in_review`, escribir `team_response`.

Debe permitirse editarla mientras siga en revisin.

### Paso 5: cerrar

Cambiar:

- `in_review -> resolved`
- `in_review -> dismissed`

Al guardar, la base de datos debe:

- exigir `team_response` no vacia tras `trim`
- fijar `closed_at` automticamente
- conservar `review_started_at`
- actualizar `updated_at`

## Team response

### submitted

- `team_response` debe permanecer `null`

### in_review

- `team_response` puede escribirse y modificarse

### resolved / dismissed

- `team_response` debe existir
- `btrim(team_response)` no puede quedar vacio
- tras el cierre queda inmutable

No es valido almacenar solo espacios como respuesta.

## Timestamps

Los timestamps autoritativos son:

- `created_at`
- `updated_at`
- `review_started_at`
- `closed_at`

### submitted

- `review_started_at = null`
- `closed_at = null`

### in_review

- `review_started_at != null`
- `closed_at = null`

### resolved / dismissed

- `review_started_at != null`
- `closed_at != null`

Los timestamps administrativos no deben requerir escritura manual desde Supabase Studio.

## Reflejo en la app

La app no usa Realtime para Feedback V1. El reflejo correcto depende de refresh explcito.

### Caso A

1. La app muestra feedback `submitted`
2. En Supabase Studio cambiar `submitted -> in_review`
3. Hacer refresh en Rutio
4. Debe aparecer `En revisin`
5. Los botones `Editar` y `Eliminar` deben desaparecer
6. `review_started_at` debe verse reflejado

### Caso B

1. Con el feedback en `in_review`, escribir `team_response` en Supabase Studio
2. Hacer refresh en Rutio
3. La respuesta debe aparecer en el detalle

### Caso C

1. Cambiar `in_review -> resolved`
2. Hacer refresh en Rutio
3. Debe aparecer `Resuelto`
4. `closed_at` debe verse reflejado
5. `team_response` debe seguir visible

### Caso D

1. Repetir con otro feedback
2. Cambiar `in_review -> dismissed`
3. Hacer refresh en Rutio
4. Debe aparecer `Descartado`

## My Feedback y filtros

Los filtros existentes deben seguir funcionando con estados reales:

- `Todos`: incluye todos
- `Enviados`: `submitted`
- `En revisin`: `in_review`
- `Cerrados`: `resolved` + `dismissed`

Tras modificar estados desde Supabase Studio, un pull-to-refresh en `MyFeedback` debe reflejar el cambio.

## Screenshot privado

Si existe `screenshot_path`, debe conservarse en `in_review`, `resolved` y `dismissed`.

La app puede seguir cargando la imagen mediante signed URL.

No eliminar manualmente screenshots desde Storage solo por estar activos o cerrados.

## Cierre invlido

Supabase Studio debe fallar si se intenta:

- `in_review -> resolved` sin `team_response`
- `in_review -> dismissed` sin `team_response`

Tambin debe fallar:

- `submitted -> resolved`
- `submitted -> dismissed`

El error es intencionado y forma parte del contrato.

## Terminales inmutables

Tras `resolved` o `dismissed`, no debe poder modificarse:

- `description`
- `contact_allowed`
- `screenshot_path`
- `category`
- `team_response`
- `status`
- timestamps

## Orden administrativo recomendado

1. pasar a `in_review`
2. investigar
3. escribir `team_response`
4. guardar
5. cambiar `status` a `resolved` o `dismissed`
6. guardar

Este orden evita cerrar una fila sin respuesta.

## Daily Admin Flow

- filtrar `submitted`
- revisar los ms antiguos o con mayor prioridad
- pasar a `in_review`
- investigar
- responder
- cerrar
- comprobar el resultado en Rutio

## Qu hacer si Supabase Studio devuelve error

1. No forzar el guardado.
2. Revisar si la transicin es una de las prohibidas.
3. Confirmar que `team_response` no sea vacia al cerrar.
4. Confirmar que la fila no sea terminal.
5. Repetir la operacin con el orden correcto.

Si el error aparece en una transicin permitida, tratarlo como defecto real del backend y no como un problema de UI.

## Validacin manual exacta

### TEST RESOLVED

1. Crear feedback desde Rutio
2. Confirmar `submitted`
3. En Supabase cambiar a `in_review`
4. Confirmar `review_started_at`
5. Refresh en Rutio
6. Comprobar `En revisin`
7. Escribir `team_response`
8. Refresh en Rutio
9. Comprobar la respuesta
10. En Supabase cambiar a `resolved`
11. Confirmar `closed_at`
12. Refresh en Rutio
13. Comprobar `Resuelto` + respuesta

### TEST DISMISSED

1. Crear un segundo feedback
2. Cambiar `submitted -> in_review`
3. Escribir `team_response`
4. Cambiar `in_review -> dismissed`
5. Comprobar `Descartado` en Rutio
6. Comprobar el filtro `Cerrados`

### NEGATIVOS

- `submitted -> resolved` debe fallar
- cierre sin response debe fallar
- editar una fila terminal debe fallar

## Validacin tcnica

Ejecutar:

- `flutter analyze`
- `flutter test test/features/feedback`
- `git diff --check`

Comprobar tambin:

- `supabase migration list --linked`

Debe seguir:

- Local == Remote

No ejecutar `db push` si no existe una migracin nueva legtima.

## Emails

Todava no forman parte de esta fase.

No implementar:

- `feedback_email_jobs`
- Database Webhooks
- Edge Functions
- Resend / SendGrid
- `no-reply@rutioapp.com`

Eso pertenece a Fase 6.

## Criterio de cierre

Fase 5 puede considerarse cerrada cuando:

- `submitted -> in_review` funciona en Studio
- `review_started_at` se establece de forma automtica
- `team_response` funciona en `in_review`
- el cierre sin respuesta falla
- `in_review -> resolved` funciona con respuesta
- `in_review -> dismissed` funciona con respuesta
- `closed_at` se establece de forma automtica
- los estados finales son terminales
- la app refleja los cambios mediante refresh
- `Editar` y `Eliminar` desaparecen en `in_review`
- `resolved` y `dismissed` se muestran correctamente
- los filtros funcionan con estados reales
- el screenshot sigue accesible
- no hay emails todavia
- no hay panel administrativo
- no hay UI polish
- la documentacin operativa existe
- los tests existentes siguen pasando

