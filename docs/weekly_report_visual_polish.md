# Weekly Report visual polish

## Objetivo

Dar a la pantalla `Tu semana` un acabado más editorial y cálido, manteniendo la
densidad compacta aprobada y sin modificar datos, clasificación, navegación ni
flujos de guardado.

## Decisiones visuales

- El fondo usa el crema cálido existente en el lenguaje de Diary V2, con una
  superficie clara, borde tenue y sombra corta para las cards.
- El resumen incorpora un acento `trending_up` y una decoración botánica
  dibujada en una esquina. La decoración es intencionadamente sutil y no añade
  un asset ni cambia la altura del contenido.
- La recomendación usa una superficie melocotón diferenciada y un CTA con pill
  bordeada; reflexión usa una superficie lila/gris cálida para separar el tono
  emocional del analítico.
- Los grupos de hábitos mantienen expansión, orden y filas existentes, pero
  sus iconos, títulos y contadores comparten un tratamiento tonal por estado.

## Criterios de color

Los tokens viven en `weekly_report_visuals.dart`:

- `0%` con programación: alerta cálida suave; `1–39%`: coral/naranja suave.
- `40–59%`: mostaza suave.
- `60–79%`: oliva estable.
- `80–100%`: verde positivo.
- Sin plan o sin dato: beige neutro claro.

El ring conserva un track neutro y aplica un gradiente muy corto dentro del
mismo tono. Las barras conservan la altura proporcional y solo cambian su
tratamiento visual.

## Componentes tocados

- `weekly_report_screen.dart`: fondo, header/rango, resumen, ring, barras,
  cards base y banners.
- `weekly_report_habits_section.dart`: superficie, tonos de grupo, contadores
  y chevrons.
- `weekly_report_recommendation.dart`: superficie cálida, decoración y CTA.
- `weekly_report_reflection.dart`: superficie lila, cabecera, mood selector y
  campo de texto.
- `weekly_report_visuals.dart`: tokens, decoración y reglas de color.

No se tocaron dominio, DTOs, mappers, repository, Supabase, scheduler,
notifications, routing ni recommendation/reflection flow.

## Phase 13

Queda para hardening la validación visual en dispositivos/emuladores reales y
la revisión final de banners cerrados si se añaden nuevos estados de producto.
