# Flexible Weekly Check — Weekly Report Manual QA

QA orientada a dispositivo para una build que ya tenga disponible el backend
compatible. No requiere conocer la implementación interna.

## A. Policy 2

- [ ] Abrir un reporte con política 2 y comprobar que muestra el contenido
      normal, sin campos vacíos inesperados.
- [ ] Verificar que los contadores y el porcentaje corresponden al mismo
      intervalo semanal.

## B. 2/3

- [ ] Crear/comprobar un hábito flexible de 3 veces por semana.
- [ ] Completar dos días distintos.
- [ ] Confirmar que el reporte muestra `2/3` y un progreso aproximado del 67%.

## C. 3/3

- [ ] Completar tres días distintos de la semana.
- [ ] Confirmar `3/3`, 100% visual y estado de objetivo alcanzado.

## D. 4/3

- [ ] Completar un cuarto día después de alcanzar la cuota.
- [ ] Confirmar que el reporte conserva `4/3` y no convierte el contador en
      `3/3`.
- [ ] Confirmar que la barra no supera 100%.

## E. Skip

- [ ] Marcar un día como omitido.
- [ ] Confirmar que no suma una finalización ni reduce la cuota semanal.
- [ ] Confirmar que la marca de omitido es visible donde corresponda.

## F. Neutral

- [ ] Dejar un día flexible sin completar ni omitir.
- [ ] Confirmar que aparece como pendiente/neutral y no como fallo diario.

## G. Mixed

- [ ] Usar en la misma semana un hábito diario, uno de días concretos y uno
      flexible.
- [ ] Confirmar que cada hábito conserva su propia regla y que el total no
      trata la cuota flexible como siete obligaciones.

## H. Grouping

- [ ] Revisar los grupos de hábitos con 0%, entre 0% y 80%, y 80% o más.
- [ ] Confirmar que un hábito 4/3 aparece en el grupo de mejor progreso y que
      un 2/3 no aparece como 100%.

## I. Trend

- [ ] Abrir dos semanas comparables con tasas distintas.
- [ ] Confirmar que la tendencia coincide con las tasas mostradas.
- [ ] En la primera semana parcial, confirmar que la tendencia se muestra como
      no disponible o equivalente neutral.

## J. Mixed history

- [ ] Abrir historial con semanas antiguas y semanas nuevas.
- [ ] Confirmar que cada semana conserva sus contadores, idioma y estado sin
      reinterpretarse usando la configuración actual.

## K. Legacy final

- [ ] Abrir un reporte final antiguo sin campos nuevos.
- [ ] Confirmar que sigue siendo legible y no cambia sus contadores al volver a
      entrar.

## L. Provisional refresh

- [ ] Abrir la semana actual provisional.
- [ ] Registrar una finalización y volver al reporte.
- [ ] Confirmar que el reporte se actualiza y que un reporte final no se
      modifica con un refresh.

## M. Offline cache

- [ ] Abrir una semana nueva con conexión y después activar modo avión.
- [ ] Confirmar que una instantánea nueva sigue mostrando los contadores, el
      progreso y la actividad disponible.
- [ ] Confirmar que una instantánea antigua sigue siendo legible offline.

## N. Deep link / notification

- [ ] Tocar una notificación del reporte semanal con la aplicación cerrada.
- [ ] Confirmar que abre el reporte de esa semana, no solo la semana actual.
- [ ] Si la semana no existe, confirmar que abre el historial o una pantalla
      de indisponibilidad recuperable.
- [ ] Comprobar una notificación alrededor del cambio de lunes y el rango
      mostrado.

## O. Unavailable / partial

- [ ] Abrir un reporte sin días programados y confirmar estado neutral/no
      disponible, sin `NaN` ni porcentaje engañoso.
- [ ] Abrir una semana cuyo hábito comenzó a mitad de semana y confirmar que
      se identifica como parcial.
- [ ] Confirmar que un dato incompleto no inventa un contador exacto.

## P. Compact layout

- [ ] Probar el ancho mínimo soportado del dispositivo.
- [ ] Probar texto grande/accesibilidad.
- [ ] Confirmar que `4/3`, nombres largos, grupos y recomendaciones no se
      cortan ni producen overflow.
