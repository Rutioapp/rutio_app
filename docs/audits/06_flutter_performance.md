# 06 — rendimiento Flutter

## Evidencia

- **VERIFICADO:** inicialización previa a `runApp` incluye Crashlytics, PostHog, Supabase y `SharedPreferences`; RevenueCat se crea lazy=false y su init se lanza sin esperar (`lib/main.dart:117-208,384-392`). Esto puede aumentar cold start y no está medido en profile/release.
- **VERIFICADO:** hay caches por usuario, scope epochs y descarte de resultados stale en bootstrap; existen tests de estas garantías.
- **RIESGO POTENCIAL:** SharedPreferences se usa para estado grande, diarios, colas y caches; el coste de serialización/memoria y tamaño no está medido.
- **RIESGO POTENCIAL:** múltiples repositorios de reportes/estadísticas pueden repetir lecturas; no se dispone de timeline ni network trace.
- **NO VERIFICABLE:** frames p50/p95, jank, memoria, cold start iOS/Android, battery, red real y años de historial representativos.

## Plan de medición

Profile/release en dispositivo físico: cold/warm start, primer frame, home ready, navegación estadísticas, 1/5/10 años, 5/50/200 hábitos, offline/reconnect. Registrar frame raster/build, memoria, bytes, número de requests, p95 y errores. Comparar debug sólo para desarrollo.

## Recomendaciones P2/P3

Paralelizar sólo inicializaciones independientes, paginar historiales, deduplicar futures/streams, aislar agregados pesados en isolate o servidor tras medir, y definir límites de cache/retención. No introducir materialized views aún.
