// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get weeklyReportTitle => 'Tu semana';

  @override
  String get weeklyReportFinalLabel => 'Cerrado';

  @override
  String get weeklyReportSummary => 'Resumen semanal';

  @override
  String get weeklyReportCompleted => 'completados';

  @override
  String get weeklyReportCompletion => 'cumplimiento';

  @override
  String get weeklyReportBestDay => 'mejor día';

  @override
  String get weeklyReportDaily => 'Tu semana día a día';

  @override
  String get weeklyReportNoScheduled => 'Sin hábitos programados';

  @override
  String get weeklyReportProvisionalMessage =>
      'Reporte provisional · Se actualizará durante el domingo';

  @override
  String get weeklyReportFirstWeek => 'Tu primera semana en Rutio';

  @override
  String get weeklyReportOffline => 'Sin conexión · mostrando datos guardados';

  @override
  String get weeklyReportTrendStable =>
      'Sin cambios respecto a la semana anterior';

  @override
  String get weeklyReportTrendCompared => 'respecto a la semana anterior';

  @override
  String get weeklyReportOf => 'de';

  @override
  String get weeklyReportEmpty => 'Tu reporte todavía no está disponible.';

  @override
  String get weeklyReportError => 'No se ha podido cargar tu reporte.';

  @override
  String get weeklyReportRetry => 'Reintentar';

  @override
  String get weeklyReportHabitsTitle => 'Hábitos de la semana';

  @override
  String get weeklyReportHabitFeatured => 'Destacado';

  @override
  String get weeklyReportHabitStable => 'Estable';

  @override
  String get weeklyReportHabitNeedsAttention => 'Necesita atención';

  @override
  String get weeklyReportHabitNoSchedule => 'Sin programación';

  @override
  String get weeklyReportHabitCompleted => 'Completado';

  @override
  String get weeklyReportHabitSkipped => 'Omitido';

  @override
  String get weeklyReportHabitPartial => 'Parcial';

  @override
  String get weeklyReportHabitNoActivity => 'Sin actividad';

  @override
  String get weeklyReportHabitStreak => 'racha';

  @override
  String get weeklyReportHabitGroupFeatured => 'Destacados';

  @override
  String get weeklyReportHabitGroupFeaturedSubtitle =>
      'Tus hábitos con mejor semana';

  @override
  String get weeklyReportHabitGroupStable => 'Estables';

  @override
  String get weeklyReportHabitGroupStableSubtitle =>
      'Mantuvieron un buen ritmo';

  @override
  String get weeklyReportHabitGroupNeedsAttention => 'Necesitan atención';

  @override
  String get weeklyReportHabitGroupNeedsAttentionSubtitle =>
      'Los que más pueden mejorar';

  @override
  String get weeklyReportHabitUnavailable => 'Sin programación esta semana';

  @override
  String get weeklyReportHabitCountUnit => 'hábitos';

  @override
  String get weeklyReportHabitExpanded => 'Expandido';

  @override
  String get weeklyReportHabitCollapsed => 'Contraído';

  @override
  String get weeklyReportHabitExpand => 'Expandir';

  @override
  String get weeklyReportHabitCollapse => 'Contraer';

  @override
  String weeklyReportHabitDayCompleted(Object day) {
    return '$day: completado';
  }

  @override
  String weeklyReportHabitDayIncomplete(Object day) {
    return '$day: pendiente';
  }

  @override
  String weeklyReportHabitDaySkipped(Object day) {
    return '$day: omitido';
  }

  @override
  String weeklyReportHabitDayPartial(Object day) {
    return '$day: parcial';
  }

  @override
  String weeklyReportHabitDayNoSchedule(Object day) {
    return '$day: sin programación';
  }

  @override
  String weeklyReportHabitDayNoActivity(Object day) {
    return '$day: sin actividad';
  }

  @override
  String get splashTagline => 'CONSTRUYE TU CAMINO';

  @override
  String get splashTapToStart => 'TOCA PARA COMENZAR';

  @override
  String get welcomeBrand => 'RUTIO';

  @override
  String get welcomeTitleLine1 => 'Tu camino\n';

  @override
  String get welcomeTitleLine2 => 'empieza hoy.';

  @override
  String get welcomeSubtitle => 'Pequeños pasos,\ngrandes cambios.';

  @override
  String get welcomeLoginButton => 'Iniciar sesión';

  @override
  String get welcomeSignupButton => 'Crear cuenta';

  @override
  String get loginHeaderSubtitle => 'Bienvenido de vuelta';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginSubtitle => 'Continúa donde lo dejaste';

  @override
  String get loginPasswordHint => '••••••••';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginPrimaryCta => 'Continuar →';

  @override
  String get loginSwitchPrefix => '¿No tienes cuenta?  ';

  @override
  String get loginSwitchLink => 'Regístrate';

  @override
  String get signupHeaderSubtitle => 'Empieza tu camino';

  @override
  String get signupTitle => 'Crear cuenta';

  @override
  String get signupSubtitle => 'Un pequeño paso hacia tus metas';

  @override
  String get signupNameLabel => 'Nombre';

  @override
  String get signupNameHint => '¿Cómo te llamas?';

  @override
  String get signupPasswordHint => 'Mín. 8 caracteres';

  @override
  String get signupPrimaryCta => 'Comenzar →';

  @override
  String get signupSwitchPrefix => '¿Ya tienes cuenta?  ';

  @override
  String get signupSwitchLink => 'Inicia sesión';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get fieldEmailHint => 'tu@email.com';

  @override
  String get fieldPasswordLabel => 'Contraseña';

  @override
  String homeErrorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get homeFallbackUsername => 'Usuario';

  @override
  String get homeFallbackHabitTitle => 'Hábito';

  @override
  String get homeHabitCompletionBurstDefault => '+XP';

  @override
  String get homeCompletedLabel => 'Completados ';

  @override
  String homeCompletedCount(String count) {
    return 'Completados ($count)';
  }

  @override
  String homeSkippedCount(String count) {
    return 'Skipeados ($count)';
  }

  @override
  String get homeSkippedToday => 'Omitido hoy';

  @override
  String get homeEmptyStateMultiline =>
      'Aún no tienes hábitos activos.\nPulsa “Nuevo” para añadir el primero.';

  @override
  String get homeEmptyStateSingleLine =>
      'Aún no tienes hábitos activos. Pulsa “Nuevo” para añadir el primero.';

  @override
  String get homeEditCounterTitle => 'Editar contador';

  @override
  String get homeEditCounterHint => 'Introduce un número';

  @override
  String get homeInputValueHint => 'Introduce un valor';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get homeSwipeActionSkip => 'Saltar';

  @override
  String get homeSwipeActionEdit => 'Editar';

  @override
  String get homeSwipeActionDelete => 'Eliminar';

  @override
  String get homeSwipeDeleteConfirmTitle => 'Eliminar hábito';

  @override
  String get homeSwipeDeleteConfirmBody =>
      'Se borrará el hábito y su historial. Esta acción no se puede deshacer.';

  @override
  String get homeSwipeDeleteConfirmAction => 'Eliminar';

  @override
  String get levelUpNormalTitle => 'Enhorabuena';

  @override
  String levelUpNormalSubtitle(int level) {
    return 'Has subido al nivel $level.';
  }

  @override
  String get levelUpFirstMilestoneTitle => 'Primer gran hito';

  @override
  String levelUpFirstMilestoneSubtitle(int level) {
    return 'Has alcanzado el nivel $level. Tus rutinas empiezan a tomar forma.';
  }

  @override
  String get levelUpMajorMilestoneTitle => 'Nuevo hito alcanzado';

  @override
  String levelUpMajorMilestoneSubtitle(int level) {
    return 'Has llegado al nivel $level. Tu constancia sigue creciendo.';
  }

  @override
  String get levelUpContinueButton => 'Continuar';

  @override
  String get levelUpShareButton => 'Compartir';

  @override
  String levelUpRewardAmbarLine(int amount) {
    return 'Has recibido $amount Ámbar.';
  }

  @override
  String homeHabitCountProgress(String current, String target) {
    return '$current de $target';
  }

  @override
  String homeHabitCountProgressWithUnit(
      String current, String target, String unit) {
    return '$current de $target $unit';
  }

  @override
  String homeTimesPerWeekProgress(String completed, String target) {
    return '$completed/$target esta semana';
  }

  @override
  String get homeAddHabitLoadError => 'No se pudo cargar el catálogo';

  @override
  String homeAddHabitCreated(String name) {
    return 'Se ha creado \"$name\"';
  }

  @override
  String get homeAddHabitCreatedGeneric => 'Hábito creado';

  @override
  String get homeAddHabitCreateFromScratch => 'Crear hábito desde cero';

  @override
  String get habitConfigTypeSection => 'Tipo';

  @override
  String get habitConfigCheckOption => 'Check';

  @override
  String get habitConfigCounterOption => 'Contador';

  @override
  String get habitConfigGoalSection => 'Objetivo';

  @override
  String habitConfigGoalSectionWithUnit(String unit) {
    return 'Objetivo ($unit)';
  }

  @override
  String get habitConfigFrequencySection => 'Frecuencia';

  @override
  String get habitConfigDailyOption => 'Diario';

  @override
  String get habitConfigWeeklyOption => 'Semanal';

  @override
  String get habitConfigOnceOption => 'Una vez';

  @override
  String get habitConfigDaysSection => 'Días';

  @override
  String get habitConfigDateSection => 'Fecha';

  @override
  String get habitConfigChooseDate => 'Elegir fecha';

  @override
  String get habitConfigInvalidGoal => 'Pon un objetivo válido (mayor que 0).';

  @override
  String get habitConfigSelectDay => 'Selecciona al menos un día.';

  @override
  String get habitConfigSelectDate => 'Selecciona una fecha.';

  @override
  String get weekdayShortMon => 'Lun';

  @override
  String get weekdayShortTue => 'Mar';

  @override
  String get weekdayShortWed => 'Mié';

  @override
  String get weekdayShortThu => 'Jue';

  @override
  String get weekdayShortFri => 'Vie';

  @override
  String get weekdayShortSat => 'Sáb';

  @override
  String get weekdayShortSun => 'Dom';

  @override
  String get weekdayLetterMon => 'L';

  @override
  String get weekdayLetterTue => 'M';

  @override
  String get weekdayLetterWed => 'X';

  @override
  String get weekdayLetterThu => 'J';

  @override
  String get weekdayLetterFri => 'V';

  @override
  String get weekdayLetterSat => 'S';

  @override
  String get weekdayLetterSun => 'D';

  @override
  String get unitTimesShort => 'veces';

  @override
  String get unitMinutesShort => 'min';

  @override
  String get unitHoursShort => 'h';

  @override
  String get unitPagesShort => 'páginas';

  @override
  String get unitStepsShort => 'pasos';

  @override
  String get unitKilometersShort => 'km';

  @override
  String get unitLitersShort => 'L';

  @override
  String habitUnitLabel(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'times': 'veces',
        'minutes': 'min',
        'mins': 'min',
        'min': 'min',
        'hours': 'h',
        'hour': 'h',
        'h': 'h',
        'pages': 'páginas',
        'page': 'páginas',
        'steps': 'pasos',
        'step': 'pasos',
        'km': 'km',
        'liters': 'L',
        'liter': 'L',
        'l': 'L',
        'other': '$unit',
      },
    );
    return '$_temp0';
  }

  @override
  String get familyMindName => 'Mente';

  @override
  String get familySpiritName => 'Espíritu';

  @override
  String get familyBodyName => 'Cuerpo';

  @override
  String get familyEmotionalName => 'Emocional';

  @override
  String get familySocialName => 'Social';

  @override
  String get familyDisciplineName => 'Disciplina';

  @override
  String get familyProfessionalName => 'Profesional';

  @override
  String get catalogHabitLeerXMinutos => 'Leer';

  @override
  String catalogHabitLeerXMinutosTarget(String target) {
    return 'Leer $target minutos';
  }

  @override
  String get catalogHabitResolverProblemaLogico =>
      'Resolver un problema lógico';

  @override
  String get catalogHabitEscribirIdeasReflexiones =>
      'Escribir ideas o reflexiones';

  @override
  String get catalogHabitEstudiarXTiempo => 'Estudiar';

  @override
  String catalogHabitEstudiarXTiempoTarget(String target) {
    return 'Estudiar $target horas';
  }

  @override
  String get catalogHabitAprenderIdioma => 'Practicar un idioma';

  @override
  String get catalogHabitEscucharPodcastEducativo =>
      'Escuchar podcast educativo';

  @override
  String get catalogHabitTomarNotas => 'Tomar notas del día';

  @override
  String get catalogHabitJuegoMental => 'Juego mental o rompecabezas';

  @override
  String get catalogHabitPracticarEscrituraCreativa => 'Escritura creativa';

  @override
  String get catalogHabitRepasarNotas => 'Repasar notas del día';

  @override
  String get catalogHabitVerDocumental => 'Ver un documental o vídeo educativo';

  @override
  String get catalogHabitMeditar => 'Meditar';

  @override
  String get catalogHabitPracticarGratitud => 'Practicar gratitud';

  @override
  String get catalogHabitRespiracionConsciente => 'Respiración consciente';

  @override
  String get catalogHabitReflexionPersonal => 'Reflexión personal';

  @override
  String get catalogHabitOracionConexionEspiritual =>
      'Oración o conexión espiritual';

  @override
  String get catalogHabitRevisarAprendizajesDia =>
      'Revisar aprendizajes del día';

  @override
  String get catalogHabitVisualizacionPositiva => 'Visualización positiva';

  @override
  String get catalogHabitLecturaEspiritual => 'Lectura espiritual';

  @override
  String get catalogHabitDesconexionDigital => 'Desconexión digital';

  @override
  String get catalogHabitContactoNaturaleza => 'Tiempo en la naturaleza';

  @override
  String get catalogHabitTresCosasBuenas => 'Escribir 3 cosas buenas del día';

  @override
  String get catalogHabitPaseoSinMovil => 'Paseo sin móvil';

  @override
  String get catalogHabitMomentoParaTi => 'Momento para ti';

  @override
  String get catalogHabitHacerEjercicio => 'Hacer ejercicio';

  @override
  String get catalogHabitIrGimnasio => 'Ir al gimnasio';

  @override
  String get catalogHabitCaminarPasosKm => 'Caminar';

  @override
  String catalogHabitCaminarPasosKmTarget(String target) {
    return 'Caminar $target pasos';
  }

  @override
  String get catalogHabitComerSaludable => 'Comer saludable';

  @override
  String get catalogHabitBeberXLAgua => 'Beber agua';

  @override
  String catalogHabitBeberXLAguaTarget(String target) {
    return 'Beber $target L de agua';
  }

  @override
  String get catalogHabitDormirXHoras => 'Dormir bien';

  @override
  String catalogHabitDormirXHorasTarget(String target) {
    return 'Dormir $target horas';
  }

  @override
  String get catalogHabitEstiramientos => 'Estiramientos';

  @override
  String get catalogHabitEvitarUltraprocesados => 'Evitar ultraprocesados';

  @override
  String get catalogHabitCuidarPostura => 'Cuidar la postura';

  @override
  String get catalogHabitRutinaManana => 'Rutina de mañana';

  @override
  String get catalogHabitRutinaNoche => 'Rutina de noche';

  @override
  String get catalogHabitSinAlcohol => 'Sin alcohol';

  @override
  String get catalogHabitCardio => 'Cardio';

  @override
  String catalogHabitCardioTarget(String target) {
    return 'Cardio $target minutos';
  }

  @override
  String get catalogHabitTomarElSol => 'Tomar el sol';

  @override
  String get catalogHabitNoPicar => 'No picar entre horas';

  @override
  String get catalogHabitDuchaFria => 'Ducha fría';

  @override
  String get catalogHabitHacerCama => 'Hacer la cama';

  @override
  String get catalogHabitSkincare => 'Skincare';

  @override
  String get catalogHabitHigieneBucal => 'Higiene bucal completa';

  @override
  String get catalogHabitTomarSuplementos => 'Tomar suplementos o medicación';

  @override
  String get catalogHabitHidratarPiel => 'Hidratarse la piel';

  @override
  String get catalogHabitDiarioEmocional => 'Diario emocional';

  @override
  String get catalogHabitIdentificarEmociones => 'Identificar mis emociones';

  @override
  String get catalogHabitGestionarEstres => 'Gestionar el estrés';

  @override
  String get catalogHabitAutocompasion => 'Practicar autocompasión';

  @override
  String get catalogHabitHablarSentimientos => 'Expresar mis sentimientos';

  @override
  String get catalogHabitReducirPensamientosNegativos =>
      'Reducir pensamientos negativos';

  @override
  String get catalogHabitPracticarPaciencia => 'Practicar paciencia';

  @override
  String get catalogHabitMomentoAlegria => 'Hacer algo que me alegre';

  @override
  String get catalogHabitCelebrarLogro => 'Celebrar un logro';

  @override
  String get catalogHabitNotaAnimo => 'Nota de ánimo del día';

  @override
  String catalogHabitNotaAnimoTarget(String target) {
    return 'Ánimo: $target/10';
  }

  @override
  String get catalogHabitSinPantallasNoche => 'Sin pantallas antes de dormir';

  @override
  String catalogHabitSinPantallasNocheTarget(String target) {
    return 'Sin pantallas $target min antes de dormir';
  }

  @override
  String get catalogHabitHablarSerQuerido => 'Hablar con alguien querido';

  @override
  String get catalogHabitEscucharActivamente => 'Escuchar activamente';

  @override
  String get catalogHabitExpresarGratitud => 'Expresar gratitud a alguien';

  @override
  String get catalogHabitAyudarAlguien => 'Ayudar a alguien';

  @override
  String get catalogHabitMantenerContacto => 'Mantener el contacto';

  @override
  String get catalogHabitCompartirExperiencias => 'Compartir una experiencia';

  @override
  String get catalogHabitPracticarEmpatia => 'Practicar empatía';

  @override
  String get catalogHabitPlanSocial => 'Quedar con alguien';

  @override
  String get catalogHabitDesconectarRedes => 'Desconectarse de redes sociales';

  @override
  String get catalogHabitMensajeAnimo => 'Enviar un mensaje de ánimo';

  @override
  String get catalogHabitLlamadaFamiliaAmigo => 'Llamada con familia o amigo';

  @override
  String get catalogHabitPlanificarDia => 'Planificar el día';

  @override
  String get catalogHabitCumplirRutina => 'Cumplir la rutina';

  @override
  String get catalogHabitRevisarObjetivos => 'Revisar objetivos';

  @override
  String get catalogHabitEvitarProcrastinacion => 'Vencer la procrastinación';

  @override
  String get catalogHabitTareaDificil => 'Hacer la tarea más difícil primero';

  @override
  String get catalogHabitPriorizarImportante => 'Priorizar lo importante';

  @override
  String get catalogHabitDejarFumar => 'Sin tabaco';

  @override
  String get catalogHabitSinRedesSociales => 'Sin redes sociales';

  @override
  String catalogHabitSinRedesSocialesTarget(String target) {
    return 'Sin redes sociales $target horas';
  }

  @override
  String get catalogHabitMadrugar => 'Madrugar';

  @override
  String get catalogHabitRevisarFinDia => 'Revisar el día al terminar';

  @override
  String get catalogHabitApagarMovil => 'Apagar el móvil a una hora fija';

  @override
  String get catalogHabitSinComprasImpulsivas => 'Sin compras impulsivas';

  @override
  String get catalogHabitPrepararRopa => 'Preparar la ropa del día siguiente';

  @override
  String get catalogHabitTrabajoProfundo => 'Sesión de trabajo profundo';

  @override
  String catalogHabitTrabajoProfundoTarget(String target) {
    return 'Trabajo profundo $target min';
  }

  @override
  String get catalogHabitHabilidadLaboral => 'Desarrollar habilidad laboral';

  @override
  String get catalogHabitOrganizarTareas => 'Organizar tareas del día';

  @override
  String get catalogHabitRevisarRendimiento => 'Revisar rendimiento';

  @override
  String get catalogHabitNetworking => 'Networking';

  @override
  String get catalogHabitFormacionProfesional => 'Formación profesional';

  @override
  String catalogHabitFormacionProfesionalTarget(String target) {
    return 'Formación $target horas';
  }

  @override
  String get catalogHabitResponderEmails => 'Bandeja de entrada a cero';

  @override
  String get catalogHabitProyectoPersonal => 'Avanzar en proyecto personal';

  @override
  String get catalogHabitLeerSector => 'Leer sobre mi sector';

  @override
  String get catalogHabitPomodoro => 'Bloque Pomodoro completado';

  @override
  String catalogHabitPomodoroTarget(String target) {
    return '$target pomodoros';
  }

  @override
  String get catalogHabitTrucoNuevo => 'Aprender un atajo o truco nuevo';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguageSectionTitle => 'Idioma';

  @override
  String get settingsLanguageOptionSpanish => 'Español';

  @override
  String get settingsLanguageOptionEnglish => 'Inglés';

  @override
  String get settingsAccountSectionTitle => 'Cuenta';

  @override
  String get settingsNotificationsTitle => 'Notificaciones';

  @override
  String get settingsNotificationsSubtitle =>
      'Abre las notificaciones y recordatorios de Rutio';

  @override
  String get settingsLogOut => 'Cerrar sesión';

  @override
  String get settingsLogOutTitle => '¿Cerrar sesión?';

  @override
  String get settingsLogOutMessage =>
      'Podrás volver a entrar con tu email y contraseña cuando quieras.';

  @override
  String get settingsLogOutConfirm => 'Cerrar sesión';

  @override
  String get settingsLogOutError =>
      'No se ha podido cerrar sesión. Inténtalo de nuevo.';

  @override
  String get settingsLogoutTitle => 'Cerrar sesión';

  @override
  String get settingsLogoutConfirmationBody =>
      '¿Seguro que quieres cerrar sesión? Podrás volver a entrar cuando quieras.';

  @override
  String get settingsLogoutConfirmAction => 'Cerrar sesión';

  @override
  String get settingsLogoutError =>
      'No se ha podido cerrar sesión. Inténtalo de nuevo.';

  @override
  String get settingsDeleteAccountTitle => 'Eliminar cuenta';

  @override
  String get settingsDeleteAccountHelperText =>
      'Elimina tu cuenta y los datos asociados de forma permanente.';

  @override
  String get settingsDeleteAccountConfirmationTitle => '¿Eliminar cuenta?';

  @override
  String get settingsDeleteAccountConfirmationBody =>
      'Esta acción eliminará tu cuenta y tus datos asociados. No se puede deshacer.';

  @override
  String get settingsDeleteAccountConfirmAction => 'Eliminar cuenta';

  @override
  String get settingsDeleteAccountMessage =>
      'Esta acción eliminará tu cuenta y tus datos asociados. No se puede deshacer.';

  @override
  String get settingsDeleteAccountConfirm => 'Eliminar cuenta';

  @override
  String get settingsDeleteAccountTypeToConfirm =>
      'Escribe ELIMINAR para confirmar.';

  @override
  String get settingsDeleteAccountError =>
      'No se ha podido eliminar la cuenta. Inténtalo de nuevo.';

  @override
  String get settingsDeleteAccountDeleting => 'Eliminando cuenta...';

  @override
  String get settingsDeleteAccountSuccess =>
      'Tu cuenta se ha eliminado correctamente.';

  @override
  String get personalizedNotificationsSectionTitle => 'Notificaciones de Rutio';

  @override
  String get personalizedNotificationsSectionSubtitle =>
      'Pequeños recordatorios y mensajes adaptados a tu progreso.';

  @override
  String get personalizedNotificationsEnableTitle =>
      'Activar notificaciones de Rutio';

  @override
  String get personalizedNotificationsEnableSubtitle =>
      'Separa los mensajes de Rutio de los recordatorios de hábitos.';

  @override
  String get personalizedNotificationsIntensityLabel => 'Intensidad';

  @override
  String get personalizedNotificationsIntensitySubtitle =>
      'Elige con qué frecuencia aparece Rutio.';

  @override
  String get personalizedNotificationsIntensitySoft => 'Suave';

  @override
  String get personalizedNotificationsIntensityBalanced => 'Equilibrado';

  @override
  String get personalizedNotificationsIntensityActive => 'Activo';

  @override
  String get personalizedNotificationsReferenceTimeTitle =>
      'Hora de referencia';

  @override
  String get personalizedNotificationsReferenceTimeSubtitle =>
      'Se usa como base para los mensajes personalizados.';

  @override
  String get personalizedNotificationsHabitReminderNote =>
      'Los recordatorios de hábitos siguen configurándose en su propia pantalla.';

  @override
  String get profileSettingsTitle => 'Ajustes';

  @override
  String get profileSettingsSubtitle => 'Idioma, privacidad y más';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileDefaultName => 'Tu perfil';

  @override
  String get profileDefaultSubtitle => 'Tu progreso, ajustes y cuenta';

  @override
  String get profileNotificationsTitle => 'Notificaciones';

  @override
  String get profileEnableNotificationsTitle => 'Activar notificaciones';

  @override
  String get profileEnableNotificationsSubtitle =>
      'Recordatorios, cierre del día y rachas';

  @override
  String get profileNotificationSettingsTitle => 'Ajustes de notificaciones';

  @override
  String profileNotificationCategoriesActive(int count, int total) {
    return '$count de $total categorías activas';
  }

  @override
  String get profileAccountSectionTitle => 'Cuenta y ajustes';

  @override
  String get profileThemeTitle => 'Tema';

  @override
  String get profileThemeSubtitle => 'Claro / Oscuro / Automático';

  @override
  String get profileThemeTodo => 'Tema (TODO)';

  @override
  String get profileHelpTitle => 'Ayuda';

  @override
  String get profileHelpSubtitle => 'FAQ y soporte';

  @override
  String get profileHelpTodo => 'Ayuda (TODO)';

  @override
  String get profileAboutTitle => 'Acerca de';

  @override
  String get profileAboutSubtitle => 'Versión y legal';

  @override
  String get profileAboutTodo => 'Acerca de (TODO)';

  @override
  String get profileDangerSectionTitle => 'Zona peligrosa';

  @override
  String get profileManageDataTitle => 'Gestionar datos';

  @override
  String get profileManageDataSubtitle => 'Exportar o borrar tu información';

  @override
  String get profileManageDataTodo => 'Gestionar datos (TODO)';

  @override
  String get profileLogoutTodo => 'Cerrar sesión (TODO)';

  @override
  String get profileNotificationPermissionDenied =>
      'Permiso de notificaciones no concedido.';

  @override
  String get profileEditButton => 'Editar';

  @override
  String get profileDangerZoneTitle => 'Zona de peligro';

  @override
  String get profileLogoutTitle => 'Cerrar sesión';

  @override
  String get profileLogoutSubtitle =>
      'Se cerrará tu sesión en este dispositivo';

  @override
  String get profileDeleteDataTitle => 'Borrar datos';

  @override
  String get profileDeleteDataSubtitle =>
      'Elimina todos tus datos y progreso (irreversible)';

  @override
  String get profileFamiliesProgressTitle => 'Progreso por familias';

  @override
  String profileFamilyLevelShort(int level) {
    return 'Lvl $level';
  }

  @override
  String profileFamilyLevelLabel(int level) {
    return 'Nivel $level';
  }

  @override
  String get profileNotificationsPhaseOneTitle => 'Fase 1';

  @override
  String get notificationsRemindersSectionTitle => 'Recordatorios';

  @override
  String get profileNotificationHabitRemindersTitle =>
      'Recordatorios de hábitos';

  @override
  String get profileNotificationHabitRemindersSubtitle =>
      'Respeta la hora configurada en cada hábito';

  @override
  String get profileNotificationDayClosureTitle => 'Cierre del día';

  @override
  String get profileNotificationDayClosureSubtitle =>
      'Solo si aún quedan hábitos pendientes hoy';

  @override
  String get profileNotificationDayClosureTimeTitle => 'Hora de cierre del día';

  @override
  String get profileNotificationDayClosureTimeSubtitle =>
      'Momento para recordar lo que aún queda pendiente';

  @override
  String get profileNotificationStreakRiskTitle => 'Racha en riesgo';

  @override
  String get profileNotificationStreakRiskSubtitle =>
      'Avisa cuando aún puedes salvar una racha relevante';

  @override
  String get profileNotificationStreakCelebrationTitle =>
      'Celebraciones de racha';

  @override
  String get profileNotificationStreakCelebrationSubtitle =>
      'Celebra hitos básicos como 1, 3, 7, 14 y 30 días';

  @override
  String get profileNotificationInactivityTitle =>
      'Reactivación por inactividad';

  @override
  String get profileNotificationInactivitySubtitle =>
      'Un recordatorio amable tras 3 días sin abrir la app';

  @override
  String get notificationPermissionTitle => 'Activa tus recordatorios';

  @override
  String get notificationPermissionBody =>
      'Rutio puede avisarte en el momento adecuado para ayudarte a mantener tus hábitos sin presión.';

  @override
  String get notificationPermissionPrimaryAction => 'Activar recordatorios';

  @override
  String get notificationPermissionSecondaryAction => 'Ahora no';

  @override
  String get notificationPermissionDeniedTitle => 'Notificaciones desactivadas';

  @override
  String get notificationPermissionDeniedBody =>
      'Puedes activarlas más adelante desde los ajustes de tu dispositivo.';

  @override
  String get notificationPermissionOpenSettings => 'Abrir ajustes';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackIntro =>
      'Tu experiencia nos ayuda a mejorar Rutio. Puedes compartir una idea, avisarnos de un problema o consultar el estado de tus envíos.';

  @override
  String get feedbackSendAction => 'Enviar feedback';

  @override
  String get feedbackSendActionSubtitle =>
      'Comparte una idea o avísanos de un problema.';

  @override
  String get feedbackMineAction => 'Mis envíos';

  @override
  String get feedbackMineActionSubtitle =>
      'Consulta el estado de lo que ya has enviado.';

  @override
  String get feedbackNewTitle => 'Enviar feedback';

  @override
  String get feedbackNewIntro =>
      'Elige una categoría, describe lo ocurrido y deja listo el envío.';

  @override
  String get feedbackCategorySectionTitle =>
      '¿Qué tipo de feedback quieres enviar?';

  @override
  String get feedbackCategoryBugTitle => 'He encontrado un problema';

  @override
  String get feedbackCategoryBugHelp =>
      'Cuéntanos qué ocurrió, qué esperabas que pasara y, si puedes, cómo reproducirlo.';

  @override
  String get feedbackCategorySuggestionTitle => 'Tengo una sugerencia';

  @override
  String get feedbackCategorySuggestionHelp =>
      'Explícanos tu idea y qué necesidad te ayudaría a resolver.';

  @override
  String get feedbackCategoryImprovementTitle =>
      'Quiero mejorar algo existente';

  @override
  String get feedbackCategoryImprovementHelp =>
      'Dinos qué parte de Rutio cambiarías y cómo te gustaría que funcionara.';

  @override
  String get feedbackCategoryOtherTitle => 'Otro comentario';

  @override
  String get feedbackCategoryOtherHelp =>
      'Comparte cualquier comentario que pueda ayudarnos a mejorar Rutio.';

  @override
  String get feedbackCategoryGeneralHelp =>
      'Elige una categoría para ver una guía más concreta sobre lo que puedes contarnos.';

  @override
  String get feedbackDescriptionLabel => 'Describe tu feedback';

  @override
  String get feedbackDescriptionHint =>
      'Cuéntanos qué pasó, qué esperabas y cualquier detalle útil.';

  @override
  String get feedbackDescriptionRequirements =>
      'Mín. 20 y máx. 5000 caracteres tras recortar espacios.';

  @override
  String feedbackDescriptionCounter(int current, int max) {
    return '$current/$max';
  }

  @override
  String get feedbackScreenshotTitle => 'Captura de pantalla (opcional)';

  @override
  String get feedbackScreenshotPlaceholder => 'Seleccionar imagen';

  @override
  String get feedbackScreenshotSelectedLabel => 'Captura lista';

  @override
  String get feedbackScreenshotSelectAction => 'Seleccionar imagen';

  @override
  String get feedbackScreenshotReplaceAction => 'Sustituir';

  @override
  String get feedbackScreenshotRemoveAction => 'Retirar';

  @override
  String get feedbackScreenshotPreparing => 'Preparando captura...';

  @override
  String get feedbackScreenshotErrorUnsupported =>
      'No se admite ese tipo de imagen. Prueba con otra captura.';

  @override
  String get feedbackScreenshotErrorNotProcessable =>
      'No hemos podido preparar esta imagen. Prueba con otra.';

  @override
  String get feedbackScreenshotErrorCompressionFailed =>
      'No hemos podido comprimir esta imagen. Prueba con otra.';

  @override
  String get feedbackScreenshotErrorTooLarge =>
      'La imagen sigue siendo demasiado grande. Prueba con otra más ligera.';

  @override
  String get feedbackScreenshotErrorUploadFailed =>
      'No hemos podido subir la captura. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get feedbackScreenshotErrorCleanupFailed =>
      'Ha habido un problema limpiando una captura temporal. Puedes volver a intentarlo.';

  @override
  String get feedbackContactTitle => '¿Podemos contactar contigo?';

  @override
  String get feedbackContactDescription =>
      'Si activas esta opción, podremos responderte si lo necesitamos.';

  @override
  String get feedbackContactSwitchLabel => 'Sí, podéis contactarme';

  @override
  String get feedbackTechnicalNote =>
      'Incluiremos información técnica básica de la app y del dispositivo para ayudarnos a revisar tu comentario.';

  @override
  String get feedbackSubmitAction => 'Enviar feedback';

  @override
  String get feedbackMineTitle => 'Mis envíos';

  @override
  String get feedbackMineHeading => 'Tus envíos';

  @override
  String get feedbackMineIntro =>
      'Aquí verás el historial real de feedback que has enviado.';

  @override
  String get feedbackMineEmptyState => 'Todavía no has enviado feedback.';

  @override
  String get feedbackMineFilteredEmptyState =>
      'No hay envíos que coincidan con este filtro.';

  @override
  String get feedbackMineLoadingState => 'Cargando tus envíos...';

  @override
  String get feedbackMineErrorTitle => 'No hemos podido cargar tus envíos';

  @override
  String get feedbackMineErrorSessionExpired =>
      'Tu sesión no está disponible. Vuelve a iniciar sesión.';

  @override
  String get feedbackMineErrorNetwork =>
      'No se ha podido conectar con el servidor. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get feedbackMineErrorGeneric =>
      'No hemos podido cargar tus envíos ahora mismo. Inténtalo de nuevo.';

  @override
  String get feedbackMineRetryAction => 'Reintentar';

  @override
  String get feedbackFilterAll => 'Todos';

  @override
  String get feedbackFilterSubmitted => 'Enviados';

  @override
  String get feedbackFilterInReview => 'En revisión';

  @override
  String get feedbackFilterClosed => 'Cerrados';

  @override
  String get feedbackResponseAvailableBadge => 'Respuesta disponible';

  @override
  String get feedbackStatusSubmitted => 'Enviado';

  @override
  String get feedbackStatusInReview => 'En revisión';

  @override
  String get feedbackStatusResolved => 'Resuelto';

  @override
  String get feedbackStatusDismissed => 'Descartado';

  @override
  String get feedbackProgressSubmitted => 'Enviado';

  @override
  String get feedbackProgressSubmittedSubtitle =>
      'Entrada recibida en el flujo local.';

  @override
  String get feedbackProgressInReview => 'En revisión';

  @override
  String get feedbackProgressInReviewSubtitle =>
      'El equipo todavía no ha cerrado una decisión.';

  @override
  String get feedbackProgressTerminalLabel => 'Resuelto / Descartado';

  @override
  String get feedbackProgressTerminalSubtitle =>
      'Resultado final del feedback.';

  @override
  String get feedbackSuccessTitle => '¡Gracias!';

  @override
  String get feedbackSuccessBody => 'Hemos recibido tu feedback correctamente.';

  @override
  String get feedbackSuccessSummaryLabel => 'Resumen del envío';

  @override
  String get feedbackSuccessCanEditDelete =>
      'Todavía puedes editar o eliminar este feedback hasta que el equipo empiece a revisarlo.';

  @override
  String get feedbackSuccessProgressLabel => 'Proceso';

  @override
  String get feedbackSuccessMineAction => 'Ver mis envíos';

  @override
  String get feedbackSuccessHomeAction => 'Volver a Feedback';

  @override
  String get feedbackDetailTitle => 'Detalle';

  @override
  String get feedbackDetailLoadingState => 'Cargando feedback...';

  @override
  String get feedbackDetailErrorTitle => 'No se ha podido cargar el feedback';

  @override
  String get feedbackDetailLoadErrorMessage =>
      'No hemos podido cargar este feedback. Inténtalo de nuevo.';

  @override
  String get feedbackDetailNotAvailableTitle => 'Feedback no disponible';

  @override
  String get feedbackDetailNotAvailableMessage =>
      'Este feedback ya no está disponible.';

  @override
  String get feedbackDetailRetryAction => 'Reintentar';

  @override
  String get feedbackDetailDescriptionLabel => 'Descripción';

  @override
  String get feedbackDetailSentDateLabel => 'Fecha de envío';

  @override
  String get feedbackDetailReviewDateLabel => 'Fecha de revisión';

  @override
  String get feedbackDetailClosedDateLabel => 'Fecha de cierre';

  @override
  String get feedbackDetailScreenshotLabel => 'Captura adjunta';

  @override
  String get feedbackDetailScreenshotLoading => 'Cargando captura...';

  @override
  String get feedbackDetailScreenshotError =>
      'No hemos podido cargar la captura.';

  @override
  String get feedbackDetailScreenshotPlaceholder => 'Captura disponible';

  @override
  String get feedbackDetailActionsLabel => 'Acciones disponibles';

  @override
  String get feedbackEditAction => 'Editar';

  @override
  String get feedbackDeleteAction => 'Eliminar feedback';

  @override
  String get feedbackEditTitle => 'Editar feedback';

  @override
  String get feedbackEditIntro =>
      'Puedes ajustar la descripción, la captura y si quieres que podamos contactarte.';

  @override
  String get feedbackEditCategoryLockedNote =>
      'La categoría no se puede cambiar en esta fase.';

  @override
  String get feedbackEditNoScreenshot =>
      'No hay captura adjunta. Puedes añadir una nueva si lo necesitas.';

  @override
  String get feedbackEditSaveAction => 'Guardar cambios';

  @override
  String get feedbackEditErrorNoLongerEditable =>
      'Este feedback ya está en revisión y no puede modificarse.';

  @override
  String get feedbackEditSaveErrorGeneric =>
      'No hemos podido guardar los cambios. Inténtalo de nuevo.';

  @override
  String get feedbackDeleteConfirmTitle => '¿Eliminar este feedback?';

  @override
  String get feedbackDeleteConfirmMessage =>
      'Esta acción no se puede deshacer.';

  @override
  String get feedbackDeleteConfirmCancel => 'Cancelar';

  @override
  String get feedbackDeleteConfirmDelete => 'Eliminar';

  @override
  String get feedbackResponseTitle => 'Respuesta del equipo';

  @override
  String get feedbackResponseEmpty =>
      'Nuestro equipo todavía no ha añadido una respuesta.';

  @override
  String get feedbackExitConfirmTitle => '¿Quieres salir?';

  @override
  String get feedbackExitConfirmMessage =>
      'Perderás el feedback que todavía no has enviado.';

  @override
  String get feedbackExitConfirmStay => 'Seguir editando';

  @override
  String get feedbackExitConfirmLeave => 'Salir';

  @override
  String get feedbackPlaceholderBody =>
      'Esta sección del Centro de Feedback llegará en una fase posterior.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get editProfileSave => 'Guardar';

  @override
  String get editProfileSaveChanges => 'Guardar cambios';

  @override
  String get editProfileSaving => 'Guardando...';

  @override
  String get editProfileTakePhoto => 'Tomar foto';

  @override
  String get editProfileGallery => 'Galería';

  @override
  String get editProfileRemovePhoto => 'Eliminar foto';

  @override
  String get editProfilePersonalInfoTitle => 'Información personal';

  @override
  String get editProfileGoalSectionTitle => 'Tu objetivo';

  @override
  String editProfileImageSelectionError(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String get editProfileSaveSuccess => 'Perfil actualizado correctamente';

  @override
  String editProfileSaveError(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get editProfileDiscardChangesTitle => '¿Descartar cambios?';

  @override
  String get editProfileDiscardChangesBody =>
      'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?';

  @override
  String get editProfileDiscardChangesAction => 'Descartar';

  @override
  String get editProfileCropTitle => 'Recortar';

  @override
  String get editProfileStatLevel => 'Nivel';

  @override
  String get editProfileStatXp => 'XP';

  @override
  String get editProfileStatCoins => 'Monedas';

  @override
  String get editProfileNameLabel => 'Nombre';

  @override
  String get editProfileNameHint => 'Cómo quieres que te vean';

  @override
  String get editProfileNameRequired => 'El nombre es obligatorio';

  @override
  String get editProfileNameMinLength => 'Mínimo 2 caracteres';

  @override
  String get editProfileBioLabel => 'Bio';

  @override
  String get editProfileBioHint => 'Cuéntanos un poco sobre ti...';

  @override
  String get editProfileGoalLabel => 'Objetivo';

  @override
  String get editProfileGoalHint => 'Qué quieres conseguir con Rutio';

  @override
  String get editProfileChangePhoto => 'Cambiar foto de perfil';

  @override
  String get editProfileAddPhoto => 'Añadir foto de perfil';

  @override
  String get archivedHabitsTitle => 'Hábitos archivados';

  @override
  String get archivedHabitsEmpty => 'No tienes hábitos archivados.';

  @override
  String archivedHabitsFamilyLabel(String family) {
    return 'Familia: $family';
  }

  @override
  String get archivedHabitsRestoreTooltip => 'Restaurar';

  @override
  String get archivedHabitsDeleteTooltip => 'Eliminar';

  @override
  String get archivedHabitsDeleteTitle => 'Eliminar hábito';

  @override
  String get archivedHabitsDeleteBody =>
      '¿Seguro que quieres eliminar este hábito?\n\nSe eliminará también su historial.';

  @override
  String get habitDetailFallbackTitle => 'Hábito';

  @override
  String get habitDetailSaved => 'Cambios guardados';

  @override
  String get habitDetailDeleteTitle => 'Eliminar hábito';

  @override
  String get habitDetailDeleteBody =>
      'Se borrará el hábito y su historial. Esta acción no se puede deshacer.';

  @override
  String get habitDetailArchiveAction => 'Archivar hábito';

  @override
  String get habitDetailDeleteAction => 'Eliminar hábito';

  @override
  String get habitDetailMoreOptionsTooltip => 'Más opciones';

  @override
  String get habitDetailEditTab => 'Editar';

  @override
  String get habitDetailStatsTab => 'Estadísticas';

  @override
  String get archiveHabitTileTitle => 'Archivar hábito';

  @override
  String get archiveHabitTileArchivedSubtitle =>
      'Este hábito está archivado (no aparecerá en la lista principal).';

  @override
  String get archiveHabitTileActiveSubtitle =>
      'Oculta este hábito de la lista principal sin borrarlo.';

  @override
  String get archiveHabitTileConfirmTitle => 'Archivar hábito';

  @override
  String get archiveHabitTileConfirmBody =>
      '¿Quieres archivar este hábito? Podrás recuperarlo más adelante.';

  @override
  String get archiveHabitTileConfirmAction => 'Archivar';

  @override
  String get habitStatsTitle => 'Estadísticas';

  @override
  String get habitStatsEmpty => 'No hay hábitos para mostrar.';

  @override
  String get statisticsV3Subtitle => 'Tu progreso en Rutio';

  @override
  String get statisticsV3DailyActivityTitle => 'Actividad diaria';

  @override
  String get statisticsV3DailyActivitySubtitle => 'Ritmo semanal de completado';

  @override
  String get statisticsV3SummaryCardTitle => 'Resumen general';

  @override
  String get statisticsV3SummaryCompletedLabel => 'hábitos completados';

  @override
  String get statisticsV3SummaryXpLabel => 'XP';

  @override
  String get statisticsV3SummaryAmberLabel => 'Ámbar';

  @override
  String get statisticsV3RewardBreakdownTitle => 'Desglose de recompensas';

  @override
  String get statisticsV3RewardBreakdownSubtitle =>
      'Recompensas obtenidas en este periodo.';

  @override
  String get statisticsV3RewardBreakdownHabits => 'Hábitos';

  @override
  String get statisticsV3RewardBreakdownDiary => 'Diario';

  @override
  String get statisticsV3RewardBreakdownAchievements => 'Logros';

  @override
  String get statisticsV3RewardBreakdownLevelUps => 'Subidas de nivel';

  @override
  String get statisticsV3RewardBreakdownTotal => 'Total';

  @override
  String get statisticsV3RewardBreakdownEmpty =>
      'No hay recompensas registradas en este periodo.';

  @override
  String get statisticsV3RewardBreakdownHint =>
      'Mantén pulsado para ver el detalle';

  @override
  String get statisticsV3RewardBreakdownLevelUpFootnote =>
      'Las recompensas por subida de nivel se mostrarán aquí cuando exista historial fechado de recompensas.';

  @override
  String get statisticsV3ConsistencyCardTitle => 'Consistencia';

  @override
  String get statisticsV3ConsistencyCompletedLabel => 'completado';

  @override
  String get statisticsV3ConsistencyPendingLabel => 'pendientes';

  @override
  String get statisticsV3ConsistencyStreakLabel => 'racha días';

  @override
  String get statisticsV3ConsistencyActiveDays => 'días activos';

  @override
  String get statisticsV3ConsistencyCompletionLabel => 'de cumplimiento';

  @override
  String get statisticsV3FamiliesCardTitle => 'Familia destacada';

  @override
  String get statisticsV3FamiliesEmpty =>
      'Aún no hay una familia con actividad en este periodo.';

  @override
  String get statisticsV3FeaturedFamilySubtitleDay =>
      'La familia con más actividad hoy';

  @override
  String get statisticsV3FeaturedFamilySubtitleWeek =>
      'La familia con más actividad esta semana';

  @override
  String get statisticsV3FeaturedFamilySubtitleMonth =>
      'La familia con más actividad este mes';

  @override
  String get statisticsV3FeaturedFamilySubtitleYear =>
      'La familia con más actividad este año';

  @override
  String get statisticsV3BestMomentCardTitle => 'Mejor momento';

  @override
  String get statisticsV3BestMomentSubtitle => 'Tu franja más activa';

  @override
  String get statisticsV3BestMomentFallback =>
      'La información de horario aparecerá cuando haya más completados con hora registrada.';

  @override
  String statisticsV3BestMomentWithCount(String moment, int count) {
    return '$moment · $count';
  }

  @override
  String get statisticsV3MomentMorning => 'Mañana';

  @override
  String get statisticsV3MomentAfternoon => 'Mediodía';

  @override
  String get statisticsV3MomentEvening => 'Tarde';

  @override
  String get statisticsV3MomentNight => 'Noche';

  @override
  String get statisticsV3NoFamily => 'Sin familia';

  @override
  String get statisticsV3InsightCardTitle => 'Insight';

  @override
  String get statisticsV3InsightEmptyState =>
      'Cuando completes algunos hábitos, aquí verás una lectura útil de tu progreso.';

  @override
  String get statisticsV3InsightPositiveConsistency =>
      'Estás manteniendo un ritmo sólido en este periodo. Continúa con la misma calma.';

  @override
  String statisticsV3InsightFeaturedFamily(String family) {
    return '$family lidera este periodo. Apóyate en ese impulso.';
  }

  @override
  String statisticsV3InsightBestMoment(String moment) {
    return '$moment es tu franja más fuerte. Protégela con una acción simple.';
  }

  @override
  String get statisticsV3InsightLowActivity =>
      'Este periodo sigue con poca actividad. Mantén un objetivo pequeño y claro para recuperar ritmo.';

  @override
  String get statisticsV3HighlightedHabitCardTitle => 'Hábito destacado';

  @override
  String get statisticsV3HighlightedHabitSubtitleDay =>
      'El hábito con más actividad hoy';

  @override
  String get statisticsV3HighlightedHabitSubtitleWeek =>
      'El hábito con más actividad esta semana';

  @override
  String get statisticsV3HighlightedHabitSubtitleMonth =>
      'El hábito con más actividad este mes';

  @override
  String get statisticsV3HighlightedHabitSubtitleYear =>
      'El hábito con más actividad este año';

  @override
  String get statisticsV3HighlightedHabitStreakLabel => 'Racha';

  @override
  String statisticsV3HighlightedHabitStreakDays(int days) {
    return '$days días';
  }

  @override
  String get statisticsV3HighlightedHabitQuestionDay =>
      '¿Qué hábito he estado haciendo durante más tiempo hoy?';

  @override
  String get statisticsV3HighlightedHabitQuestionWeek =>
      '¿Qué hábito he estado haciendo durante más tiempo esta semana?';

  @override
  String get statisticsV3HighlightedHabitQuestionMonth =>
      '¿Qué hábito he estado haciendo durante más tiempo este mes?';

  @override
  String get statisticsV3HighlightedHabitQuestionYear =>
      '¿Qué hábito he estado haciendo durante más tiempo este año?';

  @override
  String get statisticsV3HighlightedHabitEmpty =>
      'Aún no hay un hábito destacado disponible.';

  @override
  String statisticsV3HighlightedCompletedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# días completados',
      one: '# día completado',
    );
    return '$_temp0';
  }

  @override
  String get statisticsV3HabitListTitle => 'Hábitos';

  @override
  String get statisticsV3HabitListSearchPlaceholder => 'Buscar hábitos';

  @override
  String get statisticsV3HabitListAllChip => 'Todos';

  @override
  String statisticsV3HabitListMainDaysPercent(
      int completed, int expected, int percent) {
    return '$completed de $expected días · $percent%';
  }

  @override
  String statisticsV3HabitListMainTimesPerWeek(int completed, int target) {
    return '$completed/$target esta semana';
  }

  @override
  String statisticsV3HabitListMainCountWeek(String value, String unit) {
    return '$value $unit esta semana';
  }

  @override
  String statisticsV3HabitListStreakDays(int days) {
    return 'Racha: $days días';
  }

  @override
  String statisticsV3HabitListAvgPerDay(String value, String unit) {
    return 'Media: $value $unit/día';
  }

  @override
  String get statisticsV3HabitListEmptyTitle => 'Aún no hay hábitos activos.';

  @override
  String get statisticsV3HabitListEmptySubtitle =>
      'Crea un hábito para empezar a ver progreso aquí.';

  @override
  String get statisticsV3HabitListNoResultsTitle =>
      'No hay hábitos que coincidan con tu búsqueda.';

  @override
  String get statisticsV3HabitListNoResultsSubtitle =>
      'Prueba con otro nombre o familia.';

  @override
  String get statisticsV3HabitListPlusComingSoon =>
      'Crear hábitos desde esta vista llegará pronto.';

  @override
  String get statisticsV3HabitViewPlaceholderTitle => 'Vista por hábito';

  @override
  String get statisticsV3HabitViewPlaceholderBody =>
      'Esta sección queda reservada para la vista detallada por hábito en V3. Por ahora puedes usar el resumen general sin riesgos.';

  @override
  String get statisticsV3ProgressMessageEmpty =>
      'Aún estás a tiempo de empezar';

  @override
  String get statisticsV3ProgressMessageInProgress =>
      'Tu ritmo se está construyendo';

  @override
  String get statisticsV3ProgressMessageComplete =>
      'Periodo completado con calma';

  @override
  String get statisticsV3WeeklyImprovementTitle => 'Mejora de semana';

  @override
  String get statisticsV3WeeklyImprovementVsLastWeek => 'vs semana anterior';

  @override
  String get statisticsV3WeeklyImprovementNoComparison =>
      'Sin comparación todavía';

  @override
  String get statisticsV3WeeklyImprovementSameAsLastWeek =>
      'Igual que la semana anterior';

  @override
  String get statisticsV3MonthlyCalendarTitle => 'Calendario de constancia';

  @override
  String get statisticsV3MonthlyCalendarSubtitle =>
      'Tu ritmo mensual de un vistazo';

  @override
  String get statisticsV3ConsistencyLegendFuture => 'Futuro';

  @override
  String get statisticsV3ConsistencyLegendNoData => 'Sin datos';

  @override
  String get habitStatsMetricCompleted => 'Completado';

  @override
  String habitStatsMetricCompletionDescription(int done, int total) {
    return '$done/$total días';
  }

  @override
  String get habitStatsMetricConsistency => 'Consistencia';

  @override
  String habitStatsMetricConsistencyDescription(int window) {
    return 'Últimos $window días';
  }

  @override
  String get habitStatsMetricBestStreak => 'Mejor racha';

  @override
  String get habitStatsMetricPersonalBest => 'Record personal';

  @override
  String get habitStatsMetricTotalDone => 'Total hechos';

  @override
  String get habitStatsMetricHistoricRecords => 'Historico (registros)';

  @override
  String get habitStatsChartWeekTitle => 'Semana';

  @override
  String get habitStatsChartLastFourWeeksTitle => 'Últimas 4 semanas';

  @override
  String get habitStatsChartWeekSubtitle => 'Completado por día';

  @override
  String get habitStatsChartWeeksSubtitle => 'Completado agregado por semana';

  @override
  String get habitStatsNextMilestone => 'Siguiente hito';

  @override
  String get habitStatsWeeklyComparisonTitle => 'Comparacion semanal';

  @override
  String get habitStatsWeeklyComparisonSubtitle => 'Esta semana vs la anterior';

  @override
  String get habitStatsBestTimeSectionTitle => '¿Cuándo lo cumples mejor?';

  @override
  String get habitStatsBestTimeSectionSubtitle =>
      'Basado en tus registros, tus momentos más consistentes';

  @override
  String get habitStatsMonthCalendarTitle => 'Calendario del mes';

  @override
  String get habitStatsMonthlyActivityTitle => 'Actividad mensual';

  @override
  String get habitStatsMonthlyActivityPlaceholderBody =>
      'El calendario mensual estará disponible en la siguiente fase.';

  @override
  String get habitStatsTabSummaryTitle => 'Resumen';

  @override
  String habitStatsTabLastDaysTitle(int days) {
    return 'Últimos $days días';
  }

  @override
  String get habitStatsTabAchievementsUnlocked => 'Logros desbloqueados';

  @override
  String get habitStatsTabCurrentStreakTitle => 'Racha actual';

  @override
  String habitStatsTabDayUnit(int count) {
    return '$count día';
  }

  @override
  String get habitStatsTabTotalLabel => 'total';

  @override
  String habitStatsTabCompletionWindow(int done, int total) {
    return '$done / $total días';
  }

  @override
  String get habitStatsTabCounterHint =>
      'Cuenta el número de veces completado cada día';

  @override
  String get habitStatsTabCheckHint =>
      'Días en los que completaste este hábito';

  @override
  String get habitStatsTabFireStreakTitle => 'Racha de fuego';

  @override
  String habitStatsTabStreakInARow(int days) {
    return '$days días seguidos';
  }

  @override
  String get habitStatsTabCentennialTitle => 'Centenario!';

  @override
  String get habitStatsTabHalfCenturyTitle => 'Medio centenar';

  @override
  String habitStatsTabCompletedCount(int count) {
    return '$count completados';
  }

  @override
  String get habitStatsTabMaxConsistencyTitle => 'Consistencia maxima';

  @override
  String habitStatsTabLast30DaysPercent(int percent) {
    return '$percent% últimos 30 días';
  }

  @override
  String get habitStatsTabLegendaryRecordTitle => 'Record legendario';

  @override
  String habitStatsTabRecordStreak(int days) {
    return '$days días de racha';
  }

  @override
  String habitStatsTabWeeklyDelta(int delta) {
    return '$delta vs semana anterior';
  }

  @override
  String get habitStatsTabWeeklyDeltaEqual => 'Igual que semana anterior';

  @override
  String get diaryTitle => 'Diario';

  @override
  String get diaryMenuTooltip => 'Menú';

  @override
  String get diaryCloseSearchTooltip => 'Cerrar búsqueda';

  @override
  String get diarySearchTooltip => 'Buscar';

  @override
  String get diaryFiltersTooltip => 'Filtros';

  @override
  String get diaryNewEntry => 'Nueva entrada';

  @override
  String get diaryEntryDeleted => 'Entrada eliminada';

  @override
  String get diaryEntrySaved => 'Entrada guardada';

  @override
  String get diaryNoteSaved => 'Nota guardada';

  @override
  String get diaryPinSoon => 'Fijar: próximamente';

  @override
  String get diaryDeleteEntryTitle => 'Eliminar entrada';

  @override
  String get diaryDeleteEntryBody => 'Esta acción no se puede deshacer.';

  @override
  String diaryEntriesCount(int count) {
    return '$count entradas';
  }

  @override
  String get diaryPeriodAll => 'Todo';

  @override
  String get diaryPeriodDays => 'Días';

  @override
  String get diaryPeriodWeeks => 'Semanas';

  @override
  String get diaryPeriodMonths => 'Meses';

  @override
  String get diarySearchHint => 'Buscar en tu diario...';

  @override
  String get diaryClearTooltip => 'Borrar';

  @override
  String get diarySearchScopeAll => 'Todo';

  @override
  String get diarySearchScopeHabits => 'Hábitos';

  @override
  String get diarySearchScopePersonal => 'Personal';

  @override
  String diaryWrittenEntriesToday(int count) {
    return 'Hoy escribiste $count entradas';
  }

  @override
  String diaryEmotionalXp(int xp) {
    return '+$xp XP emocional';
  }

  @override
  String get diarySummaryEmptyTitle => 'Hoy aún no has escrito';

  @override
  String get diarySummaryEmptySubtitle => 'Un minuto puede cambiar tu día';

  @override
  String get diarySummaryOneTitle => 'Buen comienzo';

  @override
  String get diarySummaryOneSubtitle => 'Has dado espacio a tu mente';

  @override
  String get diarySummaryFewTitle => 'Estás cuidando tu mundo interior';

  @override
  String get diarySummaryFewSubtitle => 'Sigue así';

  @override
  String get diarySummaryManyTitle => 'Día muy consciente';

  @override
  String get diarySummaryManySubtitle => 'Gran trabajo emocional';

  @override
  String get diaryActionEdit => 'Editar';

  @override
  String get diaryActionDelete => 'Eliminar';

  @override
  String get diaryComposerCancel => '← Cancelar';

  @override
  String get diaryComposerEditEntryUpper => 'EDITAR ENTRADA';

  @override
  String get diaryComposerNewEntryUpper => 'NUEVA ENTRADA';

  @override
  String get diaryComposerMoodSectionUpper => '¿CÓMO TE SENTISTE?';

  @override
  String get diaryComposerTitleUpper => 'TÍTULO';

  @override
  String get diaryComposerReflectionUpper => 'REFLEXIÓN';

  @override
  String get diaryComposerTitleHint => '¿Cómo resumirías hoy?';

  @override
  String get diaryComposerHabitReflectionHint =>
      '¿Qué pasó hoy con tu hábito? ¿Qué sentiste? ¿Qué aprendiste?';

  @override
  String get diaryComposerPersonalReflectionHint =>
      '¿Qué tienes en mente? ¿Qué quieres dejar por escrito hoy?';

  @override
  String get diaryComposerSaveChanges => 'Guardar cambios';

  @override
  String get diaryComposerSaveEntry => 'Guardar entrada';

  @override
  String get diaryComposerTypeHabit => 'Ligada a hábito';

  @override
  String get diaryComposerTypePersonal => 'Personal';

  @override
  String get diaryComposerSelectHabit => 'Seleccionar hábito';

  @override
  String get diaryComposerTapToChooseHabit => 'Toca para elegir un hábito';

  @override
  String get diaryComposerWriteSomethingError =>
      'Escribe algo para guardar la entrada';

  @override
  String get diaryComposerSelectHabitError => 'Selecciona un hábito';

  @override
  String get diaryComposerNoActiveHabits =>
      'No hay hábitos activos para seleccionar';

  @override
  String get diaryComposerSelectHabitSheetTitle => 'Seleccionar hábito';

  @override
  String get diaryDetailScreenTitle => 'Entrada';

  @override
  String get diaryDetailTopHabitUpper => 'ENTRADA DE HÁBITO';

  @override
  String get diaryDetailTopPersonalUpper => 'ENTRADA PERSONAL';

  @override
  String get diaryDetailFallbackHabitTitle => 'Entrada de hábito';

  @override
  String get diaryDetailFallbackPersonalTitle => 'Entrada personal';

  @override
  String get diaryDetailLeadingPersonal => 'Escrito personal';

  @override
  String get diaryDetailFamilyPersonal => 'Personal';

  @override
  String get diaryDetailTypeHabit => 'Día de hábito';

  @override
  String get diaryDetailTypePersonal => 'Nota personal';

  @override
  String get diaryDetailNotesUpper => 'NOTAS';

  @override
  String diaryDetailLoggedAt(String time) {
    return 'Registrado a las $time';
  }

  @override
  String get diaryDetailThisWeekUpper => 'ESTA SEMANA';

  @override
  String get diaryTodayUpper => 'HOY';

  @override
  String habitStatsWeekShort(int weekNumber) {
    return 'S$weekNumber';
  }

  @override
  String get habitStatsHabitFallbackTitle => 'Hábito';

  @override
  String get habitStatsPeriodDay => 'Día';

  @override
  String get habitStatsPeriodWeek => 'Semana';

  @override
  String get habitStatsPeriodMonth => 'Mes';

  @override
  String get habitStatsPeriodYear => 'Año';

  @override
  String get habitStatsYearSummaryTitle => 'Resumen anual';

  @override
  String get habitStatsYearSummaryBody =>
      'Pronto verás tus meses, actividad e insights de este hábito durante el año.';

  @override
  String get habitStatsYearMonthsTitle => 'Meses del año';

  @override
  String get habitStatsYearMonthsBody =>
      'Un vistazo rápido a cómo ha ido este hábito mes a mes.';

  @override
  String get habitStatsYearCalendarTitle => 'Calendario anual';

  @override
  String get habitStatsYearCalendarDone => 'Hecho';

  @override
  String get habitStatsYearCalendarSkipped => 'Omitido';

  @override
  String get habitStatsYearCalendarMissed => 'Pendiente';

  @override
  String get habitStatsPeriodThreeMonths => '3 meses';

  @override
  String get habitStatsPeriodAll => 'Todo';

  @override
  String habitStatsDaysLabel(int count) {
    return '$count día';
  }

  @override
  String get habitStatsCurrentStreakUpper => 'RACHA ACTUAL';

  @override
  String get habitStatsHeadlineStartToday => 'Empezamos hoy!';

  @override
  String get habitStatsHeadlineGoodStart => 'Buen inicio!';

  @override
  String get habitStatsHeadlineOnStreak => 'En racha!';

  @override
  String habitStatsMilestoneProgress(String label, int next) {
    return '$label: $next días';
  }

  @override
  String get habitStatsThisWeek => 'Esta semana';

  @override
  String get habitStatsThisYear => 'Este año';

  @override
  String get habitStatsYearMetricCompletedTotal => 'Hecho / Total';

  @override
  String get habitStatsYearMetricConsistencySubtitle => 'Consistencia anual';

  @override
  String get habitStatsYearMetricBestMonth => 'Mejor mes';

  @override
  String get habitStatsYearMetricBestMonthSubtitle => 'Mayor rendimiento';

  @override
  String get habitStatsYearMetricActiveMonths => 'Meses activos';

  @override
  String get habitStatsYearMetricActiveMonthsSubtitle => 'Con actividad';

  @override
  String get yearlyActivityTitle => 'Actividad anual';

  @override
  String get yearlyActivitySubtitle =>
      'Un resumen claro de cómo ha evolucionado este hábito durante el año.';

  @override
  String get yearlyActivityBestMonth => 'Mejor mes';

  @override
  String get yearlyActivityWeakestMonth => 'Mes más tranquilo';

  @override
  String get yearlyActivityActiveMonths => 'Meses activos';

  @override
  String yearlyActivityActiveMonthsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mes',
      zero: '0 meses',
    );
    return '$_temp0';
  }

  @override
  String get yearlyActivityTrend => 'Ritmo';

  @override
  String get yearlyActivityTrendImproving => 'Mejorando';

  @override
  String get yearlyActivityTrendStable => 'Estable';

  @override
  String get yearlyActivityTrendDeclining => 'Bajando el ritmo';

  @override
  String get yearlyActivityTrendStarting => 'Empezando';

  @override
  String get yearlyActivityTrendNoData => 'Sin datos aún';

  @override
  String get habitStatsYearlyInsightTitle => 'Insight anual';

  @override
  String get habitStatsYearlyComparisonTitle => 'Comparación anual';

  @override
  String get habitStatsYearlyComparisonImproving =>
      'Los últimos meses van mejor';

  @override
  String get habitStatsYearlyComparisonStable => 'Un año estable por ahora';

  @override
  String get habitStatsYearlyComparisonDeclining => 'El ritmo está bajando';

  @override
  String get habitStatsYearlyComparisonAboveAverage =>
      'Este mes está por encima de tu media anual';

  @override
  String get habitStatsYearlyComparisonBelowAverage =>
      'Este mes está por debajo de tu media anual';

  @override
  String get habitStatsYearlyComparisonStarting => 'Aún construyendo historial';

  @override
  String get habitStatsYearlyComparisonNoData => 'Sin datos anuales aún';

  @override
  String get habitStatsYearlyInsightStrongTitle => 'Año sólido';

  @override
  String get habitStatsYearlyInsightStrongBody =>
      'Este hábito está teniendo un año sólido. Tus mejores meses empiezan a destacar.';

  @override
  String get habitStatsYearlyInsightImprovingTitle => 'Ritmo en mejora';

  @override
  String get habitStatsYearlyInsightImprovingBody =>
      'Tu ritmo está mejorando. Los últimos meses empiezan a ser más constantes.';

  @override
  String get habitStatsYearlyInsightSteadyTitle => 'Ritmo estable';

  @override
  String get habitStatsYearlyInsightSteadyBody =>
      'Mantienes un ritmo estable. Las pequeñas repeticiones están sosteniendo el hábito durante el año.';

  @override
  String get habitStatsYearlyInsightIrregularTitle => 'Año irregular';

  @override
  String get habitStatsYearlyInsightIrregularBody =>
      'Este año ha sido algo irregular. Un pequeño reinicio el próximo mes puede ayudarte a recuperar impulso.';

  @override
  String get habitStatsYearlyInsightQuietTitle => 'Año tranquilo';

  @override
  String get habitStatsYearlyInsightQuietBody =>
      'Este hábito ha estado tranquilo este año. Una sola vez completado puede volver a activar el ritmo.';

  @override
  String get habitStatsYearlyInsightStartingTitle => 'Base anual iniciada';

  @override
  String get habitStatsYearlyInsightStartingBody =>
      'Aún hay poco historial anual, pero ya tienes una base sobre la que construir.';

  @override
  String get habitStatsYearlyInsightNoDataTitle => 'Sin datos anuales';

  @override
  String get habitStatsYearlyInsightNoDataBody =>
      'Todavía no hay actividad anual. Cuando completes este hábito, aparecerá aquí tu insight del año.';

  @override
  String get habitStatsLastWeek => 'Semana pasada';

  @override
  String get habitStatsTimeSlotMorning => 'manana';

  @override
  String get habitStatsTimeSlotAfternoon => 'tarde';

  @override
  String get habitStatsTimeSlotEvening => 'noche';

  @override
  String get habitStatsTimeSlotNight => 'madrugada';

  @override
  String get habitStatsLegendLess => 'Menos';

  @override
  String get habitStatsLegendMore => 'Más';

  @override
  String habitStatsDayTooltip(int day) {
    return 'Día $day';
  }

  @override
  String get habitStatsThisHabitFallback => 'este hábito';

  @override
  String get habitStatsMotivationLead => 'Llevas ';

  @override
  String get habitStatsMotivationWith => ' con ';

  @override
  String get habitStatsMotivationAboveLead => 'estas ';

  @override
  String get habitStatsMotivationAboveKeyword => 'por encima';

  @override
  String get habitStatsMotivationAboveTail => ' de la semana pasada. ';

  @override
  String get habitStatsMotivationBelowLead => 'esta semana vas un poco ';

  @override
  String get habitStatsMotivationBelowKeyword => 'por debajo';

  @override
  String get habitStatsMotivationBelowTail => ' de la anterior. ';

  @override
  String get habitStatsMotivationEqual =>
      'mantienes el ritmo de la semana pasada. ';

  @override
  String get habitStatsMotivationStart => 'buen comienzo. ';

  @override
  String get habitStatsMotivationGoalLead => 'Anticiparte te ayudara a ';

  @override
  String habitStatsMotivationGoalKeyword(int days) {
    return 'llegar a los $days días';
  }

  @override
  String get habitStatsMotivationKeepLead => 'Ahora toca ';

  @override
  String get habitStatsMotivationKeepKeyword => 'mantener la racha';

  @override
  String get habitStatsMotivationKeepTail => ' y consolidarlo.';

  @override
  String get habitStatsMotivationBestTimeLead => ' Prueba a hacerlo en la ';

  @override
  String get habitStatsMotivationBestTimeTail =>
      ', cuando sueles ser más constante.';

  @override
  String habitStatsObjectiveDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Objetivo: # veces al día',
      one: 'Objetivo: # vez al día',
    );
    return '$_temp0';
  }

  @override
  String habitStatsObjectiveDailySingular(int count) {
    return 'Objetivo: $count vez al día';
  }

  @override
  String habitStatsObjectiveDailyPlural(int count) {
    return 'Objetivo: $count veces al día';
  }

  @override
  String habitStatsObjectiveWeekly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Objetivo: # veces por semana',
      one: 'Objetivo: # vez por semana',
    );
    return '$_temp0';
  }

  @override
  String habitStatsObjectiveWeeklySingular(int count) {
    return 'Objetivo: $count vez por semana';
  }

  @override
  String habitStatsObjectiveWeeklyPlural(int count) {
    return 'Objetivo: $count veces por semana';
  }

  @override
  String get habitStatsPerDayCompact => 'al día';

  @override
  String get habitStatsObjectiveFallback => 'Objetivo configurado';

  @override
  String habitStatsTimesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# veces',
      one: '# vez',
    );
    return '$_temp0';
  }

  @override
  String get habitStatsPerWeek => 'Por semana';

  @override
  String get habitStatsMetricCompletion => 'Cumplimiento';

  @override
  String get habitStatsMostFrequentTime => 'Hora más frecuente';

  @override
  String get habitStatsNoData => 'Sin datos';

  @override
  String get habitStatsInsightLabel => 'Insight';

  @override
  String get habitStatsInsightTodaySkippedTitle => 'Día pausado.';

  @override
  String get habitStatsInsightTodaySkippedBody =>
      'La pausa mantiene el contexto sin contar como una repetición.';

  @override
  String get habitStatsInsightTodayCompletedTitle => 'Buen cierre de hoy.';

  @override
  String get habitStatsInsightTodayCompletedBody =>
      'Tu progreso queda protegido por un día más.';

  @override
  String get habitStatsInsightPendingStreakTitle => 'Mantén tu ritmo.';

  @override
  String habitStatsInsightPendingStreakBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Completar hoy llevaría tu racha a $days días.',
      one: 'Completar hoy llevaría tu racha a 1 día.',
    );
    return '$_temp0';
  }

  @override
  String get habitStatsInsightNearMilestoneTitle => 'Hito cerca.';

  @override
  String habitStatsInsightNearMilestoneBody(int days, int milestone) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Estás a $days días de alcanzar $milestone días.',
      one: 'Estás a 1 día de alcanzar $milestone días.',
    );
    return '$_temp0';
  }

  @override
  String get habitStatsInsightCountPartialTitle => 'Ya has empezado.';

  @override
  String get habitStatsInsightCountPartialBody =>
      'Te falta poco para cerrar el objetivo de hoy.';

  @override
  String get habitStatsInsightWeeklyTrendPositiveTitle =>
      'Mejor que la semana pasada.';

  @override
  String get habitStatsInsightWeeklyTrendPositiveBody =>
      'Esta semana estás sumando más ritmo.';

  @override
  String get habitStatsInsightWeeklyTrendNegativeTitle => 'Ritmo más bajo.';

  @override
  String get habitStatsInsightWeeklyTrendNegativeBody =>
      'Esta semana vas algo por debajo de la anterior.';

  @override
  String get habitStatsInsightStrongConsistencyTitle => 'Ritmo sólido.';

  @override
  String get habitStatsInsightStrongConsistencyBody =>
      'Este hábito ya empieza a tener una base estable.';

  @override
  String get habitStatsInsightBestMomentTitle => 'Tu patrón es claro.';

  @override
  String habitStatsInsightBestMomentBody(String moment) {
    return 'La $moment suele ser tu mejor franja.';
  }

  @override
  String get habitStatsInsightRecoveryTitle => 'Vuelve con calma.';

  @override
  String get habitStatsInsightRecoveryBody =>
      'Una repetición pequeña puede reactivar el hábito.';

  @override
  String get habitStatsInsightWeeklyGoalTitle => 'Objetivo semanal cubierto.';

  @override
  String get habitStatsInsightWeeklyGoalBody =>
      'Ya cumpliste lo previsto para esta semana.';

  @override
  String get habitStatsInsightLowConsistencyTitle => 'Vuelve a lo simple.';

  @override
  String get habitStatsInsightLowConsistencyBody =>
      'Una repetición pequeña puede ayudarte a recuperar ritmo.';

  @override
  String get habitStatsInsightFallbackTitle => 'Cada repetición cuenta.';

  @override
  String get habitStatsInsightFallbackBody =>
      'Empieza con una acción pequeña hoy.';

  @override
  String get habitStatsInsightSteadyRoutine =>
      'Vas construyendo una rutina estable.';

  @override
  String get habitStatsInsightGoodRhythm => 'Buen ritmo esta semana.';

  @override
  String get habitStatsInsightEveryRepetition => 'Cada repetición cuenta.';

  @override
  String get habitStatsInsightMonthlyNotStartedTitle => 'Mes por empezar';

  @override
  String get habitStatsInsightMonthlyNotStartedBody =>
      'Todavía no hay registros este mes. Un primer check ya empieza a construir ritmo.';

  @override
  String get habitStatsInsightMonthlyInConstructionTitle =>
      'Mes en construcción';

  @override
  String habitStatsInsightMonthlyInConstructionBody(
      int completed, int objective) {
    return 'Llevas $completed/$objective. Todavía puedes recuperar ritmo con unos días constantes.';
  }

  @override
  String get habitStatsInsightMonthlyInProgressTitle => 'Buen mes en marcha';

  @override
  String habitStatsInsightMonthlyInProgressBody(int completed) {
    return 'Ya completaste $completed veces este mes. Mantén este ritmo sin forzarlo.';
  }

  @override
  String get habitStatsInsightMonthlyStrongTitle => 'Ritmo mensual sólido';

  @override
  String habitStatsInsightMonthlyStrongBody(int completed, int objective) {
    return 'Vas muy bien este mes: $completed/$objective completado.';
  }

  @override
  String get habitStatsInsightMonthlyGoalCompletedTitle =>
      'Objetivo mensual completado';

  @override
  String get habitStatsInsightMonthlyGoalCompletedBody =>
      'Ya has cumplido el objetivo de este mes. Todo lo extra suma sin presión.';

  @override
  String habitStatsInsightMonthlyBestMomentBody(String bestMoment) {
    return 'Tu mejor franja sigue siendo $bestMoment.';
  }

  @override
  String get habitStatsInsightMonthlyComparisonBetter =>
      'Además, vas mejor que el mes pasado.';

  @override
  String get habitStatsInsightMonthlyComparisonSame =>
      'Tu ritmo es parecido al mes pasado.';

  @override
  String get habitStatsInsightMonthlyComparisonWorse =>
      'Vas algo por debajo del mes pasado, pero aún hay margen.';

  @override
  String get editHabitSaveChanges => 'Guardar cambios';

  @override
  String get editHabitSaving => 'Guardando...';

  @override
  String get editHabitNotificationPermissionDenied =>
      'Permisos de notificación denegados.';

  @override
  String get editHabitDailyGoalDialogTitle => 'Meta diaria';

  @override
  String get editHabitDailyGoalDialogSubtitle => 'Escribe el numero objetivo.';

  @override
  String get editHabitCounterStepDialogTitle => 'Incremento';

  @override
  String get editHabitCounterStepDialogSubtitle =>
      'Cada cuanto aumenta el contador.';

  @override
  String get editHabitTimesPerWeekDialogTitle => 'Veces por semana';

  @override
  String get editHabitTimesPerWeekDialogSubtitle =>
      'Puedes superarlo durante la semana.';

  @override
  String get editHabitHeaderTitle => 'Editar hábito';

  @override
  String get editHabitHeaderSubtitle => 'Ajusta cómo quieres continuar.';

  @override
  String get editHabitSectionIdentity => 'Identidad';

  @override
  String get editHabitSectionCategory => 'Categoria';

  @override
  String get editHabitSectionTracking => '¿Cómo lo mides?';

  @override
  String get editHabitSectionFrequency => 'Frecuencia';

  @override
  String get editHabitSectionReminder => 'Recordatorio';

  @override
  String get editHabitSectionDetails => 'Detalles';

  @override
  String get editHabitTitleHint => 'Ej: Meditar cada manana';

  @override
  String get editHabitTrackingCheckTitle => 'Si o no';

  @override
  String get editHabitTrackingCheckSubtitle => 'Lo hice o no lo hice';

  @override
  String get editHabitTrackingCountTitle => 'Contador';

  @override
  String get editHabitTrackingCountSubtitle => 'Vasos, minutos, paginas...';

  @override
  String get editHabitDailyGoalSection => 'Meta diaria';

  @override
  String get editHabitRepetitionsTitle => 'Repeticiones';

  @override
  String get editHabitRepetitionsSubtitle => '¿Cuántas veces al día?';

  @override
  String get editHabitUnitHint => 'Unidad (ej: vasos, km...)';

  @override
  String get editHabitCounterStepTitle => 'Incremento';

  @override
  String get editHabitCounterStepSubtitle => 'Cuanto aumenta cada toque.';

  @override
  String get editHabitFrequencyDaily => 'Cada día';

  @override
  String get editHabitFrequencySpecificDays => 'Días concretos';

  @override
  String get editHabitFrequencyTimesPerWeek => 'X veces / semana';

  @override
  String get editHabitWeeklyGoalTitle => 'Objetivo semanal';

  @override
  String get editHabitWeeklyGoalSubtitle =>
      'Marca cuántas veces quieres completarlo.';

  @override
  String get editHabitReminderDailyTitle => 'Notificación diaria';

  @override
  String get editHabitReminderDailySubtitle =>
      'Elige cuando quieres que te avise';

  @override
  String get editHabitDescriptionHint => 'Descripcion breve';

  @override
  String get editHabitNotesHint => 'Notas o contexto adicional';

  @override
  String get editHabitUnitPickerTitle => 'Unidad';

  @override
  String get editHabitUnitPickerSubtitle =>
      'Elige una sugerencia o escribe una personalizada.';

  @override
  String get editHabitUnitPickerAction => 'Usar unidad';

  @override
  String get editHabitSuggestedUnitGlasses => 'vasos';

  @override
  String get editHabitSuggestedUnitMinutes => 'minutos';

  @override
  String get editHabitSuggestedUnitKilometers => 'km';

  @override
  String get editHabitSuggestedUnitPages => 'paginas';

  @override
  String get editHabitSuggestedUnitSteps => 'pasos';

  @override
  String get editHabitSuggestedUnitRepetitions => 'repeticiones';

  @override
  String get editHabitSuggestedUnitHours => 'horas';

  @override
  String get drawerBrandName => 'rutio';

  @override
  String get drawerBrandTagline => 'CONSTRUYE TU CAMINO';

  @override
  String get drawerSectionViews => 'VISTAS';

  @override
  String get drawerDaily => 'Diario';

  @override
  String get drawerWeekly => 'Semanal';

  @override
  String get drawerMonthly => 'Mensual';

  @override
  String get drawerSectionTracking => 'SEGUIMIENTO';

  @override
  String get drawerStatistics => 'Estadísticas';

  @override
  String get drawerStatisticsV3 => 'Estadísticas V3';

  @override
  String get drawerDiary => 'Diario (Journal)';

  @override
  String get drawerSectionArchive => 'ARCHIVO';

  @override
  String get drawerArchived => 'Archivados';

  @override
  String get drawerSectionAccount => 'CUENTA';

  @override
  String get drawerProfile => 'Mi perfil';

  @override
  String get drawerProfileVersion => 'v0.1 alpha';

  @override
  String get weeklyScreenUnavailableSoon => 'Pantalla no disponible todavía.';

  @override
  String get weeklyScreenUnavailable => 'Pantalla no disponible';

  @override
  String get weeklyWeekPrefix => 'Semana';

  @override
  String weeklyActiveHabitsCount(String count) {
    return '$count HABITOS ACTIVOS';
  }

  @override
  String get weeklyShowHabitNameHint => '<- toca el emoji para ver el nombre';

  @override
  String get weeklyViewMenuTitle => 'Cambiar vista';

  @override
  String get weeklyViewMenuDailyTitle => 'Vista diaria';

  @override
  String get weeklyViewMenuDailySubtitle => 'Ver hábitos de hoy';

  @override
  String get weeklyViewMenuWeeklyTitle => 'Vista semanal';

  @override
  String get weeklyViewMenuWeeklySubtitle => 'Actual';

  @override
  String get weeklyViewMenuMonthlyTitle => 'Vista mensual';

  @override
  String get weeklyViewMenuMonthlySubtitle => 'Ver progreso del mes';

  @override
  String get drawerTodo => 'To-do';

  @override
  String get familyPersonalName => 'Personal';

  @override
  String get todoTitle => 'To-dos';

  @override
  String get todoDateTodayFormatLabel => 'Hoy';

  @override
  String get todoFilterAll => 'Todos';

  @override
  String get todoFilterPending => 'Pendientes';

  @override
  String get todoFilterToday => 'Hoy';

  @override
  String get todoFilterThisWeek => 'Esta semana';

  @override
  String get todoFilterCompleted => 'Completadas';

  @override
  String get todoProgressToday => 'PROGRESO HOY';

  @override
  String todoTasksCount(String total) {
    return ' / $total tareas';
  }

  @override
  String todoPendingCount(int count) {
    return '$count pendientes';
  }

  @override
  String todoOverdueCount(int count) {
    return '$count vencida';
  }

  @override
  String todoSectionPending(int count) {
    return 'PENDIENTES · $count';
  }

  @override
  String todoSectionCompleted(int count) {
    return 'COMPLETADOS · $count';
  }

  @override
  String get todoCreateTitle => 'Nueva tarea';

  @override
  String get todoEditTitle => 'Editar tarea';

  @override
  String get todoCancel => 'Cancelar';

  @override
  String get todoSave => 'Guardar';

  @override
  String get todoTypeFree => 'Tarea libre';

  @override
  String get todoTypeLinkedHabit => 'Vinculada a hábito';

  @override
  String get todoWhatNeedToDo => '¿Qué tienes que hacer?';

  @override
  String get todoDescriptionOptional => 'Descripción (opcional)';

  @override
  String get todoWhen => 'CUÁNDO';

  @override
  String get todoDate => 'Fecha';

  @override
  String get todoSelect => 'Seleccionar';

  @override
  String get todoTime => 'Hora';

  @override
  String get todoNoTime => 'Sin hora';

  @override
  String get todoCategory => 'CATEGORÍA';

  @override
  String get todoPriority => 'PRIORIDAD';

  @override
  String get todoNotes => 'NOTAS';

  @override
  String get todoAddNote => 'Añade una nota...';

  @override
  String get todoPriorityNone => '—';

  @override
  String get todoPriorityNormal => 'Normal';

  @override
  String get todoPriorityHigh => 'Alta';

  @override
  String get todoPriorityUrgent => 'Urgente';

  @override
  String get todoPriorityHighBadge => 'Prioritaria';

  @override
  String get todoPriorityUrgentBadge => 'Urgente';

  @override
  String todoXpReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get todoStatusOverdueYesterday => 'Vencida ayer';

  @override
  String todoStatusOverdueDate(String date) {
    return 'Vencida $date';
  }

  @override
  String todoStatusTodayAt(String time) {
    return 'Hoy · $time';
  }

  @override
  String get todoStatusDueToday => 'Hoy';

  @override
  String get todoStatusThisWeek => 'Esta semana';

  @override
  String todoStatusOnDate(String date) {
    return '$date';
  }

  @override
  String get todoMockMeditateTitle => 'Meditar 10 minutos antes de dormir';

  @override
  String get todoMockReadTitle => 'Leer 20 páginas del libro actual';

  @override
  String get todoMockGroceriesTitle => 'Preparar la lista de la compra semanal';

  @override
  String get todoMockDoctorTitle => 'Llamar al médico para pedir cita';

  @override
  String get todoMockCardioTitle => 'Ejercicio matutino: 30 min cardio';

  @override
  String get todoMockWaterTitle => 'Preparar botella de agua y mochila';

  @override
  String get todoMockReviewGoalsTitle => 'Revisar prioridades clave del día';

  @override
  String get todoMockEncouragementTitle => 'Enviar un mensaje de ánimo';

  @override
  String get todoMockPrayerTitle => 'Momento breve de oración';

  @override
  String get todoMockInboxTitle => 'Vaciar correos importantes';

  @override
  String get todoMockJournalTitle => 'Journaling emocional de 5 minutos';

  @override
  String get todoEmptyStateTitle => 'Todavía no tienes tareas';

  @override
  String get todoEmptyStateBody =>
      'Crea tu primera tarea para empezar a organizar este espacio.';

  @override
  String get todoCreateFirstTask => 'Crear primera tarea';

  @override
  String get diaryFiltersTitle => 'Filtros';

  @override
  String get diaryFiltersType => 'Tipo';

  @override
  String get diaryFiltersPinnedOnly => 'Solo fijadas';

  @override
  String get diaryFiltersFamily => 'Familia';

  @override
  String get diaryFiltersApply => 'Aplicar';

  @override
  String diaryAfterCompleteTitle(String habitName) {
    return 'Hábito completado: $habitName';
  }

  @override
  String get diaryAfterCompletePrompt => '¿Quieres añadir una nota rápida?';

  @override
  String get diaryAfterCompleteSkip => 'Ahora no';

  @override
  String get diaryAfterCompleteWrite => 'Escribir';

  @override
  String get diaryGeneralFamilyName => 'General';

  @override
  String get diaryCardTypeHabitShort => 'DÍA';

  @override
  String get diaryCardTypePersonalShort => 'NOTA';

  @override
  String get diaryShowMore => 'Ver más';

  @override
  String get diaryShowLess => 'Ver menos';

  @override
  String diaryStreakLabel(int count, String sufix) {
    return 'Racha: $count día$sufix';
  }

  @override
  String get diaryEmotionalStreakTitle => 'Racha emocional';

  @override
  String diaryDaysLabel(int count, String sufix) {
    return '$count día$sufix';
  }

  @override
  String get monthShortJan => 'Ene';

  @override
  String get monthShortFeb => 'Feb';

  @override
  String get monthShortMar => 'Mar';

  @override
  String get monthShortApr => 'Abr';

  @override
  String get monthShortMay => 'May';

  @override
  String get monthShortJun => 'Jun';

  @override
  String get monthShortJul => 'Jul';

  @override
  String get monthShortAug => 'Ago';

  @override
  String get monthShortSep => 'Sep';

  @override
  String get monthShortOct => 'Oct';

  @override
  String get monthShortNov => 'Nov';

  @override
  String get monthShortDec => 'Dic';

  @override
  String get createHabitNewHabitTitle => 'Nuevo hábito';

  @override
  String get createHabitHeaderSubtitle => 'Pequeños pasos, progreso constante.';

  @override
  String get createHabitNameLabel => 'NOMBRE DEL HÁBITO';

  @override
  String get createHabitNameHelper =>
      'Un nombre claro te ayuda a mantener el foco.';

  @override
  String get createHabitSectionCategory => 'Categoría';

  @override
  String get createHabitSectionTracking => 'Tipo de seguimiento';

  @override
  String get createHabitSectionFrequency => 'Frecuencia';

  @override
  String get createHabitTrackingCheckTitle => 'Sí / No';

  @override
  String get createHabitTrackingCheckSubtitle => 'Complétalo una vez';

  @override
  String get createHabitTrackingCountTitle => 'Contador';

  @override
  String get createHabitTrackingCountSubtitle =>
      'Registra cantidad, minutos, páginas...';

  @override
  String get createHabitCounterGoalTitle => 'Objetivo diario';

  @override
  String get createHabitCounterGoalSubtitle =>
      'Define la cantidad que quieres alcanzar cada día.';

  @override
  String get createHabitCounterGoalExamples =>
      'Ejemplos: 8 vasos, 20 páginas, 30 minutos';

  @override
  String get createHabitCounterTargetAmountLabel => 'Cantidad objetivo';

  @override
  String get createHabitCounterUnitLabel => 'Unidad';

  @override
  String get createHabitCounterQuickUnitsLabel => 'Unidades rápidas';

  @override
  String get createHabitCounterQuickUnitMinutes => 'minutos';

  @override
  String get createHabitCounterQuickUnitPages => 'páginas';

  @override
  String get createHabitCounterQuickUnitGlasses => 'vasos';

  @override
  String get createHabitCounterQuickUnitReps => 'reps';

  @override
  String get createHabitCounterQuickUnitCustom => '+ Personalizada';

  @override
  String get createHabitCounterExampleTitle => 'Ejemplo: 10 minutos';

  @override
  String get createHabitCounterExampleSubtitle =>
      'Registra el tiempo total que dedicas a meditar.';

  @override
  String get createHabitFrequencyDailyTitle => 'Cada día';

  @override
  String get createHabitFrequencyDailySubtitle =>
      'Se repite cada día hasta que lo cambies.';

  @override
  String get createHabitFrequencySpecificTitle => 'Días concretos';

  @override
  String get createHabitFrequencySpecificSubtitle =>
      'Elige qué días de la semana aparece.';

  @override
  String get createHabitFrequencyTimesPerWeekTitle => 'X veces por semana';

  @override
  String get createHabitFrequencyTimesPerWeekSubtitle =>
      'Objetivo semanal flexible. Complétalo cualquier día.';

  @override
  String get createHabitRoutineTitle => 'Añadir a rutina';

  @override
  String get createHabitOptionalPill => 'Opcional';

  @override
  String get createHabitRoutineSubtitle =>
      'Coloca este hábito dentro de una rutina de mañana o noche.';

  @override
  String get createHabitRoutineSheetSubtitle =>
      'Elige dónde podría vivir este hábito más adelante.';

  @override
  String get createHabitRoutineMorningTitle => 'Ritual de mañana';

  @override
  String get createHabitRoutineMorningSubtitle =>
      'Empieza el día con intención.';

  @override
  String get createHabitRoutineDeepFocusTitle => 'Foco profundo';

  @override
  String get createHabitRoutineDeepFocusSubtitle =>
      'Agrupa hábitos que te ayudan a concentrarte.';

  @override
  String get createHabitRoutineEveningTitle => 'Cierre del día';

  @override
  String get createHabitRoutineEveningSubtitle =>
      'Baja el ritmo y cierra el día.';

  @override
  String get createHabitRoutineSoon => 'Pronto';

  @override
  String get createHabitRoutineCreateNew => 'Crear nueva rutina';

  @override
  String get createHabitRoutineNotNow => 'Ahora no';

  @override
  String get createHabitComingSoon => 'Próximamente';

  @override
  String get createHabitRoutineComingSoonDialogBody =>
      'La asignación a rutinas llegará pronto. Puedes guardar este hábito ahora.';

  @override
  String get createHabitReminderTitle => 'Recordatorio';

  @override
  String get createHabitReminderEnabledSubtitle => 'Recordatorio diario';

  @override
  String get createHabitReminderDisabledSubtitle => 'Recordatorio desactivado';

  @override
  String get createHabitReminderTimeTitle => 'Hora del recordatorio';

  @override
  String get createHabitDone => 'Listo';

  @override
  String get createHabitSaveHabit => 'Guardar hábito';

  @override
  String get createHabitSaved => 'Guardado';

  @override
  String get emojiPickerTitle => 'Selecciona un emoji';

  @override
  String emojiPickerCurrent(String emoji) {
    return 'Actual: $emoji';
  }

  @override
  String get emojiPickerBrowseSubtitle =>
      'Catalogo completo con categorias y busqueda';

  @override
  String get emojiPickerNoRecents => 'Tus emojis recientes aparecerán aquí';

  @override
  String get emojiPickerSearchHint => 'Buscar emoji';

  @override
  String get monthlyDefaultUsername => 'Usuario';

  @override
  String get monthlyEmptyFilteredMessage =>
      'No hay hábitos para mostrar en este filtro.';

  @override
  String monthlyElapsedDaysWeek(int elapsed, int week) {
    return '$elapsed días transcurridos · semana $week';
  }

  @override
  String monthlyFilterSummaryFamily(String family) {
    return 'Familia: $family';
  }

  @override
  String monthlyFilterSummaryHabit(String habit) {
    return 'Hábito: $habit';
  }

  @override
  String get monthlyFilterSummaryAll => 'Todos los hábitos';

  @override
  String get monthlyFiltersTooltip => 'Filtros';

  @override
  String get monthlyResetTooltip => 'Restablecer';

  @override
  String get monthlyFiltersTitle => 'Filtros';

  @override
  String get monthlyResetAction => 'Restablecer';

  @override
  String get monthlyFilterModeAll => 'Todos';

  @override
  String get monthlyFilterModeFamily => 'Familia';

  @override
  String get monthlyFilterModeHabit => 'Hábito';

  @override
  String get monthlyApplyAction => 'Aplicar';

  @override
  String get monthlySelectHabitLabel => 'Selecciona un hábito';

  @override
  String get monthlyHabitSelectorTitle => 'VER HABITO';

  @override
  String get monthlyHabitFallbackTitle => 'Hábito';

  @override
  String get monthlyStatMonthLabel => 'MES';

  @override
  String get monthlyStatStreakLabel => 'RACHA';

  @override
  String get monthlyStatHabitsLabel => 'HABITOS';

  @override
  String monthlyDaysLabel(int count, String sufix) {
    return '$count día$sufix';
  }

  @override
  String get monthlyCurrentStreakSoft => 'racha actual';

  @override
  String get monthlyBestStreakSoft => 'mejor racha';

  @override
  String get monthlySelectionToday => 'Hoy';

  @override
  String get monthlySelectionDone => 'Completado';

  @override
  String get monthlySelectionSkipped => 'Saltado';

  @override
  String get monthlySelectionPending => 'Pendiente';

  @override
  String get monthlySelectionFuture => 'Futuro';

  @override
  String get monthlySelectionUnscheduled => 'Sin programar';

  @override
  String get monthlySelectionSelected => 'Seleccionado';

  @override
  String monthlySelectionLabel(int day, int month, String state) {
    return '$day/$month · $state';
  }

  @override
  String get monthlyCurrentMonthTooltip => 'Ir a este mes';

  @override
  String get monthlyMenuTooltip => 'Menu';

  @override
  String get shopTitle => 'Tienda';

  @override
  String get shopHomeSubtitle => 'Mejora tu experiencia Rutio';

  @override
  String get shopExploreTitle => 'Explora';

  @override
  String get shopExploreSubtitle =>
      'Tres accesos rápidos para entrar en la nueva tienda.';

  @override
  String get shopCosmeticsTitle => 'Cosméticos';

  @override
  String get shopCosmeticsSubtitle =>
      'Fondos, tarjetas de hábitos y tarjetas de usuario con estilo Rutio.';

  @override
  String get shopUtilitiesTitle => 'Utilidades';

  @override
  String get shopUtilitiesSubtitle =>
      'Boosts y ayudas listas para integrarse más adelante.';

  @override
  String get shopBackpackTitle => 'Mochila';

  @override
  String get shopBackpackSubtitle => 'Gestiona tus consumibles';

  @override
  String get shopCustomizationTitle => 'Personalización';

  @override
  String get shopCustomizationSubtitle =>
      'Gestiona los cosméticos que ya son tuyos';

  @override
  String get shopCollectionsTitle => 'Colecciones';

  @override
  String get shopCollectionsSubtitle => 'Cada colección es un pequeño universo';

  @override
  String get shopDetailTitle => 'Detalle';

  @override
  String get shopDetailUnavailableTitle => 'Detalle no disponible';

  @override
  String get shopDetailUnavailableMessage =>
      'No hemos podido cargar este item.';

  @override
  String get shopNoDescriptionYet => 'Sin descripción todavía.';

  @override
  String get shopEmptyStateNoResultsTitle => 'Sin resultados';

  @override
  String get shopEmptyStateNoResultsMessage =>
      'No hay resultados para este filtro.';

  @override
  String get shopEmptyBackpackTitle => 'La mochila está vacía';

  @override
  String get shopEmptyBackpackMessage =>
      'Las utilidades compradas aparecerán aquí.';

  @override
  String get shopEmptyUtilitiesTitle => 'Nada por mostrar';

  @override
  String get shopEmptyUtilitiesMessage =>
      'No hay utilidades disponibles en esta categoría.';

  @override
  String get shopEmptyCollectionsTitle => 'No hay colecciones disponibles.';

  @override
  String get shopEmptyCollectionsMessage =>
      'Vuelve más tarde para descubrir nuevas colecciones.';

  @override
  String get shopActionBuy => 'Comprar';

  @override
  String get shopActionBuyPack => 'Comprar pack';

  @override
  String get shopActionActivate => 'Activar';

  @override
  String get shopActionOpen => 'Abrir';

  @override
  String get shopActionContinue => 'Continuar';

  @override
  String get shopActionUse => 'Usar';

  @override
  String get shopActionAccept => 'Aceptar';

  @override
  String get shopActionEquip => 'Equipar';

  @override
  String get shopActionEquipped => 'Equipado';

  @override
  String get shopActionAvailable => 'Disponible';

  @override
  String get shopActionActive => 'Activo';

  @override
  String get shopStatusPurchased => 'Comprado';

  @override
  String get shopStatusBlocked => 'Bloqueado';

  @override
  String get shopStatusIncludedInPack => 'Incluido en pack';

  @override
  String get shopStatusInsufficientCoins => 'Saldo insuficiente';

  @override
  String get shopStatusProcessing => 'Procesando...';

  @override
  String get shopStatusBusyOpening => 'Abriendo...';

  @override
  String get shopRarityCommon => 'Común';

  @override
  String get shopRarityUncommon => 'Poco común';

  @override
  String get shopRarityRare => 'Raro';

  @override
  String get shopRarityEpic => 'Épico';

  @override
  String get shopRarityLegendary => 'Legendario';

  @override
  String get shopFilterAll => 'Todos';

  @override
  String get shopFilterBoosts => 'Boosts';

  @override
  String get shopFilterStreak => 'Racha';

  @override
  String get shopFilterBoxes => 'Cajas';

  @override
  String get shopFilterWallpapers => 'Fondos';

  @override
  String get shopFilterCards => 'Tarjetas';

  @override
  String get shopFilterPacks => 'Packs';

  @override
  String get shopCategoryPack => 'Pack';

  @override
  String get shopCategoryWallpaper => 'Fondo';

  @override
  String get shopCategoryHabitCard => 'Tarjeta de hábitos';

  @override
  String get shopCategoryUserCard => 'Tarjeta de usuario';

  @override
  String get shopCategoryUtility => 'Utilidad';

  @override
  String get shopCategoryBoosts => 'Boosts';

  @override
  String get shopCategoryStreaks => 'Rachas';

  @override
  String get shopCategoryBoxes => 'Cajas';

  @override
  String shopPriceCoins(int value) {
    return '$value monedas';
  }

  @override
  String shopPriceAmber(int value) {
    return '$value ámbar';
  }

  @override
  String shopRemainingUses(int remaining, int total) {
    return '$remaining de $total completaciones';
  }

  @override
  String shopOwnedCount(int count) {
    return '$count objetos';
  }

  @override
  String shopBackpackCount(int count) {
    return 'Mochila x$count';
  }

  @override
  String get shopXpBoostTitle => 'Potenciador de XP de 1 día';

  @override
  String get shopXpBoostDescription =>
      'Aumenta temporalmente la experiencia obtenida al completar hábitos.';

  @override
  String get shopXpBoostEffect => 'Multiplicador de XP x2';

  @override
  String get shopCoinBoostTitle => 'Potenciador de monedas de 1 día';

  @override
  String get shopCoinBoostDescription =>
      'Aumenta temporalmente las monedas obtenidas al completar hábitos.';

  @override
  String get shopCoinBoostEffect => 'Multiplicador de monedas x2';

  @override
  String get shopStreakRecoverTitle => 'Recuperación de racha';

  @override
  String get shopStreakRecoverDescription =>
      'Recupera una racha perdida una vez.';

  @override
  String get shopStreakRecoverEffect => 'Recuperación de racha';

  @override
  String get shopStreakShieldTitle => 'Escudo de racha';

  @override
  String get shopStreakShieldDescription =>
      'Protege una racha frente a un día fallado.';

  @override
  String get shopStreakShieldEffect => 'Protección de racha';

  @override
  String get shopMysteryBoxTitle => 'Caja misteriosa';

  @override
  String get shopMysteryBoxDescription =>
      'Una caja misteriosa básica con una sorpresa en su interior.';

  @override
  String get shopMysteryBoxEffect => 'Sorpresa futura';

  @override
  String shopUtilityDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String shopUtilityCharges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usos',
      one: '1 uso',
    );
    return '$_temp0';
  }

  @override
  String get shopMysteryBoxOpeningTitle => 'Tu Mystery Box está lista';

  @override
  String get shopMysteryBoxTapToOpen => 'Pulsa para abrir';

  @override
  String get shopMysteryBoxOpenButton => 'Abrir Mystery Box';

  @override
  String get shopMysteryBoxRewardTitle => 'Tu recompensa';

  @override
  String get shopMysteryBoxRewardContinue => 'Continuar';

  @override
  String get shopMysteryBoxRewardDescription =>
      'La apertura ha terminado. Todo ya está guardado en tu cuenta y en tu mochila.';

  @override
  String get shopMysteryBoxErrorNoBoxes =>
      'No quedan Mystery Boxes disponibles.';

  @override
  String get shopMysteryBoxErrorConfig =>
      'La Mystery Box no está configurada correctamente.';

  @override
  String get shopMysteryBoxErrorPersist =>
      'No pudimos guardar la apertura. Inténtalo otra vez.';

  @override
  String get shopMysteryBoxErrorPending =>
      'Ya hay una apertura pendiente para esta Mystery Box.';

  @override
  String get shopMysteryBoxErrorOpen =>
      'No pudimos completar la apertura. Inténtalo otra vez.';

  @override
  String get shopMysteryBoxErrorReward => 'No pudimos mostrar la recompensa.';

  @override
  String get shopCollectionMinimalTitle => 'Minimal';

  @override
  String get shopCollectionMinimalDescription =>
      'Colores planos y familias suaves para una base calmada.';

  @override
  String get shopCollectionGradientTitle => 'Gradient';

  @override
  String get shopCollectionGradientDescription =>
      'Texturas y degradados sutiles con identidad editorial.';

  @override
  String get shopCollectionLandscapeTitle => 'Landscape';

  @override
  String get shopCollectionLandscapeDescription =>
      'Composiciones con más presencia visual y profundidad suave.';

  @override
  String get shopConfirmPurchaseTitle => 'Confirmar compra';

  @override
  String get shopCancel => 'Cancelar';

  @override
  String get shopPriceLabel => 'Precio';

  @override
  String get shopCurrentBalanceLabel => 'Saldo actual';

  @override
  String get shopRemainingBalanceLabel => 'Saldo restante';

  @override
  String get shopCategoryLabel => 'Categoría';

  @override
  String get shopOriginalPriceLabel => 'Precio original';

  @override
  String get shopSavingsLabel => 'Ahorro';

  @override
  String get shopIncludesLabel => 'Incluye';

  @override
  String get shopRarityLabel => 'Rareza';

  @override
  String get shopTypeLabel => 'Tipo';

  @override
  String get shopStyleLabel => 'Estilo';

  @override
  String get shopStatusLabel => 'Estado';

  @override
  String get shopDurationLabel => 'Duración';

  @override
  String get shopEffectLabel => 'Efecto';

  @override
  String get shopProcessingLabel => 'Procesando...';

  @override
  String get shopBackpackEmptyAction => 'Ir a Utilidades';

  @override
  String get shopBackpackActiveEffectsTitle => 'Efectos activos';

  @override
  String get shopBackpackActiveEffectsEmpty => 'No tienes efectos activos.';

  @override
  String get shopBackpackActiveEffectsActiveLabel => 'Activo';

  @override
  String shopBackpackActiveEffectsProgressLabel(int remaining, int total) {
    return '$remaining de $total usos restantes';
  }

  @override
  String get shopHomeHeroTitle => 'Tu espacio, más tuyo';

  @override
  String get shopHomeHeroSubtitle => 'Combina fondos, cards y estilo Rutio';

  @override
  String get shopHomeHeroBackpackTitle => 'Mochila';

  @override
  String get shopHomeHeroBackpackSubtitle => 'Tus objetos';

  @override
  String get shopHomeHeroCustomizationTitle => 'Personalizar';

  @override
  String get shopHomeHeroCustomizationSubtitle => 'Tu estilo';

  @override
  String get shopCollectionStatusCompleted => 'Completada';

  @override
  String get shopCollectionStatusStarted => 'Empezada';

  @override
  String get shopCollectionStatusNew => 'Nueva';

  @override
  String get shopCollectionStatusBlocked => 'Bloqueada';

  @override
  String shopCollectionItemsLabel(int count) {
    return '$count objetos';
  }

  @override
  String get shopCollectionViewCollection => 'Ver colección';

  @override
  String get pnGeneralMorningGentle01Title => 'Rutio sigue aquí';

  @override
  String get pnGeneralMorningGentle01Body =>
      'Empieza a tu ritmo. Un paso pequeño también cuenta.';

  @override
  String get pnGeneralMorningGentle02Title => 'Un comienzo tranquilo';

  @override
  String get pnGeneralMorningGentle02Body =>
      'Hoy puedes volver a empezar sin prisa.';

  @override
  String pnGeneralMorningGentle02BodyWithName(String displayName) {
    return '$displayName, hoy puedes volver a empezar sin prisa.';
  }

  @override
  String get pnGeneralMorningFocus01Title => 'Una intención para hoy';

  @override
  String pnGeneralMorningFocus01Body(String weekday) {
    return '$weekday puede empezar con algo sencillo y valioso.';
  }

  @override
  String get pnGeneralMotivationGentle01Title => 'Sigue a tu manera';

  @override
  String get pnGeneralMotivationGentle01Body =>
      'No hace falta hacerlo perfecto para seguir avanzando.';

  @override
  String get pnGeneralMotivationGentle02Title => 'Un recordatorio amable';

  @override
  String get pnGeneralMotivationGentle02Body =>
      'Lo importante hoy es no perder el hilo.';

  @override
  String pnGeneralMotivationGentle02BodyWithName(String displayName) {
    return '$displayName, lo importante hoy es no perder el hilo.';
  }

  @override
  String get pnGeneralPendingProgress01Title => 'Aún hay margen';

  @override
  String pnGeneralPendingProgress01Body(int pendingCount) {
    return 'Te quedan $pendingCount cosas por cerrar hoy, sin presión.';
  }

  @override
  String get pnGeneralPendingProgress02Title => 'Tu día sigue abierto';

  @override
  String pnGeneralPendingProgress02Body(int pendingCount, int totalCount) {
    return 'Quedan $pendingCount de $totalCount. Si te encaja, todavía puedes sumar una más.';
  }

  @override
  String get pnGeneralPendingProgress03Title => 'Vas construyendo';

  @override
  String pnGeneralPendingProgress03Body(String progress) {
    return 'Hoy ya llevas $progress. Un paso más también sería una buena señal.';
  }

  @override
  String get pnGeneralStrongProgress01Title => 'Buen ritmo';

  @override
  String pnGeneralStrongProgress01Body(String progress) {
    return 'Ese $progress ya dice mucho de tu constancia de hoy.';
  }

  @override
  String get pnGeneralStrongProgress02Title => 'Se nota el avance';

  @override
  String pnGeneralStrongProgress02Body(int completedCount, int totalCount) {
    return 'Llevas $completedCount de $totalCount. Vas dejando huella en el día.';
  }

  @override
  String get pnGeneralCompletedDay01Title => 'Día bien cuidado';

  @override
  String pnGeneralCompletedDay01Body(int completedCount) {
    return 'Hoy ya has completado $completedCount. Eso también merece un momento de reconocimiento.';
  }

  @override
  String get pnGeneralCompletedDay02Title => 'Cierre con calma';

  @override
  String pnGeneralCompletedDay02Body(String progress, String timeOfDay) {
    return 'Con $progress a las $timeOfDay, tu día ya tiene forma.';
  }

  @override
  String get pnGeneralStreakEncouragement01Title => 'Tu racha importa';

  @override
  String pnGeneralStreakEncouragement01Body(int streak) {
    return 'Llevas $streak días seguidos. Aún estás a tiempo de cuidarla hoy.';
  }

  @override
  String get pnGeneralStreakEncouragement02Title => 'Constancia que se nota';

  @override
  String pnGeneralStreakEncouragement02Body(String displayName, int streak) {
    return '$displayName, ya son $streak días. Hoy puede ser otro paso tranquilo.';
  }

  @override
  String get pnGeneralComebackGentle01Title => 'Cuando quieras volver';

  @override
  String get pnGeneralComebackGentle01Body =>
      'Rutio sigue en el mismo sitio. Puedes retomar desde donde te nazca.';

  @override
  String get pnGeneralComebackGentle02Title => 'Sin empezar de cero';

  @override
  String get pnGeneralComebackGentle02Body =>
      'Aquí sigues teniendo un lugar para volver con calma.';

  @override
  String pnGeneralComebackGentle02BodyWithName(String displayName) {
    return '$displayName, aquí sigues teniendo un lugar para volver con calma.';
  }

  @override
  String get pnGeneralReflectionPrompt01Title => 'Un minuto para mirar el día';

  @override
  String get pnGeneralReflectionPrompt01Body =>
      'Quizá te venga bien dejar una nota sobre cómo ha ido hoy.';

  @override
  String get pnGeneralReflectionPrompt02Title =>
      'Tu día también merece palabras';

  @override
  String get pnGeneralReflectionPrompt02Body =>
      'Si te apetece, puedes dejar por escrito lo que hoy te dejó.';

  @override
  String pnGeneralReflectionPrompt02BodyWithName(String displayName) {
    return '$displayName, si te apetece, puedes dejar por escrito lo que hoy te dejó.';
  }

  @override
  String get pnGeneralConsistencyGentle01Title =>
      'La constancia se está notando';

  @override
  String pnGeneralConsistencyGentle01Body(int streak) {
    return '$streak días seguidos no aparecen por casualidad.';
  }

  @override
  String get pnGeneralConsistencyGentle02Title => 'Paso a paso';

  @override
  String pnGeneralConsistencyGentle02Body(String progress) {
    return 'Ese $progress encaja con una rutina que ya va tomando forma.';
  }

  @override
  String get pnGeneralEncouragementNeutral01Title => 'Sigue sumando';

  @override
  String get pnGeneralEncouragementNeutral01Body =>
      'No hace falta correr. Lo importante es seguir en contacto con lo que te importa.';

  @override
  String get pnGeneralEncouragementNeutral02Title => 'Todavía cuenta';

  @override
  String get pnGeneralEncouragementNeutral02Body =>
      'Aunque el día vaya rápido, aún puedes guardar un pequeño espacio para ti.';

  @override
  String pnGeneralEncouragementNeutral02BodyWithName(String displayName) {
    return '$displayName, aunque el día vaya rápido, aún puedes guardar un pequeño espacio para ti.';
  }

  @override
  String get pnGeneralProgressHabit01Title => 'Un hábito que sigue vivo';

  @override
  String pnGeneralProgressHabit01Body(String habitName, String progress) {
    return '$habitName ya va en $progress. Va cogiendo continuidad.';
  }

  @override
  String get pnGeneralEncouragementWeekday01Title => 'Aún queda día';

  @override
  String pnGeneralEncouragementWeekday01Body(String weekday, String timeOfDay) {
    return 'Si $weekday te deja un hueco hacia las $timeOfDay, puede ser un buen momento para volver a ti.';
  }

  @override
  String get pnGeneralReflectionProgress01Title => 'El día ya tiene historia';

  @override
  String pnGeneralReflectionProgress01Body(int completedCount, int totalCount) {
    return 'Has cerrado $completedCount de $totalCount. Quizá apetezca mirar qué te ayudó hoy.';
  }

  @override
  String get pnGeneralConsistencyName01Title => 'Tu ritmo cuenta';

  @override
  String pnGeneralConsistencyName01Body(String displayName, String progress) {
    return '$displayName, ese $progress habla de una constancia muy tuya.';
  }

  @override
  String get pnJournalNudgeMilestone7Insight01Title => 'Primeras señales';

  @override
  String get pnJournalNudgeMilestone7Insight01Body =>
      '¿Qué te ayudó a empezar y volver esta semana?';

  @override
  String get pnJournalNudgeMilestone7Change01Title => 'Un comienzo que cambia';

  @override
  String get pnJournalNudgeMilestone7Change01Body =>
      '¿Qué notas distinto después de estos primeros días?';

  @override
  String get pnJournalNudgeMilestone7Ease01Title => 'Tu forma de volver';

  @override
  String get pnJournalNudgeMilestone7Ease01Body =>
      '¿Qué hizo más fácil retomar el hábito?';

  @override
  String get pnJournalNudgeMilestone7Return01Title =>
      'Algo empieza a funcionar';

  @override
  String get pnJournalNudgeMilestone7Return01Body =>
      '¿Qué parece estar funcionando para ti?';

  @override
  String get pnJournalNudgeMilestone7Memory01Title => 'Guarda este comienzo';

  @override
  String get pnJournalNudgeMilestone7Memory01Body =>
      '¿Qué te gustaría recordar de esta primera semana?';

  @override
  String get pnJournalNudgeMilestone14Insight01Title => 'Patrones que aparecen';

  @override
  String get pnJournalNudgeMilestone14Insight01Body =>
      '¿Qué patrón empiezas a reconocer en estas dos semanas?';

  @override
  String get pnJournalNudgeMilestone14Change01Title => 'Cada vez más natural';

  @override
  String get pnJournalNudgeMilestone14Change01Body =>
      '¿Qué parte del hábito empieza a salirte sin pensarlo tanto?';

  @override
  String get pnJournalNudgeMilestone14Ease01Title => 'Lo que te sostiene';

  @override
  String get pnJournalNudgeMilestone14Ease01Body =>
      '¿Qué te ha ayudado a mantener el hábito estos días?';

  @override
  String get pnJournalNudgeMilestone14Return01Title =>
      'Una forma que se consolida';

  @override
  String get pnJournalNudgeMilestone14Return01Body =>
      '¿Qué has aprendido sobre tu manera de volver?';

  @override
  String get pnJournalNudgeMilestone14Memory01Title =>
      'Dos semanas en perspectiva';

  @override
  String get pnJournalNudgeMilestone14Memory01Body =>
      '¿Qué empieza a consolidarse en tu rutina?';

  @override
  String get pnJournalNudgeMilestone30Insight01Title => 'Un mes de perspectiva';

  @override
  String get pnJournalNudgeMilestone30Insight01Body =>
      '¿Qué cambio ves al mirar atrás un mes?';

  @override
  String get pnJournalNudgeMilestone30Change01Title =>
      'Ya forma parte de tus días';

  @override
  String get pnJournalNudgeMilestone30Change01Body =>
      '¿Qué empieza a formar parte de tu rutina?';

  @override
  String get pnJournalNudgeMilestone30Ease01Title => 'Lo que has aprendido';

  @override
  String get pnJournalNudgeMilestone30Ease01Body =>
      '¿Qué has aprendido sobre lo que te ayuda a mantenerlo?';

  @override
  String get pnJournalNudgeMilestone30Return01Title =>
      'Mirar hacia el próximo mes';

  @override
  String get pnJournalNudgeMilestone30Return01Body =>
      '¿Qué quieres llevar contigo al próximo mes?';

  @override
  String get pnJournalNudgeMilestone30Memory01Title =>
      'Lo que quieres conservar';

  @override
  String get pnJournalNudgeMilestone30Memory01Body =>
      '¿Qué merece quedarse de este mes?';

  @override
  String get pnJournalNudgePerfectDayInsight01Title => 'Una pista de hoy';

  @override
  String get pnJournalNudgePerfectDayInsight01Body =>
      '¿Qué crees que te ayudó a completar tus hábitos?';

  @override
  String get pnJournalNudgePerfectDayDifference01Title => 'Algo que repetirías';

  @override
  String get pnJournalNudgePerfectDayDifference01Body =>
      '¿Qué hiciste hoy que te gustaría repetir?';

  @override
  String get pnJournalNudgePerfectDayDecision01Title => 'Una decisión útil';

  @override
  String get pnJournalNudgePerfectDayDecision01Body =>
      '¿Qué decisión facilitó completar tus hábitos?';

  @override
  String get pnJournalNudgePerfectDayEnergy01Title => 'Lo que te acompañó';

  @override
  String get pnJournalNudgePerfectDayEnergy01Body =>
      '¿Qué momento te dio energía mientras hacías tus hábitos?';

  @override
  String get pnJournalNudgePerfectDayEase01Title => 'Lo que facilitó el día';

  @override
  String get pnJournalNudgePerfectDayEase01Body =>
      '¿Qué hizo más sencillo completar tus hábitos hoy?';

  @override
  String get pnJournalNudgePerfectDayTomorrow01Title => 'Una idea para mañana';

  @override
  String get pnJournalNudgePerfectDayTomorrow01Body =>
      '¿Qué te gustaría probar mañana a partir de lo de hoy?';

  @override
  String get pnJournalNudgePerfectDayMoment01Title => 'Un momento del proceso';

  @override
  String get pnJournalNudgePerfectDayMoment01Body =>
      '¿Qué momento de hoy te gustaría recordar de tus hábitos?';

  @override
  String get pnJournalNudgePerfectDayLearning01Title => 'Lo que descubriste';

  @override
  String get pnJournalNudgePerfectDayLearning01Body =>
      '¿Qué descubriste sobre ti al completar tus hábitos?';

  @override
  String get pnJournalNudgePerfectDayFeeling01Title => 'Cómo fue para ti';

  @override
  String get pnJournalNudgePerfectDayFeeling01Body =>
      '¿Cómo te sentiste al terminar tus hábitos hoy?';

  @override
  String get pnJournalNudgePerfectDayMarker01Title => 'Una señal de tu proceso';

  @override
  String get pnJournalNudgePerfectDayMarker01Body =>
      '¿Qué señal te indica que la forma de hoy te funcionó?';

  @override
  String get pnJournalNudgePerfectDayMeaning01Title => 'Lo que tuvo sentido';

  @override
  String get pnJournalNudgePerfectDayMeaning01Body =>
      '¿Qué parte de completar tus hábitos tuvo más sentido para ti?';

  @override
  String get pnJournalNudgePerfectDayNote01Title => 'Una nota para mañana';

  @override
  String get pnJournalNudgePerfectDayNote01Body =>
      '¿Qué quieres dejar apuntado antes de cerrar el día?';

  @override
  String get pnJournalNudgeEndOfDayReflection01Title =>
      'Un momento para observar';

  @override
  String get pnJournalNudgeEndOfDayReflection01Body =>
      '¿Qué te gustaría observar de tu día, tal como fue?';

  @override
  String get pnJournalNudgeEndOfDayEnergy01Title => 'Tu energía hoy';

  @override
  String get pnJournalNudgeEndOfDayEnergy01Body =>
      '¿En qué momento cambió tu energía durante el día?';

  @override
  String get pnJournalNudgeEndOfDayDrain01Title => 'Lo que pesó hoy';

  @override
  String get pnJournalNudgeEndOfDayDrain01Body =>
      '¿Qué parte del día se sintió más pesada?';

  @override
  String get pnJournalNudgeEndOfDayMemory01Title => 'Algo que queda';

  @override
  String get pnJournalNudgeEndOfDayMemory01Body =>
      '¿Qué detalle de hoy te gustaría recordar?';

  @override
  String get pnJournalNudgeEndOfDayDifference01Title => 'Un detalle distinto';

  @override
  String get pnJournalNudgeEndOfDayDifference01Body =>
      '¿Qué fue diferente hoy, aunque fuera pequeño?';

  @override
  String get pnJournalNudgeEndOfDayLearning01Title => 'Algo que observaste';

  @override
  String get pnJournalNudgeEndOfDayLearning01Body =>
      '¿Qué aprendiste hoy sobre cómo transcurrió tu día?';

  @override
  String get pnJournalNudgeEndOfDayDescribe01Title => 'Ponle palabras al día';

  @override
  String get pnJournalNudgeEndOfDayDescribe01Body =>
      '¿Cómo describirías tu día en una frase?';

  @override
  String get pnJournalNudgeEndOfDayKeep01Title => 'Algo para guardar';

  @override
  String get pnJournalNudgeEndOfDayKeep01Body =>
      '¿Qué te gustaría conservar de hoy?';

  @override
  String get pnJournalNudgeEndOfDaySurprise01Title => 'Una sorpresa del día';

  @override
  String get pnJournalNudgeEndOfDaySurprise01Body => '¿Qué te sorprendió hoy?';

  @override
  String get pnJournalNudgeEndOfDayRelease01Title => 'Dejar espacio';

  @override
  String get pnJournalNudgeEndOfDayRelease01Body =>
      '¿Qué te gustaría dejar atrás al terminar el día?';

  @override
  String get pnJournalNudgeEndOfDayNotice01Title => 'Algo que notaste';

  @override
  String get pnJournalNudgeEndOfDayNotice01Body =>
      '¿Qué notaste hoy que merece un momento de atención?';

  @override
  String get pnJournalNudgeEndOfDayQuestion01Title =>
      'Una pregunta para cerrar';

  @override
  String get pnJournalNudgeEndOfDayQuestion01Body =>
      '¿Qué pregunta te deja el día?';

  @override
  String get pnJournalNudgePromptMilestone7Insight01 =>
      'Al mirar estos primeros días, ¿qué te ayudó a empezar y volver?';

  @override
  String get pnJournalNudgePromptMilestone7Change01 =>
      'Después de esta primera semana, ¿qué notas diferente?';

  @override
  String get pnJournalNudgePromptMilestone7Ease01 =>
      '¿Qué hizo más fácil retomar el hábito esta semana?';

  @override
  String get pnJournalNudgePromptMilestone7Return01 =>
      '¿Qué parece estar funcionando para ti en este comienzo?';

  @override
  String get pnJournalNudgePromptMilestone7Memory01 =>
      '¿Qué te gustaría recordar de esta primera semana?';

  @override
  String get pnJournalNudgePromptMilestone14Insight01 =>
      '¿Qué patrón empiezas a reconocer después de estas dos semanas?';

  @override
  String get pnJournalNudgePromptMilestone14Change01 =>
      '¿Qué parte del hábito empieza a sentirse más natural?';

  @override
  String get pnJournalNudgePromptMilestone14Ease01 =>
      '¿Qué te ha ayudado a mantener el hábito estos días?';

  @override
  String get pnJournalNudgePromptMilestone14Return01 =>
      '¿Qué estás aprendiendo sobre tu manera de volver?';

  @override
  String get pnJournalNudgePromptMilestone14Memory01 =>
      '¿Qué empieza a consolidarse en tu rutina?';

  @override
  String get pnJournalNudgePromptMilestone30Insight01 =>
      'Al mirar atrás un mes, ¿qué cambio ves?';

  @override
  String get pnJournalNudgePromptMilestone30Change01 =>
      '¿Qué empieza a formar parte de tu rutina?';

  @override
  String get pnJournalNudgePromptMilestone30Ease01 =>
      '¿Qué has aprendido sobre lo que te ayuda a mantenerlo?';

  @override
  String get pnJournalNudgePromptMilestone30Return01 =>
      '¿Qué quieres llevar contigo al próximo mes?';

  @override
  String get pnJournalNudgePromptMilestone30Memory01 =>
      '¿Qué merece quedarse de este mes?';

  @override
  String get pnJournalNudgePromptPerfectDayInsight01 =>
      '¿Qué crees que te ayudó a completar tus hábitos hoy?';

  @override
  String get pnJournalNudgePromptPerfectDayDifference01 =>
      '¿Qué hiciste hoy que te gustaría repetir?';

  @override
  String get pnJournalNudgePromptPerfectDayDecision01 =>
      '¿Qué decisión facilitó completar tus hábitos?';

  @override
  String get pnJournalNudgePromptPerfectDayEnergy01 =>
      '¿Qué momento te dio energía mientras hacías tus hábitos?';

  @override
  String get pnJournalNudgePromptPerfectDayEase01 =>
      '¿Qué hizo más sencillo completar tus hábitos hoy?';

  @override
  String get pnJournalNudgePromptPerfectDayTomorrow01 =>
      '¿Qué te gustaría probar mañana a partir de lo de hoy?';

  @override
  String get pnJournalNudgePromptPerfectDayMoment01 =>
      '¿Qué momento de hoy te gustaría recordar de tus hábitos?';

  @override
  String get pnJournalNudgePromptPerfectDayLearning01 =>
      '¿Qué descubriste sobre ti al completar tus hábitos?';

  @override
  String get pnJournalNudgePromptPerfectDayFeeling01 =>
      '¿Cómo te sentiste al terminar tus hábitos hoy?';

  @override
  String get pnJournalNudgePromptPerfectDayMarker01 =>
      '¿Qué te indica que la forma de hoy te funcionó?';

  @override
  String get pnJournalNudgePromptPerfectDayMeaning01 =>
      '¿Qué parte de completar tus hábitos tuvo más sentido para ti?';

  @override
  String get pnJournalNudgePromptPerfectDayNote01 =>
      '¿Qué quieres dejar apuntado antes de cerrar el día?';

  @override
  String get pnJournalNudgePromptEndOfDayReflection01 =>
      '¿Qué te gustaría observar de tu día, tal como fue?';

  @override
  String get pnJournalNudgePromptEndOfDayEnergy01 =>
      '¿En qué momento cambió tu energía durante el día?';

  @override
  String get pnJournalNudgePromptEndOfDayDrain01 =>
      '¿Qué parte del día se sintió más pesada?';

  @override
  String get pnJournalNudgePromptEndOfDayMemory01 =>
      '¿Qué detalle de hoy te gustaría recordar?';

  @override
  String get pnJournalNudgePromptEndOfDayDifference01 =>
      '¿Qué fue diferente hoy, aunque fuera pequeño?';

  @override
  String get pnJournalNudgePromptEndOfDayLearning01 =>
      '¿Qué aprendiste hoy sobre cómo transcurrió tu día?';

  @override
  String get pnJournalNudgePromptEndOfDayDescribe01 =>
      '¿Cómo describirías tu día en una frase?';

  @override
  String get pnJournalNudgePromptEndOfDayKeep01 =>
      '¿Qué te gustaría conservar de hoy?';

  @override
  String get pnJournalNudgePromptEndOfDaySurprise01 =>
      '¿Qué te sorprendió hoy?';

  @override
  String get pnJournalNudgePromptEndOfDayRelease01 =>
      '¿Qué te gustaría dejar atrás al terminar el día?';

  @override
  String get pnJournalNudgePromptEndOfDayNotice01 =>
      '¿Qué notaste hoy que merece un momento de atención?';

  @override
  String get pnJournalNudgePromptEndOfDayQuestion01 =>
      '¿Qué pregunta te deja el día?';

  @override
  String get feedbackSubmitErrorSessionExpired =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get feedbackSubmitErrorNetwork =>
      'Ha ocurrido un problema de conexión al enviar tu feedback. Inténtalo de nuevo.';

  @override
  String get feedbackSubmitErrorRejected =>
      'No se ha podido enviar tu feedback. Revisa el contenido e inténtalo otra vez.';

  @override
  String get feedbackSubmitErrorGeneric =>
      'Ha ocurrido un problema al enviar tu feedback. Inténtalo de nuevo.';

  @override
  String get weeklyReportSummaryFirstPartial01 =>
      'Es tu primera lectura semanal; aún queda tiempo para ver cómo evoluciona.';

  @override
  String get weeklyReportSummaryProvisional01 =>
      'Por ahora, tu semana va tomando forma.';

  @override
  String get weeklyReportSummaryNoSchedule01 =>
      'Esta semana no hubo hábitos programados que evaluar.';

  @override
  String get weeklyReportSummaryStrong01 =>
      'Has mantenido un ritmo muy sólido esta semana.';

  @override
  String get weeklyReportSummaryGood01 =>
      'Hubo una buena continuidad esta semana.';

  @override
  String get weeklyReportSummaryMixed01 =>
      'Hubo avances esta semana, aunque aún queda margen para ganar consistencia.';

  @override
  String get weeklyReportSummaryNeedsRecovery01 =>
      'Esta semana tuvo más altibajos. La próxima empieza con una nueva oportunidad.';

  @override
  String get weeklyReportSummaryImproved01 =>
      'Tu ritmo mejoró respecto a la semana anterior.';

  @override
  String get weeklyReportSummaryDeclined01 =>
      'El ritmo fue algo menor que la semana anterior, sin perder la perspectiva.';

  @override
  String get weeklyReportHabitHighlighted01 =>
      'Has mantenido un ritmo muy sólido.';

  @override
  String get weeklyReportHabitStable01 =>
      'El ritmo se mantuvo bastante estable.';

  @override
  String get weeklyReportHabitNeedsAttention01 =>
      'El ritmo de este hábito fue más irregular esta semana.';

  @override
  String get weeklyReportSummaryFirstPartial02 =>
      'Tu primer reporte empieza a tomar forma. Esta semana todavía recoge solo una parte del camino.';

  @override
  String get weeklyReportSummaryFirstPartial03 =>
      'Un primer vistazo a tu ritmo. La próxima semana nos dará una imagen mucho más completa.';

  @override
  String get weeklyReportSummaryFirstPartial04 =>
      'Ya tenemos una primera referencia. Tómala como un punto de partida, no como una semana completa.';

  @override
  String get weeklyReportSummaryFirstPartial05 =>
      'Este primer reporte cubre solo parte de la semana, pero ya empieza a mostrar cómo se mueve tu rutina.';

  @override
  String get weeklyReportSummaryFirstPartial06 =>
      'Primeros datos, primera perspectiva. Con una semana completa podremos comparar mejor tu ritmo.';

  @override
  String get weeklyReportSummaryFirstPartial07 =>
      'Tu reporte semanal ya está en marcha. Por ahora, quédate con él como una primera fotografía de tus hábitos.';

  @override
  String get weeklyReportSummaryFirstPartial08 =>
      'Esto acaba de empezar. Los próximos reportes tendrán más contexto para enseñarte cómo evoluciona tu semana.';

  @override
  String get weeklyReportSummaryProvisional02 =>
      'Este es solo un vistazo provisional. La semana aún tiene margen para cambiar.';

  @override
  String get weeklyReportSummaryProvisional03 =>
      'De momento, este es el ritmo de tu semana. El reporte seguirá actualizándose hasta el cierre.';

  @override
  String get weeklyReportSummaryProvisional04 =>
      'La semana sigue abierta. Estos datos muestran dónde estás ahora, no dónde terminarás.';

  @override
  String get weeklyReportSummaryProvisional05 =>
      'Así va tu semana por el momento. Lo que ocurra hasta el cierre todavía puede cambiar el balance.';

  @override
  String get weeklyReportSummaryProvisional06 =>
      'Una fotografía del momento, no el resultado final. El reporte seguirá evolucionando contigo.';

  @override
  String get weeklyReportSummaryProvisional07 =>
      'Tu semana todavía está en movimiento. Este resumen se irá completando a medida que avances.';

  @override
  String get weeklyReportSummaryProvisional08 =>
      'Por ahora ya se empieza a ver un patrón, aunque la semana todavía no ha dicho su última palabra.';

  @override
  String get weeklyReportSummaryNoSchedule02 =>
      'No hubo ninguna actividad programada en este periodo.';

  @override
  String get weeklyReportSummaryNoSchedule03 =>
      'Sin objetivos programados, no hay una base de cumplimiento que comparar.';

  @override
  String get weeklyReportSummaryNoSchedule04 =>
      'Esta semana queda neutral porque no hubo hábitos programados.';

  @override
  String get weeklyReportSummaryNoSchedule05 =>
      'No había oportunidades programadas para interpretar el resultado.';

  @override
  String get weeklyReportSummaryNoSchedule06 =>
      'El reporte no tiene actividad programada sobre la que construir una lectura.';

  @override
  String get weeklyReportSummaryStrong02 =>
      'Una semana consistente, con muchos de tus planes convertidos en hechos.';

  @override
  String get weeklyReportSummaryStrong03 =>
      'Esta semana deja una base muy sólida sobre la que seguir construyendo.';

  @override
  String get weeklyReportSummaryStrong04 =>
      'Buen ritmo y mucha continuidad. La semana ha sido especialmente consistente.';

  @override
  String get weeklyReportSummaryStrong05 =>
      'Tus hábitos han tenido una semana muy estable. Mantener este ritmo ya es un gran resultado.';

  @override
  String get weeklyReportSummaryStrong06 =>
      'Has estado cerca de lo que te habías propuesto durante buena parte de la semana.';

  @override
  String get weeklyReportSummaryStrong07 =>
      'Una semana con mucha continuidad. No hace falta complicarlo más: sigue construyendo desde aquí.';

  @override
  String get weeklyReportSummaryStrong08 =>
      'La constancia ha tenido bastante peso esta semana. Llegas a la próxima con una buena base.';

  @override
  String get weeklyReportSummaryStrong09 =>
      'Muchos pequeños cumplimientos han terminado formando una semana muy sólida.';

  @override
  String get weeklyReportSummaryStrong10 =>
      'Esta semana muestra un ritmo difícil de conseguir por casualidad. Hay consistencia detrás de estos números.';

  @override
  String get weeklyReportSummaryGood02 =>
      'La mayor parte de la semana estuvo bien encaminada. Hay una base clara para seguir avanzando.';

  @override
  String get weeklyReportSummaryGood03 =>
      'Has mantenido un buen ritmo general, aunque todavía queda algo de margen para hacerlo más estable.';

  @override
  String get weeklyReportSummaryGood04 =>
      'Una semana positiva y bastante consistente. No todo tiene que salir perfecto para avanzar.';

  @override
  String get weeklyReportSummaryGood05 =>
      'El balance de la semana es bueno. Has mantenido presentes muchos de tus hábitos.';

  @override
  String get weeklyReportSummaryGood06 =>
      'Esta semana tuvo más continuidad que interrupciones. Es una buena base para la siguiente.';

  @override
  String get weeklyReportSummaryGood07 =>
      'Vas construyendo un ritmo sólido sin necesidad de que cada día sea perfecto.';

  @override
  String get weeklyReportSummaryGood08 =>
      'La semana deja buenas señales de continuidad. Ahora se trata de hacerlas cada vez más habituales.';

  @override
  String get weeklyReportSummaryGood09 =>
      'Has completado una parte importante de lo que tenías previsto. Buen punto de partida para seguir afinando.';

  @override
  String get weeklyReportSummaryGood10 =>
      'El ritmo general ha sido bueno. La siguiente semana puede servir para consolidar lo que ya está funcionando.';

  @override
  String get weeklyReportSummaryMixed02 =>
      'Hubo avances, aunque la continuidad fue cambiando a lo largo de la semana.';

  @override
  String get weeklyReportSummaryMixed03 =>
      'Una semana con luces y sombras. Hay hábitos que ya tienen buena base y otros que todavía buscan su sitio.';

  @override
  String get weeklyReportSummaryMixed04 =>
      'El ritmo fue irregular, pero hubo suficientes avances como para saber por dónde seguir.';

  @override
  String get weeklyReportSummaryMixed05 =>
      'No fue una semana lineal, y está bien. El reporte ya empieza a mostrar dónde resulta más fácil mantener el ritmo.';

  @override
  String get weeklyReportSummaryMixed06 =>
      'Algunas partes de la semana funcionaron mejor que otras. La próxima puede servir para simplificar y ajustar.';

  @override
  String get weeklyReportSummaryMixed07 =>
      'Hubo constancia en algunos momentos y más dificultad en otros. Una semana útil para observar patrones.';

  @override
  String get weeklyReportSummaryMixed08 =>
      'El balance queda a medio camino. Hay progreso, pero también espacio para encontrar más continuidad.';

  @override
  String get weeklyReportSummaryMixed09 =>
      'Esta semana no siguió un único ritmo. Quédate con lo que funcionó y construye desde ahí.';

  @override
  String get weeklyReportSummaryMixed10 =>
      'Una semana irregular también aporta información. Ya tienes una referencia para decidir dónde poner el foco después.';

  @override
  String get weeklyReportSummaryNeedsRecovery02 =>
      'No ha sido la semana más constante, pero sigue siendo información útil para ajustar el rumbo.';

  @override
  String get weeklyReportSummaryNeedsRecovery03 =>
      'Esta semana tuvo más interrupciones de lo habitual. Quizá la siguiente sea un buen momento para simplificar.';

  @override
  String get weeklyReportSummaryNeedsRecovery04 =>
      'El ritmo quedó por debajo de lo previsto. No hace falta compensarlo todo de golpe.';

  @override
  String get weeklyReportSummaryNeedsRecovery05 =>
      'Hubo menos continuidad esta semana. Volver a una base sencilla puede ser suficiente para empezar de nuevo.';

  @override
  String get weeklyReportSummaryNeedsRecovery06 =>
      'Esta semana fue más difícil de sostener. La próxima no necesita ser perfecta, solo un poco más llevadera.';

  @override
  String get weeklyReportSummaryNeedsRecovery07 =>
      'Los hábitos encontraron más obstáculos esta semana. El siguiente paso puede ser simplemente recuperar el ritmo.';

  @override
  String get weeklyReportSummaryNeedsRecovery08 =>
      'No todas las semanas encajan igual. Esta deja pistas sobre qué hábitos quizá necesiten un pequeño ajuste.';

  @override
  String get weeklyReportSummaryNeedsRecovery09 =>
      'Esta semana avanzó más despacio. A veces reducir fricción es más útil que intentar hacer más.';

  @override
  String get weeklyReportSummaryNeedsRecovery10 =>
      'El balance ha sido más irregular de lo previsto. La próxima semana ofrece una nueva oportunidad para reorganizar el ritmo.';

  @override
  String get weeklyReportSummaryImproved02 =>
      'Tu ritmo ha mejorado esta semana. Una señal pequeña, pero importante.';

  @override
  String get weeklyReportSummaryImproved03 =>
      'Hay una evolución positiva respecto al último reporte.';

  @override
  String get weeklyReportSummaryImproved04 =>
      'Esta semana muestra más continuidad que la anterior. Buen momento para consolidarla.';

  @override
  String get weeklyReportSummaryImproved05 =>
      'Has conseguido mover la semana en una dirección positiva respecto a la anterior.';

  @override
  String get weeklyReportSummaryImproved06 =>
      'El progreso respecto a la semana pasada ya se empieza a notar en tus números.';

  @override
  String get weeklyReportSummaryImproved07 =>
      'Un poco más de constancia que la semana anterior. Ese tipo de cambio es el que termina acumulándose.';

  @override
  String get weeklyReportSummaryImproved08 =>
      'Esta semana ha funcionado mejor que la anterior. Quédate con lo que te ayudó a mantener el ritmo.';

  @override
  String get weeklyReportSummaryDeclined02 =>
      'El ritmo bajó respecto al último reporte. Puede ser un buen momento para revisar qué merece simplificarse.';

  @override
  String get weeklyReportSummaryDeclined03 =>
      'Esta semana quedó algo por debajo de la anterior. La siguiente puede empezar con objetivos más fáciles de sostener.';

  @override
  String get weeklyReportSummaryDeclined04 =>
      'Hubo menos constancia que la semana pasada. Tómalo como una señal para observar, no como un paso atrás definitivo.';

  @override
  String get weeklyReportSummaryDeclined05 =>
      'Los números bajaron un poco esta semana. Una variación puntual no define tu progreso.';

  @override
  String get weeklyReportSummaryDeclined06 =>
      'Esta semana perdió algo de ritmo respecto a la anterior. La próxima puede servir para recuperar una base sencilla.';

  @override
  String get weeklyReportSummaryDeclined07 =>
      'La continuidad fue menor que la semana pasada. Quizá sea suficiente con volver a lo esencial.';

  @override
  String get weeklyReportSummaryDeclined08 =>
      'Esta semana ha sido algo más irregular que la anterior. El siguiente reporte será otra oportunidad para cambiar la tendencia.';

  @override
  String get weeklyReportHabitHighlighted02 =>
      'Este hábito tuvo una semana especialmente consistente.';

  @override
  String get weeklyReportHabitHighlighted03 =>
      'La continuidad ha sido una de las fortalezas de este hábito esta semana.';

  @override
  String get weeklyReportHabitHighlighted04 =>
      'Este hábito se mantuvo muy cerca de lo que tenías previsto.';

  @override
  String get weeklyReportHabitHighlighted05 =>
      'Una semana muy estable para este hábito. Buena base para seguir.';

  @override
  String get weeklyReportHabitHighlighted06 =>
      'Aquí la constancia ha tenido bastante peso esta semana.';

  @override
  String get weeklyReportHabitHighlighted07 =>
      'Este hábito encontró un ritmo que parece estar funcionando bien.';

  @override
  String get weeklyReportHabitHighlighted08 =>
      'Muchos de los momentos previstos terminaron convirtiéndose en cumplimientos.';

  @override
  String get weeklyReportHabitStable02 =>
      'Hay una buena base de continuidad sobre la que seguir construyendo.';

  @override
  String get weeklyReportHabitStable03 =>
      'El hábito estuvo presente durante buena parte de la semana.';

  @override
  String get weeklyReportHabitStable04 =>
      'Una semana razonablemente constante para este hábito.';

  @override
  String get weeklyReportHabitStable05 =>
      'El ritmo está ahí; ahora se trata de hacerlo cada vez más natural.';

  @override
  String get weeklyReportHabitStable06 =>
      'Este hábito avanzó con bastante regularidad, aunque todavía tiene margen para consolidarse.';

  @override
  String get weeklyReportHabitStable07 =>
      'La semana deja una base suficientemente estable para seguir ajustando poco a poco.';

  @override
  String get weeklyReportHabitStable08 =>
      'Aquí hubo más continuidad que interrupciones. Un buen punto desde el que seguir.';

  @override
  String get weeklyReportHabitNeedsAttention02 =>
      'El ritmo quedó algo por debajo de lo previsto.';

  @override
  String get weeklyReportHabitNeedsAttention03 =>
      'Este hábito tuvo una semana más irregular.';

  @override
  String get weeklyReportHabitNeedsAttention04 =>
      'Hubo menos oportunidades completadas esta semana.';

  @override
  String get weeklyReportHabitNeedsAttention05 =>
      'Este hábito encontró más fricción esta semana.';

  @override
  String get weeklyReportHabitNeedsAttention06 =>
      'La continuidad fue limitada esta semana.';

  @override
  String get weeklyReportHabitNeedsAttention07 =>
      'No terminó de asentarse esta semana.';

  @override
  String get weeklyReportHabitNeedsAttention08 =>
      'Este hábito mostró menos estabilidad esta semana.';

  @override
  String get weeklyReportSummaryFirstPartial09 =>
      'La lectura aún es parcial, pero ya ofrece una primera orientación.';

  @override
  String get weeklyReportSummaryFirstPartial10 =>
      'Todavía faltan días para completar el contexto; por ahora, observa sin presión.';

  @override
  String get weeklyReportSummaryFirstPartial11 =>
      'Este punto de partida reúne señales iniciales, no una conclusión sobre tu rutina.';

  @override
  String get weeklyReportSummaryFirstPartial12 =>
      'Hay poco recorrido todavía, aunque ya se puede empezar a reconocer tu forma de organizarte.';

  @override
  String get weeklyReportSummaryFirstPartial13 =>
      'La semana no está completa en este primer registro. Úsalo para orientarte, no para juzgarte.';

  @override
  String get weeklyReportSummaryFirstPartial14 =>
      'Algunos días quedan fuera de esta lectura; la imagen irá ganando contexto con el tiempo.';

  @override
  String get weeklyReportSummaryFirstPartial15 =>
      'Este primer balance es breve y necesariamente incompleto, pero puede servirte de referencia.';

  @override
  String get weeklyReportSummaryFirstPartial16 =>
      'Aún estamos reuniendo contexto. Lo que aparece aquí es una señal inicial y útil.';

  @override
  String get weeklyReportSummaryFirstPartial17 =>
      'No hace falta sacar conclusiones todavía: este reporte solo recoge el comienzo.';

  @override
  String get weeklyReportSummaryFirstPartial18 =>
      'Tu primera lectura abre una referencia; habrá más información cuando el ciclo esté completo.';

  @override
  String get weeklyReportSummaryProvisional09 =>
      'La semana sigue abierta y este balance puede cambiar antes del cierre.';

  @override
  String get weeklyReportSummaryProvisional10 =>
      'Lo que ves es una lectura en curso, útil para orientarte mientras avanzas.';

  @override
  String get weeklyReportSummaryProvisional11 =>
      'Todavía no hay un cierre: el ritmo puede ganar forma de aquí al final de la semana.';

  @override
  String get weeklyReportSummaryProvisional12 =>
      'Este resumen recoge el camino recorrido hasta ahora, no una valoración definitiva.';

  @override
  String get weeklyReportSummaryProvisional13 =>
      'La semana sigue abierta para que el balance cambie antes del cierre.';

  @override
  String get weeklyReportSummaryProvisional14 =>
      'La fotografía actual es provisional; úsala para observar, no para anticipar el resultado.';

  @override
  String get weeklyReportSummaryProvisional15 =>
      'Tu semana se está construyendo; lo que ocurra hasta el cierre aún cuenta.';

  @override
  String get weeklyReportSummaryProvisional16 =>
      'Por ahora, estos datos cuentan una parte de la historia.';

  @override
  String get weeklyReportSummaryProvisional17 =>
      'El resultado aún está abierto, pero ya hay señales que pueden ayudarte a orientarte.';

  @override
  String get weeklyReportSummaryProvisional18 =>
      'Una lectura del momento: suficiente para observar patrones, todavía pronto para cerrar conclusiones.';

  @override
  String get weeklyReportSummaryNoSchedule07 =>
      'No hubo actividad programada evaluable esta semana.';

  @override
  String get weeklyReportSummaryNoSchedule08 =>
      'No existe una base programada para calcular el cumplimiento.';

  @override
  String get weeklyReportSummaryNoSchedule09 =>
      'Esta semana no tuvo hábitos programados que comparar.';

  @override
  String get weeklyReportSummaryNoSchedule10 =>
      'Sin actividad programada, el balance queda sin una lectura de cumplimiento.';

  @override
  String get weeklyReportSummaryNoSchedule11 =>
      'No hubo oportunidades previstas para esta lectura semanal.';

  @override
  String get weeklyReportSummaryNoSchedule12 =>
      'La semana queda neutral al no tener hábitos programados.';

  @override
  String get weeklyReportSummaryNoSchedule13 =>
      'El reporte necesita hábitos programados para ofrecer una señal de cumplimiento.';

  @override
  String get weeklyReportSummaryNoSchedule14 =>
      'Cuando vuelva a haber hábitos programados, habrá una nueva referencia.';

  @override
  String get weeklyReportSummaryStrong11 =>
      'Una base firme y bien sostenida recorre toda la semana.';

  @override
  String get weeklyReportSummaryStrong12 =>
      'El cumplimiento se mantuvo alto sin perder naturalidad.';

  @override
  String get weeklyReportSummaryStrong13 =>
      'Tus planes encontraron bastante continuidad en estos días.';

  @override
  String get weeklyReportSummaryStrong14 =>
      'Hay una consistencia clara detrás del balance de la semana.';

  @override
  String get weeklyReportSummaryStrong15 =>
      'El conjunto de hábitos se sostuvo con solidez.';

  @override
  String get weeklyReportSummaryStrong16 =>
      'Una semana con buen control del ritmo y pocas interrupciones.';

  @override
  String get weeklyReportSummaryStrong17 =>
      'Lo que te propusiste tuvo una presencia muy estable.';

  @override
  String get weeklyReportSummaryStrong18 =>
      'El balance habla de una rutina cuidada y constante.';

  @override
  String get weeklyReportSummaryStrong19 =>
      'Muchos días encajaron bien con lo que habías previsto.';

  @override
  String get weeklyReportSummaryStrong20 =>
      'La semana deja una señal nítida de continuidad y buen ritmo.';

  @override
  String get weeklyReportSummaryGood11 =>
      'El balance es positivo y deja una base sana para seguir.';

  @override
  String get weeklyReportSummaryGood12 =>
      'Tu semana avanzó con una continuidad que merece ser reconocida.';

  @override
  String get weeklyReportSummaryGood13 =>
      'Buena parte de lo previsto encontró su momento.';

  @override
  String get weeklyReportSummaryGood14 =>
      'Se aprecia un ritmo útil, con margen tranquilo para seguir afinando.';

  @override
  String get weeklyReportSummaryGood15 =>
      'La rutina tuvo una presencia sólida durante varios días.';

  @override
  String get weeklyReportSummaryGood16 =>
      'Hay progreso real en cómo estás sosteniendo tus hábitos.';

  @override
  String get weeklyReportSummaryGood17 =>
      'El resultado general acompaña: vas construyendo una base práctica.';

  @override
  String get weeklyReportSummaryGood18 =>
      'No todo tuvo que salir igual para que la semana avanzara bien.';

  @override
  String get weeklyReportSummaryGood19 =>
      'Tu planificación encontró bastante espacio en los días.';

  @override
  String get weeklyReportSummaryGood20 =>
      'Un balance favorable, con señales de que algunas cosas ya encajan.';

  @override
  String get weeklyReportSummaryMixed11 =>
      'El balance combina avances y pausas; ambas partes ayudan a entender la semana.';

  @override
  String get weeklyReportSummaryMixed12 =>
      'Hubo momentos de buena continuidad junto a otros más difíciles de sostener.';

  @override
  String get weeklyReportSummaryMixed13 =>
      'La semana cambió de ritmo varias veces, y eso también deja información.';

  @override
  String get weeklyReportSummaryMixed14 =>
      'Algunas cosas encajaron mejor que otras. Ahí puede estar la pista útil.';

  @override
  String get weeklyReportSummaryMixed15 =>
      'El resultado es desigual, sin ser definitivo: conviene observar cómo se repite.';

  @override
  String get weeklyReportSummaryMixed16 =>
      'Hay señales positivas mezcladas con interrupciones normales.';

  @override
  String get weeklyReportSummaryMixed17 =>
      'No todo siguió el mismo patrón, pero el conjunto permite aprender.';

  @override
  String get weeklyReportSummaryMixed18 =>
      'La semana tuvo distintos momentos; quédate con los que te resultaron más fáciles.';

  @override
  String get weeklyReportSummaryMixed19 =>
      'Entre días fuertes y días más flojos aparece una referencia para ajustar.';

  @override
  String get weeklyReportSummaryMixed20 =>
      'Un balance intermedio puede ser valioso cuando ayuda a ver qué funciona.';

  @override
  String get weeklyReportSummaryNeedsRecovery11 =>
      'Esta semana pide menos exigencia y una mirada más sencilla al siguiente paso.';

  @override
  String get weeklyReportSummaryNeedsRecovery12 =>
      'El ritmo tuvo más dificultades de lo previsto; volver a lo básico puede ayudar.';

  @override
  String get weeklyReportSummaryNeedsRecovery13 =>
      'No hace falta recuperar todo de golpe. Un comienzo manejable ya cuenta.';

  @override
  String get weeklyReportSummaryNeedsRecovery14 =>
      'La semana deja señales para revisar expectativas y reducir fricción.';

  @override
  String get weeklyReportSummaryNeedsRecovery15 =>
      'Hubo poca continuidad, pero también una oportunidad clara para reordenar.';

  @override
  String get weeklyReportSummaryNeedsRecovery16 =>
      'Cuando sostenerlo cuesta, simplificar puede abrir espacio para volver.';

  @override
  String get weeklyReportSummaryNeedsRecovery17 =>
      'Este balance no define tu rutina; solo señala dónde conviene mirar con calma.';

  @override
  String get weeklyReportSummaryNeedsRecovery18 =>
      'La semana fue difícil de mantener. Un paso pequeño puede ser suficiente ahora.';

  @override
  String get weeklyReportSummaryNeedsRecovery19 =>
      'Hay margen para recuperar presencia sin convertirlo en una deuda.';

  @override
  String get weeklyReportSummaryNeedsRecovery20 =>
      'Una semana complicada puede servir para ajustar el plan a algo más llevadero.';

  @override
  String get weeklyReportSummaryImproved09 =>
      'Esta semana trae una señal favorable frente a la anterior.';

  @override
  String get weeklyReportSummaryImproved10 =>
      'Se nota un avance en la dirección de tu rutina.';

  @override
  String get weeklyReportSummaryImproved11 =>
      'El balance mejora respecto al último registro, paso a paso.';

  @override
  String get weeklyReportSummaryImproved12 =>
      'Hay más continuidad que antes, aunque la tendencia aún puede cambiar.';

  @override
  String get weeklyReportSummaryImproved13 =>
      'Un cambio positivo empieza a hacerse visible en esta comparación.';

  @override
  String get weeklyReportSummaryImproved14 =>
      'La semana recuperó parte del ritmo perdido.';

  @override
  String get weeklyReportSummaryImproved15 =>
      'El resultado acompaña mejor que la semana pasada.';

  @override
  String get weeklyReportSummaryImproved16 =>
      'Has encontrado algo más de estabilidad en estos días.';

  @override
  String get weeklyReportSummaryImproved17 =>
      'La comparación deja una mejora clara, sin necesidad de forzarla.';

  @override
  String get weeklyReportSummaryImproved18 =>
      'Este avance suma una referencia positiva para seguir observando.';

  @override
  String get weeklyReportSummaryDeclined09 =>
      'El balance queda por debajo del anterior, pero una semana no fija el rumbo.';

  @override
  String get weeklyReportSummaryDeclined10 =>
      'Esta vez hubo menos continuidad. Puede ser útil observar qué cambió.';

  @override
  String get weeklyReportSummaryDeclined11 =>
      'La comparación muestra una bajada moderada, no una conclusión sobre tu proceso.';

  @override
  String get weeklyReportSummaryDeclined12 =>
      'El ritmo perdió algo de fuerza respecto al último registro.';

  @override
  String get weeklyReportSummaryDeclined13 =>
      'La semana fue más irregular que la anterior; todavía hay margen para reajustar.';

  @override
  String get weeklyReportSummaryDeclined14 =>
      'Un resultado menor también puede señalar dónde conviene mirar.';

  @override
  String get weeklyReportSummaryDeclined15 =>
      'La diferencia con la semana pasada es visible, sin definir lo que viene.';

  @override
  String get weeklyReportSummaryDeclined16 =>
      'Esta comparación invita a revisar el ritmo con curiosidad y sin juicio.';

  @override
  String get weeklyReportSummaryDeclined17 =>
      'Hubo menos cumplimiento que antes, pero el patrón aún está abierto.';

  @override
  String get weeklyReportSummaryDeclined18 =>
      'La semana bajó un poco respecto a la anterior; volver a lo esencial puede orientar.';

  @override
  String get weeklyReportHabitHighlighted09 =>
      'Este hábito mantuvo una presencia especialmente firme.';

  @override
  String get weeklyReportHabitHighlighted10 =>
      'Aquí se ve una regularidad clara.';

  @override
  String get weeklyReportHabitHighlighted11 =>
      'El hábito respondió bien a lo que habías previsto.';

  @override
  String get weeklyReportHabitHighlighted12 =>
      'Una de las bases más constantes de la semana.';

  @override
  String get weeklyReportHabitHighlighted13 =>
      'Este hábito encontró una cadencia que encaja.';

  @override
  String get weeklyReportHabitHighlighted14 =>
      'Su presencia fue sólida a lo largo de los días.';

  @override
  String get weeklyReportHabitHighlighted15 =>
      'Muchos de sus momentos previstos terminaron ocurriendo.';

  @override
  String get weeklyReportHabitHighlighted16 =>
      'Hay una continuidad visible en este hábito.';

  @override
  String get weeklyReportHabitStable09 =>
      'Este hábito mantiene una base razonable.';

  @override
  String get weeklyReportHabitStable10 =>
      'La presencia del hábito fue bastante regular.';

  @override
  String get weeklyReportHabitStable11 =>
      'Hay continuidad suficiente para seguir construyendo.';

  @override
  String get weeklyReportHabitStable12 =>
      'El ritmo se sostiene sin grandes cambios.';

  @override
  String get weeklyReportHabitStable13 =>
      'Este hábito conserva un lugar estable en la rutina.';

  @override
  String get weeklyReportHabitStable14 =>
      'Una presencia tranquila, con margen para asentarse más.';

  @override
  String get weeklyReportHabitStable15 =>
      'La semana muestra una base que puede seguir creciendo.';

  @override
  String get weeklyReportHabitStable16 =>
      'El hábito aparece con una regularidad útil.';

  @override
  String get weeklyReportHabitNeedsAttention09 =>
      'Esta semana, este hábito tuvo menos continuidad.';

  @override
  String get weeklyReportHabitNeedsAttention10 =>
      'La presencia del hábito fue menor esta semana.';

  @override
  String get weeklyReportHabitNeedsAttention11 =>
      'Este hábito tuvo más interrupciones esta semana.';

  @override
  String get weeklyReportHabitNeedsAttention12 =>
      'La frecuencia del hábito fue irregular.';

  @override
  String get weeklyReportHabitNeedsAttention13 =>
      'La semana dejó menos continuidad en este hábito.';

  @override
  String get weeklyReportHabitNeedsAttention14 =>
      'La presencia del hábito fue inestable.';

  @override
  String get weeklyReportHabitNeedsAttention15 =>
      'Este hábito apareció menos de forma sostenida.';

  @override
  String get weeklyReportHabitNeedsAttention16 =>
      'El hábito mostró una estabilidad más baja esta semana.';
}
