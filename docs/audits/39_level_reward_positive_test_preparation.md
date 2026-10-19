# Preparación de prueba positiva — recompensa de nivel 5

## Umbral exacto

La fórmula instalada es `80 + 35 × (L - 1) + round(18 × (L - 1)^1.65)`.

| Nivel | XP siguiente | XP acumulada |
|---:|---:|---:|
| 1 | 80 | 0 |
| 2 | 133 | 80 |
| 3 | 207 | 213 |
| 4 | 295 | 420 |
| 5 | 389 | 715 |

Con 20 XP actuales, faltan `715 - 20 = 695 XP`.

## Operaciones legítimas estimadas

Según `habit_completion_base_reward`:

- `check`: 10 XP por completado; mínimo teórico `ceil(695 / 10) = 70` operaciones.
- `count`: entre 5 y 15 XP; con el máximo de 15 XP, mínimo teórico `ceil(695 / 15) = 47` operaciones.

El número real depende de hábitos activos, calendario, fechas ya completadas y estado canónico de cada fecha. [level_reward_positive_preflight.sql](D:/dev/alpha/rutio_app-security-economy/supabase/tests/level_reward_positive_preflight.sql) calcula esa capacidad sin modificar datos.

## Limitaciones y alternativa recomendada

La ventana por defecto permite 31 días hacia atrás y el día actual, nunca fechas futuras. La fecha no puede ser anterior a `habits.created_at`, el hábito debe estar programado y un estado ya completado no aporta otro completado legítimo para la misma fecha. En hábitos `count`, el valor debe ser válido y alcanzar el target para obtener el máximo XP.

La alternativa menos invasiva es reutilizar hábitos activos existentes y completar ocurrencias realmente programadas dentro de la ventana. Si la capacidad es menor que 695 XP, la prueba positiva queda bloqueada. No se deben insertar XP, modificar progreso, alterar wallets ni escribir ledgers directamente. Crear hábitos nuevos mediante el flujo normal solo sería una alternativa posterior y autorizada.

## Preflight y comandos preparados

Primero confirmar manualmente en Staging la definición instalada, el umbral 715, la capacidad disponible y que el nivel 5 aún no está reclamado:

```powershell
psql "$env:RUTIO_STAGING_ADMIN_DATABASE_URL" --set=ON_ERROR_STOP=1 --file .\supabase\tests\level_reward_positive_preflight.sql
```

Después de completar legítimamente la XP necesaria y confirmar nivel 5:

```powershell
$levelRequestId = [guid]::NewGuid().ToString()
powershell -NoProfile -File .\supabase\tests\run_rewards_validation_phase_a.ps1 `
  -Action level-valid -ValidLevel 5 -RequestId $levelRequestId -ConfirmStagingExecution

psql "$env:RUTIO_STAGING_ADMIN_DATABASE_URL" --set=ON_ERROR_STOP=1 --file .\supabase\tests\level_reward_projection_sync_verification.sql

powershell -NoProfile -File .\supabase\tests\run_rewards_validation_phase_a.ps1 `
  -Action level-repeat-request -ValidLevel 5 -RequestId $levelRequestId -ConfirmStagingExecution

powershell -NoProfile -File .\supabase\tests\run_rewards_validation_phase_a.ps1 `
  -Action level-repeat-source -ValidLevel 5 -ConfirmStagingExecution

powershell -NoProfile -File .\supabase\tests\run_rewards_validation_phase_a.ps1 `
  -Action level-concurrent -ValidLevel 5 -ConfirmStagingExecution
```

La concurrencia debe ejecutarse solo cuando el nivel 5 todavía no se haya reclamado. Debe observarse una sola recompensa económica; las repeticiones no deben aumentar wallet, versión ni filas del ledger.

## Estado

Preparación local completada. No se ejecutaron consultas remotas, completados de hábitos ni reclamaciones. No se desplegaron migraciones adicionales.
