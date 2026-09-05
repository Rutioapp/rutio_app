# Completed Day Phrase · es-ES v1

## Fuente editorial

La fuente de verdad es [`docs/source/rutio_frases_home_documento_maestro.docx`](../docs/source/rutio_frases_home_documento_maestro.docx), versión 1.0, fechada el 31 de julio de 2026. El catálogo estructurado se generó desde las tres tablas editoriales del Word; `assets/phrase_fallback/es.json` no se utilizó como fuente.

Fuente canónica: [`supabase/catalog/completed_day_phrase/es-ES.v1.json`](../supabase/catalog/completed_day_phrase/es-ES.v1.json).

- `schemaVersion`: `1`
- `catalogVersion`: `"1"`
- `releaseVersion`: `1`
- `locale`: `es-ES`
- Total: 300 frases
- Distribución: 50 `personal`, 100 `consistency`, 150 `motivation`
- Todas las frases tienen `weight = 100`, `enabled = true` y `contentVersion = 1`.

Los IDs, templates, tokens y atribuciones se copiaron literalmente del documento. Las frases con `Original Rutio` tienen `sourceType = original` y `author = null`. Las atribuciones de refranes, proverbios y citas se mantienen en `author`, fuera del template. `Refrán` y `Proverbio` usan `sourceType = proverb`; las atribuciones `Antonio Machado` y `Máxima délfica` usan el tipo soportado `quote`.

El Word no asigna tone individual. Por eso `tone` es metadata técnica derivada, no una clasificación editorial declarada: una regla léxica fija y conservadora asigna `energetic` solo a lenguaje de intensidad explícita, `balanced` a lenguaje de continuidad/acción y `gentle` al resto. Resultado: 122 `gentle`, 136 `balanced`, 42 `energetic`.

## Validación

Herramienta: [`tool/completed_day_phrase/validate_catalog.dart`](../tool/completed_day_phrase/validate_catalog.dart).

Resultado de la fuente actual:

- 300 entradas y distribución 50/100/150: OK.
- IDs secuenciales completos, sin ausencias ni duplicados: OK.
- `requiredTokens` coincide exactamente con los placeholders reales; solo aparecen `name`, `streak_label` y `progress`: OK.
- Templates no vacíos, pesos y `contentVersion` positivos, tipos de fuente y autor coherentes: OK.
- Longitud máxima: 85 caracteres.
- Frases de más de 110 caracteres: ninguna.
- Duplicados exactos de texto: ninguno.

## Seed generado y migración productiva

El SQL reproducible está en [`supabase/seeds/completed_day_phrase_es_es_v1.sql`](../supabase/seeds/completed_day_phrase_es_es_v1.sql) y se genera con [`tool/completed_day_phrase/generate_es_release_sql.dart`](../tool/completed_day_phrase/generate_es_release_sql.dart). La salida es determinista: dos ejecuciones con la misma fuente produjeron el mismo SHA-256 (`07DBCBAF978C567BF3575A50E9338DFAD3CCD0D53035D2F6E6A184935A613750`).

La migración productiva [`supabase/migrations/20260905120000_publish_completed_day_phrase_es_es_v1.sql`](../supabase/migrations/20260905120000_publish_completed_day_phrase_es_es_v1.sql) es una copia byte a byte del seed generado. La cadena mantenible es:

`es-ES.v1.json` → `generate_es_release_sql.dart` → `supabase/seeds/...sql` → migración productiva.

La migración no es una fuente editorial independiente y no debe editarse manualmente. La comprobación [`tool/completed_day_phrase/verify_es_release_artifacts.dart`](../tool/completed_day_phrase/verify_es_release_artifacts.dart) regenera el SQL desde el JSON y compara el resultado completo tanto con el seed como con la migración; detecta drift de contenido, orden o SQL sin depender de timestamps.

El seed:

1. Rechaza con una excepción controlada una `es-ES` v1 ya publicada, antes de mutarla.
2. Hace upsert de las 300 filas base y las 300 traducciones `reviewed`.
3. Crea o reutiliza una release draft `es-ES` v1.
4. Materializa las 300 `phrase_catalog_release_entries` desde metadata y traducciones.
5. Verifica conteos, categorías, IDs esperados, templates, tokens, pesos y `contentVersion`.
6. Solo después publica la release y la marca como `is_current = true`; el contenido snapshot publicado queda protegido por las migraciones de Phase 3A.

Las verificaciones RPC están en [`supabase/tests/completed_day_phrase_es_es_release_v1_verification.sql`](../supabase/tests/completed_day_phrase_es_es_release_v1_verification.sql). Comprueban metadata de release v1, snapshot de 300 frases y muestras `personal_001`, `personal_050`, `consistency_001`, `consistency_100`, `motivation_001` y `motivation_150`.

## Compatibilidad y tamaño

El snapshot con forma RPC se parsea con `PhraseCatalogSnapshotDto`/`PhraseCatalogJson` y es aceptado por `PhraseCatalogValidator`. La prueba también escribe y lee el catálogo completo mediante `SharedPreferencesPhraseCatalogCacheStore` y lo devuelve desde `PhraseCatalogRepository` sin red.

- JSON canónico formateado: aproximadamente 104 KB (104.053 bytes).
- Payload real serializado en un slot de cache: 72.997 bytes.
- Dos slots de cache: 145.994 bytes.

El fallback empaquetado `assets/phrase_fallback/es.json` permanece pequeño y sin sustituir. `en-US` sigue pendiente; no se creó traducción ni release inglesa.

## Verificación ejecutada

- `dart run tool/completed_day_phrase/validate_catalog.dart`: OK.
- Generador SQL ejecutado dos veces y hash comparado: OK, salida idéntica.
- Comprobación JSON → seed → migración: OK, sin drift.
- Regresión de bloques `VALUES`: OK; todas las filas finales carecen de coma antes de `ON CONFLICT`.
- `dart analyze tool/completed_day_phrase`: OK.
- `dart analyze lib/features/completed_day_phrase lib/screens/home tool/completed_day_phrase`: OK.
- `flutter test --no-pub test/features/completed_day_phrase/phase_3b_catalog_test.dart`: OK.
- `flutter test --no-pub test/tool/completed_day_phrase/generate_es_release_sql_test.dart`: OK.
- `flutter test --no-pub test/features/completed_day_phrase`: OK.
- Las pruebas SQL RPC no se ejecutaron contra una base local porque no hay Postgres local disponible en el entorno; el test queda preparado para ejecutarse después de aplicar migraciones y seed.
- `supabase db lint --local` tampoco pudo conectar porque no hay Postgres local en `127.0.0.1:54322`.
- No se ejecutó `supabase db push`, no se aplicaron migraciones remotas y no se modificó Supabase remoto.

## Aplicación productiva posterior

El orden pendiente de migraciones es:

1. `supabase/migrations/20260905100000_create_completed_day_phrase_catalog.sql`
2. `supabase/migrations/20260905110000_create_completed_day_phrase_catalog_read_api.sql`
3. `supabase/migrations/20260905120000_publish_completed_day_phrase_es_es_v1.sql`

Cuando se autorice el despliegue:

```powershell
supabase projects list
supabase migration list
supabase db push --dry-run
supabase db push
supabase migration list
```

Después del `db push`, ejecutar [`supabase/tests/completed_day_phrase_es_es_release_v1_verification.sql`](../supabase/tests/completed_day_phrase_es_es_release_v1_verification.sql) contra el proyecto enlazado mediante SQL Editor o `supabase db query --linked --file ...` como verificación QA, nunca como mecanismo principal de publicación. Confirmar después la QA de aplicación. No se ha ejecutado ninguno de esos comandos en esta tarea. Para una futura release 2, crear un nuevo JSON y seed, usar `release_version = 2`, materializar un snapshot nuevo y mover el puntero `is_current` después de las verificaciones, sin actualizar ni borrar las entries publicadas de v1.
