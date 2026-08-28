# Notificaciones personalizadas Fase 3: message catalog

Fecha: 2026-08-28

## 1. Estrategia de localización encontrada en Rutio

- Los ARB viven en `lib/l10n/`.
- El locale base real del proyecto es `es`, porque `l10n.yaml` usa `template-arb-file: app_es.arb`.
- Los idiomas soportados hoy por `AppLocalizations` son `es` y `en`.
- Flutter genera `AppLocalizations` en `lib/l10n/gen/`.
- En widgets se consumen traducciones con `context.l10n`.
- Además existe una capa propia en `lib/l10n/l10n.dart` con helpers y extensiones.
- Fuera de widgets ya hay una forma estable de resolver textos: instanciar `AppLocalizationsEs()` o `AppLocalizationsEn()` directamente, o inyectar `AppLocalizations`.

## 2. Decisión final de localización

Se implementó una estrategia híbrida alineada con la infraestructura real del repo:

- metadata estructurada del catálogo en `assets/config/notification_message_catalog.v1.json`;
- copy localizada en `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`;
- resolución explícita y tipada mediante `NotificationLocalizedCopyResolver`.

No se usó reflexión dinámica sobre `AppLocalizations`.

Desviación real respecto al diseño inicial:

- en lugar de guardar `l10nKeyTitle` y `l10nKeyBody` para resolverlos dinámicamente, el renderer usa un switch/map explícito sobre `templateKey` y llama a getters/métodos tipados generados por Flutter.

Motivo:

- es más seguro con el l10n real del repo;
- evita lookup frágil por strings;
- mantiene cobertura de tests y fail-fast cuando falta copy.

## 3. Estructura del template

Cada template seed expresa:

- `templateId` estable e independiente del idioma;
- `templateKey` para enlazar metadata con el resolver tipado;
- `localeNamespace`;
- `category`;
- `variantTags`;
- `declaredVariables`;
- `requiredVariables`;
- `weight`;
- `cooldown`;
- `maxUsesPer7d`;
- `compatibleKinds`.

## 4. Categorías

Se implementaron 10 categorías ampliables:

- `morning`
- `gentleMotivation`
- `pendingProgress`
- `strongProgress`
- `completedDay`
- `streak`
- `comeback`
- `reflection`
- `consistency`
- `encouragement`

## 5. Variables

Variables soportadas por el contrato tipado:

- `displayName`
- `streak`
- `progress`
- `pendingCount`
- `completedCount`
- `totalCount`
- `habitName`
- `weekday`
- `timeOfDay`

Se modelan con:

- `NotificationTemplateVariable`
- `NotificationRenderContext`
- validación de variables requeridas antes de renderizar

Las variables opcionales tienen comportamiento definido en el resolver. Si faltan, se usa una variante de copy sin esa interpolación cuando existe.

## 6. Renderer

Se añadió una capa pura:

- `NotificationLocalizedCopyResolver`

Entrada:

- `NotificationTemplateDescriptor`
- `NotificationRenderContext`
- locale o `AppLocalizations`

Salida:

- `RenderedNotificationContent`

Incluye:

- `title`
- `body`
- `templateId`
- `templateKey`
- `locale`
- `category`
- variables resueltas mínimas

No depende del plugin nativo ni de widgets.

## 7. Catálogo inicial

Se creó un catálogo local seed de 26 templates.

Distribución:

- mensajes neutros;
- progreso pendiente;
- progreso fuerte;
- consistencia;
- reflexión;
- comeback;
- variantes con `displayName`;
- variantes con `streak`, `progress`, conteos, `habitName`, `weekday` y `timeOfDay`.

El tono se mantuvo cercano, calmado y motivador sin presión.

## 8. Template IDs

Se adoptó un formato legible y estable, por ejemplo:

- `general.morning.gentle_01`
- `general.streak.encouragement_02`
- `general.progress.habit_01`

Una reordenación del asset no cambia la identidad.

## 9. Validaciones

Se implementaron validaciones ejecutables para:

- `templateId` único;
- identidad básica no vacía;
- `compatibleKinds` presentes;
- coherencia de familia entre kinds compatibles;
- `weight` positivo;
- `cooldown` no negativo;
- `maxUsesPer7d` válido;
- `variantTags` no vacíos;
- variables declaradas/requeridas sin duplicados;
- requeridas como subconjunto de declaradas;
- templateKey soportado por el resolver;
- ninguna variable usada por el copy fuera de metadata;
- ninguna variable requerida que el copy no utilice;
- render correcto en todos los locales soportados;
- ausencia de title/body vacíos;
- ausencia de placeholders sin resolver.

## 10. Idiomas cubiertos

Cobertura completa en los idiomas reales soportados hoy por Rutio:

- `es`
- `en`

Fallback aplicado:

- si llega un locale no soportado, el resolver cae a `es`, que es el locale base real del proyecto.

## 11. Fallback policy

- Si falta un `templateId` o `templateKey`, se falla de forma explícita.
- Si falta una variable requerida, se lanza error y no se genera copy rota.
- Si una variable opcional no está disponible, se usa la variante sin esa interpolación si existe.
- Si un locale no está soportado, se usa fallback a `es`.
- Si el catálogo es inválido, la validación falla de forma visible durante desarrollo y tests.

## 12. Evolución futura a catálogo remoto

La evolución prevista sigue siendo:

- catálogo local base autoritativo para offline;
- overlay remoto opcional por `templateId`;
- overrides remotos solo para metadata y/o copy permitida;
- fallback inmediato al catálogo local si el overlay falta, caduca o es inválido.

Esto preserva:

- `templateId`;
- historial futuro por template;
- compatibilidad con el selection engine;
- comportamiento offline.

## 13. Tests

Se añadieron tests para:

- carga del catálogo real desde asset;
- unicidad de IDs;
- `getById`;
- filtros por kind y categoría;
- metadata de templates;
- render de todos los seeds en `es` y `en`;
- templates sin variables;
- `displayName` opcional;
- `streak`;
- `progress`;
- múltiples variables;
- caracteres especiales;
- missing required variable;
- fallback de locale no soportado;
- determinismo del renderer;
- validaciones de duplicate id;
- validaciones de variable no declarada;
- validaciones de required no declarada;
- validaciones de familias incompatibles;
- validaciones de copy vacía;
- validaciones de locale/copy incompleto mediante placeholders no resueltos.

## 14. Archivos creados/modificados

Creados:

- `assets/config/notification_message_catalog.v1.json`
- `lib/features/notifications/data/local/local_notification_template_catalog.dart`
- `lib/features/notifications/domain/notification_message_catalog.dart`
- `lib/features/notifications/domain/notification_template_content.dart`
- `test/features/notifications/data/local/local_notification_template_catalog_test.dart`
- `test/features/notifications/domain/notification_template_catalog_validator_test.dart`
- `test/features/notifications/domain/notification_template_renderer_test.dart`
- `docs/personalized_notifications_phase_3_message_catalog.md`

Modificados:

- `lib/core/assets/app_assets.dart`
- `lib/features/notifications/domain/personalized_notification_models.dart`
- `lib/features/notifications/domain/personalized_notification_ports.dart`
- `lib/features/notifications/domain/personalized_notifications.dart`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/gen/app_localizations.dart`
- `lib/l10n/gen/app_localizations_es.dart`
- `lib/l10n/gen/app_localizations_en.dart`
- `pubspec.yaml`
- `docs/personalized_notifications_architecture.md`

## 15. Qué NO está implementado todavía

Sigue fuera de esta fase:

- selection engine;
- weighted random;
- anti-repeat real;
- scheduling;
- reconciliation;
- integración con `NotificationService`;
- nuevas notificaciones productivas v2;
- Settings UI;
- cambios de permisos/onboarding;
- Supabase;
- Firebase/analytics;
- migración de IDs legacy.

## 16. Riesgos pendientes

- El renderer tipado obliga a mantener sincronizados asset metadata y switch/map de copy.
- Si el volumen de templates crece mucho, el archivo ARB y el resolver explícito crecerán también.
- Todavía no existe un engine que consuma estas piezas en producción.
- El fallback a `es` para locales no soportados debe seguir siendo válido si la política futura de locales cambia.

## 17. Recomendación para Fase 4

La siguiente fase recomendada es conectar estas piezas al selection engine:

- candidatos;
- elegibilidad;
- selección de template;
- anti-repeat;
- presupuesto/caps;
- integración con manifest e historial.

No se recomienda saltar aún a scheduling productivo ni a Supabase antes de cerrar ese engine.
