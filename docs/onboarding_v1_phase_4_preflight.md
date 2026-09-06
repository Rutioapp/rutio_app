# Onboarding V1 — FASE 4 Pre-flight

Rama auditada: `feature/onboarding-v1-phase-4-preflight`  
Fecha: 2026-09-06  
Alcance: pre-flight técnico de recomendaciones, selección y configuración inicial de hábito.

Este documento separa `Hecho comprobado` de `Propuesta`. No implementa la FASE 4, no cambia UI, no cambia Supabase y no corrige el bug baseline de `timesPerWeek`.

## 1. Reality check

### Hecho comprobado

El flujo real de alta de hábito hoy nace en Home:

```text
HomeScreen / FAB
  → showHomeAddHabitSheet
  → HomeAddHabitSheet
  → HomeCatalogService.loadCatalog
  → selección de familia y HabitPillsList
  → HabitTargetConfigSheet (catálogo) o CreateHabitScreen (desde cero)
  → UserStateStore.addHabitFromCatalog / addCustomHabit
  → activeHabits local
  → persistencia UserStateRepository / UserStateStorage
  → notificationMutationObserver
  → HabitSyncService.syncHabitCreated (best effort)
  → HabitRemoteMapper.toRemoteHabit
  → HabitRepository.upsertHabitForCurrentUser
  → public.habits en Supabase
  → persistencia posterior de remoteId local
```

La edición sigue otra ruta:

```text
HabitDetailScreen
  → EditHabitTab
  → EditHabitTabFormData
  → buildUpdatedHabit
  → onSaved / _handleSaved
  → updateHabitDetailsFromEdit
  → persistencia local + HabitSyncService.syncHabitUpdated
```

La creación es local-first. El guardado remoto es asíncrono, best effort y no bloquea la UX. En tests sin sesión aparece el log `habit sync create skipped: no authenticated session`.

El tracking diario no forma parte del alta remota del hábito: el estado inicial vive en `activeHabits` (`progress`, `doneToday`, `skippedToday`), mientras el histórico vive en estructuras de `UserStateStore`. Los logs posteriores pasan por `HabitLogSyncService`/`HabitLogRepository` hacia `public.habit_logs`.

### Propuesta

La FASE 4 debe entrar en este flujo antes de `UserStateStore.addHabit...`, pero separar claramente:

```text
Goals + Pace
  → RecommendationCatalogRepository
  → RecommendationRankingService
  → RecommendationsStep
  → selectedRecommendationId
  → HabitStep / editor tipado
  → adaptador al contrato local existente
  → UserStateStore al confirmar la FASE 4B
```

La recomendación no debe crear `activeHabits` al mostrarse ni sincronizar nada a Supabase. Esa creación queda para la confirmación posterior del hábito y fuera de la FASE 4A.

## 2. Current onboarding surface

### Hecho comprobado

`OnboardingCoordinator.internalSteps` ya define `name`, `goals`, `pace`, `recommendations`, `habit`, `reminder` y `preview`. `OnboardingV1Screen` implementa de forma real solamente Name, Goals y Pace; el resto cae actualmente en `submitPlaceholderStep`.

`submitPlaceholderStep` conoce claves de mapa y escribe valores placeholder:

- Recommendations: `selectedRecommendationId: 'placeholder'`.
- Habit: `{id: 'placeholder-habit', type: 'check', schedule: {type: 'daily'}}`.
- Reminder: `{permissionState: 'notRequested'}`.
- Preview: no avanza.

### Propuesta

Recommendations y Habit deben reemplazar esos placeholders por pasos reales de forma incremental. Reminder, Preview, Auth, creación remota e idempotencia de finalización deben permanecer fuera de este pre-flight y de la implementación de Fase 4.

## 3. Existing data and contract inventory

### Hecho comprobado

No existe una entidad tipada única `Habit` reutilizable para creación. El repositorio usa dos representaciones principales:

1. `activeHabits`: `List<Map<String, dynamic>>` dentro del estado local.
2. `RemoteHabit`: DTO inmutable y tipado para el borde Supabase.

También existen tipos parciales de presentación: `HabitTargetConfigResult` y `EditHabitTabFormData`. La búsqueda no encontró `HabitDraft`, `HabitFormState`, `CreateHabitCommand`, `CreateHabitInput` ni `HabitPayload` como contrato de creación de dominio.

### Propuesta

La FASE 4B necesita un input tipado de editor/creación en el borde de presentación. Puede llamarse `CreateHabitInput` o equivalente y debe expresar el contrato canónico existente: nombre, emoji, familia primaria opcional, tipo `check|count`, objetivo/unidad, reminder y `schedule` normalizado. Debe adaptarse después al mapa local y a `RemoteHabit`, sin introducir una tercera persistencia.

## 4. Habit creation contract

### Hecho comprobado

El contrato actual es `PARTIAL`: `RemoteHabit` tipa el DTO remoto, pero `UserStateStore.addHabitFromCatalog` y `addCustomHabit` reciben mapas dinámicos con aliases históricos. `HabitRemoteMapper` concentra gran parte de la traducción al remoto.

IDs actuales:

- Catálogo: ID estable del JSON; se reutiliza como ID local y se omite si no es UUID remoto.
- Custom: `custom_<milliseconds>` generado en cliente.
- Remoto: `public.habits.id` UUID, con `gen_random_uuid()` cuando no se envía ID UUID.
- Draft de onboarding: `draftId` y `onboardingOperationId` UUID, actualmente no ligados al alta de hábito.

El remote ID se conserva mediante callback en `UserStateStore`; existe además un mapa de sesión en `HabitSyncService`. No hay hoy idempotencia de creación de hábito ligada a `onboardingOperationId`.

### Propuesta

Para Fase 4B, el adaptador debe generar un ID local estable antes de guardar y no inventar un UUID remoto. Debe llamar al camino local-first existente y dejar que `HabitRemoteMapper`/`HabitRepository` resuelvan el borde remoto. La decisión de una operación idempotente de onboarding pertenece a la fase de finalización y queda explícitamente fuera.

## 5. Draft map assessment

### Hecho comprobado

El draft actual contiene campos tipados para el sobre de onboarding y mantiene `habit` y `reminder` como `Map<String, dynamic>?`. `OnboardingDraftCodec` conserva claves desconocidas y `copyWith` copia mapas de forma defensiva. La persistencia versionada, migración v0→v1, scopes anónimo/usuario y recuperación ante payload corrupto están cubiertas por tests.

### Propuesta

El mapa es aceptable como boundary privado de persistencia temporal, pero no como API entre pasos. La presentación no debe conocer claves del mapa y el coordinator no debe construir hábitos dinámicos; el `submitPlaceholderStep` actual es deuda temporal que debe desaparecer al implementar esos pasos.

Antes de 4B hace falta un adapter/value object mínimo. El adapter lee/escribe el mapa solamente en el borde del draft y traduce desde el input tipado al contrato de `UserStateStore`. No hace falta migrar ahora a un `HabitDraft` paralelo.

## 6. What should remain in draft vs catalog-only

### Hecho comprobado

El draft ya persiste `catalogVersion`, `shownRecommendationIds`, `discardedRecommendationIds` y `selectedRecommendationId`. No persiste todavía una recomendación tipada ni una snapshot de catálogo.

### Propuesta

Persistir en el draft:

- `catalogVersion`.
- IDs mostrados, descartados y seleccionado.
- El `habit` únicamente después de que HabitStep confirme una configuración.

Mantener catalog-only:

- nombre localizado, emoji y texto editorial;
- goals/familias/pace compatibles;
- prioridad editorial, estado activo y metadata de ranking;
- `suggestedReminderTime`;
- definición completa de schedule/target sugerida mientras no se confirme HabitStep.

No copiar el catálogo completo dentro del draft. Si una versión antigua debe seguir resolviendo un ID seleccionado, la fuente versionada debe conservar su definición o una migración explícita.

## 7. Schedule contract

### Hecho comprobado

`HabitScheduleNormalizer` y la migración SQL definen cuatro formas canónicas:

```json
{"type":"daily"}
{"type":"weekly","weekdays":[1,2,3]}
{"type":"once","date":"YYYY-MM-DD"}
{"type":"timesPerWeek","timesPerWeek":3,"weekStartsOn":1}
```

`weekly` requiere weekdays no vacíos entre 1 y 7; `once` requiere una fecha ISO válida; `timesPerWeek` requiere entero positivo y `weekStartsOn` opcional entre 1 y 7. La base termina con `schedule NOT NULL DEFAULT {"type":"daily"}`.

La UI de catálogo soporta daily/weekly/once. `CreateHabitScreen` y `EditHabitTabFormData` soportan `timesPerWeek` solamente para hábitos `check`; para `count`, el camino existente lo degrada a daily. La relación de días seleccionados es `weekly` y no una lista ad hoc de frecuencia.

### Propuesta

HabitStep debe emitir siempre una de esas formas canónicas y validar antes de escribir el draft. Defaults recomendados: `check + daily`; si se seleccionan días concretos, `weekly`; `count + timesPerWeek` no debe existir. `once` no debe ser un default de onboarding y sólo debe exponerse si producto lo decide.

## 8. Known baseline bug

### Hecho comprobado

El test `test/stores/user_state_store_times_per_week_schedule_test.dart` falla en `addCustomHabit normalizes invalid timesPerWeek payload values`: espera `{type: timesPerWeek, timesPerWeek: 1, weekStartsOn: 1}` y obtiene `{type: daily}`.

La causa observada es que `_resolvedScheduleForHabitSave` recibe el schedule ya normalizado a daily por `HabitScheduleNormalizer` y, sin metadata legacy suficiente, no puede reconstruir el fallback específico. El camino normal de `CreateHabitScreen` sí emite un schedule válido.

### Propuesta

No corregir este bug en Fase 4. HabitStep debe evitar payloads inválidos y no depender de una normalización implícita para reparar decisiones del usuario. Si producto quiere `timesPerWeek`, debe restringirse a `check`, construirse con entero positivo y `weekStartsOn` válido, y cubrirse con un test de frontera dedicado en una tarea posterior.

## 9. Reusable form parts

### Hecho comprobado

Reutilizables directos, principalmente visuales:

- `HabitFormTypeCard`.
- `HabitFormEditableTargetValue`.
- `HabitFormStepperButton`.
- `HabitFormFrequencyChip`.
- `HabitFormSectionLabel` y `HabitFormBackground`.
- `showEmojiPickerBottomSheet` / `EmojiPickerBottomSheet`.

Reutilizables con wrapper:

- `CreateHabitScreen`: contiene efectos de Home, store, permisos y notificaciones; no es un componente embebible.
- `EditHabitTabFormData`: es estado mutable de edición y contiene aliases/advanced fields.
- `HabitTargetConfigSheet`: es específico del catálogo y no representa todavía el contrato completo de onboarding.
- `HabitFormBottomCta`: puede envolverse para conectarlo al shell de onboarding.

No reutilizar como API de dominio `habit_editor_utils.dart` ni el submit de `CreateHabitScreen`; son helpers dinámicos/efectos de la UI existente.

### Propuesta

Extraer sólo componentes pequeños si 4B lo necesita: identidad + emoji, objetivo/unidad, frecuencia/días y selector de hora. Mantener la lógica de estado en un editor tipado de onboarding y hacer que el adapter sea el único punto que conozca el mapa local.

## 10. Recommendation model

### Hecho comprobado

El catálogo bundled actual está en `assets/data/habits_catalog.json`: 7 familias y 91 hábitos. Los IDs son estables y `AppLocalizations.catalogHabitName` resuelve etiquetas ES/EN para muchos IDs. No hay catálogo remoto de recomendaciones ni tabla/RPC de onboarding.

### Propuesta

Modelo conceptual mínimo:

| Campo | Uso | Fuente |
|---|---|---|
| `id` | ID estable de recomendación | catálogo |
| `habitCatalogId` | hábito base si aplica | catálogo |
| `nameKey` o resolver localizado | nombre ES/EN | catálogo/l10n |
| `emoji` | presentación | catálogo |
| `habitType` | `check` o `count` | contrato existente |
| `targetCount`, `unit` | sugerencia de configuración | catálogo |
| `schedule` | forma canónica | catálogo |
| `suggestedReminderTime` | sugerencia `HH:mm` | catalog-only |
| `goalCodes`, `familyCodes` | cobertura y filtros | catálogo |
| `paceTags` / esfuerzo opcional | compatibilidad con pace | catálogo |
| `editorialPriority` | desempate/ranking | catálogo |
| `active`, `catalogVersion` | versionado | catálogo |

Si una recomendación sólo representa un hábito, `id` puede ser el ID del hábito. Si hay variantes de schedule/target, debe tener un ID de recomendación propio y un `habitCatalogId` común.

## 11. Goal-to-family seed mapping

### Hecho comprobado

Las familias canónicas son las de `lib/utils/family_theme.dart`: `mind`, `spirit`, `body`, `emotional`, `social`, `discipline`, `professional`. El catálogo las usa, pero no existe hoy una relación de goals de onboarding con familias.

### Propuesta

Semilla inicial, editable como configuración de dominio/catálogo y no hardcodeada en widgets:

| Goal | Familias principales | Familia secundaria |
|---|---|---|
| `care_body` | `body` | `discipline` |
| `find_calm` | `emotional` | `mind`, `spirit` |
| `organize_days` | `discipline` | `professional`, `mind` |
| `learn_grow` | `professional` | `mind`, `discipline` |
| `care_relationships` | `social` | `emotional` |
| `build_discipline` | `discipline` | `body`, `professional` |

Las familias son señales de cobertura, no filtros duros: una recomendación puede cubrir un goal aunque su familia secundaria sea la que mejor encaje.

## 12. Pace strategy

### Hecho comprobado

`OnboardingPace` sólo tiene `gentle`, `balanced` y `energized`. No existe aún metadata de esfuerzo en el catálogo ni una función de ranking de recomendaciones.

### Propuesta

Representar compatibilidad por tags/rangos opcionales (`gentle`, `balanced`, `energized`, duración/esfuerzo estimado), y calcularla en el dominio. Orientación inicial, no límites rígidos:

- Gentle: aproximadamente 2–5 min o acciones pequeñas.
- Balanced: aproximadamente 5–15 min.
- Energized: aproximadamente 10–30 min o más acciones.

La ausencia de metadata no debe eliminar una recomendación; debe aplicar una penalización neutral. Los umbrales y pesos son decisión de producto, no deben inventarse en la UI.

## 13. Ranking strategy

### Hecho comprobado

No hay motor actual. El draft sí ofrece los conjuntos necesarios para no repetir en una sesión reanudada.

### Propuesta

Un `RecommendationRankingService` puro debe recibir goals seleccionados, pace, snapshot versionada, IDs mostrados/descartados y un contexto estable de draft/refresh. Debe devolver resultados con ID, score, razones de cobertura y metadata suficiente para renderizar.

Orden recomendado: cobertura de goals, compatibilidad de familias, compatibilidad de pace, diversidad, prioridad editorial y luego desempate estable por ID. La misma entrada debe producir la misma salida. Si se requiere rotación, usar un seed derivado de `draftId + catalogVersion + refreshRound`, nunca random no reproducible.

Los pesos exactos quedan como decisión abierta de producto. No crear una falsa precisión numérica en Fase 4A.

## 14. Recommendation count and diversity

### Propuesta

Mostrar 4 recomendaciones normalmente y permitir hasta 6 cuando hay múltiples goals/familias compatibles. La selección debe:

- cubrir cada goal seleccionado al menos una vez cuando el catálogo lo permita;
- evitar duplicados semánticos del mismo `habitCatalogId`;
- incluir varias familias cuando hay candidatos suficientes;
- devolver menos de 4 si no hay suficientes candidatos válidos;
- no convertir “hasta 6” en obligación cuando perjudique la relevancia.

Para agotamiento, relajar en este orden: candidatos no mostrados y no descartados; después candidatos previamente mostrados pero no descartados; nunca reintroducir descartados dentro del mismo draft/versionado salvo una acción explícita de reset. El resultado debe seguir siendo determinista.

## 15. Refresh semantics

### Propuesta

Al renderizar correctamente un batch, añadir sus IDs a `shownRecommendationIds`. Al pedir “Ver otras opciones”, marcar como descartados los IDs visibles que el usuario está abandonando; la selección activa no se marca como descartada. Persistir antes o junto al nuevo batch para que un cierre/reanudación no repita la pantalla anterior.

Back conserva shown/discarded y `selectedRecommendationId`. Restart crea un draft nuevo y reinicia esos conjuntos. Al cambiar goals o pace, recomputar y conservar el historial del mismo draft; limpiar la selección sólo si deja de ser resoluble/compatible y todavía no existe una configuración de hábito confirmada.

## 16. Selected recommendation semantics

### Propuesta

Seleccionar una tarjeta sólo escribe `selectedRecommendationId`; no crea el hábito ni rellena `habit` todavía. Back conserva la selección. El flujo esperado es:

```text
selectedRecommendationId
  → abrir HabitStep pre-rellenado
  → usuario confirma/edita
  → guardar snapshot de hábito en draft
  → fase posterior decide cuándo crear activeHabits
```

“Crear desde cero” no tiene recommendation ID y abre HabitStep con defaults seguros. Si el usuario vuelve de HabitStep, la selección y los valores confirmados deben restaurarse independientemente.

## 17. Remote/cache/bundled strategy

### Hecho comprobado

Los hábitos de Home son bundled y no tienen repository/cache remoto de recomendaciones. El patrón más maduro del repo es `PhraseCatalogRepository`: cache local validada → bundled por locale/fallback → sync remoto opcional mediante datasource y coordinator. Shop también tiene infraestructura cloud, pero no es la referencia adecuada para este onboarding.

### Propuesta

Para Fase 4A: remote `NO`; no tabla, RPC, migration, RLS ni Auth. Implementar conceptualmente un `RecommendationCatalogRepository` con implementación bundled y contrato preparado para una fuente futura. No añadir cache remota/local nueva si no es necesaria para el entregable.

El fallback offline debe funcionar con el catálogo bundled y resolver ES/EN mediante IDs/l10n existentes o recursos bundled equivalentes. En una fase posterior, aplicar el patrón validado de Phrase Catalog: snapshot/cache validada, luego bundled compatible. Un fallo remoto nunca debe impedir recomendaciones offline.

## 18. Catalog version policy

### Hecho comprobado

`OnboardingVersions.catalogVersion` vale `1` al crear un draft y el codec lo conserva al reanudar. Sin embargo, `habits_catalog.json` no expone actualmente un versionado de contenido equivalente y el codec no comprueba que `catalogVersion` corresponda a una snapshot disponible.

### Propuesta

`catalogVersion` debe pinchar la snapshot usada por un draft. Resume/refresh conserva la versión; Restart toma la versión vigente. Un ID seleccionado debe seguir resolviendo aunque el hábito quede inactivo: mantener la definición histórica o un alias/deprecated record para esa versión.

Si en el futuro llega remoto, solicitar exactamente la versión pinned. Si no está disponible, usar una snapshot bundled/cache compatible; no sustituir silenciosamente por latest para un draft activo. Si tampoco existe, mostrar un estado recuperable que conserve el ID y no lo convierta en placeholder.

## 19. Exact Phase 4A scope

### Propuesta

Incluye únicamente:

- modelo tipado conceptual de recommendation y snapshot versionada;
- seed bundled y validator de catálogo/localización;
- interface `RecommendationCatalogRepository` y fuente bundled;
- `RecommendationRankingService` puro;
- integración de Coordinator para load, refresh, select y persistencia de sets/selección;
- `RecommendationsStep` con 4–6 cards, estados vacío/offline y CTA de crear desde cero;
- tests de cobertura de goals, diversidad, determinismo, refresh, resume, agotamiento y catalogVersion.

No incluye HabitStep real, creación local, notificaciones, remote habit save, completion, Auth, Home, cambios de schema ni arreglo de schedules.

## 20. Exact Phase 4B scope

### Propuesta

Incluye únicamente el editor inicial conectado al draft:

- abrir desde recommendation seleccionada con prefill;
- crear desde cero con defaults seguros;
- nombre, emoji, familia primaria, tipo, target/unidad y daily/weekly;
- validación usando el contrato canónico y `HabitScheduleNormalizer`;
- adapter tipado → mapa local existente, persistido sólo en el boundary del draft;
- componentes visuales reutilizados mediante wrappers o extracción pequeña;
- tests de prefill, edición, Back/resume, validación y serialización.

Defaults de “desde cero”: `check`, schedule `daily`, reminder desactivado, emoji de `FamilyTheme` si hay familia seleccionada y ningún efecto de notificaciones. `count` exige target positivo y unidad opcional; weekdays seleccionados producen `weekly`; `count + timesPerWeek` queda prohibido. No crear `activeHabits` ni sincronizar Supabase desde 4B.

## 21. Testing plan

### Propuesta

Tests de dominio:

- cada goal cubierto cuando existen candidatos;
- máximo de 4/6, diversidad familiar y eliminación de duplicados;
- score y desempate deterministas;
- shown/discarded, refresh, Back, restart y resume;
- catálogo vacío, locale ES/EN y fallback offline;
- catalogVersion pinning, IDs retirados y versión no disponible;
- pace compatible, neutral y penalizado;
- recommendation seleccionada distinta de habit configurado.

Tests de adapter/HabitStep:

- `check + daily`, `check + weekly`, días vacíos/todos;
- `count` con target/unidad;
- rechazo de schedule inválido y de `count + timesPerWeek`;
- round-trip del mapa del draft sin pérdida de claves soportadas;
- no llamadas a `UserStateStore`, notificaciones o Supabase durante 4A/4B.

Baseline ejecutado en este pre-flight:

```text
Onboarding draft/store/coordinator/screen: 56 passed
Alta desde catálogo + EditHabitTabFormData + target config: 10 passed
Schedule mapper + timesPerWeek store: 16 passed, 1 failed (baseline conocido)
Total focalizado: 83 passed, 1 failed
```

El fallo es únicamente `test/stores/user_state_store_times_per_week_schedule_test.dart`; no se modificó el test ni la producción.

## 22. Modified files

### Hecho comprobado

El único archivo que debe modificarse como resultado de este trabajo es:

- `docs/onboarding_v1_phase_4_preflight.md`.

### Propuesta

La implementación futura debería tocar sólo los módulos de onboarding/catalog/ranking/editor que se aprueben explícitamente. No debe incluir cambios oportunistas en `UserStateStore`, migraciones, tablas, RPC, RLS, Auth, Notifications, Home ni el bug baseline.

## 23. Risks

### Hecho comprobado

- El contrato local de hábitos es dinámico y tiene aliases históricos.
- La creación real tiene efectos laterales de persistencia, observer de notificaciones y sync best effort.
- `timesPerWeek` inválido se degrada a daily en un caso probado.
- El catálogo de hábitos actual no tiene metadata de goals, pace, prioridad ni versión de contenido.
- `selectedRecommendationId` no equivale hoy a un hábito configurado.

### Propuesta

Riesgos principales: crear duplicados al volver/reintentar, romper IDs del catálogo al actualizarlo, presentar recomendaciones sin localización, convertir familias secundarias en filtros demasiado rígidos, mezclar una sugerencia de reminder con permisos reales, o hacer que la selección dispare una creación prematura. El adapter y la política de versionado son las barreras principales.

## 24. Critical unknowns

### Propuesta

Resolver antes de implementar:

- pesos exactos del ranking y definición de “relevancia”;
- contenido editorial y relación goal→habit definitiva;
- si `count` puede recomendar `timesPerWeek` alguna vez;
- si una recomendación representa un hábito o una variante;
- representación de múltiples familias, dado que el hábito actual tiene una familia primaria (`familyId`);
- estrategia de localización: claves l10n existentes frente a datos ES/EN bundled;
- política de IDs retirados por versión;
- qué significa exactamente refresh y “descartar” en copy/UX;
- cuándo la finalización crea el primer hábito y cómo usa `onboardingOperationId`;
- ownership de reminder sugerido frente a permisos/notificaciones;
- si Goals/Pace pueden cambiar después de configurar el hábito;
- si el catálogo remoto futuro exige personalización por usuario.

## 25. Decision log

### Decisiones de este pre-flight

1. Fase 4A es catalog + ranking + selección; no creación.
2. Fase 4B es configuración y persistencia en draft; no creación remota.
3. Remote Supabase queda en `NO` para ambas fases.
4. Offline bundled es requisito; Phrase Catalog es referencia arquitectónica, no código a copiar ahora.
5. Se reutilizan componentes visuales y se envuelven pantallas con side effects.
6. El mapa se conserva sólo como boundary de persistencia; la UI futura usa valores tipados.
7. `timesPerWeek` inválido es baseline y queda fuera de alcance.
8. `catalogVersion` se trata como pin de snapshot, no como permiso para cambiar a latest.
9. shown/discarded/selected se persisten por draft y no se mezclan con un hábito configurado.

## 26. Explicitly not implemented Phase 4

Este documento es únicamente el pre-flight técnico. No se ha implementado la FASE 4A ni la FASE 4B: no hay RecommendationStep funcional, ranking, catálogo versionado en código, HabitStep real, adapter de creación, cambios de UI, escritura de hábitos desde onboarding, notificaciones, remote save, Supabase, Auth, Home ni corrección del bug `timesPerWeek`.
