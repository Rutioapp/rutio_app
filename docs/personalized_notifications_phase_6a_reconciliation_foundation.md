# Notificaciones personalizadas Fase 6A: reconciliation foundation

Fecha: 2026-08-29

## 1. Arquitectura de planificacion

La Fase 6A introduce una tuberia nueva, pura y no conectada al OS:

`NotificationScope`
-> `NotificationPlanningContextBuilder`
-> `NotificationSelectionPolicy`
-> `NotificationSchedulePolicy`
-> `NotificationSelectionEngine`
-> `NotificationLocalizedCopyResolver`
-> `DesiredNotificationPlan`
-> `NotificationReconciler`
-> `NotificationReconciliationPlan`
-> `NotificationScheduleExecutor` fake
-> `NotificationScheduleManifest` actualizado

No se modifico `NotificationService` legacy, `NotificationScheduler` legacy ni `flutter_local_notifications` productivo.

## 2. DesiredNotification

Se creo `DesiredNotification` en:

- `lib/features/notifications/domain/desired_notification.dart`

Campos principales:

- `logicalNotificationId`
- `platformId`
- `kind`
- `family`
- `templateId`
- `renderedTitle`
- `renderedBody`
- `intendedLocalDateTime`
- `timezoneSemantics`
- `timezoneIdAtPlanTime`
- `payload`
- `fingerprint`
- `scope`
- `categoryTag`
- `opportunityId`
- `planVersion`
- `metadata`

No contiene tipos del plugin nativo.

## 3. DesiredNotificationPlan

`DesiredNotificationPlan` modela el conjunto completo v2 dentro de un horizonte corto y distingue explicitamente:

- `ready`
- `empty`
- `personalizedDisabled`
- `contextFailure`
- `notBuilt`

No se usa `null` ambiguo para expresar estado de planificacion.

## 4. Opportunities y slots

Se creo una policy centralizada en:

- `lib/features/notifications/application/notification_schedule_policy.dart`

Slots V1 materializados:

- `morning`
- `midday`
- `afternoon`
- `evening`

Cada opportunity lleva:

- `opportunityId`
- `kind`
- `reason`
- `priority`
- `window`
- `intendedAtLocal`
- `isEligible`
- `usesWakeUpFallback`
- `selectedLogicalNotificationId`

No hay slots infinitos ni programacion masiva.

## 5. Wake-up fallback

La Fase 5 dejo documentado que hoy no existe una senal fiable de wake-up time.

En 6A se centralizo un fallback V1 explicito:

- `fallbackWakeUpTime = 08:00`

Ese fallback solo sirve para derivar slots de `morning`, `midday` y `afternoon`.

La ancla de cierre/general de tarde sigue siendo:

- `NotificationPreferences.dailyAnchorTime`
- fallback actual del modelo: `20:30`

No se dispersaron horas magicas fuera de la policy.

## 6. Frequency policy

La policy diaria vive tambien en `notification_schedule_policy.dart`.

Regla implementada:

- `light` -> 1
- `balanced` -> hasta 2
- `active` -> hasta `generalNotificationCapPerDay + maxAdditionalContextualPerDay`, limitado a 4

Con los defaults actuales del modelo:

- `light` -> 1
- `balanced` -> 2
- `active` -> 3

Ademas, si una futura fuente fiable informa mucha carga de habit reminders:

- `>= 3` reminders reduce 1
- `>= 6` reminders reduce 2

En 6A esa integracion queda preparada por abstraccion; no se conecto de forma fragil al legacy.

## 7. Quiet hours

Se definio una policy V1 explicita y centralizada:

- inicio por defecto: `22:30`
- fin por defecto: `08:00`

Si el usuario ya tiene `quietHoursStart/quietHoursEnd` en preferencias, esas horas prevalecen.

Los opportunities que caen dentro de quiet hours quedan inelegibles antes de generar desired notifications.

## 8. Fingerprints

El fingerprint es determinista y cambia solo con campos relevantes:

- `logicalNotificationId`
- `templateId`
- `intendedLocalDateTime`
- `title`
- `body`
- payload v2 serializado
- `scope.scopeKey`

Implementacion:

- `lib/features/notifications/application/personalized_notification_plan_builder.dart`

Usa un hash estable FNV-like, sin `String.hashCode`.

## 9. Reconciliation algorithm

Se implemento `NotificationReconciler` en:

- `lib/features/notifications/application/notification_reconciler.dart`

Entrada:

- `DesiredNotificationPlan`
- `NotificationScheduleManifest`

Salida:

- `NotificationReconciliationPlan`

Reglas:

- `scope` distinto -> fail closed
- `contextFailure/notBuilt` -> plan bloqueado sin side effects
- desired sin entry en manifest -> `CREATE`
- same logical id con fingerprint igual -> `KEEP`
- same logical id con fingerprint distinto -> `REPLACE`
- entry v2 extra en manifest y fuera de desired -> `CANCEL`
- entries legacy/no v2 no se tocan

## 10. CREATE / KEEP / REPLACE / CANCEL

Semantica implementada:

- `CREATE`: desired v2 no existe en manifest.
- `KEEP`: logical id y fingerprint coinciden; no hay trabajo nuevo.
- `REPLACE`: mismo logical id bajo ownership v2, pero cambia fingerprint, template, hora, payload o contenido relevante.
- `CANCEL`: existe en manifest una entry v2 de `personalizedGeneral` que ya no esta en desired.

`REPLACE` queda modelado explicitamente; no se colapso conceptualmente en `cancel + create`.

## 11. Scope y multiusuario

La reconciliacion arrastra scope inequívoco:

- `userId`
- `scopeEpoch`
- `installId`

Garantias de 6A:

- el plan builder usa `NotificationPlanningContextBuilder` fail-closed;
- el reconciler falla cerrado ante `scope` distinto;
- el payload v2 incluye `scopeHash` y `scopeEpoch`;
- el fake executor y la proyeccion de manifest no aplican un plan para otro usuario.

## 12. Platform IDs

Se reutiliza el repositorio de Fase 2:

- `NotificationPlatformIdRepository`

El `platformId` se resuelve antes de producir `DesiredNotification` final, de modo que `CREATE` y `REPLACE` ya salen completamente ejecutables para 6B.

La estrategia sigue siendo:

- namespace `rutio:v2`
- rangos por familia
- asignacion estable
- persistencia en `platformIdIndex`
- sin `String.hashCode`
- sin tocar IDs legacy

## 13. Payload v2

Se creo `NotificationPayloadV2` en:

- `lib/features/notifications/domain/notification_payload.dart`

Campos:

- `schema`
- `family`
- `kind`
- `logicalId`
- `templateId`
- `scopeHash`
- `scopeEpoch`
- `categoryTag`
- `route`

No incluye `displayName` ni contenido sensible.

## 14. Manifest semantics

Se sigue reutilizando `NotificationScheduleManifest` de Fase 2 como:

- ultimo estado v2 conocido por Rutio

No se trata como verdad absoluta del OS.

En 6A la reconciliacion es:

- `DesiredNotificationPlan` vs `NotificationScheduleManifest`

Sin leer `pending notifications` nativas.

## 15. Partial failures

Se introdujo:

- `NotificationScheduleExecutor`
- `InMemoryNotificationScheduleExecutor`
- `NotificationReconciliationResult`

La proyeccion de manifest aplica solo operaciones confirmadas como success.

Si hay fallo parcial:

- `CREATE` fallido no entra al manifest
- `REPLACE` fallido conserva la entry anterior
- `CANCEL` fallido conserva la entry anterior

Esto deja el sistema listo para reintentos idempotentes en 6B.

## 16. Idempotencia

Propiedad validada:

- reconciliar un manifest ya alineado con el mismo desired state produce solo `KEEP`

Se anadio un test de flujo completo sin OS que verifica:

- plan
- reconcile
- fake execution
- manifest siguiente
- segunda reconciliacion no-op

## 17. Horizon e iOS capacity

La policy V1 define:

- horizonte explicito de `24h`

No se programan semanas ni colas largas.

Esto mantiene el diseno compatible con el limite practico de iOS y con reconciliacion frecuente.

## 18. Future reconciliation triggers

Se documentan para 6B/6C, pero no se conectaron:

- login/bootstrap
- app foreground/resume
- preferences change
- habit create/edit/delete/archive
- habit reminder toggle/change
- timezone change
- logout
- local date rollover

## 19. Tests

Se anadieron tests para:

- `NotificationSchedulePolicy`
- `PersonalizedNotificationPlanBuilder`
- `NotificationReconciler`
- flujo de integracion sin OS con segunda reconciliacion idempotente

Ademas sigue pasando la suite previa de notifications.

## 20. Archivos creados/modificados

Creados:

- `lib/features/notifications/domain/notification_payload.dart`
- `lib/features/notifications/domain/desired_notification.dart`
- `lib/features/notifications/application/notification_schedule_policy.dart`
- `lib/features/notifications/application/personalized_notification_plan_builder.dart`
- `lib/features/notifications/application/notification_reconciliation_models.dart`
- `lib/features/notifications/application/notification_reconciler.dart`
- `test/features/notifications/application/notification_schedule_policy_test.dart`
- `test/features/notifications/application/personalized_notification_plan_builder_test.dart`
- `test/features/notifications/application/notification_reconciler_test.dart`
- `test/features/notifications/application/notification_reconciliation_integration_test.dart`
- `docs/personalized_notifications_phase_6a_reconciliation_foundation.md`

Modificados:

- `lib/features/notifications/application/notification_context_builder.dart`
- `lib/features/notifications/data/local/notification_platform_id_repository.dart`
- `lib/features/notifications/domain/personalized_notification_ports.dart`
- `lib/features/notifications/domain/personalized_notifications.dart`

## 21. Que sigue legacy

Sin cambios:

- `lib/services/notification_service.dart`
- `lib/services/notification_scheduler.dart`
- `lib/services/notification_rules.dart`
- onboarding/permisos actuales
- scheduling real por `flutter_local_notifications`
- IDs y payloads legacy
- habit reminders legacy

## 22. Que NO esta conectado

No se conecto todavia:

- scheduling nativo productivo
- lectura de pending notifications del OS
- cleanup real de logout
- deep links productivos
- analytics
- Supabase
- migration de IDs legacy
- cambios de Settings UI

## 23. Riesgos antes de 6B

- La policy de slots sigue siendo V1 y necesitara ajuste cuando exista feedback real.
- Wake-up time sigue en fallback porque aun no hay senal fiable en contexto real.
- Habit reminder awareness solo esta abstraida; no esta alimentada por una fuente productiva robusta.
- Todavia no se compara manifest contra pending notifications nativas reales.
- La ejecucion fake demuestra arquitectura, no comportamiento del plugin.

## 24. Plan recomendado para 6B

1. Implementar adapter productivo de `NotificationScheduleExecutor` contra `flutter_local_notifications`.
2. Comparar manifest v2 con pending notifications reales del OS sin tocar ownership legacy.
3. Confirmar success/failure por operacion antes de persistir manifest.
4. Conectar triggers oficiales de reconciliacion.
5. Mantener el namespace v2 completamente separado de IDs/payloads legacy.

## 25. Desviaciones reales

No hizo falta actualizar `docs/personalized_notifications_architecture.md`.

Desviaciones conscientes respecto al ideal objetivo:

- la policy actual usa fallback de wake-up `08:00` porque Fase 5 aun no expone una senal fiable;
- la capacidad `active` depende del modelo actual de preferencias, por lo que los defaults efectivos hoy quedan en 3 y no 4;
- habit reminder awareness queda como contrato y test, no como integracion productiva con legacy.
