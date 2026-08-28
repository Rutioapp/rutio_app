# Notificaciones personalizadas Fase 4: selection engine

Fecha: 2026-08-28

## 1. Flujo de selección

La Fase 4 implementa un motor puro que transforma:

- `NotificationSelectionContext`
- `NotificationPreferences`
- `NotificationTemplateCatalog`
- historial reciente ya cargado
- `NotificationRandomSource`

en uno de estos resultados:

- `NotificationSelectionResult.selected(...)`
- `NotificationSelectionResult.suppressed(...)`

Pipeline real:

1. suppression upfront por preferencias o quiet hours;
2. carga de catálogo;
3. descubrimiento de oportunidades contextuales;
4. filtro de eligibility por template;
5. cálculo de peso efectivo y penalización anti-repeat;
6. aplicación escalonada de cooldowns;
7. selección ponderada con random inyectable;
8. devolución de resultado explícito con diagnostics.

No programa notificaciones, no escribe historial y no toca delivery.

## 2. Result model

Se añadieron:

- `NotificationSelectionResult`
- `SelectedNotificationTemplate`
- `NotificationSelectionDiagnostics`
- `NotificationSelectionSuppressionReason`
- `NotificationSelectionReason`
- `NotificationSelectionOpportunity`

`SelectedNotificationTemplate` devuelve:

- template seleccionado;
- `kind` final;
- categoría;
- reason;
- `priorityScore`;
- `effectiveWeight`;
- `renderContext`;
- oportunidad utilizada.

`suppressed(...)` devuelve:

- `suppressionReason`;
- diagnostics mínimos del intento.

No se usa `null` ambiguo.

## 3. Contexto utilizado

Se introdujo `NotificationSelectionContext`, que distingue entre dato ausente y dato conocido con valor cero.

Señales soportadas:

- `now`, `timezoneId`, `locale`, `scope`;
- `timeOfDay`;
- `displayName`;
- `progressRatio`;
- `pendingCount`, `completedCount`, `totalCount`;
- `streak`;
- `inactivityDays`;
- `habitName`, `weekdayLabel`, `timeOfDayLabel`;
- `latestDiaryEntryAt`, `latestMood`;
- `recentMessageHistory`.

También se añadió `NotificationContextTimeOfDay` y su derivación desde `DateTime`.

## 4. Eligibility

Cada template ahora puede declarar `NotificationTemplateEligibility` con reglas cerradas:

- `allowedTimesOfDay`
- `minProgressRatio`, `maxProgressRatio`
- `minPendingCount`, `maxPendingCount`
- `minCompletedCount`
- `minTotalCount`
- `requiresCompletedDay`
- `requiresStreak`, `minStreak`
- `requiresDisplayName`
- `requiresInactivity`, `minInactivityDays`

El motor excluye además cualquier template cuya `requiredVariables` no pueda satisfacer `NotificationRenderContext`.

No se usan expresiones dinámicas ni un DSL abierto.

## 5. Priorización

La política contextual vive en `NotificationSelectionPolicy.discoverOpportunities(...)`.

Prioridades relevantes:

- comeback por inactividad `>= 3` días;
- completed day cuando el día está completado;
- streak cuando `streak >= 3`;
- pending progress si quedan pendientes;
- strong progress si `progressRatio >= 0.6 && < 1`;
- consistency si hay progreso parcial;
- reflection por tarde/noche;
- morning por la mañana;
- safe fallback siempre disponible.

La prioridad decide qué oportunidades compiten primero y qué categorías son primarias o fallback en cada caso.

## 6. Weighting

El peso final de un candidato se calcula como:

`template.weight * contextualWeightMultiplier * antiRepeatPenalty`

El multiplicador contextual tiene en cuenta:

- si la categoría es primaria o fallback para la oportunidad;
- `NotificationIntensityPreset`;
- boosts concretos para `completedDay`, `comeback`, `strongProgress` alto y streak largo.

La selección final usa weighted random sobre candidatos con peso positivo, con ordenación previa por `effectiveWeight` y `priorityScore` para mantener determinismo útil en tests con fake random.

## 7. Anti-repeat

La política anti-repeat usa `recentMessageHistory` sin side effects.

Reglas implementadas:

- cooldown por template (`template.cooldown`);
- exclusión del último template durante `recentSelectionWindow` de 6 horas;
- cooldown de categoría de 24 horas;
- penalización por repetir categoría en las últimas 3 entregas;
- penalización por repetir el mismo `kind` que el último;
- penalización progresiva por reuso del mismo template en 7 días;
- respeto de `maxUsesPer7d`.

## 8. Category balancing

El balance es intencionalmente simple e interpretable:

- si la misma categoría aparece 2 veces en las últimas 3 entregas, su peso cae con fuerza;
- si aparece 1 vez, recibe una penalización menor;
- las categorías primarias de la oportunidad reciben ventaja sobre las de fallback.

No hay scoring opaco ni machine learning.

## 9. Fallback

Se añadió `isFallbackCandidate` al descriptor de template.

La relajación ocurre por capas:

1. candidatos elegibles con cooldowns completos;
2. relajar cooldown de categoría;
3. relajar cooldown de template manteniendo exclusión del último template;
4. emergency fallback solo con templates marcados como seguros, permitiendo incluso reusar el último template si no queda otra opción.

Los fallback seguros actuales se concentran en categorías como:

- `encouragement`
- `gentleMotivation`
- `morning` cuando aplica

Siempre respetando variables requeridas disponibles.

## 10. Suppression reasons

Razones implementadas:

- `notificationsDisabled`
- `personalizedDisabled`
- `quietHours`
- `invalidCatalogState`
- `noEligibleTemplates`
- `missingRequiredContext`
- `unsupportedContext`
- `frequencyLimitReached`

Se mantienen separadas de futuras razones de scheduler o delivery.

## 11. Random abstraction

Se creó `NotificationRandomSource` con dos implementaciones:

- `SeededNotificationRandomSource`
- `FixedNotificationRandomSource`

Esto evita usar `Random()` dentro del engine y permite tests reproducibles con seed fija o secuencias fake.

## 12. Integración con preferences

En esta fase `NotificationPreferences` afecta selección solo donde ya tenía sentido:

- `masterEnabled`
- `generalNotificationsEnabled`
- `quietHoursStart` / `quietHoursEnd`
- `intensityPreset`

No se añadieron cambios de UI ni nuevos flujos de settings.

## 13. Relación con history

El engine consume historial ya resuelto desde `recentMessageHistory`.

Lo usa para:

- cooldowns;
- category balancing;
- frecuencia por 7 días;
- exclusión del último template;
- diagnostics.

No escribe historial al seleccionar.

## 14. Tests

Cobertura añadida:

- eligibility por progreso, pending, streak, displayName, inactivity y franjas horarias;
- prioridad de completed day, comeback, strong progress y streak;
- anti-repeat sobre último template, cooldowns y fallback;
- weighted random determinista con fake random y seed fija;
- suppression por preferencias y quiet hours;
- invariantes sobre pertenencia al catálogo, variables requeridas y estabilidad con history vacío o 30 entradas.

## 15. Archivos creados/modificados

Creados:

- `lib/features/notifications/domain/notification_random_source.dart`
- `lib/features/notifications/domain/notification_selection_engine.dart`
- `lib/features/notifications/domain/notification_selection_models.dart`
- `lib/features/notifications/domain/notification_selection_policy.dart`
- `test/features/notifications/domain/notification_selection_engine_test.dart`
- `test/features/notifications/domain/notification_selection_policy_test.dart`
- `docs/personalized_notifications_phase_4_selection_engine.md`

Modificados:

- `assets/config/notification_message_catalog.v1.json`
- `lib/features/notifications/data/local/local_notification_template_catalog.dart`
- `lib/features/notifications/domain/notification_message_catalog.dart`
- `lib/features/notifications/domain/notification_template_content.dart`
- `lib/features/notifications/domain/personalized_notification_models.dart`
- `lib/features/notifications/domain/personalized_notifications.dart`
- `test/features/notifications/data/local/local_notification_template_catalog_test.dart`
- `test/features/notifications/domain/notification_template_catalog_validator_test.dart`

## 16. Qué NO está implementado

Sigue fuera de Fase 4:

- scheduling productivo;
- `NotificationReconciler`;
- integración con `NotificationService` legacy;
- delivery real;
- escritura de historial al seleccionar;
- permisos y onboarding;
- Settings UI;
- Supabase;
- Firebase o analytics;
- apertura de notificaciones;
- migración de IDs legacy.

## 17. Riesgos

- La política de prioridad sigue siendo heurística y necesitará ajuste cuando exista feedback real de delivery.
- El mapeo de categoría derivado del `templateId` usado en anti-repeat es suficiente para el seed actual, pero conviene endurecerlo si el catálogo crece.
- La calidad del resultado depende de que futuras capas construyan bien `NotificationSelectionContext`.

## 18. Recomendación de Fase 5

La siguiente fase debería conectar este engine a una capa de scheduling no destructiva que:

- construya el contexto real;
- invoque selección;
- decida si programar;
- escriba historial solo cuando exista una decisión efectiva de scheduling o delivery.

No se recomienda saltar todavía a analytics, remoto o migraciones legacy antes de cerrar esa integración.
