# Corrección local — sincronización de recompensas de nivel

## Causa

`claim_level_reward` actualizaba `public.user_wallets` y añadía una fila a `public.achievement_level_reward_ledger`, pero retornaba sin invocar `app_private.refresh_authoritative_user_progress`. Por tanto, `user_progress.ambar_balance` podía conservar el saldo anterior aunque `user_wallets.coins` ya fuese correcto.

## Comparación con logros

`claim_achievement_reward` ya ejecuta `refresh_authoritative_user_progress` después de insertar el ledger monetario y el ledger XP. No presenta el mismo defecto.

## Corrección local

Se añadió `20261018100000_sync_level_reward_user_progress.sql`. Reemplaza únicamente la función `claim_level_reward` y conserva:

- wallet como autoridad económica;
- fórmula y niveles de recompensa existentes;
- cálculo de elegibilidad desde `economy_xp_ledger`;
- locks por usuario y request;
- unicidad e idempotencia del ledger;
- ausencia de escrituras en `economy_xp_ledger`;
- permisos y RLS sin cambios.

El refresh ocurre dentro de la misma transacción después de un claim nuevo. También se ejecuta en los caminos idempotentes para reparar una proyección antigua sin sumar monedas: el refresh solo recalcula `user_progress` desde wallet y ledgers.

Si el refresh falla, la transacción revierte tanto la actualización de wallet como el ledger del claim.

## Verificaciones preparadas

- `supabase/tests/level_reward_projection_sync_static_test.ps1`
- `supabase/tests/level_reward_projection_sync_verification.sql`

La consulta administrativa comprueba wallet, versión, `ambar_balance`, ledger, igualdad wallet/proyección y que una recompensa de nivel no cree XP.

## Pruebas locales

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\supabase\tests\level_reward_projection_sync_static_test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\supabase\tests\run_rewards_validation_phase_a.ps1 -Action selftest
powershell -NoProfile -ExecutionPolicy Bypass -File .\supabase\tests\authoritative_economy_phase1_static_test.ps1
```

## Revisión y despliegue manual en Staging

No se ejecuta automáticamente. Revisar primero el diff y el SQL. Después, con el proyecto objetivo verificado como `fuibgptjhsjvenjdxtqt`, aplicar manualmente la migración mediante el procedimiento habitual de Supabase. Antes y después ejecutar `level_reward_projection_sync_verification.sql` con conexión administrativa.

La prueba positiva debe usar un nivel que el usuario A ya haya alcanzado de forma natural y que aún no figure en `achievement_level_reward_ledger`. No se modifican XP, wallet, progreso ni ledgers para crear la precondición.

Secuencia posterior recomendada:

1. Snapshot administrativo inicial.
2. Claim positivo con un `request_id` nuevo.
3. Comprobar que wallet y ledger aumentan exactamente la recompensa configurada.
4. Comprobar `user_progress.ambar_balance = user_wallets.coins`.
5. Repetir con el mismo `request_id`; comprobar que no aumenta wallet, versión ni número de filas.
6. Repetir con `request_id` distinto para el mismo nivel; comprobar idempotencia por fuente.
7. Ejecutar dos claims simultáneos del mismo nivel y comprobar una sola recompensa.

Producción, Flutter, RevenueCat, Vault, Cron, permisos, RLS y datos remotos no se han tocado. No hay commit, push ni merge.
