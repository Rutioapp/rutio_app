# Feedback V1 Phase 1B

Fecha: 2026-08-29

## Resumen

Se convirtió `/feedback/new` en un formulario funcional completo de la Fase 1B del Centro de Feedback V1 de Rutio, manteniendo la foundation de la Fase 1A y sin conectar Supabase, Storage ni image picker real.

## Arquitectura implementada

- `lib/features/feedback/application/feedback_form_controller.dart`
  - `FeedbackFormController` como estado local del formulario.
  - Validación pura para descripción con límites de 20 a 5000 caracteres tras `trim()`.
  - Estado `dirty`, `contactAllowed`, `category` y `isSubmitting`.
- `lib/features/feedback/presentation/screens/feedback_form_screen.dart`
  - Pantalla iOS-first con `SafeArea`, scroll y confirmación de salida.
  - `PopScope` para back navigation moderna.
  - CTA temporal aislado mediante callback de éxito.
- `lib/features/feedback/presentation/widgets/feedback_category_card.dart`
  - Card de categoría con estado seleccionado y semántica de selección.
- `lib/features/feedback/presentation/widgets/feedback_screenshot_field.dart`
  - Placeholder visual de captura sin integración real.
- `lib/features/feedback/presentation/screens/feedback_success_screen.dart`
  - Pantalla temporal de éxito local para cerrar el flujo UI.

## Comportamiento del formulario

- Categorías disponibles:
  - bug
  - suggestion
  - improvement
  - other
- Solo una categoría puede quedar seleccionada.
- La descripción:
  - es obligatoria,
  - se valida con `trim()`,
  - requiere entre 20 y 5000 caracteres,
  - muestra contador visible.
- El CTA `Enviar feedback` solo se habilita con categoría elegida y descripción válida.
- El switch de contacto arranca apagado y solo modifica estado local.
- El screenshot field existe como UI placeholder, sin `image_picker`, permisos ni subida.
- El formulario se marca como dirty si cambia categoría, descripción o contacto.
- Si el usuario intenta salir con cambios, aparece confirmación.
- Si no hay cambios, la salida es directa.
- Al enviar, el flujo usa una acción temporal local que navega a `/feedback/success`.

## L10n añadido

Se añadieron claves ES/EN para:

- intro y título de la pantalla nueva,
- texto de guía por categoría,
- label, hint, requirements y contador de descripción,
- placeholder de screenshot,
- bloque de contacto y nota técnica,
- diálogo de salida,
- copy de la pantalla de éxito.

## Tests añadidos

### Application

- estado inicial de categoría,
- estado inicial de contacto,
- selección de categoría,
- exclusión mutua de categorías,
- validación 19/20/5000/5001,
- trim aplicado,
- `canSubmit`,
- dirty state.

### Presentation

- render de las cuatro categorías,
- estado visual de selección,
- copy dinámico por categoría,
- CTA inicialmente desactivado,
- CTA desactivado con descripción inválida,
- CTA activo con categoría + descripción válida,
- switch de contacto funcional,
- screenshot placeholder visible,
- confirmación de salida con cambios,
- salida sin cambios sin confirmación,
- submit temporal aislado.

## Decisiones tomadas

- Se mantuvo la arquitectura ligera de Rutio con `ChangeNotifier` y sin introducir Riverpod o Bloc.
- La pantalla nueva se integra con el router existente de `MaterialApp.routes`.
- La subida real, el historial, el detalle, la edición y la persistencia remota quedan fuera de esta fase.
- La pantalla de éxito es temporal y existe solo para permitir validar el flujo UI.

## Qué queda expresamente aplazado

- Supabase e inserción real.
- Storage.
- `image_picker` real.
- HEIC, compresión, WebP/JPEG y EXIF.
- Historial, detalle y edición de feedback existente.
- Email y respuestas.
- Metadatos técnicos reales del dispositivo y la app.
- Cualquier router nuevo o refactor no relacionado.

## Riesgos detectados

- La navegación temporal a éxito todavía no representa el flujo real de backend.
- El screenshot field es solo visual; cuando llegue Fase 3 habrá que conectar permisos, picker y subida.
- El contador usa longitud cruda y la validez usa `trim()`, que es correcto para el contrato pero conviene mantenerlo alineado al conectar backend.
