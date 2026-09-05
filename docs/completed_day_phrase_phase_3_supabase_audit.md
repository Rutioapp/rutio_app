# Completed Day Phrase — Fase 3: auditoría Supabase y catálogo remoto

Fecha: 2026-09-05  
Estado: auditoría terminada; no se han creado migraciones, no se ha ejecutado Supabase y no se han insertado frases remotas.

## Resumen ejecutivo

La recomendación es combinar el patrón de catálogo activo del Shop con el límite de lectura por RPC y la publicación inmutable de Weekly Report:

- `motivational_phrases` y `motivational_phrase_translations` son tablas editoriales internas.
- `phrase_catalog_releases` identifica una publicación por locale y versión.
- `phrase_catalog_release_entries` materializa el snapshot exacto de cada release.
- El cliente no lee ni modifica tablas directamente; usa RPCs `SECURITY DEFINER` de solo lectura para obtener metadata y, solo si cambia la versión, el snapshot completo.
- Home sigue sirviendo inmediatamente el catálogo bundled o la caché local. Ninguna resolución de frase espera red.
- La caché remota se separa del historial y de `daily_phrase`.
- La primera release es-ES puede validarse con 300 entradas exactas; futuras releases no deben quedar atadas a ese número.

No se recomienda añadir analytics ni feature flag en esta fase. Tampoco se recomienda modificar Home, habit cards, Weekly Report, `timesPerWeek` o la lógica visual existente como parte de la implementación remota.

## Alcance y evidencia inspeccionada

Se inspeccionaron los siguientes patrones locales:

- Migraciones Shop: `20260717130000_create_shop_foundation.sql`, `20260718101000_seed_shop_catalog_v1.sql`, `20260719194500_seed_shop_cosmetics_catalog_v1.sql`, `20260722120000_create_shop_bundle_catalog_and_purchase_rpc.sql`.
- Migraciones Feedback: `20260829153540_create_feedback_v1_foundation.sql`.
- Migraciones Weekly Report: `20260901090000_create_weekly_report_foundation.sql`, `20260901110000_weekly_report_history_sync.sql`, `20260901150000_weekly_report_read_api.sql` y las migraciones posteriores de releases/copy/automatización.
- Verificaciones SQL existentes en `supabase/tests/`, incluyendo Shop, Feedback y Weekly Report.
- `supabase/seed.sql` y seeds versionados del Shop.
- `lib/features/completed_day_phrase/`, `assets/phrase_fallback/es.json`, `assets/phrase_fallback/en.json`, el store SharedPreferences, `CompletedDayPhraseService`, `BundledPhraseCatalog` y `PhraseCatalogValidator`.
- Repositorios remotos de Feedback, Weekly Report y Shop, además de bootstrap/auth y localización.

El working tree ya contenía cambios de las fases anteriores. Esta auditoría solo añade este documento.

## 1. Convenciones Supabase reutilizables

### Migraciones

La convención actual es:

- nombre `YYYYMMDDHHMMSS_descripcion.sql`;
- `begin;` / `commit;` por migración;
- `create ... if not exists` cuando la operación es repetible;
- migraciones posteriores pequeñas para reparaciones, grants o correcciones de contrato;
- comentarios SQL para tablas, columnas, triggers y RPCs cuando el contrato necesita quedar explícito.

Las migraciones recientes muestran que Rutio prefiere forward fixes idempotentes antes que reescribir una migración ya aplicada.

### Tipos y constraints

Hay dos patrones válidos:

- enums SQL para estados muy estables y con lifecycle cerrado, como `feedback_category` y `feedback_status`;
- `text` más `check` para catálogos y configuraciones que pueden evolucionar, como Shop y Weekly Report.

Para un catálogo editorial remoto recomiendo `text` más constraints. Añadir una categoría o un estado editorial no debería requerir una migración de enum ni bloquear una release anterior.

### Timestamps y triggers

Se reutiliza `timestamptz not null default now()` para `created_at` y `updated_at`. El helper existente `app_private.set_updated_at()` actualiza `updated_at` en triggers `before update`.

Los contratos sensibles usan triggers `SECURITY DEFINER` con `set search_path = ''`. Las releases publicadas deben seguir ese patrón para impedir que el cliente o una edición accidental muten un snapshot ya servido.

### Grants y RLS

El patrón general es:

1. habilitar RLS;
2. revocar permisos de `public`, `anon` y `authenticated`;
3. conceder solo la operación necesaria;
4. limitar filas con policies owner-scoped o `is_active`;
5. encapsular operaciones sensibles en RPCs `SECURITY DEFINER`.

Shop concede `SELECT` autenticado sobre catálogo activo. Feedback concede `SELECT`/ `INSERT` autenticado y fuerza updates/deletes por RPC. Weekly Report bloquea el acceso directo a snapshots internos y expone payloads owner-scoped mediante RPC. Para Completed Day Phrase debe prevalecer el último patrón: las releases publicadas son snapshots internos y la API pública es una RPC de lectura.

### Índices y claves

Se usan primary keys naturales `text` cuando el catálogo tiene IDs estables, UUIDs para filas operativas y unique indexes parciales para estados activos. Los índices deben cubrir al menos `(locale, release_version)` y la búsqueda de entries por `release_id`.

### Seeds y verificaciones

Shop usa CTE `seed_data (...) as (values ...)`, inserción explícita y `on conflict` idempotente. Weekly Report usa también generación SQL cuando el contenido es regular. `supabase/tests/` contiene verificaciones estáticas con `DO $$ ... raise exception ... $$` y consultas de integridad.

La convención recomendada para 300 frases es un archivo SQL de seed versionado separado de la migración estructural, más una verificación SQL dedicada. `supabase/seed.sql` puede seguir siendo una entrada local mínima, pero no debe ser el único artefacto auditable de producción.

## 2. Modelo recomendado

### 2.1 `public.motivational_phrases`

Tabla editorial de metadata estable:

- `id text primary key`;
- `category text not null` con check `personal | consistency | motivation`;
- `tone text not null` con check `gentle | balanced | energetic`;
- `source_type text not null` con check `original | quote | proverb`;
- `author text null`;
- `required_tokens text[] not null default '{}'`;
- `enabled boolean not null default true`;
- `created_at timestamptz not null default now()`;
- `updated_at timestamptz not null default now()`.

El ID debe ser estable y no debe contener locale. Para la primera release el seed verificará el patrón `personal_001` ... `personal_050`, `consistency_001` ... `consistency_100` y `motivation_001` ... `motivation_150`. No conviene fijar ese patrón como constraint universal si en el futuro se necesitan IDs editoriales adicionales.

No debe existir `user_id`, nombre, streak, progress ni rendered text en esta tabla.

### 2.2 `public.motivational_phrase_translations`

Tabla editorial por idioma:

- `phrase_id text not null references public.motivational_phrases(id) on delete restrict`;
- `locale text not null`;
- `template text not null`;
- `review_status text not null` con check `draft | review | published | retired`;
- `translator_note text null`;
- `content_version integer not null default 1` con check `> 0`;
- `created_at timestamptz not null default now()`;
- `updated_at timestamptz not null default now()`;
- primary key `(phrase_id, locale)`.

La combinación `phrase_id + locale` evita duplicados. `on delete restrict` protege los IDs históricos: una frase se desactiva o se retira, pero no se borra si existen traducciones o releases que dependan de ella.

El `content_version` debe vivir aquí, no solamente en la tabla maestra. Una corrección de español no debe obligar a cambiar la versión editorial de inglés. El snapshot de release lo copiará al campo `contentVersion` que ya entiende Dart.

### 2.3 `public.phrase_catalog_releases`

Tabla de publicaciones:

- `id uuid primary key default gen_random_uuid()`;
- `locale text not null`;
- `release_version text not null`;
- `schema_version integer not null default 1`;
- `status text not null` con check `draft | published | superseded`;
- `published_at timestamptz null`;
- `created_at timestamptz not null default now()`;
- `updated_at timestamptz not null default now()`;
- unique `(locale, release_version)`;
- unique parcial `(locale) where status = 'published'`.

Constraints adicionales:

- `btrim(locale) <> ''`;
- `btrim(release_version) <> ''`;
- `schema_version > 0`;
- `status = 'published'` exige `published_at is not null`;
- `status <> 'published'` no puede presentarse como release actual.

La release se publica una sola vez. Una edición posterior crea otra versión; no se actualizan sus entries existentes.

### 2.4 `public.phrase_catalog_release_entries`

Esta es la pieza que fija el snapshot exacto. Cada fila contiene el payload que el cliente necesita:

- `release_id uuid not null references public.phrase_catalog_releases(id) on delete cascade`;
- `phrase_id text not null references public.motivational_phrases(id) on delete restrict`;
- `category text not null`;
- `tone text not null`;
- `source_type text not null`;
- `author text null`;
- `template text not null`;
- `required_tokens text[] not null`;
- `weight smallint not null`;
- `enabled boolean not null`;
- `content_version integer not null`;
- primary key `(release_id, phrase_id)`.

Los campos repetidos son intencionados: la release debe seguir siendo reproducible aunque cambie la tabla editorial. También evitan que una RPC mezcle una traducción nueva con metadata antigua.

La migración debe validar en publish que cada entry es coherente, que sus tokens coinciden con el template y que existe como máximo una entry por `phrase_id`. La verificación de “300 exactas” pertenece al seed inicial, no a todas las releases futuras.

## 3. Enum vs `text + check`

Recomendación concreta: `text + check` para `category`, `tone`, `source_type`, `review_status` y `status` de release.

Motivos:

- sigue la flexibilidad de los catálogos Shop/Weekly Report;
- permite añadir un tono o estado editorial con una migración pequeña sin reescribir enums usados por datos históricos;
- el catálogo ya tiene validación estricta en Dart y en el seed;
- los valores siguen estando limitados por SQL.

La excepción serían estados operativos extremadamente cerrados. En este caso no aporta suficiente ventaja crear enums para contenido editorial.

## 4. RLS y API de lectura

### Contrato del cliente

El cliente autenticado puede:

- consultar la metadata de la release publicada de un locale;
- descargar un snapshot publicado o superseded por su `release_id` durante una carrera de actualización;
- no insertar, actualizar ni borrar contenido;
- no leer tablas editoriales directamente.

No se necesita `anon`: Home y el controller operan después de auth y el fallback bundled cubre el arranque sin red.

### RPC recomendada

Usaría dos RPCs públicas, ambas `stable`, `SECURITY DEFINER`, `set search_path = ''` y `grant execute ... to authenticated`:

~~~text
get_published_phrase_catalog_release(p_locale text)
  -> { releaseId, locale, releaseVersion, schemaVersion }

get_phrase_catalog_release(p_release_id uuid)
  -> { schemaVersion, catalogVersion, locale, phrases: [...] }
~~~

La segunda función solo acepta releases que hayan estado publicadas y cuyos entries sean completos. Mantener las releases superseded permite terminar una descarga iniciada justo antes de la publicación siguiente sin mezclar filas.

Las tablas deben tener RLS habilitado, pero sin grants directos para `anon` ni `authenticated`. Las RPCs validan el locale canonicalizado y seleccionan únicamente el release/entries completo. Service role y Studio conservan la capacidad administrativa fuera de la superficie móvil.

Una única RPC que devuelva metadata y snapshot completo también sería válida cuando cambie una release, pero obligaría a descargar las 300 frases en cada consulta de versión. La separación en dos requests lógicos conserva la optimización solicitada sin perder el snapshot.

## 5. Releases: decisión elegida

Se elige la opción C: tabla intermedia materializada `phrase_catalog_release_entries`.

### Por qué no la opción A

Leer “todas las filas activas y publicadas” no identifica qué filas pertenecen juntas a una release. Una traducción editada entre dos lecturas puede producir una mezcla parcial. También es difícil reproducir exactamente qué vio un cliente.

### Por qué no una opción B mínima

Guardar solo `release_version` en cada traducción mejora el control, pero sigue dejando la publicación acoplada a varias tablas editoriales y hace más fácil que una corrección mutable afecte una release histórica.

### Por qué C es adecuada

- 300 entradas por locale es un volumen pequeño;
- el publish queda explícito y auditable;
- la RPC lee una sola release y sus entries;
- el cliente nunca recibe una combinación parcial;
- una release publicada puede conservarse indefinidamente;
- se puede validar el snapshot completo antes de cambiar qué release está publicada.

La transacción de publicación debe ser:

1. crear release draft;
2. insertar todas las entries;
3. ejecutar validaciones de cardinalidad y contenido;
4. marcar la release anterior como `superseded`;
5. marcar la nueva como `published` y fijar `published_at`;
6. commit.

No debe existir un estado observable donde la release publicada tenga entries incompletas.

## 6. Versionado

### `schemaVersion`

Versión de la estructura del payload y del contrato que sabe interpretar el cliente. Cambia cuando cambian nombres, tipos o campos obligatorios. La Fase 3 debe mantener `1` y rechazar valores desconocidos.

### `releaseVersion` / `catalogVersion`

Identidad del snapshot publicado para un locale. En SQL se llamará `release_version`; en el JSON seguirá llamándose `catalogVersion` para reutilizar `PhraseCatalog`. Es una cadena opaca, por ejemplo `es-ES-2026-09-05-01`.

### `contentVersion`

Versión editorial de la traducción de un ID en un locale. Cambia cuando cambia el template, sus tokens o su autoría publicada. El ID permanece estable.

El contrato resultante es:

~~~text
schemaVersion  = contrato estructural del JSON
catalogVersion = release snapshot por locale
contentVersion = versión de contenido de phrase_id + locale
~~~

El `PhraseCatalogValidator` existente seguirá siendo la última barrera en Dart. La validación SQL evita que un snapshot obviamente inválido llegue a la app.

## 7. Contrato de descarga y sincronización

Flujo recomendado:

~~~text
auth/bootstrap listo
        |
        +--> Home y controller usan bundled/cache sin esperar
        |
        +--> background: get_published_phrase_catalog_release(locale)
                    |
                    +-- misma releaseId/version --> terminar
                    |
                    +-- nueva release --> get_phrase_catalog_release(releaseId)
                                      |
                                      +--> parse DTO
                                      +--> validar catálogo completo
                                      +--> guardar atómicamente
                                      +--> siguiente resolución usa caché nueva
~~~

Reglas:

- nunca llamar a Supabase desde `Home.build` esperando el resultado;
- no mostrar errores de red al usuario;
- si falla la metadata, conservar cache/bundled;
- si falla la descarga, conservar cache/bundled;
- si falla parse o validación, no tocar la caché activa;
- descartar una respuesta si cambió el usuario/scope durante la operación;
- limitar refresh por locale y por un intervalo de throttle para evitar duplicados.

El punto más consistente es después de que Bootstrap publique Home y dentro del trabajo post-home asociado a auth, usando el mismo scope/user epoch. Como refuerzo, puede reintentarse en `AppLifecycleState.resumed` con throttle, siguiendo el patrón de `ShopCloudRefreshCoordinator`. No debe arrancar como una dependencia de la primera construcción de Home.

## 8. Formato remoto y adaptación al dominio local

El payload final de la RPC debe ser compatible con `PhraseCatalog`:

~~~json
{
  "schemaVersion": 1,
  "catalogVersion": "es-ES-2026-09-05-01",
  "locale": "es-ES",
  "phrases": [
    {
      "id": "motivation_001",
      "category": "motivation",
      "tone": "balanced",
      "sourceType": "original",
      "author": null,
      "template": "...",
      "requiredTokens": [],
      "weight": 10,
      "enabled": true,
      "contentVersion": 1
    }
  ]
}
~~~

No se debe crear un segundo modelo de selección. La capa remota debe ser un adaptador:

- `SupabasePhraseCatalogDataSource`: llama a las RPCs y devuelve DTOs;
- `PhraseCatalogDto`: convierte JSON en `PhraseCatalog` y `MotivationalPhrase`;
- `PhraseCatalogCacheStore`: guarda/lee envelopes validados;
- `CachedOrBundledPhraseCatalogSource`: devuelve local cache o bundled para la selección;
- `PhraseCatalogSyncCoordinator`: actualiza cache best-effort;
- opcionalmente `PhraseCatalogRepository` para agrupar source/cache/sync sin cargar responsabilidades en Home.

`CompletedDayPhraseService` debe seguir recibiendo una abstracción compatible con `PhraseCatalogSource`. El controller no debe conocer Supabase ni Home.

El peso remoto conserva la semántica numérica actual: `smallint` se convierte al `double` que usa Dart sin dividirlo automáticamente por 100. El bundled actual usa peso `10`; si se decide un rango nuevo, debe quedar fijado antes del seed y reflejarse en SQL, DTO, validator y pruebas.

## 9. Cache local

Debe separarse del store actual:

- `SharedPreferencesCompletedDayPhraseStore`: historial y daily selection por usuario;
- `SharedPreferencesPhraseCatalogCacheStore`: contenido remoto por locale, sin datos de usuario.

No conviene ampliar el mismo store porque son responsabilidades, ciclos de vida y políticas de invalidación distintas.

Namespace conceptual:

~~~text
completed_day_phrase_catalog_v1/<canonical-locale>/slot_a
completed_day_phrase_catalog_v1/<canonical-locale>/slot_b
completed_day_phrase_catalog_v1/<canonical-locale>/active_slot
~~~

Envelope persistido:

~~~json
{
  "cacheSchemaVersion": 1,
  "releaseId": "uuid",
  "releaseVersion": "es-ES-2026-09-05-01",
  "locale": "es-ES",
  "downloadedAt": "2026-09-05T12:00:00Z",
  "catalog": {
    "schemaVersion": 1,
    "catalogVersion": "es-ES-2026-09-05-01",
    "locale": "es-ES",
    "phrases": []
  }
}
~~~

La caché no debe estar namespaced por usuario: el contenido editorial es común al dispositivo. History y daily selection sí permanecen namespaced por usuario.

## 10. Atomicidad con SharedPreferences

Para una actualización all-or-nothing se recomienda doble slot:

1. leer y validar todo el response en memoria;
2. serializar el envelope completo antes de escribir;
3. escribir el slot inactivo;
4. comprobar que la escritura terminó correctamente;
5. cambiar `active_slot` como último paso;
6. no borrar nunca el slot anterior durante la actualización.

Al leer:

- validar primero el slot indicado por `active_slot`;
- si está corrupto, validar el otro slot y recuperar el último payload válido;
- si ninguno es válido, usar bundled.

Un único `setString` sin borrar la clave anterior sería suficiente para el caso normal, pero no ofrece una recuperación tan clara ante una escritura interrumpida. El doble slot mantiene la tecnología existente y evita dejar a la app sin catálogo válido.

El tamaño debe medirse con el seed real. 300 frases traducidas pueden representar cientos de KB por locale. Para esta fase no hay evidencia suficiente que obligue a introducir otra tecnología; si el payload real supera los límites prácticos de UserDefaults/SharedPreferences o degrada el arranque, la alternativa futura sería un archivo local atómico, no cambiar ahora preventivamente de almacenamiento.

## 11. Locale y fallback

La app actual declara únicamente `Locale('es')` y `Locale('en')`. `UserStateStore` acepta solo `es`/`en`, y `PhraseLocale.canonicalize()` reduce cualquier `es-*` a `es` y cualquier `en-*` a `en`.

Eso es compatible con Phase 1, pero no con el contrato exacto de Fase 3. La futura implementación debe separar:

- locale solicitado: BCP-47 normalizado, por ejemplo `es-ES` o `en-US`;
- locale efectivo: el catálogo que realmente se pudo resolver;
- locale base: `es` o `en`.

Resolución recomendada:

1. `es-ES` exacto;
2. `es` base;
3. bundled `es`;
4. fallback ARB genérico solo si el producto lo necesita más adelante.

Para `en-US`, el flujo es análogo. Los IDs no cambian al traducir.

Las claves de catálogo deben usar el locale efectivo y conservar releases independientes. Mientras la app solo exponga `es`/`en`, el primer seed remoto debe publicar `es` y no fingir que es `es-ES`; cuando se amplíe el locale de producto, se podrán publicar `es-ES` y `en-US` como releases exactas.

El cambio de locale debe cargar inmediatamente bundled/cache del nuevo idioma y sincronizar en background. Nunca se debe usar una traducción de otro locale para completar una cache.

## 12. Incompatibilidades con Phase 1/2

### Locale demasiado amplio

`PhraseLocale.canonicalize()` solo conserva idioma base. No puede distinguir `es-ES` de `es-MX` ni `en-US` de `en-GB`. Esto debe cambiar antes de publicar releases regionales.

### Daily selection y versión de release

El store ya separa daily selection por locale y fecha, lo cual es correcto para evitar mezclar idiomas. Actualmente la canonicalización hace que la separación sea `es`/`en`, no exacta por región.

Además, `CompletedDayPhraseService` conserva la selección solo si `daily.catalogVersion == catalog.catalogVersion`. Eso protege la versión pero fuerza una nueva selección cuando llega una release nueva, incluso si el mismo ID sigue habilitado. Para el contrato remoto se debe aplicar la política de la sección 16.

### `contentVersion` por traducción

`MotivationalPhrase.contentVersion` existe y el JSON bundled lo representa, pero el modelo SQL propuesto lo coloca en la frase maestra. Con varias traducciones, el versionado correcto es por `phrase_id + locale`, materializado en cada entry de release.

### Catálogo bundled actual

Los fallback actuales tienen 15 frases por locale, no las 300 objetivo:

- es: 4 personal, 4 consistency y 7 motivation;
- en: 4 personal, 4 consistency y 7 motivation.

Esto no es un bug de Phase 1. La release remota de 300 frases debe ser adicional y el bundled debe continuar siendo un fallback funcional.

### Estado de Home

No se detecta una incompatibilidad que requiera tocar Home para Fase 3. El controller debe seguir resolviendo localmente desde una source cache-first/bundled. La sincronización debe notificar o invalidar la source en segundo plano, no bloquear la presentación.

## 13. Seed de 300 frases

Recomendación: archivo SQL de seed versionado separado de la migración estructural, acompañado por un archivo fuente auditable y un script de generación/validación.

Propuesta futura:

~~~text
supabase/seeds/completed_day_phrase_es_es_v1.sql
supabase/tests/completed_day_phrase_catalog_verification.sql
tooling/completed_day_phrase/validate_catalog.dart
~~~

El SQL puede seguir el patrón CTE `seed_data (...) as (values ...)` del Shop, pero no conviene mantener 300 filas escritas manualmente en la migración de tablas. El flujo recomendado es:

1. fuente estructurada versionada, por ejemplo JSON/CSV editorial;
2. script que valida y genera SQL determinista;
3. SQL con `on conflict` solo para el seed controlado;
4. publicación explícita que materializa entries de release;
5. verificación SQL posterior.

La migración estructural no debe insertar las 300 frases. El seed sí debe ser repetible y auditable, pero la publicación de una release debe ser una operación diferenciada.

## 14. Validación pre-publicación

### Validaciones del script/Dart

- exactamente 300 IDs en la release inicial;
- 50 personal, 100 consistency y 150 motivation;
- IDs únicos y estables;
- locale válido y único por snapshot;
- templates no vacíos y de longitud razonable;
- tokens pertenecientes al conjunto admitido por `PhraseTemplateRenderer`;
- `required_tokens` exactamente igual al conjunto de tokens del template;
- weights positivos y finitos dentro del rango SQL;
- `source_type` válido;
- `author` obligatorio para quote/proverb y nulo para original salvo excepción editorial explícita;
- `review_status = published` para todas las entries de una release;
- ninguna traducción publicada incompleta;
- versión de schema compatible;
- coherencia entre `contentVersion` y el snapshot generado.

### Validaciones SQL

- PK/unique de IDs y `(phrase_id, locale)`;
- checks de category/tone/source/review/weight/version;
- no duplicados en entries de una release;
- locale y release version no vacíos;
- una sola release published por locale;
- `published_at` coherente con status;
- todas las entries de una release referencian el mismo release;
- trigger o RPC de publicación que no permite activar una release sin entries;
- RLS, grants, funciones y triggers presentes.

SQL no debe intentar reproducir toda la semántica de tokens si el renderer Dart es la autoridad de sintaxis. La publicación debe ejecutarse mediante un script que haga la validación completa y la comprobación SQL debe cubrir invariantes estructurales.

## 15. Citas y proverbios

El texto y su atribución deben viajar separados:

~~~text
sourceType = original | quote | proverb
author     = null | texto editorial
template   = solo el contenido renderizable
~~~

Ejemplos:

- frase original: `sourceType=original`, `author=null`;
- refrán: `sourceType=proverb`, `author='Refrán popular'`;
- Antonio Machado: `sourceType=quote`, `author='Antonio Machado'`.

No se debe concatenar el autor dentro del template ni enviarlo como parte de una frase personalizada. `PhraseCatalogValidator` ya impone que quote/proverb tenga author; el DTO remoto debe conservar esa semántica.

## 16. Daily selection ante actualizaciones

Contrato recomendado:

### A. El ID sigue enabled y existe en la nueva release

Conservar el mismo `phraseId`. Actualizar la versión de release de la daily selection. No añadir una nueva entrada al historial solo por cambiar la release.

### B. El ID está disabled, retirado, falta o no puede renderizarse

Invalidar esa daily selection y seleccionar otra frase elegible con el `PhraseSelectionEngine`. Guardar la nueva selección en la misma fecha/locale.

### C. El ID sigue existiendo pero cambia su template

Conservar el ID y renderizar el template nuevo. Actualizar la versión guardada. El ID es identidad estable; el texto publicado pertenece a la release actual.

El service actual necesita una evolución pequeña para implementar esta política: al encontrar una selección de la misma fecha y locale, debe buscar el ID en el catálogo vigente aunque cambie `catalogVersion`; si sigue habilitado y renderizable, debe conservarlo. El `catalogVersion` sigue siendo necesario para saber qué snapshot se utilizó, no para invalidar automáticamente un ID estable.

Ante cambio de locale, no se deben copiar silenciosamente selecciones entre claves. Cada locale mantiene su selección independiente. El mismo ID puede conservarse solo como continuidad conceptual si existe una traducción válida, pero el contrato seguro por defecto es resolver la selección del nuevo locale sin mezclar historial de otro idioma.

## 17. Sincronización y cambio de usuario

La coordinación debe recibir:

- `userId` autenticado;
- `scopeEpoch` o equivalente;
- locale solicitado y locale efectivo;
- release/cache actual.

Antes de guardar, debe comprobar que user/scope/locale siguen siendo los mismos. El catálogo es común al dispositivo, pero una resolución en curso no debe actualizar el controller de una cuenta o locale que ya no está activo.

La sincronización debe ser best-effort:

- errores de red solo en debug logging;
- no snackbars ni estados de error de Home;
- no borrar cache válida por respuesta inválida;
- no enviar nombre, streak, progress ni rendered phrase a Supabase.

## 18. Analytics y feature flag

Recomendación: posponer ambos.

No se encontró un canal de analytics de producto general ni un feature flag global que aporte valor inmediato. La feature ya tiene fallback local y puede apagarse operativamente dejando de publicar releases o haciendo que la RPC devuelva la versión actual sin cambiar Home.

Si posteriormente se necesita rollout gradual, debe añadirse primero un contrato de runtime/fallback, no una condición remota dentro del renderer. Analytics de impresión o selección necesitaría además política de privacidad y deduplicación por usuario/fecha.

## 19. Tests de Fase 3

### DTO y validación

- payload válido se convierte al mismo `PhraseCatalog`;
- category, tone, sourceType, author y contentVersion se conservan;
- tokens y `requiredTokens` inválidos se rechazan;
- locale o schemaVersion inesperados se rechazan;
- release sin entries completas se rechaza.

### Cache/repository

- cache hit no hace red;
- misma release no descarga snapshot;
- nueva release válida reemplaza el slot activo;
- fallo al escribir el slot conserva el slot anterior;
- pointer corrupto recupera el otro slot válido;
- payload inválido no sustituye cache;
- error de red conserva cache;
- sin cache se usa bundled;
- locales no se mezclan;
- cambio de usuario no contamina history ni daily selection.

### Sync

- metadata igual termina en una request;
- metadata nueva hace exactamente la segunda request;
- la release descargada por `releaseId` sigue siendo consistente si aparece otra publicada durante el proceso;
- respuesta tardía de otro scope se descarta;
- no se bloquea la resolución local.

### Daily selection

- misma release conserva ID;
- release nueva con ID enabled conserva ID;
- ID disabled fuerza nueva selección;
- template actualizado conserva ID y usa nuevo texto;
- locale nuevo mantiene cache y selección independientes.

### SQL estático

Crear una verificación en `supabase/tests/completed_day_phrase_catalog_verification.sql` siguiendo el estilo existente de `shop_catalog_verification.sql`, `weekly_report_foundation_static_verification.sql` y las verificaciones de Feedback. Debe comprobar tablas, constraints, indexes, RLS, grants, RPCs, publicación única y snapshot entries.

## 20. Archivos previstos para la implementación

### Supabase

- `supabase/migrations/<timestamp>_create_completed_day_phrase_catalog.sql`;
- `supabase/migrations/<timestamp>_create_completed_day_phrase_catalog_read_api.sql`;
- `supabase/seeds/completed_day_phrase_es_es_v1.sql`;
- `supabase/tests/completed_day_phrase_catalog_verification.sql`;
- `supabase/tests/completed_day_phrase_catalog_release_verification.sql`.

Si el equipo mantiene una sola migración para tabla y RPC, la segunda puede fusionarse; mantenerlas separadas favorece auditoría y reparaciones forward.

### Cliente

- `lib/features/completed_day_phrase/data/remote/supabase_phrase_catalog_data_source.dart`;
- `lib/features/completed_day_phrase/data/remote/phrase_catalog_dto.dart`;
- `lib/features/completed_day_phrase/data/local/shared_preferences_phrase_catalog_cache_store.dart`;
- `lib/features/completed_day_phrase/data/phrase_catalog_repository.dart`;
- `lib/features/completed_day_phrase/application/phrase_catalog_sync_coordinator.dart`;
- composición del controller/service para inyectar la source cache-first;
- evolución localizada de `PhraseLocale` y de la política de daily selection;
- tests de DTO, cache, sync y service descritos arriba.

No se prevén cambios en Home ni en habit cards para conectar el catálogo remoto.

## 21. Migraciones que habría que crear

Orden recomendado:

1. crear/reutilizar `pgcrypto` y `app_private`, revocando el schema;
2. reutilizar `app_private.set_updated_at()`;
3. crear tablas editoriales;
4. crear tabla de releases;
5. crear tabla de snapshot entries;
6. añadir constraints, indexes, FKs y comentarios;
7. añadir triggers de timestamps e inmutabilidad de releases publicadas;
8. habilitar RLS y dejar tablas sin grants directos al cliente;
9. crear las RPCs de metadata y snapshot;
10. revocar/grant explícitos de las RPCs;
11. añadir tests/verificaciones SQL;
12. aplicar el seed y publicar la primera release en un paso controlado separado.

No se debe ejecutar ninguna de estas operaciones en esta fase de auditoría.

## 22. Riesgos antes de implementar

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| Locale actual solo `es`/`en` | No distingue `es-ES`/`en-US` | Acordar canonicalización exacta antes del seed regional |
| Publicar leyendo filas editoriales vivas | Mezcla parcial de traducciones | Entries materializadas por release |
| `contentVersion` solo en frase maestra | Una traducción cambia la versión de otra | Versionar traducción y snapshot por locale |
| SharedPreferences con payload grande | Escrituras o recuperación menos robustas | Doble slot, medir payload real y fallback bundled |
| Release publicada mutable | Clientes ven contenido no reproducible | Trigger de inmutabilidad y nuevas releases |
| RPC `SECURITY DEFINER` mal configurada | Escalada o lectura indebida | `search_path=''`, grants mínimos, tests de privilegios |
| Release sin una traducción renderizable | Service devuelve null o cambia selección | Validación completa pre-publish y validator Dart |
| Cambio de release invalida siempre daily ID | Rotación innecesaria de frase | Conservar ID si sigue enabled y renderizable |
| Cambio de locale copia selección incorrecta | Texto/idioma mezclado | Caches y daily selections independientes |
| Error de red durante bootstrap | Home bloqueada o mensaje de error | Sync posterior y best-effort |
| 300 frases manuales | IDs/tokens/categorías incorrectos | Fuente estructurada + script + seed generado + verificación |
| Autor y sourceType incoherentes | Atribución editorial incorrecta | Checks de script, SQL y `PhraseCatalogValidator` |
| Cliente recibe datos personalizados | Riesgo de privacidad | Supabase solo templates/metadata; interpolación local |
| Intentar usar anon sin necesidad | Superficie pública innecesaria | Solo `authenticated`; bundled cubre pre-auth |

## Conclusión operativa

La Fase 3 debe implementar primero el contrato de release y su snapshot, no una lectura directa de traducciones activas. La combinación recomendada es:

~~~text
editorial tables
      -> validated immutable release entries
      -> authenticated read RPCs
      -> DTO -> same PhraseCatalog
      -> validated double-slot SharedPreferences cache
      -> cache/bundled local source
      -> existing CompletedDayPhraseService
~~~

Esto conserva el comportamiento offline de Fases 1/2, evita bloquear Home y deja una superficie remota pequeña, versionada y auditable.
