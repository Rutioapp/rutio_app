# Weekly Report — Phase 4 generator audit

Estado: **NOT_READY**.

Este documento registra el preflight y el data sufficiency gate de Phase 4. No se implementa un generador autoritativo mientras las fuentes server-side no permitan distinguir una ocurrencia incompleta de una omitida y conservar actividad de un hábito borrado.

## 1. Generator execution architecture

La arquitectura recomendada, una vez cerrado el prerequisite, es Postgres/RPC:

- helpers SQL pequeños para resolver semana, timezone, configuración efectiva y métricas;
- una función interna transaccional para refresh de snapshot;
- una RPC de refresh autenticado que derive `user_id` de `auth.uid()`;
- una RPC interna/service-role para jobs futuros;
- una operación separada de finalización que refresque children, refresque parent y establezca `final` al final.

No se crea todavía ninguna RPC, Edge Function ni migración Phase 4. Esta opción mantiene ownership e idempotencia dentro de la base y evita duplicar en backend las reglas Dart como una segunda implementación incomprobable.

## 2. Server data sufficiency audit

### Fuentes revisadas

- `public.habits`: `id`, `user_id`, `created_at`, `updated_at`, tipo, target, schedule e `is_archived`.
- `public.habit_logs`: una fila diaria por hábito con `log_date`, `value`, `is_completed`, timestamps y source.
- `weekly_report_habit_config_versions`: historial scoped desde activation, con `effective_from`, timestamps de fuente/observación y orden determinista.
- `habit_streak_shields` y `habit_streak_breaks`: continuidad, no completion.
- `profiles.habit_time_zone`: timezone IANA de lógica de hábitos.
- sincronización Flutter en `habit_log_sync_service.dart` y `user_state_store_habits.dart`.

### Resultado por dato requerido

| Dato | Disponible server-side | Resultado |
| --- | --- | --- |
| identidad/tipo/target/schedule actual | sí | suficiente solo para estado actual |
| creación y archive | parcial | creation está; archive histórico depende del config history |
| configuración efectiva por instante | sí desde activation | usable para filas registradas con effective time fiable |
| check completion | sí, mediante `is_completed` | usable salvo necesidad de distinguir skip |
| count progress | sí, `value` | usable; target debe venir del config history |
| completion timestamp | parcialmente, `completed_at` existe en el contrato SQL | no sustituye un evento efectivo ni resuelve skip |
| skip histórico | no | **bloqueante** |
| actividad después de hard delete | no fiable | **bloqueante**: `habit_logs.habit_id` usa `ON DELETE CASCADE` |
| pending client sync | no | limitación explícita para finalización |
| streak canónico | parcial | nullable/diferido; no bloquea por sí solo |
| IANA timezone | sí en profile/activation/config | suficiente para el contrato de fecha |

## 3. Sources of truth

La fuente de verdad prevista es `habit_logs` para actividad diaria, config history para el estado efectivo y activation para el límite histórico. El hábito live no puede proyectarse hacia atrás cuando existe historial.

Hoy esa combinación no es suficiente: el sync local describe skip como `is_completed=false` y no envía un campo `skipped`. Por tanto, el backend no puede cumplir D01 sin convertir un estado ambiguo en una suposición.

## 4. Effective config resolution

El contrato de Phase 3 es correcto y debe conservarse:

`effective_from <= target_instant`, orden descendente por `effective_from, source_updated_at, created_at, source_mutation_id, id`, con los `NULLS LAST` definidos por el contrato.

`effective_local_date` sirve para representar la fecha, pero no debe ser la única clave de búsqueda. Las filas basadas solo en `observed_at` deben marcarse como fallback no preciso para mutaciones offline.

## 5. Activation semantics

La primera semana conserva Monday–Sunday. Solo es elegible el intervalo desde `activation_local_date`; no se generan semanas anteriores. Para una activation en jueves, `eligibleDays = 4` y `is_first_partial_week = true`.

La lógica está soportada por la foundation, pero no se puede generar un snapshot autoritativo completo hasta cerrar los gaps de actividad.

## 6. Schedule algorithms

El contrato esperado es:

- `daily`: una ocurrencia por día elegible;
- `weekly`: solo weekdays configurados;
- `once`: solo la fecha configurada;
- `timesPerWeek`: cuota semanal, sin ocurrencias scheduled artificiales por día.

La implementación Dart de referencia está en `lib/features/habits/domain/metrics`. No se replica aún en SQL porque hacerlo sobre entradas incompletas produciría snapshots engañosos.

## 7. timesPerWeek semantics

La política cerrada es `proratedCeil`: `ceil(configuredTimesPerWeek * eligibleDays / 7)`, acotada a la cuota configurada, con cero si no hay días elegibles. La actividad diaria puede conservarse en occurrences/actividad raw, pero el denominator global es la cuota y no la suma de cuotas diarias.

## 8. Check/count semantics

CHECK: `completed = true` solo si hay completion verdadera y `skipped = false`.

COUNT: `completed = progress >= effectiveTarget`; un progress menor es partial y no completa. Si el target cambia durante la semana, cada fecha usa su versión efectiva.

El segundo contrato no puede observarse de forma completa para skip porque la fuente remota solo expone el estado colapsado.

## 9. Daily/global reconciliation

Se generarían siete filas Monday–Sunday. `completion_rate` sería `NULL` cuando `scheduled_count = 0`. Para `timesPerWeek`, los días no recibirían una cuota scheduled ficticia; el global usaría la cuota semanal y no tendría por qué ser la suma de los denominadores diarios.

## 10. Snapshot habit config strategy

La representación mínima correcta sería `config_at_week_end` más occurrences con `target` y schedule efectivos por fecha, y metadata de las versiones utilizadas. No se guardaría únicamente la configuración live actual.

## 11. Current-day sync limitation

El refresh provisional debe asumir solo datos persistidos server-side. Abrir la pantalla no sincroniza mágicamente. El cliente debería ejecutar `sync success -> refresh provisional`; si quedan mutaciones pendientes, el resultado solo puede ser provisional y debe reflejar `refreshed_at`.

Actualmente no hay una señal server-side completa de pending client sync, por lo que no puede garantizarse un cierre final consciente de todas las mutaciones pendientes.

## 12. Provisional refresh

El futuro refresh será idempotente por `(user_id, week_start_date)`, preservará ownership/versiones y reemplazará children dentro de la misma transacción. Un report `final` no se tocará.

## 13. Finalization

La finalización futura validará activation, timezone y cierre de semana; hará refresh final de days y habits, luego parent, y pondrá `status = 'final'` como última operación. Los triggers de Phase 3 preservarán inmutabilidad.

## 14. Timezone/DST

Las fronteras serán DATE Monday–Sunday en la timezone IANA snapshot del report, no 168 horas UTC. La foundation valida nombres IANA. Falta implementar y probar la construcción de instantes DST en el generador.

## 15. Best day

Regla propuesta: mayor `completed/scheduled`, después mayor completed count y, finalmente, fecha cronológicamente más temprana. Los días sin schedule no compiten.

## 16. Trend

V1 comparará solo con el previous final report cuando exista y sea comparable. Primera semana parcial, previous ausente o denominator cero producen `unavailable`. Cuando sea comparable, `delta = current - previous`; la primera clasificación puede usar comparación exacta (`improved`, `stable`, `declined`).

## 17. Security

Las futuras RPCs derivarán el usuario desde `auth.uid()` en callers autenticados, separarán service-role/internal helpers, fijarán `search_path`, usarán referencias schema-qualified y tendrán grants explícitos. No se concederá acceso directo a tablas snapshot.

## 18. Idempotency

La base ya ofrece unique `(user_id, week_start_date)` y unique mutation id para config history. La generación debe ser una transacción; la finalización debe ser una transición única protegida por el estado final.

## 19. Domain parity matrix

| Fixture Phase 2 | Dart | Backend Phase 4 |
| --- | --- | --- |
| check daily 0/7, 3/7, 7/7 | cubierto por domain tests | no implementado |
| count partial/exact/over | cubierto | no implementado |
| weekly/once | cubierto | no implementado |
| timesPerWeek full/partial matrix | cubierto | no implementado |
| zero scheduled | cubierto, rate `NULL` | no implementado |
| first partial week | cubierto por quota/week contract | no implementado |
| Monday–Sunday | cubierto | no implementado |

No se declara parity hasta que exista backend ejecutable y fixtures comunes.

## 20. Deferred Phase 5+

No se implementaron UI, repository/cache Flutter, Premium, Diary, notifications, recommendations ni message copy. Recommendations quedan para Phase 8 y copy para Phase 10 según el contrato recibido.

## 21. Known risks and prerequisite

`NOT_READY` requiere una subfase prerequisite de sync/historial:

1. Persistir `skipped` explícitamente en el modelo remoto y en el camino de sync.
2. Conservar logs/configuración de un hábito borrado, mediante tombstone o una relación histórica que no cascade; no basta con el trigger de config porque la actividad se pierde.
3. Transportar mutation/effective timestamp fiable para cambios offline, o marcar esos intervalos como no autoritativos.
4. Añadir una señal de sync pendiente si se quiere una garantía fuerte al finalizar.

Esto no es un cambio pequeño aislado de Phase 4: afecta el contrato de sync y la retención histórica. No se crea una migración parcial ni se modifica la migración Phase 3 aplicada.

## Validation record

- `supabase migration list --linked`: OK; local y remoto coinciden hasta `20260901090000`.
- `git diff --check`: se ejecutará tras este documento.
- `supabase db dump --linked`: no se pudo usar porque el CLI intenta usar Docker y el prompt prohíbe Docker; no se usó ningún contenedor.
- No se aplicaron migraciones ni se desplegaron Edge Functions.

