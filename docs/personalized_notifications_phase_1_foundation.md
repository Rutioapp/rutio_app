# Notificaciones personalizadas Fase 1: foundation

Fecha: 2026-08-28

## Que se creo

Se introdujo una foundation nueva y aislada bajo `lib/features/notifications/domain/` para el futuro sistema de notificaciones personalizadas, sin sustituir ni modificar el scheduling productivo actual de `NotificationService`.

La foundation incluye:

- modelos de dominio inmutables y comparables por valor;
- enums de `NotificationKind`, `NotificationFamily`, `NotificationTriggerReason`, presets, suppression reasons y permission state;
- value objects para `NotificationScope`, horas locales, ventanas horarias, `NotificationPreferences`, `NotificationContextSnapshot`, `NotificationCandidate`, `NotificationTemplateDescriptor`, `NotificationScheduleSpec`, `NotificationPlan`, `NotificationScheduleManifest` e historial minimo para anti-repeat;
- abstraccion pequena de clock con `NotificationClock`, `SystemNotificationClock` y `FakeNotificationClock`;
- namespace v2 de identifiers con `notificationKey` semantico y `NotificationPlatformIdAllocator` por rangos de familia;
- puertos minimos para catalogo, historial, manifest/schedule store, scheduler y context provider.

## Estructura final

- `lib/features/notifications/domain/personalized_notifications.dart`
- `lib/features/notifications/domain/notification_clock.dart`
- `lib/features/notifications/domain/personalized_notification_models.dart`
- `lib/features/notifications/domain/personalized_notification_ids.dart`
- `lib/features/notifications/domain/personalized_notification_ports.dart`

## Decisiones tomadas

- Se mantuvo la foundation completamente desacoplada de Flutter UI y de `flutter_local_notifications`.
- Se reutilizo el modelo real del repo para aislamiento por usuario: `userId` + `scopeEpoch`, dejando `installId` como parte explicita del `NotificationScope` para fases posteriores.
- Se adopto un `notificationKey` versionado (`rutio:v2:...`) separado del `platformId`.
- Para `platformId` se implemento un asignador estable por rangos de familia con hash FNV-1a + linear probing en memoria. Esto evita depender de `String.hashCode` y deja preparada una futura persistencia del indice en manifest.
- No se cablearon adapters productivos ni persistencia nueva en esta fase.

## Desviaciones respecto al diseno

- El documento arquitectonico sugeria como opcion preferible un asignador persistido por manifest. En esta fase se implemento la pieza de asignacion estable en memoria, preparada para rehidratarse desde `platformIdIndex` cuando llegue la persistencia real.
- `Locale` no se modela como objeto Flutter; el scope usa un `String locale` para mantener la foundation mas pura y testeable.
- No se creo todavia `NotificationOrchestrator`; esta fase solo deja dominio, clock, IDs y contratos.

## Que sigue siendo legacy

- `lib/services/notification_service.dart`
- `lib/services/notification_scheduler.dart`
- `lib/services/notification_rules.dart`
- `lib/services/notification_preferences.dart`
- todo el flujo actual de permisos/onboarding
- todos los IDs y payloads productivos actuales

## Que no se implemento todavia

- scheduling de nuevas notificaciones personalizadas;
- reconciliacion productiva contra pending native notifications;
- cleanup de logout;
- migracion de IDs legacy;
- cambios de Settings;
- persistencia local de manifest/historial;
- payload codec v2 productivo;
- adapters de scheduler/catalog/contexto;
- cambios de permisos, analytics, Firebase o Supabase.

## Tests anadidos

- `test/features/notifications/domain/notification_clock_test.dart`
- `test/features/notifications/domain/personalized_notification_ids_test.dart`
- `test/features/notifications/domain/personalized_notification_models_test.dart`

Cobertura principal:

- igualdad y comportamiento inmutable de modelos base;
- clasificacion `NotificationKind -> NotificationFamily`;
- defaults de `NotificationPreferences`;
- validaciones basicas de `NotificationScope` y `NotificationScheduleSpec`;
- separacion por usuario/scope en `notificationKey`;
- rangos y ausencia de colisiones relevantes en IDs;
- fake clock y cambios de timezone para tests futuros.

## Riesgos pendientes

- El asignador de `platformId` aun no persiste asignaciones entre sesiones; la persistencia debe entrar junto con el manifest real en la siguiente fase que conecte el engine.
- El repo sigue usando hoy IDs legacy con `String.hashCode`; esta foundation no corrige todavia ese comportamiento productivo.
- Falta definir donde vivira el `installId` device-level y como se hidrata sin introducir una segunda arquitectura de identidad.
- Aun no existe bridge entre el permission model actual y `NotificationSchedulingCapabilities`.

## Siguiente fase recomendada

Fase 2 recomendada: conectar esta foundation a un manifest local por usuario y a un reconciliador minimo, manteniendo el owner legacy intacto pero delegando ya la estrategia de IDs, cleanup y schedule ownership.
