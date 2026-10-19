# Rutio — Fase 1: verificación de autorización, RLS y operaciones sensibles

Fecha: 2026-10-12
Alcance: revisión read-only del repositorio, migraciones y tests locales.
Estado remoto: no verificado. `supabase status` no pudo inspeccionar la instancia porque Docker Engine no está disponible en este entorno.

## 1. Conclusión ejecutiva

La separación entre operaciones sensibles protegidas por RPC y operaciones de sincronización directa todavía no es uniforme.

Confirmado en el código fuente:

- Flutter puede escribir directamente `user_progress`, `xp_events`, `currency_events` y `user_achievements`.
- Los payloads de progreso, XP y moneda contienen valores derivados del cliente; el repositorio local no demuestra que esas tablas sean sólo una proyección no autoritativa.
- Las migraciones más recientes de recompensas de hábitos implementan `SECURITY DEFINER`, validación de propietario, idempotencia lógica, locks advisory y `FOR UPDATE` sobre el wallet.
- Premium controla la interfaz desde el entitlement del cliente, pero no se ha verificado un enforcement equivalente para todos los recursos backend.
- La configuración efectiva desplegada, los grants efectivos y el comportamiento RLS entre dos usuarios no están comprobados.

No se ha confirmado una explotación cross-user ni una configuración remota vulnerable. Sí queda confirmado un riesgo de manipulación por el propio usuario si los grants y políticas del código fuente están desplegados tal como aparecen.

## 2. Matriz de tablas y operaciones

La columna “estado” distingue el contrato que aparece en el repositorio de la verificación efectiva en Supabase.

| Dominio / tabla | RLS y políticas observadas en fuente | Grants / escritura observada | Estado de verificación |
|---|---|---|---|
| `profiles` | RLS; lectura, inserción y actualización del propio `auth.uid()` | Flutter hace upsert/update de perfil | Fuente revisada; remoto no verificado |
| `habits` | RLS; CRUD del propio usuario | Flutter CRUD directo | Fuente revisada; remoto no verificado |
| `habit_logs` | RLS; CRUD/upsert del propio usuario | Flutter upsert/delete directo | Fuente revisada; remoto no verificado |
| `journal_entries`, `daily_moods` | Políticas propias de la propuesta Diary V2; CRUD del propietario | Flutter upsert/delete directo | Parte del contrato está en `supabase/sql`, no es evidencia de despliegue; remoto no verificado |
| `user_progress` | RLS; select/insert/update propios, sin delete en el contrato revisado | `UserProgressRepository` hace `select` y `upsert` directo | Riesgo confirmado en cliente; grants remotos no verificados |
| `xp_events` | RLS; select/insert propios | `XpEventRepository` inserta directamente cantidad y origen recibidos del cliente | Riesgo confirmado en cliente; remoto no verificado |
| `currency_events` | RLS; select/insert propios | `CurrencyEventRepository` inserta directamente eventos de moneda | Riesgo confirmado en cliente; remoto no verificado |
| `user_achievements` | RLS; select/insert/update propios | Repositorio Flutter hace upsert/update/insert | Riesgo de autoridad del cliente; remoto no verificado |
| `user_wallets` | RLS; lectura del wallet propio y catálogo activo | Las migraciones de economía revocan escrituras directas; escritura esperada vía RPC | Contrato fuerte en migraciones; remoto no verificado |
| `user_inventory`, `user_equipped_cosmetics` | RLS; lectura propia; catálogo activo para lectura | Escrituras sensibles previstas vía RPC; grants directos limitados | Contrato revisado; remoto no verificado |
| `shop_items`, bundles y catálogo | RLS y lectura autenticada de elementos activos | Sin escritura de cliente prevista | Contrato revisado; remoto no verificado |
| ledgers de shop, recompensa, mystery box, utilities y achievements | RLS; lectura del ledger propio; escrituras directas revocadas | Inserción mediante RPC `SECURITY DEFINER` | Contrato revisado; remoto no verificado |
| streak protection / shields | RLS de propietario; operaciones sensibles vía RPC | Cliente llama RPC de consumo/protección | Contrato revisado; staging necesario |
| `feedback` y respuestas | RLS; creación propia y mutaciones sensibles vía RPC | Insert directo de feedback; update/delete por RPC | Contrato revisado; remoto no verificado |
| weekly report snapshots / payloads | RLS en tablas; APIs públicas revocadas para `public`/`anon`; RPCs concedidas a `authenticated` | Cliente usa RPCs `get_my_*`, `list_my_*`, `refresh_*`, `activate_*` | Owner-scoping visible en fuente; entitlement premium remoto no probado |
| suscripciones / identidad RevenueCat | No se encontró una tabla de suscripción con enforcement server-side equivalente | RevenueCat y entitlement se consultan en cliente | Integración cliente revisada; webhook/enforcement remoto no verificado |

### Grants de RPC relevantes en fuente

Las migraciones conceden a `authenticated` las funciones de compra/equipamiento, recompensas de hábitos, logros/niveles, mystery box, utilidades, streak protection y weekly reports, y revocan `public`/`anon` para las APIs sensibles. La migración de hardening de recompensa de hábitos también vuelve a conceder `authenticated` y `service_role` para `apply_habit_completion_reward` y `reverse_habit_completion_reward`.

Esto no prueba el estado remoto: hay SQL bajo `supabase/sql` que parece patch/propuesta y varias migraciones sucesivas que sustituyen funciones y grants. Hay que inspeccionar `pg_proc`, `information_schema.routine_privileges`, `pg_class` y `pg_policies` en staging.

## 3. Flujo real de escrituras

### Progreso, XP y moneda sincronizados desde Flutter

El flujo observado es:

`acción local → UserStateStore / lógica de sincronización → UserProgressSyncService → repositorio Supabase → escritura directa`

En concreto:

1. La app actualiza estado local de progreso/economía.
2. `UserProgressSyncService` valida que haya usuario autenticado y normaliza algunas fuentes.
3. `UserProgressRepository.touchProgressFromLocalState` lee y hace `upsert` de `user_progress`.
4. `XpEventRepository` inserta en `xp_events`.
5. `CurrencyEventRepository` inserta en `currency_events`.
6. `UserAchievementRepository` puede hacer upsert/update/insert de logros.

El `user_id` se fuerza normalmente al usuario de la sesión, lo que reduce el riesgo cross-user directo, pero no impide que ese usuario modifique su propio XP, nivel, balance derivado o eventos si la política permite el insert/update. Además, `touchProgressFromLocalState` es un patrón read-then-write sin control de versión observado: dos dispositivos pueden perder actualizaciones.

### Recompensa cloud de completar hábito

El flujo RPC observado es:

`completar hábito → data source cloud → apply_habit_completion_reward(request_id, habit_id, date, ...) → validación server-side → lock → cálculo → wallet → ledger`

La función más reciente:

- exige `auth.uid()` y valida request, hábito, fecha, evento y operación;
- comprueba que el hábito pertenece al usuario;
- toma locks advisory por usuario/request/source;
- hace idempotencia por `request_id` y por identidad lógica de la operación;
- calcula la recompensa en PostgreSQL mediante función privada;
- bloquea el wallet con `FOR UPDATE`;
- actualiza el balance e inserta el ledger dentro de la misma transacción.

Este camino tiene controles razonables contra replay y carreras. El riesgo pendiente es que coexistía con el camino directo de sincronización de `user_progress` y eventos. Hay que determinar en staging si ambos son autoridad, si uno es sólo proyección y si una misma acción puede acreditarse por los dos.

### Mystery box y shop

El cliente llama RPC para la apertura cloud y guarda una operación pendiente local con request id. La migración protege el consumo con ledger/idempotencia y grants autenticados. Los cinco tests fallidos de mystery box devuelven `unavailableState`; esto apunta primero a configuración/fixture/estado de sesión local, no demuestra un bypass remoto.

## 4. Vulnerabilidades confirmadas y riesgos hipotéticos

### Confirmadas en el alcance local

1. **Autoridad de cliente en economía/progreso — P1.** Existen escrituras directas desde Flutter a tablas que contienen progreso, XP, moneda y logros. El cliente puede construir o modificar el payload antes de enviarlo.
2. **Posible pérdida de actualización — P1/P2.** El read-then-upsert de progreso no muestra versionado, `updated_at` monotónico validado ni operación atómica para combinar incrementos.
3. **Enforcement Premium incompleto — P1 si el recurso es de pago.** El gate `PremiumAccessPolicy` depende de `state.isPremium`; no se encontró evidencia suficiente de que los RPC de weekly report y otros recursos premium verifiquen entitlement server-side.
4. **Verificación de despliegue incompleta — P1 de assurance.** No fue posible conectar a Supabase local ni hay evidencia de staging en esta ejecución. La matriz de fuente no puede presentarse como configuración efectiva.

### Riesgos todavía hipotéticos

- **Cross-user/BOLA.** Las políticas de fuente parecen usar `auth.uid()`, pero no se ejecutó la prueba con usuarios A/B.
- **Grants excesivos.** Una migración posterior puede haber dejado grants antiguos; sólo `information_schema`/catálogos de staging lo confirma.
- **Doble acreditación.** Puede ocurrir si la ruta RPC y la sincronización directa representan la misma recompensa; requiere traza de una acción real en staging.
- **`search_path=public` en RPCs de utilities.** Es menos estricto que `search_path=''`; no es una explotación confirmada. Hay que comprobar `CREATE` sobre `public`, resolución de objetos y ownership.
- **Rate limiting de RPC/PostgREST.** Sólo se verificó configuración local de Auth y `api.max_rows`; no hay evidencia suficiente de límites de negocio desplegados.

## 5. Premium: qué puede seguir siendo cliente y qué debe ser servidor

Puede permanecer como control de interfaz del cliente: mostrar/ocultar paywall, iconos de bloqueo, navegación premium, previews, copy y estado visual mientras no conceda datos ni efectos protegidos.

Debe autorizarse en backend: lectura o generación de informes premium, exportaciones, agregados históricos no gratuitos, operaciones que concedan monedas/objetos y cualquier acción cuya ausencia de entitlement tenga valor económico. La autenticación `authenticated` por sí sola no equivale a entitlement premium.

No se recomienda implementar webhooks ni nuevos servicios en esta fase. Primero hay que identificar el origen fiable del entitlement y probar el comportamiento de cada RPC con usuario free, premium y entitlement expirado.

## 6. Clasificación de los 35 tests fallidos

| Grupo | Nº | Clasificación | Lectura actual |
|---|---:|---|---|
| Achievement overlay | 1 | Regresión funcional UI | Cola/orden visual; no seguridad |
| Generador EN-US de completed-day SQL | 1 | Fixture/generador o contrato de formato | Revisar normalización de saltos de línea y salida determinista |
| Mystery box use case | 5 | Entorno/fixture/configuración; integridad potencial | Todos reciben `unavailableState`; no prueba fallo RPC remoto |
| Onboarding con pantalla pequeña/text scale | 3 | Regresión UI | Layout/scroll, no seguridad |
| Shop cloud disabled by default | 1 | Configuración/fixture | Contrato de flag por defecto no coincide con test |
| Shop customization | 7 | Regresión UI/controlador/fixture | Estado persistido, filtros y refresco |
| Home habit status filter | 2 | Regresión UI | Menú/fecha/filtros |
| Settings → Feedback | 1 | Regresión de navegación | No seguridad |
| Notification rules | 2 | Regresión lógica | Candidatos y ordenación |
| Streak shield cloud | 1 | Entorno/cloud fixture; integridad potencial | Requiere aislar sesión/RPC/fixture |
| Onboarding SQL static tests | 3 | Problema de entorno/fixture de texto probable | Las aserciones leen LF y varios SQL están en CRLF; no demuestra SQL inseguro |
| Weekly report static tests | 6 | Problema de entorno/fixture de texto probable | Mismo patrón de contratos estáticos y line endings |
| Recommendation migration static test | 1 | Problema de entorno/fixture de texto probable | Aislar normalización antes de atribuir regresión SQL |
| ES release SQL generator | 1 | Generador/line endings probable | No evidencia de vulnerabilidad |
| Loading screen retry | 1 | Regresión de estado/UI | Flujo externo de error/reintento |

Total: **35**. No se modificaron tests. Los grupos de mystery box y streak shield deben revisarse antes de cerrar el lote porque tocan integridad, aunque el resultado actual no confirma una vulnerabilidad de backend.

## 7. Correcciones propuestas por prioridad

### P0 — No hay hallazgo confirmado que requiera P0

No se observó una vía confirmada de acceso cross-user o ejecución privilegiada.

### P1

1. **Definir autoridad de datos.** Declarar por tabla si es autoridad server-side o proyección local. En particular, decidir si `user_progress`, `xp_events`, `currency_events` y `user_achievements` pueden aceptar escrituras de cliente.
2. **Cerrar la autoridad de economía.** Para balances y acreditaciones, mantener la lógica en transacciones/RPC PostgreSQL seguras donde ya existe el patrón, y eliminar sólo las escrituras directas que duplican esa autoridad. No hace falta migrar toda la economía a Edge Functions.
3. **Proteger los recursos Premium en el punto de lectura/escritura.** Añadir la comprobación server-side únicamente a RPCs y datos que realmente sean premium; conservar los gates visuales del cliente.
4. **Verificar staging antes de cambiar migraciones.** Confirmar RLS, grants, funciones efectivas y pruebas A/B.

### P2

5. Sustituir read-then-upsert de progreso por una operación atómica o un esquema de versión/idempotency key según la autoridad elegida.
6. Normalizar line endings en el lector de tests o en los fixtures SQL sin alterar el significado de las migraciones.
7. Separar claramente tests de entorno/configuración de tests de integridad y añadir fixtures autenticados deterministas.
8. Medir y limitar replays, llamadas RPC y eventos de economía a nivel de request/usuario.

## 8. Verificaciones remotas exactas para staging

Ejecutar como rol de inspección autorizado y guardar el resultado con timestamp. No ejecutar estas comprobaciones contra producción sin aprobación explícita.

### 8.1 Tablas, RLS y políticas

```sql
select n.nspname as schema_name,
       c.relname as table_name,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as force_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public', 'app_private')
  and c.relkind in ('r', 'p')
  and c.relname in (
    'profiles','habits','habit_logs','journal_entries','daily_moods',
    'user_progress','xp_events','currency_events','user_achievements',
    'user_wallets','user_inventory','user_equipped_cosmetics',
    'shop_items','shop_bundles','shop_bundle_items','owned_shop_bundles',
    'habit_currency_reward_ledger','currency_event_ledger',
    'mystery_box_opening_ledger','user_utility_ledger',
    'achievement_reward_ledger','weekly_report_snapshots'
  )
order by 1, 2;

select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname in ('public', 'app_private')
order by schemaname, tablename, policyname;
```

### 8.2 Grants efectivos de tablas y secuencias

```sql
select grantee, table_schema, table_name, privilege_type
from information_schema.role_table_grants
where table_schema in ('public', 'app_private')
  and grantee in ('anon','authenticated','service_role')
order by table_schema, table_name, grantee, privilege_type;

select grantee, object_schema, object_name, privilege_type
from information_schema.role_usage_grants
where object_schema in ('public', 'app_private')
order by object_schema, object_name, grantee;
```

### 8.3 Funciones `SECURITY DEFINER`, `search_path` y grants

```sql
select n.nspname as schema_name,
       p.proname,
       pg_get_function_identity_arguments(p.oid) as identity_args,
       p.prosecdef as security_definer,
       p.proleakproof as leakproof,
       p.proconfig as config,
       pg_get_userbyid(p.proowner) as owner
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public', 'app_private')
order by 1, 2, 3;

select grantee, routine_schema, routine_name, privilege_type
from information_schema.routine_privileges
where routine_schema in ('public', 'app_private')
  and grantee in ('anon','authenticated','service_role')
order by routine_schema, routine_name, grantee;
```

Para cada `SECURITY DEFINER`, revisar manualmente que valide `auth.uid()`, que no acepte `user_id` arbitrario, que use `search_path=''` o nombres totalmente cualificados y que sus tablas internas no sean escribibles por el cliente.

### 8.4 Constraints, índices e idempotencia

```sql
select n.nspname as schema_name,
       c.relname as table_name,
       con.conname,
       pg_get_constraintdef(con.oid) as definition
from pg_constraint con
join pg_class c on c.oid = con.conrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public','app_private')
order by 1, 2, 3;

select schemaname, tablename, indexname, indexdef
from pg_indexes
where schemaname in ('public','app_private')
order by schemaname, tablename, indexname;
```

Confirmar especialmente las constraints únicas por `request_id` y por identidad lógica de recompensa, además de checks de saldo no negativo.

### 8.5 Pruebas funcionales de staging con dos usuarios

Crear usuarios A y B mediante el mecanismo seguro de Auth del entorno; no insertar credenciales en SQL compartido. Con dos clientes PostgREST que usen sus JWT:

1. A sólo debe poder leer sus filas de progreso, eventos, wallet, inventario, logros y reportes.
2. B no debe poder leer filas de A aunque conozca el UUID.
3. Cada RPC debe ignorar o rechazar cualquier `user_id` distinto del `auth.uid()`; preferir una fixture desechable y un rollback si se prueban mutaciones.
4. Repetir exactamente el mismo `request_id` debe devolver el resultado idempotente y no aumentar el saldo dos veces.
5. Enviar dos requests concurrentes para la misma recompensa y para dos recompensas distintas del mismo usuario; verificar que el ledger y el saldo final sean correctos.
6. Ejecutar la misma secuencia con un usuario free y uno premium para cada RPC de recurso premium.
7. Repetir tras expirar/revocar la sesión y tras cambiar de usuario en el mismo dispositivo para descartar mezcla de scopes locales.

Estas son comprobaciones de staging, no se han ejecutado en esta sesión.

## 9. Primer lote de implementación recomendado

Un único lote pequeño y reversible:

**Lote 1 — cerrar y probar sólo las escrituras directas de eventos de economía.**

- No tocar todavía catálogo, Premium, webhooks ni toda la economía.
- Añadir una prueba de contrato que marque `xp_events` y `currency_events` como no escribibles directamente por el cliente, si esa es la autoridad acordada.
- En staging, confirmar el grant efectivo y el resultado A/B.
- Mantener temporalmente una ruta de compatibilidad detrás de una feature flag o migración reversible sólo si la aplicación aún la necesita para datos legacy.
- Probar: usuario A/B, replay de request, concurrencia y reconciliación con `user_progress`.

El criterio de salida es que una acción de recompensa tenga una sola autoridad, que un replay no cambie el balance y que una escritura directa del cliente no pueda crear moneda/XP. Después de ese lote se puede decidir, con evidencia, si `user_progress` debe ser una proyección sincronizada o una tabla protegida por RPC.
