# Auditoria del estado actual de notificaciones personalizadas

Fecha de auditoria: 2026-08-28

Alcance: auditoria estatica del repositorio. No se ha modificado codigo productivo ni se ha implementado el nuevo sistema.

## 1. Resumen ejecutivo

Rutio tiene hoy un sistema de notificaciones locales "phase 1" basado en `flutter_local_notifications`, `timezone`, `flutter_timezone` y `permission_handler`. No hay integracion activa con Firebase Messaging, FCM, APNs remoto, tokens de dispositivo, push server-side, background handlers de mensajeria ni categorias/actions de iOS.

El flujo actual se apoya en dos capas principales:

- Scheduling local: `lib/services/notification_service.dart`, `notification_scheduler.dart`, `notification_rules.dart`, `notification_preferences.dart`, `notification_runtime.dart`.
- Permisos/onboarding de notificaciones: `lib/features/notifications/...` mas `lib/core/notifications/notification_permission_service.dart`.

Las notificaciones existentes son:

- Recordatorios diarios por habito.
- Cierre del dia.
- Racha en riesgo.
- Celebracion inmediata de racha.
- Reactivacion por inactividad.
- Motivacion diaria legacy.

El sistema es reutilizable como base tactica para scheduling local, permisos y reglas simples, pero no esta preparado como arquitectura de notificaciones personalizadas relacionales. Falta una entidad de dominio persistente por notificacion, aislamiento explicito por usuario en los schedules nativos, versionado de planes, trazabilidad de entregas, gestion de timezone/reinstalacion, y tests especificos de notificaciones.

Riesgo principal: las notificaciones programadas son globales al dispositivo/plugin y no estan asociadas a un usuario. El logout normal cambia el scope local, pero no cancela explicitamente los schedules. Esto puede dejar notificaciones de un usuario anterior si otra persona usa la app en el mismo dispositivo.

## 2. Arquitectura actual

### Dependencias

Declaradas en `pubspec.yaml`:

- `flutter_local_notifications: ^17.1.2`
- `permission_handler: ^11.3.1`
- `timezone: ^0.9.2`
- `flutter_timezone: ^4.1.1`

No aparecen dependencias de `firebase_messaging`, `firebase_core`, Google services, FCM ni SDK especifico de APNs remoto.

### Servicios de notificaciones

`lib/services/notification_service.dart`

- Singleton global `NotificationService.instance`.
- Inicializa `timezone`, resuelve zona local via `MethodChannel('rutio/notification_permission')`, inicializa `FlutterLocalNotificationsPlugin`, crea canal Android y ejecuta una limpieza unica de produccion.
- Orquesta `syncPhaseOne()`.
- Expone metodos manuales: `scheduleHabitDailyReminder`, `cancelHabitDailyReminder`, `scheduleDailyMotivation`, `cancelDailyMotivation`, `cancelAllNotifications`.
- Consulta y solicita permisos mediante `NotificationPermissionService`.

`lib/services/notification_scheduler.dart`

- Wrapper bajo nivel de `FlutterLocalNotificationsPlugin`.
- Construye `NotificationDetails`.
- Crea el canal Android `rutio_phase1_notifications_v1`.
- Programa notificaciones con `zonedSchedule`.
- Para diarias usa `matchDateTimeComponents: DateTimeComponents.time`.
- Cancela por id, todos los ids, rango de recordatorio de habito y prefijo de payload.
- Tiene recuperacion especifica de errores del cache Android del plugin.

`lib/services/notification_rules.dart`

- Deriva reglas desde `UserStateStore.state`.
- Calcula habitos activos, recordatorios por habito, cierre de dia, racha en riesgo, inactividad y celebraciones.
- Usa `doneToday`, `skippedToday`, `history.habitCompletions`, `history.habitCountValues`, `history.habitSkips` y `schedule`.

`lib/services/notification_preferences.dart`

- Lee/escribe preferencias desde `UserStateStore.notificationSettings` y `notificationMetadata`.
- Persiste cambios llamando a `UserStateStore.updateNotificationSettings()` y `updateNotificationMetadata()`.
- Gestiona `lastAppOpenAt` y deduplicacion diaria de celebraciones en metadata local.

`lib/services/notification_models.dart`

- Define `NotificationTime`, `NotificationCopy`, `ScheduledNotificationRequest`, `HabitReminderDefinition`, `NotificationPreferencesSnapshot`, candidatos y eventos.

`lib/services/notification_types.dart`

- Define tipos, canal Android, ids, payloads y milestones.
- IDs fijos: `dayClosure=51001`, `streakRisk=51002`, `inactivityReengagement=51003`, `dailyMotivation=90001`.
- IDs hash: `habitReminder = 10000 + (habitId.hashCode % 40000)`, `streakCelebration = 60000 + ((hash + milestone) % 10000)`.

`lib/services/notification_copy.dart`

- Copy local con variantes deterministas por hash o modulo.
- No hay personalizacion remota ni segmentacion avanzada.

`lib/services/notification_runtime.dart`

- Widget envoltorio en `main.dart` alrededor de `MaterialApp`.
- Observa `UserStateStore`.
- En primer estado cargado programa `syncPhaseOne(recordAppOpen: true)`.
- En cambios de store programa sync con debounce de 250 ms.
- En `AppLifecycleState.resumed` programa sync y registra apertura.

### Permisos

`lib/core/notifications/notification_permission_service.dart`

- Consulta status iOS primero por canal nativo `getNotificationPermissionStatus`.
- En Android combina `permission_handler` con `AndroidFlutterLocalNotificationsPlugin.areNotificationsEnabled()`.
- Solicita permiso iOS con `IOSFlutterLocalNotificationsPlugin.requestPermissions(alert,badge,sound)`.
- Solicita Android con `requestNotificationsPermission()` y fallback a `permission_handler`.
- Considera autorizado tanto `authorized` como `provisional`.

`lib/features/notifications/application/notification_permission_controller.dart`

- Une estado del sistema con estado interno local.
- Decide si mostrar prompt post-login.
- Marca prompt mostrado, soft decline y status interno.
- Expone `ensureCanScheduleFromReminderFlow()` para el caso de crear/editar habito con recordatorio.

`lib/features/notifications/data/notification_permission_preferences.dart`

- SharedPreferences global, no por usuario:
  - `notificationPermissionPromptShown`
  - `notificationPermissionInternalStatus`
  - `notificationPermissionLastUpdatedAt`

`lib/features/notifications/presentation/...`

- Bottom sheet de onboarding de permisos.
- Bottom sheet de recovery con enlace a settings.

### Persistencia local y remota

Las preferencias de notificacion viven dentro de `userState.settings.notifications`, inyectadas por defecto en `lib/stores/user_state_store_account.dart` si faltan:

- `enabled`: default `true`
- `habitReminders`: default `true`
- `dayClosure`: default `true`
- `dayClosureTime`: default `21:00`
- `streakRisk`: default `true`
- `streakCelebration`: default `true`
- `inactivityReengagement`: default `true`
- `dailyMotivation`: default `true`
- `marketing`: default `false`
- `dailyMotivationTime`: default `21:00`
- `metadata`: default `{}`

El template `assets/templates/user_state_template.json` no incluye `settings.notifications`; se crean de forma perezosa al leer getters.

Persistencia por usuario:

- `UserStateStorage` usa `SharedPreferences` con `user_state_v1_<userId>` para usuarios autenticados y `user_state_v1` para guest.
- `UserStateRepository.save()` bloquea escrituras cross-scope obvias si el payload contiene otro `userId`.

Persistencia remota parcial:

- `RemoteProfile` modela `notifications_enabled`, `daily_motivation_enabled`, `marketing_notifications_enabled`, `daily_motivation_time`.
- `ProfileRepository.updateNotificationSettings()` puede escribir esas cuatro columnas.
- `UserStateStore._bestEffortSyncNotificationSettingsPatch()` solo escribe a remoto si cambia `enabled`, `dailyMotivation`, `marketing` o `dailyMotivationTime`.
- No se ve hidratacion completa de esos valores remotos hacia `settings.notifications`; `AuthController.applySupabaseIdentity()` aplica identidad/perfil basico, no settings de notificaciones.

## 3. Flujo actual end-to-end

### Instalacion / app start

1. `main()` ejecuta `WidgetsFlutterBinding.ensureInitialized()`.
2. Inicializa Supabase.
3. Prepara demo seed si aplica.
4. Ejecuta `NotificationService.instance.init()` en best effort.
5. `NotificationService.init()`:
   - `tzdata.initializeTimeZones()`
   - resuelve timezone local por MethodChannel (`getLocalTimeZone`)
   - `tz.setLocalLocation(localLocation)`
   - inicializa plugin sin pedir permisos automaticamente
   - crea canal Android
   - ejecuta cleanup unico `rutio.notifications.production_cleanup_v1`
6. `MyApp` monta providers y envuelve `MaterialApp` en `NotificationRuntime`.

### Onboarding / post-login

1. `HomeScreen` inicializa `_schedulePostLoginNotificationPrompt()` en `initState`.
2. El prompt se difiere a post-frame.
3. `_maybeShowPostLoginNotificationPrompt()` espera a que `UserStateStore` tenga estado o agota reintentos.
4. `NotificationPermissionController.shouldShowPostLoginPrompt()` consulta:
   - `notificationPermissionPromptShown`
   - `notificationPermissionInternalStatus`
   - permiso real del sistema
5. Muestra el sheet solo si el prompt no fue mostrado y no hay estado interno final.
6. Si el usuario acepta, se marca prompt mostrado y se solicita permiso del sistema.
7. Si el usuario cierra o elige "Ahora no", se guarda `softDeclined`.
8. Si el sistema deniega, se abre el recovery sheet.

### Creacion/edicion de habitos con recordatorio

1. `CreateHabitScreen` guarda un habito con `reminderEnabled`, `remindersEnabled` y `reminderTime`.
2. Despues llama a `_syncReminderNotification(habitId)`.
3. Si el recordatorio esta activo:
   - marca el prompt post-login como mostrado
   - intenta asegurar permiso por `ensureCanScheduleFromReminderFlow()`
   - si permiso concedido, activa master y habit reminders si estaban apagados
4. Llama a `NotificationService.instance.syncPhaseOne(store: store)`.
5. `EditHabitTab` replica el mismo patron al guardar cambios de recordatorio.

### Programacion

1. `NotificationRuntime` y pantallas de settings/perfil/create/edit llaman `syncPhaseOne()`.
2. `syncPhaseOne()` sale si:
   - el plugin no inicializa
   - el state esta vacio
   - el permiso del sistema no esta autorizado
3. Si `settings.notifications.enabled` es false:
   - cancela day closure, streak risk, inactivity
   - cancela por payload `habit:`
   - cancela daily motivation
4. Si esta enabled:
   - reprograma motivacion diaria legacy si procede
   - reprograma recordatorios de habitos activos con reminder enabled
   - programa cierre de dia one-shot si hay pendientes hoy
   - programa racha en riesgo one-shot si hay candidato
   - programa reactivacion por inactividad one-shot
   - muestra celebraciones inmediatas si detecta milestone

### Entrega

La entrega es local/nativa:

- Diarias: `zonedSchedule(..., matchDateTimeComponents: DateTimeComponents.time)`.
- One-shot: `zonedSchedule()` sin `matchDateTimeComponents`.
- Celebraciones: `show()`.

No hay handling de tap/payload visible en `initialize()`: no se pasa `onDidReceiveNotificationResponse`. Por tanto el payload se usa para cancelacion/deduplicacion interna, no para navegacion profunda.

## 4. Inventario de notificaciones existentes

### Recordatorio diario de habito

- Tipo: `RutioNotificationType.habitReminder`.
- Quien programa: `NotificationService._syncHabitReminders()` via `syncPhaseOne()`. Tambien existe API directa `scheduleHabitDailyReminder()`.
- Cuando: cada sync, para habitos activos con `reminderEnabled == true` o `remindersEnabled == true`.
- ID: `RutioNotificationIds.habitReminder(habitId) = 10000 + hash % 40000`.
- Payload: `habit:<habitId>`.
- Datos: `activeHabits[].id`, `name/title`, `reminderTime`, flags de reminder.
- Dependencia: datos locales de `UserStateStore`, potencialmente sincronizados desde Supabase por otros flujos.
- Cancelacion/reprogramacion: antes de programar cancela el mismo id; cancela obsoletos por payload o por `cancelHabitReminder(habitId)`.
- Observacion: `cancelHabitReminder()` cancela `baseId + 0..63`, pero `scheduleDaily()` usa solo `baseId`. El rango parece compatibilidad/defensa frente a versiones anteriores.

### Cierre del dia

- Tipo: `dayClosure`.
- Quien programa: `NotificationService._syncScheduledRequest()` con `NotificationRules.buildDayClosureNotification()`.
- Cuando: en sync, solo si quedan habitos pendientes hoy y la hora `dayClosureTime` aun no paso.
- ID: `51001`.
- Payload: `phase1:day_closure`.
- Datos: habitos activos, schedule, completions/skips de hoy, `dayClosureTime`.
- Dependencia: local.
- Cancelacion/reprogramacion: cancela `51001` si la regla devuelve null; si hay request, cancela y programa el one-shot.
- Limitacion: si la app no vuelve a sincronizar al dia siguiente, es one-shot y no se programa por adelantado para futuros dias.

### Racha en riesgo

- Tipo: `streakRisk`.
- Quien programa: `NotificationService._syncScheduledRequest()` con `NotificationRules.buildStreakRiskNotification()`.
- Cuando: en sync, para el mejor habito pendiente hoy con racha previa >= 3.
- ID: `51002`.
- Payload: `phase1:streak_risk`.
- Hora: 90 minutos antes de `dayClosureTime`; fallback 19:30 si cae antes de las 18:00; ajuste a 45 minutos antes si no queda antes del cierre.
- Datos: historial local, schedule, done/skipped, nombres, rachas.
- Dependencia: local.
- Cancelacion/reprogramacion: cancela `51002` si no hay candidato; si hay request, cancela y reprograma.

### Celebracion de racha

- Tipo: `streakCelebration`.
- Quien programa/entrega: `NotificationService._triggerCelebrations()`.
- Cuando: inmediatamente al detectar transicion de no hecho a hecho en un habito programado hoy y racha en `[1,3,7,14,30]`.
- ID: `60000 + ((hash + milestone) % 10000)`.
- Payload: `phase1:streak_celebration:<habitId>:<milestone>`.
- Datos: previousState, currentState, history, doneToday, schedule.
- Dependencia: local.
- Cancelacion/reprogramacion: no se programa a futuro; dedup diaria por metadata `celebrationMilestones[habitId:milestone] = yyyy-mm-dd`.
- Riesgo: si `previousState` no refleja correctamente el estado anterior, puede no dispararse o dispararse mas de una vez.

### Reactivacion por inactividad

- Tipo: `inactivityReengagement`.
- Quien programa: `NotificationService._syncInactivity()` con `NotificationRules.buildInactivityNotification()`.
- Cuando: en sync si hay `lastAppOpenAt`, programada a `lastAppOpenAt + 3 dias`.
- ID: `51003`.
- Payload: `phase1:inactivity_3d`.
- Datos: metadata local `lastAppOpenAt`.
- Dependencia: local.
- Cancelacion/reprogramacion: si esta desactivada o request invalida/pasada, cancela `51003`; si procede, cancela y reprograma.
- Observacion: `recordAppOpen` se ejecuta en bootstrap/resume; eso desplaza la reactivacion cada vez que la app abre.

### Motivacion diaria legacy

- Tipo: `dailyMotivation`.
- Quien programa: `NotificationService._syncLegacyDailyMotivation()` y API directa `scheduleDailyMotivation()`.
- Cuando: cada sync si `dailyMotivation == true`.
- ID: `90001`.
- Payload: `legacy:daily_motivation`.
- Datos: `dailyMotivationTime` y copy fijo/local.
- Dependencia: local; cuatro campos pueden escribirse a Supabase pero no se ve lectura remota aplicada al store.
- Cancelacion/reprogramacion: cancela `90001` si esta desactivada; si activa, cancela y programa daily.

### Diario, recompensas y otras

No se encontro un tipo especifico de notificacion para diario ni recompensas. Hay gamificacion, diario y achievements en UI y dominio, pero no integracion con `NotificationService` salvo la celebracion local de racha.

## 5. Persistencia y scheduling

### Persistencia

- Settings por usuario: `user_state_v1_<userId>` en SharedPreferences.
- Settings globales de permiso/onboarding: SharedPreferences sin userId.
- Schedules nativos: gestionados por `flutter_local_notifications`; en Android el plugin usa prefs nativas `scheduled_notifications`.
- Metadata de dedup: `userState.settings.notifications.metadata`.

### Scheduling

- Diarias recurrentes: una notificacion programada con `DateTimeComponents.time`.
- One-shot de hoy/inactividad: una notificacion concreta.
- No hay cola propia, plan persistente, version de schedule ni reconciliador por usuario.
- No hay consulta sistematica de pending requests salvo para limpiar obsoletos por payload.
- No hay cap explicito sobre numero maximo de notificaciones salvo el numero de habitos activos.

### Timezone

- `NotificationService` inicializa `timezone` al start.
- iOS/Android devuelven `TimeZone.current.identifier` / `TimeZone.getDefault().id`.
- Fallback hardcoded: `Europe/Madrid`.
- Las reglas usan `DateTime.now()` local y luego convierten a `tz.local` al programar.
- No hay listener explicito de cambio de timezone.
- En resume se resincroniza, lo cual puede corregir schedules si el usuario abre la app despues de cambiar timezone.
- DST: las diarias por `DateTimeComponents.time` deberian seguir hora local conceptual, pero los one-shot ya programados dependen del instante calculado en la sync previa.

## 6. Auditoria especifica iOS

### Info.plist

`ios/Runner/Info.plist` contiene permisos de camara/fotos, launch storyboard y orientaciones. No contiene:

- `UIBackgroundModes` con `remote-notification`.
- claves de push remoto.
- textos especificos de notificaciones, ya que iOS no requiere usage description para notificaciones.

### AppDelegate

`ios/Runner/AppDelegate.swift`:

- Importa `UserNotifications` y `flutter_local_notifications`.
- Registra callback de plugins para local notifications.
- Asigna `UNUserNotificationCenter.current().delegate = self` en iOS 10+.
- Expone MethodChannel `rutio/notification_permission`:
  - `getNotificationPermissionStatus`
  - `getLocalTimeZone`
- Mapea `.ephemeral` como `authorized`.

### Entitlements

No se encontraron archivos `.entitlements` bajo `ios/`. Tampoco aparece `aps-environment`. Esto confirma que no hay push remoto/APNs configurado en iOS.

### Permisos

- La inicializacion del plugin usa `DarwinInitializationSettings(requestAlertPermission:false, requestBadgePermission:false, requestSoundPermission:false)`, asi que no pide permisos en startup.
- La peticion ocurre bajo intencion del usuario: onboarding sheet, settings o reminder flow.
- `provisional` existe en el enum y se considera autorizado en `NotificationPermissionResult.isAuthorized`, pero no se solicita autorizacion provisional de forma explicita. `IOSFlutterLocalNotificationsPlugin.requestPermissions()` no pasa ningun flag provisional.

### Foreground/background

- `DarwinInitializationSettings` pone `defaultPresentAlert/Badge/Sound/Banner/List` en true.
- `UNUserNotificationCenter.delegate = self` queda en `FlutterAppDelegate`; deberia permitir presentacion foreground segun configuracion del plugin.
- No hay callbacks Dart de response/tap ni background notification response.
- No hay categorias/actions iOS (`DarwinNotificationCategory`, `DarwinNotificationAction`, `UNNotificationCategory`).

### Limitaciones iOS actuales

- Solo local notifications.
- Sin deep links desde notificacion.
- Sin actions/categorias.
- Sin push remoto ni background delivery.
- Sin aislamiento nativo por usuario.
- Sin ajuste explicito al cambiar timezone salvo sync en apertura/resume.
- Sin plan persistente que permita auditar que hay realmente programado frente a lo esperado.

## 7. Integracion con onboarding/permisos

Hay dos experiencias:

- Prompt post-login en Home: soft prompt propio antes del prompt del sistema.
- Recovery sheet: tras denegacion o intento desde settings/reminder.

Reglas relevantes:

- El prompt post-login solo se muestra si `notificationPermissionPromptShown` es false y no hay estado interno final.
- `softDeclined` evita volver a mostrarlo automaticamente.
- Crear/editar un habito con recordatorio marca `promptShown=true`, intenta pedir permiso si puede y activa master/habit reminders si el usuario concede.
- Settings permite activar master/categorias y solicita permiso si hace falta.

Riesgo de producto: `notificationPermissionPromptShown` es global del dispositivo, no por usuario. Un segundo usuario podria no ver el prompt porque el primero ya lo vio o lo rechazo.

## 8. Logout y aislamiento multiusuario

### Lo que esta aislado

- `UserStateStorage` separa estado por `user_state_v1_<userId>`.
- `UserStateRepository.save()` bloquea algunas escrituras cross-scope.
- `AuthController.signOut()` cambia a scope guest, limpia wallet en memoria y suprime overlays.
- Hay tests de auth/bootstrap/scope que cubren aislamiento general, pero no schedules.

### Lo que no esta aislado

- Schedules nativos de `flutter_local_notifications`.
- SharedPreferences de permiso/onboarding de notificaciones.
- Canal Android y cache plugin.

### Logout normal

`AuthController.signOut()` y eventos de auth state cambian scope local pero no llaman a `NotificationService.cancelAllNotifications()`. Al cambiar el store a guest, `NotificationRuntime` puede sincronizar usando el nuevo estado, pero eso depende de que el runtime siga montado, de que el state guest cargue y de que haya permiso. Si el permiso no esta autorizado, `syncPhaseOne()` sale antes de cancelar schedules.

### Limpieza total / delete local

`lib/core/services/user_local_data_cleanup.dart` si llama a `NotificationService.instance.cancelAllNotifications()` antes de `store.clearLocalAccountData()`. Esto no parece ser el logout normal desde `AuthController`.

### Reinstalacion

- Android manifest tiene `android:allowBackup="false"`, reduciendo restauraciones automaticas de prefs/app data.
- iOS no tiene manejo explicito de reinstalacion.
- No hay reconciliacion por install id ni device id.

## 9. Riesgos detectados

### Alto

- Notificaciones de usuario anterior: schedules nativos no llevan userId ni se cancelan en logout normal.
- Cancelacion condicionada por permiso: `syncPhaseOne()` retorna si el permiso no esta autorizado. Si el usuario revoca permiso y luego desactiva settings, puede no limpiar schedules internos porque sale antes de la rama de cancelacion.
- Colisiones de ID por hash: `habitReminder()` usa 40.000 slots y `streakCelebration()` 10.000 slots. Con muchos habitos historicos o ids generados, dos entidades pueden compartir id.
- `String.hashCode` en Dart no debe tratarse como contrato estable cross-runtime/version para persistencia de ids. Para schedules nativos conviene ids deterministas propios.
- No hay ownership de schedule: el sistema no sabe que pending request pertenece a usuario X, plan Y o version Z.

### Medio

- `dailyMotivation` default true aunque el template no trae settings. Tras conceder permiso, podria programarse sin una eleccion explicita de esa categoria.
- `promptShown` global puede saltarse onboarding de permisos para usuarios nuevos en el mismo dispositivo.
- `softDeclined` global puede bloquear prompts posteriores aunque el usuario autenticado sea distinto.
- One-shot de cierre del dia/racha dependen de que la app sincronice ese dia antes de la hora.
- Cambio de timezone/DST no tiene detector dedicado. Resume ayuda, pero no corrige si la app no abre.
- No hay callback de tap; las notificaciones no llevan al habito/diario.
- `cancelHabitReminder()` cancela 64 ids por base; puede cancelar accidentalmente ids vecinos si hay colisiones o si futuros tipos usan rangos cercanos.
- La recuperacion Android limpia cache del plugin, pero no reconstruye inmediatamente un plan auditado por usuario; confia en siguientes syncs.

### Bajo / deuda

- El canal Android se llama "Rutio Notifications" y agrupa todos los tipos.
- No hay categorias/actions iOS.
- `repeatDaily` existe en `ScheduledNotificationRequest` pero no se usa para decidir scheduling.
- Copy esta hardcodeado y no localizado por `l10n`.
- `dailyMotivation` conserva payload `legacy:daily_motivation`, senal de deuda de migracion.

## 10. Tests actuales

No se encontraron tests especificos para:

- `NotificationService`
- `NotificationScheduler`
- `NotificationRules`
- `NotificationPreferences`
- `NotificationRuntime`
- `NotificationPermissionController`
- bottom sheets de permisos
- configuracion nativa de notificaciones

Tests relacionados indirectamente:

- `test/application/auth/auth_controller_test.dart`: logout, cambio de scope, carreras post-home.
- `test/application/bootstrap/bootstrap_controller_test.dart`: navegacion/bootstrap/onboarding y logout.
- `test/data/models/remote_profile_onboarding_test.dart`: parseo de perfil remoto; no cubre settings de notificaciones.
- `test/data/repositories/profile_repository_onboarding_test.dart`: onboarding remoto/cache; no notificaciones.
- Tests de streak timezone (`test/stores/user_state_store_streak_protection_remote_sync_test.dart`) cubren timezone de habitos/remoto, no timezone de scheduling local.

Escenarios faltantes prioritarios:

- Reglas de habit reminders por flags, horarios invalidos, habitos archivados, semanal/once/timesPerWeek.
- Day closure solo si hay pendientes y hora futura.
- Streak risk con candidatos, skips, count habits y horarios limite.
- Inactivity con `lastAppOpenAt`, resume y cancelacion.
- Celebraciones con dedup metadata y transiciones previous/current.
- Colisiones de ids y estabilidad de ids.
- Logout cancela o replanifica schedules del usuario anterior.
- Cambio de usuario A -> B -> A.
- Permiso denegado/revocado no impide limpieza de schedules obsoletos.
- Prompt post-login por usuario y soft decline.
- iOS permission mapping (`notDetermined`, `denied`, `authorized`, `provisional`, `ephemeral`).
- Android exact alarm fallback y cache recovery.
- Timezone/DST: daily y one-shot al cambiar zona.

## 11. Deuda tecnica

- Mezcla de sistema "phase 1" y legacy daily motivation.
- Logica de notificaciones acoplada al shape JSON de `UserStateStore`.
- No hay repositorio dedicado de notificaciones ni modelo persistente de plan.
- Preferencias locales y remotas no estan completamente reconciliadas.
- Settings de permisos son globales al dispositivo.
- No hay auditoria de pending notifications contra desired state.
- No hay instrumentacion de entrega, apertura o conversion.
- Sin deep links ni response handlers.
- Sin tests unitarios de reglas/scheduler.
- Sin separacion entre preferencias de canal, intencion del usuario, permiso del SO y capacidad tecnica.

## 12. Componentes reutilizables

- `NotificationPermissionService`: base util para consultar/pedir permisos por plataforma.
- `NotificationPermissionController`: reutilizable parcialmente para soft prompt, aunque debe hacerse user-aware.
- `NotificationScheduler`: wrapper aprovechable para local scheduling, con mejoras en ids, payloads y callbacks.
- `NotificationRuntime`: idea reutilizable como reconciliador ante cambios de estado/lifecycle, pero deberia delegar a un planner versionado.
- `NotificationTime`: parsing/formato HH:mm simple.
- `NotificationRules`: algunas reglas de habitos pueden migrarse a use cases puros y testeables.
- `NotificationCopyLibrary`: util como fallback local, aunque debe localizarse/personalizarse.
- MethodChannel timezone: util, aunque ya existe `flutter_timezone` en otra zona del codigo y conviene unificar.

## 13. Componentes que deberian sustituirse o refactorizarse

- IDs basados en `String.hashCode`: reemplazar por asignacion determinista estable y namespaced.
- `syncPhaseOne()` monolitico: dividir en planner, reconciler, permission gate y scheduler adapter.
- SharedPreferences globales de prompt/status: mover a estado por usuario o separar claramente device-level vs user-level.
- Payloads sin version/user/scope: reemplazar por payload estructurado versionado.
- `dailyMotivation` legacy: migrar a tipo normal del nuevo sistema o eliminar si no encaja.
- Copy hardcodeado: mover a motor de contenido/contexto con localizacion.
- Cancelacion solo por id/prefix: sustituir por reconciliacion contra manifest de schedules activos.
- Settings remotos parciales: crear contrato remoto completo o declarar explicitamente que scheduling es local-only.

## 14. Recomendacion de arquitectura objetivo a alto nivel

Propuesta:

- `NotificationIntent`: evento o necesidad de producto, por ejemplo "habito pendiente", "racha en riesgo", "volver al diario", "celebrar progreso".
- `NotificationPreferenceProfile`: preferencias por usuario, canal, quiet hours, frecuencia maxima, idioma, tono, categorias.
- `NotificationContextProvider`: compone contexto local/remoto: habitos, logs, rachas, diario, rewards, timezone, ultima apertura.
- `NotificationPlanner`: genera un `NotificationPlan` determinista para usuario + fecha + version.
- `NotificationScheduleManifest`: persistencia local del plan aplicado, con userId, installId, planVersion, notificationId, type, payload, scheduledFor, sourceDataHash.
- `NotificationReconciler`: compara desired plan contra pending/native + manifest, cancela obsoletas y programa faltantes.
- `NotificationSchedulerAdapter`: encapsula `flutter_local_notifications`.
- `NotificationPermissionCoordinator`: separa permiso SO, soft prompt, decision del usuario, y capacidad tecnica.
- `NotificationInteractionRouter`: maneja tap/actions y deep links a habito, diario, stats o reward.
- `NotificationTelemetry`: registra scheduled/delivered/opened/dismissed cuando sea posible.

Para iOS-first:

- Mantener local notifications para recordatorios predictibles.
- Anadir categorias/actions solo cuando haya UX clara.
- Preparar APNs/FCM solo si se necesitan mensajes server-driven, experimentos remotos o reengagement fuera del conocimiento local.
- Usar calendario/timezone local conscientemente y replanificar en app start/resume/day boundary/timezone change.

## 15. Propuesta de fases de implementacion

### Fase 0: hardening antes de personalizacion

- Crear tests unitarios de `NotificationRules`.
- Crear fake scheduler para probar `syncPhaseOne()` sin plugin real.
- Documentar matriz de tipos/ids/payloads actual.
- Decidir politica de logout: cancelar todo o mantener solo schedules del mismo usuario autenticado.

### Fase 1: aislamiento y reconciliacion

- Introducir manifest local por usuario.
- Reemplazar ids hash por ids estables namespaced.
- Incluir user/scope/version en payload.
- Cancelar schedules al logout/cambio de usuario antes de cargar scope nuevo.
- Permitir limpieza aunque el permiso del SO este denegado.

### Fase 2: planner personalizado local

- Extraer reglas a `NotificationPlanner`.
- Anadir limites de frecuencia, quiet hours y deduplicacion por tipo.
- Incorporar contexto de diario/recompensas si el producto lo decide.
- Localizar copy y separar tono/plantillas.

### Fase 3: experiencia iOS

- Anadir response handlers y deep links.
- Evaluar categorias/actions iOS: completar habito, posponer, abrir diario.
- Validar foreground presentation.
- Crear pruebas manuales iOS por permisos, background, DST/timezone y reinstall.

### Fase 4: remoto opcional

- Definir contrato Supabase para preferencias completas y/o plantillas remotas.
- Evaluar APNs/FCM solo si hacen falta push remotas reales.
- Si se adopta push remoto, agregar tokens por usuario/dispositivo, opt-in, revocacion, logout cleanup y RLS.

### Fase 5: observabilidad y experimentacion

- Instrumentar scheduled/opened/actioned.
- Dashboard de salud: duplicados, schedules obsoletos, fallos plugin.
- Tests de regresion multiusuario y timezone.
- Rollout gradual por feature flag.
