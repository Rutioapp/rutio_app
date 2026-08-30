# Rutio Feedback V1 - Phase 3B

Fecha: 2026-08-30

## Resumen

La Fase 3B conecta el formulario de Feedback con una captura opcional desde galería, procesamiento local y subida al bucket privado de Supabase antes del `INSERT`.

El flujo ahora queda así:

- seleccionar captura opcional
- previsualizarla
- sustituirla o retirarla
- comprimirla localmente
- subir JPEG procesado a Storage
- insertar `feedback_reports`
- navegar a `FeedbackSuccessScreen`

Si no hay captura, el submit de la Fase 3A sigue funcionando igual.

## Dependencia añadida

- `flutter_image_compress: ^2.5.1`

La versión elegida es compatible con el toolchain actual del proyecto y no exigió subir el deployment target iOS ni añadir permisos nuevos de Android.

## Arquitectura de imagen

Se separó la lógica en dos piezas de data layer:

- `lib/features/feedback/data/feedback_image_service.dart`
- `lib/features/feedback/data/feedback_storage_service.dart`

### `FeedbackImageService`

Responsabilidades:

- abrir la galería con `ImageSource.gallery`
- validar tipo de imagen cuando se puede inferir
- mantener la selección en local
- comprimir a JPEG
- crear archivo temporal de subida
- limpiar temporales

### `FeedbackStorageService`

Responsabilidades:

- construir el path canonico
- subir el binario JPEG a Storage
- borrar el objeto huérfano como compensación best-effort

### Controller

`FeedbackFormController` orquesta:

- estado local de categoría, descripción, contacto y captura
- bloqueo de doble submit
- compresión
- upload
- insert
- compensación si el insert falla después del upload

## Formato y compresión

- formato remoto: `image/jpeg`
- extensión remota: `.jpg`
- lado mayor objetivo: `1600 px`
- objetivo de peso: alrededor de `1 MB`
- hard limit seguro: `5 MB`
- `EXIF` desactivado en la compresión

La estrategia aplicada es:

1. convertir a JPEG
2. redimensionar manteniendo aspect ratio con lado mayor máximo de 1600 px
3. comprimir con una calidad inicial razonable
4. reintentar con calidades más bajas si el resultado sigue por encima del objetivo
5. abortar si el resultado supera el límite duro

## Gestión EXIF

El output procesado es el archivo que se sube y no conserva EXIF.

No se mantiene:

- GPS
- modelo de cámara
- fechas de captura
- metadatos EXIF adicionales

## Flujo HEIC

La selección acepta assets de Photos que vengan como:

- HEIC
- JPEG
- PNG

La salida se normaliza a JPEG para evitar problemas de compatibilidad entre iOS y Android.

La validación es defensiva:

- si el tipo puede identificarse y no es soportado, se rechaza
- si el tipo no se puede inferir, se permite continuar y se confía en la compresión real

## Temp files

La compresión escribe un archivo temporal en `cache/temp`, nunca en Documents.

Ese temporal:

- se elimina tras terminar el submit
- también se limpia si el submit falla antes de la navegación final

El archivo original gestionado por `image_picker` no se toca de forma destructiva.

## Path Storage

Contrato implementado:

- `<user_id>/<feedback_id>/screenshot_<uuid>.jpg`

El `feedbackId` usado para el upload es el mismo UUID que luego se inserta en `feedback_reports.id`.

## Flujo upload

Orden de submit con captura:

1. comprobar `canSubmit`
2. bloquear doble submit
3. generar `feedbackId`
4. generar `technicalContext`
5. procesar y comprimir captura
6. generar `screenshotId`
7. subir a `feedback-screenshots`
8. insertar `feedback_reports` con `screenshotPath`
9. devolver `FeedbackReport` real
10. limpiar temporales

Sin captura:

1. generar `feedbackId`
2. generar `technicalContext`
3. insertar con `screenshot_path = null`
4. success

## Compensación implementada

Si el upload de Storage tiene éxito pero el insert falla, se ejecuta un borrado best-effort del objeto subido.

Si esa limpieza también falla:

- el submit sigue considerándose fallido
- no se oculta el error original
- no se reintenta indefinidamente

## Comportamiento retry

Si algo falla antes del insert:

- la categoría, descripción y contacto se conservan
- la captura local se conserva cuando es razonablemente posible
- un retry genera un nuevo `screenshotId` y, si hace falta, un nuevo path remoto

No hay duplicación de inserts porque `isSubmitting` bloquea el doble tap.

## Errores de imagen

Se mapearon errores de UI para:

- cancelación del picker, que no es error
- tipo no soportado
- imagen no procesable
- compresión fallida
- tamaño excesivo
- upload fallido
- cleanup temporal fallido

El copy visible está localizado en ES/EN.

## Configuración iOS

`ios/Runner/Info.plist` se actualizó con un `NSPhotoLibraryUsageDescription` que cubre:

- selección de imagen para perfil
- adjuntar capturas de feedback

`NSCameraUsageDescription` no se añadió para esta fase.

## Android

No hubo cambios en `AndroidManifest.xml`.

No se añadió permisos legacy de almacenamiento.

## Tests

Se añadieron o ampliaron tests para:

- `FeedbackImageService`
- `FeedbackStorageService`
- `FeedbackFormController`
- `FeedbackFormScreen`
- `SupabaseFeedbackRepository`

Cobertura destacada:

- cancelación de picker
- representación de captura local
- output JPEG y temp file válido
- hard limit de tamaño
- cleanup de temporales
- path canonico de Storage
- `contentType = image/jpeg`
- `upsert = false`
- upload antes del insert
- compensación de huérfanos
- doble submit bloqueado
- retry tras fallo

## Prueba real

No ejecuté una prueba real en dispositivo durante esta sesión.

## Frontera exacta con 3C y Fase 4

### Queda fuera de 3B

- historial real
- `MyFeedback` real
- detalle real desde Supabase
- `update_my_feedback` desde UI
- `delete_my_feedback` desde UI
- signed URLs para detalle
- emails
- Realtime

### Fase 3C

La siguiente fase puede centrarse en terminar detalles de experiencia y pulido del flujo de captura/subida si se necesita algo adicional, pero sin convertir todavía `MyFeedback` ni el detalle en lectura real.

### Fase 4

Ahí entra todo lo que depende de lectura y gestión real:

- listados reales
- detalle real
- edición real
- borrado real
- estados gobernados por backend desde la UI

