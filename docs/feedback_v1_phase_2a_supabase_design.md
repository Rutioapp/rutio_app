# Feedback V1 Phase 2A - Supabase Design

Fecha: 2026-08-29

Alcance: esta fase es solo de analisis y diseno. No crea migraciones, no toca Storage, no conecta Flutter y no ejecuta nada contra remoto.

## 1. Estado actual de Supabase relevante

Lo que ya existe en Rutio y sirve de referencia real:

- Rutio ya usa el esquema privado `app_private` para helpers internos y lo protege con `REVOKE ALL`.
- Las funciones criticas se definen con `SECURITY DEFINER` y `SET search_path = ''`.
- El patron de timestamps centralizados existe con `app_private.set_updated_at()`.
- Las tablas de dominio ya siguen un patron de RLS minimo: `SELECT` por `auth.uid()`, sin writes directos cuando la feature necesita RPC.
- Las RPC criticas ya usan errores simples con `raise exception` y privilegios cerrados mediante `REVOKE` / `GRANT EXECUTE`.
- Para transiciones de estado, Rutio ya tiene un antecedente muy cercano en `app_private.enforce_profile_onboarding_transition()`:
  - trigger `BEFORE UPDATE`,
  - transiciones acotadas,
  - timestamps decididos por PostgreSQL,
  - rechazo de regresiones.

Lo que no existe todavia en el arbol actual:

- No encontre migraciones de Storage.
- No encontre policies de `storage.objects`.
- No encontre buckets para feedback.
- No existe todavia la tabla `public.feedback_reports`.
- No existen RPCs de feedback.
- No existen tests SQL de feedback.

Archivos inspeccionados para llegar a este estado:

- [docs/feedback_v1_phase_0_audit.md](D:/dev/alpha/rutio_app/docs/feedback_v1_phase_0_audit.md)
- [docs/feedback_v1_phase_1a.md](D:/dev/alpha/rutio_app/docs/feedback_v1_phase_1a.md)
- [docs/feedback_v1_phase_1b.md](D:/dev/alpha/rutio_app/docs/feedback_v1_phase_1b.md)
- [docs/feedback_v1_phase_1c.md](D:/dev/alpha/rutio_app/docs/feedback_v1_phase_1c.md)
- [supabase/migrations/20260717130000_create_shop_foundation.sql](D:/dev/alpha/rutio_app/supabase/migrations/20260717130000_create_shop_foundation.sql)
- [supabase/migrations/20260718100000_create_shop_transactional_operations.sql](D:/dev/alpha/rutio_app/supabase/migrations/20260718100000_create_shop_transactional_operations.sql)
- [supabase/migrations/20260727183000_bootstrap_user_wallets_for_existing_and_new_auth_users.sql](D:/dev/alpha/rutio_app/supabase/migrations/20260727183000_bootstrap_user_wallets_for_existing_and_new_auth_users.sql)
- [supabase/migrations/20260727213017_enforce_remote_onboarding_transitions.sql](D:/dev/alpha/rutio_app/supabase/migrations/20260727213017_enforce_remote_onboarding_transitions.sql)
- [supabase/migrations/20260728110000_create_authoritative_bootstrap_decision_contract.sql](D:/dev/alpha/rutio_app/supabase/migrations/20260728110000_create_authoritative_bootstrap_decision_contract.sql)
- [supabase/tests/bootstrap_user_wallets_verification.sql](D:/dev/alpha/rutio_app/supabase/tests/bootstrap_user_wallets_verification.sql)
- [supabase/tests/authoritative_bootstrap_decision_contract_static_verification.sql](D:/dev/alpha/rutio_app/supabase/tests/authoritative_bootstrap_decision_contract_static_verification.sql)
- [supabase/tests/shop_foundation_verification.sql](D:/dev/alpha/rutio_app/supabase/tests/shop_foundation_verification.sql)
- [lib/features/feedback/domain/feedback_category.dart](D:/dev/alpha/rutio_app/lib/features/feedback/domain/feedback_category.dart)
- [lib/features/feedback/domain/feedback_status.dart](D:/dev/alpha/rutio_app/lib/features/feedback/domain/feedback_status.dart)
- [lib/features/feedback/domain/feedback_report.dart](D:/dev/alpha/rutio_app/lib/features/feedback/domain/feedback_report.dart)

## 2. Patrones inspeccionados

Patrones que conviene reutilizar tal cual:

- `app_private.set_updated_at()` como trigger de `updated_at`.
- `SECURITY DEFINER` con `SET search_path = ''` en toda funcion sensible.
- `REVOKE ALL` sobre tablas y helpers internos.
- `GRANT EXECUTE` solo a `authenticated` cuando el cliente realmente debe poder invocar la RPC.
- RLS con `SELECT` explicito y sin superficie de escritura innecesaria.
- Trigger de estado como unica fuente de verdad para transiciones criticas.

Patrones que NO conviene repetir:

- Writes directos del cliente a tablas sensibles cuando el contrato pide RPC.
- Dependencia en la UI para bloquear transiciones invalidas.
- Reglas de seguridad solo en Storage sin una segunda capa backend cuando la destruccion del objeto tiene dependencia del estado del feedback.

## 3. Modelo SQL recomendado

### 3.1 Enum `feedback_category`

Valores:

- `bug`
- `suggestion`
- `improvement`
- `other`

Recomendacion:

- Mantener estos cuatro valores exactos.
- Usar el mismo literal en Postgres y en Dart para evitar mapeos ambiguos.
- No anadir alias ni valores legacy en V1.

### 3.2 Enum `feedback_status`

Valores:

- `submitted`
- `in_review`
- `resolved`
- `dismissed`

Recomendacion:

- Esta es la maquina de estados canonica.
- `submitted` es el unico estado de alta.
- `resolved` y `dismissed` son terminales.

### 3.3 Tabla `public.feedback_reports`

Blueprint recomendado:

- `id uuid` primary key
- `user_id uuid` not null references `auth.users(id)` on delete cascade
- `category feedback_category` not null
- `description text` not null
- `screenshot_path text` nullable
- `contact_allowed boolean` not null default false
- `status feedback_status` not null default `submitted`
- `team_response text` nullable
- `technical_context jsonb` not null default `'{}'`
- `review_started_at timestamptz` nullable
- `closed_at timestamptz` nullable
- `created_at timestamptz` not null default `now()`
- `updated_at timestamptz` not null default `now()`

Recomendacion:

- `id` debe generarse con `gen_random_uuid()`.
- `technical_context` debe ser extensible y no sensible.
- `team_response`, `review_started_at` y `closed_at` no deben poder setearse libremente desde el cliente.

## 4. Checks

### 4.1 `description`

Regla:

- `btrim(description)` entre 20 y 5000 caracteres.

Recomendacion:

- Hacer el check sobre `btrim(description)` para que el contrato coincida con lo que valida Flutter.
- No permitir descripcion vacia ni espacios de relleno.

### 4.2 `team_response`

Regla de cierre:

- Si `status` es `resolved` o `dismissed`, `team_response` debe existir y `btrim(team_response)` no puede ser vacio.

Recomendacion:

- Validar esto en trigger, no solo con check, porque depende de la transicion.
- El check estatico por si solo no captura el contexto temporal.

### 4.3 `technical_context`

Recomendacion para V1:

- No validar claves concretas en DB.
- Mantenerlo como JSONB extensible.
- Si se quiere un hardening minimo, permitir solo objetos JSON, no arrays ni escalares.

Motivo:

- Los campos previstos son de telemetria ligera y cambian con el tiempo.
- Validar schema detallado en SQL ahora solo creararia migraciones futuras innecesarias.

## 5. Diseño del trigger

### 5.1 Tipo de trigger

Recomendacion:

- `BEFORE INSERT OR UPDATE` sobre `public.feedback_reports`.
- Un solo helper centralizado, idealmente en `app_private`.

### 5.2 Comportamiento en `INSERT`

La base de datos debe imponer:

- `status = submitted` siempre.
- `team_response = NULL`.
- `review_started_at = NULL`.
- `closed_at = NULL`.

Tambien:

- `user_id` debe venir de `auth.uid()` o validarse contra el caller en la RPC de insercion.
- `updated_at` debe quedar alineado con `created_at`.

### 5.3 Comportamiento en `UPDATE` sin cambio de estado

### Si la fila sigue en `submitted`

Permitir solo:

- cambios via RPC del usuario en `description`,
- `screenshot_path`,
- `contact_allowed`.

Rechazar:

- `user_id`,
- `status`,
- `team_response`,
- `review_started_at`,
- `closed_at`,
- `created_at`.

### Si la fila sigue en `in_review`

Permitir:

- cambios de `team_response` por administracion,
- potencialmente solo eso.

Rechazar:

- descripcion,
- screenshot_path,
- contact_allowed,
- `review_started_at`,
- `closed_at`,
- `user_id`,
- `created_at`.

### Si la fila es terminal

Recomendacion:

- Fila completamente inmutable.

Motivo:

- Preserva auditoria.
- Evita que una correccion manual o un update accidental cambie el historial cerrado.

### 5.4 Transicion `submitted -> in_review`

Permitir solo esta transicion.

Acciones automaticas:

- setear `review_started_at` si aun es null.
- no tocar `closed_at`.

Recomendacion:

- usar `statement_timestamp()` o `now()` de forma consistente con el resto del backend.
- impedir que un cambio manual sobrescriba `review_started_at` si ya existe.

### 5.5 Transicion `in_review -> resolved`

Permitir solo si:

- `team_response` es real, y
- `btrim(team_response)` no esta vacio.

Acciones automaticas:

- setear `closed_at` si aun es null.
- dejar `review_started_at` intacto.

### 5.6 Transicion `in_review -> dismissed`

Mismas reglas que `resolved`.

### 5.7 Transiciones prohibidas

Prohibir:

- `submitted -> resolved`
- `submitted -> dismissed`
- `in_review -> submitted`
- `resolved -> cualquier estado`
- `dismissed -> cualquier estado`
- cualquier reapertura de terminales

### 5.8 Tabla de transiciones

| Estado origen | Estado destino | Permitido | Efecto |
| --- | --- | --- | --- |
| INSERT | `submitted` | si | normaliza timestamps y campos administrativos a null |
| `submitted` | `submitted` | si, solo para ediciones del usuario via RPC | solo cambia campos permitidos |
| `submitted` | `in_review` | si | set `review_started_at` |
| `submitted` | `resolved` | no | error |
| `submitted` | `dismissed` | no | error |
| `in_review` | `in_review` | si, solo admin | permite `team_response` |
| `in_review` | `resolved` | si | exige `team_response`, set `closed_at` |
| `in_review` | `dismissed` | si | exige `team_response`, set `closed_at` |
| `resolved` | cualquier estado | no | error |
| `dismissed` | cualquier estado | no | error |

## 6. Diseno RLS

### 6.1 Superficie minima recomendada

Recomendacion:

- habilitar RLS en `public.feedback_reports`.
- crear solo `SELECT` e `INSERT` via policies.
- no crear `UPDATE` ni `DELETE` directos para `authenticated`.

### 6.2 `SELECT`

Policy:

- `authenticated` solo puede leer filas con `user_id = auth.uid()`.

### 6.3 `INSERT`

Policy:

- `authenticated` solo puede insertar su propia fila.

`WITH CHECK` debe impedir:

- `user_id` ajeno,
- `status` distinto de `submitted`,
- `team_response`,
- `review_started_at`,
- `closed_at`.

### 6.4 Sin `UPDATE` / `DELETE` directos

Recomendacion:

- No dar superficie de `UPDATE` ni `DELETE` al cliente.
- Toda edicion o borrado de usuario debe pasar por RPC.

### 6.5 Interaccion con Supabase Studio

Supabase Studio puede operar con privilegios altos, asi que:

- RLS no debe ser la unica defensa.
- El trigger de transiciones es el guardarrail real.
- Si Studio usa un contexto que bypassa RLS, el trigger sigue aplicando.

## 7. Grants y revoke

Recomendacion de permisos:

- `revoke all on public.feedback_reports from public, anon, authenticated;`
- `grant select, insert on public.feedback_reports to authenticated;`
- no conceder `update` ni `delete` a `authenticated`.

Para RPCs:

- `revoke all on function public.update_my_feedback(...) from public, anon;`
- `revoke all on function public.delete_my_feedback(...) from public, anon;`
- `grant execute on function public.update_my_feedback(...) to authenticated;`
- `grant execute on function public.delete_my_feedback(...) to authenticated;`

Si se crea un helper interno de Storage:

- debe vivir en `app_private`.
- no debe concederse a `authenticated`.

## 8. Diseno de `update_my_feedback`

### 8.1 Objetivo

Entrada conceptual:

- `feedback_id`
- `description`
- `screenshot_path`
- `contact_allowed`

### 8.2 Reglas de seguridad

La funcion debe:

- comprobar `auth.uid()`,
- comprobar ownership,
- comprobar `status = submitted`,
- limitar los campos modificables,
- validar `description`,
- validar `screenshot_path`,
- evitar race conditions con cambios de estado concurrentes,
- devolver la fila actualizada.

### 8.3 Validacion de `description`

Debe repetir el contrato del frontend:

- trim,
- longitud 20..5000.

### 8.4 Validacion de `screenshot_path`

Debe aceptar solo paths con prefijo:

- `<auth.uid()>/<feedback_id>/`

Y ademas:

- no aceptar rutas de otro usuario,
- no aceptar rutas de otro feedback,
- no aceptar path traversal,
- no aceptar prefijos ambiguos.

Recomendacion de implementacion en PostgreSQL:

- normalizar con `btrim()`,
- rechazar vacio,
- rechazar `\`,
- rechazar `..`,
- exigir prefijo exacto de `auth.uid()` + `/` + `feedback_id` + `/`,
- validar extension permitida si se desea hardening adicional (`jpg`, `jpeg`, `png`, `webp`).

### 8.5 Proteccion contra race condition

La estrategia recomendada es:

- leer la fila con bloqueo `FOR UPDATE`,
- verificar que sigue en `submitted`,
- aplicar el `UPDATE` en la misma transaccion,
- devolver la fila final.

Esto evita que un admin cambie el estado entre la lectura y la edicion.

### 8.6 Errores

Coherencia con Rutio:

- usar `raise exception` con mensajes claros y estables,
- no introducir una codificacion de errores compleja en esta fase,
- dejar que Flutter mapee el mensaje a errores de dominio si hace falta.

## 9. Diseno de `delete_my_feedback`

### 9.1 Objetivo

Debe:

- comprobar `auth.uid()`,
- comprobar ownership,
- comprobar `status = submitted`,
- borrar la fila,
- devolver `screenshot_path` para limpieza posterior.

### 9.2 Error distinguible

Si ya esta en revision:

- debe fallar de forma distinta a "no existe".

Recomendacion:

- mensaje tipo `feedback can only be deleted while submitted`.

### 9.3 Recomendacion fuerte sobre el borrado de captura

La garantia real de backend no la da una policy de Storage sola.

Motivo:

- si la fila de feedback ya desaparecio, una policy que dependa de esa fila dificulta la limpieza posterior del objeto,
- pero si dejas DELETE libre en Storage, el usuario puede borrar objetos que ya estan ligados a un feedback en revision o cerrado.

Recomendacion:

- el borrado de la captura debe ejecutarlo un helper backend `SECURITY DEFINER`, no el cliente directamente.
- `delete_my_feedback` deberia devolver `screenshot_path` y, idealmente, disparar la limpieza backend dentro de la misma operacion o delegarla a un helper interno antes de eliminar la fila.

Esta es la opcion que deja la garantia realmente en backend.

## 10. Estrategia de `screenshot_path`

Contrato futuro:

- `<user_id>/<feedback_id>/screenshot_<uuid>.<extension>`

Recomendacion:

- almacenar siempre una ruta canonica sin slash inicial.
- no permitir rutas relativas raras ni path traversal.
- si se actualiza la captura, la nueva ruta debe pertenecer al mismo `auth.uid()` y al mismo `feedback_id`.
- el backend debe poder distinguir entre la ruta actual del feedback y un objeto huérfano para limpieza posterior.

## 11. Diseno del bucket privado

Bucket:

- `feedback-screenshots`

Propiedades:

- privado,
- nunca publico,
- destinado solo a imagenes de feedback.

Tipos permitidos:

- `image/jpeg`
- `image/png`
- `image/webp`

Tamano recomendado:

- 5 MB maximo por archivo.

Objetivo de cliente:

- menos de 1 MB despues de compresion.

Recomendacion:

- crear el bucket de forma idempotente en la migracion de feedback.
- no exponerlo como publico ni como bucket generico compartido.

## 12. Diseno de Storage policies

### 12.1 Principio general

La regla del bucket debe ser estricta:

- cada usuario solo trabaja dentro de su prefijo,
- no puede leer objetos de otros,
- no puede subir objetos dentro del prefijo de otros,
- no puede borrar libremente objetos vinculados a feedback activo o cerrado.

### 12.2 Policy de lectura

Recomendacion:

- permitir solo lectura de objetos cuyo nombre empiece por `<auth.uid()>/`.

### 12.3 Policy de insercion

Recomendacion:

- permitir solo insercion en `feedback-screenshots`,
- exigir `auth.uid()` como owner,
- exigir path con prefijo `<auth.uid()>/`.

### 12.4 Policy de actualizacion

Recomendacion:

- no conceder update directo del objeto al cliente.

### 12.5 Policy de delete

Recomendacion:

- no conceder delete directo al cliente.

Motivo:

- es la unica forma limpia de impedir borrado libre una vez el feedback entra en `in_review/resolved/dismissed`.
- la limpieza debe pasar por backend controlado.

## 13. Estrategia para impedir borrado de captura cuando entra en revision

La recomendacion real es una combinacion:

- no dar `DELETE` directo en `storage.objects`,
- usar una RPC o helper `SECURITY DEFINER` para la limpieza,
- hacer que ese helper verifique:
  - ownership,
  - prefijo del path,
  - y que el feedback siga en `submitted`.

Por que esta es la mejor garantia:

- una policy sola puede quedar corta cuando el feedback ya se borro,
- una RPC backend puede decidir con estado de negocio y borrar el objeto sin depender de permisos del cliente,
- evita que un usuario borre manualmente una captura asociada a un ticket ya revisado.

## 14. Diseno de tests SQL

### 14.1 Tests de contrato estatico

Deberian comprobar:

- existencia de la tabla,
- existencia de enums,
- existencia de constraints,
- RLS habilitado,
- policies esperadas,
- grants y revokes,
- triggers de timestamp y transicion,
- RPCs expuestas solo a `authenticated`,
- bucket privado y policies de Storage.

### 14.2 Tests funcionales de RLS

Deberian cubrir:

- `A != B` para `SELECT`,
- `anon` no lee ni inserta,
- `user_id` ajeno falla,
- `INSERT` con `status` distinto de `submitted` falla,
- `UPDATE` directo de usuario falla,
- `DELETE` directo de usuario falla.

### 14.3 Tests funcionales de RPC

Deberian cubrir:

- `update_my_feedback` funciona en `submitted`,
- `update_my_feedback` falla en `in_review`,
- `delete_my_feedback` funciona en `submitted`,
- `delete_my_feedback` falla en `in_review`,
- `submitted -> resolved` directo falla,
- `submitted -> dismissed` directo falla,
- cierre sin `team_response` falla,
- `in_review -> resolved` funciona con respuesta,
- `in_review -> dismissed` funciona con respuesta,
- `resolved` es terminal,
- `dismissed` es terminal,
- `review_started_at` se establece correctamente,
- `closed_at` se establece correctamente,
- `updated_at` cambia correctamente.

### 14.4 Tests de `screenshot_path`

Deberian cubrir:

- path de otro usuario falla,
- path de otro feedback falla.

### 14.5 Tests de Storage

Deberian cubrir:

- usuario A no puede acceder a objetos de B,
- usuario A no puede borrar libremente una captura ya ligada a feedback en review o cerrado.

### 14.6 Nombres recomendados para Fase 2B

- `supabase/tests/feedback_reports_contract_verification.sql`
- `supabase/tests/feedback_reports_transitions_verification.sql`
- `supabase/tests/feedback_reports_storage_verification.sql`

## 15. Riesgos y race conditions

### 15.1 Race de edicion

Riesgo:

- el usuario abre un feedback en `submitted`,
- un admin lo mueve a `in_review`,
- el usuario intenta guardar cambios sobre una copia vieja.

Mitigacion:

- bloqueo `FOR UPDATE` dentro de `update_my_feedback`,
- validacion de `status = submitted` al momento real de la escritura.

### 15.2 Cambio manual de timestamps

Riesgo:

- Studio o una herramienta privilegiada intenta fijar `review_started_at` o `closed_at` a mano.

Mitigacion:

- el trigger debe ser el unico que decide esos campos.

### 15.3 Borrado de captura tras cerrar feedback

Riesgo:

- si dependemos solo de Storage policies, puede ser dificil garantizar limpieza y al mismo tiempo impedir borrados libres.

Mitigacion:

- borrar la captura con backend controlado, no con delete libre del cliente.

### 15.4 JSONB demasiado libre

Riesgo:

- un payload malformado o sensible termina en `technical_context`.

Mitigacion:

- validar en app y, si se quiere, solo aceptar objetos JSON en DB.

## 16. Compatibilidad con administracion desde Supabase Studio

Objetivo:

- el equipo puede mover `submitted -> in_review -> resolved/dismissed` manualmente desde Studio.

Como se sostiene esto:

- RLS minima en la tabla,
- trigger que bloquea transiciones invalidas,
- trigger que exige `team_response` para el cierre,
- trigger que fija timestamps.

Lectura importante:

- Si Studio usa un contexto que bypassa RLS, el trigger sigue protegiendo el modelo.
- Si Studio usa una identidad que no bypassa RLS, entonces la politica de `SELECT/INSERT` sigue siendo minima y consistente.

## 17. Archivos que debera crear o modificar Fase 2B

### Migracion

- `supabase/migrations/<timestamp>_create_feedback_reports_foundation.sql`

### Tests

- `supabase/tests/feedback_reports_contract_verification.sql`
- `supabase/tests/feedback_reports_transitions_verification.sql`
- `supabase/tests/feedback_reports_storage_verification.sql`

### Posibles helpers internos

- `app_private.set_updated_at()` ya existe y deberia reutilizarse.
- Si se decide borrar capturas desde backend, puede hacer falta un nuevo helper interno en `app_private`.

## 18. Orden exacto recomendado dentro de la futura migracion

1. `create extension if not exists pgcrypto`
2. `create schema if not exists app_private` y `REVOKE` de schema si hace falta mantener el patron
3. crear o reutilizar `app_private.set_updated_at()`
4. crear enums `feedback_category` y `feedback_status`
5. crear tabla `public.feedback_reports`
6. crear checks de dominio
7. crear indices
8. crear trigger `BEFORE INSERT OR UPDATE`
9. habilitar RLS
10. crear policies de `SELECT` e `INSERT`
11. `REVOKE` / `GRANT` sobre tabla
12. crear RPC `update_my_feedback`
13. crear RPC `delete_my_feedback`
14. crear bucket privado de Storage
15. crear policies de Storage
16. crear tests SQL de verificacion

## 19. Decisiones que deben quedar cerradas antes de 2B

Hay algunos puntos que conviene fijar antes de escribir SQL:

- Si la fila terminal debe ser absolutamente inmutable. Mi recomendacion es que si.
- Si `team_response` puede editarse mientras el ticket sigue en `in_review`. Mi recomendacion es que si, pero solo antes del cierre.
- Si el borrado de captura se ejecuta dentro de `delete_my_feedback` o mediante un helper interno separado. Mi recomendacion es backend controlado, no delete libre del cliente.
- Si `technical_context` debe tener solo validacion de objeto JSON o tambien un esquema mas estricto. Mi recomendacion es solo objeto JSON en V1.
- Si el flujo de lectura de captura sera con signed URLs o via proxy backend. El bucket privado funciona con ambos, pero conviene cerrarlo antes de la implementacion.

## 20. Conclusiones operativas

La arquitectura recomendada para Rutio es:

- tabla nueva con enums strictos,
- transicion de estados gobernada por trigger,
- superficie de cliente minima: `SELECT`, `INSERT`, `update_my_feedback`, `delete_my_feedback`,
- cero `UPDATE` / `DELETE` directos para el cliente,
- bucket privado y borrado de capturas controlado por backend,
- tests SQL que verifiquen contrato, permisos, transiciones y Storage.

Eso deja el backend listo para una Fase 2B implementable sin reabrir decisiones de arquitectura basicas.
