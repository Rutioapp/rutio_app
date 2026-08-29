# Notificaciones personalizadas Fase 5: context builder

Fecha: 2026-08-29

## 1. Objetivo

La Fase 5 conecta el motor puro de selección de la Fase 4 con contexto real de usuario, pero sin activar todavía scheduling productivo ni delivery real.

El objetivo de esta fase es construir un `NotificationContextSnapshot` fiable, scoped y reusable a partir del estado local actual, y además derivar un `NotificationSelectionContext` listo para el engine.

## 2. Resultado

Se añadió `StoreBackedNotificationContextBuilder` en:

- `lib/features/notifications/application/notification_context_builder.dart`

El builder:

- valida identidad y scope antes de leer contexto;
- vuelve a validar el scope después de operaciones async;
- falla en modo cerrado cuando detecta sesión inválida o cambio de usuario;
- construye `NotificationContextSnapshot`;
- construye `NotificationSelectionContext`;
- expone `NotificationContextBuildDiagnostics`;
- clasifica la calidad del contexto como `unavailable`, `minimal`, `partial` o `rich`.

No programa notificaciones, no reconcilia manifests y no toca el `NotificationService` legacy.

## 3. Fuentes autoritativas

Se decidió no reinventar semánticas ya existentes.

Fuentes utilizadas:

- hábitos visibles/esperados/completados/pendientes/skipped:
  `lib/features/habits/domain/habit_day_summary.dart`
- semántica de Home unificada:
  `lib/screens/home/logic/home_selectors.dart` ahora delega en `buildHabitDaySummary(...)`
- streak por hábito:
  `UserStateStore.habitStreakSnapshotForHabitId(...)`
- identidad/scope:
  `activeLocalScopeUserId`, `userId`, `scopeEpoch`
- display name:
  `UserStateStore.displayName`
- locale:
  `UserStateStore.preferredLanguageCode`
- inactividad:
  `UserStateStore.notificationMetadata['lastAppOpenAt']`
- señal de diario:
  `UserStateStore.diaryEntries`
- historial reciente de mensajes:
  `NotificationHistoryStore`
- install identity:
  `NotificationInstallIdProvider`

## 4. Semántica compartida de hábitos

Se consolidó la lógica diaria en:

- `lib/features/habits/domain/habit_day_summary.dart`

Reglas relevantes:

- filtra hábitos archivados igual que Home;
- respeta `createdAt` al decidir si un hábito existía ese día;
- soporta `daily`, `weekly`, `timesPerWeek` y `once`;
- distingue `pending`, `completed` y `skipped`;
- para `timesPerWeek` usa cumplimiento semanal real, no solo el estado del día;
- no usa `DateTime.now()` oculto dentro de la lógica compartida.

`Home` pasó a consumir esta misma implementación para evitar deriva entre pantalla y notificaciones.

## 5. Scope y fail-closed

El builder no intenta “seguir adelante” si el scope deja de ser fiable.

Fallos cerrados implementados:

- usuario no autenticado;
- `expectedUserId` no coincide;
- `expectedScopeEpoch` o `expectedScopeKey` no coinciden;
- cambio de scope mientras se resuelve `installId` o historial;
- `state` ausente.

Esto evita construir contexto con datos mezclados entre sesiones o usuarios.

## 6. Señales soportadas

`NotificationContextSnapshot` y `NotificationSelectionContext` reciben:

- `scope`
- `now`
- `timezoneId`
- `calendarDate`
- resumen de hábitos activos
- hábitos pendientes y completados de hoy
- mejor riesgo de streak entre hábitos pendientes
- `lastAppOpenAt`
- `latestDiaryEntryAt`
- `progressTodayRatio`
- historial reciente
- capacidades de scheduling recibidas desde fuera

`NotificationSelectionContext` añade además:

- `displayName`
- `pendingCount`, `completedCount`, `totalCount`
- `streak`
- `inactivityDays`
- `habitName`
- `weekdayLabel`
- `timeOfDayLabel`

## 7. Distinción entre cero y desconocido

Se endureció el modelado para no inventar contexto:

- `NotificationContextSnapshot.progressTodayRatio` ahora es `double?`
- si `totalCount == 0`, el progreso queda en `null`
- `NotificationSelectionContext.fromSnapshot(...)` deja de sintetizar progreso artificial a partir de contadores

Esto preserva la diferencia entre:

- progreso conocido de `0.0`
- progreso desconocido porque hoy no hay hábitos esperados

## 8. Endurecimiento de anti-repeat

La Fase 4 infería la categoría desde `templateId`, lo que era frágil si el catálogo crecía o cambiaba naming.

En esta fase:

- `NotificationDeliveryRecord` añade `categoryTag`
- `SharedPreferencesNotificationHistoryStore` persiste y recupera `categoryTag`
- `NotificationSelectionPolicy.antiRepeatPenalty(...)` usa `categoryTag` persistido

Se elimina así la dependencia de parsear categorías desde strings implícitos.

## 9. Calidad y diagnósticos

Se añadió `NotificationContextDiagnostics` para exponer:

- scope inicial y final;
- presencia de display name;
- fiabilidad de progreso, streak e inactividad;
- señal de diario;
- ausencia intencionada de mood y wake-up time;
- lista de señales faltantes.

Clasificación actual:

- `rich`: 5 señales o más
- `partial`: 2 a 4 señales
- `minimal`: 0 o 1 señales
- `unavailable`: build fallido

## 10. Señales intencionadamente fuera

No se añadieron todavía señales que hoy no tengan una fuente local barata, tipada y estable.

Siguen fuera:

- mood fiable;
- wake-up time fiable;
- scheduling productivo;
- reconciliación con manifiestos;
- escritura de historial al seleccionar;
- integración de delivery real;
- analytics;
- remoto/Supabase.

## 11. Tests

Cobertura añadida o reforzada:

- `test/features/notifications/application/notification_context_builder_test.dart`
- `test/features/notifications/domain/notification_selection_engine_test.dart`
- `test/features/notifications/data/local/shared_preferences_notification_history_store_test.dart`

Casos cubiertos:

- fail-closed sin usuario o con scope inválido;
- cambio de usuario durante build async;
- progreso desconocido cuando no hay hábitos esperados;
- semántica Home para pending/completed/skipped/archived;
- schedules `daily`, `weekly`, `timesPerWeek`, `once`;
- streak desconocido frente a streak cero real;
- display name, locale, inactividad y diario;
- franjas horarias derivadas del reloj fake;
- calidad del contexto;
- integración builder -> selection engine sin scheduling productivo.

## 12. Verificación ejecutada

Comandos ejecutados en esta fase:

- `dart format` sobre archivos tocados
- `flutter analyze --no-pub lib/features/notifications test/features/notifications`
- `flutter test --no-pub test/features/notifications`
- `flutter test --no-pub test/screens/home/home_selectors_schedule_test.dart`
- `flutter test --no-pub test/stores/user_state_store_schedule_guards_test.dart`

Estado observado:

- la suite de notifications quedó en verde;
- `home_selectors_schedule_test` se usa como red de seguridad del refactor compartido;
- `user_state_store_schedule_guards_test` siguió pasando;
- existe un fallo separado en `test/stores/user_state_store_times_per_week_schedule_test.dart` donde un payload inválido de `timesPerWeek` se normaliza a `daily`; no forma parte de los cambios de esta fase y queda como deuda preexistente o trabajo aparte.

## 13. Archivos creados/modificados

Creados:

- `lib/features/habits/domain/habit_day_summary.dart`
- `lib/features/notifications/application/notification_context_builder.dart`
- `test/features/notifications/application/notification_context_builder_test.dart`
- `docs/personalized_notifications_phase_5_context_builder.md`

Modificados:

- `lib/features/notifications/data/local/shared_preferences_notification_history_store.dart`
- `lib/features/notifications/domain/notification_selection_models.dart`
- `lib/features/notifications/domain/notification_selection_policy.dart`
- `lib/features/notifications/domain/personalized_notification_models.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/home/logic/home_selectors.dart`
- `test/features/notifications/data/local/shared_preferences_notification_history_store_test.dart`
- `test/features/notifications/domain/notification_selection_engine_test.dart`

## 14. Siguiente paso recomendado

La siguiente fase debería consumir este builder desde una capa de reconciliación no destructiva que:

1. construya contexto scoped;
2. invoque el selection engine;
3. decida schedule/cancel sin romper prod;
4. escriba historial solo cuando exista decisión efectiva de scheduling o delivery.
