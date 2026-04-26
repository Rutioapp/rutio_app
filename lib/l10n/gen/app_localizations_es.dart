// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get welcomeSubtitle => 'PequeÃ±os pasos,\ngrandes cambios.';

  @override
  String get welcomeLoginButton => 'Iniciar sesiÃ³n';

  @override
  String get welcomeSignupButton => 'Crear cuenta';

  @override
  String get loginHeaderSubtitle => 'Bienvenido de vuelta';

  @override
  String get loginTitle => 'Iniciar sesiÃ³n';

  @override
  String get loginSubtitle => 'ContinÃºa donde lo dejaste';

  @override
  String get loginPasswordHint => 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢';

  @override
  String get loginForgotPassword => 'Â¿Olvidaste tu contraseÃ±a?';

  @override
  String get loginPrimaryCta => 'Continuar â†’';

  @override
  String get loginSwitchPrefix => 'Â¿No tienes cuenta?  ';

  @override
  String get loginSwitchLink => 'RegÃ­strate';

  @override
  String get signupHeaderSubtitle => 'Empieza tu camino';

  @override
  String get signupTitle => 'Crear cuenta';

  @override
  String get signupSubtitle => 'Un pequeÃ±o paso hacia tus metas';

  @override
  String get signupNameLabel => 'Nombre';

  @override
  String get signupNameHint => 'Â¿CÃ³mo te llamas?';

  @override
  String get signupPasswordHint => 'MÃ­n. 8 caracteres';

  @override
  String get signupPrimaryCta => 'Comenzar â†’';

  @override
  String get signupSwitchPrefix => 'Â¿Ya tienes cuenta?  ';

  @override
  String get signupSwitchLink => 'Inicia sesiÃ³n';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get fieldEmailHint => 'tu@email.com';

  @override
  String get fieldPasswordLabel => 'ContraseÃ±a';

  @override
  String homeErrorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get homeFallbackUsername => 'Usuario';

  @override
  String get homeFallbackHabitTitle => 'HÃ¡bito';

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
  String get homeEmptyStateMultiline =>
      'AÃºn no tienes hÃ¡bitos activos.`nPulsa â€œNuevoâ€ para aÃ±adir el primero.';

  @override
  String get homeEmptyStateSingleLine =>
      'AÃºn no tienes hÃ¡bitos activos. Pulsa â€œNuevoâ€ para aÃ±adir el primero.';

  @override
  String get homeEditCounterTitle => 'Editar contador';

  @override
  String get homeEditCounterHint => 'Introduce un nÃºmero';

  @override
  String get homeInputValueHint => 'Introduce un valor';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonAdd => 'AÃ±adir';

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
  String get homeAddHabitLoadError => 'No se pudo cargar el catÃ¡logo';

  @override
  String homeAddHabitCreated(String name) {
    return 'Se ha creado \"$name\"';
  }

  @override
  String get homeAddHabitCreatedGeneric => 'HÃ¡bito creado';

  @override
  String get homeAddHabitCreateFromScratch => 'Crear hÃ¡bito desde cero';

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
  String get habitConfigDaysSection => 'DÃ­as';

  @override
  String get habitConfigDateSection => 'Fecha';

  @override
  String get habitConfigChooseDate => 'Elegir fecha';

  @override
  String get habitConfigInvalidGoal => 'Pon un objetivo vÃ¡lido (mayor que 0).';

  @override
  String get habitConfigSelectDay => 'Selecciona al menos un dÃ­a.';

  @override
  String get habitConfigSelectDate => 'Selecciona una fecha.';

  @override
  String get weekdayShortMon => 'Lun';

  @override
  String get weekdayShortTue => 'Mar';

  @override
  String get weekdayShortWed => 'MiÃ©';

  @override
  String get weekdayShortThu => 'Jue';

  @override
  String get weekdayShortFri => 'Vie';

  @override
  String get weekdayShortSat => 'SÃ¡b';

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
  String get unitPagesShort => 'pÃ¡ginas';

  @override
  String get unitStepsShort => 'pasos';

  @override
  String get unitKilometersShort => 'km';

  @override
  String get unitLitersShort => 'L';

  @override
  String get familyMindName => 'Mente';

  @override
  String get familySpiritName => 'EspÃ­ritu';

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
      'Resolver un problema lÃ³gico';

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
  String get catalogHabitTomarNotas => 'Tomar notas del dÃ­a';

  @override
  String get catalogHabitJuegoMental => 'Juego mental o rompecabezas';

  @override
  String get catalogHabitPracticarEscrituraCreativa => 'Escritura creativa';

  @override
  String get catalogHabitRepasarNotas => 'Repasar notas del dÃ­a';

  @override
  String get catalogHabitVerDocumental =>
      'Ver un documental o vÃ­deo educativo';

  @override
  String get catalogHabitMeditar => 'Meditar';

  @override
  String get catalogHabitPracticarGratitud => 'Practicar gratitud';

  @override
  String get catalogHabitRespiracionConsciente => 'RespiraciÃ³n consciente';

  @override
  String get catalogHabitReflexionPersonal => 'ReflexiÃ³n personal';

  @override
  String get catalogHabitOracionConexionEspiritual =>
      'OraciÃ³n o conexiÃ³n espiritual';

  @override
  String get catalogHabitRevisarAprendizajesDia =>
      'Revisar aprendizajes del dÃ­a';

  @override
  String get catalogHabitVisualizacionPositiva => 'VisualizaciÃ³n positiva';

  @override
  String get catalogHabitLecturaEspiritual => 'Lectura espiritual';

  @override
  String get catalogHabitDesconexionDigital => 'DesconexiÃ³n digital';

  @override
  String get catalogHabitContactoNaturaleza => 'Tiempo en la naturaleza';

  @override
  String get catalogHabitTresCosasBuenas => 'Escribir 3 cosas buenas del dÃ­a';

  @override
  String get catalogHabitPaseoSinMovil => 'Paseo sin mÃ³vil';

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
  String get catalogHabitRutinaManana => 'Rutina de maÃ±ana';

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
  String get catalogHabitDuchaFria => 'Ducha frÃ­a';

  @override
  String get catalogHabitHacerCama => 'Hacer la cama';

  @override
  String get catalogHabitSkincare => 'Skincare';

  @override
  String get catalogHabitHigieneBucal => 'Higiene bucal completa';

  @override
  String get catalogHabitTomarSuplementos => 'Tomar suplementos o medicaciÃ³n';

  @override
  String get catalogHabitHidratarPiel => 'Hidratarse la piel';

  @override
  String get catalogHabitDiarioEmocional => 'Diario emocional';

  @override
  String get catalogHabitIdentificarEmociones => 'Identificar mis emociones';

  @override
  String get catalogHabitGestionarEstres => 'Gestionar el estrÃ©s';

  @override
  String get catalogHabitAutocompasion => 'Practicar autocompasiÃ³n';

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
  String get catalogHabitNotaAnimo => 'Nota de Ã¡nimo del dÃ­a';

  @override
  String catalogHabitNotaAnimoTarget(String target) {
    return 'Ãnimo: $target/10';
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
  String get catalogHabitPracticarEmpatia => 'Practicar empatÃ­a';

  @override
  String get catalogHabitPlanSocial => 'Quedar con alguien';

  @override
  String get catalogHabitDesconectarRedes => 'Desconectarse de redes sociales';

  @override
  String get catalogHabitMensajeAnimo => 'Enviar un mensaje de Ã¡nimo';

  @override
  String get catalogHabitLlamadaFamiliaAmigo => 'Llamada con familia o amigo';

  @override
  String get catalogHabitPlanificarDia => 'Planificar el dÃ­a';

  @override
  String get catalogHabitCumplirRutina => 'Cumplir la rutina';

  @override
  String get catalogHabitRevisarObjetivos => 'Revisar objetivos';

  @override
  String get catalogHabitEvitarProcrastinacion => 'Vencer la procrastinaciÃ³n';

  @override
  String get catalogHabitTareaDificil => 'Hacer la tarea mÃ¡s difÃ­cil primero';

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
  String get catalogHabitRevisarFinDia => 'Revisar el dÃ­a al terminar';

  @override
  String get catalogHabitApagarMovil => 'Apagar el mÃ³vil a una hora fija';

  @override
  String get catalogHabitSinComprasImpulsivas => 'Sin compras impulsivas';

  @override
  String get catalogHabitPrepararRopa => 'Preparar la ropa del dÃ­a siguiente';

  @override
  String get catalogHabitTrabajoProfundo => 'SesiÃ³n de trabajo profundo';

  @override
  String catalogHabitTrabajoProfundoTarget(String target) {
    return 'Trabajo profundo $target min';
  }

  @override
  String get catalogHabitHabilidadLaboral => 'Desarrollar habilidad laboral';

  @override
  String get catalogHabitOrganizarTareas => 'Organizar tareas del dÃ­a';

  @override
  String get catalogHabitRevisarRendimiento => 'Revisar rendimiento';

  @override
  String get catalogHabitNetworking => 'Networking';

  @override
  String get catalogHabitFormacionProfesional => 'FormaciÃ³n profesional';

  @override
  String catalogHabitFormacionProfesionalTarget(String target) {
    return 'FormaciÃ³n $target horas';
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
  String get settingsLanguageOptionSpanish => 'EspaÃ±ol';

  @override
  String get settingsLanguageOptionEnglish => 'InglÃ©s';

  @override
  String get settingsAccountSectionTitle => 'Cuenta';

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
  String get profileSettingsTitle => 'Ajustes';

  @override
  String get profileSettingsSubtitle => 'Idioma, privacidad y mÃ¡s';

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
  String get habitStatsTitle => 'Estadisticas';

  @override
  String get habitStatsEmpty => 'No hay habitos para mostrar.';

  @override
  String get habitStatsMetricCompleted => 'Completado';

  @override
  String habitStatsMetricCompletionDescription(int done, int total) {
    return '$done/$total dias';
  }

  @override
  String get habitStatsMetricConsistency => 'Consistencia';

  @override
  String habitStatsMetricConsistencyDescription(int window) {
    return 'Ultimos $window dias';
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
  String get habitStatsChartLastFourWeeksTitle => 'Ultimas 4 semanas';

  @override
  String get habitStatsChartWeekSubtitle => 'Completado por dia';

  @override
  String get habitStatsChartWeeksSubtitle => 'Completado agregado por semana';

  @override
  String get habitStatsNextMilestone => 'Siguiente hito';

  @override
  String get habitStatsWeeklyComparisonTitle => 'Comparacion semanal';

  @override
  String get habitStatsWeeklyComparisonSubtitle => 'Esta semana vs la anterior';

  @override
  String get habitStatsBestTimeSectionTitle => 'Cuando lo cumples mejor?';

  @override
  String get habitStatsBestTimeSectionSubtitle =>
      'Basado en tus registros, tus momentos mas consistentes';

  @override
  String get habitStatsMonthCalendarTitle => 'Calendario del mes';

  @override
  String get habitStatsTabSummaryTitle => 'Resumen';

  @override
  String habitStatsTabLastDaysTitle(int days) {
    return 'Ultimos $days dias';
  }

  @override
  String get habitStatsTabAchievementsUnlocked => 'Logros desbloqueados';

  @override
  String get habitStatsTabCurrentStreakTitle => 'Racha actual';

  @override
  String habitStatsTabDayUnit(int count) {
    return '$count dia';
  }

  @override
  String get habitStatsTabTotalLabel => 'total';

  @override
  String habitStatsTabCompletionWindow(int done, int total) {
    return '$done / $total dias';
  }

  @override
  String get habitStatsTabCounterHint =>
      'Cuenta el numero de veces completado cada dia';

  @override
  String get habitStatsTabCheckHint =>
      'Dias en los que completaste este habito';

  @override
  String get habitStatsTabFireStreakTitle => 'Racha de fuego';

  @override
  String habitStatsTabStreakInARow(int days) {
    return '$days dias seguidos';
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
    return '$percent% ultimos 30 dias';
  }

  @override
  String get habitStatsTabLegendaryRecordTitle => 'Record legendario';

  @override
  String habitStatsTabRecordStreak(int days) {
    return '$days dias de racha';
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
  String get diaryMenuTooltip => 'Menu';

  @override
  String get diaryCloseSearchTooltip => 'Cerrar busqueda';

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
  String get diaryPinSoon => 'Fijar: proximamente';

  @override
  String get diaryDeleteEntryTitle => 'Eliminar entrada';

  @override
  String get diaryDeleteEntryBody =>
      'Seguro que quieres eliminar esta entrada?';

  @override
  String diaryEntriesCount(int count) {
    return '$count entradas';
  }

  @override
  String get diaryPeriodAll => 'Todo';

  @override
  String get diaryPeriodDays => 'Dias';

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
  String get diarySearchScopeHabits => 'Habitos';

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
  String get diarySummaryEmptyTitle => 'Hoy aun no has escrito';

  @override
  String get diarySummaryEmptySubtitle => 'Un minuto puede cambiar tu dia';

  @override
  String get diarySummaryOneTitle => 'Buen comienzo';

  @override
  String get diarySummaryOneSubtitle => 'Has dado espacio a tu mente';

  @override
  String get diarySummaryFewTitle => 'Estas cuidando tu mundo interior';

  @override
  String get diarySummaryFewSubtitle => 'Sigue asi';

  @override
  String get diarySummaryManyTitle => 'Dia muy consciente';

  @override
  String get diarySummaryManySubtitle => 'Gran trabajo emocional';

  @override
  String get diaryActionEdit => 'Editar';

  @override
  String get diaryActionDelete => 'Eliminar';

  @override
  String get diaryComposerCancel => 'â† Cancelar';

  @override
  String get diaryComposerEditEntryUpper => 'EDITAR ENTRADA';

  @override
  String get diaryComposerNewEntryUpper => 'NUEVA ENTRADA';

  @override
  String get diaryComposerMoodSectionUpper => 'Â¿COMO TE SENTISTE?';

  @override
  String get diaryComposerTitleUpper => 'TITULO';

  @override
  String get diaryComposerReflectionUpper => 'REFLEXION';

  @override
  String get diaryComposerTitleHint => 'Como resumirias hoy?';

  @override
  String get diaryComposerHabitReflectionHint =>
      'Que paso hoy con tu habito? Que sentiste? Que aprendiste?';

  @override
  String get diaryComposerPersonalReflectionHint =>
      'Que tienes en mente? Que quieres dejar por escrito hoy?';

  @override
  String get diaryComposerSaveChanges => 'Guardar cambios';

  @override
  String get diaryComposerSaveEntry => 'Guardar entrada';

  @override
  String get diaryComposerTypeHabit => 'Ligada a habito';

  @override
  String get diaryComposerTypePersonal => 'Personal';

  @override
  String get diaryComposerSelectHabit => 'Seleccionar habito';

  @override
  String get diaryComposerTapToChooseHabit => 'Toca para elegir un habito';

  @override
  String get diaryComposerWriteSomethingError =>
      'Escribe algo para guardar la entrada';

  @override
  String get diaryComposerSelectHabitError => 'Selecciona un habito';

  @override
  String get diaryComposerNoActiveHabits =>
      'No hay habitos activos para seleccionar';

  @override
  String get diaryComposerSelectHabitSheetTitle => 'Seleccionar habito';

  @override
  String get diaryDetailScreenTitle => 'Entrada';

  @override
  String get diaryDetailTopHabitUpper => 'ENTRADA DE HABITO';

  @override
  String get diaryDetailTopPersonalUpper => 'ENTRADA PERSONAL';

  @override
  String get diaryDetailFallbackHabitTitle => 'Entrada de habito';

  @override
  String get diaryDetailFallbackPersonalTitle => 'Entrada personal';

  @override
  String get diaryDetailLeadingPersonal => 'Escrito personal';

  @override
  String get diaryDetailFamilyPersonal => 'Personal';

  @override
  String get diaryDetailTypeHabit => 'Dia de habito';

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
  String get habitStatsHabitFallbackTitle => 'Habito';

  @override
  String get habitStatsPeriodWeek => 'Semana';

  @override
  String get habitStatsPeriodMonth => 'Mes';

  @override
  String get habitStatsPeriodThreeMonths => '3 meses';

  @override
  String get habitStatsPeriodAll => 'Todo';

  @override
  String habitStatsDaysLabel(int count) {
    return '$count dia';
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
    return '$label: $next dias';
  }

  @override
  String get habitStatsThisWeek => 'Esta semana';

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
  String get habitStatsLegendMore => 'Mas';

  @override
  String habitStatsDayTooltip(int day) {
    return 'Dia $day';
  }

  @override
  String get habitStatsThisHabitFallback => 'este habito';

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
    return 'llegar a los $days dias';
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
      ', cuando sueles ser mas constante.';

  @override
  String get editHabitSaveChanges => 'Guardar cambios';

  @override
  String get editHabitSaving => 'Guardando...';

  @override
  String get editHabitNotificationPermissionDenied =>
      'Permisos de notificacion denegados.';

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
  String get editHabitSectionIdentity => 'Identidad';

  @override
  String get editHabitSectionCategory => 'Categoria';

  @override
  String get editHabitSectionTracking => 'Como lo mides?';

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
  String get editHabitRepetitionsSubtitle => 'Cuantas veces al dia?';

  @override
  String get editHabitUnitHint => 'Unidad (ej: vasos, km...)';

  @override
  String get editHabitCounterStepTitle => 'Incremento';

  @override
  String get editHabitCounterStepSubtitle => 'Cuanto aumenta cada toque.';

  @override
  String get editHabitFrequencyDaily => 'Cada dia';

  @override
  String get editHabitFrequencySpecificDays => 'Dias concretos';

  @override
  String get editHabitFrequencyTimesPerWeek => 'X veces / semana';

  @override
  String get editHabitWeeklyGoalTitle => 'Objetivo semanal';

  @override
  String get editHabitWeeklyGoalSubtitle =>
      'Marca cuantas veces quieres completarlo.';

  @override
  String get editHabitReminderDailyTitle => 'Notificacion diaria';

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
  String get drawerStatistics => 'EstadÃ­sticas';

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
  String get weeklyScreenUnavailableSoon => 'Pantalla no disponible todavÃ­a.';

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
  String get weeklyViewMenuDailySubtitle => 'Ver hÃ¡bitos de hoy';

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
  String get todoEmptyStateTitle => 'TodavÃ­a no tienes tareas';

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
    return 'Habito completado: $habitName';
  }

  @override
  String get diaryAfterCompletePrompt => 'Quieres anadir una nota rapida?';

  @override
  String get diaryAfterCompleteSkip => 'Ahora no';

  @override
  String get diaryAfterCompleteWrite => 'Escribir';

  @override
  String get diaryGeneralFamilyName => 'General';

  @override
  String get diaryCardTypeHabitShort => 'DIA';

  @override
  String get diaryCardTypePersonalShort => 'NOTA';

  @override
  String get diaryShowMore => 'Ver mas';

  @override
  String get diaryShowLess => 'Ver menos';

  @override
  String diaryStreakLabel(int count, String sufix) {
    return 'Racha: $count dia$sufix';
  }

  @override
  String get diaryEmotionalStreakTitle => 'Racha emocional';

  @override
  String diaryDaysLabel(int count, String sufix) {
    return '$count dia$sufix';
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
  String get createHabitNewHabitTitle => 'Nuevo habito';

  @override
  String get createHabitSaveHabit => 'Guardar habito';

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
  String get emojiPickerNoRecents => 'Tus emojis recientes apareceran aqui';

  @override
  String get emojiPickerSearchHint => 'Buscar emoji';

  @override
  String get monthlyDefaultUsername => 'Usuario';

  @override
  String get monthlyEmptyFilteredMessage =>
      'No hay habitos para mostrar en este filtro.';

  @override
  String monthlyElapsedDaysWeek(int elapsed, int week) {
    return '$elapsed dias transcurridos Â· semana $week';
  }

  @override
  String monthlyFilterSummaryFamily(String family) {
    return 'Familia: $family';
  }

  @override
  String monthlyFilterSummaryHabit(String habit) {
    return 'Habito: $habit';
  }

  @override
  String get monthlyFilterSummaryAll => 'Todos los habitos';

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
  String get monthlyFilterModeHabit => 'Habito';

  @override
  String get monthlyApplyAction => 'Aplicar';

  @override
  String get monthlySelectHabitLabel => 'Selecciona un habito';

  @override
  String get monthlyHabitSelectorTitle => 'VER HABITO';

  @override
  String get monthlyHabitFallbackTitle => 'Habito';

  @override
  String get monthlyStatMonthLabel => 'MES';

  @override
  String get monthlyStatStreakLabel => 'RACHA';

  @override
  String get monthlyStatHabitsLabel => 'HABITOS';

  @override
  String monthlyDaysLabel(int count, String sufix) {
    return '$count dia$sufix';
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
    return '$day/$month Â· $state';
  }

  @override
  String get monthlyCurrentMonthTooltip => 'Ir a este mes';

  @override
  String get monthlyMenuTooltip => 'Menu';
}
