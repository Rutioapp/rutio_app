-- GENERATED FILE. Do not edit manually.
-- Source: supabase/catalog/completed_day_phrase/es-ES.v1.json
-- Regenerate: dart run tool/completed_day_phrase/generate_release_sql.dart supabase/catalog/completed_day_phrase/es-ES.v1.json
-- This file never calls Supabase remotely; apply it only after the migrations.

begin;

-- A published v1 is immutable. Re-running fails as a controlled no-op.
do $$
declare
  v_status text;
  v_entry_count integer;
begin
  select status into v_status
  from public.phrase_catalog_releases
  where locale = 'es-ES' and release_version = 1;
  if v_status = 'published' then
    select count(*) into v_entry_count
    from public.phrase_catalog_release_entries e
    join public.phrase_catalog_releases r on r.id = e.release_id
    where r.locale = 'es-ES' and r.release_version = 1;
    if v_entry_count = 300 then
      raise exception 'completed_day_phrase es-ES v1 is already published; seed aborted as a controlled no-op check';
    end if;
    raise exception 'completed_day_phrase es-ES v1 is published but incomplete; refusing to mutate it';
  end if;
end;
$$;

-- Expected locale-specific release payload.
create temporary table _completed_day_phrase_expected (
  id text primary key,
  category text not null,
  tone text not null,
  source_type text not null,
  author text,
  required_tokens text[] not null,
  weight numeric not null,
  enabled boolean not null,
  template text not null,
  content_version integer not null
) on commit drop;

insert into _completed_day_phrase_expected (
  id, category, tone, source_type, author, required_tokens,
  weight, enabled, template, content_version
) values
  ('personal_001', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, hoy te has demostrado que puedes contar contigo.', 1),
  ('personal_002', 'personal', 'balanced', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, has llegado al {progress}. Disfruta de este momento.', 1),
  ('personal_003', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Buen trabajo, {name}. Hoy también has estado de tu lado.', 1),
  ('personal_004', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, lo que has hecho hoy también construye tu mañana.', 1),
  ('personal_005', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Hoy has sumado otro día del que sentirte orgulloso, {name}.', 1),
  ('personal_006', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, tu esfuerzo de hoy merece un momento de calma.', 1),
  ('personal_007', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, 'Has llegado hasta aquí por ti, {name}. Reconócelo.', 1),
  ('personal_008', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, hoy no necesitabas hacerlo perfecto; solo hacerlo tuyo.', 1),
  ('personal_009', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Este día también lleva tu firma, {name}.', 1),
  ('personal_010', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, guarda esta sensación: eres capaz de avanzar.', 1),
  ('personal_011', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Hoy te elegiste a ti, {name}. Eso también cuenta.', 1),
  ('personal_012', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, tu progreso habla de todo lo que estás cuidando.', 1),
  ('personal_013', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Lo has conseguido a tu manera, {name}, y eso vale mucho.', 1),
  ('personal_014', 'personal', 'energetic', 'original', null, array['name']::text[], 100, true, '{name}, hoy has convertido intención en acción.', 1),
  ('personal_015', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Otro día completo, {name}. Sin ruido, pero con significado.', 1),
  ('personal_016', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, tu mejor ritmo es el que puedes sostener.', 1),
  ('personal_017', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Hoy has dado razones para confiar más en ti, {name}.', 1),
  ('personal_018', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, disfruta del orgullo tranquilo de haber cumplido contigo.', 1),
  ('personal_019', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, 'Lo de hoy puede parecer pequeño, {name}, pero está construyendo algo grande.', 1),
  ('personal_020', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, has llegado al final del día sin dejarte atrás.', 1),
  ('personal_021', 'personal', 'balanced', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Tu racha de {streak_label} cuenta una historia de constancia, {name}.', 1),
  ('personal_022', 'personal', 'gentle', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Tu recorrido de {streak_label} habla mejor que cualquier promesa, {name}.', 1),
  ('personal_023', 'personal', 'gentle', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Llevas {streak_label} eligiendo continuar, {name}.', 1),
  ('personal_024', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, cada día de tu racha confirma que puedes volver a elegirte.', 1),
  ('personal_025', 'personal', 'gentle', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Tu racha de {streak_label} no exige perfección, solo presencia, {name}.', 1),
  ('personal_026', 'personal', 'balanced', 'original', null, array['name', 'streak_label']::text[], 100, true, '{name}, ya son {streak_label} dando forma a una versión más constante de ti.', 1),
  ('personal_027', 'personal', 'balanced', 'original', null, array['streak_label', 'name']::text[], 100, true, 'Detrás de estos {streak_label} hay decisiones que solo tú conoces, {name}.', 1),
  ('personal_028', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, tu racha crece porque tú sigues apareciendo.', 1),
  ('personal_029', 'personal', 'gentle', 'original', null, array['streak_label', 'name']::text[], 100, true, '{streak_label} después, sigues aquí. Buen trabajo, {name}.', 1),
  ('personal_030', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, '{name}, que tu racha te recuerde tu capacidad, no que te presione.', 1),
  ('personal_031', 'personal', 'balanced', 'original', null, array['progress', 'name']::text[], 100, true, 'Hoy tu progreso marca {progress}, {name}. Respira y celébralo.', 1),
  ('personal_032', 'personal', 'gentle', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, {progress} no es solo una cifra: es lo que decidiste cuidar hoy.', 1),
  ('personal_033', 'personal', 'energetic', 'original', null, array['progress', 'name']::text[], 100, true, 'Has alcanzado el {progress}, {name}. Ahora también toca descansar.', 1),
  ('personal_034', 'personal', 'balanced', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, hoy el {progress} tiene tu esfuerzo detrás.', 1),
  ('personal_035', 'personal', 'gentle', 'original', null, array['progress', 'name']::text[], 100, true, 'Tu día está al {progress}, {name}; tu valor nunca dependió de la cifra.', 1),
  ('personal_036', 'personal', 'balanced', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, llegar al {progress} demuestra lo que puedes hacer paso a paso.', 1),
  ('personal_037', 'personal', 'gentle', 'original', null, array['progress', 'name']::text[], 100, true, 'Hoy has cerrado el círculo al {progress}, {name}.', 1),
  ('personal_038', 'personal', 'gentle', 'original', null, array['name', 'progress']::text[], 100, true, '{name}, has llevado tu intención hasta el {progress}.', 1),
  ('personal_039', 'personal', 'energetic', 'original', null, array['progress', 'name']::text[], 100, true, 'El {progress} de hoy es una pequeña victoria que sí merece espacio, {name}.', 1),
  ('personal_040', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, hoy completaste lo previsto y conservaste tu propio ritmo.', 1),
  ('personal_041', 'personal', 'balanced', 'original', null, array['name', 'streak_label', 'progress']::text[], 100, true, '{name}, {streak_label} de constancia y un día al {progress}. Bien hecho.', 1),
  ('personal_042', 'personal', 'balanced', 'original', null, array['progress', 'streak_label', 'name']::text[], 100, true, 'Tu progreso está al {progress} y tu racha en {streak_label}, {name}. Sigue sin prisa.', 1),
  ('personal_043', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, hoy tu constancia y tu progreso han caminado juntos.', 1),
  ('personal_044', 'personal', 'balanced', 'original', null, array['streak_label', 'progress', 'name']::text[], 100, true, '{streak_label} construyendo algo tuyo. Hoy, además, llegaste al {progress}, {name}.', 1),
  ('personal_045', 'personal', 'gentle', 'original', null, array['name', 'progress', 'streak_label']::text[], 100, true, '{name}, el {progress} de hoy se suma a una racha de {streak_label}.', 1),
  ('personal_046', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Hoy has completado tu día sin perder tu esencia, {name}.', 1),
  ('personal_047', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, tu progreso se ve; el esfuerzo que hay detrás también importa.', 1),
  ('personal_048', 'personal', 'gentle', 'original', null, array['name']::text[], 100, true, 'Has hecho tu parte por hoy, {name}. Puedes soltar el día con tranquilidad.', 1),
  ('personal_049', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, '{name}, sigue construyendo desde el cuidado, no desde la exigencia.', 1),
  ('personal_050', 'personal', 'balanced', 'original', null, array['name']::text[], 100, true, 'Hoy has cumplido contigo, {name}. Mañana será una nueva elección.', 1),
  ('consistency_001', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia no hace ruido, pero deja huella.', 1),
  ('consistency_002', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Cada vez que vuelves, fortaleces el camino.', 1),
  ('consistency_003', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo sostenible siempre vale más que lo perfecto.', 1),
  ('consistency_004', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Un día bien cuidado puede cambiar la dirección de una semana.', 1),
  ('consistency_005', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Seguir apareciendo también es una forma de valentía.', 1),
  ('consistency_006', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La repetición convierte lo difícil en familiar.', 1),
  ('consistency_007', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu ritmo no necesita parecerse al de nadie.', 1),
  ('consistency_008', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La continuidad se construye con decisiones pequeñas.', 1),
  ('consistency_009', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'No subestimes el poder de cumplir contigo una vez más.', 1),
  ('consistency_010', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La confianza propia nace de las promesas que sí mantienes.', 1),
  ('consistency_011', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Cada paso repetido abre un camino más claro.', 1),
  ('consistency_012', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia crece mejor sin castigos.', 1),
  ('consistency_013', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Volver cuenta tanto como no haberse detenido.', 1),
  ('consistency_014', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo que repites con cuidado termina formando parte de ti.', 1),
  ('consistency_015', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La disciplina amable también transforma.', 1),
  ('consistency_016', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'No necesitas intensidad todos los días; necesitas una dirección.', 1),
  ('consistency_017', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Las grandes mejoras suelen llegar vestidas de rutina.', 1),
  ('consistency_018', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hoy has reforzado algo que mañana será más natural.', 1),
  ('consistency_019', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Un paso pequeño sigue siendo movimiento.', 1),
  ('consistency_020', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La paciencia permite que el progreso eche raíces.', 1),
  ('consistency_021', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Mantener el rumbo importa más que avanzar deprisa.', 1),
  ('consistency_022', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia es elegir de nuevo, incluso sin emoción.', 1),
  ('consistency_023', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Cada repetición reduce la distancia entre intención e identidad.', 1),
  ('consistency_024', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'No todo avance se nota al instante.', 1),
  ('consistency_025', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Los resultados tardan; la identidad se practica desde hoy.', 1),
  ('consistency_026', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu sistema diario puede llevarte donde la motivación no llega.', 1),
  ('consistency_027', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo que hoy requiere atención mañana puede sentirse natural.', 1),
  ('consistency_028', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Avanzar despacio también protege lo que estás construyendo.', 1),
  ('consistency_029', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'La regularidad da fuerza a los días normales.', 1),
  ('consistency_030', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Una buena dirección compensa muchos pasos lentos.', 1),
  ('consistency_031', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia se reconoce mirando atrás.', 1),
  ('consistency_032', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Repetir con intención es una forma de aprenderte.', 1),
  ('consistency_033', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Cada día no tiene que ser extraordinario para ser valioso.', 1),
  ('consistency_034', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo importante no es hacerlo enorme, sino hacerlo posible.', 1),
  ('consistency_035', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu progreso vive en lo que eliges repetir.', 1),
  ('consistency_036', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La estabilidad se construye antes de sentirse.', 1),
  ('consistency_037', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Cumplir en pequeño entrena la confianza en grande.', 1),
  ('consistency_038', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La mejora duradera rara vez necesita prisa.', 1),
  ('consistency_039', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Un buen hábito es una ayuda, no una deuda.', 1),
  ('consistency_040', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La consistencia también incluye saber adaptar el ritmo.', 1),
  ('consistency_041', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Hacer menos y sostenerlo puede llevarte más lejos.', 1),
  ('consistency_042', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'El camino se vuelve más tuyo cada vez que lo recorres.', 1),
  ('consistency_043', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia no exige días idénticos.', 1),
  ('consistency_044', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Seguir no siempre significa apretar más.', 1),
  ('consistency_045', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Cuidar la frecuencia también es cuidar tu energía.', 1),
  ('consistency_046', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'La repetición consciente convierte acciones en cimientos.', 1),
  ('consistency_047', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu avance se acumula aunque hoy no puedas verlo.', 1),
  ('consistency_048', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo que sostienes con calma gana profundidad.', 1),
  ('consistency_049', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La disciplina funciona mejor cuando cabe en tu vida.', 1),
  ('consistency_050', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Una decisión repetida puede cambiar una historia.', 1),
  ('consistency_051', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Los días sencillos también construyen resultados.', 1),
  ('consistency_052', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hoy has alimentado la versión de ti que quieres conservar.', 1),
  ('consistency_053', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia transforma sin pedir protagonismo.', 1),
  ('consistency_054', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'El progreso real suele parecer normal mientras ocurre.', 1),
  ('consistency_055', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Cada regreso evita que un tropiezo se convierta en abandono.', 1),
  ('consistency_056', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Tu fuerza también está en saber continuar con suavidad.', 1),
  ('consistency_057', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Los hábitos crecen cuando encuentran espacio, no presión.', 1),
  ('consistency_058', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo que haces a menudo pesa más que lo que haces de vez en cuando.', 1),
  ('consistency_059', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La repetición da estabilidad a tus buenas intenciones.', 1),
  ('consistency_060', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Una cadena fuerte se forma enlace a enlace.', 1),
  ('consistency_061', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'No necesitas recuperar el tiempo; solo retomar la dirección.', 1),
  ('consistency_062', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia acepta pausas, pero recuerda el camino.', 1),
  ('consistency_063', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'El progreso se protege mejor con expectativas humanas.', 1),
  ('consistency_064', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Cada día sostenido hace más fácil confiar en el siguiente.', 1),
  ('consistency_065', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Una acción pequeña puede ser una señal poderosa para ti.', 1),
  ('consistency_066', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'El hábito se consolida cuando deja de ser una batalla diaria.', 1),
  ('consistency_067', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La regularidad convierte el esfuerzo en estructura.', 1),
  ('consistency_068', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Avanzar sin agotarte también es avanzar bien.', 1),
  ('consistency_069', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La paciencia es parte del entrenamiento.', 1),
  ('consistency_070', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La continuidad no se rompe por un día difícil.', 1),
  ('consistency_071', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu sistema debe apoyarte también cuando baja la motivación.', 1),
  ('consistency_072', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Una base tranquila puede sostener cambios profundos.', 1),
  ('consistency_073', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'El compromiso más útil es el que puedes renovar mañana.', 1),
  ('consistency_074', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Cada día suma contexto, experiencia y confianza.', 1),
  ('consistency_075', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia no busca impresionar; busca permanecer.', 1),
  ('consistency_076', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu ritmo estable puede vencer a muchos impulsos breves.', 1),
  ('consistency_077', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Hoy has hecho más fácil volver a hacerlo.', 1),
  ('consistency_078', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Lo repetido con sentido termina dejando identidad.', 1),
  ('consistency_079', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Mantener una práctica es también aprender a cuidarla.', 1),
  ('consistency_080', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Los pequeños cumplimientos reducen la distancia con tus metas.', 1),
  ('consistency_081', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Ser constante no significa ser inflexible.', 1),
  ('consistency_082', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Una rutina sana se adapta sin perder su intención.', 1),
  ('consistency_083', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La continuidad se mide en meses, no en momentos aislados.', 1),
  ('consistency_084', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo que sostienes termina sosteniéndote.', 1),
  ('consistency_085', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La práctica diaria afina incluso lo que no puedes medir.', 1),
  ('consistency_086', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Cada decisión coherente refuerza la siguiente.', 1),
  ('consistency_087', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'Un día completo no define todo, pero sí añade una pieza.', 1),
  ('consistency_088', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia convierte el deseo en evidencia.', 1),
  ('consistency_089', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Lo que hoy eliges repetir puede facilitarte el futuro.', 1),
  ('consistency_090', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La disciplina no tiene que doler para funcionar.', 1),
  ('consistency_091', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu progreso necesita espacio para ser lento.', 1),
  ('consistency_092', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'La mejor cadena es la que no te encadena.', 1),
  ('consistency_093', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La continuidad nace de volver a empezar las veces necesarias.', 1),
  ('consistency_094', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Los días imperfectos también pueden mantener una dirección.', 1),
  ('consistency_095', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La repetición amable es una inversión en tu bienestar.', 1),
  ('consistency_096', 'consistency', 'energetic', 'original', null, '{}'::text[], 100, true, 'Cada acción coherente vota por la persona que quieres ser.', 1),
  ('consistency_097', 'consistency', 'gentle', 'original', null, '{}'::text[], 100, true, 'No midas solo la velocidad; mira cuánto has sostenido.', 1),
  ('consistency_098', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'La constancia crece cuando el plan respeta tu realidad.', 1),
  ('consistency_099', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Mantenerte presente vale más que exigirte impecabilidad.', 1),
  ('consistency_100', 'consistency', 'balanced', 'original', null, '{}'::text[], 100, true, 'Lo construido poco a poco suele resistir mejor.', 1),
  ('motivation_001', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hoy también puede ser un buen punto de partida.', 1),
  ('motivation_002', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo que viene no está escrito; todavía puedes influir en ello.', 1),
  ('motivation_003', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Tu energía merece una dirección que te haga bien.', 1),
  ('motivation_004', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hay más posibilidades delante de ti de las que ves ahora.', 1),
  ('motivation_005', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Confía en la parte de ti que decidió intentarlo.', 1),
  ('motivation_006', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'No necesitas tenerlo todo claro para dar el siguiente paso.', 1),
  ('motivation_007', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Haz espacio para reconocer lo que sí estás logrando.', 1),
  ('motivation_008', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu esfuerzo cuenta incluso cuando nadie lo ve.', 1),
  ('motivation_009', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hoy puedes estar orgulloso sin tener que demostrar nada.', 1),
  ('motivation_010', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo que haces por ti también transforma tu entorno.', 1),
  ('motivation_011', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Permítete avanzar sin pedir permiso a la duda.', 1),
  ('motivation_012', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu historia todavía tiene muchas páginas abiertas.', 1),
  ('motivation_013', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'El próximo paso no tiene que ser grande; solo honesto.', 1),
  ('motivation_014', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tienes derecho a crecer a tu propio ritmo.', 1),
  ('motivation_015', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Descansar después de avanzar también forma parte del camino.', 1),
  ('motivation_016', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu capacidad no desaparece en los días difíciles.', 1),
  ('motivation_017', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'A veces, la victoria es terminar el día en paz contigo.', 1),
  ('motivation_018', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No olvides mirar cuánto has cambiado ya.', 1),
  ('motivation_019', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'La versión de ti que buscas también se está acercando.', 1),
  ('motivation_020', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Puedes sentir miedo y seguir avanzando.', 1),
  ('motivation_021', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu mejor momento no tiene por qué haber pasado.', 1),
  ('motivation_022', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Haz que la esperanza tenga hoy una acción concreta.', 1),
  ('motivation_023', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Eres más que cualquier día complicado.', 1),
  ('motivation_024', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu futuro agradecerá la atención que te das hoy.', 1),
  ('motivation_025', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No te hace falta una señal perfecta para continuar.', 1),
  ('motivation_026', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Tu forma de intentarlo también merece respeto.', 1),
  ('motivation_027', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Hay fuerza en elegirte incluso cuando cuesta.', 1),
  ('motivation_028', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'No minimices el valor de haber llegado hasta aquí.', 1),
  ('motivation_029', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Puedes cambiar de dirección sin haber perdido el camino.', 1),
  ('motivation_030', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'El día de hoy también puede dejarte algo bueno.', 1),
  ('motivation_031', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu voz interior también puede aprender a cuidarte.', 1),
  ('motivation_032', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo posible empieza cuando dejas espacio para probar.', 1),
  ('motivation_033', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No necesitas correr para acercarte a lo que importa.', 1),
  ('motivation_034', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Agradece tu esfuerzo antes de exigir el siguiente.', 1),
  ('motivation_035', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Dentro de ti ya existe la capacidad de empezar otra vez.', 1),
  ('motivation_036', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hazlo por la tranquilidad de saber que lo intentaste.', 1),
  ('motivation_037', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu camino puede ser distinto y seguir siendo válido.', 1),
  ('motivation_038', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Hay días para conquistar y días para conservar fuerzas.', 1),
  ('motivation_039', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Una decisión valiente puede ser simplemente no rendirte hoy.', 1),
  ('motivation_040', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu progreso no tiene que ser visible para ser real.', 1),
  ('motivation_041', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'No dejes que una duda momentánea decida tu dirección.', 1),
  ('motivation_042', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Lo que cuidas hoy puede sostenerte mañana.', 1),
  ('motivation_043', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tú también mereces beneficiarte de tu esfuerzo.', 1),
  ('motivation_044', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Sigue construyendo una vida en la que puedas respirar.', 1),
  ('motivation_045', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'La calma también puede ser una forma de poder.', 1),
  ('motivation_046', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu siguiente capítulo no necesita repetir el anterior.', 1),
  ('motivation_047', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'No estás llegando tarde a tu propia vida.', 1),
  ('motivation_048', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'A veces avanzar consiste en soltar lo que ya pesa demasiado.', 1),
  ('motivation_049', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Haz sitio para la persona que estás llegando a ser.', 1),
  ('motivation_050', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'La confianza crece cuando actúas a pesar de la incertidumbre.', 1),
  ('motivation_051', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hoy has hecho algo que tu yo de antes quizá veía difícil.', 1),
  ('motivation_052', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu valor no disminuye cuando necesitas una pausa.', 1),
  ('motivation_053', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'La dirección correcta puede sentirse lenta al principio.', 1),
  ('motivation_054', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No todo tiene que resolverse hoy para que hoy haya valido.', 1),
  ('motivation_055', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'La vida también cambia con elecciones discretas.', 1),
  ('motivation_056', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Puedes ser amable contigo y seguir siendo ambicioso.', 1),
  ('motivation_057', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No renuncies a una posibilidad solo porque todavía no la dominas.', 1),
  ('motivation_058', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu esfuerzo merece continuidad, no castigo.', 1),
  ('motivation_059', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'La incomodidad de crecer no dura para siempre.', 1),
  ('motivation_060', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Cuando te tratas mejor, también decides mejor.', 1),
  ('motivation_061', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'No hace falta sentirte invencible para actuar con valentía.', 1),
  ('motivation_062', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu camino no pierde valor porque tenga curvas.', 1),
  ('motivation_063', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Cada etapa te enseña una forma distinta de avanzar.', 1),
  ('motivation_064', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Lo que hoy parece lejano puede empezar con una sola elección.', 1),
  ('motivation_065', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tienes permiso para celebrar antes de llegar a la meta final.', 1),
  ('motivation_066', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'El orgullo sano también alimenta el próximo paso.', 1),
  ('motivation_067', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No conviertas tus metas en una razón para dejar de cuidarte.', 1),
  ('motivation_068', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu vida mejora cuando tus decisiones también te incluyen.', 1),
  ('motivation_069', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'La motivación puede empezar después de la acción.', 1),
  ('motivation_070', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'No esperes a sentirte listo para darte una oportunidad.', 1),
  ('motivation_071', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Tu intención merece una oportunidad real.', 1),
  ('motivation_072', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hoy puedes cerrar el día sabiendo que aportaste algo bueno.', 1),
  ('motivation_073', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Una mente cansada también merece palabras amables.', 1),
  ('motivation_074', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No dejes que la comparación borre tu propio recorrido.', 1),
  ('motivation_075', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Lo que te cuesta también puede estar fortaleciéndote.', 1),
  ('motivation_076', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu forma de avanzar puede evolucionar contigo.', 1),
  ('motivation_077', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No estás obligado a ser la misma persona que ayer.', 1),
  ('motivation_078', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Hay decisiones pequeñas que cambian la forma de verte.', 1),
  ('motivation_079', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Puedes elegir una vida más tuya, paso a paso.', 1),
  ('motivation_080', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu bienestar no es una recompensa; es parte del camino.', 1),
  ('motivation_081', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Que el miedo tenga voz no significa que tenga el mando.', 1),
  ('motivation_082', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu esfuerzo de hoy puede abrirte opciones mañana.', 1),
  ('motivation_083', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No necesitas una versión perfecta de ti para empezar a cuidarte.', 1),
  ('motivation_084', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Lo que haces con intención tiene una fuerza especial.', 1),
  ('motivation_085', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Deja que tus avances también ocupen espacio en tu memoria.', 1),
  ('motivation_086', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Puedes seguir queriendo más y valorar lo que ya tienes.', 1),
  ('motivation_087', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Una pausa consciente puede devolverte dirección.', 1),
  ('motivation_088', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No todo lo valioso produce resultados inmediatos.', 1),
  ('motivation_089', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu presente también merece atención, no solo tus metas.', 1),
  ('motivation_090', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Hay algo poderoso en decidir continuar con calma.', 1),
  ('motivation_091', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No permitas que un mal momento defina todo el día.', 1),
  ('motivation_092', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Puedes aprender sin hablarte con dureza.', 1),
  ('motivation_093', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu capacidad crece cada vez que atraviesas algo nuevo.', 1),
  ('motivation_094', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Haz que tu siguiente decisión esté a favor de ti.', 1),
  ('motivation_095', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'No necesitas ganar todos los días para construir una buena vida.', 1),
  ('motivation_096', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Tu energía es limitada; úsala en algo que te acerque a ti.', 1),
  ('motivation_097', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'A veces el cambio empieza al dejar de posponer tu bienestar.', 1),
  ('motivation_098', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Todavía puedes sorprenderte con lo que eres capaz de hacer.', 1),
  ('motivation_099', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu vida no necesita parecer perfecta para sentirse significativa.', 1),
  ('motivation_100', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Elige una razón que te ayude a volver mañana.', 1),
  ('motivation_101', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No estás empezando de cero; empiezas con experiencia.', 1),
  ('motivation_102', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu perspectiva puede cambiar antes que tus circunstancias.', 1),
  ('motivation_103', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Hay fuerza en reconocer que hoy lo hiciste bien.', 1),
  ('motivation_104', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'No todo reto exige más fuerza; algunos piden más paciencia.', 1),
  ('motivation_105', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Tu siguiente oportunidad puede nacer de lo que aprendiste hoy.', 1),
  ('motivation_106', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Atrévete a construir algo que también te cuide.', 1),
  ('motivation_107', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No confundas ir despacio con estar detenido.', 1),
  ('motivation_108', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'La forma en que te acompañas importa tanto como la meta.', 1),
  ('motivation_109', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Hoy puedes elegir avanzar sin pelearte contigo.', 1),
  ('motivation_110', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu potencial también necesita descanso para desplegarse.', 1),
  ('motivation_111', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'El cambio real suele empezar de manera discreta.', 1),
  ('motivation_112', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No dejes para después el reconocimiento que mereces hoy.', 1),
  ('motivation_113', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu camino se aclara mientras lo recorres.', 1),
  ('motivation_114', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'La valentía también puede hablar en voz baja.', 1),
  ('motivation_115', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Haz algo hoy que te ayude a confiar en mañana.', 1),
  ('motivation_116', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu vida puede hacerse más ligera sin hacerse más pequeña.', 1),
  ('motivation_117', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'No necesitas justificar cada paso que das por ti.', 1),
  ('motivation_118', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'La esperanza se fortalece cuando la conviertes en movimiento.', 1),
  ('motivation_119', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Puedes transformar presión en una dirección más amable.', 1),
  ('motivation_120', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu mejor respuesta a la duda puede ser seguir probando.', 1),
  ('motivation_121', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No te exijas florecer en todas las estaciones.', 1),
  ('motivation_122', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Hay progreso en aprender cuándo insistir y cuándo ajustar.', 1),
  ('motivation_123', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Tu esfuerzo no necesita aplausos para tener valor.', 1),
  ('motivation_124', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hoy también has acumulado experiencia para lo que viene.', 1),
  ('motivation_125', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'No temas empezar pequeño; teme no darte la oportunidad.', 1),
  ('motivation_126', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'La energía que inviertes en ti nunca es completamente perdida.', 1),
  ('motivation_127', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Puedes reconocer el cansancio sin renunciar a tus sueños.', 1),
  ('motivation_128', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Lo que hoy eliges creer sobre ti puede cambiar tus próximos pasos.', 1),
  ('motivation_129', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'No tienes que resolver tu vida; solo cuidar la siguiente decisión.', 1),
  ('motivation_130', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Tu avance puede ser silencioso y aun así profundo.', 1),
  ('motivation_131', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'Hay días que no cambian todo, pero cambian algo importante.', 1),
  ('motivation_132', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Permítete sentir satisfacción por el camino recorrido.', 1),
  ('motivation_133', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'No esperes a la meta para tratarte como alguien valioso.', 1),
  ('motivation_134', 'motivation', 'gentle', 'original', null, '{}'::text[], 100, true, 'La determinación funciona mejor cuando también escucha.', 1),
  ('motivation_135', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Tu próximo intento llegará con más experiencia que el anterior.', 1),
  ('motivation_136', 'motivation', 'balanced', 'original', null, '{}'::text[], 100, true, 'Lo que estás construyendo merece tiempo para madurar.', 1),
  ('motivation_137', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'No abandones una buena dirección por una jornada difícil.', 1),
  ('motivation_138', 'motivation', 'energetic', 'original', null, '{}'::text[], 100, true, 'Sigue: quizá estás más cerca de lo que ahora puedes medir.', 1),
  ('motivation_139', 'motivation', 'energetic', 'proverb', 'Refrán popular', '{}'::text[], 100, true, 'Quien la sigue, la consigue.', 1),
  ('motivation_140', 'motivation', 'balanced', 'proverb', 'Proverbio tradicional', '{}'::text[], 100, true, 'Poco a poco se llega lejos.', 1),
  ('motivation_141', 'motivation', 'energetic', 'proverb', 'Refrán popular', '{}'::text[], 100, true, 'La práctica hace al maestro.', 1),
  ('motivation_142', 'motivation', 'energetic', 'proverb', 'Proverbio latino', '{}'::text[], 100, true, 'La fortuna favorece a los audaces.', 1),
  ('motivation_143', 'motivation', 'balanced', 'proverb', 'Refrán popular', '{}'::text[], 100, true, 'Después de la tormenta llega la calma.', 1),
  ('motivation_144', 'motivation', 'gentle', 'proverb', 'Refrán popular', '{}'::text[], 100, true, 'Mientras hay vida, hay esperanza.', 1),
  ('motivation_145', 'motivation', 'energetic', 'proverb', 'Refrán popular', '{}'::text[], 100, true, 'El que persevera, alcanza.', 1),
  ('motivation_146', 'motivation', 'gentle', 'proverb', 'Refrán popular', '{}'::text[], 100, true, 'No hay mal que por bien no venga.', 1),
  ('motivation_147', 'motivation', 'energetic', 'proverb', 'Refrán popular', '{}'::text[], 100, true, 'La unión hace la fuerza.', 1),
  ('motivation_148', 'motivation', 'balanced', 'proverb', 'Refrán popular', '{}'::text[], 100, true, 'Más vale paso que dure que trote que canse.', 1),
  ('motivation_149', 'motivation', 'balanced', 'quote', 'Antonio Machado', '{}'::text[], 100, true, 'Caminante, no hay camino, se hace camino al andar.', 1),
  ('motivation_150', 'motivation', 'gentle', 'quote', 'Máxima délfica', '{}'::text[], 100, true, 'Conócete a ti mismo.', 1)
;

-- Existing base metadata must match; it is never overwritten.
do $$
begin
  if exists (
    select 1
    from _completed_day_phrase_expected e
    left join public.motivational_phrases p on p.id = e.id
    where p.id is null
  ) then
    raise exception 'Missing motivational phrase base metadata.';
  end if;
  if exists (
    select 1
    from _completed_day_phrase_expected e
    join public.motivational_phrases p on p.id = e.id
    where p.category is distinct from e.category
       or p.tone is distinct from e.tone
       or p.source_type is distinct from e.source_type
       or p.required_tokens is distinct from e.required_tokens
       or p.weight is distinct from e.weight
  ) then
    raise exception 'Motivational phrase structural metadata mismatch.';
  end if;
end;
$$;

insert into public.motivational_phrases (
  id, category, tone, source_type, author, required_tokens, weight, enabled
)
select id, category, tone, source_type, author, required_tokens, weight, enabled
from _completed_day_phrase_expected
on conflict (id) do nothing;

insert into public.motivational_phrase_translations (
  phrase_id, locale, template, review_status, translator_note, content_version
)
select id, 'es-ES', template, 'reviewed', null, content_version
from _completed_day_phrase_expected
on conflict (phrase_id, locale) do update set
  template = excluded.template,
  review_status = excluded.review_status,
  translator_note = excluded.translator_note,
  content_version = excluded.content_version;

create temporary table _completed_day_phrase_seed_release (
  release_id uuid primary key
) on commit drop;

do $$
declare
  v_release_id uuid;
begin
  select id into v_release_id
  from public.phrase_catalog_releases
  where locale = 'es-ES' and release_version = 1;
  if v_release_id is null then
    insert into public.phrase_catalog_releases (locale, release_version, schema_version, status, is_current)
    values ('es-ES', 1, 1, 'draft', false)
    returning id into v_release_id;
  else
    update public.phrase_catalog_releases
    set schema_version = 1, status = 'draft', is_current = false, published_at = null
    where id = v_release_id;
  end if;
  insert into _completed_day_phrase_seed_release values (v_release_id);
end;
$$;

delete from public.phrase_catalog_release_entries
where release_id = (select release_id from _completed_day_phrase_seed_release);

insert into public.phrase_catalog_release_entries (
  release_id, phrase_id, category, tone, source_type, author, template,
  required_tokens, weight, enabled, content_version
)
select
  s.release_id, e.id, e.category, e.tone, e.source_type, e.author, e.template,
  e.required_tokens, e.weight, e.enabled, e.content_version
from _completed_day_phrase_seed_release s
join _completed_day_phrase_expected e on true;

-- Pre-publication integrity checks.
do $$
declare
  v_release_id uuid;
  v_count integer;
begin
  select release_id into v_release_id from _completed_day_phrase_seed_release;
  select count(*) into v_count from public.motivational_phrase_translations t
    join _completed_day_phrase_expected e on e.id = t.phrase_id
    where t.locale = 'es-ES';
  if v_count <> 300 then raise exception 'Expected 300 es-ES translations, got %', v_count; end if;
  select count(*) into v_count from public.phrase_catalog_release_entries where release_id = v_release_id;
  if v_count <> 300 then raise exception 'Expected 300 es-ES release entries, got %', v_count; end if;
  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'personal') <> 50 then raise exception 'Expected 50 personal entries'; end if;
  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'consistency') <> 100 then raise exception 'Expected 100 consistency entries'; end if;
  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'motivation') <> 150 then raise exception 'Expected 150 motivation entries'; end if;
  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and btrim(template) = '') then raise exception 'Empty release template'; end if;
  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and weight <= 0) then raise exception 'Invalid release weight'; end if;
  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and content_version <= 0) then raise exception 'Invalid release content version'; end if;
  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and not (required_tokens <@ array['name', 'streak_label', 'progress']::text[])) then raise exception 'Invalid required token'; end if;
  if (select count(distinct phrase_id) from public.phrase_catalog_release_entries where release_id = v_release_id) <> 300 then raise exception 'Duplicate release phrase IDs'; end if;
end;
$$;

update public.phrase_catalog_releases set is_current = false where locale = 'es-ES' and status = 'published' and is_current = true and id <> (select release_id from _completed_day_phrase_seed_release);
update public.phrase_catalog_releases set status = 'published', published_at = now(), is_current = true where id = (select release_id from _completed_day_phrase_seed_release);

commit;
