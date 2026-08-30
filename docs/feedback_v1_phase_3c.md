# Rutio Feedback V1 - Phase 3C

Fecha: 2026-08-30

## 1. Auditoría final del flujo

Flujo auditado:

- `FeedbackFormScreen`
- `FeedbackFormController`
- `FeedbackImageService` cuando hay captura
- `FeedbackStorageService` cuando hay captura
- `SupabaseFeedbackRepository`
- `public.feedback_reports`
- `FeedbackSuccessScreen`

Resultado de la auditoría:

- La presentación no contiene lógica directa de Supabase, compresión ni Storage.
- La lógica de captura, preparación y subida vive en `data/` y la orquesta el controller.
- El success solo se navega cuando el `INSERT` devuelve una fila real y el controller recibe un `FeedbackReport` real.

## 2. Contrato sin captura

Validado en código y tests:

- categoría válida
- descripción válida
- `contactAllowed`
- `technical_context`
- UUID generado antes del insert
- `screenshot_path = null`
- `insert` real
- `status = submitted`
- success con `FeedbackReport` real

No se ejecuta Storage en este caso.

## 3. Contrato con captura

Validado en código y tests:

- selección local
- preview local
- sustitución
- retirada
- procesamiento JPEG
- upload
- insert DB
- success

Contrato de path:

- bucket: `feedback-screenshots`
- path: `<user_id>/<feedback_id>/screenshot_<uuid>.jpg`
- `contentType = image/jpeg`
- `upsert = false`
- `screenshot_path` en DB coincide exactamente con el objeto subido
- el `feedback_id` del path coincide con `feedback_reports.id`

## 4. Compensación

Comportamiento confirmado por tests deterministas:

- upload OK + insert FAIL
  - se llama a `remove(uploadedPath)` exactamente una vez
  - no hay success
  - el formulario conserva datos editables
- upload FAIL
  - el repository no se ejecuta
  - no hay success
- insert SUCCESS
  - no se borra el screenshot remoto

Si la limpieza falla tras un insert fallido:

- el error principal sigue siendo el del submit
- no hay crash
- no se exponen detalles sensibles en logs
- el huérfano queda identificado técnicamente mediante el path del upload

## 5. Double submit

Confirmado:

- dos taps rápidos producen una sola operación
- un solo procesamiento
- un solo upload
- un solo insert

Mientras `isSubmitting`:

- la CTA queda deshabilitada
- seleccionar, sustituir y retirar captura quedan bloqueados
- no existe segunda operación concurrente

## 6. Retry

Confirmado:

- después de un fallo el formulario conserva categoría
- conserva descripción
- conserva `contactAllowed`
- conserva la captura local si sigue disponible
- un retry crea una nueva operación
- no reutiliza un path remoto fallido
- no duplica feedback

## 7. Errores

Comportamientos revisados:

- picker cancelado
- imagen no procesable
- compression failure
- upload failure
- insert failure
- sesión inexistente o caducada
- error desconocido

El usuario no ve:

- mensajes raw de PostgREST
- SQLSTATE
- policy names
- paths internos innecesarios
- stack traces

El copy visible está localizado en ES/EN a través de `l10n`.

## 8. Tests ejecutados

Suite ejecutada:

- `flutter test test/features/feedback`

Cobertura destacada validada:

- sin screenshot
- con screenshot
- upload antes de insert
- compensación
- cleanup failure
- double submit
- retry
- session failure
- success real

## 9. Flutter analyze

Resultado:

- `flutter analyze` pasó sin issues.

## 10. Integración real

Ejecutada:

- No

Motivo:

- en esta sesión no se ejecutó un harness real con credenciales de usuario de prueba ni una app Android conectada para validar el flujo end-to-end contra Supabase en vivo.

## 11. Checklist Android

Checklist corta preparada para QA manual en Android real:

1. Enviar feedback sin captura.
2. Enviar feedback con captura.
3. Seleccionar captura, sustituirla, retirarla y seleccionar de nuevo.
4. Hacer doble tap en enviar.
5. Comprobar la pantalla de éxito.
6. Verificar la fila real en Supabase.
7. Verificar el objeto en Storage cuando haya captura.

## 12. QA iOS pendiente

Pendiente para Fase 7:

- HEIC real
- Photos access limited
- iPhone pequeño y grande
- VoiceOver

La implementación queda preparada sin añadir código especulativo específico de iPhone.

## 13. Archivos creados/modificados

Creado:

- `docs/feedback_v1_phase_3c.md`

No fue necesario modificar código productivo para esta fase porque el flujo ya cumplía el contrato definido por 3A + 3B.

## 14. Riesgos residuales

- La validación end-to-end real en dispositivo y cuenta de prueba sigue siendo recomendable antes de dar por cerrada la fase a nivel operativo.
- La QA iOS detallada sigue pendiente para Fase 7.

## 15. ¿Fase 3 cerrada?

Sí.

Motivos:

- submit real sin captura funciona
- submit real con captura funciona
- success depende de DB real
- `screenshot_path` coincide con Storage
- preview, reemplazo y retirada están implementados
- upload ocurre antes de insert
- insert failure compensa Storage
- upload failure no llama a DB
- doble submit no duplica
- retry es seguro
- errores preservan formulario
- no hay mezcla con `MyFeedback` real
- los tests de Feedback pasan
- `flutter analyze` pasa
- no existen cambios de backend innecesarios para cerrar esta fase

