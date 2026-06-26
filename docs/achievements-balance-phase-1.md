# Achievements Balance Phase 1

## Summary
This phase rebalances special achievements by raising thresholds that were being unlocked too early while keeping the same IDs, names, visual assets, and overall concepts. The unlock engine remains centralized in `lib/stores/user_state_store_achievements.dart`, and already unlocked achievements are preserved as-is.

## Special achievements changes
| Achievement ID / nombre | Definición original | Regla anterior | Regla nueva | Dificultad estimada | Motivo del cambio |
| --- | --- | --- | --- | --- | --- |
| `special:madrugador` / Madrugador | Completar hábitos temprano | 10 completados antes de las 09:00 | 20 completados antes de las 09:00 | Entrada / primera semana | 10 se quedaba corto para un logro temático; 20 sigue siendo accesible pero ya exige repetición real. |
| `special:buho_nocturno` / Búho nocturno | Completar hábitos tarde | 10 completados después de las 22:00 | 20 completados después de las 22:00 | Entrada / primera semana | Misma lógica que Madrugador para evitar desbloqueos casi inmediatos. |
| `special:flash` / Flash | Pico alto de hábitos en un día | 5 hábitos en un día | 8 hábitos en un día | Entrada | Sigue siendo un pico puntual, pero ahora requiere un día realmente cargado. |
| `special:guerrero_del_finde` / Guerrero del finde | Mantener actividad en fin de semana | 25 días de fin de semana con progreso | 30 días de fin de semana con progreso | Long-term | Se refuerza como hábito sostenido de fin de semana y no como logro de dos meses escasos. |
| `special:el_arquitecto` / El arquitecto | Mucho volumen acumulado | 500 acciones totales | 750 acciones totales | Advanced / long-term | 500 quedaba demasiado cerca de otros hitos acumulativos; 750 separa mejor la progresión. |
| `special:turista` / Turista | Explorar familias distintas | 5 familias con al menos un hábito completado | 6 familias con al menos un hábito completado | Entrada / consistencia | Obliga a salir de la zona de confort sin solaparse del todo con `polimota`. |
| `special:hay_alguien_ahi` / ¿Hay alguien ahí? | Presencia social sostenida | 7 días sociales distintos | 12 días sociales distintos | Consistency | 7 días era casi inmediato; 12 mantiene el concepto pero pide más recurrencia. |
| `special:ave_fenix` / Ave fénix | Recuperarse tras romper rachas | 1 recuperación | 2 recuperaciones | Consistency | Una sola recuperación era demasiado fácil; 2 confirma resiliencia sin incentivar el fallo en exceso. |
| `special:perfeccionista` / Perfeccionista | Completar todo lo programado | 10 días perfectos | 21 días perfectos | Consistency | Convierte el logro en una muestra real de disciplina sostenida. |
| `special:el_centurion` / El centurión | Volumen total de completados | 100 completados | 150 completados | Advanced | 100 llegaba demasiado pronto; 150 sigue siendo razonable pero más memorable. |
| `special:imparable` / Imparable | Racha global continua | 21 días seguidos | 30 días seguidos | Advanced | Un mes completo encaja mejor con el fantasy de “imparable”. |
| `special:coleccionista` / Coleccionista | Acumular muchos logros | 30 logros desbloqueados | 40 logros desbloqueados | Long-term | Evita que salte demasiado pronto dentro del árbol total de logros actual. |
| `special:leyenda_viva` / Leyenda viva | Muchísimo volumen histórico | 1000 completados históricos | 1500 completados históricos | Long-term | Refuerza el carácter de meta tardía y separa mejor este logro de `el_arquitecto`. |
| `special:francotirados` / Francotirados | Clavar el target exacto en hábitos numéricos | 25 aciertos exactos | 100 aciertos exactos | Long-term | Se convierte en un hito de precisión sostenida de verdad, manteniendo la condición de clavar exactamente el target y no simplemente superarlo. |
| `special:reloj_suizo` / Reloj suizo | Completar cerca del recordatorio | 20 completados dentro de ±10 min | 30 completados dentro de ±10 min | Consistency / advanced | Hace falta más regularidad horaria para sentirlo como precisión real. |
| `special:veterano` / Veterano | Volver muchos días distintos | 180 días con progreso | 240 días con progreso | Long-term | Se consolida como hito de permanencia real en la app. |

## Not changed
- Family achievements were not touched in this phase because the goal was to rebalance only special achievements.
- UI, navigation, and visual treatment were not changed.
- Achievement persistence format was not changed.
- Achievement IDs were not changed.
- `special:polimota` was not changed because its concept is already bounded by the number of Rutio families.
- `special:plusmarquista` was not changed because 100 days is already a healthy long-term streak target.
- Global `count` completion semantics were not changed in this phase to avoid side effects in diary, stats, and habit behavior.

## Compatibility note
Already unlocked achievements are not revoked. Existing records remain stored and visible even if their old threshold is now below the new rule, which protects current users from losing progress or rewards they already earned.

## Future phases
- Phase 2: review `count` semantics so achievement/streak logic can distinguish `> 0` from truly reaching the configured target where appropriate.
- Phase 3: revisit family- and habit-type-specific achievements to reduce repetition and improve identity.
- Phase 4: expand long-term goals and evaluate cosmetic or premium-adjacent achievement layers only if they fit product direction.
