# Weekly Report contextual copy

El backend persiste únicamente una `message_key` determinista en
`weekly_reports` o `weekly_report_habits`. Flutter resuelve esa key mediante
los catálogos ES/EN; no se persiste texto traducido ni se genera copy en
tiempo de ejecución.

## Catálogo v1

| Familia | Keys |
|---|---:|
| `summary_first_partial` | 18 |
| `summary_provisional` | 18 |
| `summary_no_schedule` | 14 |
| `summary_strong` | 20 |
| `summary_good` | 20 |
| `summary_mixed` | 20 |
| `summary_needs_recovery` | 20 |
| `summary_improved` | 18 |
| `summary_declined` | 18 |
| `habit_highlighted` | 16 |
| `habit_stable` | 16 |
| `habit_needs_attention` | 16 |
| **Total** | **214** |

La ampliación mantiene `content_version=1`: es compatible con las keys
anteriores, es aditiva e idempotente, y no modifica reports finalizados.

Las summaries mezclan observación, reflexión, reconocimiento y motivación
suave. Las observaciones de hábitos son breves y no sustituyen la lógica de
clasificación, recommendation o reflection. El texto está disponible en
español de España e inglés natural de EE. UU., con intención equivalente pero
sin traducción literal obligatoria.

La selección sigue siendo determinista y conserva la política anti-repeat
actual: summaries evitan las últimas cuatro finales cuando hay alternativas y
las observaciones respetan la rotación por hábito y dentro del report.

Las futuras ampliaciones deben usar una nueva migración forward, conservar el
namespace `weekly_report_<family>_<nn>`, añadir ambos idiomas y actualizar las
pruebas de paridad, counts, keys únicas y fallback sin modificar migrations
aplicadas.

## Contratos editoriales auditados

`summary_no_schedule` se selecciona en backend únicamente cuando
`p_scheduled = 0`; en Flutter, `hasScheduledCount` equivale a
`scheduledCount > 0`. No existe una familia adicional de estado “low signal”
en este flujo. Por eso sus 14 frases describen exclusivamente la ausencia de
hábitos u oportunidades programadas, sin inferir poca actividad, calendario
ligero o descanso voluntario.

Las frases `summary_provisional` son válidas cualquier día de lunes a domingo.
Cuando hablan del futuro usan el cierre de la semana como referencia, no días
pendientes ni próximos días.

Las observaciones `habit_needs_attention` son descriptivas: señalan ritmo,
continuidad, interrupciones o estabilidad observados. Las recomendaciones
siguen siendo el único lugar para proponer ajustes o acciones. La tarjeta de
hábito ya presenta `emoji + habit.name` y después la observación, así que el
catálogo no duplica nombres ni añade placeholders. No se usa interpolación en
v1; personalización contextual queda como posible v2.
