# Shop UI Phase 3 Audit

Fecha: 2026-07-01

## Resumen Ejecutivo

La nueva tienda ya tiene una base sólida y coherente para entrar en fase de pulido visual. La arquitectura visual está bastante bien encaminada: `ShopPageShell`, `ShopHeader`, `ShopUiTokens` y los cards reutilizables dan una base consistente, y `ShopFlowScreen` ya integra el flujo completo.

El principal riesgo no está en la apariencia, sino en la coordinación: `ShopFlowScreen` concentra navegación interna, carga de snapshot, compra, equipamiento, snacks y fallback de pantallas. Funciona, pero será el punto que más cuesta escalar cuando lleguen packs, eventos, boosts reales y variaciones de catálogo.

## Flujo Revisado

Shop -> Cosméticos -> Detalle -> Compra -> Personalización -> Mochila -> Colecciones

## Hallazgos Prioritarios

| Prioridad | Area | Hallazgo | Complejidad | Beneficio |
|---|---|---|---|---|
| Alta | Arquitectura UI | `ShopFlowScreen` mezcla orquestacion de flujo, carga de datos, acciones de compra/equipado y feedback visual en un solo widget. | Media | Alta |
| Alta | UX | Hay pantallas y acciones que siguen siendo temporales: `Colecciones` muestra snack de "pronto", y `Mochila` usa feedback provisional para usar items. | Baja | Alta |
| Alta | Estados | No todas las vistas tienen empty states propios cuando el resultado es vacio o casi vacio. `Utilities` y algunos filtros pueden quedar en blanco. | Baja | Alta |
| Media | Consistencia visual | Hay mezcla de etiquetas en espanol e ingles dentro de la misma experiencia: `Owned`, `Equipped`, `Common`, `Habit Cards`, `User Cards`. | Baja | Media |
| Media | Responsive | Las grids usan umbrales y aspect ratios fijos; en pantallas pequenas o con text scaling alto puede aparecer recorte o densidad visual excesiva. | Media | Alta |
| Media | Arquitectura futura | El progreso de colecciones se infiere por objetos comprados, no por una nocion explicita de desbloqueo/pack/evento. | Media | Alta |
| Media | Duplicacion | Hay repeticion de patrones de seccion + grid en `Cosmeticos`, `Utilidades`, `Personalizacion` y `Mochila`. | Media | Media |
| Baja | Accesibilidad | Hay buena base de tap targets, pero faltan semantics/labels explicitas en chips, badges y algunos estados. | Baja | Media |
| Baja | Rendimiento | El coste actual es correcto para el catalogo pequeno, pero varias pantallas recalculan listas filtradas en cada build. | Baja | Media |

## Auditoria Por Area

### 1. Arquitectura UI

La separacion por capas esta bien encaminada:

- `ShopPageShell` centraliza `SafeArea`, ancho maximo y scaffold comun.
- `ShopHeader` estandariza titulo, subtitulo y wallet.
- `ShopUiTokens` concentra radios, paddings, colores y tipografia.
- Los cards de contenido estan bastante enfocados y pequeños.

El punto mas fuerte es que la UI presentacional ya no depende de la pantalla legacy. El punto mas debil es que `ShopFlowScreen` sigue siendo un coordinador muy cargado:

- Carga snapshot.
- Mantiene stack interno.
- Resuelve navegacion a secciones.
- Lanza snackbars.
- Ejecuta compra/equipamiento.
- Rehidrata estado.

### 2. UX

El flujo principal se entiende bien para una primera fase. La home explica bien las tres entradas clave y el bloque `Destacado` ayuda a que la tienda no se sienta vacia.

Donde todavia hay friccion:

- `ShopHomeScreen` tiene varias entradas, pero la navegacion a detalles sigue requiriendo varios pasos desde algunas rutas.
- `ShopCollectionsScreen` aun no lleva a detalle, solo informa con un snack.
- `ShopBackpackScreen` y `ShopCustomizationScreen` son utiles, pero hay callbacks que hoy solo muestran estados provisionales.

### 3. Consistencia Visual

La direccion visual general es consistente y bien alineada con Rutio:

- Paleta camel/beige coherente.
- Tarjetas con bordes suaves.
- Mucho aire y jerarquia clara.
- Wallet visible en todas las pantallas principales.

Puntos a vigilar:

- Algunas etiquetas siguen en ingles.
- Algunos titulos secundarios repiten idea pero no siempre con la misma sintaxis.
- El tratamiento de rareza y coleccion cambia segun pantalla.

### 4. Estados

Hay una base buena de estados vacios, pero no es uniforme.

Lo que ya esta cubierto:

- Mochila vacia.
- Personalizacion vacia.
- Detalle no disponible.
- Confirmacion de compra con saldo insuficiente.

Lo que falta reforzar:

- Utilidades vacias.
- Cosmicos/filtros vacios cuando el filtro no devuelve items.
- Colecciones vacias o sin progreso real.
- Todo comprado / todo equipado con mensaje explicito de cierre.

### 5. Responsive

La experiencia esta preparada para mobile, pero el siguiente pulido deberia revisar:

- Pantallas pequenas con nombres largos.
- Text scaling alto.
- Landscape.
- Overflow en grids con 3 columnas.
- Altura fija del bottom sheet de confirmacion.

`ShopPageShell` ya ayuda bastante con `SafeArea` y ancho maximo, pero no resuelve por completo el layout interno de cada grid.

### 6. Accesibilidad

La base es razonable:

- Botones con `InkWell` y areas de toque aceptables.
- Titulos y subtitulos legibles.
- Contraste suficiente en la mayor parte de la UI.

Lo que faltaria antes de una fase mas madura:

- Semantics en filtros.
- Semantics en estados comprados/equipados.
- Labels mas descriptivos para wallet y previews.
- Reforzar foco y navegacion por teclado si aplica en desktop/web.

### 7. Rendimiento

No hay alarmas graves. El catalogo todavia es pequeno y la UI es liviana.

Posibles optimizaciones futuras:

- Evitar recalcular secciones filtradas en cada build si el catalogo crece.
- Centralizar aun mas el render de grids repetidas.
- Mantener el uso de `const` donde ya sea estable.
- Seguir evitando animaciones y rebuilds innecesarios en `ShopFlowScreen`.

### 8. Arquitectura Futura

La estructura actual soporta razonablemente bien:

- nuevos fondos,
- nuevos tipos,
- boosts,
- avatar,
- iconos,
- sonidos,
- eventos,
- packs,
- descuentos,
- colecciones temporales,
- temas completos.

Pero para que eso sea sencillo de verdad, el siguiente paso deberia desacoplar:

- coordinacion de flujo,
- resolucion de estado visual,
- acciones de dominio,
- y widgets de presentacion.

### 9. Codigo y Deuda

Observaciones:

- La wrapper legacy de `lib/screens/shop_screen.dart` es correcta y ya no condiciona la experiencia final.
- No he visto una cantidad preocupante de `TODO` o `FIXME` dentro de shop.
- La principal deuda no es codigo muerto, sino repeticion estructural y coordinacion excesiva en el flujo.

## Recomendaciones Priorizadas

### Alta

1. Separar `ShopFlowScreen` en un coordinador mas fino y una capa de estado/presentacion.
2. Dar empty states reales a `Utilidades` y a las vistas filtradas sin resultados.
3. Reemplazar los snacks temporales de `Colecciones` y `Usar` por un flujo mas claro, aunque siga siendo stub.

### Media

1. Unificar etiquetas y microcopy para eliminar mezcla de ingles/espanol.
2. Extraer una abstraccion comun para secciones con grid y cabecera.
3. Revisar thresholds de grid, alturas fijas y textos largos en pantallas pequenas.
4. Definir un modelo de progreso de colecciones mas explicito para packs/eventos.

### Baja

1. Anadir semantics a chips y badges.
2. Afinar mensajes de fallback y estados de exito/error.
3. Reducir recalculos de listas filtradas si el catalogo crece mucho.

## Roadmap Propuesto

### 1. Cierre de estados vacios y copy

- Harmonizar utilidades, cosmeticos y colecciones vacias.
- Unificar microcopy de estados, rarezas y categorias.

### 2. Consolidacion de estructura

- Extraer un componente comun para secciones de catalogo con grid.
- Reducir duplicacion entre `Cosmetics`, `Utilities`, `Customization` y `Backpack`.

### 3. Robustez responsive

- Revisar filtros, grids y bottom sheet en pantallas pequenas.
- Probar landscape y text scaling alto.

### 4. Arquitectura de flujo

- Dividir `ShopFlowScreen` en controlador de navegacion y widgets puros.
- Separar feedback visual de la logica de compra/equipado.

### 5. Preparacion para Fase 4

- Definir soporte explicito para packs, eventos, colecciones temporales y temas completos.
- Preparar el modelo para assets finales sin reescribir pantallas.

