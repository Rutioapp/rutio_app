// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get splashTagline => 'BUILD YOUR PATH';

  @override
  String get splashTapToStart => 'TAP TO START';

  @override
  String get welcomeBrand => 'RUTIO';

  @override
  String get welcomeTitleLine1 => 'Your journey\n';

  @override
  String get welcomeTitleLine2 => 'starts today.';

  @override
  String get welcomeSubtitle => 'Small steps,\nbig changes.';

  @override
  String get welcomeLoginButton => 'Log in';

  @override
  String get welcomeSignupButton => 'Create account';

  @override
  String get loginHeaderSubtitle => 'Welcome back';

  @override
  String get loginTitle => 'Log in';

  @override
  String get loginSubtitle => 'Continue where you left off';

  @override
  String get loginPasswordHint => '••••••••';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginPrimaryCta => 'Continue →';

  @override
  String get loginSwitchPrefix => 'Don\'t have an account?  ';

  @override
  String get loginSwitchLink => 'Sign up';

  @override
  String get signupHeaderSubtitle => 'Start your path';

  @override
  String get signupTitle => 'Create account';

  @override
  String get signupSubtitle => 'A small step toward your goals';

  @override
  String get signupNameLabel => 'Name';

  @override
  String get signupNameHint => 'What\'s your name?';

  @override
  String get signupPasswordHint => 'Min. 8 characters';

  @override
  String get signupPrimaryCta => 'Get started →';

  @override
  String get signupSwitchPrefix => 'Already have an account?  ';

  @override
  String get signupSwitchLink => 'Log in';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get fieldEmailHint => 'you@email.com';

  @override
  String get fieldPasswordLabel => 'Password';

  @override
  String homeErrorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get homeFallbackUsername => 'User';

  @override
  String get homeFallbackHabitTitle => 'Habit';

  @override
  String get homeHabitCompletionBurstDefault => '+XP';

  @override
  String get homeCompletedLabel => 'Completed ';

  @override
  String homeCompletedCount(String count) {
    return 'Completed ($count)';
  }

  @override
  String homeSkippedCount(String count) {
    return 'Skipped ($count)';
  }

  @override
  String get homeEmptyStateMultiline =>
      'You still have no active habits.`nTap “New” to add your first one.';

  @override
  String get homeEmptyStateSingleLine =>
      'You still have no active habits. Tap “New” to add your first one.';

  @override
  String get homeEditCounterTitle => 'Edit counter';

  @override
  String get homeEditCounterHint => 'Enter a number';

  @override
  String get homeInputValueHint => 'Enter a value';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonAdd => 'Add';

  @override
  String homeHabitCountProgress(String current, String target) {
    return '$current of $target';
  }

  @override
  String homeHabitCountProgressWithUnit(
      String current, String target, String unit) {
    return '$current of $target $unit';
  }

  @override
  String get homeAddHabitLoadError => 'Could not load the catalog';

  @override
  String homeAddHabitCreated(String name) {
    return '\"$name\" has been created';
  }

  @override
  String get homeAddHabitCreatedGeneric => 'Habit created';

  @override
  String get homeAddHabitCreateFromScratch => 'Create habit from scratch';

  @override
  String get habitConfigTypeSection => 'Type';

  @override
  String get habitConfigCheckOption => 'Check';

  @override
  String get habitConfigCounterOption => 'Counter';

  @override
  String get habitConfigGoalSection => 'Goal';

  @override
  String habitConfigGoalSectionWithUnit(String unit) {
    return 'Goal ($unit)';
  }

  @override
  String get habitConfigFrequencySection => 'Frequency';

  @override
  String get habitConfigDailyOption => 'Daily';

  @override
  String get habitConfigWeeklyOption => 'Weekly';

  @override
  String get habitConfigOnceOption => 'Once';

  @override
  String get habitConfigDaysSection => 'Days';

  @override
  String get habitConfigDateSection => 'Date';

  @override
  String get habitConfigChooseDate => 'Choose date';

  @override
  String get habitConfigInvalidGoal => 'Set a valid goal (greater than 0).';

  @override
  String get habitConfigSelectDay => 'Select at least one day.';

  @override
  String get habitConfigSelectDate => 'Select a date.';

  @override
  String get weekdayShortMon => 'Mon';

  @override
  String get weekdayShortTue => 'Tue';

  @override
  String get weekdayShortWed => 'Wed';

  @override
  String get weekdayShortThu => 'Thu';

  @override
  String get weekdayShortFri => 'Fri';

  @override
  String get weekdayShortSat => 'Sat';

  @override
  String get weekdayShortSun => 'Sun';

  @override
  String get weekdayLetterMon => 'M';

  @override
  String get weekdayLetterTue => 'T';

  @override
  String get weekdayLetterWed => 'W';

  @override
  String get weekdayLetterThu => 'T';

  @override
  String get weekdayLetterFri => 'F';

  @override
  String get weekdayLetterSat => 'S';

  @override
  String get weekdayLetterSun => 'S';

  @override
  String get unitTimesShort => 'times';

  @override
  String get unitMinutesShort => 'min';

  @override
  String get unitHoursShort => 'h';

  @override
  String get unitPagesShort => 'pages';

  @override
  String get unitStepsShort => 'steps';

  @override
  String get unitKilometersShort => 'km';

  @override
  String get unitLitersShort => 'L';

  @override
  String get familyMindName => 'Mind';

  @override
  String get familySpiritName => 'Spirit';

  @override
  String get familyBodyName => 'Body';

  @override
  String get familyEmotionalName => 'Emotional';

  @override
  String get familySocialName => 'Social';

  @override
  String get familyDisciplineName => 'Discipline';

  @override
  String get familyProfessionalName => 'Professional';

  @override
  String get catalogHabitLeerXMinutos => 'Read';

  @override
  String catalogHabitLeerXMinutosTarget(String target) {
    return 'Read $target minutes';
  }

  @override
  String get catalogHabitResolverProblemaLogico => 'Solve a logic problem';

  @override
  String get catalogHabitEscribirIdeasReflexiones =>
      'Write ideas or reflections';

  @override
  String get catalogHabitEstudiarXTiempo => 'Study';

  @override
  String catalogHabitEstudiarXTiempoTarget(String target) {
    return 'Study for $target hours';
  }

  @override
  String get catalogHabitAprenderIdioma => 'Practice a language';

  @override
  String get catalogHabitEscucharPodcastEducativo =>
      'Listen to an educational podcast';

  @override
  String get catalogHabitTomarNotas => 'Take notes about the day';

  @override
  String get catalogHabitJuegoMental => 'Mind game or puzzle';

  @override
  String get catalogHabitPracticarEscrituraCreativa => 'Creative writing';

  @override
  String get catalogHabitRepasarNotas => 'Review the day\'s notes';

  @override
  String get catalogHabitVerDocumental =>
      'Watch a documentary or educational video';

  @override
  String get catalogHabitMeditar => 'Meditate';

  @override
  String get catalogHabitPracticarGratitud => 'Practice gratitude';

  @override
  String get catalogHabitRespiracionConsciente => 'Mindful breathing';

  @override
  String get catalogHabitReflexionPersonal => 'Personal reflection';

  @override
  String get catalogHabitOracionConexionEspiritual =>
      'Prayer or spiritual connection';

  @override
  String get catalogHabitRevisarAprendizajesDia =>
      'Review the day\'s learnings';

  @override
  String get catalogHabitVisualizacionPositiva => 'Positive visualization';

  @override
  String get catalogHabitLecturaEspiritual => 'Spiritual reading';

  @override
  String get catalogHabitDesconexionDigital => 'Digital detox';

  @override
  String get catalogHabitContactoNaturaleza => 'Time in nature';

  @override
  String get catalogHabitTresCosasBuenas => 'Write 3 good things about the day';

  @override
  String get catalogHabitPaseoSinMovil => 'Walk without your phone';

  @override
  String get catalogHabitMomentoParaTi => 'Time for yourself';

  @override
  String get catalogHabitHacerEjercicio => 'Exercise';

  @override
  String get catalogHabitIrGimnasio => 'Go to the gym';

  @override
  String get catalogHabitCaminarPasosKm => 'Walk';

  @override
  String catalogHabitCaminarPasosKmTarget(String target) {
    return 'Walk $target steps';
  }

  @override
  String get catalogHabitComerSaludable => 'Eat healthy';

  @override
  String get catalogHabitBeberXLAgua => 'Drink water';

  @override
  String catalogHabitBeberXLAguaTarget(String target) {
    return 'Drink $target L of water';
  }

  @override
  String get catalogHabitDormirXHoras => 'Sleep well';

  @override
  String catalogHabitDormirXHorasTarget(String target) {
    return 'Sleep $target hours';
  }

  @override
  String get catalogHabitEstiramientos => 'Stretching';

  @override
  String get catalogHabitEvitarUltraprocesados => 'Avoid ultra-processed foods';

  @override
  String get catalogHabitCuidarPostura => 'Mind your posture';

  @override
  String get catalogHabitRutinaManana => 'Morning routine';

  @override
  String get catalogHabitRutinaNoche => 'Night routine';

  @override
  String get catalogHabitSinAlcohol => 'No alcohol';

  @override
  String get catalogHabitCardio => 'Cardio';

  @override
  String catalogHabitCardioTarget(String target) {
    return 'Cardio $target minutes';
  }

  @override
  String get catalogHabitTomarElSol => 'Get some sun';

  @override
  String get catalogHabitNoPicar => 'No snacking between meals';

  @override
  String get catalogHabitDuchaFria => 'Cold shower';

  @override
  String get catalogHabitHacerCama => 'Make the bed';

  @override
  String get catalogHabitSkincare => 'Skincare';

  @override
  String get catalogHabitHigieneBucal => 'Complete oral hygiene';

  @override
  String get catalogHabitTomarSuplementos => 'Take supplements or medication';

  @override
  String get catalogHabitHidratarPiel => 'Moisturize your skin';

  @override
  String get catalogHabitDiarioEmocional => 'Emotion journal';

  @override
  String get catalogHabitIdentificarEmociones => 'Identify my emotions';

  @override
  String get catalogHabitGestionarEstres => 'Manage stress';

  @override
  String get catalogHabitAutocompasion => 'Practice self-compassion';

  @override
  String get catalogHabitHablarSentimientos => 'Express my feelings';

  @override
  String get catalogHabitReducirPensamientosNegativos =>
      'Reduce negative thoughts';

  @override
  String get catalogHabitPracticarPaciencia => 'Practice patience';

  @override
  String get catalogHabitMomentoAlegria => 'Do something that cheers me up';

  @override
  String get catalogHabitCelebrarLogro => 'Celebrate an achievement';

  @override
  String get catalogHabitNotaAnimo => 'Daily mood score';

  @override
  String catalogHabitNotaAnimoTarget(String target) {
    return 'Mood: $target/10';
  }

  @override
  String get catalogHabitSinPantallasNoche => 'No screens before bed';

  @override
  String catalogHabitSinPantallasNocheTarget(String target) {
    return 'No screens $target min before bed';
  }

  @override
  String get catalogHabitHablarSerQuerido => 'Talk to someone you love';

  @override
  String get catalogHabitEscucharActivamente => 'Listen actively';

  @override
  String get catalogHabitExpresarGratitud => 'Express gratitude to someone';

  @override
  String get catalogHabitAyudarAlguien => 'Help someone';

  @override
  String get catalogHabitMantenerContacto => 'Stay in touch';

  @override
  String get catalogHabitCompartirExperiencias => 'Share an experience';

  @override
  String get catalogHabitPracticarEmpatia => 'Practice empathy';

  @override
  String get catalogHabitPlanSocial => 'Meet up with someone';

  @override
  String get catalogHabitDesconectarRedes => 'Disconnect from social media';

  @override
  String get catalogHabitMensajeAnimo => 'Send an encouraging message';

  @override
  String get catalogHabitLlamadaFamiliaAmigo => 'Call family or a friend';

  @override
  String get catalogHabitPlanificarDia => 'Plan the day';

  @override
  String get catalogHabitCumplirRutina => 'Stick to the routine';

  @override
  String get catalogHabitRevisarObjetivos => 'Review goals';

  @override
  String get catalogHabitEvitarProcrastinacion => 'Beat procrastination';

  @override
  String get catalogHabitTareaDificil => 'Do the hardest task first';

  @override
  String get catalogHabitPriorizarImportante => 'Prioritize what matters';

  @override
  String get catalogHabitDejarFumar => 'No tobacco';

  @override
  String get catalogHabitSinRedesSociales => 'No social media';

  @override
  String catalogHabitSinRedesSocialesTarget(String target) {
    return 'No social media for $target hours';
  }

  @override
  String get catalogHabitMadrugar => 'Wake up early';

  @override
  String get catalogHabitRevisarFinDia => 'Review the day at the end';

  @override
  String get catalogHabitApagarMovil => 'Turn off your phone at a fixed time';

  @override
  String get catalogHabitSinComprasImpulsivas => 'No impulse purchases';

  @override
  String get catalogHabitPrepararRopa => 'Prepare tomorrow\'s clothes';

  @override
  String get catalogHabitTrabajoProfundo => 'Deep work session';

  @override
  String catalogHabitTrabajoProfundoTarget(String target) {
    return 'Deep work $target min';
  }

  @override
  String get catalogHabitHabilidadLaboral => 'Develop a work skill';

  @override
  String get catalogHabitOrganizarTareas => 'Organize the day\'s tasks';

  @override
  String get catalogHabitRevisarRendimiento => 'Review performance';

  @override
  String get catalogHabitNetworking => 'Networking';

  @override
  String get catalogHabitFormacionProfesional => 'Professional training';

  @override
  String catalogHabitFormacionProfesionalTarget(String target) {
    return 'Training $target hours';
  }

  @override
  String get catalogHabitResponderEmails => 'Inbox zero';

  @override
  String get catalogHabitProyectoPersonal =>
      'Make progress on a personal project';

  @override
  String get catalogHabitLeerSector => 'Read about my industry';

  @override
  String get catalogHabitPomodoro => 'Completed Pomodoro block';

  @override
  String catalogHabitPomodoroTarget(String target) {
    return '$target pomodoros';
  }

  @override
  String get catalogHabitTrucoNuevo => 'Learn a new shortcut or trick';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSectionTitle => 'Language';

  @override
  String get settingsLanguageOptionSpanish => 'Spanish';

  @override
  String get settingsLanguageOptionEnglish => 'English';

  @override
  String get settingsAccountSectionTitle => 'Account';

  @override
  String get settingsLogoutTitle => 'Log out';

  @override
  String get settingsLogoutConfirmationBody =>
      'Are you sure you want to log out? You can sign in again at any time.';

  @override
  String get settingsLogoutConfirmAction => 'Log out';

  @override
  String get settingsLogoutError =>
      'We couldn’t log you out. Please try again.';

  @override
  String get settingsDeleteAccountTitle => 'Delete account';

  @override
  String get settingsDeleteAccountHelperText =>
      'Delete the account data stored on this device.';

  @override
  String get settingsDeleteAccountConfirmationTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountConfirmationBody =>
      'Your account and associated data stored on this device will be permanently deleted. This action cannot be undone.';

  @override
  String get settingsDeleteAccountConfirmAction => 'Delete permanently';

  @override
  String get settingsDeleteAccountError =>
      'We couldn\'t delete your account data on this device. Please try again.';

  @override
  String get settingsDeleteAccountSuccess =>
      'Your account data has been deleted from this device.';

  @override
  String get deleteAccountGenericError =>
      'Could not delete your account. Please try again.';

  @override
  String get deleteAccountNetworkError =>
      'Could not connect to delete your account. Please check your connection and try again.';

  @override
  String get deleteAccountSuccess => 'Your account has been deleted.';

  @override
  String get profileSettingsTitle => 'Settings';

  @override
  String get profileSettingsSubtitle => 'Language, privacy and more';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileDefaultName => 'Your profile';

  @override
  String get profileDefaultSubtitle => 'Your progress, settings and account';

  @override
  String get profileNotificationsTitle => 'Notifications';

  @override
  String get profileEnableNotificationsTitle => 'Enable notifications';

  @override
  String get profileEnableNotificationsSubtitle =>
      'Reminders, end-of-day prompts and streaks';

  @override
  String get profileNotificationSettingsTitle => 'Notification settings';

  @override
  String profileNotificationCategoriesActive(int count, int total) {
    return '$count of $total active categories';
  }

  @override
  String get profileAccountSectionTitle => 'Account and settings';

  @override
  String get profileThemeTitle => 'Theme';

  @override
  String get profileThemeSubtitle => 'Light / Dark / Automatic';

  @override
  String get profileThemeTodo => 'Theme (TODO)';

  @override
  String get profileHelpTitle => 'Help';

  @override
  String get profileHelpSubtitle => 'FAQ and support';

  @override
  String get profileHelpTodo => 'Help (TODO)';

  @override
  String get profileAboutTitle => 'About';

  @override
  String get profileAboutSubtitle => 'Version and legal';

  @override
  String get profileAboutTodo => 'About (TODO)';

  @override
  String get profileDangerSectionTitle => 'Danger zone';

  @override
  String get profileManageDataTitle => 'Manage data';

  @override
  String get profileManageDataSubtitle => 'Export or delete your information';

  @override
  String get profileManageDataTodo => 'Manage data (TODO)';

  @override
  String get profileLogoutTodo => 'Log out (TODO)';

  @override
  String get profileNotificationPermissionDenied =>
      'Notification permission was not granted.';

  @override
  String get profileEditButton => 'Edit';

  @override
  String get profileDangerZoneTitle => 'Danger zone';

  @override
  String get profileLogoutTitle => 'Log out';

  @override
  String get profileLogoutSubtitle =>
      'Your session will be closed on this device';

  @override
  String get profileDeleteDataTitle => 'Delete data';

  @override
  String get profileDeleteDataSubtitle =>
      'Delete all your data and progress (irreversible)';

  @override
  String get profileFamiliesProgressTitle => 'Progress by family';

  @override
  String profileFamilyLevelShort(int level) {
    return 'Lvl $level';
  }

  @override
  String profileFamilyLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get profileNotificationsPhaseOneTitle => 'Phase 1';

  @override
  String get profileNotificationHabitRemindersTitle => 'Habit reminders';

  @override
  String get profileNotificationHabitRemindersSubtitle =>
      'Respect the time configured for each habit';

  @override
  String get profileNotificationDayClosureTitle => 'End of day';

  @override
  String get profileNotificationDayClosureSubtitle =>
      'Only if there are still pending habits today';

  @override
  String get profileNotificationDayClosureTimeTitle => 'End-of-day time';

  @override
  String get profileNotificationDayClosureTimeSubtitle =>
      'A moment to remember what is still pending';

  @override
  String get profileNotificationStreakRiskTitle => 'Streak at risk';

  @override
  String get profileNotificationStreakRiskSubtitle =>
      'Alert when you can still save an important streak';

  @override
  String get profileNotificationStreakCelebrationTitle => 'Streak celebrations';

  @override
  String get profileNotificationStreakCelebrationSubtitle =>
      'Celebrate basic milestones like 1, 3, 7, 14 and 30 days';

  @override
  String get profileNotificationInactivityTitle =>
      'Reactivation after inactivity';

  @override
  String get profileNotificationInactivitySubtitle =>
      'A gentle reminder after 3 days without opening the app';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileSave => 'Save';

  @override
  String get editProfileSaveChanges => 'Save changes';

  @override
  String get editProfileSaving => 'Saving...';

  @override
  String get editProfileTakePhoto => 'Take photo';

  @override
  String get editProfileGallery => 'Gallery';

  @override
  String get editProfileRemovePhoto => 'Remove photo';

  @override
  String get editProfilePersonalInfoTitle => 'Personal information';

  @override
  String get editProfileGoalSectionTitle => 'Your goal';

  @override
  String editProfileImageSelectionError(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get editProfileSaveSuccess => 'Profile updated successfully';

  @override
  String editProfileSaveError(String error) {
    return 'Error while saving: $error';
  }

  @override
  String get editProfileDiscardChangesTitle => 'Discard changes?';

  @override
  String get editProfileDiscardChangesBody =>
      'You have unsaved changes. Are you sure you want to leave?';

  @override
  String get editProfileDiscardChangesAction => 'Discard';

  @override
  String get editProfileCropTitle => 'Crop';

  @override
  String get editProfileStatLevel => 'Level';

  @override
  String get editProfileStatXp => 'XP';

  @override
  String get editProfileStatCoins => 'Coins';

  @override
  String get editProfileNameLabel => 'Name';

  @override
  String get editProfileNameHint => 'How do you want to be seen';

  @override
  String get editProfileNameRequired => 'Name is required';

  @override
  String get editProfileNameMinLength => 'Minimum 2 characters';

  @override
  String get editProfileBioLabel => 'Bio';

  @override
  String get editProfileBioHint => 'Tell us a little about yourself...';

  @override
  String get editProfileGoalLabel => 'Goal';

  @override
  String get editProfileGoalHint => 'What do you want to achieve with Rutio';

  @override
  String get editProfileChangePhoto => 'Change profile photo';

  @override
  String get editProfileAddPhoto => 'Add profile photo';

  @override
  String get archivedHabitsTitle => 'Archived habits';

  @override
  String get archivedHabitsEmpty => 'You don\'t have any archived habits.';

  @override
  String archivedHabitsFamilyLabel(String family) {
    return 'Family: $family';
  }

  @override
  String get archivedHabitsRestoreTooltip => 'Restore';

  @override
  String get archivedHabitsDeleteTooltip => 'Delete';

  @override
  String get archivedHabitsDeleteTitle => 'Delete habit';

  @override
  String get archivedHabitsDeleteBody =>
      'Are you sure you want to delete this habit?\n\nIts history will also be deleted.';

  @override
  String get habitDetailFallbackTitle => 'Habit';

  @override
  String get habitDetailSaved => 'Changes saved';

  @override
  String get habitDetailDeleteTitle => 'Delete habit';

  @override
  String get habitDetailDeleteBody =>
      'The habit and its history will be deleted. This action cannot be undone.';

  @override
  String get habitDetailArchiveAction => 'Archive habit';

  @override
  String get habitDetailDeleteAction => 'Delete habit';

  @override
  String get habitDetailMoreOptionsTooltip => 'More options';

  @override
  String get habitDetailEditTab => 'Edit';

  @override
  String get habitDetailStatsTab => 'Statistics';

  @override
  String get archiveHabitTileTitle => 'Archive habit';

  @override
  String get archiveHabitTileArchivedSubtitle =>
      'This habit is archived (it will not appear in the main list).';

  @override
  String get archiveHabitTileActiveSubtitle =>
      'Hide this habit from the main list without deleting it.';

  @override
  String get archiveHabitTileConfirmTitle => 'Archive habit';

  @override
  String get archiveHabitTileConfirmBody =>
      'Do you want to archive this habit? You can recover it later.';

  @override
  String get archiveHabitTileConfirmAction => 'Archive';

  @override
  String get habitStatsTitle => 'Statistics';

  @override
  String get habitStatsEmpty => 'There are no habits to show.';

  @override
  String get habitStatsMetricCompleted => 'Completed';

  @override
  String habitStatsMetricCompletionDescription(int done, int total) {
    return '$done/$total days';
  }

  @override
  String get habitStatsMetricConsistency => 'Consistency';

  @override
  String habitStatsMetricConsistencyDescription(int window) {
    return 'Last $window days';
  }

  @override
  String get habitStatsMetricBestStreak => 'Best streak';

  @override
  String get habitStatsMetricPersonalBest => 'Personal best';

  @override
  String get habitStatsMetricTotalDone => 'Total done';

  @override
  String get habitStatsMetricHistoricRecords => 'Historical records';

  @override
  String get habitStatsChartWeekTitle => 'Week';

  @override
  String get habitStatsChartLastFourWeeksTitle => 'Last 4 weeks';

  @override
  String get habitStatsChartWeekSubtitle => 'Completed by day';

  @override
  String get habitStatsChartWeeksSubtitle => 'Completed aggregated by week';

  @override
  String get habitStatsNextMilestone => 'Next milestone';

  @override
  String get habitStatsWeeklyComparisonTitle => 'Weekly comparison';

  @override
  String get habitStatsWeeklyComparisonSubtitle => 'This week vs last week';

  @override
  String get habitStatsBestTimeSectionTitle => 'When do you complete it best?';

  @override
  String get habitStatsBestTimeSectionSubtitle =>
      'Based on your logs, your most consistent moments';

  @override
  String get habitStatsMonthCalendarTitle => 'Monthly calendar';

  @override
  String get habitStatsTabSummaryTitle => 'Summary';

  @override
  String habitStatsTabLastDaysTitle(int days) {
    return 'Last $days days';
  }

  @override
  String get habitStatsTabAchievementsUnlocked => 'Achievements unlocked';

  @override
  String get habitStatsTabCurrentStreakTitle => 'Current streak';

  @override
  String habitStatsTabDayUnit(int count) {
    return '$count day';
  }

  @override
  String get habitStatsTabTotalLabel => 'total';

  @override
  String habitStatsTabCompletionWindow(int done, int total) {
    return '$done / $total days';
  }

  @override
  String get habitStatsTabCounterHint =>
      'Counts how many times you completed it each day';

  @override
  String get habitStatsTabCheckHint => 'Days when you completed this habit';

  @override
  String get habitStatsTabFireStreakTitle => 'Fire streak';

  @override
  String habitStatsTabStreakInARow(int days) {
    return '$days days in a row';
  }

  @override
  String get habitStatsTabCentennialTitle => 'Centennial!';

  @override
  String get habitStatsTabHalfCenturyTitle => 'Half century';

  @override
  String habitStatsTabCompletedCount(int count) {
    return '$count completed';
  }

  @override
  String get habitStatsTabMaxConsistencyTitle => 'Peak consistency';

  @override
  String habitStatsTabLast30DaysPercent(int percent) {
    return '$percent% in the last 30 days';
  }

  @override
  String get habitStatsTabLegendaryRecordTitle => 'Legendary record';

  @override
  String habitStatsTabRecordStreak(int days) {
    return '$days-day streak';
  }

  @override
  String habitStatsTabWeeklyDelta(int delta) {
    return '$delta vs last week';
  }

  @override
  String get habitStatsTabWeeklyDeltaEqual => 'Same as last week';

  @override
  String get diaryTitle => 'Diary';

  @override
  String get diaryMenuTooltip => 'Menu';

  @override
  String get diaryCloseSearchTooltip => 'Close search';

  @override
  String get diarySearchTooltip => 'Search';

  @override
  String get diaryFiltersTooltip => 'Filters';

  @override
  String get diaryNewEntry => 'New entry';

  @override
  String get diaryEntryDeleted => 'Entry deleted';

  @override
  String get diaryEntrySaved => 'Entry saved';

  @override
  String get diaryNoteSaved => 'Note saved';

  @override
  String get diaryPinSoon => 'Pin: coming soon';

  @override
  String get diaryDeleteEntryTitle => 'Delete entry';

  @override
  String get diaryDeleteEntryBody =>
      'Are you sure you want to delete this entry?';

  @override
  String diaryEntriesCount(int count) {
    return '$count entries';
  }

  @override
  String get diaryPeriodAll => 'All';

  @override
  String get diaryPeriodDays => 'Days';

  @override
  String get diaryPeriodWeeks => 'Weeks';

  @override
  String get diaryPeriodMonths => 'Months';

  @override
  String get diarySearchHint => 'Search your diary...';

  @override
  String get diaryClearTooltip => 'Clear';

  @override
  String get diarySearchScopeAll => 'All';

  @override
  String get diarySearchScopeHabits => 'Habits';

  @override
  String get diarySearchScopePersonal => 'Personal';

  @override
  String diaryWrittenEntriesToday(int count) {
    return 'Today you wrote $count entries';
  }

  @override
  String diaryEmotionalXp(int xp) {
    return '+$xp emotional XP';
  }

  @override
  String get diarySummaryEmptyTitle => 'You have not written yet';

  @override
  String get diarySummaryEmptySubtitle => 'One minute can change your day';

  @override
  String get diarySummaryOneTitle => 'Good start';

  @override
  String get diarySummaryOneSubtitle => 'You made space for your mind';

  @override
  String get diarySummaryFewTitle => 'You are caring for your inner world';

  @override
  String get diarySummaryFewSubtitle => 'Keep it up';

  @override
  String get diarySummaryManyTitle => 'Very mindful day';

  @override
  String get diarySummaryManySubtitle => 'Great emotional work';

  @override
  String get diaryActionEdit => 'Edit';

  @override
  String get diaryActionDelete => 'Delete';

  @override
  String get diaryComposerCancel => '← Cancel';

  @override
  String get diaryComposerEditEntryUpper => 'EDIT ENTRY';

  @override
  String get diaryComposerNewEntryUpper => 'NEW ENTRY';

  @override
  String get diaryComposerMoodSectionUpper => 'HOW DID YOU FEEL?';

  @override
  String get diaryComposerTitleUpper => 'TITLE';

  @override
  String get diaryComposerReflectionUpper => 'REFLECTION';

  @override
  String get diaryComposerTitleHint => 'How would you sum up today?';

  @override
  String get diaryComposerHabitReflectionHint =>
      'What happened today with your habit? What did you feel? What did you learn?';

  @override
  String get diaryComposerPersonalReflectionHint =>
      'What is on your mind? What do you want to leave in writing today?';

  @override
  String get diaryComposerSaveChanges => 'Save changes';

  @override
  String get diaryComposerSaveEntry => 'Save entry';

  @override
  String get diaryComposerTypeHabit => 'Linked to habit';

  @override
  String get diaryComposerTypePersonal => 'Personal';

  @override
  String get diaryComposerSelectHabit => 'Select habit';

  @override
  String get diaryComposerTapToChooseHabit => 'Tap to choose a habit';

  @override
  String get diaryComposerWriteSomethingError =>
      'Write something to save the entry';

  @override
  String get diaryComposerSelectHabitError => 'Select a habit';

  @override
  String get diaryComposerNoActiveHabits =>
      'There are no active habits to choose from';

  @override
  String get diaryComposerSelectHabitSheetTitle => 'Select habit';

  @override
  String get diaryDetailScreenTitle => 'Entry';

  @override
  String get diaryDetailTopHabitUpper => 'HABIT ENTRY';

  @override
  String get diaryDetailTopPersonalUpper => 'PERSONAL ENTRY';

  @override
  String get diaryDetailFallbackHabitTitle => 'Habit entry';

  @override
  String get diaryDetailFallbackPersonalTitle => 'Personal entry';

  @override
  String get diaryDetailLeadingPersonal => 'Personal note';

  @override
  String get diaryDetailFamilyPersonal => 'Personal';

  @override
  String get diaryDetailTypeHabit => 'Habit day';

  @override
  String get diaryDetailTypePersonal => 'Personal note';

  @override
  String get diaryDetailNotesUpper => 'NOTES';

  @override
  String diaryDetailLoggedAt(String time) {
    return 'Logged at $time';
  }

  @override
  String get diaryDetailThisWeekUpper => 'THIS WEEK';

  @override
  String get diaryTodayUpper => 'TODAY';

  @override
  String habitStatsWeekShort(int weekNumber) {
    return 'W$weekNumber';
  }

  @override
  String get habitStatsHabitFallbackTitle => 'Habit';

  @override
  String get habitStatsPeriodWeek => 'Week';

  @override
  String get habitStatsPeriodMonth => 'Month';

  @override
  String get habitStatsPeriodThreeMonths => '3 months';

  @override
  String get habitStatsPeriodAll => 'All';

  @override
  String habitStatsDaysLabel(int count) {
    return '$count day';
  }

  @override
  String get habitStatsCurrentStreakUpper => 'CURRENT STREAK';

  @override
  String get habitStatsHeadlineStartToday => 'We start today!';

  @override
  String get habitStatsHeadlineGoodStart => 'Good start!';

  @override
  String get habitStatsHeadlineOnStreak => 'On a streak!';

  @override
  String habitStatsMilestoneProgress(String label, int next) {
    return '$label: $next days';
  }

  @override
  String get habitStatsThisWeek => 'This week';

  @override
  String get habitStatsLastWeek => 'Last week';

  @override
  String get habitStatsTimeSlotMorning => 'morning';

  @override
  String get habitStatsTimeSlotAfternoon => 'afternoon';

  @override
  String get habitStatsTimeSlotEvening => 'evening';

  @override
  String get habitStatsTimeSlotNight => 'late night';

  @override
  String get habitStatsLegendLess => 'Less';

  @override
  String get habitStatsLegendMore => 'More';

  @override
  String habitStatsDayTooltip(int day) {
    return 'Day $day';
  }

  @override
  String get habitStatsThisHabitFallback => 'this habit';

  @override
  String get habitStatsMotivationLead => 'You have ';

  @override
  String get habitStatsMotivationWith => ' with ';

  @override
  String get habitStatsMotivationAboveLead => 'you are ';

  @override
  String get habitStatsMotivationAboveKeyword => 'ahead';

  @override
  String get habitStatsMotivationAboveTail => ' of last week. ';

  @override
  String get habitStatsMotivationBelowLead => 'this week you are a bit ';

  @override
  String get habitStatsMotivationBelowKeyword => 'behind';

  @override
  String get habitStatsMotivationBelowTail => ' than the previous one. ';

  @override
  String get habitStatsMotivationEqual => 'you are keeping last week\'s pace. ';

  @override
  String get habitStatsMotivationStart => 'good start. ';

  @override
  String get habitStatsMotivationGoalLead => 'Planning ahead will help you ';

  @override
  String habitStatsMotivationGoalKeyword(int days) {
    return 'reach $days days';
  }

  @override
  String get habitStatsMotivationKeepLead => 'Now it is time to ';

  @override
  String get habitStatsMotivationKeepKeyword => 'keep the streak';

  @override
  String get habitStatsMotivationKeepTail => ' and make it stick.';

  @override
  String get habitStatsMotivationBestTimeLead => ' Try doing it in the ';

  @override
  String get habitStatsMotivationBestTimeTail =>
      ', when you tend to be most consistent.';

  @override
  String get editHabitSaveChanges => 'Save changes';

  @override
  String get editHabitSaving => 'Saving...';

  @override
  String get editHabitNotificationPermissionDenied =>
      'Notification permissions denied.';

  @override
  String get editHabitDailyGoalDialogTitle => 'Daily goal';

  @override
  String get editHabitDailyGoalDialogSubtitle => 'Enter the target number.';

  @override
  String get editHabitCounterStepDialogTitle => 'Increment';

  @override
  String get editHabitCounterStepDialogSubtitle =>
      'How much the counter increases each tap.';

  @override
  String get editHabitTimesPerWeekDialogTitle => 'Times per week';

  @override
  String get editHabitTimesPerWeekDialogSubtitle =>
      'You can go over it during the week.';

  @override
  String get editHabitSectionIdentity => 'Identity';

  @override
  String get editHabitSectionCategory => 'Category';

  @override
  String get editHabitSectionTracking => 'How do you track it?';

  @override
  String get editHabitSectionFrequency => 'Frequency';

  @override
  String get editHabitSectionReminder => 'Reminder';

  @override
  String get editHabitSectionDetails => 'Details';

  @override
  String get editHabitTitleHint => 'Ex: Meditate every morning';

  @override
  String get editHabitTrackingCheckTitle => 'Yes or no';

  @override
  String get editHabitTrackingCheckSubtitle => 'I did it or I did not';

  @override
  String get editHabitTrackingCountTitle => 'Counter';

  @override
  String get editHabitTrackingCountSubtitle => 'Glasses, minutes, pages...';

  @override
  String get editHabitDailyGoalSection => 'Daily goal';

  @override
  String get editHabitRepetitionsTitle => 'Repetitions';

  @override
  String get editHabitRepetitionsSubtitle => 'How many times per day?';

  @override
  String get editHabitUnitHint => 'Unit (ex: glasses, km...)';

  @override
  String get editHabitCounterStepTitle => 'Increment';

  @override
  String get editHabitCounterStepSubtitle => 'How much each tap increases it.';

  @override
  String get editHabitFrequencyDaily => 'Every day';

  @override
  String get editHabitFrequencySpecificDays => 'Specific days';

  @override
  String get editHabitFrequencyTimesPerWeek => 'X times / week';

  @override
  String get editHabitWeeklyGoalTitle => 'Weekly goal';

  @override
  String get editHabitWeeklyGoalSubtitle =>
      'Choose how many times you want to complete it.';

  @override
  String get editHabitReminderDailyTitle => 'Daily notification';

  @override
  String get editHabitReminderDailySubtitle =>
      'Choose when you want to be reminded';

  @override
  String get editHabitDescriptionHint => 'Short description';

  @override
  String get editHabitNotesHint => 'Notes or additional context';

  @override
  String get editHabitUnitPickerTitle => 'Unit';

  @override
  String get editHabitUnitPickerSubtitle =>
      'Choose a suggestion or type a custom one.';

  @override
  String get editHabitUnitPickerAction => 'Use unit';

  @override
  String get editHabitSuggestedUnitGlasses => 'glasses';

  @override
  String get editHabitSuggestedUnitMinutes => 'minutes';

  @override
  String get editHabitSuggestedUnitKilometers => 'km';

  @override
  String get editHabitSuggestedUnitPages => 'pages';

  @override
  String get editHabitSuggestedUnitSteps => 'steps';

  @override
  String get editHabitSuggestedUnitRepetitions => 'reps';

  @override
  String get editHabitSuggestedUnitHours => 'hours';

  @override
  String get drawerBrandName => 'rutio';

  @override
  String get drawerBrandTagline => 'BUILD YOUR PATH';

  @override
  String get drawerSectionViews => 'VIEWS';

  @override
  String get drawerDaily => 'Daily';

  @override
  String get drawerWeekly => 'Weekly';

  @override
  String get drawerMonthly => 'Monthly';

  @override
  String get drawerSectionTracking => 'TRACKING';

  @override
  String get drawerStatistics => 'Statistics';

  @override
  String get drawerDiary => 'Diary (Journal)';

  @override
  String get drawerSectionArchive => 'ARCHIVE';

  @override
  String get drawerArchived => 'Archived';

  @override
  String get drawerSectionAccount => 'ACCOUNT';

  @override
  String get drawerProfile => 'My profile';

  @override
  String get drawerProfileVersion => 'v0.1 alpha';

  @override
  String get weeklyScreenUnavailableSoon => 'Screen not available yet.';

  @override
  String get weeklyScreenUnavailable => 'Screen not available';

  @override
  String get weeklyWeekPrefix => 'Week';

  @override
  String weeklyActiveHabitsCount(String count) {
    return '$count ACTIVE HABITS';
  }

  @override
  String get weeklyShowHabitNameHint => '<- tap the emoji to see the name';

  @override
  String get weeklyViewMenuTitle => 'Change view';

  @override
  String get weeklyViewMenuDailyTitle => 'Daily view';

  @override
  String get weeklyViewMenuDailySubtitle => 'See today\'s habits';

  @override
  String get weeklyViewMenuWeeklyTitle => 'Weekly view';

  @override
  String get weeklyViewMenuWeeklySubtitle => 'Current';

  @override
  String get weeklyViewMenuMonthlyTitle => 'Monthly view';

  @override
  String get weeklyViewMenuMonthlySubtitle => 'See this month progress';

  @override
  String get drawerTodo => 'To-do';

  @override
  String get familyPersonalName => 'Personal';

  @override
  String get todoTitle => 'To-dos';

  @override
  String get todoDateTodayFormatLabel => 'Today';

  @override
  String get todoFilterAll => 'All';

  @override
  String get todoFilterPending => 'Pending';

  @override
  String get todoFilterToday => 'Today';

  @override
  String get todoFilterThisWeek => 'This week';

  @override
  String get todoFilterCompleted => 'Completed';

  @override
  String get todoProgressToday => 'TODAY\'S PROGRESS';

  @override
  String todoTasksCount(String total) {
    return ' / $total tasks';
  }

  @override
  String todoPendingCount(int count) {
    return '$count pending';
  }

  @override
  String todoOverdueCount(int count) {
    return '$count overdue';
  }

  @override
  String todoSectionPending(int count) {
    return 'PENDING · $count';
  }

  @override
  String todoSectionCompleted(int count) {
    return 'COMPLETED · $count';
  }

  @override
  String get todoCreateTitle => 'New task';

  @override
  String get todoEditTitle => 'Edit task';

  @override
  String get todoCancel => 'Cancel';

  @override
  String get todoSave => 'Save';

  @override
  String get todoTypeFree => 'Free task';

  @override
  String get todoTypeLinkedHabit => 'Linked to habit';

  @override
  String get todoWhatNeedToDo => 'What do you need to do?';

  @override
  String get todoDescriptionOptional => 'Description (optional)';

  @override
  String get todoWhen => 'WHEN';

  @override
  String get todoDate => 'Date';

  @override
  String get todoSelect => 'Select';

  @override
  String get todoTime => 'Time';

  @override
  String get todoNoTime => 'No time';

  @override
  String get todoCategory => 'CATEGORY';

  @override
  String get todoPriority => 'PRIORITY';

  @override
  String get todoNotes => 'NOTES';

  @override
  String get todoAddNote => 'Add a note...';

  @override
  String get todoPriorityNone => '—';

  @override
  String get todoPriorityNormal => 'Normal';

  @override
  String get todoPriorityHigh => 'High';

  @override
  String get todoPriorityUrgent => 'Urgent';

  @override
  String get todoPriorityHighBadge => 'High';

  @override
  String get todoPriorityUrgentBadge => 'Urgent';

  @override
  String todoXpReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get todoStatusOverdueYesterday => 'Overdue yesterday';

  @override
  String todoStatusOverdueDate(String date) {
    return 'Overdue $date';
  }

  @override
  String todoStatusTodayAt(String time) {
    return 'Today · $time';
  }

  @override
  String get todoStatusDueToday => 'Today';

  @override
  String get todoStatusThisWeek => 'This week';

  @override
  String todoStatusOnDate(String date) {
    return '$date';
  }

  @override
  String get todoMockMeditateTitle => 'Meditate for 10 minutes before sleep';

  @override
  String get todoMockReadTitle => 'Read 20 pages of the current book';

  @override
  String get todoMockGroceriesTitle => 'Prepare the weekly grocery list';

  @override
  String get todoMockDoctorTitle => 'Call the doctor to book an appointment';

  @override
  String get todoMockCardioTitle => 'Morning workout: 30 min cardio';

  @override
  String get todoMockWaterTitle => 'Prepare water bottle and gym bag';

  @override
  String get todoMockReviewGoalsTitle => 'Review today\'s key priorities';

  @override
  String get todoMockEncouragementTitle => 'Send an encouraging message';

  @override
  String get todoMockPrayerTitle => 'Short prayer moment';

  @override
  String get todoMockInboxTitle => 'Clear important emails';

  @override
  String get todoMockJournalTitle => '5-minute emotional journaling';

  @override
  String get todoEmptyStateTitle => 'You don\'t have any tasks yet';

  @override
  String get todoEmptyStateBody =>
      'Create your first task to start organizing this space.';

  @override
  String get todoCreateFirstTask => 'Create first task';

  @override
  String get diaryFiltersTitle => 'Filters';

  @override
  String get diaryFiltersType => 'Type';

  @override
  String get diaryFiltersPinnedOnly => 'Pinned only';

  @override
  String get diaryFiltersFamily => 'Family';

  @override
  String get diaryFiltersApply => 'Apply';

  @override
  String diaryAfterCompleteTitle(String habitName) {
    return 'Habit completed: $habitName';
  }

  @override
  String get diaryAfterCompletePrompt => 'Do you want to add a quick note?';

  @override
  String get diaryAfterCompleteSkip => 'Not now';

  @override
  String get diaryAfterCompleteWrite => 'Write';

  @override
  String get diaryGeneralFamilyName => 'General';

  @override
  String get diaryCardTypeHabitShort => 'DAY';

  @override
  String get diaryCardTypePersonalShort => 'NOTE';

  @override
  String get diaryShowMore => 'Show more';

  @override
  String get diaryShowLess => 'Show less';

  @override
  String diaryStreakLabel(int count, String sufix) {
    return 'Streak: $count day$sufix';
  }

  @override
  String get diaryEmotionalStreakTitle => 'Emotional streak';

  @override
  String diaryDaysLabel(int count, String sufix) {
    return '$count day$sufix';
  }

  @override
  String get monthShortJan => 'Jan';

  @override
  String get monthShortFeb => 'Feb';

  @override
  String get monthShortMar => 'Mar';

  @override
  String get monthShortApr => 'Apr';

  @override
  String get monthShortMay => 'May';

  @override
  String get monthShortJun => 'Jun';

  @override
  String get monthShortJul => 'Jul';

  @override
  String get monthShortAug => 'Aug';

  @override
  String get monthShortSep => 'Sep';

  @override
  String get monthShortOct => 'Oct';

  @override
  String get monthShortNov => 'Nov';

  @override
  String get monthShortDec => 'Dec';

  @override
  String get createHabitNewHabitTitle => 'New habit';

  @override
  String get createHabitSaveHabit => 'Save habit';

  @override
  String get createHabitSaved => 'Saved';

  @override
  String get emojiPickerTitle => 'Select an emoji';

  @override
  String emojiPickerCurrent(String emoji) {
    return 'Current: $emoji';
  }

  @override
  String get emojiPickerBrowseSubtitle =>
      'Full catalog with categories and search';

  @override
  String get emojiPickerNoRecents => 'Your recent emojis will appear here';

  @override
  String get emojiPickerSearchHint => 'Search emoji';

  @override
  String get monthlyDefaultUsername => 'User';

  @override
  String get monthlyEmptyFilteredMessage =>
      'There are no habits to show for this filter.';

  @override
  String monthlyElapsedDaysWeek(int elapsed, int week) {
    return '$elapsed days elapsed · week $week';
  }

  @override
  String monthlyFilterSummaryFamily(String family) {
    return 'Family: $family';
  }

  @override
  String monthlyFilterSummaryHabit(String habit) {
    return 'Habit: $habit';
  }

  @override
  String get monthlyFilterSummaryAll => 'All habits';

  @override
  String get monthlyFiltersTooltip => 'Filters';

  @override
  String get monthlyResetTooltip => 'Reset';

  @override
  String get monthlyFiltersTitle => 'Filters';

  @override
  String get monthlyResetAction => 'Reset';

  @override
  String get monthlyFilterModeAll => 'All';

  @override
  String get monthlyFilterModeFamily => 'Family';

  @override
  String get monthlyFilterModeHabit => 'Habit';

  @override
  String get monthlyApplyAction => 'Apply';

  @override
  String get monthlySelectHabitLabel => 'Select a habit';

  @override
  String get monthlyHabitSelectorTitle => 'VIEW HABIT';

  @override
  String get monthlyHabitFallbackTitle => 'Habit';

  @override
  String get monthlyStatMonthLabel => 'MONTH';

  @override
  String get monthlyStatStreakLabel => 'STREAK';

  @override
  String get monthlyStatHabitsLabel => 'HABITS';

  @override
  String monthlyDaysLabel(int count, String sufix) {
    return '$count day$sufix';
  }

  @override
  String get monthlyCurrentStreakSoft => 'current streak';

  @override
  String get monthlyBestStreakSoft => 'best streak';

  @override
  String get monthlySelectionToday => 'Today';

  @override
  String get monthlySelectionDone => 'Completed';

  @override
  String get monthlySelectionSkipped => 'Skipped';

  @override
  String get monthlySelectionPending => 'Pending';

  @override
  String get monthlySelectionFuture => 'Future';

  @override
  String get monthlySelectionUnscheduled => 'Unscheduled';

  @override
  String get monthlySelectionSelected => 'Selected';

  @override
  String monthlySelectionLabel(int day, int month, String state) {
    return '$day/$month · $state';
  }

  @override
  String get monthlyCurrentMonthTooltip => 'Go to this month';

  @override
  String get monthlyMenuTooltip => 'Menu';
}
