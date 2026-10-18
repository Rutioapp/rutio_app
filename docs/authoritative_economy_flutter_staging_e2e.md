# Rutio — Flutter E2E de economía autoritativa en Staging

## Destino y preflight

Usar exclusivamente el proyecto `fuibgptjhsjvenjdxtqt`. Confirmar visualmente el proyecto en el Dashboard antes de abrir el SQL Editor. No usar `dart_defines/dev.local.json`: apunta a Producción y contiene configuración local sensible.

Preparar un archivo local ignorado a partir de `dart_defines/staging.example.json`, rellenando únicamente la anon/publishable key de Staging:

```powershell
flutter devices
flutter run -d <pixel-id> --dart-define-from-file=dart_defines/staging.local.json
```

La app sólo debe recibir `SUPABASE_URL` y `SUPABASE_ANON_KEY` mediante `dart-define`. Nunca usar `service_role`, JWT copiado de otra cuenta ni credenciales de Producción.

## Secuencia en Pixel

1. Crear o seleccionar una cuenta de pruebas exclusiva de Staging y dos hábitos: CHECK y COUNT.
2. Con conexión: completar CHECK, comprobar el cambio visual y esperar la frase de día completado.
3. Deshacer CHECK y volver a completarlo.
4. Incrementar COUNT por debajo del objetivo; confirmar que no aparece recompensa económica. Alcanzar el objetivo y confirmar una única recompensa.
5. Deshacer COUNT y repetir la sincronización.
6. Desactivar la red, registrar una finalización y cerrar/reabrir la app.
7. Restaurar la red, dejar que la cola se resuelva y repetir la apertura para comprobar que no duplica.
8. No usar la cuenta aislada de nivel 5 para pruebas de hábitos; reservarla para claims.

## Consultas SQL de sólo lectura

Ejecutar en el SQL Editor de Staging, sustituyendo sólo el UUID de la cuenta de pruebas:

```sql
select user_id, level, total_xp, current_level_xp, next_level_xp, ambar_balance
from public.user_progress
where user_id = '<TEST_USER_UUID>';

select user_id, coins, version, updated_at
from public.user_wallets
where user_id = '<TEST_USER_UUID>';

select request_id, habit_id, logical_date, transition_no, is_completed,
       value, completion_event_id
from public.economy_habit_transition_ledger
where user_id = '<TEST_USER_UUID>'
order by created_at desc
limit 20;

select request_id, source_type, source_id, operation_type, xp_delta,
       created_at
from public.economy_xp_ledger
where user_id = '<TEST_USER_UUID>'
order by created_at desc
limit 20;

select request_id, source_type, source_id, operation_type, coin_delta,
       balance_after, is_idempotent, created_at
from public.achievement_level_reward_ledger
where user_id = '<TEST_USER_UUID>'
order by created_at desc
limit 20;
```

## Concurrencia de claim

Preparar dos clientes autenticados con la misma cuenta aislada y dos request IDs distintos. No ejecutar la prueba hasta autorizar explícitamente la escritura en Staging. El resultado esperado es un solo ledger positivo para el nivel, una sola modificación económica efectiva, una versión de wallet coherente y una proyección sincronizada.

## Bloqueos actuales

- El entorno de esta sesión no tiene `adb` disponible, por lo que no se puede ejecutar la prueba en Pixel.
- No se ejecutaron escrituras remotas ni claims contra Staging.
- La configuración Staging local requiere una anon/publishable key proporcionada fuera del repositorio.
