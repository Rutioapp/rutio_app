# Flexible Weekly Check — Weekly Report Deploy Checklist

Checklist para revisión y despliegue controlado de WR-FLEX-4. La migración
debe aplicarse solo tras aprobación explícita del entorno y del proyecto. No se
ejecutó ningún despliegue remoto como parte de esta tarea.

## Pre-deploy

- [ ] Confirmar la rama y revisar el estado de trabajo antes de empaquetar;
      conservar cualquier cambio no relacionado del worktree.
- [ ] Confirmar que la migración preparada es exactamente
      `supabase/migrations/20260907100000_weekly_report_flexible_canonical_backend_v1.sql`.
- [ ] Confirmar que el cliente que se va a distribuir entiende los payloads
      legacy y política 2 antes de modificar el backend.
- [ ] Ejecutar las suites de Weekly Report, dominio relacionado y migración
      estática del pipeline CI.
- [ ] Verificar de forma independiente el proyecto Supabase, organización,
      ref y entorno de destino; no reutilizar credenciales de otro entorno.
- [ ] Confirmar backup/export y un contacto responsable del rollback.
- [ ] Revisar que la compatibilidad v1/v2 y la protección de snapshots finales
      están cubiertas antes de aprobar el cambio.

## Orden recomendado

1. Publicar primero el cliente compatible con payload legacy y política 2.
2. Confirmar que la versión cliente está estable y que los reportes legacy se
   pueden leer.
3. Aplicar después la migración backend en el proyecto Supabase verificado.
4. Ejecutar smoke checks y la matriz manual de
   `flexible_weekly_check_weekly_report_manual_qa.md`.
5. Habilitar el flujo para usuarios solo después de revisar los resultados.

## Comandos preparados, no ejecutados aquí

En PowerShell, con valores revisados por la persona responsable:

```powershell
$env:SUPABASE_PROJECT_REF = "<project-ref-verificado>"
supabase login
supabase link --project-ref $env:SUPABASE_PROJECT_REF
supabase migration list --linked
supabase db push --linked
supabase migration list --linked
```

Estos comandos son una receta de despliegue, no una autorización. En esta
tarea no se ejecutaron `supabase login`, `supabase link` ni `supabase db push`.

## Post-deploy

- [ ] Comprobar que el RPC de lectura devuelve reportes legacy y política 2.
- [ ] Comprobar 2/3, 3/3, 4/3, skip, neutral, semana parcial, cambio de
      configuración, archive y semana actual provisional.
- [ ] Comprobar que un reporte final no cambia al repetir refresh.
- [ ] Comprobar caché offline, deep link de notificación, historial y layout
      compacto en un dispositivo real.
- [ ] Revisar logs de RPC y errores de payload durante el primer periodo de
      observación.

## Rollback

- [ ] Detener la promoción del cliente si falla el smoke test.
- [ ] No usar `supabase db reset` en un proyecto compartido.
- [ ] Esta migración no aporta un rollback automático: si se requiere revertir
      funciones, preparar y revisar una migración correctiva desde la versión
      etiquetada anterior, preservando los snapshots finales y los datos
      aditivos.
- [ ] Si hubiera corrupción de datos, usar el backup aprobado y el procedimiento
      de recuperación del entorno; documentar la decisión antes de ejecutarla.
- [ ] Repetir los checks de lectura legacy y de inmutabilidad después de
      cualquier corrección.
