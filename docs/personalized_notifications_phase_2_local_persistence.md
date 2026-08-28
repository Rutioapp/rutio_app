# Notificaciones personalizadas Fase 2: persistencia local

Fecha: 2026-08-28

## 1. Arquitectura implementada

Se añadió una capa persistente local nueva bajo `lib/features/notifications/data/local/`, manteniendo intacta la foundation de Fase 1 en `domain/` y sin conectar todavía scheduler, reconciliación productiva ni nuevas notificaciones v2.

La estructura queda así:

- `domain/`
  - modelos y contratos
- `data/local/`
  - `SharedPreferencesNotificationInstallIdProvider`
  - `SharedPreferencesNotificationPreferencesStore`
  - `SharedPreferencesNotificationScheduleStore`
  - `SharedPreferencesNotificationHistoryStore`
  - `NotificationPlatformIdRepository`
  - `NotificationLocalStorageScope`

## 2. InstallId

Se implementó un `installId` estable por instalación mediante `SharedPreferencesNotificationInstallIdProvider`.

Contrato aplicado:

- UUID v4 aleatorio.
- Se genera una sola vez si la key no existe o si el valor almacenado es inválido.
- Se persiste en storage local normal.
- No usa Keychain ni ningún mecanismo que sobreviva a reinstalación.
- No contiene información personal.
- No sustituye al `userId`.

Key usada:

- `rutio_notifications_v2/install_id`

## 3. Scope de almacenamiento

Todo el estado persistente de personalized notifications queda scopeado por:

- `installId`
- `userId`

Formato implementado:

- `rutio_notifications_v2/installations/<installId>/users/<userId>/preferences`
- `rutio_notifications_v2/installations/<installId>/users/<userId>/manifest`
- `rutio_notifications_v2/installations/<installId>/users/<userId>/history`

Para componer keys se usa `NotificationLocalStorageScope`, que aplica `Uri.encodeComponent` a `installId` y `userId`.

`scopeEpoch` sigue viviendo en el modelo de dominio y dentro del manifest, pero no define el bucket persistente. Esto evita fragmentar preferencias/historial por reinicios de scope y mantiene el aislamiento fuerte pedido para `userId + installId`.

## 4. Preferences store

Se implementó `SharedPreferencesNotificationPreferencesStore` como repositorio local de `NotificationPreferences`.

Capacidades:

- `load`
- `save`
- `update`
- `reset`

Comportamiento:

- usa defaults seguros de `NotificationPreferences.defaults()`;
- tolera payload ausente;
- tolera JSON corrupto devolviendo defaults;
- hace parsing defensivo de enums, enteros y horarios;
- en campos opcionales corruptos como quiet hours cae a `null`.

## 5. Manifest

Se implementó `SharedPreferencesNotificationScheduleStore` para persistir `NotificationScheduleManifest`.

Persistencia incluida:

- `scope`
- `scopeEpochAtPlanTime`
- `timezoneId`
- `lastReconciledAt`
- `lastReconciledDate`
- `entries`
- `platformIdIndex`
- `schemaVersion`

Notas:

- el manifest representa el estado local de reconciliación de Rutio;
- no replica ciegamente el OS;
- todavía no consulta ni modifica pending notifications productivas;
- permite `save`, `load`, `clear`, `upsertEntry`, `removeEntry` y persistencia explícita del índice de `platformId`.

## 6. PlatformId persistence

La persistencia de asignaciones `logical notification id -> platformId` se implementó dentro de `platformIdIndex` del manifest.

Flujo:

1. `NotificationPlatformIdRepository` carga el manifest del `scope`.
2. Valida que no existan conflictos persistidos de `platformId`.
3. Si el mapping ya existe, lo reutiliza.
4. Si no existe, usa `NotificationPlatformIdAllocator` de Fase 1.
5. Persiste el resultado mediante `SharedPreferencesNotificationScheduleStore.savePlatformIdMapping(...)`.

Garantías:

- estable entre reinicios y nuevas instancias;
- respeta el namespace/rangos de Fase 1;
- no usa `String.hashCode`;
- si encuentra conflicto persistido, falla de forma controlada con `StateError`;
- no sobrescribe silenciosamente otra asignación.

## 7. History store

Se implementó `SharedPreferencesNotificationHistoryStore`.

Persistencia mínima:

- `recentDeliveries`
- `lastSelectedAtByTemplateId`
- `lastSelectedAtByKind`
- `lastSelectedAtByCategoryTag`
- `schemaVersion`

No se guarda copy localizada completa.

API práctica añadida:

- `append`
- `load`
- `save`
- `clear`

## 8. Serialización y versionado

La persistencia usa JSON simple y parsing defensivo.

Se añadió `schemaVersion = 1` en:

- preferences
- manifest
- history

En esta fase el versionado es informativo y deja preparada evolución futura, sin introducir codegen ni frameworks pesados.

## 9. Comportamiento multiusuario

El aislamiento implementado garantiza que:

- usuario B no puede leer preferences de A;
- usuario B no puede leer history de A;
- usuario B no puede leer manifest de A;
- usuario B no puede reutilizar `platformIdIndex` de A;
- el mismo `userId` bajo otro `installId` queda aislado.

No se añadió todavía cleanup del OS en logout. Esta fase aísla datos locales; la cancelación/reconciliación productiva queda para fases posteriores.

## 10. Modelo de reinstalación

Política implementada:

- una instalación nueva genera un `installId` nuevo;
- storage bajo otro `installId` no se carga accidentalmente;
- no se hace cleanup agresivo de restos de instalaciones antiguas en esta fase.

Esto mantiene el comportamiento simple y seguro sin mezclar todavía políticas de housekeeping.

## 11. Archivos creados/modificados

Creados:

- `lib/features/notifications/data/local/notification_local_storage_scope.dart`
- `lib/features/notifications/data/local/shared_preferences_notification_install_id_provider.dart`
- `lib/features/notifications/data/local/shared_preferences_notification_preferences_store.dart`
- `lib/features/notifications/data/local/shared_preferences_notification_schedule_store.dart`
- `lib/features/notifications/data/local/shared_preferences_notification_history_store.dart`
- `lib/features/notifications/data/local/notification_platform_id_repository.dart`
- `test/features/notifications/data/local/shared_preferences_notification_install_id_provider_test.dart`
- `test/features/notifications/data/local/shared_preferences_notification_preferences_store_test.dart`
- `test/features/notifications/data/local/shared_preferences_notification_schedule_store_test.dart`
- `test/features/notifications/data/local/shared_preferences_notification_history_store_test.dart`
- `docs/personalized_notifications_phase_2_local_persistence.md`

Modificados:

- `lib/features/notifications/domain/personalized_notification_models.dart`
- `lib/features/notifications/domain/personalized_notification_ports.dart`

## 12. Tests

Se añadieron tests para:

- generación y reuso de `installId`;
- nueva instalación simulada;
- defaults y round-trip de preferences;
- update y reset de preferences;
- tolerancia a datos ausentes/corruptos;
- aislamiento por usuario e instalación;
- save/load/upsert/remove del manifest;
- persistencia y conflicto de `platformId`;
- append, orden, retención y reload de history.

## 13. Qué sigue siendo legacy

- `lib/services/notification_service.dart`
- `lib/services/notification_scheduler.dart`
- `lib/services/notification_rules.dart`
- `lib/services/notification_preferences.dart`
- todos los payloads e IDs legacy productivos
- onboarding y permission flow actuales

## 14. Qué NO se implementó

- nuevas notificaciones personalizadas productivas;
- selection engine;
- catálogo de mensajes;
- reconciliador productivo;
- integración con pending notifications del OS;
- cambios de Settings UI;
- cambios de permisos/onboarding;
- sincronización Supabase;
- migración de IDs legacy;
- Firebase o analytics.

## 15. Riesgos pendientes

- `platformIdIndex` ya persiste, pero aún no está conectado a un reconciliador real.
- No existe todavía cleanup de logout a nivel OS.
- Falta decidir cuándo y dónde se hidratará el `installId` en el flujo productivo futuro.
- El manifest aún no se contrasta contra pending notifications nativas.

## 16. Recomendación para Fase 3

Fase 3 recomendada: conectar esta persistencia local a un servicio de ownership y cleanup controlado, preparando reconciliación por scope sin cambiar todavía el scheduling productivo legacy hasta que exista un bridge claro.
