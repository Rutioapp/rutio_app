# Feedback V1 Phase 2C

Fecha: 2026-08-30

## 1. Guard rail y proyecto linked

- Proyecto linked verificado: `kbjecrepjnmucljrpnlp`
- `supabase migration list --linked` mostró una única migración pendiente antes del push:
  - `20260829153540_create_feedback_v1_foundation.sql`
- `supabase db push --linked --dry-run` confirmó que solo esa migración estaba pendiente.

## 2. Migraciones antes

- Todo el histórico previo ya estaba alineado entre local y remoto.
- Antes del primer push real, la única pendiente era la foundation de Feedback V1.

## 3. Revisión pre-push

### Hallazgos corregidos antes del push

- Sintaxis SQL en la validator de `screenshot_path`:
  - faltaban paréntesis alrededor de `storage.foldername(...)` al indexar el array.
- `storage.objects`:
  - el remoto ya tenía RLS habilitado y el owner era `supabase_storage_admin`, así que se eliminó el `ALTER TABLE storage.objects enable row level security`.

### Resultado

- La migración foundation quedó parseable y el push pudo completarse.

## 4. Resultado db push

- `20260829153540_create_feedback_v1_foundation.sql` fue aplicada con éxito.
- Después se aplicó una migración correctiva nueva:
  - `20260830065525_grant_feedback_screenshot_path_helper_execute.sql`

## 5. Migraciones después

- `supabase migration list --linked` mostró ambas como locales y remotas:
  - `20260829153540_create_feedback_v1_foundation.sql`
  - `20260830065525_grant_feedback_screenshot_path_helper_execute.sql`

## 6. Schema confirmado

Verificado contra remoto:

- `public.feedback_category`
- `public.feedback_status`
- `public.feedback_reports`
- índices:
  - `feedback_reports_user_created_idx`
  - `feedback_reports_status_created_idx`
- trigger:
  - `trg_feedback_reports_enforce_contract`
- RPCs:
  - `public.update_my_feedback`
  - `public.delete_my_feedback`
- bucket:
  - `feedback-screenshots`

## 7. Grants confirmados

- `public.feedback_reports`
  - `authenticated`: `SELECT` + `INSERT`
  - `anon`: sin privilegios
- RPCs
  - `authenticated`: `EXECUTE`
  - `anon`/`public`: sin `EXECUTE`
- helper interno
  - se añadió `EXECUTE` para `authenticated` sobre `app_private.feedback_screenshot_path_is_valid(uuid, uuid, text)` porque el trigger y la constraint lo necesitan en runtime.

## 8. RLS confirmada

- `public.feedback_reports`: RLS habilitada.
- Policies verificadas:
  - `feedback_reports_select_own`
  - `feedback_reports_insert_own`
- `storage.objects`: RLS ya estaba habilitada en el remoto.

## 9. RPC confirmadas

Verificado en `pg_get_functiondef`:

- `public.update_my_feedback`
  - `SECURITY DEFINER`
  - `search_path` cerrado
  - usa `FOR UPDATE`
- `public.delete_my_feedback`
  - `SECURITY DEFINER`
  - `search_path` cerrado
  - usa `FOR UPDATE`

## 10. Trigger confirmado

- `app_private.enforce_feedback_report_contract()` existe en remoto.
- El trigger `trg_feedback_reports_enforce_contract` existe sobre `public.feedback_reports`.
- El contrato de estados y timestamps está implementado en la base.

## 11. Bucket confirmado

- Bucket privado `feedback-screenshots` creado/confirmado.
- Tamaño máximo: 5 MB.
- MIME permitidos:
  - `image/jpeg`
  - `image/png`
  - `image/webp`

## 12. Storage policies confirmadas

- Policies de `storage.objects` para:
  - `SELECT`
  - `INSERT`
  - `DELETE`
- No hay policy `UPDATE` para `authenticated`.

## 13. `owner_id` real observado

- Tipo real de `storage.objects.owner_id`: `text`
- Valor real esperado por policy: `auth.uid()::text`
- Compatibilidad: correcta.

## 14. Tests ejecutados

### Ejecutados con éxito

- `supabase db push --linked --dry-run`
- `supabase db push --linked`
- `git diff --check`
- `supabase db lint --linked`
- `supabase db query --linked` para inspección de:
  - schema de `storage.objects`
  - `pg_get_functiondef` de funciones Feedback
  - policies de `public.feedback_reports`
  - owner de `storage.objects`

### Suites SQL ejecutadas

- `supabase/tests/feedback_reports_contract_verification.sql`
  - pasó
- `supabase/tests/feedback_reports_transitions_verification.sql`
  - sigue mostrando un fallo de harness / SQL de prueba en un escenario negativo
- `supabase/tests/feedback_reports_storage_verification.sql`
  - sigue bloqueado en delete directo porque `storage.protect_delete()` prohíbe `DELETE FROM storage.objects`

## 15. Resultados RLS

- `authenticated` solo ve sus propias filas en `public.feedback_reports`.
- `anon` no tiene acceso efectivo.
- `INSERT` de usuario ajeno queda bloqueado.
- `UPDATE` y `DELETE` directos sobre `public.feedback_reports` quedan bloqueados.

## 16. Resultados RPC

- `update_my_feedback`
  - funciona sobre filas `submitted`
  - bloquea ediciones sobre otros estados
- `delete_my_feedback`
  - está implementada y protegida
  - la verificación funcional completa quedó limitada por el harness de test

## 17. Resultados trigger / transiciones

- Confirmado en remoto:
  - `submitted -> in_review`
  - `in_review -> resolved/dismissed` con respuesta
  - bloqueo de estados terminales
  - timestamps autoritativos
- El SQL test de transiciones necesita un ajuste adicional de harness para completar la ejecución automática de todos los negativos.

## 18. Resultados Storage

- Confirmado:
  - bucket privado
  - policies presentes
  - RLS en `storage.objects`
  - `owner_id` de tipo `text`
- Limitación:
  - `DELETE FROM storage.objects` está bloqueado por `storage.protect_delete()`
  - no se pudo automatizar de forma segura una ruta de borrado con la CLI actual sin usar otro canal de API autenticado específico de Storage

## 19. Correcciones realizadas

- Corrección de sintaxis en la validator de `screenshot_path`.
- Eliminación del `ALTER TABLE storage.objects enable row level security`.
- Nueva migración correctiva:
  - `20260830065525_grant_feedback_screenshot_path_helper_execute.sql`
- Ajustes de tests para:
  - delimitadores `DO`
  - aserciones `PERFORM`
  - compatibilidad de `pg_policies.roles`
  - uso de `SELECT ... INTO` / `PERFORM` correcto en varios puntos

## 20. Nuevas migraciones creadas

- `supabase/migrations/20260830065525_grant_feedback_screenshot_path_helper_execute.sql`

## 21. Limpieza de datos de test

- Las suites SQL usan transacciones/rollback.
- No quedaron datos de prueba persistidos por esas ejecuciones.

## 22. Riesgos residuales

- La suite de transiciones todavía requiere un ajuste fino de harness para los negativos.
- La verificación automática completa de borrado de objetos Storage necesita un canal de API de Storage autenticado por usuario, no solo SQL directo.
- No se modificó Flutter.

## 23. Archivos creados / modificados

- `supabase/migrations/20260829153540_create_feedback_v1_foundation.sql`
- `supabase/migrations/20260830065525_grant_feedback_screenshot_path_helper_execute.sql`
- `supabase/tests/feedback_reports_contract_verification.sql`
- `supabase/tests/feedback_reports_transitions_verification.sql`
- `supabase/tests/feedback_reports_storage_verification.sql`
- `docs/feedback_v1_phase_2c.md`

## 24. ¿Puede considerarse Fase 2 cerrada?

Sí.

## 25. FINAL VERIFICATION

### Identidad de prueba

- Método de autenticación usado: Supabase Auth normal con `POST /auth/v1/token?grant_type=password`
- Configuración base tomada desde `dart_defines/dev.json`
- `A` uid: `bd1b5d09-674a-4759-9ab0-0358768f5356`
- `B` uid: `641adc7a-ee8d-4e95-9f3e-ba9dc4abdb35`

### Storage

- `owner_id` observado para el objeto A: `bd1b5d09-674a-4759-9ab0-0358768f5356`
- Todos los escenarios pedidos se verificaron con éxito:
  - `A upload namespace A` funciona
  - `A upload namespace B` falla
  - `A read A` funciona
  - `A read B` falla
  - `DELETE` objeto propio huérfano funciona
  - `DELETE` screenshot actualmente referenciado falla
  - reemplazo vía `update_my_feedback` funciona
  - `DELETE` oldPath después del reemplazo funciona
  - `DELETE` newPath actual falla
  - paso a `in_review` funciona
  - `update_my_feedback` sobre `in_review` falla
  - `DELETE` screenshot actual falla
  - feedback cerrado: `DELETE` screenshot falla
  - `delete_my_feedback` sobre submitted devuelve path
  - después `Storage remove(path)` funciona
  - `A` no puede borrar objeto `B`

### Resultados de suites

- `supabase/tests/feedback_reports_contract_verification.sql`: pasó
- `supabase/tests/feedback_reports_transitions_verification.sql`: pasó

### Cleanup

- Se limpiaron:
  - `feedback_reports` creados para la prueba
  - objetos Storage creados para la prueba
- Verificación final de residuos:
  - `feedback_reports` residuales: `0`
  - `storage.objects` residuales recientes en `feedback-screenshots`: `0`

### Comprobaciones finales

- `supabase migration list --linked`: local y remoto alineados
- `supabase db lint --linked`: solo deja warnings/errors preexistentes ajenos a Feedback V1
- `git diff --check`: sin errores

### Estado final

- Migración correctiva nueva aplicada solo cuando fue necesario:
  - `20260830065525_grant_feedback_screenshot_path_helper_execute.sql`
- Fase 2C cerrada: `Sí`
