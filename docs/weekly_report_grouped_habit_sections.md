# Weekly Report — grouped habit sections

## Motivo

La lista plana de Phase 8A podía hacer que el Weekly Report dejase de sentirse
como una síntesis cuando una persona tenía muchos hábitos. Esta iteración
mantiene el detalle existente, pero lo oculta inicialmente detrás de grupos
compactos.

## Grupos de rendimiento

El bloque presenta siempre, en este orden, `highlighted` (Destacados), `stable`
(Estables) y `needs_attention` (Necesitan atención). Cada encabezado muestra
icono, título, copy breve, contador y estado expandible.

## Estado y expansión

Los tres grupos empiezan contraídos en cada instancia del widget. El estado es
local y no se persiste. Cada fila completa es táctil, y varios grupos pueden
permanecer expandidos simultáneamente. `AnimatedSize` proporciona una
transición breve y ligera.

## Autoridad y orden del backend

Flutter solo filtra por `habit.classification` para presentation grouping. No
calcula ni cambia la clasificación, y no inspecciona completion rate para
decidir el grupo. El recorrido de la lista conserva el orden recibido por el
backend dentro de cada grupo.

## `unavailable`

Los hábitos `unavailable` no se mezclan con ningún grupo de rendimiento. Si
existen, aparecen debajo como una línea secundaria «Sin programación esta
semana · N», contraída por defecto y expandible con las mismas filas.

## Reutilización de filas y chip

Se reutiliza la fila compacta de Phase 8A, incluidos identidad de snapshot,
métricas, dots diarios, `timesPerWeek`, skip, partial y streak. El chip
individual de clasificación se retira en el layout agrupado: el encabezado
padre ya comunica esa clasificación y así se mejora la densidad. La
clasificación permanece en la semántica del encabezado y no cambia el dominio.

## Accesibilidad y responsive

Los encabezados anuncian título, cantidad y estado contraído/expandido, con la
acción de expandir o contraer. Los grupos vacíos anuncian solo su título y
contador, sin acción. Las semánticas existentes de las filas y dots se
conservan. No hay alturas fijas: subtítulos y nombres pueden envolver con
Dynamic Type y anchos estrechos (incluido `<=350` logical px).

## Trabajo diferido

Recommendations, reflection y cualquier lógica de negocio permanecen fuera de
este refinement.
