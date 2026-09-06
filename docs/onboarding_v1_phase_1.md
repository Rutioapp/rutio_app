# Onboarding V1 — Fase 1

La Fase 1 añade el dominio y la persistencia local del `OnboardingDraft`.

## Alcance

El draft se serializa como un único payload JSON bajo una key namespaced de
`SharedPreferences`. El campo `habit` conserva el mapa del contrato local real
de `activeHabits`; no existe un `HabitDraft` alternativo. `reminder` sigue el
mismo enfoque de payload JSON extensible hasta que el contrato funcional de
recordatorios quede definido.

Las versiones actuales viven únicamente en
`OnboardingVersions` (`draftSchemaVersion`, `onboardingVersion` y
`catalogVersion`). Los enums se guardan mediante códigos estables.

## Garantías reales

El payload se valida y se convierte a JSON antes de escribirlo. Una validación o
serialización fallida no toca el valor anterior. La sustitución de la key es la
operación que garantiza `SharedPreferences`; no se simula una transacción de
dos fases ni se promete atomicidad frente a un corte de proceso durante la
escritura.

Los drafts anónimos viven en una key distinta de las keys por usuario. Un draft
con `boundUserId` no se puede guardar en el scope anónimo y una vinculación a
otro usuario falla explícitamente. Los payloads corruptos o de schema futuro
no provocan crash ni se eliminan automáticamente, de modo que la información
original queda disponible para una recuperación posterior.

Los drafts `completed` pueden mantenerse como respaldo técnico durante 24
horas, pero nunca se consideran reanudables. `restart()` elimina el draft
anónimo y crea otro con nuevos IDs y timestamps.

## Integración aplazada

No se modificaron Bootstrap, Welcome, `TemporaryOnboardingScreen`, navegación,
Auth, Supabase, recordatorios, recomendaciones ni analytics. La auditoría
referenciada por el brief (`docs/onboarding_v1_phase_0_audit.md`) no estaba
presente en el checkout al implementar esta fase; se usó la arquitectura real
del repositorio y el resto se deja explícitamente para Fase 2.

