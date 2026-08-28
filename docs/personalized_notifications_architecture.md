# Arquitectura tecnica del nuevo sistema de Notificaciones Personalizadas

Fecha de diseno: 2026-08-28

Base de partida: [docs/personalized_notifications_current_state_audit.md](D:/dev/alpha/rutio_app/docs/personalized_notifications_current_state_audit.md)

Alcance: diseno tecnico de produccion. No se implementan cambios productivos, migraciones ni cambios de comportamiento en esta fase.

## 1. Decisiones de arquitectura

### Decision 1: mantener local notifications como base V1

La auditoria demuestra que Rutio hoy solo tiene notificaciones locales con `flutter_local_notifications`, sin FCM ni APNs remoto. La recomendacion para V1 es mantener ese modelo para:

- recordatorios explicitos de habitos;
- notificaciones generales/personalizadas derivadas de contexto local;
- scheduling robusto iOS-first sin dependencia de red.

Motivo:

- el producto exige que las notificaciones principales no dependan de red;
- el estado actual del repo ya tiene un runtime local reutilizable;
- empujar FCM/APNs ahora aumentaria complejidad, permisos, backend y riesgos sin resolver primero multiusuario, anti-repeticion e ids.

### Decision 2: un unico owner de scheduling y reconciliacion

Ningun widget, screen, controller de feature ni flujo de onboarding debe programar notificaciones directamente.

Owner unico propuesto:

- `NotificationOrchestrator`

Responsabilidades:

- cargar contexto;
- construir plan deseado;
- reconciliarlo con el manifiesto local y con el scheduler nativo;
- programar, cancelar y reprogramar;
- ejecutar cleanup de logout/cambio de usuario.

Conflicto con el estado actual:

- hoy `NotificationService.syncPhaseOne()` se invoca desde runtime, settings, perfil, create habit y edit habit.
- eso debe evolucionar hacia llamadas al orquestador, pero manteniendo compatibilidad incremental con el flujo actual de permisos.

### Decision 3: separar claramente las capas

El nuevo sistema separa seis decisiones distintas:

1. `Permission`: si legalmente/tecnicamente podemos notificar.
2. `Preferences`: cuanto, cuando y con que intensidad quiere el usuario.
3. `Context`: que sabemos hoy del usuario.
4. `Intent`: que seria util comunicar.
5. `Template selection`: como formularlo sin repetir.
6. `Scheduling`: cuando y con que identificador se entrega.

Esto evita que `NotificationService` siga creciendo como monolito.

### Decision 4: dos familias de producto con reglas independientes

La capa de producto debe distinguir desde el modelo:

- `habit_reminder`: recordatorios explicitos configurados por el usuario por habito.
- `general_personalized`: mensajes de Rutio derivados de contexto, frecuencia y presets.

Motivo:

- el producto ya exige una capa diferenciada entre ambos grupos;
- las reglas de frecuencia y ownership son distintas;
- ayuda a respetar el limite de pending notifications de iOS.

### Decision 5: V1 local-first, catalogo de mensajes hibrido

El catalogo de copy no debe quedar hardcodeado en codigo. Para V1 se recomienda un sistema hibrido:

- catalogo estructurado local versionado;
- templates localizados por `l10n`/ARB;
- metadata local para pesos, cooldowns, tags, variables y reglas de elegibilidad;
- opcion futura de overlay remoto desde Supabase.

Motivo:

- evita dependencia de red para programar;
- permite evolucionar mensajes y reglas sin convertir todo en ARB plano;
- deja abierta una futura ampliacion remota.

### Decision 6: idempotencia y aislamiento multiusuario son requisitos de foundation

Antes de sofisticar copy o contexto, el sistema debe asegurar:

- ids estables sin colisiones por hash;
- manifiesto local por usuario;
- cleanup explicito de logout;
- reconciliacion segura aunque el permiso del SO este denegado;
- payloads con namespace y version.

## 2. Diagrama textual del flujo

```text
Auth validada
  ->
NotificationOrchestrator.reconcile(trigger)
  ->
NotificationPermissionCoordinator.getSchedulingCapability()
  ->
NotificationContextAssembler.build(userScope)
  ->
NotificationCandidateGenerator.generate(context)
  ->
NotificationEligibilityEvaluator.filter(candidates, preferences, capability)
  ->
NotificationPrioritizer.rank(candidates)
  ->
NotificationTemplateSelector.select(candidate, messageHistory, locale)
  ->
NotificationPlanBuilder.build(planDateWindow, iosBudget)
  ->
NotificationScheduleReconciler.diff(desiredPlan, localManifest, nativePending)
  ->
NotificationSchedulerAdapter.apply(diff)
  ->
NotificationManifestRepository.save(appliedPlan)
  ->
TelemetrySink.record(scheduled/suppressed/cancelled)
```

Flujo de apertura/tap:

```text
Local notification tap
  ->
NotificationInteractionRouter.parsePayload()
  ->
validate user scope + family + entity
  ->
route to target screen
  ->
TelemetrySink.record(opened)
```

## 3. Componentes y responsabilidades

### Capa de dominio

`NotificationKind`

- `habitReminder`
- `generalDayClosure`
- `generalStreakRisk`
- `generalDailyReflection`
- `generalInactivity`
- `generalProgressNudge`
- `generalDiaryPrompt`
- `celebrationStreak`
- `futureWeeklyReport`

`NotificationFamily`

- `habitReminder`
- `personalizedGeneral`
- `celebration`
- `system`

`NotificationTriggerReason`

- `appBootstrap`
- `postLogin`
- `preferencesChanged`
- `habitCreated`
- `habitUpdated`
- `habitDeleted`
- `habitArchived`
- `habitReminderToggleChanged`
- `dayBoundary`
- `timezoneChanged`
- `appResumed`
- `logout`
- `manualRecovery`

`NotificationIntensityPreset`

- `light`
- `balanced`
- `active`

### Capa de coordinacion

`NotificationOrchestrator`

- API unica usada por la app.
- Expone:
  - `reconcile(trigger, scope)`
  - `cancelAllForScope(scope)`
  - `handleLogout(previousScope)`
  - `handlePermissionStateChanged(scope)`

`NotificationPermissionCoordinator`

- Envuelve el flujo actual de `NotificationPermissionService` y `NotificationPermissionController`.
- Separa:
  - `permissionState`: status del SO;
  - `promptPolicyState`: si mostrar soft prompt;
  - `schedulingCapability`: si hoy podemos programar localmente.
- Mantiene el flujo actual de onboarding, adaptandolo en lugar de sustituirlo.

`NotificationContextAssembler`

- Construye un `NotificationContextSnapshot` inmutable y testeable.
- Lee solo desde repositorios/controladores autorizados, no desde widgets.

`NotificationPlanBuilder`

- A partir de candidatos y preferencias genera un `NotificationPlan`.
- Aplica presupuesto iOS y reglas de frecuencia.

`NotificationScheduleReconciler`

- Compara `desiredPlan` vs `NotificationManifest` local vs `pendingNative`.
- Decide:
  - `schedule`
  - `reschedule`
  - `cancel`
  - `keep`

### Capa de contenido

`NotificationMessageCatalog`

- Resuelve definiciones de mensaje por clave de template.
- No devuelve strings finales directos; devuelve un template descriptor.

`NotificationTemplateRenderer`

- Renderiza copy localizada con variables.
- Usa ARB/l10n para textos finales.

`NotificationTemplateSelector`

- Selecciona el mejor template elegible evitando repeticion.

### Capa de persistencia

`NotificationManifestRepository`

- Persistencia local por usuario del plan aplicado.

`NotificationMessageHistoryRepository`

- Persistencia local por usuario del historial reciente de mensajes usados.

`NotificationPreferencesRepository`

- Fachada para preferencias locales y, mas adelante, write-through remoto.

`NotificationSettingsRemoteContract`

- Contrato de datos propuesto para Supabase, no implementado todavia.

### Capa de plataforma

`NotificationSchedulerAdapter`

- Adapta `flutter_local_notifications`.
- Unico punto autorizado para hablar con el plugin.

`NotificationPlatformClock`

- Fuente de hora actual, timezone efectiva y cambios de zona.

`NotificationInteractionRouter`

- Maneja taps y acciones futuras.

## 4. Modelo de datos

### Entidades y value objects

`NotificationScope`

- `userId`
- `scopeEpoch`
- `installId`
- `locale`

Uso:

- identifica de forma estable a quien pertenece el plan actual;
- separa un mismo usuario en reinstalaciones distintas si mas adelante hace falta.

`NotificationPreferences`

- `masterEnabled`
- `habitRemindersEnabled`
- `generalNotificationsEnabled`
- `intensityPreset`
- `generalNotificationCapPerDay`
- `maxAdditionalContextualPerDay`
- `preferredGeneralWindow`
- `dayClosureTime`
- `dailyAnchorTime`
- `quietHoursStart`
- `quietHoursEnd`
- `useWakeTimeAsAnchor`
- `wakeTimeSource`
- `fallbackAnchorPolicy`

Notas:

- `generalNotificationsEnabled` debe separarse de `habitRemindersEnabled`.
- `generalNotificationCapPerDay` modela la regla de producto de aproximadamente 2 notificaciones generales base.
- `maxAdditionalContextualPerDay` cubre las hasta 2 adicionales.

`WakeTimeSource`

- `userConfigured`
- `derivedFromProfile`
- `derivedFromUsage`
- `fallbackDefault`
- `unknown`

V1 recomendada:

- si no hay hora configurada ni wake time disponible, usar fallback explicito `20:30` local para generales.
- no inferir wake time de manera silenciosa hasta que exista una senal bien definida.

`NotificationContextSnapshot`

- `scope`
- `now`
- `timezoneId`
- `calendarDate`
- `activeHabitsSummary`
- `pendingHabitsToday`
- `completedHabitsToday`
- `bestStreakRisk`
- `streakMilestonesTriggered`
- `lastAppOpenAt`
- `recentAppOpenCount7d`
- `latestDiaryEntryAt`
- `latestMood`
- `progressTodayRatio`
- `recentMessageHistory`
- `permissionState`

V1 realista:

- usar solo senales ya presentes o muy cercanas al repo:
  - habitos activos;
  - pendientes hoy;
  - racha;
  - `lastAppOpenAt`;
  - locale;
  - timezone;
  - historial reciente de mensajes.

`NotificationCandidate`

- `candidateId`
- `kind`
- `family`
- `priorityScore`
- `baseWeight`
- `reasonCode`
- `schedulePolicy`
- `copyContext`
- `dedupeKey`
- `cooldownKey`
- `originSignals`

`NotificationTemplateDescriptor`

- `templateId`
- `templateKey`
- `localeNamespace`
- `requiredVariables`
- `categoryTags`
- `weight`
- `cooldown`
- `maxUsesPer7d`
- `compatibleKinds`

`NotificationScheduleSpec`

- `scheduleType`: `exactDateTime` or `dailyClockTime`
- `scheduledLocalDateTime`
- `timeWindow`
- `repeats`
- `anchorSource`
- `timezoneIdAtPlanTime`

`NotificationPlanEntry`

- `notificationKey`
- `platformId`
- `family`
- `kind`
- `entityRef`
- `payloadVersion`
- `payload`
- `templateId`
- `renderedTitle`
- `renderedBody`
- `scheduleSpec`
- `planVersion`
- `sourceFingerprint`

`NotificationPlan`

- `scope`
- `generatedAt`
- `windowStart`
- `windowEnd`
- `entries`
- `suppressedCandidates`
- `planVersion`

`NotificationDeliveryRecord`

- `notificationKey`
- `userId`
- `templateId`
- `kind`
- `scheduledAt`
- `openedAt`
- `deliveredObservedAt`
- `dismissedObservedAt`
- `suppressionReason`

`NotificationSuppressionReason`

- `permissionDenied`
- `masterDisabled`
- `familyDisabled`
- `cooldownActive`
- `duplicateTemplate`
- `dailyCapReached`
- `iosBudgetReached`
- `noEligibleTemplate`
- `noRelevantContext`
- `scopeMismatch`
- `outsideAllowedWindow`
- `logoutCleanup`

## 5. Estrategia de copies

### Comparativa requerida

#### A. ARB/l10n puro

Ventajas:

- ya existe infraestructura `l10n`;
- fuerte soporte multiidioma;
- build-time safe para claves.

Problemas:

- ARB plano no modela bien pesos, cooldowns, categorias, compatibilidad por kind ni versionado de catalogo;
- mezclar metadata avanzada en ARB seria torpe y dificil de mantener.

Veredicto:

- insuficiente como sistema completo.

#### B. Catalogo local estructurado + claves l10n

Propuesta:

- archivo local estructurado, por ejemplo JSON, con:
  - `templateId`
  - `kind`
  - `l10nKeyTitle`
  - `l10nKeyBody`
  - `weight`
  - `cooldownHours`
  - `categoryTags`
  - `requiredVariables`
  - `maxUsesPer7d`
- strings finales en ARB.

Ventajas:

- sin dependencia de red;
- metadata rica;
- compatible con tests deterministas;
- buena evolucion incremental.

Problemas:

- cambiar catalogo requiere release;
- si el catalogo crece mucho, necesitara versionado interno cuidadoso.

Veredicto:

- muy buena opcion para V1.

#### C. Catalogo remoto Supabase

Ventajas:

- cambios de copy y pesos sin release;
- experimentacion futura.

Problemas:

- contradice el requisito de no depender de red para programar;
- complejiza cache, versionado y fallback;
- en V1 puede degradar la solidez iOS-first.

Veredicto:

- no recomendable como fuente primaria V1.

#### D. Sistema hibrido

Propuesta:

- base local estructurada + ARB;
- overlay remoto opcional con cache local y version;
- si no hay red o overlay invalido, se usa siempre el base local.

Ventajas:

- robustez local;
- apertura a futuro.

Problemas:

- mas complejidad que B;
- requiere contrato de merge y priorizacion.

Veredicto:

- mejor arquitectura objetivo.

### Recomendacion V1

Usar `B` en la implementacion inicial, pero disenando ya interfaces compatibles con `D`.

Estructura recomendada:

- `assets/config/notification_message_catalog.v1.json`
- `lib/l10n/app_*.arb` para `titleKey` y `bodyKey`

Ejemplo conceptual:

```json
{
  "version": 1,
  "templates": [
    {
      "templateId": "general_day_closure_gentle_01",
      "kind": "generalDayClosure",
      "titleKey": "notifGeneralTitleRutio",
      "bodyKey": "notifDayClosureGentle01",
      "weight": 10,
      "cooldownHours": 48,
      "maxUsesPer7d": 2,
      "categoryTags": ["closure", "gentle"],
      "requiredVariables": ["pending_count"]
    }
  ]
}
```

## 6. Selection engine

### Objetivo

El motor decide que comunicar y como formularlo sin repartir logica por widgets.

### Pipeline recomendado

1. `Candidate generation`
   - genera candidatos puros desde el contexto.
2. `Eligibility`
   - elimina candidatos no permitidos por preferencias, estado del usuario o ventanas horarias.
3. `Priority and quota`
   - aplica caps por familia, preset e iOS budget.
4. `Template selection`
   - elige template elegible con anti-repeticion.
5. `Schedule build`
   - asigna la ventana y hora exacta.

### Reglas de frecuencia base

Separacion de familias:

- `habitReminder`
  - governed by explicit habit config.
- `personalizedGeneral`
  - governed by preset y caps.

Base de producto recomendada:

- si el usuario no tiene recordatorios de habitos:
  - objetivo base: hasta 2 generales al dia.
- adicionales contextuales:
  - hasta 2 mas segun contexto y preset.

Interpretacion operativa:

- `light`: 1 base + 0 o 1 contextual.
- `balanced`: hasta 2 base + hasta 1 contextual.
- `active`: hasta 2 base + hasta 2 contextuales.

Estas cifras deben modelarse como politica configurable, no como `if` hardcodeado en scheduler.

### Anti-repeticion

Sistema recomendado, barato y mantenible:

- historial local por usuario de los ultimos N templates enviados;
- cooldown por `templateId`;
- cooldown por `categoryTag` dominante;
- penalizacion si el mismo `kind` fue usado recientemente;
- weighted random determinista sobre un seed diario por usuario;
- fallback a template menos usado si todos quedan penalizados.

Algoritmo propuesto:

1. filtrar templates incompatibles por variables y kind;
2. descartar templates en cooldown duro;
3. calcular `effectiveWeight`:
   - `baseWeight`
   - multiplicado por penalizaciones de uso reciente;
4. ordenar con random estable seeded:
   - seed = `userId + date + kind + candidateId`;
5. elegir el primero con score mas alto.

Cooldowns recomendados V1:

- mismo `templateId`: 48 horas;
- misma `categoryTag`: 24 horas;
- mismo `kind` general: preferir alternancia si existe otro candidato util.

Persistencia minima:

- ultimos 30 envios por usuario;
- contador rolling 7d por `templateId`;
- ultima fecha por `kind` y por `categoryTag`.

### Determinismo y testabilidad

Para tests:

- inyectar clock;
- inyectar random source seeded;
- inyectar catalogo fijo;
- inyectar historial fijo.

## 7. Scheduling y reconciliacion

### Owner unico

El unico owner autorizado debe ser `NotificationOrchestrator`, que internamente usa `NotificationSchedulerAdapter`.

No deben programar directamente:

- `HomeScreen`
- `CreateHabitScreen`
- `EditHabitTab`
- `NotificationSettingsScreen`
- `ProfileScreen`
- `NotificationRuntime`

Esas capas solo deben emitir triggers al orquestador.

### Trigger points de reconciliacion

Obligatorios:

- login con scope valido;
- bootstrap al cargar estado de usuario;
- cambio de preferencias de notificaciones;
- creacion de habito;
- edicion de habito;
- archivado o eliminacion de habito;
- toggle de recordatorios;
- cambio de timezone detectado;
- vuelta a foreground cuando cambie el dia o la timezone;
- logout;
- recuperacion manual tras cambios de permiso.

### Politica de reconciliacion

`reconcile(trigger)` debe ser idempotente:

1. leer scope actual;
2. construir `NotificationContextSnapshot`;
3. construir `desiredPlan`;
4. leer `manifest` local del scope;
5. leer `nativePending`;
6. calcular diff;
7. aplicar cancels primero;
8. aplicar schedules;
9. guardar nuevo manifest;
10. registrar telemetria.

### Politica de permission gate

Importante por conflicto con el sistema actual:

- el permiso del SO no debe impedir cleanup ni cancelacion.

Regla:

- `canScheduleNewEntries == false` bloquea altas nuevas;
- `canCancelExistingEntries == true` siempre que el plugin este operativo.

Esto corrige el riesgo actual identificado en la auditoria.

### Limite de pending notifications en iOS

Apple impone un limite practico de 64 pending notifications locales por app. El diseno debe asumirlo como restriccion fuerte.

Reglas propuestas:

- los recordatorios diarios de habito usan triggers repetitivos por hora local, no una cola infinita de instancias futuras;
- las generales no se programan a mas de una ventana corta, por ejemplo 24 a 72 horas maximo;
- el planner calcula `iosPendingBudget`;
- si el presupuesto se agota:
  - prioridad 1: habit reminders explicitos;
  - prioridad 2: generals de mayor utilidad contextual;
  - prioridad 3: experimentales o secundarios.

Recomendacion V1:

- programar solo:
  - recordatorios diarios de habito activos;
  - generales del dia actual y, como mucho, la siguiente ventana inmediata;
  - no programar una semana completa de generales.

## 8. IDs

### Problema actual

Hoy se usan ids hash basados en `String.hashCode`, con riesgo de colision e inestabilidad.

### Propuesta

Separar dos conceptos:

- `notificationKey`: identificador semantico estable, string.
- `platformId`: entero estable para el plugin.

#### `notificationKey`

Formato:

```text
rutio:v2:{family}:{kind}:{scopeHash}:{entityRef}:{slot}
```

Ejemplos:

- `rutio:v2:habit:habitReminder:u12ab:h_custom_123:daily`
- `rutio:v2:general:generalDayClosure:u12ab:today:slot_1`
- `rutio:v2:celebration:celebrationStreak:u12ab:h_custom_123:m7`

#### `platformId`

Estrategia:

- reservar rangos por familia;
- usar un asignador determinista persistido en el manifiesto local;
- nunca derivarlo de `hashCode` directo.

Rangos sugeridos:

- `1000-19999`: habit reminders
- `20000-29999`: personalized general
- `30000-39999`: celebrations
- `40000-49999`: diary
- `50000-59999`: weekly reports
- `90000-99999`: sistema/migracion

Asignacion:

- para entidades estables, derivar a partir de un hash criptografico truncado sobre `notificationKey`, con resolucion de colisiones persistida;
- o mas simple para V1:
  - `platformIdAllocator` local por usuario/familia que asigne y recuerde ids por `notificationKey`.

La segunda opcion es mas facil de auditar en este repo.

### Payload

Payload versionado:

```json
{
  "v": 2,
  "notificationKey": "rutio:v2:general:generalDayClosure:u12ab:today:slot_1",
  "family": "general",
  "kind": "generalDayClosure",
  "userId": "user_123",
  "scopeEpoch": 7,
  "entityRef": "today",
  "route": "home",
  "templateId": "general_day_closure_gentle_01"
}
```

Esto permite cancelacion selectiva, routing y validacion de scope al abrir.

## 9. Timezone

### Principios

- todas las decisiones de negocio se calculan con `timezoneId` explicita;
- los schedules se expresan en hora local del usuario;
- la reconciliacion debe ejecutarse al detectar cambio de timezone o cambio de fecha;
- los one-shot no deben sobrevivir ciegamente a cambios de zona.

### Fuente de timezone

Recomendacion:

- unificar la obtencion de timezone en un `NotificationPlatformClock` reutilizable;
- reutilizar el canal nativo actual mientras no se consolide con `flutter_timezone`.

### Reglas

- `dailyClockTime`:
  - se interpreta siempre en la timezone local efectiva del momento de planificacion;
  - en iOS usar `UNCalendarNotificationTrigger` indirectamente via plugin.
- `exactDateTime`:
  - si cambia timezone y el evento aun no se ha disparado, se reevalua en la siguiente reconciliacion;
  - si el motivo era "hoy por la tarde", debe moverse con el nuevo "hoy por la tarde", no quedarse anclado al instante absoluto antiguo.

### DST y viajes

Politica recomendada:

- habit reminders y anchors diarios:
  - semanticamente ligados a hora local.
- generals contextuales de "hoy":
  - semanticamente ligados al dia local actual.
- celebraciones inmediatas:
  - no se reprograman, se emiten o no se emiten.

### Deteccion

Triggers minimos:

- al start;
- en resume;
- si el `timezoneId` actual difiere del guardado en el manifiesto;
- si el `localDateKey` actual difiere del de la ultima reconciliacion.

## 10. Multiusuario

### Requisito fuerte

No debe ser posible que:

1. usuario A cierre sesion;
2. entre usuario B;
3. B reciba una notificacion planificada con contexto de A.

### Diseno propuesto

`NotificationScope` debe incluir:

- `userId`
- `scopeEpoch`
- `installId`

Reglas:

- todo manifest es por `userId`;
- todo historial de mensajes es por `userId`;
- todo payload incluye `userId` y `scopeEpoch`;
- al abrir una notificacion se valida que coincide con el scope autenticado actual;
- si no coincide, no se navega y se registra `scopeMismatch`.

### Cleanup de logout

`AuthController.signOut()` o una capa invocada por el debe llamar explicitamente:

- `NotificationOrchestrator.handleLogout(previousScope)`

Comportamiento:

1. leer manifiesto del scope anterior;
2. cancelar todos sus `platformId`;
3. limpiar historia y manifest en memoria activa;
4. opcionalmente conservar preferencias remotas del usuario, pero nunca schedules nativos activos.

Esto no debe depender de que el runtime o el store guest terminen una sync posterior.

### Prompt y permission state

Conflicto con el estado actual:

- hoy `notificationPermissionPromptShown` y `internalStatus` son globales.

Diseno recomendado:

- distinguir:
  - `systemPermissionState`: device-level;
  - `userPromptPolicyState`: user-level.

V1 incremental:

- mantener la lectura del permiso del sistema como device-level;
- migrar el estado de soft prompt a una clave por usuario.

## 11. Persistencia local y remota

### Local

`NotificationManifest`

- store local por usuario.
- Contiene:
  - `userId`
  - `scopeEpochAtPlanTime`
  - `timezoneId`
  - `lastReconciledAt`
  - `lastReconciledDateKey`
  - `entries[]`
  - `platformIdIndex`

`NotificationMessageHistory`

- por usuario:
  - ultimos envios;
  - ultimo uso por `templateId`;
  - ultimo uso por categoria;
  - contadores 7d.

`NotificationPreferencesLocal`

- por usuario:
  - familia habit reminders;
  - familia general personalized;
  - preset intensidad;
  - caps;
  - ventanas horarias;
  - anchor/fallback.

`NotificationPromptPolicyLocal`

- por usuario:
  - `postLoginPromptShown`
  - `softDeclinedAt`
  - `lastPromptedAt`

`NotificationDeviceStateLocal`

- global dispositivo:
  - `lastKnownSystemPermissionStatus`
  - `installId`
  - `lastKnownTimezoneId`

### Remoto Supabase

No crear migraciones ahora. Solo contrato propuesto.

`profiles` o tabla futura asociada:

- `notifications_enabled`
- `habit_reminders_enabled`
- `general_notifications_enabled`
- `notification_intensity_preset`
- `notification_daily_cap`
- `notification_additional_cap`
- `notification_anchor_time`
- `notification_quiet_hours_start`
- `notification_quiet_hours_end`
- `notification_wake_time`
- `notification_wake_time_source`
- `marketing_notifications_enabled`

Principio:

- remoto para preferencias portables entre dispositivos;
- local para manifest, schedules pendientes e historial de mensajes;
- derivado para candidatos, planes y suppression reasons.

### Derivados

Derivados, no fuente primaria:

- `NotificationContextSnapshot`
- `NotificationPlan`
- candidatos elegibles
- puntuaciones de prioridad

## 12. Diseno iOS

### Pending notifications

- tratar 64 como presupuesto maximo estricto;
- reservar la mayor parte a recordatorios explicitos;
- mantener generales en horizonte corto.

### Triggers

- para habit reminders diarios:
  - scheduling por hora local diaria.
- para generales:
  - `UNCalendarNotificationTrigger` equivalente via plugin, ligado a fecha/hora local.

### Timezone y DST

- el manifiesto guarda `timezoneIdAtPlanTime`;
- si cambia, reconciliar y sustituir one-shots pendientes;
- no confiar en que iOS reinterpretara toda la intencion de producto por si solo.

### Permisos

Mantener el flujo actual de soft prompt + prompt del sistema. No sustituirlo salvo para:

- mover el estado de prompt a user scope;
- anadir una politica explicita de cuando mostrar el prompt para generales.

### Provisional authorization

Estado actual:

- el repo reconoce `provisional`, pero no la solicita.

Recomendacion:

- no hacerla parte de V1 foundation;
- documentar una evaluacion posterior.

Motivo:

- puede ser util en iOS-first para introducir valor sin friccion total;
- pero cambia UX, copy y estrategia del onboarding, y no debe mezclarse con la fase de foundation.

### Categories y actions

No son necesarias para foundation V1.

Posibles acciones futuras:

- abrir habito;
- abrir diario;
- posponer recordatorio;
- marcar como hecho si el modelo de consistencia lo permite.

Solo introducirlas cuando haya routing y validacion de scope robustos.

### Foreground behavior

Mantener presentacion foreground compatible con la inicializacion actual, pero anadir despues:

- callback de tap;
- trazabilidad de apertura;
- politicas para evitar ruido si la app ya esta en primer plano en la pantalla relevante.

## 13. Observabilidad

Eventos internos futuros recomendados:

- `notification_reconcile_started`
- `notification_reconcile_completed`
- `notification_candidate_generated`
- `notification_candidate_suppressed`
- `notification_template_selected`
- `notification_scheduled`
- `notification_rescheduled`
- `notification_cancelled`
- `notification_opened`
- `notification_scope_mismatch_ignored`
- `notification_cleanup_logout`

Campos comunes:

- `user_id_hash`
- `scope_epoch`
- `kind`
- `family`
- `template_id`
- `trigger_reason`
- `timezone_id`
- `scheduled_local_time`
- `suppression_reason`
- `intensity_preset`
- `ios_pending_count`

Sobre `delivered` y `dismissed`:

- `delivered` no siempre es medible de forma fiable con local notifications;
- `dismissed` es aun menos portable.

Recomendacion:

- modelarlos como eventos opcionales `best effort`;
- no usarlos como dependencia de reglas V1.

## 14. Testing

### Unit

- `NotificationCandidateGenerator`
- `NotificationEligibilityEvaluator`
- `NotificationPrioritizer`
- `NotificationTemplateSelector`
- `NotificationPlanBuilder`
- `NotificationScheduleReconciler`
- `NotificationIdAllocator`
- `NotificationPayloadCodec`

### Scheduler

- fake adapter para comprobar:
  - schedule
  - reschedule
  - cancel
  - keep
- caso de plugin cache recovery Android sin romper manifiesto.

### Selection engine

- cooldown por template;
- alternancia por categoria;
- weighted selection estable;
- fallback cuando todo esta penalizado;
- caps por preset.

### Timezone y DST

- `Europe/Madrid` con cambio DST;
- viaje `Europe/Madrid -> America/New_York`;
- cambio manual de hora;
- reconcile idempotente con misma timezone.

### Multiusuario

- A programa, logout, cleanup, login B, cero schedules de A;
- A y B con preferencias distintas;
- tap sobre payload de A con B autenticado;
- guest scope no hereda schedules autenticados.

### Preference changes

- apagar master cancela;
- apagar solo generales conserva habit reminders;
- cambiar preset reduce o expande budget;
- cambiar hora reprograma sin duplicar.

### iOS budget

- 70 habitos con reminder no deben sobrepasar politica definida;
- generales deben sacrificarse antes que habit reminders;
- `keep` de entradas validas evita churn innecesario.

## 15. Migracion desde el sistema actual

### Principios

- no romper habit reminders;
- no sustituir de golpe onboarding/permisos;
- introducir componentes en paralelo;
- migrar feature por feature.

### Paso 1: foundation sin cambiar UX

- introducir `NotificationOrchestrator` como fachada;
- hacer que las llamadas actuales a `syncPhaseOne()` deleguen internamente;
- introducir `NotificationManifestRepository` local;
- introducir `NotificationIdAllocator` estable.

### Paso 2: hardening de cleanup y multiusuario

- logout llama cleanup explicito;
- cancelacion no depende del permiso del SO;
- prompt policy se separa en device-level y user-level.

### Paso 3: encapsular el sistema actual como providers de candidatos

- mover:
  - habit reminders
  - day closure
  - streak risk
  - inactivity
  - celebration
- desde `NotificationRules` a generadores de candidatos.

Asi reutilizamos la logica actual donde tenga sentido.

### Paso 4: introducir catalogo de mensajes

- reemplazar `NotificationCopyLibrary` hardcodeado por:
  - catalogo estructurado local
  - renderer l10n

### Paso 5: introducir preferencias nuevas de generales

- mantener compatibilidad con settings actuales;
- anadir separacion `habit reminders` vs `general personalized`;
- luego sumar preset/intensidad y hora base.

### Paso 6: integrar nuevas senales contextuales

- progreso del dia;
- diario/mood;
- actividad reciente;
- historial de mensajes.

### Paso 7: eliminar deuda legacy

- retirar `dailyMotivation` legacy cuando el nuevo motor absorba su caso de uso;
- retirar ids hash;
- retirar scheduling directo desde pantallas.

## 16. Fases propuestas

### Fase A: Foundation

- orquestador
- adapter scheduler
- manifiesto local
- id allocator estable
- payload codec v2
- tests basicos de reconcile

### Fase B: Hardening

- cleanup explicito en logout
- cancel aunque permiso denegado
- scope validation en payload tap
- prompt policy por usuario
- tests multiusuario

### Fase C: Message catalog

- catalogo local estructurado
- claves ARB
- renderer con variables
- tests de localizacion y variables

### Fase D: Selection engine

- generacion de candidatos
- elegibilidad
- prioridad
- anti-repeticion
- presets de intensidad

### Fase E: Scheduling integration

- reemplazar llamadas directas desde runtime y pantallas
- reconcile por triggers oficiales
- iOS budget enforcement

### Fase F: Settings

- separar recordatorios de habitos y generales
- preset intensidad
- hora base
- fallback anchor policy

### Fase G: Context expansion

- progreso del dia
- diario/mood
- actividad reciente
- reportes futuros

### Fase H: QA y observabilidad

- telemetria interna
- matrix iOS manual
- DST/timezone suite
- stress tests de caps

## 17. Riesgos y trade-offs

- Mantener local-first simplifica V1, pero limita mensajes totalmente remotos y campañas server-driven.
- Un catalogo hibrido es la mejor arquitectura objetivo, pero la V1 deberia arrancar solo con base local para reducir complejidad.
- Separar preferencias locales y remotas mejora claridad, pero obliga a decidir que gana en conflictos multi-dispositivo.
- Reservar el presupuesto iOS para habit reminders protege la promesa explicita al usuario, pero puede reducir el volumen de mensajes generales en usuarios con muchos habitos.
- Introducir anti-repeticion con historial local mejora calidad percibida, pero requiere disciplina para no convertirlo en un motor demasiado opaco.
- La migracion incremental minimiza riesgo, pero durante algunas fases coexistiran `phase 1` y componentes nuevos, lo que exige una estrategia clara de ownership temporal.

## 18. Preguntas de producto pendientes

- La familia de notificaciones generales debe tener un toggle maestro separado del toggle global actual.
- El preset de intensidad final sera de 2 o 3 niveles.
- La hora habitual de despertar existira como dato explicitamente editable por el usuario o sera solo derivada.
- Cuando no exista hora configurada ni wake time, el fallback por defecto debe ser `20:30`, `21:00` o otro valor de producto.
- Las celebraciones de racha deben seguir siendo inmediatas y fuera del presupuesto de generales, o entrar tambien en caps globales.
- El diario/mood en V1 entra solo como senal contextual o tambien como tipo explicito de notificacion.
- Las generales deben poder aparecer cuando hay recordatorios de habitos activos, o esos recordatorios reducen automaticamente el presupuesto general.
- Provisional authorization en iOS es una apuesta deseada para V2 o se mantiene fuera de roadmap.
- Weekly report y resumenes similares formaran parte del mismo motor o de una familia separada con otra politica de scheduling.
