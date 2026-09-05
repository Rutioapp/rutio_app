# Fase 0 — Auditoría de frases para día completado

Fecha: 2026-09-04  
Estado: auditoría terminada; no se ha implementado funcionalidad.

## Alcance y conclusión ejecutiva

El objetivo auditado es mostrar en Home una frase cuando, para el día local actual, todos los hábitos programados estén completados. Esta fase se ha limitado a inspección de código, pruebas, persistencia, Supabase, localización y patrones existentes.

Conclusión: Home ya calcula los estados necesarios mediante HabitDaySummary, pero no expone todavía un contrato explícito isCompletedDay. La frase no debe depender del filtro visual “Pendientes”, de la racha global ni de una animación de transición.

Para hábitos diarios, semanales y de fecha única, el criterio seguro sería:

    estado local listo
    AND fecha = día local actual
    AND hábitos programados > 0
    AND pendientes = 0
    AND saltados = 0
    AND completados = hábitos programados

La condición no puede cerrarse de forma inequívoca para timesPerWeek sin decidir antes si “completado” significa haber completado el hábito hoy o haber alcanzado la cuota semanal. La implementación actual de Home permite que un hábito timesPerWeek aparezca como completado por cuota semanal aunque no se haya completado hoy; también puede mantenerlo como completado si hoy se saltó pero la cuota ya estaba cumplida. Eso entra en conflicto con la frase de un “día completado” si los saltos nunca deben contar como completados.

## 1. Archivos relevantes inspeccionados

### Home y dominio de hábitos

- lib/screens/home/home_screen.dart
- lib/screens/home/state/home_state.dart
- lib/screens/home/logic/home_selectors.dart
- lib/screens/home/logic/home_view_data.dart
- lib/screens/home/build/home_build.dart
- lib/screens/home/build/sections/home_scrollable_content_sliver.dart
- lib/screens/home/build/sections/home_habits_sliver.dart
- lib/screens/home/build/sections/home_empty_state_card.dart
- lib/screens/home/ui/home_header_builders.dart
- lib/screens/home/ui/home_card_builders.dart
- lib/features/habits/domain/habit_day_summary.dart
- lib/features/habits/domain/metrics/habit_occurrence_evaluator.dart
- lib/features/habits/domain/metrics/habit_occurrence_result.dart
- lib/features/habits/domain/metrics/habit_snapshot.dart
- lib/features/habits/domain/metrics/habit_date_utils.dart
- lib/features/habits/domain/metrics/times_per_week_quota_policy.dart

### Estado, identidad y perfil

- lib/stores/user_state_store.dart
- lib/stores/user_state_store_core.dart
- lib/stores/user_state_store_account.dart
- lib/stores/user_state_store_habits.dart
- lib/stores/user_state_store_habit_progress.dart
- lib/stores/user_state_store_achievements.dart
- lib/data/local/user_state_storage.dart
- lib/data/repositories/user_state_repository.dart
- lib/core/identity/user_namespace.dart
- lib/application/auth/auth_controller.dart
- lib/data/repositories/auth_repository.dart
- lib/data/repositories/profile_repository.dart
- lib/screens/edit_profile/edit_profile_controller.dart
- lib/screens/profile/profile_screen.dart

### Localización, persistencia y patrones remotos

- lib/l10n/l10n.dart
- lib/l10n/app_es.arb
- lib/l10n/app_en.arb
- lib/main.dart
- lib/features/notifications/data/local/shared_preferences_notification_history_store.dart
- lib/features/notifications/data/local/notification_local_storage_scope.dart
- lib/features/notifications/data/local/local_notification_template_catalog.dart
- lib/features/weekly_report/data/weekly_report_repository.dart
- lib/features/weekly_report/presentation/weekly_report_copy_resolver.dart
- lib/features/shop/data/cloud/cloud_cosmetics_cache.dart
- lib/features/shop/data/cloud/shop_cloud_read_repository.dart
- lib/features/shop/data/cloud/shop_cloud_remote_data_sources.dart
- lib/features/shop/data/cloud/shop_cloud_runtime_config.dart
- lib/core/supabase/rutio_supabase_client.dart
- supabase/migrations/20260717130000_create_shop_foundation.sql
- supabase/migrations/20260722120000_create_shop_bundle_catalog_and_purchase_rpc.sql
- supabase/migrations/20260901090000_create_weekly_report_foundation.sql
- supabase/migrations/20260901150000_weekly_report_read_api.sql
- supabase/seed.sql
- pubspec.yaml

### Pruebas consultadas

- test/screens/home/home_selectors_schedule_test.dart
- test/screens/home/home_habit_status_filter_test.dart
- test/screens/home/home_screen_refresh_test.dart
- test/features/habits/domain/metrics/habit_occurrence_evaluator_test.dart
- test/stores/user_state_store_times_per_week_schedule_test.dart
- test/stores/user_state_store_schedule_guards_test.dart
- test/stores/user_state_store_habits_cloud_test.dart
- test/stores/user_state_store_habits_remote_pull_test.dart
- test/stores/user_state_store_user_progress_restore_test.dart
- test/stores/user_state_store_global_activity_metrics_test.dart
- test/features/notifications/data/local/shared_preferences_notification_history_store_test.dart
- test/features/weekly_report/data/weekly_report_repository_test.dart
- test/features/weekly_report/presentation/weekly_report_copy_catalog_integrity_test.dart
- test/features/shop/data/shop_local_repository_test.dart
- test/features/shop/data/cloud/cloud_cosmetics_cache_test.dart
- test/features/shop/data/shop_catalog_remote_contract_test.dart
- test/features/shop/data/shop_cloud_runtime_config_test.dart
- test/application/bootstrap/home_background_bootstrapper_test.dart
- test/screens/profile/profile_phase3_test.dart

## 2. Estado actual de Home y determinación del día

Home mantiene _selectedDay y se reconstruye observando UserStateStore con context.watch<UserStateStore>(). En cada reconstrucción buildHomeViewData(root, _selectedDay) vuelve a derivar los datos de la vista. Home permite navegar días anteriores; por tanto, “día completado” para esta feature debe fijarse explícitamente al día local actual, no al día seleccionado de forma genérica.

buildHomeViewData obtiene el día de referencia con DateTime.now() y lo normaliza a año/mes/día local. Los historiales se consultan por claves de fecha locales. No hay en Home una abstracción de zona horaria IANA ni una condición específica para la frase.

HabitDaySummary es el cálculo más cercano a una fuente canónica para Home:

- excluye hábitos archivados;
- determina los hábitos esperados para la fecha;
- lee habitCompletions, habitCountValues y habitSkips del historial local;
- calcula pendingHabits, completedHabits y skippedHabits;
- expone totalCount, completedCount y progressRatio;
- para un día sin hábitos, progressRatio es null, no 1.0.

HomeViewData conserva esos resultados como viewHabits, pendingHabits, completedHabits, skippedHabits, doneCount y totalCount, pero no tiene hasScheduledHabitsToday, isCompletedDay ni un porcentaje diario expreso. Tampoco se ha encontrado un widget de porcentaje diario visible en Home.

### Diferencia entre “sin hábitos” y “todos completados”

- Sin hábitos programados: homeData.viewHabits.isEmpty; se muestra HomeEmptyStateCard, con CTA para crear un hábito.
- Hábitos programados y todos completados: viewHabits no está vacío, pendingHabits está vacío y el filtro por defecto “Pendientes” muestra HomeHabitFilterEmptyState con “No tienes hábitos pendientes.”
- Hábitos saltados: permanecen en skippedHabits y no deben convertirse en completados para esta feature.

La frase debe distinguir el primer caso del segundo con una comprobación totalCount > 0; un ratio ausente no equivale a un día completado.

### Estados especiales y sincronización

home_build.dart no construye el contenido normal cuando isLoading es true, hay error o el estado raíz aún es nulo. Estos estados no son seguros para mostrar la frase. Home sí puede renderizar estado local mientras hay una recuperación remota de hábitos en segundo plano (isHabitsRemotePullRunning), por lo que Phase 1 debe decidir si espera a una fuente lista o si considera el snapshot local cargado como suficiente.

La recomendación es no declarar “día completado” en estado loading, failed, emptyFromTemplate, durante un cambio de scope o cuando los datos de hábitos aún son provisionales.

UserStateStore protege la carga y guardado con scopeEpoch; Home también resetea filtros y transiciones al cambiar el scope. La nueva selección de frase debe respetar la misma protección para no reutilizar el resultado de otra cuenta.

## 3. Punto visual exacto recomendado

El punto correcto está en el contenido cargado de Home, después del bloque de fecha/progreso (dayProgress) y antes del RefreshIndicator que contiene el CustomScrollView. La composición actual es:

    _HomeLoadedView
      -> header
      -> week strip
      -> dayProgress
      -> RefreshIndicator
         -> HomeScrollableContentSliver
            -> HomeEmptyStateCard o HomeHabitsSliver

La frase debe ser un sliver/widget propio insertado entre dayProgress y la lista, condicionado por el estado canónico del día. No debe insertarse dentro de HomeHabitsSliver: el filtro Pendientes puede estar vacío por una selección visual y no representa por sí solo un “día perfecto”. Tampoco debe mostrarse en HomeEmptyStateCard.

## 4. Identidad de usuario y cambio de cuenta

La identidad autenticada canónica es AuthController.currentUser?.id, procedente de AuthRepository y del usuario actual de Supabase Auth. El userId expuesto por UserStateStore procede del estado local y es útil para datos ya cargados, pero no debe ser la autoridad única para decidir el scope de una caché nueva.

Al iniciar sesión, AuthController llama a UserStateStore.switchLocalScope(userId: currentUser.id). Al cerrar sesión, limpia el usuario actual y cambia el scope a null. UserStateStore incrementa scopeEpoch, limpia estado transitorio y evita aplicar resultados de una carga que pertenezca a una sesión anterior.

Para la feature, la clave debe incluir el usuario autenticado. Se puede reutilizar safeUserNamespace de lib/core/identity/user_namespace.dart o el patrón de NotificationLocalStorageScope; no se debe interpolar un userId sin normalizar en una clave arbitraria. Un cambio de cuenta debe invalidar la frase seleccionada en memoria y hacer que una lectura pendiente de la cuenta anterior sea descartada.

## 5. Fuente del nombre editable

La fuente de UI actual es UserStateStore.displayName, con prioridad sobre los argumentos de ruta y sobre los campos crudos del perfil. El getter resuelve displayName, name o username. El perfil se conserva en el estado local y ProfileRepository lo sincroniza con la tabla profiles, leyendo por id y actualizando display_name.

EditProfileController inicializa el campo desde profile['displayName'] y envía text.trim() al guardar. No hay una sanitización más profunda ni una normalización uniforme de espacios aparte de ese trim. Si el nombre está vacío, Home usa homeFallbackUsername (en español, “Usuario”); Profile tiene su propio fallback.

La frase no necesita enviar el nombre a Supabase. Si Phase 1 admite un token de nombre, debe usar el valor local ya resuelto, recortado y con fallback, y tratarlo como texto de presentación; el catálogo remoto no debe almacenar nombres personales ni frases generadas por usuario.

## 6. Racha global

UserStateStore.globalHabitStreakSnapshot se calcula localmente a partir del historial de hábitos. La función _globalHabitCountsByDay marca un día global como activo si existe al menos un hábito completado ese día cuando había hábitos programados; no exige que se completen todos. La racha actual empieza en el día local de referencia y retrocede mientras haya conteo positivo.

La usan, entre otros, Profile y Statistics V3. No es la métrica correcta para decidir que el día está completado: una racha global puede crecer con un solo hábito completado.

El token {streak_label} debe derivarse de esta misma snapshot global, pero renderizarse localmente. lib/l10n/l10n.dart ya tiene patrones manuales como habitStatsDaysUnitLabel(int count), que resuelven día/días y day/days con count == 1. No hace falta ni conviene poner lógica ICU o pluralización en un catálogo remoto.

## 7. Localización

MaterialApp usa store.preferredLocale, los delegates generados de AppLocalizations y AppLocalizations.supportedLocales. Los ARB de español e inglés son la fuente de copy local; l10n.dart contiene helpers manuales para copy que no están modelados como getters generados.

El patrón recomendado es guardar en remoto un identificador de frase y, si es necesario, una versión/categoría, y resolver el texto local con el locale actual. Si el producto exige textos editables desde Supabase, el fallback debe ser un catálogo local versionado por locale; el renderizador sigue siendo responsable de validar tokens y de producir el texto final.

El locale de la frase debe canonizarse (es-ES/es y en-*/en) antes de seleccionar caché.

## 8. Persistencia local reutilizable

La infraestructura disponible en pubspec.yaml usa shared_preferences; no se encontró Hive, Isar, Drift ni SQLite como almacenamiento de esta feature.

Patrones reutilizables:

- UserStateStorage: JSON, claves por usuario, migración de clave legacy y protección de scope.
- NotificationLocalStorageScope y SharedPreferencesNotificationHistoryStore: claves namespaced, JSON, schemaVersion, historial acotado a 30 registros, orden estable y clear.
- SharedPreferencesWeeklyReportCache: cache-first, versión de esquema, validación de datos corruptos, control de usuario/scope y fallback remoto.
- CloudCosmeticsCache: caché por usuario con timestamp y limpieza por scope.
- LocalNotificationTemplateCatalog: catálogo bundled con validación y cache en memoria.

Persistencia propuesta para Phase 1:

    completed_day_phrase_v1/<user-namespace>/<locale>

El valor debería ser un sobre JSON con schemaVersion, catalogVersion, locale, userId o namespace validado y un historial acotado de selecciones. Cada selección debe incluir como mínimo localDate, phraseId y la versión del catálogo.

La política inicial recomendada es conservar como máximo 30 fechas por usuario, con una sola selección estable por fecha; no almacenar la frase ya interpolada con nombre o racha. La selección de un día debe ser determinista después de la primera elección y cambiar sólo si se invalida la versión del catálogo o se define explícitamente otra política.

## 9. Patrón Supabase existente y recomendación

No existe una tabla de catálogo de frases de día completado en el repositorio. Sí existen dos patrones aplicables:

1. Shop: catálogo de filas activas, catalog_version, orden estable, lectura autenticada mediante Supabase y RLS de solo lectura para catálogo.
2. Weekly Report: contrato de datos versionado, RPC/lectura remota encapsulada, cache-first, validación de schemaVersion/versiones de contenido, rechazo de datos de otra cuenta y fallback a caché válida.

Para frases, la recomendación es una lectura remota encapsulada en una feature-specific data source/repository, con catálogo activo por locale, catalog_version, is_active, identificador estable y tokens permitidos. RLS debe permitir únicamente la lectura autenticada de filas activas; no debe permitirse que el cliente modifique el catálogo.

El cliente debe:

1. leer el fallback bundled/catálogo local;
2. servir una caché local válida sin bloquear Home;
3. actualizar desde Supabase de forma best-effort;
4. aceptar sólo filas con esquema, locale, tokens y versión válidos;
5. descartar resultados si cambia el usuario o scopeEpoch durante la lectura.

La migración y el seed quedan fuera de Phase 0. En Phase 1 deberá decidirse si se usa una tabla directa tipo completed_day_phrases/phrase_catalog o una API RPC versionada siguiendo Weekly Report. No se debe reutilizar una tabla de contenido no relacionada ni mezclar textos personalizados con profiles.

## 10. Flags y analítica

No se encontró un sistema general de feature flags ni un SDK de analítica de eventos de producto en el cliente. Hay telemetría interna de bootstrap y una configuración de runtime específica del Shop (ShopCloudRuntimeConfig, RutioRuntimeProfile) que falla cerrada ante configuraciones mixtas o inválidas.

Para el primer lanzamiento no hace falta añadir analítica ni una flag nueva. Si se necesita kill switch, debe seguirse el patrón de configuración de runtime existente y definirse primero el comportamiento offline. Si se quiere medir impresiones, selección o repetición de frases, hace falta un contrato explícito de privacidad, deduplicación por usuario/fecha y destino; no existe actualmente un canal genérico que se pueda asumir.

## 11. Riesgos y conflictos detectados

| Riesgo | Evidencia | Consecuencia | Resolución requerida |
|---|---|---|---|
| Confundir lista Pendientes vacía con día completado | HomeHabitsSliver y filtros de Home | Falsos positivos por estado visual | Usar selector de dominio independiente |
| Confundir ausencia de hábitos con 100% | HomeEmptyStateCard; progressRatio es null cuando total es 0 | Frase en días sin hábitos | Exigir scheduledCount > 0 |
| Saltos contados como completados | HabitDaySummary mantiene skippedHabits separado | Mensaje incorrecto | Exigir skippedCount == 0 |
| Semántica de timesPerWeek | Home marca completado por cuota semanal aunque hoy no esté hecho | No existe un criterio diario único | Decidir cuota semanal vs ocurrencia de hoy |
| Racha global demasiado amplia | _globalHabitCountsByDay usa “al menos un hábito” | Frase mostrada por una métrica equivocada | No usar globalHabitStreakSnapshot como guard |
| Fecha local/UTC | Home usa DateTime.now() local; Supabase usa fechas y timestamps que se convierten a local | Desfase alrededor de medianoche | Definir localDate como contrato y probar cambio de día |
| Datos loading/error/provisionales | home_build.dart, bootstrap y pull remoto | Frase inestable o basada en estado incompleto | Guardar sólo con estado listo y scope estable |
| Cambio de cuenta | scopeEpoch, switchLocalScope, caches namespaced | Fuga de frase o selección entre usuarios | Clave por usuario y descarte de respuestas obsoletas |
| Home se reconstruye | context.watch<UserStateStore>() y post-frame sync | Reelección de frase o parpadeo | Persistir selección por usuario/fecha |
| Nombre vacío o cambiante | displayName local, trim, fallbacks | Copy inconsistente | Resolver localmente con fallback y sin persistir nombre en catálogo |
| Catálogo remoto inválido | Patrones Shop/Weekly Report validan versiones y filas | Crash, tokens sin resolver o copy incompleto | Fallback bundled y validación estricta |
| Cache compartida por locale | preferredLocale puede cambiar | Texto en idioma anterior | Incluir locale canonizado en la clave |

## 12. Contrato recomendado antes de Phase 1

Debe quedar escrito y cubierto por pruebas el siguiente contrato:

- El ámbito es únicamente el día local actual, no el día seleccionado para consultar histórico.
- “Programado” se determina con la misma política de Home y excluye archivados y hábitos creados después del día.
- 0 hábitos programados no es un día completado.
- Un hábito pendiente invalida el día.
- Un hábito saltado invalida el día, incluso si existe otra métrica positiva.
- Un hábito de conteo sólo está completo cuando alcanza su target.
- Debe decidirse explícitamente la regla de timesPerWeek.
- El estado debe estar cargado y pertenecer al usuario/scope actuales.
- La fecha se normaliza como clave local yyyy-MM-dd; no se debe comparar un timestamp UTC directamente con esa clave.
- Cambiar de cuenta, cerrar sesión, restaurar estado o invalidar catálogo no debe conservar una selección de otra identidad.
- Reabrir un hábito en el mismo día debe recalcular el guard y dejar de mostrar la frase si vuelve a existir un pendiente.
- La selección de frase debe ser estable durante reconstrucciones de Home.
- El nombre y {streak_label} se interpolan localmente después de resolver la frase y no se envían al catálogo remoto.

## 13. Propuesta de archivos para Phase 1

La siguiente lista es deliberadamente concreta, pero no se ha creado ni modificado en Phase 0.

### Feature y dominio

- lib/features/completed_day_phrase/domain/completed_day_phrase.dart
- lib/features/completed_day_phrase/domain/completed_day_status.dart
- lib/features/completed_day_phrase/domain/completed_day_phrase_repository.dart
- lib/features/completed_day_phrase/application/completed_day_phrase_controller.dart

### Persistencia y remoto

- lib/features/completed_day_phrase/data/local/completed_day_phrase_local_store.dart
- lib/features/completed_day_phrase/data/local/shared_preferences_completed_day_phrase_store.dart
- lib/features/completed_day_phrase/data/local/completed_day_phrase_fallback_catalog.dart
- lib/features/completed_day_phrase/data/remote/completed_day_phrase_remote_data_source.dart
- lib/features/completed_day_phrase/data/remote/completed_day_phrase_repository.dart
- lib/features/completed_day_phrase/data/remote/completed_day_phrase_dto.dart
- assets/config/completed_day_phrase_catalog.v1.json

### Integración Home y copy

- lib/screens/home/logic/home_selectors.dart — exponer o consumir el selector canónico del estado del día.
- lib/screens/home/logic/home_view_data.dart — añadir los datos mínimos si se decide mantener el estado derivado dentro de Home.
- lib/screens/home/build/home_build.dart — insertar el bloque en el punto visual auditado y respetar loading/error/scope.
- lib/screens/home/build/sections/home_scrollable_content_sliver.dart — sólo si la composición sliver exige pasar el nuevo bloque por esa capa.
- lib/l10n/l10n.dart, lib/l10n/app_es.arb y lib/l10n/app_en.arb — sólo para nuevos labels/helpers locales y pluralización.

### Supabase, condicionado a confirmar el contrato remoto

- supabase/migrations/<timestamp>_create_completed_day_phrase_catalog.sql
- supabase/seed.sql o un seed versionado del catálogo, según la decisión de release existente.
- test/supabase/completed_day_phrase_catalog_migration_static_test.dart
- test/features/completed_day_phrase/data/completed_day_phrase_remote_data_source_test.dart

### Pruebas mínimas

- test/features/completed_day_phrase/domain/completed_day_status_test.dart
- test/features/completed_day_phrase/data/shared_preferences_completed_day_phrase_store_test.dart
- test/features/completed_day_phrase/application/completed_day_phrase_controller_test.dart
- test/screens/home/completed_day_phrase_home_test.dart
- extensión de test/screens/home/home_selectors_schedule_test.dart para horarios, conteos, saltos, fecha local, timesPerWeek, estado vacío y reconstrucción.

No se recomienda modificar la lógica general de UserStateStore para esta feature salvo que Phase 1 decida formalmente que el selector de estado diario debe convertirse en API compartida del store. El store existente ya ofrece historial, perfil, locale, scope y snapshot de racha suficientes para una primera integración desacoplada.

## Resultado de Phase 0

No se han realizado cambios productivos, migraciones, seeds, eventos de analítica ni cambios de UI. El único artefacto de esta fase es este documento.

