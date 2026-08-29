# Feedback V1 Phase 1A

Fecha: 2026-08-29

## Resumen

Se creó la foundation inicial del Centro de Feedback dentro de la arquitectura real de Rutio, sin añadir Supabase, storage, migraciones ni un router nuevo.

## Arquitectura creada

- `lib/features/feedback/domain/` con los enums base `FeedbackCategory` y `FeedbackStatus`.
- `lib/features/feedback/presentation/screens/` con la home funcional y una pantalla futura mínima para cubrir rutas todavía no implementadas.
- `lib/features/feedback/presentation/widgets/` con una tarjeta reutilizable para las acciones de la home.
- Navegación integrada con `MaterialApp.routes` y `Navigator.pushNamed`, manteniendo el patrón actual del proyecto.

## Rutas registradas

- `/feedback`
- `/feedback/new`
- `/feedback/success`
- `/feedback/mine`

En esta fase, solo `/feedback` quedó completamente implementada.

## Integración con drawer

- El acceso de soporte del drawer dejó de abrir Google Forms.
- El tap ahora navega internamente a `/feedback`.
- No se modificó la posición ni el estilo general del drawer.

## Decisiones tomadas

- Se respetó el router estático actual de Rutio.
- Se evitó crear controllers, repositories o storage todavía.
- Se usaron tokens existentes de `AppTheme` y la paleta beige/camel/sage.
- La home de Feedback se diseñó como una pantalla iOS-first, con `SafeArea` y áreas táctiles amplias.
- Las rutas futuras se cubrieron con una pantalla placeholder mínima para no romper compilación ni navegación.

## Archivos creados

- `lib/features/feedback/domain/feedback_category.dart`
- `lib/features/feedback/domain/feedback_status.dart`
- `lib/features/feedback/presentation/screens/feedback_home_screen.dart`
- `lib/features/feedback/presentation/screens/feedback_future_screen.dart`
- `lib/features/feedback/presentation/widgets/feedback_action_tile.dart`
- `test/features/feedback/domain/feedback_enums_test.dart`
- `test/features/feedback/presentation/feedback_home_screen_test.dart`
- `docs/feedback_v1_phase_1a.md`

## Archivos modificados

- `lib/main.dart`
- `lib/widgets/app_view_drawer.dart`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/gen/app_localizations.dart`
- `lib/l10n/gen/app_localizations_es.dart`
- `lib/l10n/gen/app_localizations_en.dart`
- `test/app_view_drawer_test.dart`

## Tests añadidos

- El drawer abre la feature interna de Feedback.
- `FeedbackHomeScreen` renderiza sus dos acciones.
- `FeedbackHomeScreen` navega a `/feedback/new`.
- `FeedbackHomeScreen` navega a `/feedback/mine`.
- Los enums validan el mapeo Dart/Postgres.

## Elementos aplazados a 1B / 1C

- Supabase.
- Migraciones SQL.
- Storage y subida de imágenes.
- Historial, filtros y detalle.
- Edición y eliminación.
- Formulario real de envío.
- Pantalla de éxito real.

## Desviaciones respecto a la auditoría

- Se optó por una pantalla futura placeholder compartida en lugar de introducir un router adicional o una arquitectura paralela.
- No se añadió `onGenerateRoute` porque esta fase solo necesitaba rutas estáticas compatibles con el router actual.

## Riesgos detectados

- La pantalla futura placeholder no representa todavía el flujo real de envío.
- El servicio legacy de Google Forms queda obsoleto, aunque todavía existe en el código hasta una limpieza posterior.

