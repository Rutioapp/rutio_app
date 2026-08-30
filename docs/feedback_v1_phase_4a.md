# Rutio Feedback V1 - Phase 4A

Fecha: 2026-08-30

## Objetivo

Sustituir el historial mock de `MyFeedbackScreen` por lectura real desde `public.feedback_reports`, manteniendo la UI de la fase anterior y sin tocar migraciones, RLS, Storage, edición, borrado, signed URLs, emails ni Realtime.

## Qué cambió

- `FeedbackRepository` expone ahora una operación read-only:
  - `getMyFeedback()`
- `SupabaseFeedbackRepository` implementa la lectura real contra `feedback_reports`.
- Se añadió un controller local para el historial:
  - `FeedbackMineController`
  - `FeedbackMineState`
  - `FeedbackMineStatus`
  - `FeedbackMineFilter`
- `MyFeedbackScreen` deja de leer `FeedbackMockReports` en flujo productivo.
- `FeedbackDetailScreen` sigue recibiendo el `FeedbackReport` por `RouteSettings.arguments`, pero ahora sin mostrar el `screenshot_path` técnico.

## Fuente de verdad

- `getMyFeedback()` usa la sesión autenticada existente.
- La consulta ordena por `created_at DESC`.
- El mapping reutiliza `FeedbackReport.fromSupabaseRow`.
- Los valores desconocidos de `category` o `status` fallan de forma controlada.

## Estado y filtros

- El historial tiene estados explícitos:
  - `initial`
  - `loading`
  - `loaded`
  - `empty`
  - `error`
- Los filtros siguen siendo locales sobre la lista ya descargada:
  - `Todos`
  - `Enviados`
  - `En revisión`
  - `Cerrados`
- `Cerrados` agrupa:
  - `resolved`
  - `dismissed`

## Refresh

- `MyFeedbackScreen` incorpora pull-to-refresh.
- El refresh vuelve a ejecutar `getMyFeedback()`.
- No hay Realtime en esta fase.

## Comportamiento tras un nuevo envío

- `FeedbackSuccessScreen` sigue navegando a `/feedback/mine`.
- `MyFeedbackScreen` carga desde Supabase al construirse.
- Por tanto, un feedback recién enviado aparece al abrir el historial sin insertar manualmente nada en una lista local.

## Detalle

- `FeedbackDetailScreen` sigue funcionando por argumentos.
- No hay fetch por id independiente todavía.
- No hay signed URL para screenshots todavía.
- La pantalla no expone el path técnico de Storage al usuario.

## Mocks

- `FeedbackMockReports` ya no se usa productivamente en:
  - `MyFeedbackScreen`
  - `FeedbackDetailScreen`
- Puede seguir existiendo como fixture para tests y previews.

## Errores visibles

- Se mapean y localizan:
  - sesión no autenticada
  - error de red
  - error de PostgREST
  - error de mapping
  - error desconocido
- La UI muestra un estado recuperable con acción de reintento.

## Tests añadidos o ajustados

- Repository
  - lectura de `feedback_reports`
  - usuario autenticado requerido
  - orden `created_at DESC`
  - mapping de múltiples rows
  - estados `submitted`, `in_review`, `resolved`, `dismissed`
  - `screenshot_path` nullable
  - `team_response` nullable
  - error de Supabase mapeado
  - enum desconocido falla de forma controlada
- Controller
  - `initial`
  - `loading`
  - `loaded`
  - `empty`
  - `error`
  - `retry`
  - `refresh`
  - filtros
- Widget
  - loading
  - empty
  - error
  - retry
  - lista real simulada
  - orden
  - filtros
  - tap al detalle
  - detalle recibe el `FeedbackReport` correcto

## Validación

- `flutter analyze`: OK
- `flutter test test/features/feedback`: OK
- `git diff --check`: OK

## Prueba real

No ejecutada desde esta sesión.

Motivo:

- no tenía una sesión autenticada reutilizable desde el CLI para hacer una lectura real y read-only contra Supabase sin tocar datos.

Checklist manual recomendado:

1. Iniciar sesión con un usuario real en la app.
2. Crear un feedback desde el formulario.
3. Abrir `Mis envíos`.
4. Confirmar que aparece ese registro recién creado.
5. Confirmar que no aparecen registros de otro usuario.

## Riesgos residuales

- La validación real en producción/dev con sesión autenticada sigue pendiente.
- `FeedbackDetailScreen` todavía no resuelve signed URLs para screenshots.
- Edición y eliminación siguen pendientes de Fase 4B.
- Realtime sigue fuera de alcance.

## Qué queda para 4B

- edición real
- eliminación real
- signed URLs para screenshots
- fetch adicional por id si hace falta
- pulido de estados de detalle si la nueva UX lo requiere
- cualquier sincronización más fina entre historial y detalle

