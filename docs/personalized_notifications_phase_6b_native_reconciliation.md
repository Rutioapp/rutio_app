# Notificaciones personalizadas Fase 6B: native reconciliation

Fecha: 2026-08-29

## 1. Arquitectura native adapter

La Fase 6B conecta por primera vez la tuberia de `DesiredNotificationPlan` con el sistema operativo mediante:

- `FlutterLocalNotificationsNativeGateway`
- `NativeNotificationScheduleExecutor`
- `NotificationOsReconciliationCoordinator`

La responsabilidad queda separada asi:

- el coordinator carga `manifest` y pending del OS;
- el reconciler compara `Desired + Manifest + OS`;
- el executor aplica `CREATE`, `REPLACE`, `CANCEL`, `ADOPT` y `manifest cleanup`;
- el gateway es el unico punto que habla con `flutter_local_notifications`.

## 2. Integracion con plugin existente

Se reutiliza la unica instancia central de `FlutterLocalNotificationsPlugin` ya creada por `NotificationService`.

No se crea una segunda instancia paralela.

`FlutterLocalNotificationsNativeGateway` reutiliza:

- `NotificationService.ensureInitializedForFeature()`
- `NotificationService.scheduler`
- `NotificationService.permissionService`

La resolucion efectiva local inspeccionada en cache es `flutter_local_notifications 17.2.4`.

El `pubspec.yaml` declara `^17.1.2`, asi que 6B implementa contra las APIs reales resueltas de la serie 17:

- `zonedSchedule(...)`
- `pendingNotificationRequests()`
- `resolvePlatformSpecificImplementation(...)`

## 3. Scheduling iOS

Para personalized notifications v2 se usa `zonedSchedule(...)` con `timezone`.

El scheduling se expresa en hora local/IANA efectiva y no mediante UTC con offset fijo.

En iOS se mantiene `uiLocalNotificationDateInterpretation.absoluteTime`, consistente con el scheduler legacy compartido.

En Android se sigue reutilizando el mismo scheduler compartido, que ya degrada de exact a inexact cuando no hay permiso de exact alarm.

## 4. Timezone y DST

La timezone efectiva se valida por IANA antes de programar.

Si la timezone no existe o no puede resolverse:

- fail closed
- `invalidTimezone`
- no se programa nada

La construccion del instante nativo usa `TZDateTime(location, year, month, day, hour, minute, second)`.

Policy documentada para DST:

- la semantica es `localClockTime`;
- se delega la normalizacion de horas inexistentes/ambiguas a `timezone`;
- si una hora local no existe por salto DST, se acepta el siguiente instante local valido que la libreria materializa;
- si una hora es ambigua, se mantiene la interpretacion estable elegida por la libreria para ese `TZDateTime`.

No se implementa watcher permanente de timezone en 6B.

## 5. Pending OS model

Se introduce `NativePendingNotification` como modelo propio minimo:

- `platformId`
- `title`
- `body`
- `payload`
- `logicalNotificationId`
- `templateId`
- `scopeHash`
- `scopeEpoch`
- `family`
- `kind`
- `isOwnedV2`

El dominio no expone objetos del plugin.

## 6. Desired + Manifest + OS reconciliation

El reconciler ahora trabaja con tres fuentes:

- `DesiredNotificationPlan`
- `NotificationScheduleManifest`
- `List<NativePendingNotification>`

Operaciones posibles:

- `KEEP`
- `CREATE`
- `REPLACE`
- `ADOPT`
- `CANCEL`
- `DROP_MANIFEST`

Reglas principales:

- desired + manifest + OS iguales -> `KEEP`
- desired + manifest pero OS falta -> `CREATE`
- desired + OS valido pero manifest falta -> `ADOPT`
- desired + OS dudoso -> `REPLACE`
- desired ausente + manifest + OS -> `CANCEL`
- desired ausente + manifest pero OS falta -> `DROP_MANIFEST`
- OS owned del scope actual sin desired ni manifest -> `CANCEL`
- OS legacy, unknown o de otro scope -> `IGNORE`

`manifest` deja de tratarse como verdad absoluta.

## 7. Ownership v2

El ownership v2 es fail-closed y usa varias senales:

- payload `NotificationPayloadV2` parseable
- `logicalId`
- `templateId`
- `family`
- `kind`
- `scopeHash`
- `scopeEpoch`
- `platformId`
- manifest del scope cuando existe

Si el payload no parsea, no se asume ownership.

No se cancela por rangos amplios ni por `cancelAll()`.

## 8. CREATE / REPLACE / CANCEL native semantics

`CREATE`

- valida scope vigente;
- valida fecha futura;
- valida capabilities;
- valida timezone;
- valida capacidad iOS;
- programa nativamente;
- solo entonces se considera `scheduleAccepted`.

`REPLACE`

- intenta cancelar el pending previo si sigue en OS;
- luego reprograma;
- no finge atomicidad;
- si cancelar funciona pero reprogramar falla, el resultado refleja `stateChange=cancelled` y el manifest elimina esa entry para permitir retry coherente.

`CANCEL`

- cancela solo por `platformId` owned confirmado;
- si la entry ya no existe en OS, la limpieza de `manifest` se modela por `DROP_MANIFEST`.

## 9. Permissions y capabilities

6B no vuelve a pedir permisos.

`FlutterLocalNotificationsNativeGateway.getSchedulingCapabilities()` puentea el estado real del sistema a `NotificationSchedulingCapabilities` usando la infraestructura existente de `NotificationPermissionService`.

Estados cubiertos:

- `authorized`
- `denied`
- `provisional`
- `notDetermined`
- `restricted`
- `permanentlyDenied`
- `unknown`

Si `canScheduleNewEntries == false`, personalized v2 no programa nuevas notificaciones.

`canCancelExistingEntries` permanece `true` para mantener cleanup seguro con la infraestructura compartida.

## 10. iOS capacity

Se encapsula una policy conservadora en el executor:

- limite iOS observado: 64
- slots reservados: 4
- capacidad segura usada por v2: 60

Comportamiento:

- nunca se cancela legacy para hacer hueco;
- si no hay capacidad segura, devuelve `capacityExceeded`;
- `REPLACE` no consume capacidad extra si la pending anterior sigue presente;
- el horizonte sigue siendo corto, 24h.

## 11. Android behavior

Android sigue compilando con la misma infraestructura compartida.

No se crean channels nuevos para 6B.

Se reutiliza el channel actual y la politica ya existente:

- icono pequeño compartido
- channel de importancia alta ya configurado por legacy
- `AndroidScheduleMode` exacto solo cuando el sistema lo permite
- fallback a `inexactAllowWhileIdle` cuando corresponde

6B no solicita permisos especiales de exact alarm.

## 12. Payload serialization

`NotificationPayloadV2` ahora implementa:

- `encode()`
- `tryParse(...)`
- `fromJson(...)`

Propiedades:

- versionado por `schema`
- JSON compacto
- sin PII
- compatible con legacy porque payload invalido o antiguo devuelve `null`

Cobertura de tests:

- round trip
- malformed
- unknown schema
- legacy payload
- missing fields

## 13. Multiusuario

Garantias clave:

- B no adopta pendientes de A durante reconciliacion normal;
- pending del OS de otro scope se ignoran salvo cleanup explicito del scope correcto;
- manifest e history siguen scoped por usuario/install;
- payload parseado debe coincidir en `scopeHash + scopeEpoch`.

## 14. Stale-plan protection

`NativeNotificationScheduleExecutor` recibe un validador de scope esperado.

Antes de cada `CREATE`, `REPLACE`, `ADOPT` y `CANCEL` verifica que el scope siga vigente.

Si cambio la sesion entre plan y ejecucion:

- devuelve `staleScope`
- detiene el side effect de esa operacion

## 15. Logout cleanup primitive

Se implementa `NotificationOsReconciliationCoordinator.cancelOwnedNotificationsForScope(scope)`.

Todavia no se conecta a logout productivo.

La primitive:

- construye desired vacio para ese scope;
- cancela pendientes owned del scope;
- limpia entries stale del manifest;
- conserva intacto legacy;
- no toca scopes de otros usuarios.

La politica actual conserva `platformIdIndex` del manifest aunque se vacien las entries, para mantener estabilidad del namespace v2.

## 16. History semantics

`NotificationOsReconciliationCoordinator` escribe `NotificationDeliveryRecord` solo cuando una operacion:

- es `CREATE` o `REPLACE`
- devuelve `scheduleAccepted == true`

No registra:

- `KEEP`
- `ADOPT`
- `DROP_MANIFEST`
- fallos de scheduling

El significado del history en 6B es:

- "scheduled successfully"
- no "delivered by OS"

## 17. Partial failures

El resultado nativo expone:

- `operationAccepted`
- `scheduleAccepted`
- `platformId`
- `errorCode`
- `stateChange`
- `diagnostics`

Taxonomia de error pequena:

- `permissionDenied`
- `invalidTimezone`
- `invalidSchedule`
- `nativeFailure`
- `capacityExceeded`
- `staleScope`
- `unknown`

Caso importante ya soportado:

- `REPLACE` cancela
- re-schedule falla
- manifest no finge que la notification sigue pendiente

## 18. Manifest projection

La proyeccion del siguiente manifest aplica:

- upsert en `CREATE`, `REPLACE` y `ADOPT` exitosos
- remove en `CANCEL` y `DROP_MANIFEST` exitosos
- remove tambien en `REPLACE` fallido si el pending previo ya fue cancelado

Esto mantiene retries coherentes en la siguiente reconciliacion.

## 19. Tests

Se anadieron o ampliaron tests para:

- payload v2 codec
- reconciliacion OS-aware
- executor nativo
- capacity iOS conservadora
- stale scope
- cleanup primitive
- integracion manifest/history sin dispositivo

La suite de `test/features/notifications` pasa completa.

## 20. Archivos creados/modificados

Creados:

- `lib/features/notifications/domain/notification_native_models.dart`
- `lib/features/notifications/domain/notification_native_gateway.dart`
- `lib/features/notifications/data/native/flutter_local_notifications_native_gateway.dart`
- `lib/features/notifications/data/native/native_notification_schedule_executor.dart`
- `lib/features/notifications/application/notification_os_reconciliation_coordinator.dart`
- `test/features/notifications/domain/notification_payload_v2_test.dart`
- `test/features/notifications/application/notification_reconciler_os_aware_test.dart`
- `test/features/notifications/data/native/native_notification_schedule_executor_test.dart`
- `test/features/notifications/application/notification_os_reconciliation_coordinator_test.dart`
- `docs/personalized_notifications_phase_6b_native_reconciliation.md`

Modificados:

- `lib/features/notifications/domain/notification_payload.dart`
- `lib/features/notifications/domain/desired_notification.dart`
- `lib/features/notifications/domain/personalized_notification_ports.dart`
- `lib/features/notifications/domain/personalized_notifications.dart`
- `lib/features/notifications/application/notification_reconciliation_models.dart`
- `lib/features/notifications/application/notification_reconciler.dart`
- `lib/services/notification_service.dart`
- `lib/services/notification_scheduler.dart`
- tests existentes de reconciler/integracion para reflejar `OS = source of truth`

## 21. Config nativa iOS revisada

Se revisaron:

- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`

Resultado:

- sin cambios de capabilities;
- sin APNs;
- sin Push Notifications capability;
- sin cambios de entitlements;
- se mantiene el delegate actual de `UNUserNotificationCenter`.

Foreground actual:

- `DarwinInitializationSettings` ya tiene `defaultPresentAlert`, `defaultPresentBadge`, `defaultPresentSound`, `defaultPresentBanner` y `defaultPresentList` activados en la inicializacion compartida.

Como 6B reutiliza esa inicializacion, personalized v2 heredara ese comportamiento mientras no se tome una decision de producto distinta en 6C.

## 22. Que sigue legacy

Sin cambios productivos:

- habit reminders legacy
- daily motivation legacy
- weekly reports legacy
- permisos/onboarding actuales
- triggers productivos actuales

## 23. Que NO esta activado todavia

6B no conecta automaticamente esta tuberia a:

- app startup global v2
- bootstrap global v2
- foreground global v2
- login
- mutaciones de habitos
- settings UI nueva
- onboarding nuevo
- analytics
- Supabase
- remote config

La activacion masiva queda explicitamente fuera de 6B.

## 24. Riesgos para Fase 6C

- la policy DST se apoya en la semantica real de `timezone`, asi que 6C deberia validar matrix manual iOS con cambios de zona reales;
- la capacidad iOS es conservadora pero estatica, y puede necesitar presupuesto por familia al activar triggers reales;
- el scheduler compartido sigue heredando comportamiento foreground legacy;
- el cleanup de logout existe como primitive, pero aun falta el punto oficial de integracion de producto;
- para daily/recurring v2 futuras, convendra extender el executor para usar `NotificationScheduleSpec` directamente y no solo desired one-shot.

## 25. Recomendacion concreta para 6C

Activar primero un coordinator v2 explicito y opt-in, conectado solo a triggers controlados:

1. trigger manual o feature flag local
2. cleanup de logout
3. reconcile post-login acotado
4. reconcile en cambio de timezone/fecha

Solo despues de esa activacion gradual conviene conectar los triggers productivos mas frecuentes.
