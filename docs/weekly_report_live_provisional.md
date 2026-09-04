# Live provisional Weekly Report

## 1. Comportamiento

La semana local actual puede consultarse desde el lunes hasta el domingo. Al
abrir el reporte productivo, el controller obtiene la semana local con la zona
IANA configurada:

- provisional actual existente: solicita refresh remoto una vez;
- semana actual ausente: solicita el RPC público de refresh, que genera el
  provisional;
- último reporte anterior: resuelve primero la semana actual y después genera
  o refresca si corresponde;
- final actual o histórico: solo lectura, nunca se regenera desde el cliente.

El botón/gesture de refresh productivo usa el mismo método
`refreshCurrentWeek()` y no puede refrescar reportes abiertos desde History.

## 2. Fuente de datos y días futuros

Los `habit_logs` siguen siendo la fuente viva para cada refresh. El generator
lee las filas por `user_id`, `habit_id` y `log_date`, reconstruye
`weekly_report_days` y `weekly_report_habits`, y reemplaza los hijos del
provisional.

La elegibilidad provisional termina en la fecha local actual. Por tanto, en una
semana en curso solo los días transcurridos pueden reflejar logs reales; los
días futuros se mantienen como `noPlan` con denominador cero y no son fallos ni
tareas completadas.

La política `timesPerWeek`, la activación, `created_at`/config history y
`firstPartialWeek` no cambian.

## 3. Causa del rechazo jueves/viernes

Los logs de Device QA demuestran que Flutter calculó correctamente
`2026-08-31`, `2026-09-04` y `Europe/Madrid`, y que sí llamó al RPC público. La
base remota confirma además que el report existe como `provisional`, que la
activación es válida y que la semana calculada por SQL es `2026-08-31`.

El rechazo exacto ocurría dentro del generator, antes de reconstruir los días:
existían simultáneamente las sobrecargas privadas de
`weekly_report_pick_copy_key` con 5 y 6 argumentos; la de 6 tenía parámetros
por defecto. Las llamadas internas con 4/5 argumentos eran ambiguas y
PostgreSQL devolvía SQLSTATE `42725`.

La rama anterior del controller para “último report anterior o ningún report”
también estaba incompleta: solo releía `getLatest()` y no llegaba al RPC. Esa
ruta ya queda corregida, pero no es la causa del `WeeklyReportRefreshRejected`
observado cuando el report provisional actual ya existía.

Además, el generator tenía un bug independiente y confirmado en la frontera de
evaluación: `wr_days.eligible` solo comprobaba que el día fuese posterior a la
activación, pero no que fuese menor o igual que el día local actual. Esto hacía
que un provisional de mitad de semana evaluara también días futuros y
contaminara el snapshot con denominador/estados que no representan "hasta hoy".

Cuando sí existía un provisional de la semana actual, la cadena anterior ya
llamaba al RPC público, hacía el read-back autoritativo y reemplazaba el estado;
no se encontró una ruta en la que el cache provisional pisara esa respuesta.

Las fechas de día se mantienen como `date` en SQL y se registran en debug para
detectar desplazamientos de zona; el payload remoto conserva la fecha ISO sin
hora. El mapper reconstruye esas fechas como calendario local y no convierte
medianoche UTC a hora del dispositivo.

## 4. Cache, errores y scope

La respuesta remota se publica en estado visible después de un refresh. El
cache provisional solo es fallback ante error; el cache final permanece
protegido. `scopeEpoch`/scope checks existentes siguen descartando respuestas
stale. Un fallo con snapshot actual conserva el snapshot; sin snapshot actual
se muestra el estado de retry/error.

## 5. Automatización

La garantía backend del domingo 19:00, la notificación del domingo 20:00 y la
finalización del lunes 00:10 permanecen sin cambios. Las migraciones nuevas
actualizan la ventana provisional live y eliminan la sobrecarga SQL ambigua.

## 6. Diagnóstico debug

En builds debug se emiten entradas `[WEEKLY_REPORT_REFRESH]` con report id,
semana, fecha local, zona, estado previo, source cache/remoto, métricas y
resumen diario (`scheduled`, `completed`, `skipped`). No se registran nombres ni
otro PII.

La cobertura automatizada incluye contrato estático de la migración y fixtures
Flutter para semana actual existente/ausente, final, error y scope stale. La
fixture SQL ejecutable contra una base local requiere el stack Supabase/Docker;
en este entorno no estaba disponible.
