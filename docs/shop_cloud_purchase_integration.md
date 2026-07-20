# Shop Cloud Purchase Integration

## 1. Resumen

Esta fase completa la integracion cloud de compras de utilidades para que la tienda pueda mostrar y usar la wallet remota como fuente visible de economia cuando los dos flags cloud estan activos:

- `SHOP_CLOUD_READ_ENABLED`
- `SHOP_CLOUD_PURCHASE_ENABLED`

Cuando uno de los flags no esta activo, la tienda sigue usando exactamente el flujo local anterior.

## 2. Causa exacta del problema previo

La wallet cloud no llegaba a presentation por una combinacion de dos problemas:

- La pantalla de tienda estaba dependiendo del saldo legacy/local como valor por defecto visible.
- El controlador de tienda no tenia una fuente explicita de economia ni un estado cloud separado, asi que una recarga podia volver a pintar el saldo local aunque ya existiera una wallet remota valida.

Ademas, el flujo visual no distinguia entre:

- economia local
- economia cloud cargando
- economia cloud lista
- wallet cloud ausente
- sesion ausente

El resultado era que Supabase podia tener 10.000 monedas, pero la UI seguia mostrando el saldo local.

## 3. ShopEconomySource

Se introdujo una fuente explicita de economia:

```dart
enum ShopEconomySource {
  local,
  cloud,
}
```

Regla aplicada:

- `local` cuando la compra cloud no esta habilitada.
- `cloud` solo cuando:
  - `SHOP_CLOUD_READ_ENABLED == true`
  - `SHOP_CLOUD_PURCHASE_ENABLED == true`
  - existe sesion autenticada
  - existe una wallet remota valida

La decision se resuelve en `ShopController`, no en varios widgets.

## 3.1 Fuente canonica para shop

La fuente remota canonica para la compra cloud de utilidades es `public.user_wallets`.

Motivos:

- la RPC `purchase_shop_item` hace la lectura y escritura atomica sobre `user_wallets`
- la tabla tiene `version` para reconciliacion de wallet
- `shop_ledger` deja trazabilidad de cada compra
- la tienda cloud no necesita conocer `user_progress` para validar compra

`public.user_progress.ambar_balance` sigue existiendo como proyeccion legacy de la economia global de la app, pero no es la autoridad de la tienda cloud en esta fase.

## 4. Estados cloud

El estado visible de economia cloud queda modelado con:

- `disabled`
- `loading`
- `ready`
- `stale`
- `walletMissing`
- `unauthenticated`
- `failed`

Comportamiento clave:

- `ready` muestra la wallet cloud confirmada.
- `stale` mantiene el ultimo saldo valido mientras se reintenta o si falla un refresh posterior.
- `walletMissing` bloquea la compra cloud y no cae silenciosamente al saldo local.
- `unauthenticated` no reutiliza datos anteriores.
- `failed` no destruye el ultimo snapshot valido.

## 5. Saldo efectivo

`ShopController` expone un saldo visible unico:

- `visibleCoinBalance`

Reglas:

- Modo local: devuelve el saldo local actual.
- Modo cloud listo: devuelve `ShopCloudSnapshot.wallet.coins`.
- Cloud cargando: devuelve `null` mientras se hidrata, salvo que ya exista un snapshot valido del mismo usuario.
- Wallet cloud inexistente: devuelve `null` y deja el estado en `walletMissing`.

La UI de tienda usa este saldo efectivo en lugar del saldo local legacy cuando la economia cloud esta activa.

## 6. Cantidades efectivas

Las cantidades visibles de las cinco utilidades cloud salen del inventario remoto:

- `utility_xp_boost_1d`
- `utility_coin_boost_1d`
- `utility_streak_recover_1`
- `utility_streak_shield_1`
- `utility_mystery_box_basic`

Fuente:

- `public.user_inventory.quantity`

Reglas:

- si no hay fila remota, la cantidad visible es `0`
- no se suma inventario local y cloud
- no se copia inventario cloud al inventario legacy
- cosmeticos y bundles siguen en local

La vista de tienda ajusta el `ShopState` visible para reflejar el inventario cloud sin migrar esos datos al estado local.

## 7. Carga inicial

Cuando la pantalla de tienda entra en escena con ambos flags activos, el flujo es:

1. Obtener el usuario autenticado actual.
2. Hidratar `ShopCloudSnapshot`.
3. Validar que `authenticatedUserId` coincide con la sesion actual.
4. Guardar el snapshot en memoria por `userId`.
5. Notificar a presentation.
6. Pintar la wallet cloud.
7. Pintar las cantidades cloud de utilidades.

La hidratacion se hace con coalescing de `Future` por usuario para evitar duplicar lecturas cuando varias pantallas piden la misma informacion al mismo tiempo.

## 8. Compra confirmada

Cuando `purchase_shop_item` responde correctamente:

1. Se valida el DTO de resultado.
2. Se aplica de inmediato al snapshot en memoria:
   - monedas
   - version de wallet
   - cantidad remota del item comprado
3. La UI recibe el resultado confirmado.
4. Se lanza un refresh remoto completo.
5. Si el refresh falla:
   - la compra sigue siendo exitosa
   - el ultimo resultado confirmado se mantiene visible
   - el snapshot queda como `stale`
   - no se repite la compra
   - no se restaura el saldo anterior

No se resta saldo local en paralelo.

## 9. Snapshot stale

El estado `stale` existe para el caso en que:

- la compra ya fue confirmada
- el refresh posterior no pudo completar

Ese estado conserva la ultima informacion valida del mismo usuario y evita que la UI vuelva a un saldo anterior o a cero.

## 10. Sesion y cambio de usuario

Cuando cambia el usuario:

- se limpia el snapshot en memoria del usuario anterior
- se limpia el saldo visible previo
- se ignoran lecturas tardias del usuario anterior
- se carga el snapshot del nuevo usuario
- no se reutilizan monedas ni inventario entre cuentas

En logout:

- la tienda vuelve a un estado no autenticado
- no muestra monedas del usuario anterior
- no borra operaciones pendientes inciertas de forma agresiva

## 11. Acciones cloud todavia bloqueadas

Esta fase solo completa la economia visible y la compra cloud de utilidades. Todavia no migra estas acciones:

- abrir mystery box remotamente
- activar XP Boost remotamente
- activar Coin Boost remotamente
- consumir Shield remotamente
- consumir Recover remotamente

En modo cloud, la UI solo debe permitir comprar y mostrar correctamente la cantidad remota. Las acciones de uso siguen separadas para una fase posterior.

## 12. Sin efectos de gamificacion

La hidratacion de wallet e inventario cloud no:

- modifica XP
- modifica nivel
- invoca `LevelUpCelebrationController`
- crea `LevelEvent`
- añade monedas locales
- ejecuta rewards de currency
- ejecuta rewards de achievements
- escribe `UserStateStore` de progreso

La lectura cloud solo alimenta la economia visible.

## 13. Como activar y probar

Ejemplo de ejecucion:

```bash
flutter run \
  --dart-define-from-file=dart_defines/dev.json \
  --dart-define=SHOP_CLOUD_READ_ENABLED=true \
  --dart-define=SHOP_CLOUD_PURCHASE_ENABLED=true
```

Prueba manual esperada con el usuario de desarrollo:

1. La tienda muestra 10.000 monedas.
2. Reiniciar mantiene el saldo de Supabase.
3. No aparece una subida de nivel al arrancar.
4. Comprar XP Boost resta 75.
5. El header muestra 9.925.
6. La cantidad del XP Boost aumenta en 1.
7. Reiniciar muestra 9.925 y la cantidad remota.
8. No se modifica el saldo local.
9. No se activa automaticamente el boost.
10. No aparece una celebracion de nivel.

## 14. Limitaciones

- Los cosméticos siguen en local.
- La activacion/consumo de utilidades cloud sigue separada de la compra visible.
- La tienda cloud depende de una sesion Supabase valida.
- Si falta wallet remota, la compra cloud se bloquea de forma controlada.

## 15. Siguiente fase

La siguiente fase recomendada es conectar el uso de utilidades cloud para:

- abrir mystery box remoto
- activar boosts remotos
- consumir Shield y Recover remotos

La base de economia ya queda lista para esa extension sin mezclar estados locales y remotos.
