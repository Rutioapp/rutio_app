# Fixture controlado para alcanzar nivel 5

## Diseño mínimo

El objetivo requiere 695 XP adicionales. La opción con menos hábitos es usar dos hábitos `COUNT` diarios con `target_count` suficientemente alto para producir 15 XP por completado. Dos hábitos × 24 fechas válidas producen 48 operaciones y 720 XP brutos; solo se necesitan 47 operaciones para superar el déficit.

Esto solo es válido si ambos hábitos ya existen desde al menos 24 días antes y sus fechas están programadas. Crear los hábitos hoy no permite rellenar fechas anteriores a `created_at`. Si el usuario A no dispone de dos hábitos COUNT con capacidad suficiente, el fixture queda bloqueado: no se crearán hábitos automáticamente y no se alterará la economía para forzarlo.

Alternativa con hábitos `check`: mínimo teórico de 70 operaciones a 10 XP, normalmente requiere al menos tres hábitos diarios dentro de la ventana de 32 fechas.

## Preflight

[level5_fixture_preflight.sql](D:/dev/alpha/rutio_app-security-economy/supabase/tests/level5_fixture_preflight.sql) es administrativo y de solo lectura. Comprueba wallet/progreso bootstrap, hábitos COUNT activos, fechas programadas, fechas ya completadas, capacidad XP y suficiencia para los 695 XP restantes.

No crea cuentas ni hábitos. Para una cuenta dedicada, primero debe confirmarse que Auth, `user_wallets` y `user_progress` existen; la creación de la cuenta y de sus hábitos queda fuera de este ejecutor.

## Fixture y ejecutor

- [Template de fixture](D:/dev/alpha/rutio_app-security-economy/supabase/tests/level5_fixture.template.json)
- [Ejecutor secuencial](D:/dev/alpha/rutio_app-security-economy/supabase/tests/run_level5_fixture.ps1)
- [Snapshot posterior](D:/dev/alpha/rutio_app-security-economy/supabase/tests/level_reward_projection_sync_verification.sql)

El JSON contiene únicamente el usuario, versión de cliente, IDs de hábitos existentes y fechas. El ejecutor valida ownership, tipo COUNT, target, archivado y fecha posterior a la creación. Cada operación llama exclusivamente a `complete_habit_economy_v1` con `p_value = target_count`.

Los request IDs son UUID deterministas derivados de usuario, hábito y fecha. Si se reanuda tras un error, repetir una operación ya aceptada devuelve la respuesta idempotente del servidor; no se reintenta automáticamente y el proceso se detiene ante el primer error. No hay concurrencia durante la preparación.

## Autoprueba local

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\supabase\tests\run_level5_fixture.ps1 -SelfTest
```

## Ejecución futura controlada

Primero ejecutar manualmente el preflight administrativo y completar el JSON con hábitos existentes y fechas válidas. Después, con JWT authenticated del usuario A:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\supabase\tests\run_level5_fixture.ps1 `
  -FixturePath .\supabase\tests\level5_fixture.json `
  -ConfirmStagingExecution
```

El `-ConfirmStagingExecution` es obligatorio. El ejecutor rechaza `service_role`, valida el JWT, fija el proyecto de Staging y no contiene rutas de creación o modificación directa de XP, wallet, progreso o ledgers.

## Claim posterior

Solo después de comprobar administrativamente nivel 5, XP 715, wallet/proyección coherentes y ausencia de claim previo de nivel 5, se preparará una única reclamación con `claim_level_reward`. No se incluye en el ejecutor del fixture para evitar mezclar completados y reclamación.

## Estado

Preparación local completada. No se crearon cuentas, hábitos ni datos remotos. No se ejecutaron RPCs, no se modificó Producción y no hubo commit, push ni merge.
