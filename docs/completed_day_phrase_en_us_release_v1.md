# Completed Day Phrase en-US v1

## Fuente editorial y alcance

La fuente editorial es [`docs/source/rutio_frases_home_documento_maestro.docx`](../docs/source/rutio_frases_home_documento_maestro.docx). El catálogo estructurado en español de España se usa como referencia de IDs y metadatos; las traducciones en-US se mantienen en una capa separada y no proceden del fallback de 15 frases.

La fuente canónica resultante es [`supabase/catalog/completed_day_phrase/en-US.v1.json`](../supabase/catalog/completed_day_phrase/en-US.v1.json):

- `schemaVersion`: `1`
- `catalogVersion`: `"1"`
- `releaseVersion`: `1`
- `locale`: `en-US`
- Total: 300 frases
- Distribución: 50 `personal`, 100 `consistency`, 150 `motivation`
- `contentVersion`: `1`, `weight = 100` y `enabled = true` en todas las entradas

Los IDs, categorías, tonos, tipos de fuente, tokens requeridos, pesos y orden coinciden con `es-ES.v1`. Los templates en-US son localizaciones naturales, conservan únicamente `{name}`, `{streak_label}` y `{progress}`, y mantienen exactamente sus tokens requeridos. El máximo es 102 caracteres y no hay templates duplicados ni entradas de más de 110 caracteres.

Las 12 últimas frases motivacionales conservan su naturaleza de proverbio o cita. Sus atribuciones localizadas viven en `author` de la traducción y del snapshot de release: `Popular proverb`, `Traditional proverb`, `Latin proverb`, `Antonio Machado` y `Delphic maxim`. Las frases originales de Rutio mantienen `author = null`. La tabla base `motivational_phrases.author` no se sobreescribe al materializar en-US.

## Generación y publicación

El generador reproducible es [`tool/completed_day_phrase/build_en_us_catalog.py`](../tool/completed_day_phrase/build_en_us_catalog.py) para el JSON y [`tool/completed_day_phrase/generate_release_sql.dart`](../tool/completed_day_phrase/generate_release_sql.dart) para SQL. El tooling es multi-locale y conserva wrappers compatibles para es-ES.

```powershell
python tool/completed_day_phrase/build_en_us_catalog.py
dart run tool/completed_day_phrase/validate_catalog.dart supabase/catalog/completed_day_phrase/en-US.v1.json
dart run tool/completed_day_phrase/compare_catalogs.dart
dart run tool/completed_day_phrase/verify_release_artifacts.dart `
  supabase/catalog/completed_day_phrase/en-US.v1.json `
  supabase/seeds/completed_day_phrase_en_us_v1.sql `
  supabase/migrations/20260905130000_publish_completed_day_phrase_en_us_v1.sql
```

El seed [`supabase/seeds/completed_day_phrase_en_us_v1.sql`](../supabase/seeds/completed_day_phrase_en_us_v1.sql) y la migración [`supabase/migrations/20260905130000_publish_completed_day_phrase_en_us_v1.sql`](../supabase/migrations/20260905130000_publish_completed_day_phrase_en_us_v1.sql) son byte a byte equivalentes. La migración crea o reutiliza el draft, materializa 300 entradas, valida conteos y metadata, publica la release y la marca como current. Si la release en-US v1 ya está publicada, una nueva ejecución falla antes de mutarla mediante un no-op controlado.

El snapshot de es-ES sigue siendo independiente y se conserva en su propia release, seed y migración. El catálogo de la app sigue resolviendo `en` a `en-US`, separando caché, historial y selección diaria por locale; el fallback empaquetado no se amplía con las 300 frases.

La verificación SQL está en [`supabase/tests/completed_day_phrase_en_us_release_v1_verification.sql`](../supabase/tests/completed_day_phrase_en_us_release_v1_verification.sql). Comprueba release current, 300 entradas, distribución 50/100/150, tokens, metadata, atribuciones y muestras de los límites de cada categoría.

## Verificación local

- Validación de ambos catálogos: OK.
- Comparación estructural es-ES/en-US: OK, 300 entradas.
- Generación determinista y comprobación JSON → seed → migración para ambos locales: OK, sin drift.
- Tests de catálogo, cliente, tooling y regresión es-ES: OK.
- `dart analyze` de la feature y tooling: OK.
- No se ejecutó `supabase db push`, no se ejecutaron migraciones remotas y no se modificó Supabase remoto.

## Despliegue posterior autorizado

Después de revisar el seed y enlazar explícitamente el proyecto correcto, ejecutar en ese entorno:

```powershell
supabase migration list
supabase db push --dry-run
supabase db push
supabase migration list
```

Después del despliegue, ejecutar [`supabase/tests/completed_day_phrase_en_us_release_v1_verification.sql`](../supabase/tests/completed_day_phrase_en_us_release_v1_verification.sql) contra el proyecto enlazado mediante SQL Editor o `supabase db query --linked --file ...`, y completar QA de aplicación en locale inglés. Estos comandos no se han ejecutado en esta tarea.
