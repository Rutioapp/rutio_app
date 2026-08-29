# Feedback V1 Phase 1C

Fecha: 2026-08-29

## Resumen

Se cerró la experiencia visual local del Centro de Feedback V1 sin Supabase, sin Storage, sin persistencia y sin router nuevo.

La Fase 1C completa el recorrido local:

- `/feedback`
- `/feedback/new`
- `/feedback/success`
- `/feedback/mine`
- `/feedback/detail`

Todo el flujo usa estado local, datos mock/presentation y navegación nombrada sobre `MaterialApp.routes`.

## Pantallas completadas

- `FeedbackSuccessScreen`
- `MyFeedbackScreen`
- `FeedbackDetailScreen`

Además, se dejó operativo el formulario de la Fase 1B como origen del submit local.

## Widgets reutilizables creados

- `FeedbackStatusChip`
- `FeedbackProgressIndicator`
- `FeedbackResponseCard`

## Estrategia de datos mock

Se añadió el modelo de dominio `FeedbackReport` para no duplicar tipos de cara a fases posteriores.

Los datos de presentación viven en:

- `FeedbackMockReports.examples`

Ese mock cubre los cuatro estados necesarios:

- `submitted`
- `inReview`
- `resolved`
- `dismissed`

El submit del formulario construye un `FeedbackReport` local en memoria y lo pasa a success mediante `RouteSettings.arguments`.

No existe persistencia real. El flujo sirve para validar UI, navegación y estados.

## Navegación final

- `/feedback` abre la home del Centro de Feedback.
- `/feedback/new` muestra el formulario local.
- `/feedback/success` muestra el cierre visual del submit.
- `/feedback/mine` muestra el historial mock.
- `/feedback/detail` muestra el detalle de un feedback mock.

Desde success:

- `Ver mis envíos` navega a `/feedback/mine`.
- `Volver a Feedback` retorna a `/feedback`.

Desde my feedback:

- tocar una tarjeta abre `/feedback/detail` con el reporte en `arguments`.

## Decisiones de diseño

- Se mantuvo la estética Rutio beige/camel/sage.
- Se reutilizaron tokens de `AppTheme`.
- Se evitó introducir lila específico del feedback.
- Se priorizó SafeArea, scroll y layouts que sobreviven a pantallas pequeñas y Dynamic Type.
- El progreso visual se resolvió con un indicador adaptable en una sola pieza reutilizable.

## Tests

Se añadieron tests para:

- modelo `FeedbackReport`
- formulario existente de Feedback
- success
- my feedback
- detail
- progress indicator

Los tests cubren:

- filtros locales
- navegación hacia mine y detail
- visibilidad condicional de editar/eliminar
- respuesta del equipo
- fallback sin respuesta
- progreso por estados

## Elementos que siguen sin backend

- Supabase
- Storage
- upload de capturas
- image picker real
- persistencia
- RPC
- RLS
- Realtime
- edición real
- eliminación real

## Frontera exacta entre fases

### Fase 1

UI base de Feedback, formulario local y flujo visual completo sin backend.

### Fase 2

Conectar Supabase para crear/leer datos reales, sin cambiar todavía el enfoque visual.

### Fase 3

Conectar el envío real y las imágenes:

- upload
- selección de captura
- metadatos asociados al envío

### Fase 4

Conectar historial/detalle/edición/eliminación reales:

- lectura real de listados
- detalle persistido
- edición real
- borrado real
- estados gobernados por backend

## Riesgos detectados

- El mock local no persiste entre sesiones.
- El detalle y el historial dependen de `arguments` o de la lista mock, no de una fuente remota.
- Cuando llegue Supabase, habrá que sustituir el origen de datos sin romper la navegación ya cerrada.
