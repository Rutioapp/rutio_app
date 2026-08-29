# Feedback V1 Phase 0 Audit

Fecha de la auditoría: 2026-08-29

Alcance: revisión técnica previa para definir cómo integrar el Centro de Feedback V1 en la arquitectura real de Rutio. No se ha implementado la feature, no se han creado migraciones y no se ha tocado comportamiento de producción.

## 1. Estado actual encontrado

- Rutio ya tiene un acceso de soporte/feedback, pero es externo: el drawer abre un Google Form mediante `FeedbackFormService`.
- La app está montada con Flutter + Supabase, con un estilo iOS-first, navegación imperativa y arquitectura mixta entre `screens/` legado y `features/` más recientes.
- El estado autenticado y el scope de usuario ya existen y se pueden reutilizar; no hace falta inventar otro sistema de sesión.
- La persistencia remota en Rutio ya sigue patrones útiles para Feedback: repositorios con `RepositoryResult`, mapeo explícito de errores Supabase y RLS por `auth.uid()`.
- Visualmente, la app ya usa una paleta beige/camel/sage y tipografías DM Sans / DM Serif Display, así que el Centro de Feedback debe apoyarse en esos tokens y no crear una estética paralela.

## 2. Archivos relevantes

- Entrada actual de soporte: [lib/widgets/app_view_drawer.dart](D:/dev/alpha/rutio_app/lib/widgets/app_view_drawer.dart#L164)
- Servicio legacy de Google Forms: [lib/core/services/feedback_form_service.dart](D:/dev/alpha/rutio_app/lib/core/services/feedback_form_service.dart#L5)
- Detección de plataforma del formulario: [lib/core/services/feedback_form_platform_io.dart](D:/dev/alpha/rutio_app/lib/core/services/feedback_form_platform_io.dart#L3)
- Inicialización y rutas de la app: [lib/main.dart](D:/dev/alpha/rutio_app/lib/main.dart#L127)
- Tema global: [lib/utils/app_theme.dart](D:/dev/alpha/rutio_app/lib/utils/app_theme.dart#L4)
- Acceso a userId/email del usuario: [lib/stores/user_state_store.dart](D:/dev/alpha/rutio_app/lib/stores/user_state_store.dart#L574)
- Cliente Supabase: [lib/core/supabase/rutio_supabase_client.dart](D:/dev/alpha/rutio_app/lib/core/supabase/rutio_supabase_client.dart#L5)
- Patrón de repositorio Supabase: [lib/data/repositories/diary_v2_supabase_repository.dart](D:/dev/alpha/rutio_app/lib/data/repositories/diary_v2_supabase_repository.dart#L11)
- Patrón de errores y resultados: [lib/data/repositories/repository_result.dart](D:/dev/alpha/rutio_app/lib/data/repositories/repository_result.dart#L1)
- Controller basado en `ChangeNotifier`: [lib/features/shop/application/shop_controller.dart](D:/dev/alpha/rutio_app/lib/features/shop/application/shop_controller.dart#L123)
- Controller ligero por pantalla: [lib/screens/edit_profile/edit_profile_controller.dart](D:/dev/alpha/rutio_app/lib/screens/edit_profile/edit_profile_controller.dart#L1)
- Settings / profile entry points: [lib/screens/profile/profile_screen.dart](D:/dev/alpha/rutio_app/lib/screens/profile/profile_screen.dart#L1), [lib/screens/profile/settings_screen.dart](D:/dev/alpha/rutio_app/lib/screens/profile/settings_screen.dart#L1)
- Internacionalización: [lib/l10n/app_en.arb](D:/dev/alpha/rutio_app/lib/l10n/app_en.arb#L1325), [lib/l10n/app_es.arb](D:/dev/alpha/rutio_app/lib/l10n/app_es.arb#L1325)
- Tests de ejemplo para drawer y Supabase: [test/app_view_drawer_test.dart](D:/dev/alpha/rutio_app/test/app_view_drawer_test.dart#L15), [test/data/repositories/diary_v2_supabase_repository_test.dart](D:/dev/alpha/rutio_app/test/data/repositories/diary_v2_supabase_repository_test.dart#L10)
- Migraciones y verificaciones SQL: [supabase/migrations](D:/dev/alpha/rutio_app/supabase/migrations), [supabase/tests](D:/dev/alpha/rutio_app/supabase/tests)

## 3. Arquitectura existente reutilizable

- `ChangeNotifier` + `Provider` como capa de orquestación de UI y estado, especialmente cuando la pantalla no necesita un router complejo.
- `RepositoryResult<T>` y `RepositoryErrorCode` para modelar éxito/error sin lanzar excepciones a la UI.
- Repositorios Supabase con `SupabaseClient` inyectable y un provider opcional de `currentUserId` para no acoplar la lógica a `Supabase.instance` salvo por defecto.
- Mapeo explícito de `PostgrestException` a errores de dominio, con tratamiento especial de `notAuthenticated`, `permissionDenied`, `network` e `invalidResponse`.
- `UserStateStore` como fuente central de `userId`, `authEmail`, locale preferida y scope del usuario.
- Sistema de localización con ARB + código generado.
- Tokens visuales centralizados en `AppColors`, `AppTextStyles` y `AppTheme`, con DMSans / DMSerifDisplay ya registrados en `pubspec.yaml`.

## 4. Navegación actual

- La app usa `MaterialApp` con `routes` estáticas en [lib/main.dart](D:/dev/alpha/rutio_app/lib/main.dart#L145), no un router declarativo tipo GoRouter.
- El patrón de navegación dominante es `Navigator.push`, `pushNamed`, `pushReplacement` y `pushNamedAndRemoveUntil`.
- El acceso actual de soporte vive en el drawer y dispara una URL externa, no una pantalla interna.
- El punto exacto que habrá que reemplazar en una fase posterior es el tile de soporte de [lib/widgets/app_view_drawer.dart](D:/dev/alpha/rutio_app/lib/widgets/app_view_drawer.dart#L164) que hoy llama a `launchReportIssueForm`.
Rutas propuestas:

- `/feedback`, `/feedback/new`, `/feedback/success` y `/feedback/mine` encajan bien como rutas nombradas estáticas.
- `/feedback/:id` no encaja bien con `routes` estático; para esa ruta, lo coherente con Rutio es usar `onGenerateRoute` solo para Feedback o, si se quiere evitar tocar el router global, usar `/feedback/detail` con `arguments`.
- Mi recomendación es `onGenerateRoute` mínimo para Feedback, porque preserva el estilo actual de navegación y mantiene el resto del mapa de rutas intacto.

## 5. Integración con Supabase existente

- Supabase se inicializa una sola vez al arranque en [lib/main.dart](D:/dev/alpha/rutio_app/lib/main.dart#L77) mediante [lib/core/supabase/rutio_supabase_client.dart](D:/dev/alpha/rutio_app/lib/core/supabase/rutio_supabase_client.dart#L5).
- El cliente actual es `anon` + sesión de usuario; no hay señal de uso de `service_role` desde la app, y esa restricción debe mantenerse.
- `UserStateStore` ya expone `userId`, `authEmail` y `preferredLocale`, que son suficientes para poblar metadatos de Feedback sin crear otra fuente de identidad.
- El patrón ya usado en `DiaryV2SupabaseRepository` y `ProfileRepository` es el que conviene repetir: repo específico, select/upsert/delete acotados por usuario, y validación de respuesta.
Para Feedback, la integración debería seguir el mismo modelo:

- un repositorio Supabase propio para `feedback_entries`;
- un adaptador de Storage propio si las capturas se suben a bucket privado;
- error mapping local a `RepositoryErrorCode`;
- nada de acceso directo desde UI a Supabase.
- RLS debería seguir la convención del resto del backend: `select/insert/update/delete` scoping por `auth.uid()`, con restricciones extra para permitir solo `submitted` en edición/borrado de usuario.
- Como la administración inicial será vía Supabase Studio, cualquier regla crítica de transición debe vivir en DB, no solo en la UI.
- No hay necesidad de Realtime en V1; los cambios de estado pueden resolverse con fetch al entrar, refresh manual o reconsulta puntual.

## 6. Integración l10n/theme

- La internacionalización está centralizada en `lib/l10n/app_en.arb` y `lib/l10n/app_es.arb`, con clases generadas en `lib/l10n/gen/`.
- Las claves nuevas de Feedback deben seguir el estilo actual: nombres descriptivos, sin hardcodear strings en widgets y con variantes ES/EN desde ARB.
- La pantalla de Feedback no debería introducir una paleta propia; debe apoyarse en `AppColors.cream`, `AppColors.earth`, `AppColors.sage`, `AppTextStyles` y los radios ya existentes.
- La app ya tiene una base visual beige/camel/verde suave; eso encaja con el pedido de Feedback y evita un bloque lila aislado.
- Si hace falta una variación cromática para estados, conviene derivarla de tokens existentes en vez de hardcodear valores nuevos.

## 7. Dependencias disponibles/faltantes

- Ya están disponibles `image_picker`, `url_launcher`, `path_provider`, `permission_handler`, `supabase_flutter` y `flutter_localizations`.
- `image_picker` ya se usa en [lib/screens/edit_profile/edit_profile_controller.dart](D:/dev/alpha/rutio_app/lib/screens/edit_profile/edit_profile_controller.dart#L1), así que el flujo de selección de captura puede reutilizar patrones de permisos y picking.
- No encontré `flutter_image_compress` en `pubspec.yaml` ni en `pubspec.lock`.
- No encontré `package_info_plus` en `pubspec.yaml` ni en `pubspec.lock`.
- No encontré `device_info_plus` en `pubspec.yaml` ni en `pubspec.lock`.
- Flutter local: 3.44.6, Dart 3.12.2.
- iOS deployment target actual: 13.0 en [ios/Podfile](D:/dev/alpha/rutio_app/ios/Podfile#L1).
- Android actual: `namespace = com.rutio.app`, `compileSdk/targetSdk/minSdk` salen del toolchain de Flutter, y el proyecto compila con Java 17 en [android/app/build.gradle.kts](D:/dev/alpha/rutio_app/android/app/build.gradle.kts#L17).
- Para la Fase 0 no hace falta añadir paquetes; si en Fase 1 se decide comprimir capturas o adjuntar metadatos del dispositivo, entonces sí habría que reevaluar dependencias.

## 8. Estrategia de tests

- El proyecto ya prueba widgets, controllers, repositorios y migraciones SQL por separado.
- Los tests de UI se organizan por feature o screen, por ejemplo [test/app_view_drawer_test.dart](D:/dev/alpha/rutio_app/test/app_view_drawer_test.dart#L15) o [test/screens/...](D:/dev/alpha/rutio_app/test/screens).
- Los repositorios Supabase se prueban con clients HTTP controlados, como en [test/data/repositories/diary_v2_supabase_repository_test.dart](D:/dev/alpha/rutio_app/test/data/repositories/diary_v2_supabase_repository_test.dart#L10).
- Las verificaciones SQL están separadas en `test/supabase/*_static_test.dart`, así que Feedback debería seguir exactamente ese patrón cuando existan migraciones.
Lugar recomendado para tests futuros:

- `test/features/feedback/data/...` para repositorios, mappers y validadores;
- `test/features/feedback/application/...` para controllers/use cases;
- `test/features/feedback/presentation/...` para pantallas y navegación;
- `test/supabase/...` para contract tests de SQL;
- `test/widgets/...` solo si se crean piezas reutilizables compartidas fuera de la feature.

## 9. Riesgos o conflictos

- `/feedback/:id` no es representable directamente con el `routes` estático actual.
- El cliente nunca debe poder resolver estados `resolved` o `dismissed` por su cuenta; si eso se deja solo en UI, se rompe el contrato funcional.
- `contact_allowed` debe nacer como `false` por defecto; si se omite el default en DB, habrá fuga de privacidad.
- Las capturas en bucket privado requieren política clara de ownership y path naming; si no se diseña bien, el usuario podría ver o pisar archivos de otros.
- No hay Realtime en V1, así que la UI no debe asumir cambios instantáneos de estado.
- La administración por Supabase Studio hace más importante que las restricciones críticas estén en la base de datos y no solo en el app code.
- El acceso de soporte legacy hoy es un enlace externo; durante la transición habrá que evitar que ambas rutas dejen copys o experiencias contradictorias.
- Si la feature se implementa sin reutilizar `UserStateStore`, se duplicará lógica de identidad y locale.

## 10. Arquitectura final recomendada para Feedback

Crear la feature en `lib/features/feedback/` con la misma partición que ya usa Rutio:

- `application/` para controllers, casos de uso y coordinación;
- `data/` para repositorios Supabase, storage y mappers;
- `domain/` para enums, entidades y validaciones;
- `presentation/` para screens, widgets y routing de la feature.
- Usar `ChangeNotifier` + `Provider` para la orquestación de pantalla, no un árbol paralelo de state management.
- Modelar Feedback con enums de dominio para `status` y `category`, y con validación centralizada de texto `trim()` entre 20 y 5000 caracteres.
- Reutilizar `RepositoryResult` y el estilo de mapeo de errores ya presente en Diary/Profile.
- Mantener la subida de captura separada del flujo de creación del ticket: primero validar y crear el feedback, luego adjuntar o subir la captura con un camino claro y privado.
- Reusar `UserStateStore` para `userId`, email y locale.
- Integrar navegación interna con named routes y `onGenerateRoute` mínimo para el detalle por id.
- Mantener la UI en la paleta actual de Rutio y usar l10n para todo el copy.

## 11. Archivos que previsiblemente crearemos o modificaremos en Fase 1

- [lib/main.dart](D:/dev/alpha/rutio_app/lib/main.dart)
- [lib/widgets/app_view_drawer.dart](D:/dev/alpha/rutio_app/lib/widgets/app_view_drawer.dart)
- [lib/screens/profile/profile_screen.dart](D:/dev/alpha/rutio_app/lib/screens/profile/profile_screen.dart)
- [lib/screens/profile/settings_screen.dart](D:/dev/alpha/rutio_app/lib/screens/profile/settings_screen.dart)
- [lib/features/feedback/application/feedback_controller.dart](D:/dev/alpha/rutio_app/lib/features/feedback/application/feedback_controller.dart)
- [lib/features/feedback/application/feedback_submission_controller.dart](D:/dev/alpha/rutio_app/lib/features/feedback/application/feedback_submission_controller.dart)
- [lib/features/feedback/data/feedback_repository.dart](D:/dev/alpha/rutio_app/lib/features/feedback/data/feedback_repository.dart)
- [lib/features/feedback/data/feedback_storage_repository.dart](D:/dev/alpha/rutio_app/lib/features/feedback/data/feedback_storage_repository.dart)
- [lib/features/feedback/domain/feedback_entry.dart](D:/dev/alpha/rutio_app/lib/features/feedback/domain/feedback_entry.dart)
- [lib/features/feedback/domain/feedback_status.dart](D:/dev/alpha/rutio_app/lib/features/feedback/domain/feedback_status.dart)
- [lib/features/feedback/domain/feedback_category.dart](D:/dev/alpha/rutio_app/lib/features/feedback/domain/feedback_category.dart)
- [lib/features/feedback/presentation/screens/feedback_screen.dart](D:/dev/alpha/rutio_app/lib/features/feedback/presentation/screens/feedback_screen.dart)
- [lib/features/feedback/presentation/screens/feedback_new_screen.dart](D:/dev/alpha/rutio_app/lib/features/feedback/presentation/screens/feedback_new_screen.dart)
- [lib/features/feedback/presentation/screens/feedback_success_screen.dart](D:/dev/alpha/rutio_app/lib/features/feedback/presentation/screens/feedback_success_screen.dart)
- [lib/features/feedback/presentation/screens/feedback_mine_screen.dart](D:/dev/alpha/rutio_app/lib/features/feedback/presentation/screens/feedback_mine_screen.dart)
- [lib/features/feedback/presentation/screens/feedback_detail_screen.dart](D:/dev/alpha/rutio_app/lib/features/feedback/presentation/screens/feedback_detail_screen.dart)
- [lib/l10n/app_en.arb](D:/dev/alpha/rutio_app/lib/l10n/app_en.arb)
- [lib/l10n/app_es.arb](D:/dev/alpha/rutio_app/lib/l10n/app_es.arb)
- [test/features/feedback/...](D:/dev/alpha/rutio_app/test/features/feedback)
- [test/supabase/...](D:/dev/alpha/rutio_app/test/supabase)

## 12. Propuesta de división interna de la Fase 1

- Fase 1A: navegación y shell de Feedback, con rutas, puntos de entrada y pantallas vacías pero conectadas.
- Fase 1B: dominio y data layer, con enums, entidad principal, repo Supabase y mapeo de errores.
- Fase 1C: formulario de creación, validación de texto, selección de captura desde galería y estado de envío.
- Fase 1D: listas y detalle de usuario, con `mine`, detalle por id y estados read-only.
- Fase 1E: l10n, ajustes visuales y tests mínimos para cerrar la feature con un contrato estable.

## Recomendación final

La mejor ruta para Rutio es construir Feedback como una feature nueva pero totalmente alineada con las convenciones actuales: `ChangeNotifier` para UI state, repositorios Supabase por feature, `RepositoryResult` para errores, l10n por ARB y tokens visuales reutilizados. Lo único que no encaja de forma natural con el router actual es `/feedback/:id`, así que conviene resolverlo con `onGenerateRoute` mínimo o con una ruta de detalle basada en `arguments`.
