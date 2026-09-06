# Onboarding V1 — Fase 5: checklist manual de permisos

Este checklist valida el boundary nativo de permisos. No verifica scheduling:
la Fase 5 no programa notificaciones porque todavía no existe un `habitId`
canónico.

## iOS

- [ ] Instalar con permisos de notificaciones en estado no decidido.
- [ ] Llegar a Reminder sin que aparezca ningún prompt automáticamente.
- [ ] Pulsar “Activar recordatorio” y confirmar una hora.
- [ ] Elegir “Allow” y comprobar que el draft conserva `authorized` y
      `readyToSchedule`.
- [ ] Repetir con “Don’t Allow” y comprobar que se avanza a Preview con la hora
      conservada y estado `pendingRetry`.
- [ ] Cerrar y reabrir en Reminder/Preview; comprobar que no aparece un segundo
      prompt y que la hora/intención siguen intactas.
- [ ] Con permiso ya decidido, cambiar la hora y comprobar que no se solicita
      permiso de nuevo.

## Android

- [ ] Repetir el flujo en cada versión Android soportada que muestre permiso de
      notificaciones.
- [ ] Comprobar Allow, Deny y permiso previamente denegado/restringido.
- [ ] Confirmar que Reminder no abre Settings automáticamente.
- [ ] Confirmar que no se crea una notificación mientras el onboarding sigue en
      Preview placeholder.
