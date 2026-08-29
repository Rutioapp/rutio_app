# Personalized Notifications Phase 8: QA + Activation Readiness

Fecha: 2026-08-29

## 1. Estado final del pipeline

El pipeline revisado queda coherente de extremo a extremo:

`Settings / runtime triggers`
→ `PersonalizedNotificationOrchestrator`
→ `Context Builder`
→ `Selection Engine`
→ `Renderer`
→ `Plan Builder`
→ `OS-aware Reconciliation`
→ `Native Executor`
→ `Manifest + History`

Estado funcional:

- `Settings / runtime triggers` llegan al orchestrator.
- El orchestrator hace single-flight, controla scope y respeta el gate.
- El context builder y el selection engine siguen intactos.
- El plan builder produce `DesiredNotificationPlan` para v2.
- La reconciliación OS-aware usa `Desired + Manifest + OS pending`.
- El executor nativo valida scope, permisos, timezone y capacidad.
- El manifest se proyecta con éxito/fallo real.
- History registra solo `CREATE` y `REPLACE` aceptados.

## 2. Bugs encontrados/corregidos

No se encontraron bugs funcionales nuevos durante esta fase.

- No hubo fixes de código.
- No fue necesario cambiar arquitectura.
- No fue necesario activar el gate.

## 3. Feature gate

`RUTIO_ENABLE_PERSONALIZED_NOTIFICATIONS_V2`

- Default actual: `OFF`.
- El gate sigue apagado al cerrar esta fase.
- Con gate OFF:
  - la UI personalizada no aparece en settings;
  - los triggers no ejecutan scheduling v2 de forma productiva;
  - el comportamiento legacy de habit reminders sigue intacto.
- Con gate ON:
  - aparece la sección de settings;
  - las preferencias del usuario controlan enable/disable;
  - el estado de permisos se respeta;
  - el scheduling v2 puede ejecutarse.

## 4. Automated tests

Ejecutados con éxito:

- `flutter analyze --no-pub lib/features/notifications test/features/notifications lib/screens/profile/settings_screen.dart lib/application/auth/auth_controller.dart lib/stores/user_state_store.dart`
- `flutter test --no-pub test/features/notifications`
- `flutter test --no-pub test/application/auth/auth_controller_test.dart`
- `flutter test --no-pub test/application/bootstrap/bootstrap_controller_test.dart`
- `flutter test --no-pub test/stores/user_state_store_notification_mutation_observer_test.dart`
- `flutter test --no-pub test/features/notifications/application/personalized_notification_settings_controller_test.dart`
- `flutter build apk --debug --no-pub`

Resultado:

- analyzer: verde;
- suite de notificaciones: verde;
- auth/logout: verde;
- bootstrap: verde;
- observer de mutaciones: verde;
- settings controller: verde;
- build Android debug: verde.

## 5. iOS manual QA checklist

### A. Permission

- permiso ya concedido;
- `notDetermined`;
- `denied`;
- permiso desactivado desde iOS Settings;
- volver a la app y verificar reconcile.

### B. Settings

- enable;
- disable;
- cambiar intensidad;
- cambiar hora;
- persistencia tras kill/relaunch.

### C. Scheduling

- crear personalized;
- verificar pending real en iOS;
- modificar preference;
- comprobar `REPLACE`;
- desactivar;
- comprobar `CANCEL`.

### D. Foreground / Background

- foreground reconciliation;
- background;
- kill app;
- relaunch;
- no duplicados.

### E. Multiuser

Usuario A:

- personalized pending.

Logout A:

- cleanup.

Login B:

- ninguna notificación ni contexto de A.

### F. Timezone

- Madrid;
- cambiar timezone simulada o del dispositivo si resulta viable;
- foreground;
- replan.

### G. Date change

- plan del día actual;
- cambio de fecha;
- foreground;
- reconcile.

### H. DST

- spring forward;
- fall back.

Si no puede probarse razonablemente en dispositivo:

- cubrirlo con tests timezone deterministas.

## 6. Android sanity

Verificación básica completada:

- compila en debug;
- el canal sigue siendo el compartido existente;
- scheduling no requiere exact alarm propio para v2;
- el payload v2 parsea correctamente en tests;
- no hay crash evidente en la ruta revisada.

## 7. Multiuser / logout validation

Resultado:

- el cleanup de logout se ejecuta mientras el scope A sigue disponible;
- un fallo de cleanup no bloquea el logout;
- el manifest de A no se mezcla con B;
- no se usa `cancelAll()`;
- legacy queda intacto.

Conclusión:

- validación correcta;
- no se detectó contaminación entre usuarios.

## 8. Timezone / DST

Estado:

- la timezone efectiva se valida antes de programar;
- timezone inválida falla cerrado;
- el executor usa `timezone` con `TZDateTime`.

Cobertura automática existente:

- payload y reconciliación ya cubren casos de timezone inválida;
- renderer y plan builder siguen siendo deterministas en tests.

Validación manual pendiente:

- cambio de timezone real en iPhone;
- spring forward;
- fall back.

Si el dispositivo no permite una validación razonable:

- mantener cobertura determinista por tests.

## 9. Pending capacity

Policy actual validada:

- cap iOS conservador;
- horizon de 24h;
- personalized no supera el cap propio;
- nunca elimina legacy para hacer hueco.

Resultado:

- consistente con la policy documentada;
- sin cambios necesarios.

## 10. Duplicate prevention

Rutas revisadas:

- bootstrap + foreground;
- foreground + habit mutation;
- preferencesChanged + foreground;
- retry tras partial failure.

Mecanismos presentes:

- single-flight;
- fingerprint;
- manifest;
- OS pending;
- reconciliación idempotente.

Resultado:

- no se detectaron duplicados funcionales en la validación automática.

## 11. Settings validation

Validado:

- toggle;
- segmented intensity;
- time picker;
- estado disabled/enabled;
- permission recovery;
- loading / state inicial;
- cambio de usuario.

Resultado:

- sin bugs claros;
- sin necesidad de polish visual adicional.

## 12. Localization / copy

Validación cubierta por tests de renderer:

- los seed templates siguen teniendo `es/en`;
- renderizan sin placeholders;
- no hay claves rotas;
- no aparece contenido técnico.

## 13. Activation readiness classification

Clasificación:

`READY_FOR_MANUAL_QA`

Motivo:

- el pipeline automático está verde;
- el gate sigue OFF por defecto;
- la parte pendiente es validación manual en iPhone real, especialmente permission states, foreground/background, cleanup y timezone/DST.

## 14. Activation steps

Secuencia recomendada:

1. Mantener el gate OFF en producción mientras se completa QA manual.
2. Activar el gate solo en build/dev interno o canal de QA controlado.
3. Ejecutar la checklist iPhone real.
4. Si no aparecen regresiones, activar el gate en producción.
5. Mantener la preferencia del usuario como control final enable/disable.

Sin Remote Config ni Supabase por ahora.

## 15. Riesgos residuales

- DST y cambio de timezone real siguen necesitando validación en dispositivo.
- La capacidad iOS es conservadora y puede requerir ajuste si el tráfico v2 crece.
- El cleanup de logout está validado en tests, pero conviene observarlo una vez en hardware real.
- La activación sigue siendo manual; no hay rollout remoto todavía.
