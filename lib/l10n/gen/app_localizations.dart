import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @weeklyReportTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu semana'**
  String get weeklyReportTitle;

  /// No description provided for @weeklyReportFinalLabel.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get weeklyReportFinalLabel;

  /// No description provided for @weeklyReportSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen semanal'**
  String get weeklyReportSummary;

  /// No description provided for @weeklyReportCompleted.
  ///
  /// In es, this message translates to:
  /// **'completados'**
  String get weeklyReportCompleted;

  /// No description provided for @weeklyReportCompletion.
  ///
  /// In es, this message translates to:
  /// **'cumplimiento'**
  String get weeklyReportCompletion;

  /// No description provided for @weeklyReportBestDay.
  ///
  /// In es, this message translates to:
  /// **'mejor día'**
  String get weeklyReportBestDay;

  /// No description provided for @weeklyReportDaily.
  ///
  /// In es, this message translates to:
  /// **'Tu semana día a día'**
  String get weeklyReportDaily;

  /// No description provided for @weeklyReportNoScheduled.
  ///
  /// In es, this message translates to:
  /// **'Sin hábitos programados'**
  String get weeklyReportNoScheduled;

  /// No description provided for @weeklyReportProvisionalMessage.
  ///
  /// In es, this message translates to:
  /// **'Reporte provisional · Se actualizará durante el domingo'**
  String get weeklyReportProvisionalMessage;

  /// No description provided for @weeklyReportFirstWeek.
  ///
  /// In es, this message translates to:
  /// **'Tu primera semana en Rutio'**
  String get weeklyReportFirstWeek;

  /// No description provided for @weeklyReportOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · mostrando datos guardados'**
  String get weeklyReportOffline;

  /// No description provided for @weeklyReportTrendStable.
  ///
  /// In es, this message translates to:
  /// **'Sin cambios respecto a la semana anterior'**
  String get weeklyReportTrendStable;

  /// No description provided for @weeklyReportTrendCompared.
  ///
  /// In es, this message translates to:
  /// **'respecto a la semana anterior'**
  String get weeklyReportTrendCompared;

  /// No description provided for @weeklyReportOf.
  ///
  /// In es, this message translates to:
  /// **'de'**
  String get weeklyReportOf;

  /// No description provided for @weeklyReportEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu reporte todavía no está disponible.'**
  String get weeklyReportEmpty;

  /// No description provided for @weeklyReportError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar tu reporte.'**
  String get weeklyReportError;

  /// No description provided for @weeklyReportRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get weeklyReportRetry;

  /// No description provided for @weeklyReportDebugGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar reporte provisional · Debug'**
  String get weeklyReportDebugGenerate;

  /// No description provided for @weeklyReportDebugRefresh.
  ///
  /// In es, this message translates to:
  /// **'Refrescar reporte · Debug'**
  String get weeklyReportDebugRefresh;

  /// No description provided for @weeklyReportHabitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábitos de la semana'**
  String get weeklyReportHabitsTitle;

  /// No description provided for @weeklyReportHabitFeatured.
  ///
  /// In es, this message translates to:
  /// **'Destacado'**
  String get weeklyReportHabitFeatured;

  /// No description provided for @weeklyReportHabitStable.
  ///
  /// In es, this message translates to:
  /// **'Estable'**
  String get weeklyReportHabitStable;

  /// No description provided for @weeklyReportHabitNeedsAttention.
  ///
  /// In es, this message translates to:
  /// **'Necesita atención'**
  String get weeklyReportHabitNeedsAttention;

  /// No description provided for @weeklyReportHabitNoSchedule.
  ///
  /// In es, this message translates to:
  /// **'Sin programación'**
  String get weeklyReportHabitNoSchedule;

  /// No description provided for @weeklyReportHabitCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get weeklyReportHabitCompleted;

  /// No description provided for @weeklyReportHabitSkipped.
  ///
  /// In es, this message translates to:
  /// **'Omitido'**
  String get weeklyReportHabitSkipped;

  /// No description provided for @weeklyReportHabitPartial.
  ///
  /// In es, this message translates to:
  /// **'Parcial'**
  String get weeklyReportHabitPartial;

  /// No description provided for @weeklyReportHabitNoActivity.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad'**
  String get weeklyReportHabitNoActivity;

  /// No description provided for @weeklyReportHabitStreak.
  ///
  /// In es, this message translates to:
  /// **'racha'**
  String get weeklyReportHabitStreak;

  /// No description provided for @weeklyReportHabitGroupFeatured.
  ///
  /// In es, this message translates to:
  /// **'Destacados'**
  String get weeklyReportHabitGroupFeatured;

  /// No description provided for @weeklyReportHabitGroupFeaturedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus hábitos con mejor semana'**
  String get weeklyReportHabitGroupFeaturedSubtitle;

  /// No description provided for @weeklyReportHabitGroupStable.
  ///
  /// In es, this message translates to:
  /// **'Estables'**
  String get weeklyReportHabitGroupStable;

  /// No description provided for @weeklyReportHabitGroupStableSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mantuvieron un buen ritmo'**
  String get weeklyReportHabitGroupStableSubtitle;

  /// No description provided for @weeklyReportHabitGroupNeedsAttention.
  ///
  /// In es, this message translates to:
  /// **'Necesitan atención'**
  String get weeklyReportHabitGroupNeedsAttention;

  /// No description provided for @weeklyReportHabitGroupNeedsAttentionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los que más pueden mejorar'**
  String get weeklyReportHabitGroupNeedsAttentionSubtitle;

  /// No description provided for @weeklyReportHabitUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Sin programación esta semana'**
  String get weeklyReportHabitUnavailable;

  /// No description provided for @weeklyReportHabitCountUnit.
  ///
  /// In es, this message translates to:
  /// **'hábitos'**
  String get weeklyReportHabitCountUnit;

  /// No description provided for @weeklyReportHabitExpanded.
  ///
  /// In es, this message translates to:
  /// **'Expandido'**
  String get weeklyReportHabitExpanded;

  /// No description provided for @weeklyReportHabitCollapsed.
  ///
  /// In es, this message translates to:
  /// **'Contraído'**
  String get weeklyReportHabitCollapsed;

  /// No description provided for @weeklyReportHabitExpand.
  ///
  /// In es, this message translates to:
  /// **'Expandir'**
  String get weeklyReportHabitExpand;

  /// No description provided for @weeklyReportHabitCollapse.
  ///
  /// In es, this message translates to:
  /// **'Contraer'**
  String get weeklyReportHabitCollapse;

  /// No description provided for @weeklyReportHabitDayCompleted.
  ///
  /// In es, this message translates to:
  /// **'{day}: completado'**
  String weeklyReportHabitDayCompleted(Object day);

  /// No description provided for @weeklyReportHabitDayIncomplete.
  ///
  /// In es, this message translates to:
  /// **'{day}: pendiente'**
  String weeklyReportHabitDayIncomplete(Object day);

  /// No description provided for @weeklyReportHabitDaySkipped.
  ///
  /// In es, this message translates to:
  /// **'{day}: omitido'**
  String weeklyReportHabitDaySkipped(Object day);

  /// No description provided for @weeklyReportHabitDayPartial.
  ///
  /// In es, this message translates to:
  /// **'{day}: parcial'**
  String weeklyReportHabitDayPartial(Object day);

  /// No description provided for @weeklyReportHabitDayNoSchedule.
  ///
  /// In es, this message translates to:
  /// **'{day}: sin programación'**
  String weeklyReportHabitDayNoSchedule(Object day);

  /// No description provided for @weeklyReportHabitDayNoActivity.
  ///
  /// In es, this message translates to:
  /// **'{day}: sin actividad'**
  String weeklyReportHabitDayNoActivity(Object day);

  /// No description provided for @splashTagline.
  ///
  /// In es, this message translates to:
  /// **'CONSTRUYE TU CAMINO'**
  String get splashTagline;

  /// No description provided for @splashTapToStart.
  ///
  /// In es, this message translates to:
  /// **'TOCA PARA COMENZAR'**
  String get splashTapToStart;

  /// No description provided for @welcomeBrand.
  ///
  /// In es, this message translates to:
  /// **'RUTIO'**
  String get welcomeBrand;

  /// No description provided for @welcomeTitleLine1.
  ///
  /// In es, this message translates to:
  /// **'Tu camino\n'**
  String get welcomeTitleLine1;

  /// No description provided for @welcomeTitleLine2.
  ///
  /// In es, this message translates to:
  /// **'empieza hoy.'**
  String get welcomeTitleLine2;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pequeños pasos,\ngrandes cambios.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeLoginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get welcomeLoginButton;

  /// No description provided for @welcomeSignupButton.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get welcomeSignupButton;

  /// No description provided for @loginHeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de vuelta'**
  String get loginHeaderSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Continúa donde lo dejaste'**
  String get loginSubtitle;

  /// No description provided for @loginPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'••••••••'**
  String get loginPasswordHint;

  /// No description provided for @loginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get loginForgotPassword;

  /// No description provided for @loginPrimaryCta.
  ///
  /// In es, this message translates to:
  /// **'Continuar →'**
  String get loginPrimaryCta;

  /// No description provided for @loginSwitchPrefix.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?  '**
  String get loginSwitchPrefix;

  /// No description provided for @loginSwitchLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get loginSwitchLink;

  /// No description provided for @signupHeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza tu camino'**
  String get signupHeaderSubtitle;

  /// No description provided for @signupTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un pequeño paso hacia tus metas'**
  String get signupSubtitle;

  /// No description provided for @signupNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get signupNameLabel;

  /// No description provided for @signupNameHint.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te llamas?'**
  String get signupNameHint;

  /// No description provided for @signupPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Mín. 8 caracteres'**
  String get signupPasswordHint;

  /// No description provided for @signupPrimaryCta.
  ///
  /// In es, this message translates to:
  /// **'Comenzar →'**
  String get signupPrimaryCta;

  /// No description provided for @signupSwitchPrefix.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?  '**
  String get signupSwitchPrefix;

  /// No description provided for @signupSwitchLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get signupSwitchLink;

  /// No description provided for @fieldEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get fieldEmailLabel;

  /// No description provided for @fieldEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get fieldEmailHint;

  /// No description provided for @fieldPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get fieldPasswordLabel;

  /// No description provided for @homeErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String homeErrorMessage(String error);

  /// No description provided for @homeFallbackUsername.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get homeFallbackUsername;

  /// No description provided for @homeFallbackHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábito'**
  String get homeFallbackHabitTitle;

  /// No description provided for @homeHabitCompletionBurstDefault.
  ///
  /// In es, this message translates to:
  /// **'+XP'**
  String get homeHabitCompletionBurstDefault;

  /// No description provided for @homeCompletedLabel.
  ///
  /// In es, this message translates to:
  /// **'Completados '**
  String get homeCompletedLabel;

  /// No description provided for @homeCompletedCount.
  ///
  /// In es, this message translates to:
  /// **'Completados ({count})'**
  String homeCompletedCount(String count);

  /// No description provided for @homeSkippedCount.
  ///
  /// In es, this message translates to:
  /// **'Skipeados ({count})'**
  String homeSkippedCount(String count);

  /// No description provided for @homeSkippedToday.
  ///
  /// In es, this message translates to:
  /// **'Omitido hoy'**
  String get homeSkippedToday;

  /// No description provided for @homeEmptyStateMultiline.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes hábitos activos.\nPulsa “Nuevo” para añadir el primero.'**
  String get homeEmptyStateMultiline;

  /// No description provided for @homeEmptyStateSingleLine.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes hábitos activos. Pulsa “Nuevo” para añadir el primero.'**
  String get homeEmptyStateSingleLine;

  /// No description provided for @homeEditCounterTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar contador'**
  String get homeEditCounterTitle;

  /// No description provided for @homeEditCounterHint.
  ///
  /// In es, this message translates to:
  /// **'Introduce un número'**
  String get homeEditCounterHint;

  /// No description provided for @homeInputValueHint.
  ///
  /// In es, this message translates to:
  /// **'Introduce un valor'**
  String get homeInputValueHint;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get commonAdd;

  /// No description provided for @homeSwipeActionSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get homeSwipeActionSkip;

  /// No description provided for @homeSwipeActionEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get homeSwipeActionEdit;

  /// No description provided for @homeSwipeActionDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get homeSwipeActionDelete;

  /// No description provided for @homeSwipeDeleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar hábito'**
  String get homeSwipeDeleteConfirmTitle;

  /// No description provided for @homeSwipeDeleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrará el hábito y su historial. Esta acción no se puede deshacer.'**
  String get homeSwipeDeleteConfirmBody;

  /// No description provided for @homeSwipeDeleteConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get homeSwipeDeleteConfirmAction;

  /// No description provided for @levelUpNormalTitle.
  ///
  /// In es, this message translates to:
  /// **'Enhorabuena'**
  String get levelUpNormalTitle;

  /// No description provided for @levelUpNormalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Has subido al nivel {level}.'**
  String levelUpNormalSubtitle(int level);

  /// No description provided for @levelUpFirstMilestoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Primer gran hito'**
  String get levelUpFirstMilestoneTitle;

  /// No description provided for @levelUpFirstMilestoneSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el nivel {level}. Tus rutinas empiezan a tomar forma.'**
  String levelUpFirstMilestoneSubtitle(int level);

  /// No description provided for @levelUpMajorMilestoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo hito alcanzado'**
  String get levelUpMajorMilestoneTitle;

  /// No description provided for @levelUpMajorMilestoneSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Has llegado al nivel {level}. Tu constancia sigue creciendo.'**
  String levelUpMajorMilestoneSubtitle(int level);

  /// No description provided for @levelUpContinueButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get levelUpContinueButton;

  /// No description provided for @levelUpShareButton.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get levelUpShareButton;

  /// No description provided for @levelUpRewardAmbarLine.
  ///
  /// In es, this message translates to:
  /// **'Has recibido {amount} Ámbar.'**
  String levelUpRewardAmbarLine(int amount);

  /// No description provided for @homeHabitCountProgress.
  ///
  /// In es, this message translates to:
  /// **'{current} de {target}'**
  String homeHabitCountProgress(String current, String target);

  /// No description provided for @homeHabitCountProgressWithUnit.
  ///
  /// In es, this message translates to:
  /// **'{current} de {target} {unit}'**
  String homeHabitCountProgressWithUnit(
      String current, String target, String unit);

  /// No description provided for @homeTimesPerWeekProgress.
  ///
  /// In es, this message translates to:
  /// **'{completed}/{target} esta semana'**
  String homeTimesPerWeekProgress(String completed, String target);

  /// No description provided for @homeAddHabitLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el catálogo'**
  String get homeAddHabitLoadError;

  /// No description provided for @homeAddHabitCreated.
  ///
  /// In es, this message translates to:
  /// **'Se ha creado \"{name}\"'**
  String homeAddHabitCreated(String name);

  /// No description provided for @homeAddHabitCreatedGeneric.
  ///
  /// In es, this message translates to:
  /// **'Hábito creado'**
  String get homeAddHabitCreatedGeneric;

  /// No description provided for @homeAddHabitCreateFromScratch.
  ///
  /// In es, this message translates to:
  /// **'Crear hábito desde cero'**
  String get homeAddHabitCreateFromScratch;

  /// No description provided for @habitConfigTypeSection.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get habitConfigTypeSection;

  /// No description provided for @habitConfigCheckOption.
  ///
  /// In es, this message translates to:
  /// **'Check'**
  String get habitConfigCheckOption;

  /// No description provided for @habitConfigCounterOption.
  ///
  /// In es, this message translates to:
  /// **'Contador'**
  String get habitConfigCounterOption;

  /// No description provided for @habitConfigGoalSection.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get habitConfigGoalSection;

  /// No description provided for @habitConfigGoalSectionWithUnit.
  ///
  /// In es, this message translates to:
  /// **'Objetivo ({unit})'**
  String habitConfigGoalSectionWithUnit(String unit);

  /// No description provided for @habitConfigFrequencySection.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get habitConfigFrequencySection;

  /// No description provided for @habitConfigDailyOption.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get habitConfigDailyOption;

  /// No description provided for @habitConfigWeeklyOption.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get habitConfigWeeklyOption;

  /// No description provided for @habitConfigOnceOption.
  ///
  /// In es, this message translates to:
  /// **'Una vez'**
  String get habitConfigOnceOption;

  /// No description provided for @habitConfigDaysSection.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get habitConfigDaysSection;

  /// No description provided for @habitConfigDateSection.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get habitConfigDateSection;

  /// No description provided for @habitConfigChooseDate.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get habitConfigChooseDate;

  /// No description provided for @habitConfigInvalidGoal.
  ///
  /// In es, this message translates to:
  /// **'Pon un objetivo válido (mayor que 0).'**
  String get habitConfigInvalidGoal;

  /// No description provided for @habitConfigSelectDay.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un día.'**
  String get habitConfigSelectDay;

  /// No description provided for @habitConfigSelectDate.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una fecha.'**
  String get habitConfigSelectDate;

  /// No description provided for @weekdayShortMon.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get weekdayShortMon;

  /// No description provided for @weekdayShortTue.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get weekdayShortTue;

  /// No description provided for @weekdayShortWed.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get weekdayShortWed;

  /// No description provided for @weekdayShortThu.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get weekdayShortThu;

  /// No description provided for @weekdayShortFri.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get weekdayShortFri;

  /// No description provided for @weekdayShortSat.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get weekdayShortSat;

  /// No description provided for @weekdayShortSun.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get weekdayShortSun;

  /// No description provided for @weekdayLetterMon.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get weekdayLetterMon;

  /// No description provided for @weekdayLetterTue.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get weekdayLetterTue;

  /// No description provided for @weekdayLetterWed.
  ///
  /// In es, this message translates to:
  /// **'X'**
  String get weekdayLetterWed;

  /// No description provided for @weekdayLetterThu.
  ///
  /// In es, this message translates to:
  /// **'J'**
  String get weekdayLetterThu;

  /// No description provided for @weekdayLetterFri.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get weekdayLetterFri;

  /// No description provided for @weekdayLetterSat.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get weekdayLetterSat;

  /// No description provided for @weekdayLetterSun.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get weekdayLetterSun;

  /// No description provided for @unitTimesShort.
  ///
  /// In es, this message translates to:
  /// **'veces'**
  String get unitTimesShort;

  /// No description provided for @unitMinutesShort.
  ///
  /// In es, this message translates to:
  /// **'min'**
  String get unitMinutesShort;

  /// No description provided for @unitHoursShort.
  ///
  /// In es, this message translates to:
  /// **'h'**
  String get unitHoursShort;

  /// No description provided for @unitPagesShort.
  ///
  /// In es, this message translates to:
  /// **'páginas'**
  String get unitPagesShort;

  /// No description provided for @unitStepsShort.
  ///
  /// In es, this message translates to:
  /// **'pasos'**
  String get unitStepsShort;

  /// No description provided for @unitKilometersShort.
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get unitKilometersShort;

  /// No description provided for @unitLitersShort.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get unitLitersShort;

  /// No description provided for @habitUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'{unit, select, times{veces} minutes{min} mins{min} min{min} hours{h} hour{h} h{h} pages{páginas} page{páginas} steps{pasos} step{pasos} km{km} liters{L} liter{L} l{L} other{{unit}}}'**
  String habitUnitLabel(String unit);

  /// No description provided for @familyMindName.
  ///
  /// In es, this message translates to:
  /// **'Mente'**
  String get familyMindName;

  /// No description provided for @familySpiritName.
  ///
  /// In es, this message translates to:
  /// **'Espíritu'**
  String get familySpiritName;

  /// No description provided for @familyBodyName.
  ///
  /// In es, this message translates to:
  /// **'Cuerpo'**
  String get familyBodyName;

  /// No description provided for @familyEmotionalName.
  ///
  /// In es, this message translates to:
  /// **'Emocional'**
  String get familyEmotionalName;

  /// No description provided for @familySocialName.
  ///
  /// In es, this message translates to:
  /// **'Social'**
  String get familySocialName;

  /// No description provided for @familyDisciplineName.
  ///
  /// In es, this message translates to:
  /// **'Disciplina'**
  String get familyDisciplineName;

  /// No description provided for @familyProfessionalName.
  ///
  /// In es, this message translates to:
  /// **'Profesional'**
  String get familyProfessionalName;

  /// No description provided for @catalogHabitLeerXMinutos.
  ///
  /// In es, this message translates to:
  /// **'Leer'**
  String get catalogHabitLeerXMinutos;

  /// No description provided for @catalogHabitLeerXMinutosTarget.
  ///
  /// In es, this message translates to:
  /// **'Leer {target} minutos'**
  String catalogHabitLeerXMinutosTarget(String target);

  /// No description provided for @catalogHabitResolverProblemaLogico.
  ///
  /// In es, this message translates to:
  /// **'Resolver un problema lógico'**
  String get catalogHabitResolverProblemaLogico;

  /// No description provided for @catalogHabitEscribirIdeasReflexiones.
  ///
  /// In es, this message translates to:
  /// **'Escribir ideas o reflexiones'**
  String get catalogHabitEscribirIdeasReflexiones;

  /// No description provided for @catalogHabitEstudiarXTiempo.
  ///
  /// In es, this message translates to:
  /// **'Estudiar'**
  String get catalogHabitEstudiarXTiempo;

  /// No description provided for @catalogHabitEstudiarXTiempoTarget.
  ///
  /// In es, this message translates to:
  /// **'Estudiar {target} horas'**
  String catalogHabitEstudiarXTiempoTarget(String target);

  /// No description provided for @catalogHabitAprenderIdioma.
  ///
  /// In es, this message translates to:
  /// **'Practicar un idioma'**
  String get catalogHabitAprenderIdioma;

  /// No description provided for @catalogHabitEscucharPodcastEducativo.
  ///
  /// In es, this message translates to:
  /// **'Escuchar podcast educativo'**
  String get catalogHabitEscucharPodcastEducativo;

  /// No description provided for @catalogHabitTomarNotas.
  ///
  /// In es, this message translates to:
  /// **'Tomar notas del día'**
  String get catalogHabitTomarNotas;

  /// No description provided for @catalogHabitJuegoMental.
  ///
  /// In es, this message translates to:
  /// **'Juego mental o rompecabezas'**
  String get catalogHabitJuegoMental;

  /// No description provided for @catalogHabitPracticarEscrituraCreativa.
  ///
  /// In es, this message translates to:
  /// **'Escritura creativa'**
  String get catalogHabitPracticarEscrituraCreativa;

  /// No description provided for @catalogHabitRepasarNotas.
  ///
  /// In es, this message translates to:
  /// **'Repasar notas del día'**
  String get catalogHabitRepasarNotas;

  /// No description provided for @catalogHabitVerDocumental.
  ///
  /// In es, this message translates to:
  /// **'Ver un documental o vídeo educativo'**
  String get catalogHabitVerDocumental;

  /// No description provided for @catalogHabitMeditar.
  ///
  /// In es, this message translates to:
  /// **'Meditar'**
  String get catalogHabitMeditar;

  /// No description provided for @catalogHabitPracticarGratitud.
  ///
  /// In es, this message translates to:
  /// **'Practicar gratitud'**
  String get catalogHabitPracticarGratitud;

  /// No description provided for @catalogHabitRespiracionConsciente.
  ///
  /// In es, this message translates to:
  /// **'Respiración consciente'**
  String get catalogHabitRespiracionConsciente;

  /// No description provided for @catalogHabitReflexionPersonal.
  ///
  /// In es, this message translates to:
  /// **'Reflexión personal'**
  String get catalogHabitReflexionPersonal;

  /// No description provided for @catalogHabitOracionConexionEspiritual.
  ///
  /// In es, this message translates to:
  /// **'Oración o conexión espiritual'**
  String get catalogHabitOracionConexionEspiritual;

  /// No description provided for @catalogHabitRevisarAprendizajesDia.
  ///
  /// In es, this message translates to:
  /// **'Revisar aprendizajes del día'**
  String get catalogHabitRevisarAprendizajesDia;

  /// No description provided for @catalogHabitVisualizacionPositiva.
  ///
  /// In es, this message translates to:
  /// **'Visualización positiva'**
  String get catalogHabitVisualizacionPositiva;

  /// No description provided for @catalogHabitLecturaEspiritual.
  ///
  /// In es, this message translates to:
  /// **'Lectura espiritual'**
  String get catalogHabitLecturaEspiritual;

  /// No description provided for @catalogHabitDesconexionDigital.
  ///
  /// In es, this message translates to:
  /// **'Desconexión digital'**
  String get catalogHabitDesconexionDigital;

  /// No description provided for @catalogHabitContactoNaturaleza.
  ///
  /// In es, this message translates to:
  /// **'Tiempo en la naturaleza'**
  String get catalogHabitContactoNaturaleza;

  /// No description provided for @catalogHabitTresCosasBuenas.
  ///
  /// In es, this message translates to:
  /// **'Escribir 3 cosas buenas del día'**
  String get catalogHabitTresCosasBuenas;

  /// No description provided for @catalogHabitPaseoSinMovil.
  ///
  /// In es, this message translates to:
  /// **'Paseo sin móvil'**
  String get catalogHabitPaseoSinMovil;

  /// No description provided for @catalogHabitMomentoParaTi.
  ///
  /// In es, this message translates to:
  /// **'Momento para ti'**
  String get catalogHabitMomentoParaTi;

  /// No description provided for @catalogHabitHacerEjercicio.
  ///
  /// In es, this message translates to:
  /// **'Hacer ejercicio'**
  String get catalogHabitHacerEjercicio;

  /// No description provided for @catalogHabitIrGimnasio.
  ///
  /// In es, this message translates to:
  /// **'Ir al gimnasio'**
  String get catalogHabitIrGimnasio;

  /// No description provided for @catalogHabitCaminarPasosKm.
  ///
  /// In es, this message translates to:
  /// **'Caminar'**
  String get catalogHabitCaminarPasosKm;

  /// No description provided for @catalogHabitCaminarPasosKmTarget.
  ///
  /// In es, this message translates to:
  /// **'Caminar {target} pasos'**
  String catalogHabitCaminarPasosKmTarget(String target);

  /// No description provided for @catalogHabitComerSaludable.
  ///
  /// In es, this message translates to:
  /// **'Comer saludable'**
  String get catalogHabitComerSaludable;

  /// No description provided for @catalogHabitBeberXLAgua.
  ///
  /// In es, this message translates to:
  /// **'Beber agua'**
  String get catalogHabitBeberXLAgua;

  /// No description provided for @catalogHabitBeberXLAguaTarget.
  ///
  /// In es, this message translates to:
  /// **'Beber {target} L de agua'**
  String catalogHabitBeberXLAguaTarget(String target);

  /// No description provided for @catalogHabitDormirXHoras.
  ///
  /// In es, this message translates to:
  /// **'Dormir bien'**
  String get catalogHabitDormirXHoras;

  /// No description provided for @catalogHabitDormirXHorasTarget.
  ///
  /// In es, this message translates to:
  /// **'Dormir {target} horas'**
  String catalogHabitDormirXHorasTarget(String target);

  /// No description provided for @catalogHabitEstiramientos.
  ///
  /// In es, this message translates to:
  /// **'Estiramientos'**
  String get catalogHabitEstiramientos;

  /// No description provided for @catalogHabitEvitarUltraprocesados.
  ///
  /// In es, this message translates to:
  /// **'Evitar ultraprocesados'**
  String get catalogHabitEvitarUltraprocesados;

  /// No description provided for @catalogHabitCuidarPostura.
  ///
  /// In es, this message translates to:
  /// **'Cuidar la postura'**
  String get catalogHabitCuidarPostura;

  /// No description provided for @catalogHabitRutinaManana.
  ///
  /// In es, this message translates to:
  /// **'Rutina de mañana'**
  String get catalogHabitRutinaManana;

  /// No description provided for @catalogHabitRutinaNoche.
  ///
  /// In es, this message translates to:
  /// **'Rutina de noche'**
  String get catalogHabitRutinaNoche;

  /// No description provided for @catalogHabitSinAlcohol.
  ///
  /// In es, this message translates to:
  /// **'Sin alcohol'**
  String get catalogHabitSinAlcohol;

  /// No description provided for @catalogHabitCardio.
  ///
  /// In es, this message translates to:
  /// **'Cardio'**
  String get catalogHabitCardio;

  /// No description provided for @catalogHabitCardioTarget.
  ///
  /// In es, this message translates to:
  /// **'Cardio {target} minutos'**
  String catalogHabitCardioTarget(String target);

  /// No description provided for @catalogHabitTomarElSol.
  ///
  /// In es, this message translates to:
  /// **'Tomar el sol'**
  String get catalogHabitTomarElSol;

  /// No description provided for @catalogHabitNoPicar.
  ///
  /// In es, this message translates to:
  /// **'No picar entre horas'**
  String get catalogHabitNoPicar;

  /// No description provided for @catalogHabitDuchaFria.
  ///
  /// In es, this message translates to:
  /// **'Ducha fría'**
  String get catalogHabitDuchaFria;

  /// No description provided for @catalogHabitHacerCama.
  ///
  /// In es, this message translates to:
  /// **'Hacer la cama'**
  String get catalogHabitHacerCama;

  /// No description provided for @catalogHabitSkincare.
  ///
  /// In es, this message translates to:
  /// **'Skincare'**
  String get catalogHabitSkincare;

  /// No description provided for @catalogHabitHigieneBucal.
  ///
  /// In es, this message translates to:
  /// **'Higiene bucal completa'**
  String get catalogHabitHigieneBucal;

  /// No description provided for @catalogHabitTomarSuplementos.
  ///
  /// In es, this message translates to:
  /// **'Tomar suplementos o medicación'**
  String get catalogHabitTomarSuplementos;

  /// No description provided for @catalogHabitHidratarPiel.
  ///
  /// In es, this message translates to:
  /// **'Hidratarse la piel'**
  String get catalogHabitHidratarPiel;

  /// No description provided for @catalogHabitDiarioEmocional.
  ///
  /// In es, this message translates to:
  /// **'Diario emocional'**
  String get catalogHabitDiarioEmocional;

  /// No description provided for @catalogHabitIdentificarEmociones.
  ///
  /// In es, this message translates to:
  /// **'Identificar mis emociones'**
  String get catalogHabitIdentificarEmociones;

  /// No description provided for @catalogHabitGestionarEstres.
  ///
  /// In es, this message translates to:
  /// **'Gestionar el estrés'**
  String get catalogHabitGestionarEstres;

  /// No description provided for @catalogHabitAutocompasion.
  ///
  /// In es, this message translates to:
  /// **'Practicar autocompasión'**
  String get catalogHabitAutocompasion;

  /// No description provided for @catalogHabitHablarSentimientos.
  ///
  /// In es, this message translates to:
  /// **'Expresar mis sentimientos'**
  String get catalogHabitHablarSentimientos;

  /// No description provided for @catalogHabitReducirPensamientosNegativos.
  ///
  /// In es, this message translates to:
  /// **'Reducir pensamientos negativos'**
  String get catalogHabitReducirPensamientosNegativos;

  /// No description provided for @catalogHabitPracticarPaciencia.
  ///
  /// In es, this message translates to:
  /// **'Practicar paciencia'**
  String get catalogHabitPracticarPaciencia;

  /// No description provided for @catalogHabitMomentoAlegria.
  ///
  /// In es, this message translates to:
  /// **'Hacer algo que me alegre'**
  String get catalogHabitMomentoAlegria;

  /// No description provided for @catalogHabitCelebrarLogro.
  ///
  /// In es, this message translates to:
  /// **'Celebrar un logro'**
  String get catalogHabitCelebrarLogro;

  /// No description provided for @catalogHabitNotaAnimo.
  ///
  /// In es, this message translates to:
  /// **'Nota de ánimo del día'**
  String get catalogHabitNotaAnimo;

  /// No description provided for @catalogHabitNotaAnimoTarget.
  ///
  /// In es, this message translates to:
  /// **'Ánimo: {target}/10'**
  String catalogHabitNotaAnimoTarget(String target);

  /// No description provided for @catalogHabitSinPantallasNoche.
  ///
  /// In es, this message translates to:
  /// **'Sin pantallas antes de dormir'**
  String get catalogHabitSinPantallasNoche;

  /// No description provided for @catalogHabitSinPantallasNocheTarget.
  ///
  /// In es, this message translates to:
  /// **'Sin pantallas {target} min antes de dormir'**
  String catalogHabitSinPantallasNocheTarget(String target);

  /// No description provided for @catalogHabitHablarSerQuerido.
  ///
  /// In es, this message translates to:
  /// **'Hablar con alguien querido'**
  String get catalogHabitHablarSerQuerido;

  /// No description provided for @catalogHabitEscucharActivamente.
  ///
  /// In es, this message translates to:
  /// **'Escuchar activamente'**
  String get catalogHabitEscucharActivamente;

  /// No description provided for @catalogHabitExpresarGratitud.
  ///
  /// In es, this message translates to:
  /// **'Expresar gratitud a alguien'**
  String get catalogHabitExpresarGratitud;

  /// No description provided for @catalogHabitAyudarAlguien.
  ///
  /// In es, this message translates to:
  /// **'Ayudar a alguien'**
  String get catalogHabitAyudarAlguien;

  /// No description provided for @catalogHabitMantenerContacto.
  ///
  /// In es, this message translates to:
  /// **'Mantener el contacto'**
  String get catalogHabitMantenerContacto;

  /// No description provided for @catalogHabitCompartirExperiencias.
  ///
  /// In es, this message translates to:
  /// **'Compartir una experiencia'**
  String get catalogHabitCompartirExperiencias;

  /// No description provided for @catalogHabitPracticarEmpatia.
  ///
  /// In es, this message translates to:
  /// **'Practicar empatía'**
  String get catalogHabitPracticarEmpatia;

  /// No description provided for @catalogHabitPlanSocial.
  ///
  /// In es, this message translates to:
  /// **'Quedar con alguien'**
  String get catalogHabitPlanSocial;

  /// No description provided for @catalogHabitDesconectarRedes.
  ///
  /// In es, this message translates to:
  /// **'Desconectarse de redes sociales'**
  String get catalogHabitDesconectarRedes;

  /// No description provided for @catalogHabitMensajeAnimo.
  ///
  /// In es, this message translates to:
  /// **'Enviar un mensaje de ánimo'**
  String get catalogHabitMensajeAnimo;

  /// No description provided for @catalogHabitLlamadaFamiliaAmigo.
  ///
  /// In es, this message translates to:
  /// **'Llamada con familia o amigo'**
  String get catalogHabitLlamadaFamiliaAmigo;

  /// No description provided for @catalogHabitPlanificarDia.
  ///
  /// In es, this message translates to:
  /// **'Planificar el día'**
  String get catalogHabitPlanificarDia;

  /// No description provided for @catalogHabitCumplirRutina.
  ///
  /// In es, this message translates to:
  /// **'Cumplir la rutina'**
  String get catalogHabitCumplirRutina;

  /// No description provided for @catalogHabitRevisarObjetivos.
  ///
  /// In es, this message translates to:
  /// **'Revisar objetivos'**
  String get catalogHabitRevisarObjetivos;

  /// No description provided for @catalogHabitEvitarProcrastinacion.
  ///
  /// In es, this message translates to:
  /// **'Vencer la procrastinación'**
  String get catalogHabitEvitarProcrastinacion;

  /// No description provided for @catalogHabitTareaDificil.
  ///
  /// In es, this message translates to:
  /// **'Hacer la tarea más difícil primero'**
  String get catalogHabitTareaDificil;

  /// No description provided for @catalogHabitPriorizarImportante.
  ///
  /// In es, this message translates to:
  /// **'Priorizar lo importante'**
  String get catalogHabitPriorizarImportante;

  /// No description provided for @catalogHabitDejarFumar.
  ///
  /// In es, this message translates to:
  /// **'Sin tabaco'**
  String get catalogHabitDejarFumar;

  /// No description provided for @catalogHabitSinRedesSociales.
  ///
  /// In es, this message translates to:
  /// **'Sin redes sociales'**
  String get catalogHabitSinRedesSociales;

  /// No description provided for @catalogHabitSinRedesSocialesTarget.
  ///
  /// In es, this message translates to:
  /// **'Sin redes sociales {target} horas'**
  String catalogHabitSinRedesSocialesTarget(String target);

  /// No description provided for @catalogHabitMadrugar.
  ///
  /// In es, this message translates to:
  /// **'Madrugar'**
  String get catalogHabitMadrugar;

  /// No description provided for @catalogHabitRevisarFinDia.
  ///
  /// In es, this message translates to:
  /// **'Revisar el día al terminar'**
  String get catalogHabitRevisarFinDia;

  /// No description provided for @catalogHabitApagarMovil.
  ///
  /// In es, this message translates to:
  /// **'Apagar el móvil a una hora fija'**
  String get catalogHabitApagarMovil;

  /// No description provided for @catalogHabitSinComprasImpulsivas.
  ///
  /// In es, this message translates to:
  /// **'Sin compras impulsivas'**
  String get catalogHabitSinComprasImpulsivas;

  /// No description provided for @catalogHabitPrepararRopa.
  ///
  /// In es, this message translates to:
  /// **'Preparar la ropa del día siguiente'**
  String get catalogHabitPrepararRopa;

  /// No description provided for @catalogHabitTrabajoProfundo.
  ///
  /// In es, this message translates to:
  /// **'Sesión de trabajo profundo'**
  String get catalogHabitTrabajoProfundo;

  /// No description provided for @catalogHabitTrabajoProfundoTarget.
  ///
  /// In es, this message translates to:
  /// **'Trabajo profundo {target} min'**
  String catalogHabitTrabajoProfundoTarget(String target);

  /// No description provided for @catalogHabitHabilidadLaboral.
  ///
  /// In es, this message translates to:
  /// **'Desarrollar habilidad laboral'**
  String get catalogHabitHabilidadLaboral;

  /// No description provided for @catalogHabitOrganizarTareas.
  ///
  /// In es, this message translates to:
  /// **'Organizar tareas del día'**
  String get catalogHabitOrganizarTareas;

  /// No description provided for @catalogHabitRevisarRendimiento.
  ///
  /// In es, this message translates to:
  /// **'Revisar rendimiento'**
  String get catalogHabitRevisarRendimiento;

  /// No description provided for @catalogHabitNetworking.
  ///
  /// In es, this message translates to:
  /// **'Networking'**
  String get catalogHabitNetworking;

  /// No description provided for @catalogHabitFormacionProfesional.
  ///
  /// In es, this message translates to:
  /// **'Formación profesional'**
  String get catalogHabitFormacionProfesional;

  /// No description provided for @catalogHabitFormacionProfesionalTarget.
  ///
  /// In es, this message translates to:
  /// **'Formación {target} horas'**
  String catalogHabitFormacionProfesionalTarget(String target);

  /// No description provided for @catalogHabitResponderEmails.
  ///
  /// In es, this message translates to:
  /// **'Bandeja de entrada a cero'**
  String get catalogHabitResponderEmails;

  /// No description provided for @catalogHabitProyectoPersonal.
  ///
  /// In es, this message translates to:
  /// **'Avanzar en proyecto personal'**
  String get catalogHabitProyectoPersonal;

  /// No description provided for @catalogHabitLeerSector.
  ///
  /// In es, this message translates to:
  /// **'Leer sobre mi sector'**
  String get catalogHabitLeerSector;

  /// No description provided for @catalogHabitPomodoro.
  ///
  /// In es, this message translates to:
  /// **'Bloque Pomodoro completado'**
  String get catalogHabitPomodoro;

  /// No description provided for @catalogHabitPomodoroTarget.
  ///
  /// In es, this message translates to:
  /// **'{target} pomodoros'**
  String catalogHabitPomodoroTarget(String target);

  /// No description provided for @catalogHabitTrucoNuevo.
  ///
  /// In es, this message translates to:
  /// **'Aprender un atajo o truco nuevo'**
  String get catalogHabitTrucoNuevo;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageSectionTitle;

  /// No description provided for @settingsLanguageOptionSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get settingsLanguageOptionSpanish;

  /// No description provided for @settingsLanguageOptionEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get settingsLanguageOptionEnglish;

  /// No description provided for @settingsAccountSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsAccountSectionTitle;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Abre las notificaciones y recordatorios de Rutio'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsLogOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogOut;

  /// No description provided for @settingsLogOutTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get settingsLogOutTitle;

  /// No description provided for @settingsLogOutMessage.
  ///
  /// In es, this message translates to:
  /// **'Podrás volver a entrar con tu email y contraseña cuando quieras.'**
  String get settingsLogOutMessage;

  /// No description provided for @settingsLogOutConfirm.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogOutConfirm;

  /// No description provided for @settingsLogOutError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cerrar sesión. Inténtalo de nuevo.'**
  String get settingsLogOutError;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsLogoutConfirmationBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres cerrar sesión? Podrás volver a entrar cuando quieras.'**
  String get settingsLogoutConfirmationBody;

  /// No description provided for @settingsLogoutConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogoutConfirmAction;

  /// No description provided for @settingsLogoutError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cerrar sesión. Inténtalo de nuevo.'**
  String get settingsLogoutError;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountHelperText.
  ///
  /// In es, this message translates to:
  /// **'Elimina tu cuenta y los datos asociados de forma permanente.'**
  String get settingsDeleteAccountHelperText;

  /// No description provided for @settingsDeleteAccountConfirmationTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar cuenta?'**
  String get settingsDeleteAccountConfirmationTitle;

  /// No description provided for @settingsDeleteAccountConfirmationBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción eliminará tu cuenta y tus datos asociados. No se puede deshacer.'**
  String get settingsDeleteAccountConfirmationBody;

  /// No description provided for @settingsDeleteAccountConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccountConfirmAction;

  /// No description provided for @settingsDeleteAccountMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta acción eliminará tu cuenta y tus datos asociados. No se puede deshacer.'**
  String get settingsDeleteAccountMessage;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccountConfirm;

  /// No description provided for @settingsDeleteAccountTypeToConfirm.
  ///
  /// In es, this message translates to:
  /// **'Escribe ELIMINAR para confirmar.'**
  String get settingsDeleteAccountTypeToConfirm;

  /// No description provided for @settingsDeleteAccountError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido eliminar la cuenta. Inténtalo de nuevo.'**
  String get settingsDeleteAccountError;

  /// No description provided for @settingsDeleteAccountDeleting.
  ///
  /// In es, this message translates to:
  /// **'Eliminando cuenta...'**
  String get settingsDeleteAccountDeleting;

  /// No description provided for @settingsDeleteAccountSuccess.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta se ha eliminado correctamente.'**
  String get settingsDeleteAccountSuccess;

  /// No description provided for @personalizedNotificationsSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones de Rutio'**
  String get personalizedNotificationsSectionTitle;

  /// No description provided for @personalizedNotificationsSectionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pequeños recordatorios y mensajes adaptados a tu progreso.'**
  String get personalizedNotificationsSectionSubtitle;

  /// No description provided for @personalizedNotificationsEnableTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar notificaciones de Rutio'**
  String get personalizedNotificationsEnableTitle;

  /// No description provided for @personalizedNotificationsEnableSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Separa los mensajes de Rutio de los recordatorios de hábitos.'**
  String get personalizedNotificationsEnableSubtitle;

  /// No description provided for @personalizedNotificationsIntensityLabel.
  ///
  /// In es, this message translates to:
  /// **'Intensidad'**
  String get personalizedNotificationsIntensityLabel;

  /// No description provided for @personalizedNotificationsIntensitySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige con qué frecuencia aparece Rutio.'**
  String get personalizedNotificationsIntensitySubtitle;

  /// No description provided for @personalizedNotificationsIntensitySoft.
  ///
  /// In es, this message translates to:
  /// **'Suave'**
  String get personalizedNotificationsIntensitySoft;

  /// No description provided for @personalizedNotificationsIntensityBalanced.
  ///
  /// In es, this message translates to:
  /// **'Equilibrado'**
  String get personalizedNotificationsIntensityBalanced;

  /// No description provided for @personalizedNotificationsIntensityActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get personalizedNotificationsIntensityActive;

  /// No description provided for @personalizedNotificationsReferenceTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hora de referencia'**
  String get personalizedNotificationsReferenceTimeTitle;

  /// No description provided for @personalizedNotificationsReferenceTimeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se usa como base para los mensajes personalizados.'**
  String get personalizedNotificationsReferenceTimeSubtitle;

  /// No description provided for @personalizedNotificationsHabitReminderNote.
  ///
  /// In es, this message translates to:
  /// **'Los recordatorios de hábitos siguen configurándose en su propia pantalla.'**
  String get personalizedNotificationsHabitReminderNote;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get profileSettingsTitle;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma, privacidad y más'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil'**
  String get profileDefaultName;

  /// No description provided for @profileDefaultSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso, ajustes y cuenta'**
  String get profileDefaultSubtitle;

  /// No description provided for @profileNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get profileNotificationsTitle;

  /// No description provided for @profileEnableNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar notificaciones'**
  String get profileEnableNotificationsTitle;

  /// No description provided for @profileEnableNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios, cierre del día y rachas'**
  String get profileEnableNotificationsSubtitle;

  /// No description provided for @profileNotificationSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de notificaciones'**
  String get profileNotificationSettingsTitle;

  /// No description provided for @profileNotificationCategoriesActive.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total} categorías activas'**
  String profileNotificationCategoriesActive(int count, int total);

  /// No description provided for @profileAccountSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta y ajustes'**
  String get profileAccountSectionTitle;

  /// No description provided for @profileThemeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get profileThemeTitle;

  /// No description provided for @profileThemeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Claro / Oscuro / Automático'**
  String get profileThemeSubtitle;

  /// No description provided for @profileThemeTodo.
  ///
  /// In es, this message translates to:
  /// **'Tema (TODO)'**
  String get profileThemeTodo;

  /// No description provided for @profileHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get profileHelpTitle;

  /// No description provided for @profileHelpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'FAQ y soporte'**
  String get profileHelpSubtitle;

  /// No description provided for @profileHelpTodo.
  ///
  /// In es, this message translates to:
  /// **'Ayuda (TODO)'**
  String get profileHelpTodo;

  /// No description provided for @profileAboutTitle.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get profileAboutTitle;

  /// No description provided for @profileAboutSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Versión y legal'**
  String get profileAboutSubtitle;

  /// No description provided for @profileAboutTodo.
  ///
  /// In es, this message translates to:
  /// **'Acerca de (TODO)'**
  String get profileAboutTodo;

  /// No description provided for @profileDangerSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Zona peligrosa'**
  String get profileDangerSectionTitle;

  /// No description provided for @profileManageDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar datos'**
  String get profileManageDataTitle;

  /// No description provided for @profileManageDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar o borrar tu información'**
  String get profileManageDataSubtitle;

  /// No description provided for @profileManageDataTodo.
  ///
  /// In es, this message translates to:
  /// **'Gestionar datos (TODO)'**
  String get profileManageDataTodo;

  /// No description provided for @profileLogoutTodo.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión (TODO)'**
  String get profileLogoutTodo;

  /// No description provided for @profileNotificationPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Permiso de notificaciones no concedido.'**
  String get profileNotificationPermissionDenied;

  /// No description provided for @profileEditButton.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get profileEditButton;

  /// No description provided for @profileDangerZoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Zona de peligro'**
  String get profileDangerZoneTitle;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se cerrará tu sesión en este dispositivo'**
  String get profileLogoutSubtitle;

  /// No description provided for @profileDeleteDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar datos'**
  String get profileDeleteDataTitle;

  /// No description provided for @profileDeleteDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elimina todos tus datos y progreso (irreversible)'**
  String get profileDeleteDataSubtitle;

  /// No description provided for @profileFamiliesProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso por familias'**
  String get profileFamiliesProgressTitle;

  /// No description provided for @profileFamilyLevelShort.
  ///
  /// In es, this message translates to:
  /// **'Lvl {level}'**
  String profileFamilyLevelShort(int level);

  /// No description provided for @profileFamilyLevelLabel.
  ///
  /// In es, this message translates to:
  /// **'Nivel {level}'**
  String profileFamilyLevelLabel(int level);

  /// No description provided for @profileNotificationsPhaseOneTitle.
  ///
  /// In es, this message translates to:
  /// **'Fase 1'**
  String get profileNotificationsPhaseOneTitle;

  /// No description provided for @notificationsRemindersSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get notificationsRemindersSectionTitle;

  /// No description provided for @profileNotificationHabitRemindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de hábitos'**
  String get profileNotificationHabitRemindersTitle;

  /// No description provided for @profileNotificationHabitRemindersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Respeta la hora configurada en cada hábito'**
  String get profileNotificationHabitRemindersSubtitle;

  /// No description provided for @profileNotificationDayClosureTitle.
  ///
  /// In es, this message translates to:
  /// **'Cierre del día'**
  String get profileNotificationDayClosureTitle;

  /// No description provided for @profileNotificationDayClosureSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo si aún quedan hábitos pendientes hoy'**
  String get profileNotificationDayClosureSubtitle;

  /// No description provided for @profileNotificationDayClosureTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hora de cierre del día'**
  String get profileNotificationDayClosureTimeTitle;

  /// No description provided for @profileNotificationDayClosureTimeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Momento para recordar lo que aún queda pendiente'**
  String get profileNotificationDayClosureTimeSubtitle;

  /// No description provided for @profileNotificationStreakRiskTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha en riesgo'**
  String get profileNotificationStreakRiskTitle;

  /// No description provided for @profileNotificationStreakRiskSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Avisa cuando aún puedes salvar una racha relevante'**
  String get profileNotificationStreakRiskSubtitle;

  /// No description provided for @profileNotificationStreakCelebrationTitle.
  ///
  /// In es, this message translates to:
  /// **'Celebraciones de racha'**
  String get profileNotificationStreakCelebrationTitle;

  /// No description provided for @profileNotificationStreakCelebrationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Celebra hitos básicos como 1, 3, 7, 14 y 30 días'**
  String get profileNotificationStreakCelebrationSubtitle;

  /// No description provided for @profileNotificationInactivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Reactivación por inactividad'**
  String get profileNotificationInactivityTitle;

  /// No description provided for @profileNotificationInactivitySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un recordatorio amable tras 3 días sin abrir la app'**
  String get profileNotificationInactivitySubtitle;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Activa tus recordatorios'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Rutio puede avisarte en el momento adecuado para ayudarte a mantener tus hábitos sin presión.'**
  String get notificationPermissionBody;

  /// No description provided for @notificationPermissionPrimaryAction.
  ///
  /// In es, this message translates to:
  /// **'Activar recordatorios'**
  String get notificationPermissionPrimaryAction;

  /// No description provided for @notificationPermissionSecondaryAction.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get notificationPermissionSecondaryAction;

  /// No description provided for @notificationPermissionDeniedTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones desactivadas'**
  String get notificationPermissionDeniedTitle;

  /// No description provided for @notificationPermissionDeniedBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes activarlas más adelante desde los ajustes de tu dispositivo.'**
  String get notificationPermissionDeniedBody;

  /// No description provided for @notificationPermissionOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get notificationPermissionOpenSettings;

  /// No description provided for @feedbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackIntro.
  ///
  /// In es, this message translates to:
  /// **'Tu experiencia nos ayuda a mejorar Rutio. Puedes compartir una idea, avisarnos de un problema o consultar el estado de tus envíos.'**
  String get feedbackIntro;

  /// No description provided for @feedbackSendAction.
  ///
  /// In es, this message translates to:
  /// **'Enviar feedback'**
  String get feedbackSendAction;

  /// No description provided for @feedbackSendActionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Comparte una idea o avísanos de un problema.'**
  String get feedbackSendActionSubtitle;

  /// No description provided for @feedbackMineAction.
  ///
  /// In es, this message translates to:
  /// **'Mis envíos'**
  String get feedbackMineAction;

  /// No description provided for @feedbackMineActionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta el estado de lo que ya has enviado.'**
  String get feedbackMineActionSubtitle;

  /// No description provided for @feedbackNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Enviar feedback'**
  String get feedbackNewTitle;

  /// No description provided for @feedbackNewIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría, describe lo ocurrido y deja listo el envío.'**
  String get feedbackNewIntro;

  /// No description provided for @feedbackCategorySectionTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tipo de feedback quieres enviar?'**
  String get feedbackCategorySectionTitle;

  /// No description provided for @feedbackCategoryBugTitle.
  ///
  /// In es, this message translates to:
  /// **'He encontrado un problema'**
  String get feedbackCategoryBugTitle;

  /// No description provided for @feedbackCategoryBugHelp.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué ocurrió, qué esperabas que pasara y, si puedes, cómo reproducirlo.'**
  String get feedbackCategoryBugHelp;

  /// No description provided for @feedbackCategorySuggestionTitle.
  ///
  /// In es, this message translates to:
  /// **'Tengo una sugerencia'**
  String get feedbackCategorySuggestionTitle;

  /// No description provided for @feedbackCategorySuggestionHelp.
  ///
  /// In es, this message translates to:
  /// **'Explícanos tu idea y qué necesidad te ayudaría a resolver.'**
  String get feedbackCategorySuggestionHelp;

  /// No description provided for @feedbackCategoryImprovementTitle.
  ///
  /// In es, this message translates to:
  /// **'Quiero mejorar algo existente'**
  String get feedbackCategoryImprovementTitle;

  /// No description provided for @feedbackCategoryImprovementHelp.
  ///
  /// In es, this message translates to:
  /// **'Dinos qué parte de Rutio cambiarías y cómo te gustaría que funcionara.'**
  String get feedbackCategoryImprovementHelp;

  /// No description provided for @feedbackCategoryOtherTitle.
  ///
  /// In es, this message translates to:
  /// **'Otro comentario'**
  String get feedbackCategoryOtherTitle;

  /// No description provided for @feedbackCategoryOtherHelp.
  ///
  /// In es, this message translates to:
  /// **'Comparte cualquier comentario que pueda ayudarnos a mejorar Rutio.'**
  String get feedbackCategoryOtherHelp;

  /// No description provided for @feedbackCategoryGeneralHelp.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría para ver una guía más concreta sobre lo que puedes contarnos.'**
  String get feedbackCategoryGeneralHelp;

  /// No description provided for @feedbackDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Describe tu feedback'**
  String get feedbackDescriptionLabel;

  /// No description provided for @feedbackDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué pasó, qué esperabas y cualquier detalle útil.'**
  String get feedbackDescriptionHint;

  /// No description provided for @feedbackDescriptionRequirements.
  ///
  /// In es, this message translates to:
  /// **'Mín. 20 y máx. 5000 caracteres tras recortar espacios.'**
  String get feedbackDescriptionRequirements;

  /// No description provided for @feedbackDescriptionCounter.
  ///
  /// In es, this message translates to:
  /// **'{current}/{max}'**
  String feedbackDescriptionCounter(int current, int max);

  /// No description provided for @feedbackScreenshotTitle.
  ///
  /// In es, this message translates to:
  /// **'Captura de pantalla (opcional)'**
  String get feedbackScreenshotTitle;

  /// No description provided for @feedbackScreenshotPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar imagen'**
  String get feedbackScreenshotPlaceholder;

  /// No description provided for @feedbackScreenshotSelectedLabel.
  ///
  /// In es, this message translates to:
  /// **'Captura lista'**
  String get feedbackScreenshotSelectedLabel;

  /// No description provided for @feedbackScreenshotSelectAction.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar imagen'**
  String get feedbackScreenshotSelectAction;

  /// No description provided for @feedbackScreenshotReplaceAction.
  ///
  /// In es, this message translates to:
  /// **'Sustituir'**
  String get feedbackScreenshotReplaceAction;

  /// No description provided for @feedbackScreenshotRemoveAction.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get feedbackScreenshotRemoveAction;

  /// No description provided for @feedbackScreenshotPreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando captura...'**
  String get feedbackScreenshotPreparing;

  /// No description provided for @feedbackScreenshotErrorUnsupported.
  ///
  /// In es, this message translates to:
  /// **'No se admite ese tipo de imagen. Prueba con otra captura.'**
  String get feedbackScreenshotErrorUnsupported;

  /// No description provided for @feedbackScreenshotErrorNotProcessable.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido preparar esta imagen. Prueba con otra.'**
  String get feedbackScreenshotErrorNotProcessable;

  /// No description provided for @feedbackScreenshotErrorCompressionFailed.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido comprimir esta imagen. Prueba con otra.'**
  String get feedbackScreenshotErrorCompressionFailed;

  /// No description provided for @feedbackScreenshotErrorTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La imagen sigue siendo demasiado grande. Prueba con otra más ligera.'**
  String get feedbackScreenshotErrorTooLarge;

  /// No description provided for @feedbackScreenshotErrorUploadFailed.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido subir la captura. Comprueba tu conexión e inténtalo de nuevo.'**
  String get feedbackScreenshotErrorUploadFailed;

  /// No description provided for @feedbackScreenshotErrorCleanupFailed.
  ///
  /// In es, this message translates to:
  /// **'Ha habido un problema limpiando una captura temporal. Puedes volver a intentarlo.'**
  String get feedbackScreenshotErrorCleanupFailed;

  /// No description provided for @feedbackContactTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Podemos contactar contigo?'**
  String get feedbackContactTitle;

  /// No description provided for @feedbackContactDescription.
  ///
  /// In es, this message translates to:
  /// **'Si activas esta opción, podremos responderte si lo necesitamos.'**
  String get feedbackContactDescription;

  /// No description provided for @feedbackContactSwitchLabel.
  ///
  /// In es, this message translates to:
  /// **'Sí, podéis contactarme'**
  String get feedbackContactSwitchLabel;

  /// No description provided for @feedbackTechnicalNote.
  ///
  /// In es, this message translates to:
  /// **'Incluiremos información técnica básica de la app y del dispositivo para ayudarnos a revisar tu comentario.'**
  String get feedbackTechnicalNote;

  /// No description provided for @feedbackSubmitAction.
  ///
  /// In es, this message translates to:
  /// **'Enviar feedback'**
  String get feedbackSubmitAction;

  /// No description provided for @feedbackMineTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis envíos'**
  String get feedbackMineTitle;

  /// No description provided for @feedbackMineHeading.
  ///
  /// In es, this message translates to:
  /// **'Tus envíos'**
  String get feedbackMineHeading;

  /// No description provided for @feedbackMineIntro.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás el historial real de feedback que has enviado.'**
  String get feedbackMineIntro;

  /// No description provided for @feedbackMineEmptyState.
  ///
  /// In es, this message translates to:
  /// **'Todavía no has enviado feedback.'**
  String get feedbackMineEmptyState;

  /// No description provided for @feedbackMineFilteredEmptyState.
  ///
  /// In es, this message translates to:
  /// **'No hay envíos que coincidan con este filtro.'**
  String get feedbackMineFilteredEmptyState;

  /// No description provided for @feedbackMineLoadingState.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus envíos...'**
  String get feedbackMineLoadingState;

  /// No description provided for @feedbackMineErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar tus envíos'**
  String get feedbackMineErrorTitle;

  /// No description provided for @feedbackMineErrorSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión no está disponible. Vuelve a iniciar sesión.'**
  String get feedbackMineErrorSessionExpired;

  /// No description provided for @feedbackMineErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido conectar con el servidor. Comprueba tu conexión e inténtalo de nuevo.'**
  String get feedbackMineErrorNetwork;

  /// No description provided for @feedbackMineErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar tus envíos ahora mismo. Inténtalo de nuevo.'**
  String get feedbackMineErrorGeneric;

  /// No description provided for @feedbackMineRetryAction.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get feedbackMineRetryAction;

  /// No description provided for @feedbackFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get feedbackFilterAll;

  /// No description provided for @feedbackFilterSubmitted.
  ///
  /// In es, this message translates to:
  /// **'Enviados'**
  String get feedbackFilterSubmitted;

  /// No description provided for @feedbackFilterInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get feedbackFilterInReview;

  /// No description provided for @feedbackFilterClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrados'**
  String get feedbackFilterClosed;

  /// No description provided for @feedbackResponseAvailableBadge.
  ///
  /// In es, this message translates to:
  /// **'Respuesta disponible'**
  String get feedbackResponseAvailableBadge;

  /// No description provided for @feedbackStatusSubmitted.
  ///
  /// In es, this message translates to:
  /// **'Enviado'**
  String get feedbackStatusSubmitted;

  /// No description provided for @feedbackStatusInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get feedbackStatusInReview;

  /// No description provided for @feedbackStatusResolved.
  ///
  /// In es, this message translates to:
  /// **'Resuelto'**
  String get feedbackStatusResolved;

  /// No description provided for @feedbackStatusDismissed.
  ///
  /// In es, this message translates to:
  /// **'Descartado'**
  String get feedbackStatusDismissed;

  /// No description provided for @feedbackProgressSubmitted.
  ///
  /// In es, this message translates to:
  /// **'Enviado'**
  String get feedbackProgressSubmitted;

  /// No description provided for @feedbackProgressSubmittedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Entrada recibida en el flujo local.'**
  String get feedbackProgressSubmittedSubtitle;

  /// No description provided for @feedbackProgressInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get feedbackProgressInReview;

  /// No description provided for @feedbackProgressInReviewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'El equipo todavía no ha cerrado una decisión.'**
  String get feedbackProgressInReviewSubtitle;

  /// No description provided for @feedbackProgressTerminalLabel.
  ///
  /// In es, this message translates to:
  /// **'Resuelto / Descartado'**
  String get feedbackProgressTerminalLabel;

  /// No description provided for @feedbackProgressTerminalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Resultado final del feedback.'**
  String get feedbackProgressTerminalSubtitle;

  /// No description provided for @feedbackSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias!'**
  String get feedbackSuccessTitle;

  /// No description provided for @feedbackSuccessBody.
  ///
  /// In es, this message translates to:
  /// **'Hemos recibido tu feedback correctamente.'**
  String get feedbackSuccessBody;

  /// No description provided for @feedbackSuccessSummaryLabel.
  ///
  /// In es, this message translates to:
  /// **'Resumen del envío'**
  String get feedbackSuccessSummaryLabel;

  /// No description provided for @feedbackSuccessCanEditDelete.
  ///
  /// In es, this message translates to:
  /// **'Todavía puedes editar o eliminar este feedback hasta que el equipo empiece a revisarlo.'**
  String get feedbackSuccessCanEditDelete;

  /// No description provided for @feedbackSuccessProgressLabel.
  ///
  /// In es, this message translates to:
  /// **'Proceso'**
  String get feedbackSuccessProgressLabel;

  /// No description provided for @feedbackSuccessMineAction.
  ///
  /// In es, this message translates to:
  /// **'Ver mis envíos'**
  String get feedbackSuccessMineAction;

  /// No description provided for @feedbackSuccessHomeAction.
  ///
  /// In es, this message translates to:
  /// **'Volver a Feedback'**
  String get feedbackSuccessHomeAction;

  /// No description provided for @feedbackDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle'**
  String get feedbackDetailTitle;

  /// No description provided for @feedbackDetailLoadingState.
  ///
  /// In es, this message translates to:
  /// **'Cargando feedback...'**
  String get feedbackDetailLoadingState;

  /// No description provided for @feedbackDetailErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar el feedback'**
  String get feedbackDetailErrorTitle;

  /// No description provided for @feedbackDetailLoadErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar este feedback. Inténtalo de nuevo.'**
  String get feedbackDetailLoadErrorMessage;

  /// No description provided for @feedbackDetailNotAvailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Feedback no disponible'**
  String get feedbackDetailNotAvailableTitle;

  /// No description provided for @feedbackDetailNotAvailableMessage.
  ///
  /// In es, this message translates to:
  /// **'Este feedback ya no está disponible.'**
  String get feedbackDetailNotAvailableMessage;

  /// No description provided for @feedbackDetailRetryAction.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get feedbackDetailRetryAction;

  /// No description provided for @feedbackDetailDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get feedbackDetailDescriptionLabel;

  /// No description provided for @feedbackDetailSentDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de envío'**
  String get feedbackDetailSentDateLabel;

  /// No description provided for @feedbackDetailReviewDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de revisión'**
  String get feedbackDetailReviewDateLabel;

  /// No description provided for @feedbackDetailClosedDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de cierre'**
  String get feedbackDetailClosedDateLabel;

  /// No description provided for @feedbackDetailScreenshotLabel.
  ///
  /// In es, this message translates to:
  /// **'Captura adjunta'**
  String get feedbackDetailScreenshotLabel;

  /// No description provided for @feedbackDetailScreenshotLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando captura...'**
  String get feedbackDetailScreenshotLoading;

  /// No description provided for @feedbackDetailScreenshotError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar la captura.'**
  String get feedbackDetailScreenshotError;

  /// No description provided for @feedbackDetailScreenshotPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Captura disponible'**
  String get feedbackDetailScreenshotPlaceholder;

  /// No description provided for @feedbackDetailActionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Acciones disponibles'**
  String get feedbackDetailActionsLabel;

  /// No description provided for @feedbackEditAction.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get feedbackEditAction;

  /// No description provided for @feedbackDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar feedback'**
  String get feedbackDeleteAction;

  /// No description provided for @feedbackEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar feedback'**
  String get feedbackEditTitle;

  /// No description provided for @feedbackEditIntro.
  ///
  /// In es, this message translates to:
  /// **'Puedes ajustar la descripción, la captura y si quieres que podamos contactarte.'**
  String get feedbackEditIntro;

  /// No description provided for @feedbackEditCategoryLockedNote.
  ///
  /// In es, this message translates to:
  /// **'La categoría no se puede cambiar en esta fase.'**
  String get feedbackEditCategoryLockedNote;

  /// No description provided for @feedbackEditNoScreenshot.
  ///
  /// In es, this message translates to:
  /// **'No hay captura adjunta. Puedes añadir una nueva si lo necesitas.'**
  String get feedbackEditNoScreenshot;

  /// No description provided for @feedbackEditSaveAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get feedbackEditSaveAction;

  /// No description provided for @feedbackEditErrorNoLongerEditable.
  ///
  /// In es, this message translates to:
  /// **'Este feedback ya está en revisión y no puede modificarse.'**
  String get feedbackEditErrorNoLongerEditable;

  /// No description provided for @feedbackEditSaveErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido guardar los cambios. Inténtalo de nuevo.'**
  String get feedbackEditSaveErrorGeneric;

  /// No description provided for @feedbackDeleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este feedback?'**
  String get feedbackDeleteConfirmTitle;

  /// No description provided for @feedbackDeleteConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get feedbackDeleteConfirmMessage;

  /// No description provided for @feedbackDeleteConfirmCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get feedbackDeleteConfirmCancel;

  /// No description provided for @feedbackDeleteConfirmDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get feedbackDeleteConfirmDelete;

  /// No description provided for @feedbackResponseTitle.
  ///
  /// In es, this message translates to:
  /// **'Respuesta del equipo'**
  String get feedbackResponseTitle;

  /// No description provided for @feedbackResponseEmpty.
  ///
  /// In es, this message translates to:
  /// **'Nuestro equipo todavía no ha añadido una respuesta.'**
  String get feedbackResponseEmpty;

  /// No description provided for @feedbackExitConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres salir?'**
  String get feedbackExitConfirmTitle;

  /// No description provided for @feedbackExitConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Perderás el feedback que todavía no has enviado.'**
  String get feedbackExitConfirmMessage;

  /// No description provided for @feedbackExitConfirmStay.
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get feedbackExitConfirmStay;

  /// No description provided for @feedbackExitConfirmLeave.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get feedbackExitConfirmLeave;

  /// No description provided for @feedbackPlaceholderBody.
  ///
  /// In es, this message translates to:
  /// **'Esta sección del Centro de Feedback llegará en una fase posterior.'**
  String get feedbackPlaceholderBody;

  /// No description provided for @editProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfileTitle;

  /// No description provided for @editProfileSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get editProfileSave;

  /// No description provided for @editProfileSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get editProfileSaveChanges;

  /// No description provided for @editProfileSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get editProfileSaving;

  /// No description provided for @editProfileTakePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get editProfileTakePhoto;

  /// No description provided for @editProfileGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get editProfileGallery;

  /// No description provided for @editProfileRemovePhoto.
  ///
  /// In es, this message translates to:
  /// **'Eliminar foto'**
  String get editProfileRemovePhoto;

  /// No description provided for @editProfilePersonalInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Información personal'**
  String get editProfilePersonalInfoTitle;

  /// No description provided for @editProfileGoalSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu objetivo'**
  String get editProfileGoalSectionTitle;

  /// No description provided for @editProfileImageSelectionError.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar imagen: {error}'**
  String editProfileImageSelectionError(String error);

  /// No description provided for @editProfileSaveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado correctamente'**
  String get editProfileSaveSuccess;

  /// No description provided for @editProfileSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String editProfileSaveError(String error);

  /// No description provided for @editProfileDiscardChangesTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar cambios?'**
  String get editProfileDiscardChangesTitle;

  /// No description provided for @editProfileDiscardChangesBody.
  ///
  /// In es, this message translates to:
  /// **'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?'**
  String get editProfileDiscardChangesBody;

  /// No description provided for @editProfileDiscardChangesAction.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get editProfileDiscardChangesAction;

  /// No description provided for @editProfileCropTitle.
  ///
  /// In es, this message translates to:
  /// **'Recortar'**
  String get editProfileCropTitle;

  /// No description provided for @editProfileStatLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get editProfileStatLevel;

  /// No description provided for @editProfileStatXp.
  ///
  /// In es, this message translates to:
  /// **'XP'**
  String get editProfileStatXp;

  /// No description provided for @editProfileStatCoins.
  ///
  /// In es, this message translates to:
  /// **'Monedas'**
  String get editProfileStatCoins;

  /// No description provided for @editProfileNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get editProfileNameLabel;

  /// No description provided for @editProfileNameHint.
  ///
  /// In es, this message translates to:
  /// **'Cómo quieres que te vean'**
  String get editProfileNameHint;

  /// No description provided for @editProfileNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio'**
  String get editProfileNameRequired;

  /// No description provided for @editProfileNameMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 2 caracteres'**
  String get editProfileNameMinLength;

  /// No description provided for @editProfileBioLabel.
  ///
  /// In es, this message translates to:
  /// **'Bio'**
  String get editProfileBioLabel;

  /// No description provided for @editProfileBioHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos un poco sobre ti...'**
  String get editProfileBioHint;

  /// No description provided for @editProfileGoalLabel.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get editProfileGoalLabel;

  /// No description provided for @editProfileGoalHint.
  ///
  /// In es, this message translates to:
  /// **'Qué quieres conseguir con Rutio'**
  String get editProfileGoalHint;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto de perfil'**
  String get editProfileChangePhoto;

  /// No description provided for @editProfileAddPhoto.
  ///
  /// In es, this message translates to:
  /// **'Añadir foto de perfil'**
  String get editProfileAddPhoto;

  /// No description provided for @archivedHabitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábitos archivados'**
  String get archivedHabitsTitle;

  /// No description provided for @archivedHabitsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes hábitos archivados.'**
  String get archivedHabitsEmpty;

  /// No description provided for @archivedHabitsFamilyLabel.
  ///
  /// In es, this message translates to:
  /// **'Familia: {family}'**
  String archivedHabitsFamilyLabel(String family);

  /// No description provided for @archivedHabitsRestoreTooltip.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get archivedHabitsRestoreTooltip;

  /// No description provided for @archivedHabitsDeleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get archivedHabitsDeleteTooltip;

  /// No description provided for @archivedHabitsDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar hábito'**
  String get archivedHabitsDeleteTitle;

  /// No description provided for @archivedHabitsDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar este hábito?\n\nSe eliminará también su historial.'**
  String get archivedHabitsDeleteBody;

  /// No description provided for @habitDetailFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábito'**
  String get habitDetailFallbackTitle;

  /// No description provided for @habitDetailSaved.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados'**
  String get habitDetailSaved;

  /// No description provided for @habitDetailDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar hábito'**
  String get habitDetailDeleteTitle;

  /// No description provided for @habitDetailDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrará el hábito y su historial. Esta acción no se puede deshacer.'**
  String get habitDetailDeleteBody;

  /// No description provided for @habitDetailArchiveAction.
  ///
  /// In es, this message translates to:
  /// **'Archivar hábito'**
  String get habitDetailArchiveAction;

  /// No description provided for @habitDetailDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar hábito'**
  String get habitDetailDeleteAction;

  /// No description provided for @habitDetailMoreOptionsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get habitDetailMoreOptionsTooltip;

  /// No description provided for @habitDetailEditTab.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get habitDetailEditTab;

  /// No description provided for @habitDetailStatsTab.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get habitDetailStatsTab;

  /// No description provided for @archiveHabitTileTitle.
  ///
  /// In es, this message translates to:
  /// **'Archivar hábito'**
  String get archiveHabitTileTitle;

  /// No description provided for @archiveHabitTileArchivedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Este hábito está archivado (no aparecerá en la lista principal).'**
  String get archiveHabitTileArchivedSubtitle;

  /// No description provided for @archiveHabitTileActiveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Oculta este hábito de la lista principal sin borrarlo.'**
  String get archiveHabitTileActiveSubtitle;

  /// No description provided for @archiveHabitTileConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Archivar hábito'**
  String get archiveHabitTileConfirmTitle;

  /// No description provided for @archiveHabitTileConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres archivar este hábito? Podrás recuperarlo más adelante.'**
  String get archiveHabitTileConfirmBody;

  /// No description provided for @archiveHabitTileConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get archiveHabitTileConfirmAction;

  /// No description provided for @habitStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get habitStatsTitle;

  /// No description provided for @habitStatsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay hábitos para mostrar.'**
  String get habitStatsEmpty;

  /// No description provided for @statisticsV3Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso en Rutio'**
  String get statisticsV3Subtitle;

  /// No description provided for @statisticsV3DailyActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad diaria'**
  String get statisticsV3DailyActivityTitle;

  /// No description provided for @statisticsV3DailyActivitySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ritmo semanal de completado'**
  String get statisticsV3DailyActivitySubtitle;

  /// No description provided for @statisticsV3SummaryCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen general'**
  String get statisticsV3SummaryCardTitle;

  /// No description provided for @statisticsV3SummaryCompletedLabel.
  ///
  /// In es, this message translates to:
  /// **'hábitos completados'**
  String get statisticsV3SummaryCompletedLabel;

  /// No description provided for @statisticsV3SummaryXpLabel.
  ///
  /// In es, this message translates to:
  /// **'XP'**
  String get statisticsV3SummaryXpLabel;

  /// No description provided for @statisticsV3SummaryAmberLabel.
  ///
  /// In es, this message translates to:
  /// **'Ámbar'**
  String get statisticsV3SummaryAmberLabel;

  /// No description provided for @statisticsV3RewardBreakdownTitle.
  ///
  /// In es, this message translates to:
  /// **'Desglose de recompensas'**
  String get statisticsV3RewardBreakdownTitle;

  /// No description provided for @statisticsV3RewardBreakdownSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recompensas obtenidas en este periodo.'**
  String get statisticsV3RewardBreakdownSubtitle;

  /// No description provided for @statisticsV3RewardBreakdownHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get statisticsV3RewardBreakdownHabits;

  /// No description provided for @statisticsV3RewardBreakdownDiary.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get statisticsV3RewardBreakdownDiary;

  /// No description provided for @statisticsV3RewardBreakdownAchievements.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get statisticsV3RewardBreakdownAchievements;

  /// No description provided for @statisticsV3RewardBreakdownLevelUps.
  ///
  /// In es, this message translates to:
  /// **'Subidas de nivel'**
  String get statisticsV3RewardBreakdownLevelUps;

  /// No description provided for @statisticsV3RewardBreakdownTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get statisticsV3RewardBreakdownTotal;

  /// No description provided for @statisticsV3RewardBreakdownEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay recompensas registradas en este periodo.'**
  String get statisticsV3RewardBreakdownEmpty;

  /// No description provided for @statisticsV3RewardBreakdownHint.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsado para ver el detalle'**
  String get statisticsV3RewardBreakdownHint;

  /// No description provided for @statisticsV3RewardBreakdownLevelUpFootnote.
  ///
  /// In es, this message translates to:
  /// **'Las recompensas por subida de nivel se mostrarán aquí cuando exista historial fechado de recompensas.'**
  String get statisticsV3RewardBreakdownLevelUpFootnote;

  /// No description provided for @statisticsV3ConsistencyCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Consistencia'**
  String get statisticsV3ConsistencyCardTitle;

  /// No description provided for @statisticsV3ConsistencyCompletedLabel.
  ///
  /// In es, this message translates to:
  /// **'completado'**
  String get statisticsV3ConsistencyCompletedLabel;

  /// No description provided for @statisticsV3ConsistencyPendingLabel.
  ///
  /// In es, this message translates to:
  /// **'pendientes'**
  String get statisticsV3ConsistencyPendingLabel;

  /// No description provided for @statisticsV3ConsistencyStreakLabel.
  ///
  /// In es, this message translates to:
  /// **'racha días'**
  String get statisticsV3ConsistencyStreakLabel;

  /// No description provided for @statisticsV3ConsistencyActiveDays.
  ///
  /// In es, this message translates to:
  /// **'días activos'**
  String get statisticsV3ConsistencyActiveDays;

  /// No description provided for @statisticsV3ConsistencyCompletionLabel.
  ///
  /// In es, this message translates to:
  /// **'de cumplimiento'**
  String get statisticsV3ConsistencyCompletionLabel;

  /// No description provided for @statisticsV3FamiliesCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Familia destacada'**
  String get statisticsV3FamiliesCardTitle;

  /// No description provided for @statisticsV3FamiliesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay una familia con actividad en este periodo.'**
  String get statisticsV3FamiliesEmpty;

  /// No description provided for @statisticsV3FeaturedFamilySubtitleDay.
  ///
  /// In es, this message translates to:
  /// **'La familia con más actividad hoy'**
  String get statisticsV3FeaturedFamilySubtitleDay;

  /// No description provided for @statisticsV3FeaturedFamilySubtitleWeek.
  ///
  /// In es, this message translates to:
  /// **'La familia con más actividad esta semana'**
  String get statisticsV3FeaturedFamilySubtitleWeek;

  /// No description provided for @statisticsV3FeaturedFamilySubtitleMonth.
  ///
  /// In es, this message translates to:
  /// **'La familia con más actividad este mes'**
  String get statisticsV3FeaturedFamilySubtitleMonth;

  /// No description provided for @statisticsV3FeaturedFamilySubtitleYear.
  ///
  /// In es, this message translates to:
  /// **'La familia con más actividad este año'**
  String get statisticsV3FeaturedFamilySubtitleYear;

  /// No description provided for @statisticsV3BestMomentCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Mejor momento'**
  String get statisticsV3BestMomentCardTitle;

  /// No description provided for @statisticsV3BestMomentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu franja más activa'**
  String get statisticsV3BestMomentSubtitle;

  /// No description provided for @statisticsV3BestMomentFallback.
  ///
  /// In es, this message translates to:
  /// **'La información de horario aparecerá cuando haya más completados con hora registrada.'**
  String get statisticsV3BestMomentFallback;

  /// No description provided for @statisticsV3BestMomentWithCount.
  ///
  /// In es, this message translates to:
  /// **'{moment} · {count}'**
  String statisticsV3BestMomentWithCount(String moment, int count);

  /// No description provided for @statisticsV3MomentMorning.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get statisticsV3MomentMorning;

  /// No description provided for @statisticsV3MomentAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Mediodía'**
  String get statisticsV3MomentAfternoon;

  /// No description provided for @statisticsV3MomentEvening.
  ///
  /// In es, this message translates to:
  /// **'Tarde'**
  String get statisticsV3MomentEvening;

  /// No description provided for @statisticsV3MomentNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get statisticsV3MomentNight;

  /// No description provided for @statisticsV3NoFamily.
  ///
  /// In es, this message translates to:
  /// **'Sin familia'**
  String get statisticsV3NoFamily;

  /// No description provided for @statisticsV3InsightCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Insight'**
  String get statisticsV3InsightCardTitle;

  /// No description provided for @statisticsV3InsightEmptyState.
  ///
  /// In es, this message translates to:
  /// **'Cuando completes algunos hábitos, aquí verás una lectura útil de tu progreso.'**
  String get statisticsV3InsightEmptyState;

  /// No description provided for @statisticsV3InsightPositiveConsistency.
  ///
  /// In es, this message translates to:
  /// **'Estás manteniendo un ritmo sólido en este periodo. Continúa con la misma calma.'**
  String get statisticsV3InsightPositiveConsistency;

  /// No description provided for @statisticsV3InsightFeaturedFamily.
  ///
  /// In es, this message translates to:
  /// **'{family} lidera este periodo. Apóyate en ese impulso.'**
  String statisticsV3InsightFeaturedFamily(String family);

  /// No description provided for @statisticsV3InsightBestMoment.
  ///
  /// In es, this message translates to:
  /// **'{moment} es tu franja más fuerte. Protégela con una acción simple.'**
  String statisticsV3InsightBestMoment(String moment);

  /// No description provided for @statisticsV3InsightLowActivity.
  ///
  /// In es, this message translates to:
  /// **'Este periodo sigue con poca actividad. Mantén un objetivo pequeño y claro para recuperar ritmo.'**
  String get statisticsV3InsightLowActivity;

  /// No description provided for @statisticsV3HighlightedHabitCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábito destacado'**
  String get statisticsV3HighlightedHabitCardTitle;

  /// No description provided for @statisticsV3HighlightedHabitSubtitleDay.
  ///
  /// In es, this message translates to:
  /// **'El hábito con más actividad hoy'**
  String get statisticsV3HighlightedHabitSubtitleDay;

  /// No description provided for @statisticsV3HighlightedHabitSubtitleWeek.
  ///
  /// In es, this message translates to:
  /// **'El hábito con más actividad esta semana'**
  String get statisticsV3HighlightedHabitSubtitleWeek;

  /// No description provided for @statisticsV3HighlightedHabitSubtitleMonth.
  ///
  /// In es, this message translates to:
  /// **'El hábito con más actividad este mes'**
  String get statisticsV3HighlightedHabitSubtitleMonth;

  /// No description provided for @statisticsV3HighlightedHabitSubtitleYear.
  ///
  /// In es, this message translates to:
  /// **'El hábito con más actividad este año'**
  String get statisticsV3HighlightedHabitSubtitleYear;

  /// No description provided for @statisticsV3HighlightedHabitStreakLabel.
  ///
  /// In es, this message translates to:
  /// **'Racha'**
  String get statisticsV3HighlightedHabitStreakLabel;

  /// No description provided for @statisticsV3HighlightedHabitStreakDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String statisticsV3HighlightedHabitStreakDays(int days);

  /// No description provided for @statisticsV3HighlightedHabitQuestionDay.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hábito he estado haciendo durante más tiempo hoy?'**
  String get statisticsV3HighlightedHabitQuestionDay;

  /// No description provided for @statisticsV3HighlightedHabitQuestionWeek.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hábito he estado haciendo durante más tiempo esta semana?'**
  String get statisticsV3HighlightedHabitQuestionWeek;

  /// No description provided for @statisticsV3HighlightedHabitQuestionMonth.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hábito he estado haciendo durante más tiempo este mes?'**
  String get statisticsV3HighlightedHabitQuestionMonth;

  /// No description provided for @statisticsV3HighlightedHabitQuestionYear.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hábito he estado haciendo durante más tiempo este año?'**
  String get statisticsV3HighlightedHabitQuestionYear;

  /// No description provided for @statisticsV3HighlightedHabitEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay un hábito destacado disponible.'**
  String get statisticsV3HighlightedHabitEmpty;

  /// No description provided for @statisticsV3HighlightedCompletedDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{# día completado} other{# días completados}}'**
  String statisticsV3HighlightedCompletedDays(int count);

  /// No description provided for @statisticsV3HabitListTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get statisticsV3HabitListTitle;

  /// No description provided for @statisticsV3HabitListSearchPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar hábitos'**
  String get statisticsV3HabitListSearchPlaceholder;

  /// No description provided for @statisticsV3HabitListAllChip.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get statisticsV3HabitListAllChip;

  /// No description provided for @statisticsV3HabitListMainDaysPercent.
  ///
  /// In es, this message translates to:
  /// **'{completed} de {expected} días · {percent}%'**
  String statisticsV3HabitListMainDaysPercent(
      int completed, int expected, int percent);

  /// No description provided for @statisticsV3HabitListMainTimesPerWeek.
  ///
  /// In es, this message translates to:
  /// **'{completed}/{target} esta semana'**
  String statisticsV3HabitListMainTimesPerWeek(int completed, int target);

  /// No description provided for @statisticsV3HabitListMainCountWeek.
  ///
  /// In es, this message translates to:
  /// **'{value} {unit} esta semana'**
  String statisticsV3HabitListMainCountWeek(String value, String unit);

  /// No description provided for @statisticsV3HabitListStreakDays.
  ///
  /// In es, this message translates to:
  /// **'Racha: {days} días'**
  String statisticsV3HabitListStreakDays(int days);

  /// No description provided for @statisticsV3HabitListAvgPerDay.
  ///
  /// In es, this message translates to:
  /// **'Media: {value} {unit}/día'**
  String statisticsV3HabitListAvgPerDay(String value, String unit);

  /// No description provided for @statisticsV3HabitListEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay hábitos activos.'**
  String get statisticsV3HabitListEmptyTitle;

  /// No description provided for @statisticsV3HabitListEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea un hábito para empezar a ver progreso aquí.'**
  String get statisticsV3HabitListEmptySubtitle;

  /// No description provided for @statisticsV3HabitListNoResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay hábitos que coincidan con tu búsqueda.'**
  String get statisticsV3HabitListNoResultsTitle;

  /// No description provided for @statisticsV3HabitListNoResultsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro nombre o familia.'**
  String get statisticsV3HabitListNoResultsSubtitle;

  /// No description provided for @statisticsV3HabitListPlusComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Crear hábitos desde esta vista llegará pronto.'**
  String get statisticsV3HabitListPlusComingSoon;

  /// No description provided for @statisticsV3HabitViewPlaceholderTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista por hábito'**
  String get statisticsV3HabitViewPlaceholderTitle;

  /// No description provided for @statisticsV3HabitViewPlaceholderBody.
  ///
  /// In es, this message translates to:
  /// **'Esta sección queda reservada para la vista detallada por hábito en V3. Por ahora puedes usar el resumen general sin riesgos.'**
  String get statisticsV3HabitViewPlaceholderBody;

  /// No description provided for @statisticsV3ProgressMessageEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún estás a tiempo de empezar'**
  String get statisticsV3ProgressMessageEmpty;

  /// No description provided for @statisticsV3ProgressMessageInProgress.
  ///
  /// In es, this message translates to:
  /// **'Tu ritmo se está construyendo'**
  String get statisticsV3ProgressMessageInProgress;

  /// No description provided for @statisticsV3ProgressMessageComplete.
  ///
  /// In es, this message translates to:
  /// **'Periodo completado con calma'**
  String get statisticsV3ProgressMessageComplete;

  /// No description provided for @statisticsV3WeeklyImprovementTitle.
  ///
  /// In es, this message translates to:
  /// **'Mejora de semana'**
  String get statisticsV3WeeklyImprovementTitle;

  /// No description provided for @statisticsV3WeeklyImprovementVsLastWeek.
  ///
  /// In es, this message translates to:
  /// **'vs semana anterior'**
  String get statisticsV3WeeklyImprovementVsLastWeek;

  /// No description provided for @statisticsV3WeeklyImprovementNoComparison.
  ///
  /// In es, this message translates to:
  /// **'Sin comparación todavía'**
  String get statisticsV3WeeklyImprovementNoComparison;

  /// No description provided for @statisticsV3WeeklyImprovementSameAsLastWeek.
  ///
  /// In es, this message translates to:
  /// **'Igual que la semana anterior'**
  String get statisticsV3WeeklyImprovementSameAsLastWeek;

  /// No description provided for @statisticsV3MonthlyCalendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario de constancia'**
  String get statisticsV3MonthlyCalendarTitle;

  /// No description provided for @statisticsV3MonthlyCalendarSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu ritmo mensual de un vistazo'**
  String get statisticsV3MonthlyCalendarSubtitle;

  /// No description provided for @statisticsV3ConsistencyLegendFuture.
  ///
  /// In es, this message translates to:
  /// **'Futuro'**
  String get statisticsV3ConsistencyLegendFuture;

  /// No description provided for @statisticsV3ConsistencyLegendNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get statisticsV3ConsistencyLegendNoData;

  /// No description provided for @habitStatsMetricCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get habitStatsMetricCompleted;

  /// No description provided for @habitStatsMetricCompletionDescription.
  ///
  /// In es, this message translates to:
  /// **'{done}/{total} días'**
  String habitStatsMetricCompletionDescription(int done, int total);

  /// No description provided for @habitStatsMetricConsistency.
  ///
  /// In es, this message translates to:
  /// **'Consistencia'**
  String get habitStatsMetricConsistency;

  /// No description provided for @habitStatsMetricConsistencyDescription.
  ///
  /// In es, this message translates to:
  /// **'Últimos {window} días'**
  String habitStatsMetricConsistencyDescription(int window);

  /// No description provided for @habitStatsMetricBestStreak.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha'**
  String get habitStatsMetricBestStreak;

  /// No description provided for @habitStatsMetricPersonalBest.
  ///
  /// In es, this message translates to:
  /// **'Record personal'**
  String get habitStatsMetricPersonalBest;

  /// No description provided for @habitStatsMetricTotalDone.
  ///
  /// In es, this message translates to:
  /// **'Total hechos'**
  String get habitStatsMetricTotalDone;

  /// No description provided for @habitStatsMetricHistoricRecords.
  ///
  /// In es, this message translates to:
  /// **'Historico (registros)'**
  String get habitStatsMetricHistoricRecords;

  /// No description provided for @habitStatsChartWeekTitle.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get habitStatsChartWeekTitle;

  /// No description provided for @habitStatsChartLastFourWeeksTitle.
  ///
  /// In es, this message translates to:
  /// **'Últimas 4 semanas'**
  String get habitStatsChartLastFourWeeksTitle;

  /// No description provided for @habitStatsChartWeekSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Completado por día'**
  String get habitStatsChartWeekSubtitle;

  /// No description provided for @habitStatsChartWeeksSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Completado agregado por semana'**
  String get habitStatsChartWeeksSubtitle;

  /// No description provided for @habitStatsNextMilestone.
  ///
  /// In es, this message translates to:
  /// **'Siguiente hito'**
  String get habitStatsNextMilestone;

  /// No description provided for @habitStatsWeeklyComparisonTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparacion semanal'**
  String get habitStatsWeeklyComparisonTitle;

  /// No description provided for @habitStatsWeeklyComparisonSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Esta semana vs la anterior'**
  String get habitStatsWeeklyComparisonSubtitle;

  /// No description provided for @habitStatsBestTimeSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo lo cumples mejor?'**
  String get habitStatsBestTimeSectionTitle;

  /// No description provided for @habitStatsBestTimeSectionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Basado en tus registros, tus momentos más consistentes'**
  String get habitStatsBestTimeSectionSubtitle;

  /// No description provided for @habitStatsMonthCalendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario del mes'**
  String get habitStatsMonthCalendarTitle;

  /// No description provided for @habitStatsMonthlyActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad mensual'**
  String get habitStatsMonthlyActivityTitle;

  /// No description provided for @habitStatsMonthlyActivityPlaceholderBody.
  ///
  /// In es, this message translates to:
  /// **'El calendario mensual estará disponible en la siguiente fase.'**
  String get habitStatsMonthlyActivityPlaceholderBody;

  /// No description provided for @habitStatsTabSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get habitStatsTabSummaryTitle;

  /// No description provided for @habitStatsTabLastDaysTitle.
  ///
  /// In es, this message translates to:
  /// **'Últimos {days} días'**
  String habitStatsTabLastDaysTitle(int days);

  /// No description provided for @habitStatsTabAchievementsUnlocked.
  ///
  /// In es, this message translates to:
  /// **'Logros desbloqueados'**
  String get habitStatsTabAchievementsUnlocked;

  /// No description provided for @habitStatsTabCurrentStreakTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get habitStatsTabCurrentStreakTitle;

  /// No description provided for @habitStatsTabDayUnit.
  ///
  /// In es, this message translates to:
  /// **'{count} día'**
  String habitStatsTabDayUnit(int count);

  /// No description provided for @habitStatsTabTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'total'**
  String get habitStatsTabTotalLabel;

  /// No description provided for @habitStatsTabCompletionWindow.
  ///
  /// In es, this message translates to:
  /// **'{done} / {total} días'**
  String habitStatsTabCompletionWindow(int done, int total);

  /// No description provided for @habitStatsTabCounterHint.
  ///
  /// In es, this message translates to:
  /// **'Cuenta el número de veces completado cada día'**
  String get habitStatsTabCounterHint;

  /// No description provided for @habitStatsTabCheckHint.
  ///
  /// In es, this message translates to:
  /// **'Días en los que completaste este hábito'**
  String get habitStatsTabCheckHint;

  /// No description provided for @habitStatsTabFireStreakTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha de fuego'**
  String get habitStatsTabFireStreakTitle;

  /// No description provided for @habitStatsTabStreakInARow.
  ///
  /// In es, this message translates to:
  /// **'{days} días seguidos'**
  String habitStatsTabStreakInARow(int days);

  /// No description provided for @habitStatsTabCentennialTitle.
  ///
  /// In es, this message translates to:
  /// **'Centenario!'**
  String get habitStatsTabCentennialTitle;

  /// No description provided for @habitStatsTabHalfCenturyTitle.
  ///
  /// In es, this message translates to:
  /// **'Medio centenar'**
  String get habitStatsTabHalfCenturyTitle;

  /// No description provided for @habitStatsTabCompletedCount.
  ///
  /// In es, this message translates to:
  /// **'{count} completados'**
  String habitStatsTabCompletedCount(int count);

  /// No description provided for @habitStatsTabMaxConsistencyTitle.
  ///
  /// In es, this message translates to:
  /// **'Consistencia maxima'**
  String get habitStatsTabMaxConsistencyTitle;

  /// No description provided for @habitStatsTabLast30DaysPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent}% últimos 30 días'**
  String habitStatsTabLast30DaysPercent(int percent);

  /// No description provided for @habitStatsTabLegendaryRecordTitle.
  ///
  /// In es, this message translates to:
  /// **'Record legendario'**
  String get habitStatsTabLegendaryRecordTitle;

  /// No description provided for @habitStatsTabRecordStreak.
  ///
  /// In es, this message translates to:
  /// **'{days} días de racha'**
  String habitStatsTabRecordStreak(int days);

  /// No description provided for @habitStatsTabWeeklyDelta.
  ///
  /// In es, this message translates to:
  /// **'{delta} vs semana anterior'**
  String habitStatsTabWeeklyDelta(int delta);

  /// No description provided for @habitStatsTabWeeklyDeltaEqual.
  ///
  /// In es, this message translates to:
  /// **'Igual que semana anterior'**
  String get habitStatsTabWeeklyDeltaEqual;

  /// No description provided for @diaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get diaryTitle;

  /// No description provided for @diaryMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get diaryMenuTooltip;

  /// No description provided for @diaryCloseSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cerrar búsqueda'**
  String get diaryCloseSearchTooltip;

  /// No description provided for @diarySearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get diarySearchTooltip;

  /// No description provided for @diaryFiltersTooltip.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get diaryFiltersTooltip;

  /// No description provided for @diaryNewEntry.
  ///
  /// In es, this message translates to:
  /// **'Nueva entrada'**
  String get diaryNewEntry;

  /// No description provided for @diaryEntryDeleted.
  ///
  /// In es, this message translates to:
  /// **'Entrada eliminada'**
  String get diaryEntryDeleted;

  /// No description provided for @diaryEntrySaved.
  ///
  /// In es, this message translates to:
  /// **'Entrada guardada'**
  String get diaryEntrySaved;

  /// No description provided for @diaryNoteSaved.
  ///
  /// In es, this message translates to:
  /// **'Nota guardada'**
  String get diaryNoteSaved;

  /// No description provided for @diaryPinSoon.
  ///
  /// In es, this message translates to:
  /// **'Fijar: próximamente'**
  String get diaryPinSoon;

  /// No description provided for @diaryDeleteEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar entrada'**
  String get diaryDeleteEntryTitle;

  /// No description provided for @diaryDeleteEntryBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get diaryDeleteEntryBody;

  /// No description provided for @diaryEntriesCount.
  ///
  /// In es, this message translates to:
  /// **'{count} entradas'**
  String diaryEntriesCount(int count);

  /// No description provided for @diaryPeriodAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get diaryPeriodAll;

  /// No description provided for @diaryPeriodDays.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get diaryPeriodDays;

  /// No description provided for @diaryPeriodWeeks.
  ///
  /// In es, this message translates to:
  /// **'Semanas'**
  String get diaryPeriodWeeks;

  /// No description provided for @diaryPeriodMonths.
  ///
  /// In es, this message translates to:
  /// **'Meses'**
  String get diaryPeriodMonths;

  /// No description provided for @diarySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en tu diario...'**
  String get diarySearchHint;

  /// No description provided for @diaryClearTooltip.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get diaryClearTooltip;

  /// No description provided for @diarySearchScopeAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get diarySearchScopeAll;

  /// No description provided for @diarySearchScopeHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get diarySearchScopeHabits;

  /// No description provided for @diarySearchScopePersonal.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get diarySearchScopePersonal;

  /// No description provided for @diaryWrittenEntriesToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy escribiste {count} entradas'**
  String diaryWrittenEntriesToday(int count);

  /// No description provided for @diaryEmotionalXp.
  ///
  /// In es, this message translates to:
  /// **'+{xp} XP emocional'**
  String diaryEmotionalXp(int xp);

  /// No description provided for @diarySummaryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Hoy aún no has escrito'**
  String get diarySummaryEmptyTitle;

  /// No description provided for @diarySummaryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un minuto puede cambiar tu día'**
  String get diarySummaryEmptySubtitle;

  /// No description provided for @diarySummaryOneTitle.
  ///
  /// In es, this message translates to:
  /// **'Buen comienzo'**
  String get diarySummaryOneTitle;

  /// No description provided for @diarySummaryOneSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Has dado espacio a tu mente'**
  String get diarySummaryOneSubtitle;

  /// No description provided for @diarySummaryFewTitle.
  ///
  /// In es, this message translates to:
  /// **'Estás cuidando tu mundo interior'**
  String get diarySummaryFewTitle;

  /// No description provided for @diarySummaryFewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sigue así'**
  String get diarySummaryFewSubtitle;

  /// No description provided for @diarySummaryManyTitle.
  ///
  /// In es, this message translates to:
  /// **'Día muy consciente'**
  String get diarySummaryManyTitle;

  /// No description provided for @diarySummaryManySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gran trabajo emocional'**
  String get diarySummaryManySubtitle;

  /// No description provided for @diaryActionEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get diaryActionEdit;

  /// No description provided for @diaryActionDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get diaryActionDelete;

  /// No description provided for @diaryComposerCancel.
  ///
  /// In es, this message translates to:
  /// **'← Cancelar'**
  String get diaryComposerCancel;

  /// No description provided for @diaryComposerEditEntryUpper.
  ///
  /// In es, this message translates to:
  /// **'EDITAR ENTRADA'**
  String get diaryComposerEditEntryUpper;

  /// No description provided for @diaryComposerNewEntryUpper.
  ///
  /// In es, this message translates to:
  /// **'NUEVA ENTRADA'**
  String get diaryComposerNewEntryUpper;

  /// No description provided for @diaryComposerMoodSectionUpper.
  ///
  /// In es, this message translates to:
  /// **'¿CÓMO TE SENTISTE?'**
  String get diaryComposerMoodSectionUpper;

  /// No description provided for @diaryComposerTitleUpper.
  ///
  /// In es, this message translates to:
  /// **'TÍTULO'**
  String get diaryComposerTitleUpper;

  /// No description provided for @diaryComposerReflectionUpper.
  ///
  /// In es, this message translates to:
  /// **'REFLEXIÓN'**
  String get diaryComposerReflectionUpper;

  /// No description provided for @diaryComposerTitleHint.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo resumirías hoy?'**
  String get diaryComposerTitleHint;

  /// No description provided for @diaryComposerHabitReflectionHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué pasó hoy con tu hábito? ¿Qué sentiste? ¿Qué aprendiste?'**
  String get diaryComposerHabitReflectionHint;

  /// No description provided for @diaryComposerPersonalReflectionHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tienes en mente? ¿Qué quieres dejar por escrito hoy?'**
  String get diaryComposerPersonalReflectionHint;

  /// No description provided for @diaryComposerSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get diaryComposerSaveChanges;

  /// No description provided for @diaryComposerSaveEntry.
  ///
  /// In es, this message translates to:
  /// **'Guardar entrada'**
  String get diaryComposerSaveEntry;

  /// No description provided for @diaryComposerTypeHabit.
  ///
  /// In es, this message translates to:
  /// **'Ligada a hábito'**
  String get diaryComposerTypeHabit;

  /// No description provided for @diaryComposerTypePersonal.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get diaryComposerTypePersonal;

  /// No description provided for @diaryComposerSelectHabit.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hábito'**
  String get diaryComposerSelectHabit;

  /// No description provided for @diaryComposerTapToChooseHabit.
  ///
  /// In es, this message translates to:
  /// **'Toca para elegir un hábito'**
  String get diaryComposerTapToChooseHabit;

  /// No description provided for @diaryComposerWriteSomethingError.
  ///
  /// In es, this message translates to:
  /// **'Escribe algo para guardar la entrada'**
  String get diaryComposerWriteSomethingError;

  /// No description provided for @diaryComposerSelectHabitError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un hábito'**
  String get diaryComposerSelectHabitError;

  /// No description provided for @diaryComposerNoActiveHabits.
  ///
  /// In es, this message translates to:
  /// **'No hay hábitos activos para seleccionar'**
  String get diaryComposerNoActiveHabits;

  /// No description provided for @diaryComposerSelectHabitSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hábito'**
  String get diaryComposerSelectHabitSheetTitle;

  /// No description provided for @diaryDetailScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrada'**
  String get diaryDetailScreenTitle;

  /// No description provided for @diaryDetailTopHabitUpper.
  ///
  /// In es, this message translates to:
  /// **'ENTRADA DE HÁBITO'**
  String get diaryDetailTopHabitUpper;

  /// No description provided for @diaryDetailTopPersonalUpper.
  ///
  /// In es, this message translates to:
  /// **'ENTRADA PERSONAL'**
  String get diaryDetailTopPersonalUpper;

  /// No description provided for @diaryDetailFallbackHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrada de hábito'**
  String get diaryDetailFallbackHabitTitle;

  /// No description provided for @diaryDetailFallbackPersonalTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrada personal'**
  String get diaryDetailFallbackPersonalTitle;

  /// No description provided for @diaryDetailLeadingPersonal.
  ///
  /// In es, this message translates to:
  /// **'Escrito personal'**
  String get diaryDetailLeadingPersonal;

  /// No description provided for @diaryDetailFamilyPersonal.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get diaryDetailFamilyPersonal;

  /// No description provided for @diaryDetailTypeHabit.
  ///
  /// In es, this message translates to:
  /// **'Día de hábito'**
  String get diaryDetailTypeHabit;

  /// No description provided for @diaryDetailTypePersonal.
  ///
  /// In es, this message translates to:
  /// **'Nota personal'**
  String get diaryDetailTypePersonal;

  /// No description provided for @diaryDetailNotesUpper.
  ///
  /// In es, this message translates to:
  /// **'NOTAS'**
  String get diaryDetailNotesUpper;

  /// No description provided for @diaryDetailLoggedAt.
  ///
  /// In es, this message translates to:
  /// **'Registrado a las {time}'**
  String diaryDetailLoggedAt(String time);

  /// No description provided for @diaryDetailThisWeekUpper.
  ///
  /// In es, this message translates to:
  /// **'ESTA SEMANA'**
  String get diaryDetailThisWeekUpper;

  /// No description provided for @diaryTodayUpper.
  ///
  /// In es, this message translates to:
  /// **'HOY'**
  String get diaryTodayUpper;

  /// No description provided for @habitStatsWeekShort.
  ///
  /// In es, this message translates to:
  /// **'S{weekNumber}'**
  String habitStatsWeekShort(int weekNumber);

  /// No description provided for @habitStatsHabitFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábito'**
  String get habitStatsHabitFallbackTitle;

  /// No description provided for @habitStatsPeriodDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get habitStatsPeriodDay;

  /// No description provided for @habitStatsPeriodWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get habitStatsPeriodWeek;

  /// No description provided for @habitStatsPeriodMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get habitStatsPeriodMonth;

  /// No description provided for @habitStatsPeriodYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get habitStatsPeriodYear;

  /// No description provided for @habitStatsYearSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen anual'**
  String get habitStatsYearSummaryTitle;

  /// No description provided for @habitStatsYearSummaryBody.
  ///
  /// In es, this message translates to:
  /// **'Pronto verás tus meses, actividad e insights de este hábito durante el año.'**
  String get habitStatsYearSummaryBody;

  /// No description provided for @habitStatsYearMonthsTitle.
  ///
  /// In es, this message translates to:
  /// **'Meses del año'**
  String get habitStatsYearMonthsTitle;

  /// No description provided for @habitStatsYearMonthsBody.
  ///
  /// In es, this message translates to:
  /// **'Un vistazo rápido a cómo ha ido este hábito mes a mes.'**
  String get habitStatsYearMonthsBody;

  /// No description provided for @habitStatsYearCalendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario anual'**
  String get habitStatsYearCalendarTitle;

  /// No description provided for @habitStatsYearCalendarDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get habitStatsYearCalendarDone;

  /// No description provided for @habitStatsYearCalendarSkipped.
  ///
  /// In es, this message translates to:
  /// **'Omitido'**
  String get habitStatsYearCalendarSkipped;

  /// No description provided for @habitStatsYearCalendarMissed.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get habitStatsYearCalendarMissed;

  /// No description provided for @habitStatsPeriodThreeMonths.
  ///
  /// In es, this message translates to:
  /// **'3 meses'**
  String get habitStatsPeriodThreeMonths;

  /// No description provided for @habitStatsPeriodAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get habitStatsPeriodAll;

  /// No description provided for @habitStatsDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} día'**
  String habitStatsDaysLabel(int count);

  /// No description provided for @habitStatsCurrentStreakUpper.
  ///
  /// In es, this message translates to:
  /// **'RACHA ACTUAL'**
  String get habitStatsCurrentStreakUpper;

  /// No description provided for @habitStatsHeadlineStartToday.
  ///
  /// In es, this message translates to:
  /// **'Empezamos hoy!'**
  String get habitStatsHeadlineStartToday;

  /// No description provided for @habitStatsHeadlineGoodStart.
  ///
  /// In es, this message translates to:
  /// **'Buen inicio!'**
  String get habitStatsHeadlineGoodStart;

  /// No description provided for @habitStatsHeadlineOnStreak.
  ///
  /// In es, this message translates to:
  /// **'En racha!'**
  String get habitStatsHeadlineOnStreak;

  /// No description provided for @habitStatsMilestoneProgress.
  ///
  /// In es, this message translates to:
  /// **'{label}: {next} días'**
  String habitStatsMilestoneProgress(String label, int next);

  /// No description provided for @habitStatsThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get habitStatsThisWeek;

  /// No description provided for @habitStatsThisYear.
  ///
  /// In es, this message translates to:
  /// **'Este año'**
  String get habitStatsThisYear;

  /// No description provided for @habitStatsYearMetricCompletedTotal.
  ///
  /// In es, this message translates to:
  /// **'Hecho / Total'**
  String get habitStatsYearMetricCompletedTotal;

  /// No description provided for @habitStatsYearMetricConsistencySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consistencia anual'**
  String get habitStatsYearMetricConsistencySubtitle;

  /// No description provided for @habitStatsYearMetricBestMonth.
  ///
  /// In es, this message translates to:
  /// **'Mejor mes'**
  String get habitStatsYearMetricBestMonth;

  /// No description provided for @habitStatsYearMetricBestMonthSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mayor rendimiento'**
  String get habitStatsYearMetricBestMonthSubtitle;

  /// No description provided for @habitStatsYearMetricActiveMonths.
  ///
  /// In es, this message translates to:
  /// **'Meses activos'**
  String get habitStatsYearMetricActiveMonths;

  /// No description provided for @habitStatsYearMetricActiveMonthsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Con actividad'**
  String get habitStatsYearMetricActiveMonthsSubtitle;

  /// No description provided for @yearlyActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad anual'**
  String get yearlyActivityTitle;

  /// No description provided for @yearlyActivitySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un resumen claro de cómo ha evolucionado este hábito durante el año.'**
  String get yearlyActivitySubtitle;

  /// No description provided for @yearlyActivityBestMonth.
  ///
  /// In es, this message translates to:
  /// **'Mejor mes'**
  String get yearlyActivityBestMonth;

  /// No description provided for @yearlyActivityWeakestMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes más tranquilo'**
  String get yearlyActivityWeakestMonth;

  /// No description provided for @yearlyActivityActiveMonths.
  ///
  /// In es, this message translates to:
  /// **'Meses activos'**
  String get yearlyActivityActiveMonths;

  /// Value for active months in yearly habit stats activity section
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{0 meses} =1{1 mes} other{{count} meses}}'**
  String yearlyActivityActiveMonthsValue(int count);

  /// No description provided for @yearlyActivityTrend.
  ///
  /// In es, this message translates to:
  /// **'Ritmo'**
  String get yearlyActivityTrend;

  /// No description provided for @yearlyActivityTrendImproving.
  ///
  /// In es, this message translates to:
  /// **'Mejorando'**
  String get yearlyActivityTrendImproving;

  /// No description provided for @yearlyActivityTrendStable.
  ///
  /// In es, this message translates to:
  /// **'Estable'**
  String get yearlyActivityTrendStable;

  /// No description provided for @yearlyActivityTrendDeclining.
  ///
  /// In es, this message translates to:
  /// **'Bajando el ritmo'**
  String get yearlyActivityTrendDeclining;

  /// No description provided for @yearlyActivityTrendStarting.
  ///
  /// In es, this message translates to:
  /// **'Empezando'**
  String get yearlyActivityTrendStarting;

  /// No description provided for @yearlyActivityTrendNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos aún'**
  String get yearlyActivityTrendNoData;

  /// No description provided for @habitStatsYearlyInsightTitle.
  ///
  /// In es, this message translates to:
  /// **'Insight anual'**
  String get habitStatsYearlyInsightTitle;

  /// No description provided for @habitStatsYearlyComparisonTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparación anual'**
  String get habitStatsYearlyComparisonTitle;

  /// No description provided for @habitStatsYearlyComparisonImproving.
  ///
  /// In es, this message translates to:
  /// **'Los últimos meses van mejor'**
  String get habitStatsYearlyComparisonImproving;

  /// No description provided for @habitStatsYearlyComparisonStable.
  ///
  /// In es, this message translates to:
  /// **'Un año estable por ahora'**
  String get habitStatsYearlyComparisonStable;

  /// No description provided for @habitStatsYearlyComparisonDeclining.
  ///
  /// In es, this message translates to:
  /// **'El ritmo está bajando'**
  String get habitStatsYearlyComparisonDeclining;

  /// No description provided for @habitStatsYearlyComparisonAboveAverage.
  ///
  /// In es, this message translates to:
  /// **'Este mes está por encima de tu media anual'**
  String get habitStatsYearlyComparisonAboveAverage;

  /// No description provided for @habitStatsYearlyComparisonBelowAverage.
  ///
  /// In es, this message translates to:
  /// **'Este mes está por debajo de tu media anual'**
  String get habitStatsYearlyComparisonBelowAverage;

  /// No description provided for @habitStatsYearlyComparisonStarting.
  ///
  /// In es, this message translates to:
  /// **'Aún construyendo historial'**
  String get habitStatsYearlyComparisonStarting;

  /// No description provided for @habitStatsYearlyComparisonNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos anuales aún'**
  String get habitStatsYearlyComparisonNoData;

  /// No description provided for @habitStatsYearlyInsightStrongTitle.
  ///
  /// In es, this message translates to:
  /// **'Año sólido'**
  String get habitStatsYearlyInsightStrongTitle;

  /// No description provided for @habitStatsYearlyInsightStrongBody.
  ///
  /// In es, this message translates to:
  /// **'Este hábito está teniendo un año sólido. Tus mejores meses empiezan a destacar.'**
  String get habitStatsYearlyInsightStrongBody;

  /// No description provided for @habitStatsYearlyInsightImprovingTitle.
  ///
  /// In es, this message translates to:
  /// **'Ritmo en mejora'**
  String get habitStatsYearlyInsightImprovingTitle;

  /// No description provided for @habitStatsYearlyInsightImprovingBody.
  ///
  /// In es, this message translates to:
  /// **'Tu ritmo está mejorando. Los últimos meses empiezan a ser más constantes.'**
  String get habitStatsYearlyInsightImprovingBody;

  /// No description provided for @habitStatsYearlyInsightSteadyTitle.
  ///
  /// In es, this message translates to:
  /// **'Ritmo estable'**
  String get habitStatsYearlyInsightSteadyTitle;

  /// No description provided for @habitStatsYearlyInsightSteadyBody.
  ///
  /// In es, this message translates to:
  /// **'Mantienes un ritmo estable. Las pequeñas repeticiones están sosteniendo el hábito durante el año.'**
  String get habitStatsYearlyInsightSteadyBody;

  /// No description provided for @habitStatsYearlyInsightIrregularTitle.
  ///
  /// In es, this message translates to:
  /// **'Año irregular'**
  String get habitStatsYearlyInsightIrregularTitle;

  /// No description provided for @habitStatsYearlyInsightIrregularBody.
  ///
  /// In es, this message translates to:
  /// **'Este año ha sido algo irregular. Un pequeño reinicio el próximo mes puede ayudarte a recuperar impulso.'**
  String get habitStatsYearlyInsightIrregularBody;

  /// No description provided for @habitStatsYearlyInsightQuietTitle.
  ///
  /// In es, this message translates to:
  /// **'Año tranquilo'**
  String get habitStatsYearlyInsightQuietTitle;

  /// No description provided for @habitStatsYearlyInsightQuietBody.
  ///
  /// In es, this message translates to:
  /// **'Este hábito ha estado tranquilo este año. Una sola vez completado puede volver a activar el ritmo.'**
  String get habitStatsYearlyInsightQuietBody;

  /// No description provided for @habitStatsYearlyInsightStartingTitle.
  ///
  /// In es, this message translates to:
  /// **'Base anual iniciada'**
  String get habitStatsYearlyInsightStartingTitle;

  /// No description provided for @habitStatsYearlyInsightStartingBody.
  ///
  /// In es, this message translates to:
  /// **'Aún hay poco historial anual, pero ya tienes una base sobre la que construir.'**
  String get habitStatsYearlyInsightStartingBody;

  /// No description provided for @habitStatsYearlyInsightNoDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin datos anuales'**
  String get habitStatsYearlyInsightNoDataTitle;

  /// No description provided for @habitStatsYearlyInsightNoDataBody.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay actividad anual. Cuando completes este hábito, aparecerá aquí tu insight del año.'**
  String get habitStatsYearlyInsightNoDataBody;

  /// No description provided for @habitStatsLastWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana pasada'**
  String get habitStatsLastWeek;

  /// No description provided for @habitStatsTimeSlotMorning.
  ///
  /// In es, this message translates to:
  /// **'manana'**
  String get habitStatsTimeSlotMorning;

  /// No description provided for @habitStatsTimeSlotAfternoon.
  ///
  /// In es, this message translates to:
  /// **'tarde'**
  String get habitStatsTimeSlotAfternoon;

  /// No description provided for @habitStatsTimeSlotEvening.
  ///
  /// In es, this message translates to:
  /// **'noche'**
  String get habitStatsTimeSlotEvening;

  /// No description provided for @habitStatsTimeSlotNight.
  ///
  /// In es, this message translates to:
  /// **'madrugada'**
  String get habitStatsTimeSlotNight;

  /// No description provided for @habitStatsLegendLess.
  ///
  /// In es, this message translates to:
  /// **'Menos'**
  String get habitStatsLegendLess;

  /// No description provided for @habitStatsLegendMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get habitStatsLegendMore;

  /// No description provided for @habitStatsDayTooltip.
  ///
  /// In es, this message translates to:
  /// **'Día {day}'**
  String habitStatsDayTooltip(int day);

  /// No description provided for @habitStatsThisHabitFallback.
  ///
  /// In es, this message translates to:
  /// **'este hábito'**
  String get habitStatsThisHabitFallback;

  /// No description provided for @habitStatsMotivationLead.
  ///
  /// In es, this message translates to:
  /// **'Llevas '**
  String get habitStatsMotivationLead;

  /// No description provided for @habitStatsMotivationWith.
  ///
  /// In es, this message translates to:
  /// **' con '**
  String get habitStatsMotivationWith;

  /// No description provided for @habitStatsMotivationAboveLead.
  ///
  /// In es, this message translates to:
  /// **'estas '**
  String get habitStatsMotivationAboveLead;

  /// No description provided for @habitStatsMotivationAboveKeyword.
  ///
  /// In es, this message translates to:
  /// **'por encima'**
  String get habitStatsMotivationAboveKeyword;

  /// No description provided for @habitStatsMotivationAboveTail.
  ///
  /// In es, this message translates to:
  /// **' de la semana pasada. '**
  String get habitStatsMotivationAboveTail;

  /// No description provided for @habitStatsMotivationBelowLead.
  ///
  /// In es, this message translates to:
  /// **'esta semana vas un poco '**
  String get habitStatsMotivationBelowLead;

  /// No description provided for @habitStatsMotivationBelowKeyword.
  ///
  /// In es, this message translates to:
  /// **'por debajo'**
  String get habitStatsMotivationBelowKeyword;

  /// No description provided for @habitStatsMotivationBelowTail.
  ///
  /// In es, this message translates to:
  /// **' de la anterior. '**
  String get habitStatsMotivationBelowTail;

  /// No description provided for @habitStatsMotivationEqual.
  ///
  /// In es, this message translates to:
  /// **'mantienes el ritmo de la semana pasada. '**
  String get habitStatsMotivationEqual;

  /// No description provided for @habitStatsMotivationStart.
  ///
  /// In es, this message translates to:
  /// **'buen comienzo. '**
  String get habitStatsMotivationStart;

  /// No description provided for @habitStatsMotivationGoalLead.
  ///
  /// In es, this message translates to:
  /// **'Anticiparte te ayudara a '**
  String get habitStatsMotivationGoalLead;

  /// No description provided for @habitStatsMotivationGoalKeyword.
  ///
  /// In es, this message translates to:
  /// **'llegar a los {days} días'**
  String habitStatsMotivationGoalKeyword(int days);

  /// No description provided for @habitStatsMotivationKeepLead.
  ///
  /// In es, this message translates to:
  /// **'Ahora toca '**
  String get habitStatsMotivationKeepLead;

  /// No description provided for @habitStatsMotivationKeepKeyword.
  ///
  /// In es, this message translates to:
  /// **'mantener la racha'**
  String get habitStatsMotivationKeepKeyword;

  /// No description provided for @habitStatsMotivationKeepTail.
  ///
  /// In es, this message translates to:
  /// **' y consolidarlo.'**
  String get habitStatsMotivationKeepTail;

  /// No description provided for @habitStatsMotivationBestTimeLead.
  ///
  /// In es, this message translates to:
  /// **' Prueba a hacerlo en la '**
  String get habitStatsMotivationBestTimeLead;

  /// No description provided for @habitStatsMotivationBestTimeTail.
  ///
  /// In es, this message translates to:
  /// **', cuando sueles ser más constante.'**
  String get habitStatsMotivationBestTimeTail;

  /// No description provided for @habitStatsObjectiveDaily.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Objetivo: # vez al día} other{Objetivo: # veces al día}}'**
  String habitStatsObjectiveDaily(int count);

  /// No description provided for @habitStatsObjectiveDailySingular.
  ///
  /// In es, this message translates to:
  /// **'Objetivo: {count} vez al día'**
  String habitStatsObjectiveDailySingular(int count);

  /// No description provided for @habitStatsObjectiveDailyPlural.
  ///
  /// In es, this message translates to:
  /// **'Objetivo: {count} veces al día'**
  String habitStatsObjectiveDailyPlural(int count);

  /// No description provided for @habitStatsObjectiveWeekly.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Objetivo: # vez por semana} other{Objetivo: # veces por semana}}'**
  String habitStatsObjectiveWeekly(int count);

  /// No description provided for @habitStatsObjectiveWeeklySingular.
  ///
  /// In es, this message translates to:
  /// **'Objetivo: {count} vez por semana'**
  String habitStatsObjectiveWeeklySingular(int count);

  /// No description provided for @habitStatsObjectiveWeeklyPlural.
  ///
  /// In es, this message translates to:
  /// **'Objetivo: {count} veces por semana'**
  String habitStatsObjectiveWeeklyPlural(int count);

  /// No description provided for @habitStatsPerDayCompact.
  ///
  /// In es, this message translates to:
  /// **'al día'**
  String get habitStatsPerDayCompact;

  /// No description provided for @habitStatsObjectiveFallback.
  ///
  /// In es, this message translates to:
  /// **'Objetivo configurado'**
  String get habitStatsObjectiveFallback;

  /// No description provided for @habitStatsTimesLabel.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{# vez} other{# veces}}'**
  String habitStatsTimesLabel(int count);

  /// No description provided for @habitStatsPerWeek.
  ///
  /// In es, this message translates to:
  /// **'Por semana'**
  String get habitStatsPerWeek;

  /// No description provided for @habitStatsMetricCompletion.
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento'**
  String get habitStatsMetricCompletion;

  /// No description provided for @habitStatsMostFrequentTime.
  ///
  /// In es, this message translates to:
  /// **'Hora más frecuente'**
  String get habitStatsMostFrequentTime;

  /// No description provided for @habitStatsNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get habitStatsNoData;

  /// No description provided for @habitStatsInsightLabel.
  ///
  /// In es, this message translates to:
  /// **'Insight'**
  String get habitStatsInsightLabel;

  /// No description provided for @habitStatsInsightTodaySkippedTitle.
  ///
  /// In es, this message translates to:
  /// **'Día pausado.'**
  String get habitStatsInsightTodaySkippedTitle;

  /// No description provided for @habitStatsInsightTodaySkippedBody.
  ///
  /// In es, this message translates to:
  /// **'La pausa mantiene el contexto sin contar como una repetición.'**
  String get habitStatsInsightTodaySkippedBody;

  /// No description provided for @habitStatsInsightTodayCompletedTitle.
  ///
  /// In es, this message translates to:
  /// **'Buen cierre de hoy.'**
  String get habitStatsInsightTodayCompletedTitle;

  /// No description provided for @habitStatsInsightTodayCompletedBody.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso queda protegido por un día más.'**
  String get habitStatsInsightTodayCompletedBody;

  /// No description provided for @habitStatsInsightPendingStreakTitle.
  ///
  /// In es, this message translates to:
  /// **'Mantén tu ritmo.'**
  String get habitStatsInsightPendingStreakTitle;

  /// No description provided for @habitStatsInsightPendingStreakBody.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{Completar hoy llevaría tu racha a 1 día.} other{Completar hoy llevaría tu racha a {days} días.}}'**
  String habitStatsInsightPendingStreakBody(int days);

  /// No description provided for @habitStatsInsightNearMilestoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Hito cerca.'**
  String get habitStatsInsightNearMilestoneTitle;

  /// No description provided for @habitStatsInsightNearMilestoneBody.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{Estás a 1 día de alcanzar {milestone} días.} other{Estás a {days} días de alcanzar {milestone} días.}}'**
  String habitStatsInsightNearMilestoneBody(int days, int milestone);

  /// No description provided for @habitStatsInsightCountPartialTitle.
  ///
  /// In es, this message translates to:
  /// **'Ya has empezado.'**
  String get habitStatsInsightCountPartialTitle;

  /// No description provided for @habitStatsInsightCountPartialBody.
  ///
  /// In es, this message translates to:
  /// **'Te falta poco para cerrar el objetivo de hoy.'**
  String get habitStatsInsightCountPartialBody;

  /// No description provided for @habitStatsInsightWeeklyTrendPositiveTitle.
  ///
  /// In es, this message translates to:
  /// **'Mejor que la semana pasada.'**
  String get habitStatsInsightWeeklyTrendPositiveTitle;

  /// No description provided for @habitStatsInsightWeeklyTrendPositiveBody.
  ///
  /// In es, this message translates to:
  /// **'Esta semana estás sumando más ritmo.'**
  String get habitStatsInsightWeeklyTrendPositiveBody;

  /// No description provided for @habitStatsInsightWeeklyTrendNegativeTitle.
  ///
  /// In es, this message translates to:
  /// **'Ritmo más bajo.'**
  String get habitStatsInsightWeeklyTrendNegativeTitle;

  /// No description provided for @habitStatsInsightWeeklyTrendNegativeBody.
  ///
  /// In es, this message translates to:
  /// **'Esta semana vas algo por debajo de la anterior.'**
  String get habitStatsInsightWeeklyTrendNegativeBody;

  /// No description provided for @habitStatsInsightStrongConsistencyTitle.
  ///
  /// In es, this message translates to:
  /// **'Ritmo sólido.'**
  String get habitStatsInsightStrongConsistencyTitle;

  /// No description provided for @habitStatsInsightStrongConsistencyBody.
  ///
  /// In es, this message translates to:
  /// **'Este hábito ya empieza a tener una base estable.'**
  String get habitStatsInsightStrongConsistencyBody;

  /// No description provided for @habitStatsInsightBestMomentTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu patrón es claro.'**
  String get habitStatsInsightBestMomentTitle;

  /// No description provided for @habitStatsInsightBestMomentBody.
  ///
  /// In es, this message translates to:
  /// **'La {moment} suele ser tu mejor franja.'**
  String habitStatsInsightBestMomentBody(String moment);

  /// No description provided for @habitStatsInsightRecoveryTitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve con calma.'**
  String get habitStatsInsightRecoveryTitle;

  /// No description provided for @habitStatsInsightRecoveryBody.
  ///
  /// In es, this message translates to:
  /// **'Una repetición pequeña puede reactivar el hábito.'**
  String get habitStatsInsightRecoveryBody;

  /// No description provided for @habitStatsInsightWeeklyGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo semanal cubierto.'**
  String get habitStatsInsightWeeklyGoalTitle;

  /// No description provided for @habitStatsInsightWeeklyGoalBody.
  ///
  /// In es, this message translates to:
  /// **'Ya cumpliste lo previsto para esta semana.'**
  String get habitStatsInsightWeeklyGoalBody;

  /// No description provided for @habitStatsInsightLowConsistencyTitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a lo simple.'**
  String get habitStatsInsightLowConsistencyTitle;

  /// No description provided for @habitStatsInsightLowConsistencyBody.
  ///
  /// In es, this message translates to:
  /// **'Una repetición pequeña puede ayudarte a recuperar ritmo.'**
  String get habitStatsInsightLowConsistencyBody;

  /// No description provided for @habitStatsInsightFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Cada repetición cuenta.'**
  String get habitStatsInsightFallbackTitle;

  /// No description provided for @habitStatsInsightFallbackBody.
  ///
  /// In es, this message translates to:
  /// **'Empieza con una acción pequeña hoy.'**
  String get habitStatsInsightFallbackBody;

  /// No description provided for @habitStatsInsightSteadyRoutine.
  ///
  /// In es, this message translates to:
  /// **'Vas construyendo una rutina estable.'**
  String get habitStatsInsightSteadyRoutine;

  /// No description provided for @habitStatsInsightGoodRhythm.
  ///
  /// In es, this message translates to:
  /// **'Buen ritmo esta semana.'**
  String get habitStatsInsightGoodRhythm;

  /// No description provided for @habitStatsInsightEveryRepetition.
  ///
  /// In es, this message translates to:
  /// **'Cada repetición cuenta.'**
  String get habitStatsInsightEveryRepetition;

  /// No description provided for @habitStatsInsightMonthlyNotStartedTitle.
  ///
  /// In es, this message translates to:
  /// **'Mes por empezar'**
  String get habitStatsInsightMonthlyNotStartedTitle;

  /// No description provided for @habitStatsInsightMonthlyNotStartedBody.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay registros este mes. Un primer check ya empieza a construir ritmo.'**
  String get habitStatsInsightMonthlyNotStartedBody;

  /// No description provided for @habitStatsInsightMonthlyInConstructionTitle.
  ///
  /// In es, this message translates to:
  /// **'Mes en construcción'**
  String get habitStatsInsightMonthlyInConstructionTitle;

  /// No description provided for @habitStatsInsightMonthlyInConstructionBody.
  ///
  /// In es, this message translates to:
  /// **'Llevas {completed}/{objective}. Todavía puedes recuperar ritmo con unos días constantes.'**
  String habitStatsInsightMonthlyInConstructionBody(
      int completed, int objective);

  /// No description provided for @habitStatsInsightMonthlyInProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Buen mes en marcha'**
  String get habitStatsInsightMonthlyInProgressTitle;

  /// No description provided for @habitStatsInsightMonthlyInProgressBody.
  ///
  /// In es, this message translates to:
  /// **'Ya completaste {completed} veces este mes. Mantén este ritmo sin forzarlo.'**
  String habitStatsInsightMonthlyInProgressBody(int completed);

  /// No description provided for @habitStatsInsightMonthlyStrongTitle.
  ///
  /// In es, this message translates to:
  /// **'Ritmo mensual sólido'**
  String get habitStatsInsightMonthlyStrongTitle;

  /// No description provided for @habitStatsInsightMonthlyStrongBody.
  ///
  /// In es, this message translates to:
  /// **'Vas muy bien este mes: {completed}/{objective} completado.'**
  String habitStatsInsightMonthlyStrongBody(int completed, int objective);

  /// No description provided for @habitStatsInsightMonthlyGoalCompletedTitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo mensual completado'**
  String get habitStatsInsightMonthlyGoalCompletedTitle;

  /// No description provided for @habitStatsInsightMonthlyGoalCompletedBody.
  ///
  /// In es, this message translates to:
  /// **'Ya has cumplido el objetivo de este mes. Todo lo extra suma sin presión.'**
  String get habitStatsInsightMonthlyGoalCompletedBody;

  /// No description provided for @habitStatsInsightMonthlyBestMomentBody.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor franja sigue siendo {bestMoment}.'**
  String habitStatsInsightMonthlyBestMomentBody(String bestMoment);

  /// No description provided for @habitStatsInsightMonthlyComparisonBetter.
  ///
  /// In es, this message translates to:
  /// **'Además, vas mejor que el mes pasado.'**
  String get habitStatsInsightMonthlyComparisonBetter;

  /// No description provided for @habitStatsInsightMonthlyComparisonSame.
  ///
  /// In es, this message translates to:
  /// **'Tu ritmo es parecido al mes pasado.'**
  String get habitStatsInsightMonthlyComparisonSame;

  /// No description provided for @habitStatsInsightMonthlyComparisonWorse.
  ///
  /// In es, this message translates to:
  /// **'Vas algo por debajo del mes pasado, pero aún hay margen.'**
  String get habitStatsInsightMonthlyComparisonWorse;

  /// No description provided for @editHabitSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get editHabitSaveChanges;

  /// No description provided for @editHabitSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get editHabitSaving;

  /// No description provided for @editHabitNotificationPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Permisos de notificación denegados.'**
  String get editHabitNotificationPermissionDenied;

  /// No description provided for @editHabitDailyGoalDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Meta diaria'**
  String get editHabitDailyGoalDialogTitle;

  /// No description provided for @editHabitDailyGoalDialogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el numero objetivo.'**
  String get editHabitDailyGoalDialogSubtitle;

  /// No description provided for @editHabitCounterStepDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Incremento'**
  String get editHabitCounterStepDialogTitle;

  /// No description provided for @editHabitCounterStepDialogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cada cuanto aumenta el contador.'**
  String get editHabitCounterStepDialogSubtitle;

  /// No description provided for @editHabitTimesPerWeekDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Veces por semana'**
  String get editHabitTimesPerWeekDialogTitle;

  /// No description provided for @editHabitTimesPerWeekDialogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Puedes superarlo durante la semana.'**
  String get editHabitTimesPerWeekDialogSubtitle;

  /// No description provided for @editHabitHeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar hábito'**
  String get editHabitHeaderTitle;

  /// No description provided for @editHabitHeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ajusta cómo quieres continuar.'**
  String get editHabitHeaderSubtitle;

  /// No description provided for @editHabitSectionIdentity.
  ///
  /// In es, this message translates to:
  /// **'Identidad'**
  String get editHabitSectionIdentity;

  /// No description provided for @editHabitSectionCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoria'**
  String get editHabitSectionCategory;

  /// No description provided for @editHabitSectionTracking.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo lo mides?'**
  String get editHabitSectionTracking;

  /// No description provided for @editHabitSectionFrequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get editHabitSectionFrequency;

  /// No description provided for @editHabitSectionReminder.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get editHabitSectionReminder;

  /// No description provided for @editHabitSectionDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get editHabitSectionDetails;

  /// No description provided for @editHabitTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Meditar cada manana'**
  String get editHabitTitleHint;

  /// No description provided for @editHabitTrackingCheckTitle.
  ///
  /// In es, this message translates to:
  /// **'Si o no'**
  String get editHabitTrackingCheckTitle;

  /// No description provided for @editHabitTrackingCheckSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo hice o no lo hice'**
  String get editHabitTrackingCheckSubtitle;

  /// No description provided for @editHabitTrackingCountTitle.
  ///
  /// In es, this message translates to:
  /// **'Contador'**
  String get editHabitTrackingCountTitle;

  /// No description provided for @editHabitTrackingCountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vasos, minutos, paginas...'**
  String get editHabitTrackingCountSubtitle;

  /// No description provided for @editHabitDailyGoalSection.
  ///
  /// In es, this message translates to:
  /// **'Meta diaria'**
  String get editHabitDailyGoalSection;

  /// No description provided for @editHabitRepetitionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones'**
  String get editHabitRepetitionsTitle;

  /// No description provided for @editHabitRepetitionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántas veces al día?'**
  String get editHabitRepetitionsSubtitle;

  /// No description provided for @editHabitUnitHint.
  ///
  /// In es, this message translates to:
  /// **'Unidad (ej: vasos, km...)'**
  String get editHabitUnitHint;

  /// No description provided for @editHabitCounterStepTitle.
  ///
  /// In es, this message translates to:
  /// **'Incremento'**
  String get editHabitCounterStepTitle;

  /// No description provided for @editHabitCounterStepSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuanto aumenta cada toque.'**
  String get editHabitCounterStepSubtitle;

  /// No description provided for @editHabitFrequencyDaily.
  ///
  /// In es, this message translates to:
  /// **'Cada día'**
  String get editHabitFrequencyDaily;

  /// No description provided for @editHabitFrequencySpecificDays.
  ///
  /// In es, this message translates to:
  /// **'Días concretos'**
  String get editHabitFrequencySpecificDays;

  /// No description provided for @editHabitFrequencyTimesPerWeek.
  ///
  /// In es, this message translates to:
  /// **'X veces / semana'**
  String get editHabitFrequencyTimesPerWeek;

  /// No description provided for @editHabitWeeklyGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo semanal'**
  String get editHabitWeeklyGoalTitle;

  /// No description provided for @editHabitWeeklyGoalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Marca cuántas veces quieres completarlo.'**
  String get editHabitWeeklyGoalSubtitle;

  /// No description provided for @editHabitReminderDailyTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificación diaria'**
  String get editHabitReminderDailyTitle;

  /// No description provided for @editHabitReminderDailySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige cuando quieres que te avise'**
  String get editHabitReminderDailySubtitle;

  /// No description provided for @editHabitDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Descripcion breve'**
  String get editHabitDescriptionHint;

  /// No description provided for @editHabitNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Notas o contexto adicional'**
  String get editHabitNotesHint;

  /// No description provided for @editHabitUnitPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get editHabitUnitPickerTitle;

  /// No description provided for @editHabitUnitPickerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige una sugerencia o escribe una personalizada.'**
  String get editHabitUnitPickerSubtitle;

  /// No description provided for @editHabitUnitPickerAction.
  ///
  /// In es, this message translates to:
  /// **'Usar unidad'**
  String get editHabitUnitPickerAction;

  /// No description provided for @editHabitSuggestedUnitGlasses.
  ///
  /// In es, this message translates to:
  /// **'vasos'**
  String get editHabitSuggestedUnitGlasses;

  /// No description provided for @editHabitSuggestedUnitMinutes.
  ///
  /// In es, this message translates to:
  /// **'minutos'**
  String get editHabitSuggestedUnitMinutes;

  /// No description provided for @editHabitSuggestedUnitKilometers.
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get editHabitSuggestedUnitKilometers;

  /// No description provided for @editHabitSuggestedUnitPages.
  ///
  /// In es, this message translates to:
  /// **'paginas'**
  String get editHabitSuggestedUnitPages;

  /// No description provided for @editHabitSuggestedUnitSteps.
  ///
  /// In es, this message translates to:
  /// **'pasos'**
  String get editHabitSuggestedUnitSteps;

  /// No description provided for @editHabitSuggestedUnitRepetitions.
  ///
  /// In es, this message translates to:
  /// **'repeticiones'**
  String get editHabitSuggestedUnitRepetitions;

  /// No description provided for @editHabitSuggestedUnitHours.
  ///
  /// In es, this message translates to:
  /// **'horas'**
  String get editHabitSuggestedUnitHours;

  /// No description provided for @drawerBrandName.
  ///
  /// In es, this message translates to:
  /// **'rutio'**
  String get drawerBrandName;

  /// No description provided for @drawerBrandTagline.
  ///
  /// In es, this message translates to:
  /// **'CONSTRUYE TU CAMINO'**
  String get drawerBrandTagline;

  /// No description provided for @drawerSectionViews.
  ///
  /// In es, this message translates to:
  /// **'VISTAS'**
  String get drawerSectionViews;

  /// No description provided for @drawerDaily.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get drawerDaily;

  /// No description provided for @drawerWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get drawerWeekly;

  /// No description provided for @drawerMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get drawerMonthly;

  /// No description provided for @drawerSectionTracking.
  ///
  /// In es, this message translates to:
  /// **'SEGUIMIENTO'**
  String get drawerSectionTracking;

  /// No description provided for @drawerStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get drawerStatistics;

  /// No description provided for @drawerStatisticsV3.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas V3'**
  String get drawerStatisticsV3;

  /// No description provided for @drawerDiary.
  ///
  /// In es, this message translates to:
  /// **'Diario (Journal)'**
  String get drawerDiary;

  /// No description provided for @drawerSectionArchive.
  ///
  /// In es, this message translates to:
  /// **'ARCHIVO'**
  String get drawerSectionArchive;

  /// No description provided for @drawerArchived.
  ///
  /// In es, this message translates to:
  /// **'Archivados'**
  String get drawerArchived;

  /// No description provided for @drawerSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'CUENTA'**
  String get drawerSectionAccount;

  /// No description provided for @drawerProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get drawerProfile;

  /// No description provided for @drawerProfileVersion.
  ///
  /// In es, this message translates to:
  /// **'v0.1 alpha'**
  String get drawerProfileVersion;

  /// No description provided for @weeklyScreenUnavailableSoon.
  ///
  /// In es, this message translates to:
  /// **'Pantalla no disponible todavía.'**
  String get weeklyScreenUnavailableSoon;

  /// No description provided for @weeklyScreenUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Pantalla no disponible'**
  String get weeklyScreenUnavailable;

  /// No description provided for @weeklyWeekPrefix.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get weeklyWeekPrefix;

  /// No description provided for @weeklyActiveHabitsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} HABITOS ACTIVOS'**
  String weeklyActiveHabitsCount(String count);

  /// No description provided for @weeklyShowHabitNameHint.
  ///
  /// In es, this message translates to:
  /// **'<- toca el emoji para ver el nombre'**
  String get weeklyShowHabitNameHint;

  /// No description provided for @weeklyViewMenuTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar vista'**
  String get weeklyViewMenuTitle;

  /// No description provided for @weeklyViewMenuDailyTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista diaria'**
  String get weeklyViewMenuDailyTitle;

  /// No description provided for @weeklyViewMenuDailySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ver hábitos de hoy'**
  String get weeklyViewMenuDailySubtitle;

  /// No description provided for @weeklyViewMenuWeeklyTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista semanal'**
  String get weeklyViewMenuWeeklyTitle;

  /// No description provided for @weeklyViewMenuWeeklySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get weeklyViewMenuWeeklySubtitle;

  /// No description provided for @weeklyViewMenuMonthlyTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista mensual'**
  String get weeklyViewMenuMonthlyTitle;

  /// No description provided for @weeklyViewMenuMonthlySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ver progreso del mes'**
  String get weeklyViewMenuMonthlySubtitle;

  /// No description provided for @drawerTodo.
  ///
  /// In es, this message translates to:
  /// **'To-do'**
  String get drawerTodo;

  /// No description provided for @familyPersonalName.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get familyPersonalName;

  /// No description provided for @todoTitle.
  ///
  /// In es, this message translates to:
  /// **'To-dos'**
  String get todoTitle;

  /// No description provided for @todoDateTodayFormatLabel.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todoDateTodayFormatLabel;

  /// No description provided for @todoFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get todoFilterAll;

  /// No description provided for @todoFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get todoFilterPending;

  /// No description provided for @todoFilterToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todoFilterToday;

  /// No description provided for @todoFilterThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get todoFilterThisWeek;

  /// No description provided for @todoFilterCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get todoFilterCompleted;

  /// No description provided for @todoProgressToday.
  ///
  /// In es, this message translates to:
  /// **'PROGRESO HOY'**
  String get todoProgressToday;

  /// No description provided for @todoTasksCount.
  ///
  /// In es, this message translates to:
  /// **' / {total} tareas'**
  String todoTasksCount(String total);

  /// No description provided for @todoPendingCount.
  ///
  /// In es, this message translates to:
  /// **'{count} pendientes'**
  String todoPendingCount(int count);

  /// No description provided for @todoOverdueCount.
  ///
  /// In es, this message translates to:
  /// **'{count} vencida'**
  String todoOverdueCount(int count);

  /// No description provided for @todoSectionPending.
  ///
  /// In es, this message translates to:
  /// **'PENDIENTES · {count}'**
  String todoSectionPending(int count);

  /// No description provided for @todoSectionCompleted.
  ///
  /// In es, this message translates to:
  /// **'COMPLETADOS · {count}'**
  String todoSectionCompleted(int count);

  /// No description provided for @todoCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea'**
  String get todoCreateTitle;

  /// No description provided for @todoEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar tarea'**
  String get todoEditTitle;

  /// No description provided for @todoCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get todoCancel;

  /// No description provided for @todoSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get todoSave;

  /// No description provided for @todoTypeFree.
  ///
  /// In es, this message translates to:
  /// **'Tarea libre'**
  String get todoTypeFree;

  /// No description provided for @todoTypeLinkedHabit.
  ///
  /// In es, this message translates to:
  /// **'Vinculada a hábito'**
  String get todoTypeLinkedHabit;

  /// No description provided for @todoWhatNeedToDo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tienes que hacer?'**
  String get todoWhatNeedToDo;

  /// No description provided for @todoDescriptionOptional.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get todoDescriptionOptional;

  /// No description provided for @todoWhen.
  ///
  /// In es, this message translates to:
  /// **'CUÁNDO'**
  String get todoWhen;

  /// No description provided for @todoDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get todoDate;

  /// No description provided for @todoSelect.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get todoSelect;

  /// No description provided for @todoTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get todoTime;

  /// No description provided for @todoNoTime.
  ///
  /// In es, this message translates to:
  /// **'Sin hora'**
  String get todoNoTime;

  /// No description provided for @todoCategory.
  ///
  /// In es, this message translates to:
  /// **'CATEGORÍA'**
  String get todoCategory;

  /// No description provided for @todoPriority.
  ///
  /// In es, this message translates to:
  /// **'PRIORIDAD'**
  String get todoPriority;

  /// No description provided for @todoNotes.
  ///
  /// In es, this message translates to:
  /// **'NOTAS'**
  String get todoNotes;

  /// No description provided for @todoAddNote.
  ///
  /// In es, this message translates to:
  /// **'Añade una nota...'**
  String get todoAddNote;

  /// No description provided for @todoPriorityNone.
  ///
  /// In es, this message translates to:
  /// **'—'**
  String get todoPriorityNone;

  /// No description provided for @todoPriorityNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get todoPriorityNormal;

  /// No description provided for @todoPriorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get todoPriorityHigh;

  /// No description provided for @todoPriorityUrgent.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get todoPriorityUrgent;

  /// No description provided for @todoPriorityHighBadge.
  ///
  /// In es, this message translates to:
  /// **'Prioritaria'**
  String get todoPriorityHighBadge;

  /// No description provided for @todoPriorityUrgentBadge.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get todoPriorityUrgentBadge;

  /// No description provided for @todoXpReward.
  ///
  /// In es, this message translates to:
  /// **'+{xp} XP'**
  String todoXpReward(int xp);

  /// No description provided for @todoStatusOverdueYesterday.
  ///
  /// In es, this message translates to:
  /// **'Vencida ayer'**
  String get todoStatusOverdueYesterday;

  /// No description provided for @todoStatusOverdueDate.
  ///
  /// In es, this message translates to:
  /// **'Vencida {date}'**
  String todoStatusOverdueDate(String date);

  /// No description provided for @todoStatusTodayAt.
  ///
  /// In es, this message translates to:
  /// **'Hoy · {time}'**
  String todoStatusTodayAt(String time);

  /// No description provided for @todoStatusDueToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todoStatusDueToday;

  /// No description provided for @todoStatusThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get todoStatusThisWeek;

  /// No description provided for @todoStatusOnDate.
  ///
  /// In es, this message translates to:
  /// **'{date}'**
  String todoStatusOnDate(String date);

  /// No description provided for @todoMockMeditateTitle.
  ///
  /// In es, this message translates to:
  /// **'Meditar 10 minutos antes de dormir'**
  String get todoMockMeditateTitle;

  /// No description provided for @todoMockReadTitle.
  ///
  /// In es, this message translates to:
  /// **'Leer 20 páginas del libro actual'**
  String get todoMockReadTitle;

  /// No description provided for @todoMockGroceriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparar la lista de la compra semanal'**
  String get todoMockGroceriesTitle;

  /// No description provided for @todoMockDoctorTitle.
  ///
  /// In es, this message translates to:
  /// **'Llamar al médico para pedir cita'**
  String get todoMockDoctorTitle;

  /// No description provided for @todoMockCardioTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio matutino: 30 min cardio'**
  String get todoMockCardioTitle;

  /// No description provided for @todoMockWaterTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparar botella de agua y mochila'**
  String get todoMockWaterTitle;

  /// No description provided for @todoMockReviewGoalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar prioridades clave del día'**
  String get todoMockReviewGoalsTitle;

  /// No description provided for @todoMockEncouragementTitle.
  ///
  /// In es, this message translates to:
  /// **'Enviar un mensaje de ánimo'**
  String get todoMockEncouragementTitle;

  /// No description provided for @todoMockPrayerTitle.
  ///
  /// In es, this message translates to:
  /// **'Momento breve de oración'**
  String get todoMockPrayerTitle;

  /// No description provided for @todoMockInboxTitle.
  ///
  /// In es, this message translates to:
  /// **'Vaciar correos importantes'**
  String get todoMockInboxTitle;

  /// No description provided for @todoMockJournalTitle.
  ///
  /// In es, this message translates to:
  /// **'Journaling emocional de 5 minutos'**
  String get todoMockJournalTitle;

  /// No description provided for @todoEmptyStateTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes tareas'**
  String get todoEmptyStateTitle;

  /// No description provided for @todoEmptyStateBody.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera tarea para empezar a organizar este espacio.'**
  String get todoEmptyStateBody;

  /// No description provided for @todoCreateFirstTask.
  ///
  /// In es, this message translates to:
  /// **'Crear primera tarea'**
  String get todoCreateFirstTask;

  /// No description provided for @diaryFiltersTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get diaryFiltersTitle;

  /// No description provided for @diaryFiltersType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get diaryFiltersType;

  /// No description provided for @diaryFiltersPinnedOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo fijadas'**
  String get diaryFiltersPinnedOnly;

  /// No description provided for @diaryFiltersFamily.
  ///
  /// In es, this message translates to:
  /// **'Familia'**
  String get diaryFiltersFamily;

  /// No description provided for @diaryFiltersApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get diaryFiltersApply;

  /// No description provided for @diaryAfterCompleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábito completado: {habitName}'**
  String diaryAfterCompleteTitle(String habitName);

  /// No description provided for @diaryAfterCompletePrompt.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres añadir una nota rápida?'**
  String get diaryAfterCompletePrompt;

  /// No description provided for @diaryAfterCompleteSkip.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get diaryAfterCompleteSkip;

  /// No description provided for @diaryAfterCompleteWrite.
  ///
  /// In es, this message translates to:
  /// **'Escribir'**
  String get diaryAfterCompleteWrite;

  /// No description provided for @diaryGeneralFamilyName.
  ///
  /// In es, this message translates to:
  /// **'General'**
  String get diaryGeneralFamilyName;

  /// No description provided for @diaryCardTypeHabitShort.
  ///
  /// In es, this message translates to:
  /// **'DÍA'**
  String get diaryCardTypeHabitShort;

  /// No description provided for @diaryCardTypePersonalShort.
  ///
  /// In es, this message translates to:
  /// **'NOTA'**
  String get diaryCardTypePersonalShort;

  /// No description provided for @diaryShowMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get diaryShowMore;

  /// No description provided for @diaryShowLess.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get diaryShowLess;

  /// No description provided for @diaryStreakLabel.
  ///
  /// In es, this message translates to:
  /// **'Racha: {count} día{sufix}'**
  String diaryStreakLabel(int count, String sufix);

  /// No description provided for @diaryEmotionalStreakTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha emocional'**
  String get diaryEmotionalStreakTitle;

  /// No description provided for @diaryDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} día{sufix}'**
  String diaryDaysLabel(int count, String sufix);

  /// No description provided for @monthShortJan.
  ///
  /// In es, this message translates to:
  /// **'Ene'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In es, this message translates to:
  /// **'Feb'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In es, this message translates to:
  /// **'Abr'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In es, this message translates to:
  /// **'May'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In es, this message translates to:
  /// **'Jun'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In es, this message translates to:
  /// **'Jul'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In es, this message translates to:
  /// **'Ago'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In es, this message translates to:
  /// **'Sep'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In es, this message translates to:
  /// **'Oct'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In es, this message translates to:
  /// **'Nov'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In es, this message translates to:
  /// **'Dic'**
  String get monthShortDec;

  /// No description provided for @createHabitNewHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo hábito'**
  String get createHabitNewHabitTitle;

  /// No description provided for @createHabitHeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pequeños pasos, progreso constante.'**
  String get createHabitHeaderSubtitle;

  /// No description provided for @createHabitNameLabel.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE DEL HÁBITO'**
  String get createHabitNameLabel;

  /// No description provided for @createHabitNameHelper.
  ///
  /// In es, this message translates to:
  /// **'Un nombre claro te ayuda a mantener el foco.'**
  String get createHabitNameHelper;

  /// No description provided for @createHabitSectionCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get createHabitSectionCategory;

  /// No description provided for @createHabitSectionTracking.
  ///
  /// In es, this message translates to:
  /// **'Tipo de seguimiento'**
  String get createHabitSectionTracking;

  /// No description provided for @createHabitSectionFrequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get createHabitSectionFrequency;

  /// No description provided for @createHabitTrackingCheckTitle.
  ///
  /// In es, this message translates to:
  /// **'Sí / No'**
  String get createHabitTrackingCheckTitle;

  /// No description provided for @createHabitTrackingCheckSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Complétalo una vez'**
  String get createHabitTrackingCheckSubtitle;

  /// No description provided for @createHabitTrackingCountTitle.
  ///
  /// In es, this message translates to:
  /// **'Contador'**
  String get createHabitTrackingCountTitle;

  /// No description provided for @createHabitTrackingCountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Registra cantidad, minutos, páginas...'**
  String get createHabitTrackingCountSubtitle;

  /// No description provided for @createHabitCounterGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo diario'**
  String get createHabitCounterGoalTitle;

  /// No description provided for @createHabitCounterGoalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Define la cantidad que quieres alcanzar cada día.'**
  String get createHabitCounterGoalSubtitle;

  /// No description provided for @createHabitCounterGoalExamples.
  ///
  /// In es, this message translates to:
  /// **'Ejemplos: 8 vasos, 20 páginas, 30 minutos'**
  String get createHabitCounterGoalExamples;

  /// No description provided for @createHabitCounterTargetAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad objetivo'**
  String get createHabitCounterTargetAmountLabel;

  /// No description provided for @createHabitCounterUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get createHabitCounterUnitLabel;

  /// No description provided for @createHabitCounterQuickUnitsLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidades rápidas'**
  String get createHabitCounterQuickUnitsLabel;

  /// No description provided for @createHabitCounterQuickUnitMinutes.
  ///
  /// In es, this message translates to:
  /// **'minutos'**
  String get createHabitCounterQuickUnitMinutes;

  /// No description provided for @createHabitCounterQuickUnitPages.
  ///
  /// In es, this message translates to:
  /// **'páginas'**
  String get createHabitCounterQuickUnitPages;

  /// No description provided for @createHabitCounterQuickUnitGlasses.
  ///
  /// In es, this message translates to:
  /// **'vasos'**
  String get createHabitCounterQuickUnitGlasses;

  /// No description provided for @createHabitCounterQuickUnitReps.
  ///
  /// In es, this message translates to:
  /// **'reps'**
  String get createHabitCounterQuickUnitReps;

  /// No description provided for @createHabitCounterQuickUnitCustom.
  ///
  /// In es, this message translates to:
  /// **'+ Personalizada'**
  String get createHabitCounterQuickUnitCustom;

  /// No description provided for @createHabitCounterExampleTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo: 10 minutos'**
  String get createHabitCounterExampleTitle;

  /// No description provided for @createHabitCounterExampleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Registra el tiempo total que dedicas a meditar.'**
  String get createHabitCounterExampleSubtitle;

  /// No description provided for @createHabitFrequencyDailyTitle.
  ///
  /// In es, this message translates to:
  /// **'Cada día'**
  String get createHabitFrequencyDailyTitle;

  /// No description provided for @createHabitFrequencyDailySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se repite cada día hasta que lo cambies.'**
  String get createHabitFrequencyDailySubtitle;

  /// No description provided for @createHabitFrequencySpecificTitle.
  ///
  /// In es, this message translates to:
  /// **'Días concretos'**
  String get createHabitFrequencySpecificTitle;

  /// No description provided for @createHabitFrequencySpecificSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige qué días de la semana aparece.'**
  String get createHabitFrequencySpecificSubtitle;

  /// No description provided for @createHabitFrequencyTimesPerWeekTitle.
  ///
  /// In es, this message translates to:
  /// **'X veces por semana'**
  String get createHabitFrequencyTimesPerWeekTitle;

  /// No description provided for @createHabitFrequencyTimesPerWeekSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo semanal flexible. Complétalo cualquier día.'**
  String get createHabitFrequencyTimesPerWeekSubtitle;

  /// No description provided for @createHabitRoutineTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir a rutina'**
  String get createHabitRoutineTitle;

  /// No description provided for @createHabitOptionalPill.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get createHabitOptionalPill;

  /// No description provided for @createHabitRoutineSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Coloca este hábito dentro de una rutina de mañana o noche.'**
  String get createHabitRoutineSubtitle;

  /// No description provided for @createHabitRoutineSheetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige dónde podría vivir este hábito más adelante.'**
  String get createHabitRoutineSheetSubtitle;

  /// No description provided for @createHabitRoutineMorningTitle.
  ///
  /// In es, this message translates to:
  /// **'Ritual de mañana'**
  String get createHabitRoutineMorningTitle;

  /// No description provided for @createHabitRoutineMorningSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza el día con intención.'**
  String get createHabitRoutineMorningSubtitle;

  /// No description provided for @createHabitRoutineDeepFocusTitle.
  ///
  /// In es, this message translates to:
  /// **'Foco profundo'**
  String get createHabitRoutineDeepFocusTitle;

  /// No description provided for @createHabitRoutineDeepFocusSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Agrupa hábitos que te ayudan a concentrarte.'**
  String get createHabitRoutineDeepFocusSubtitle;

  /// No description provided for @createHabitRoutineEveningTitle.
  ///
  /// In es, this message translates to:
  /// **'Cierre del día'**
  String get createHabitRoutineEveningTitle;

  /// No description provided for @createHabitRoutineEveningSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Baja el ritmo y cierra el día.'**
  String get createHabitRoutineEveningSubtitle;

  /// No description provided for @createHabitRoutineSoon.
  ///
  /// In es, this message translates to:
  /// **'Pronto'**
  String get createHabitRoutineSoon;

  /// No description provided for @createHabitRoutineCreateNew.
  ///
  /// In es, this message translates to:
  /// **'Crear nueva rutina'**
  String get createHabitRoutineCreateNew;

  /// No description provided for @createHabitRoutineNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get createHabitRoutineNotNow;

  /// No description provided for @createHabitComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get createHabitComingSoon;

  /// No description provided for @createHabitRoutineComingSoonDialogBody.
  ///
  /// In es, this message translates to:
  /// **'La asignación a rutinas llegará pronto. Puedes guardar este hábito ahora.'**
  String get createHabitRoutineComingSoonDialogBody;

  /// No description provided for @createHabitReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get createHabitReminderTitle;

  /// No description provided for @createHabitReminderEnabledSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio diario'**
  String get createHabitReminderEnabledSubtitle;

  /// No description provided for @createHabitReminderDisabledSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio desactivado'**
  String get createHabitReminderDisabledSubtitle;

  /// No description provided for @createHabitReminderTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hora del recordatorio'**
  String get createHabitReminderTimeTitle;

  /// No description provided for @createHabitDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get createHabitDone;

  /// No description provided for @createHabitSaveHabit.
  ///
  /// In es, this message translates to:
  /// **'Guardar hábito'**
  String get createHabitSaveHabit;

  /// No description provided for @createHabitSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get createHabitSaved;

  /// No description provided for @emojiPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un emoji'**
  String get emojiPickerTitle;

  /// No description provided for @emojiPickerCurrent.
  ///
  /// In es, this message translates to:
  /// **'Actual: {emoji}'**
  String emojiPickerCurrent(String emoji);

  /// No description provided for @emojiPickerBrowseSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Catalogo completo con categorias y busqueda'**
  String get emojiPickerBrowseSubtitle;

  /// No description provided for @emojiPickerNoRecents.
  ///
  /// In es, this message translates to:
  /// **'Tus emojis recientes aparecerán aquí'**
  String get emojiPickerNoRecents;

  /// No description provided for @emojiPickerSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar emoji'**
  String get emojiPickerSearchHint;

  /// No description provided for @monthlyDefaultUsername.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get monthlyDefaultUsername;

  /// No description provided for @monthlyEmptyFilteredMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay hábitos para mostrar en este filtro.'**
  String get monthlyEmptyFilteredMessage;

  /// No description provided for @monthlyElapsedDaysWeek.
  ///
  /// In es, this message translates to:
  /// **'{elapsed} días transcurridos · semana {week}'**
  String monthlyElapsedDaysWeek(int elapsed, int week);

  /// No description provided for @monthlyFilterSummaryFamily.
  ///
  /// In es, this message translates to:
  /// **'Familia: {family}'**
  String monthlyFilterSummaryFamily(String family);

  /// No description provided for @monthlyFilterSummaryHabit.
  ///
  /// In es, this message translates to:
  /// **'Hábito: {habit}'**
  String monthlyFilterSummaryHabit(String habit);

  /// No description provided for @monthlyFilterSummaryAll.
  ///
  /// In es, this message translates to:
  /// **'Todos los hábitos'**
  String get monthlyFilterSummaryAll;

  /// No description provided for @monthlyFiltersTooltip.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get monthlyFiltersTooltip;

  /// No description provided for @monthlyResetTooltip.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get monthlyResetTooltip;

  /// No description provided for @monthlyFiltersTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get monthlyFiltersTitle;

  /// No description provided for @monthlyResetAction.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get monthlyResetAction;

  /// No description provided for @monthlyFilterModeAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get monthlyFilterModeAll;

  /// No description provided for @monthlyFilterModeFamily.
  ///
  /// In es, this message translates to:
  /// **'Familia'**
  String get monthlyFilterModeFamily;

  /// No description provided for @monthlyFilterModeHabit.
  ///
  /// In es, this message translates to:
  /// **'Hábito'**
  String get monthlyFilterModeHabit;

  /// No description provided for @monthlyApplyAction.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get monthlyApplyAction;

  /// No description provided for @monthlySelectHabitLabel.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un hábito'**
  String get monthlySelectHabitLabel;

  /// No description provided for @monthlyHabitSelectorTitle.
  ///
  /// In es, this message translates to:
  /// **'VER HABITO'**
  String get monthlyHabitSelectorTitle;

  /// No description provided for @monthlyHabitFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábito'**
  String get monthlyHabitFallbackTitle;

  /// No description provided for @monthlyStatMonthLabel.
  ///
  /// In es, this message translates to:
  /// **'MES'**
  String get monthlyStatMonthLabel;

  /// No description provided for @monthlyStatStreakLabel.
  ///
  /// In es, this message translates to:
  /// **'RACHA'**
  String get monthlyStatStreakLabel;

  /// No description provided for @monthlyStatHabitsLabel.
  ///
  /// In es, this message translates to:
  /// **'HABITOS'**
  String get monthlyStatHabitsLabel;

  /// No description provided for @monthlyDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} día{sufix}'**
  String monthlyDaysLabel(int count, String sufix);

  /// No description provided for @monthlyCurrentStreakSoft.
  ///
  /// In es, this message translates to:
  /// **'racha actual'**
  String get monthlyCurrentStreakSoft;

  /// No description provided for @monthlyBestStreakSoft.
  ///
  /// In es, this message translates to:
  /// **'mejor racha'**
  String get monthlyBestStreakSoft;

  /// No description provided for @monthlySelectionToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get monthlySelectionToday;

  /// No description provided for @monthlySelectionDone.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get monthlySelectionDone;

  /// No description provided for @monthlySelectionSkipped.
  ///
  /// In es, this message translates to:
  /// **'Saltado'**
  String get monthlySelectionSkipped;

  /// No description provided for @monthlySelectionPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get monthlySelectionPending;

  /// No description provided for @monthlySelectionFuture.
  ///
  /// In es, this message translates to:
  /// **'Futuro'**
  String get monthlySelectionFuture;

  /// No description provided for @monthlySelectionUnscheduled.
  ///
  /// In es, this message translates to:
  /// **'Sin programar'**
  String get monthlySelectionUnscheduled;

  /// No description provided for @monthlySelectionSelected.
  ///
  /// In es, this message translates to:
  /// **'Seleccionado'**
  String get monthlySelectionSelected;

  /// No description provided for @monthlySelectionLabel.
  ///
  /// In es, this message translates to:
  /// **'{day}/{month} · {state}'**
  String monthlySelectionLabel(int day, int month, String state);

  /// No description provided for @monthlyCurrentMonthTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ir a este mes'**
  String get monthlyCurrentMonthTooltip;

  /// No description provided for @monthlyMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Menu'**
  String get monthlyMenuTooltip;

  /// No description provided for @shopTitle.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get shopTitle;

  /// No description provided for @shopHomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mejora tu experiencia Rutio'**
  String get shopHomeSubtitle;

  /// No description provided for @shopExploreTitle.
  ///
  /// In es, this message translates to:
  /// **'Explora'**
  String get shopExploreTitle;

  /// No description provided for @shopExploreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tres accesos rápidos para entrar en la nueva tienda.'**
  String get shopExploreSubtitle;

  /// No description provided for @shopCosmeticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Cosméticos'**
  String get shopCosmeticsTitle;

  /// No description provided for @shopCosmeticsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Fondos, tarjetas de hábitos y tarjetas de usuario con estilo Rutio.'**
  String get shopCosmeticsSubtitle;

  /// No description provided for @shopUtilitiesTitle.
  ///
  /// In es, this message translates to:
  /// **'Utilidades'**
  String get shopUtilitiesTitle;

  /// No description provided for @shopUtilitiesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Boosts y ayudas listas para integrarse más adelante.'**
  String get shopUtilitiesSubtitle;

  /// No description provided for @shopBackpackTitle.
  ///
  /// In es, this message translates to:
  /// **'Mochila'**
  String get shopBackpackTitle;

  /// No description provided for @shopBackpackSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus consumibles'**
  String get shopBackpackSubtitle;

  /// No description provided for @shopCustomizationTitle.
  ///
  /// In es, this message translates to:
  /// **'Personalización'**
  String get shopCustomizationTitle;

  /// No description provided for @shopCustomizationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiona los cosméticos que ya son tuyos'**
  String get shopCustomizationSubtitle;

  /// No description provided for @shopCollectionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Colecciones'**
  String get shopCollectionsTitle;

  /// No description provided for @shopCollectionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cada colección es un pequeño universo'**
  String get shopCollectionsSubtitle;

  /// No description provided for @shopDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle'**
  String get shopDetailTitle;

  /// No description provided for @shopDetailUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle no disponible'**
  String get shopDetailUnavailableTitle;

  /// No description provided for @shopDetailUnavailableMessage.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar este item.'**
  String get shopDetailUnavailableMessage;

  /// No description provided for @shopNoDescriptionYet.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción todavía.'**
  String get shopNoDescriptionYet;

  /// No description provided for @shopEmptyStateNoResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get shopEmptyStateNoResultsTitle;

  /// No description provided for @shopEmptyStateNoResultsMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay resultados para este filtro.'**
  String get shopEmptyStateNoResultsMessage;

  /// No description provided for @shopEmptyBackpackTitle.
  ///
  /// In es, this message translates to:
  /// **'La mochila está vacía'**
  String get shopEmptyBackpackTitle;

  /// No description provided for @shopEmptyBackpackMessage.
  ///
  /// In es, this message translates to:
  /// **'Las utilidades compradas aparecerán aquí.'**
  String get shopEmptyBackpackMessage;

  /// No description provided for @shopEmptyUtilitiesTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada por mostrar'**
  String get shopEmptyUtilitiesTitle;

  /// No description provided for @shopEmptyUtilitiesMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay utilidades disponibles en esta categoría.'**
  String get shopEmptyUtilitiesMessage;

  /// No description provided for @shopEmptyCollectionsTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay colecciones disponibles.'**
  String get shopEmptyCollectionsTitle;

  /// No description provided for @shopEmptyCollectionsMessage.
  ///
  /// In es, this message translates to:
  /// **'Vuelve más tarde para descubrir nuevas colecciones.'**
  String get shopEmptyCollectionsMessage;

  /// No description provided for @shopActionBuy.
  ///
  /// In es, this message translates to:
  /// **'Comprar'**
  String get shopActionBuy;

  /// No description provided for @shopActionBuyPack.
  ///
  /// In es, this message translates to:
  /// **'Comprar pack'**
  String get shopActionBuyPack;

  /// No description provided for @shopActionActivate.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get shopActionActivate;

  /// No description provided for @shopActionOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get shopActionOpen;

  /// No description provided for @shopActionContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get shopActionContinue;

  /// No description provided for @shopActionUse.
  ///
  /// In es, this message translates to:
  /// **'Usar'**
  String get shopActionUse;

  /// No description provided for @shopActionAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get shopActionAccept;

  /// No description provided for @shopActionEquip.
  ///
  /// In es, this message translates to:
  /// **'Equipar'**
  String get shopActionEquip;

  /// No description provided for @shopActionEquipped.
  ///
  /// In es, this message translates to:
  /// **'Equipado'**
  String get shopActionEquipped;

  /// No description provided for @shopActionAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get shopActionAvailable;

  /// No description provided for @shopActionActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get shopActionActive;

  /// No description provided for @shopStatusPurchased.
  ///
  /// In es, this message translates to:
  /// **'Comprado'**
  String get shopStatusPurchased;

  /// No description provided for @shopStatusBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get shopStatusBlocked;

  /// No description provided for @shopStatusIncludedInPack.
  ///
  /// In es, this message translates to:
  /// **'Incluido en pack'**
  String get shopStatusIncludedInPack;

  /// No description provided for @shopStatusInsufficientCoins.
  ///
  /// In es, this message translates to:
  /// **'Saldo insuficiente'**
  String get shopStatusInsufficientCoins;

  /// No description provided for @shopStatusProcessing.
  ///
  /// In es, this message translates to:
  /// **'Procesando...'**
  String get shopStatusProcessing;

  /// No description provided for @shopStatusBusyOpening.
  ///
  /// In es, this message translates to:
  /// **'Abriendo...'**
  String get shopStatusBusyOpening;

  /// No description provided for @shopRarityCommon.
  ///
  /// In es, this message translates to:
  /// **'Común'**
  String get shopRarityCommon;

  /// No description provided for @shopRarityUncommon.
  ///
  /// In es, this message translates to:
  /// **'Poco común'**
  String get shopRarityUncommon;

  /// No description provided for @shopRarityRare.
  ///
  /// In es, this message translates to:
  /// **'Raro'**
  String get shopRarityRare;

  /// No description provided for @shopRarityEpic.
  ///
  /// In es, this message translates to:
  /// **'Épico'**
  String get shopRarityEpic;

  /// No description provided for @shopRarityLegendary.
  ///
  /// In es, this message translates to:
  /// **'Legendario'**
  String get shopRarityLegendary;

  /// No description provided for @shopFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get shopFilterAll;

  /// No description provided for @shopFilterBoosts.
  ///
  /// In es, this message translates to:
  /// **'Boosts'**
  String get shopFilterBoosts;

  /// No description provided for @shopFilterStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha'**
  String get shopFilterStreak;

  /// No description provided for @shopFilterBoxes.
  ///
  /// In es, this message translates to:
  /// **'Cajas'**
  String get shopFilterBoxes;

  /// No description provided for @shopFilterWallpapers.
  ///
  /// In es, this message translates to:
  /// **'Fondos'**
  String get shopFilterWallpapers;

  /// No description provided for @shopFilterCards.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas'**
  String get shopFilterCards;

  /// No description provided for @shopFilterPacks.
  ///
  /// In es, this message translates to:
  /// **'Packs'**
  String get shopFilterPacks;

  /// No description provided for @shopCategoryPack.
  ///
  /// In es, this message translates to:
  /// **'Pack'**
  String get shopCategoryPack;

  /// No description provided for @shopCategoryWallpaper.
  ///
  /// In es, this message translates to:
  /// **'Fondo'**
  String get shopCategoryWallpaper;

  /// No description provided for @shopCategoryHabitCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de hábitos'**
  String get shopCategoryHabitCard;

  /// No description provided for @shopCategoryUserCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de usuario'**
  String get shopCategoryUserCard;

  /// No description provided for @shopCategoryUtility.
  ///
  /// In es, this message translates to:
  /// **'Utilidad'**
  String get shopCategoryUtility;

  /// No description provided for @shopCategoryBoosts.
  ///
  /// In es, this message translates to:
  /// **'Boosts'**
  String get shopCategoryBoosts;

  /// No description provided for @shopCategoryStreaks.
  ///
  /// In es, this message translates to:
  /// **'Rachas'**
  String get shopCategoryStreaks;

  /// No description provided for @shopCategoryBoxes.
  ///
  /// In es, this message translates to:
  /// **'Cajas'**
  String get shopCategoryBoxes;

  /// No description provided for @shopPriceCoins.
  ///
  /// In es, this message translates to:
  /// **'{value} monedas'**
  String shopPriceCoins(int value);

  /// No description provided for @shopPriceAmber.
  ///
  /// In es, this message translates to:
  /// **'{value} ámbar'**
  String shopPriceAmber(int value);

  /// No description provided for @shopRemainingUses.
  ///
  /// In es, this message translates to:
  /// **'{remaining} de {total} completaciones'**
  String shopRemainingUses(int remaining, int total);

  /// No description provided for @shopOwnedCount.
  ///
  /// In es, this message translates to:
  /// **'{count} objetos'**
  String shopOwnedCount(int count);

  /// No description provided for @shopBackpackCount.
  ///
  /// In es, this message translates to:
  /// **'Mochila x{count}'**
  String shopBackpackCount(int count);

  /// No description provided for @shopXpBoostTitle.
  ///
  /// In es, this message translates to:
  /// **'Potenciador de XP de 1 día'**
  String get shopXpBoostTitle;

  /// No description provided for @shopXpBoostDescription.
  ///
  /// In es, this message translates to:
  /// **'Aumenta temporalmente la experiencia obtenida al completar hábitos.'**
  String get shopXpBoostDescription;

  /// No description provided for @shopXpBoostEffect.
  ///
  /// In es, this message translates to:
  /// **'Multiplicador de XP x2'**
  String get shopXpBoostEffect;

  /// No description provided for @shopCoinBoostTitle.
  ///
  /// In es, this message translates to:
  /// **'Potenciador de monedas de 1 día'**
  String get shopCoinBoostTitle;

  /// No description provided for @shopCoinBoostDescription.
  ///
  /// In es, this message translates to:
  /// **'Aumenta temporalmente las monedas obtenidas al completar hábitos.'**
  String get shopCoinBoostDescription;

  /// No description provided for @shopCoinBoostEffect.
  ///
  /// In es, this message translates to:
  /// **'Multiplicador de monedas x2'**
  String get shopCoinBoostEffect;

  /// No description provided for @shopStreakRecoverTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperación de racha'**
  String get shopStreakRecoverTitle;

  /// No description provided for @shopStreakRecoverDescription.
  ///
  /// In es, this message translates to:
  /// **'Recupera una racha perdida una vez.'**
  String get shopStreakRecoverDescription;

  /// No description provided for @shopStreakRecoverEffect.
  ///
  /// In es, this message translates to:
  /// **'Recuperación de racha'**
  String get shopStreakRecoverEffect;

  /// No description provided for @shopStreakShieldTitle.
  ///
  /// In es, this message translates to:
  /// **'Escudo de racha'**
  String get shopStreakShieldTitle;

  /// No description provided for @shopStreakShieldDescription.
  ///
  /// In es, this message translates to:
  /// **'Protege una racha frente a un día fallado.'**
  String get shopStreakShieldDescription;

  /// No description provided for @shopStreakShieldEffect.
  ///
  /// In es, this message translates to:
  /// **'Protección de racha'**
  String get shopStreakShieldEffect;

  /// No description provided for @shopMysteryBoxTitle.
  ///
  /// In es, this message translates to:
  /// **'Caja misteriosa'**
  String get shopMysteryBoxTitle;

  /// No description provided for @shopMysteryBoxDescription.
  ///
  /// In es, this message translates to:
  /// **'Una caja misteriosa básica con una sorpresa en su interior.'**
  String get shopMysteryBoxDescription;

  /// No description provided for @shopMysteryBoxEffect.
  ///
  /// In es, this message translates to:
  /// **'Sorpresa futura'**
  String get shopMysteryBoxEffect;

  /// No description provided for @shopUtilityDurationHours.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 hora} other{{count} horas}}'**
  String shopUtilityDurationHours(int count);

  /// No description provided for @shopUtilityCharges.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 uso} other{{count} usos}}'**
  String shopUtilityCharges(int count);

  /// No description provided for @shopMysteryBoxOpeningTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu Mystery Box está lista'**
  String get shopMysteryBoxOpeningTitle;

  /// No description provided for @shopMysteryBoxTapToOpen.
  ///
  /// In es, this message translates to:
  /// **'Pulsa para abrir'**
  String get shopMysteryBoxTapToOpen;

  /// No description provided for @shopMysteryBoxOpenButton.
  ///
  /// In es, this message translates to:
  /// **'Abrir Mystery Box'**
  String get shopMysteryBoxOpenButton;

  /// No description provided for @shopMysteryBoxRewardTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu recompensa'**
  String get shopMysteryBoxRewardTitle;

  /// No description provided for @shopMysteryBoxRewardContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get shopMysteryBoxRewardContinue;

  /// No description provided for @shopMysteryBoxRewardDescription.
  ///
  /// In es, this message translates to:
  /// **'La apertura ha terminado. Todo ya está guardado en tu cuenta y en tu mochila.'**
  String get shopMysteryBoxRewardDescription;

  /// No description provided for @shopMysteryBoxErrorNoBoxes.
  ///
  /// In es, this message translates to:
  /// **'No quedan Mystery Boxes disponibles.'**
  String get shopMysteryBoxErrorNoBoxes;

  /// No description provided for @shopMysteryBoxErrorConfig.
  ///
  /// In es, this message translates to:
  /// **'La Mystery Box no está configurada correctamente.'**
  String get shopMysteryBoxErrorConfig;

  /// No description provided for @shopMysteryBoxErrorPersist.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar la apertura. Inténtalo otra vez.'**
  String get shopMysteryBoxErrorPersist;

  /// No description provided for @shopMysteryBoxErrorPending.
  ///
  /// In es, this message translates to:
  /// **'Ya hay una apertura pendiente para esta Mystery Box.'**
  String get shopMysteryBoxErrorPending;

  /// No description provided for @shopMysteryBoxErrorOpen.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la apertura. Inténtalo otra vez.'**
  String get shopMysteryBoxErrorOpen;

  /// No description provided for @shopMysteryBoxErrorReward.
  ///
  /// In es, this message translates to:
  /// **'No pudimos mostrar la recompensa.'**
  String get shopMysteryBoxErrorReward;

  /// No description provided for @shopCollectionMinimalTitle.
  ///
  /// In es, this message translates to:
  /// **'Minimal'**
  String get shopCollectionMinimalTitle;

  /// No description provided for @shopCollectionMinimalDescription.
  ///
  /// In es, this message translates to:
  /// **'Colores planos y familias suaves para una base calmada.'**
  String get shopCollectionMinimalDescription;

  /// No description provided for @shopCollectionGradientTitle.
  ///
  /// In es, this message translates to:
  /// **'Gradient'**
  String get shopCollectionGradientTitle;

  /// No description provided for @shopCollectionGradientDescription.
  ///
  /// In es, this message translates to:
  /// **'Texturas y degradados sutiles con identidad editorial.'**
  String get shopCollectionGradientDescription;

  /// No description provided for @shopCollectionLandscapeTitle.
  ///
  /// In es, this message translates to:
  /// **'Landscape'**
  String get shopCollectionLandscapeTitle;

  /// No description provided for @shopCollectionLandscapeDescription.
  ///
  /// In es, this message translates to:
  /// **'Composiciones con más presencia visual y profundidad suave.'**
  String get shopCollectionLandscapeDescription;

  /// No description provided for @shopConfirmPurchaseTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar compra'**
  String get shopConfirmPurchaseTitle;

  /// No description provided for @shopCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get shopCancel;

  /// No description provided for @shopPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get shopPriceLabel;

  /// No description provided for @shopCurrentBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo actual'**
  String get shopCurrentBalanceLabel;

  /// No description provided for @shopRemainingBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo restante'**
  String get shopRemainingBalanceLabel;

  /// No description provided for @shopCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get shopCategoryLabel;

  /// No description provided for @shopOriginalPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio original'**
  String get shopOriginalPriceLabel;

  /// No description provided for @shopSavingsLabel.
  ///
  /// In es, this message translates to:
  /// **'Ahorro'**
  String get shopSavingsLabel;

  /// No description provided for @shopIncludesLabel.
  ///
  /// In es, this message translates to:
  /// **'Incluye'**
  String get shopIncludesLabel;

  /// No description provided for @shopRarityLabel.
  ///
  /// In es, this message translates to:
  /// **'Rareza'**
  String get shopRarityLabel;

  /// No description provided for @shopTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get shopTypeLabel;

  /// No description provided for @shopStyleLabel.
  ///
  /// In es, this message translates to:
  /// **'Estilo'**
  String get shopStyleLabel;

  /// No description provided for @shopStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get shopStatusLabel;

  /// No description provided for @shopDurationLabel.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get shopDurationLabel;

  /// No description provided for @shopEffectLabel.
  ///
  /// In es, this message translates to:
  /// **'Efecto'**
  String get shopEffectLabel;

  /// No description provided for @shopProcessingLabel.
  ///
  /// In es, this message translates to:
  /// **'Procesando...'**
  String get shopProcessingLabel;

  /// No description provided for @shopBackpackEmptyAction.
  ///
  /// In es, this message translates to:
  /// **'Ir a Utilidades'**
  String get shopBackpackEmptyAction;

  /// No description provided for @shopBackpackActiveEffectsTitle.
  ///
  /// In es, this message translates to:
  /// **'Efectos activos'**
  String get shopBackpackActiveEffectsTitle;

  /// No description provided for @shopBackpackActiveEffectsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes efectos activos.'**
  String get shopBackpackActiveEffectsEmpty;

  /// No description provided for @shopBackpackActiveEffectsActiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get shopBackpackActiveEffectsActiveLabel;

  /// No description provided for @shopBackpackActiveEffectsProgressLabel.
  ///
  /// In es, this message translates to:
  /// **'{remaining} de {total} usos restantes'**
  String shopBackpackActiveEffectsProgressLabel(int remaining, int total);

  /// No description provided for @shopHomeHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu espacio, más tuyo'**
  String get shopHomeHeroTitle;

  /// No description provided for @shopHomeHeroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Combina fondos, cards y estilo Rutio'**
  String get shopHomeHeroSubtitle;

  /// No description provided for @shopHomeHeroBackpackTitle.
  ///
  /// In es, this message translates to:
  /// **'Mochila'**
  String get shopHomeHeroBackpackTitle;

  /// No description provided for @shopHomeHeroBackpackSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus objetos'**
  String get shopHomeHeroBackpackSubtitle;

  /// No description provided for @shopHomeHeroCustomizationTitle.
  ///
  /// In es, this message translates to:
  /// **'Personalizar'**
  String get shopHomeHeroCustomizationTitle;

  /// No description provided for @shopHomeHeroCustomizationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu estilo'**
  String get shopHomeHeroCustomizationSubtitle;

  /// No description provided for @shopCollectionStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get shopCollectionStatusCompleted;

  /// No description provided for @shopCollectionStatusStarted.
  ///
  /// In es, this message translates to:
  /// **'Empezada'**
  String get shopCollectionStatusStarted;

  /// No description provided for @shopCollectionStatusNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva'**
  String get shopCollectionStatusNew;

  /// No description provided for @shopCollectionStatusBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueada'**
  String get shopCollectionStatusBlocked;

  /// No description provided for @shopCollectionItemsLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} objetos'**
  String shopCollectionItemsLabel(int count);

  /// No description provided for @shopCollectionViewCollection.
  ///
  /// In es, this message translates to:
  /// **'Ver colección'**
  String get shopCollectionViewCollection;

  /// No description provided for @pnGeneralMorningGentle01Title.
  ///
  /// In es, this message translates to:
  /// **'Rutio sigue aquí'**
  String get pnGeneralMorningGentle01Title;

  /// No description provided for @pnGeneralMorningGentle01Body.
  ///
  /// In es, this message translates to:
  /// **'Empieza a tu ritmo. Un paso pequeño también cuenta.'**
  String get pnGeneralMorningGentle01Body;

  /// No description provided for @pnGeneralMorningGentle02Title.
  ///
  /// In es, this message translates to:
  /// **'Un comienzo tranquilo'**
  String get pnGeneralMorningGentle02Title;

  /// No description provided for @pnGeneralMorningGentle02Body.
  ///
  /// In es, this message translates to:
  /// **'Hoy puedes volver a empezar sin prisa.'**
  String get pnGeneralMorningGentle02Body;

  /// No description provided for @pnGeneralMorningGentle02BodyWithName.
  ///
  /// In es, this message translates to:
  /// **'{displayName}, hoy puedes volver a empezar sin prisa.'**
  String pnGeneralMorningGentle02BodyWithName(String displayName);

  /// No description provided for @pnGeneralMorningFocus01Title.
  ///
  /// In es, this message translates to:
  /// **'Una intención para hoy'**
  String get pnGeneralMorningFocus01Title;

  /// No description provided for @pnGeneralMorningFocus01Body.
  ///
  /// In es, this message translates to:
  /// **'{weekday} puede empezar con algo sencillo y valioso.'**
  String pnGeneralMorningFocus01Body(String weekday);

  /// No description provided for @pnGeneralMotivationGentle01Title.
  ///
  /// In es, this message translates to:
  /// **'Sigue a tu manera'**
  String get pnGeneralMotivationGentle01Title;

  /// No description provided for @pnGeneralMotivationGentle01Body.
  ///
  /// In es, this message translates to:
  /// **'No hace falta hacerlo perfecto para seguir avanzando.'**
  String get pnGeneralMotivationGentle01Body;

  /// No description provided for @pnGeneralMotivationGentle02Title.
  ///
  /// In es, this message translates to:
  /// **'Un recordatorio amable'**
  String get pnGeneralMotivationGentle02Title;

  /// No description provided for @pnGeneralMotivationGentle02Body.
  ///
  /// In es, this message translates to:
  /// **'Lo importante hoy es no perder el hilo.'**
  String get pnGeneralMotivationGentle02Body;

  /// No description provided for @pnGeneralMotivationGentle02BodyWithName.
  ///
  /// In es, this message translates to:
  /// **'{displayName}, lo importante hoy es no perder el hilo.'**
  String pnGeneralMotivationGentle02BodyWithName(String displayName);

  /// No description provided for @pnGeneralPendingProgress01Title.
  ///
  /// In es, this message translates to:
  /// **'Aún hay margen'**
  String get pnGeneralPendingProgress01Title;

  /// No description provided for @pnGeneralPendingProgress01Body.
  ///
  /// In es, this message translates to:
  /// **'Te quedan {pendingCount} cosas por cerrar hoy, sin presión.'**
  String pnGeneralPendingProgress01Body(int pendingCount);

  /// No description provided for @pnGeneralPendingProgress02Title.
  ///
  /// In es, this message translates to:
  /// **'Tu día sigue abierto'**
  String get pnGeneralPendingProgress02Title;

  /// No description provided for @pnGeneralPendingProgress02Body.
  ///
  /// In es, this message translates to:
  /// **'Quedan {pendingCount} de {totalCount}. Si te encaja, todavía puedes sumar una más.'**
  String pnGeneralPendingProgress02Body(int pendingCount, int totalCount);

  /// No description provided for @pnGeneralPendingProgress03Title.
  ///
  /// In es, this message translates to:
  /// **'Vas construyendo'**
  String get pnGeneralPendingProgress03Title;

  /// No description provided for @pnGeneralPendingProgress03Body.
  ///
  /// In es, this message translates to:
  /// **'Hoy ya llevas {progress}. Un paso más también sería una buena señal.'**
  String pnGeneralPendingProgress03Body(String progress);

  /// No description provided for @pnGeneralStrongProgress01Title.
  ///
  /// In es, this message translates to:
  /// **'Buen ritmo'**
  String get pnGeneralStrongProgress01Title;

  /// No description provided for @pnGeneralStrongProgress01Body.
  ///
  /// In es, this message translates to:
  /// **'Ese {progress} ya dice mucho de tu constancia de hoy.'**
  String pnGeneralStrongProgress01Body(String progress);

  /// No description provided for @pnGeneralStrongProgress02Title.
  ///
  /// In es, this message translates to:
  /// **'Se nota el avance'**
  String get pnGeneralStrongProgress02Title;

  /// No description provided for @pnGeneralStrongProgress02Body.
  ///
  /// In es, this message translates to:
  /// **'Llevas {completedCount} de {totalCount}. Vas dejando huella en el día.'**
  String pnGeneralStrongProgress02Body(int completedCount, int totalCount);

  /// No description provided for @pnGeneralCompletedDay01Title.
  ///
  /// In es, this message translates to:
  /// **'Día bien cuidado'**
  String get pnGeneralCompletedDay01Title;

  /// No description provided for @pnGeneralCompletedDay01Body.
  ///
  /// In es, this message translates to:
  /// **'Hoy ya has completado {completedCount}. Eso también merece un momento de reconocimiento.'**
  String pnGeneralCompletedDay01Body(int completedCount);

  /// No description provided for @pnGeneralCompletedDay02Title.
  ///
  /// In es, this message translates to:
  /// **'Cierre con calma'**
  String get pnGeneralCompletedDay02Title;

  /// No description provided for @pnGeneralCompletedDay02Body.
  ///
  /// In es, this message translates to:
  /// **'Con {progress} a las {timeOfDay}, tu día ya tiene forma.'**
  String pnGeneralCompletedDay02Body(String progress, String timeOfDay);

  /// No description provided for @pnGeneralStreakEncouragement01Title.
  ///
  /// In es, this message translates to:
  /// **'Tu racha importa'**
  String get pnGeneralStreakEncouragement01Title;

  /// No description provided for @pnGeneralStreakEncouragement01Body.
  ///
  /// In es, this message translates to:
  /// **'Llevas {streak} días seguidos. Aún estás a tiempo de cuidarla hoy.'**
  String pnGeneralStreakEncouragement01Body(int streak);

  /// No description provided for @pnGeneralStreakEncouragement02Title.
  ///
  /// In es, this message translates to:
  /// **'Constancia que se nota'**
  String get pnGeneralStreakEncouragement02Title;

  /// No description provided for @pnGeneralStreakEncouragement02Body.
  ///
  /// In es, this message translates to:
  /// **'{displayName}, ya son {streak} días. Hoy puede ser otro paso tranquilo.'**
  String pnGeneralStreakEncouragement02Body(String displayName, int streak);

  /// No description provided for @pnGeneralComebackGentle01Title.
  ///
  /// In es, this message translates to:
  /// **'Cuando quieras volver'**
  String get pnGeneralComebackGentle01Title;

  /// No description provided for @pnGeneralComebackGentle01Body.
  ///
  /// In es, this message translates to:
  /// **'Rutio sigue en el mismo sitio. Puedes retomar desde donde te nazca.'**
  String get pnGeneralComebackGentle01Body;

  /// No description provided for @pnGeneralComebackGentle02Title.
  ///
  /// In es, this message translates to:
  /// **'Sin empezar de cero'**
  String get pnGeneralComebackGentle02Title;

  /// No description provided for @pnGeneralComebackGentle02Body.
  ///
  /// In es, this message translates to:
  /// **'Aquí sigues teniendo un lugar para volver con calma.'**
  String get pnGeneralComebackGentle02Body;

  /// No description provided for @pnGeneralComebackGentle02BodyWithName.
  ///
  /// In es, this message translates to:
  /// **'{displayName}, aquí sigues teniendo un lugar para volver con calma.'**
  String pnGeneralComebackGentle02BodyWithName(String displayName);

  /// No description provided for @pnGeneralReflectionPrompt01Title.
  ///
  /// In es, this message translates to:
  /// **'Un minuto para mirar el día'**
  String get pnGeneralReflectionPrompt01Title;

  /// No description provided for @pnGeneralReflectionPrompt01Body.
  ///
  /// In es, this message translates to:
  /// **'Quizá te venga bien dejar una nota sobre cómo ha ido hoy.'**
  String get pnGeneralReflectionPrompt01Body;

  /// No description provided for @pnGeneralReflectionPrompt02Title.
  ///
  /// In es, this message translates to:
  /// **'Tu día también merece palabras'**
  String get pnGeneralReflectionPrompt02Title;

  /// No description provided for @pnGeneralReflectionPrompt02Body.
  ///
  /// In es, this message translates to:
  /// **'Si te apetece, puedes dejar por escrito lo que hoy te dejó.'**
  String get pnGeneralReflectionPrompt02Body;

  /// No description provided for @pnGeneralReflectionPrompt02BodyWithName.
  ///
  /// In es, this message translates to:
  /// **'{displayName}, si te apetece, puedes dejar por escrito lo que hoy te dejó.'**
  String pnGeneralReflectionPrompt02BodyWithName(String displayName);

  /// No description provided for @pnGeneralConsistencyGentle01Title.
  ///
  /// In es, this message translates to:
  /// **'La constancia se está notando'**
  String get pnGeneralConsistencyGentle01Title;

  /// No description provided for @pnGeneralConsistencyGentle01Body.
  ///
  /// In es, this message translates to:
  /// **'{streak} días seguidos no aparecen por casualidad.'**
  String pnGeneralConsistencyGentle01Body(int streak);

  /// No description provided for @pnGeneralConsistencyGentle02Title.
  ///
  /// In es, this message translates to:
  /// **'Paso a paso'**
  String get pnGeneralConsistencyGentle02Title;

  /// No description provided for @pnGeneralConsistencyGentle02Body.
  ///
  /// In es, this message translates to:
  /// **'Ese {progress} encaja con una rutina que ya va tomando forma.'**
  String pnGeneralConsistencyGentle02Body(String progress);

  /// No description provided for @pnGeneralEncouragementNeutral01Title.
  ///
  /// In es, this message translates to:
  /// **'Sigue sumando'**
  String get pnGeneralEncouragementNeutral01Title;

  /// No description provided for @pnGeneralEncouragementNeutral01Body.
  ///
  /// In es, this message translates to:
  /// **'No hace falta correr. Lo importante es seguir en contacto con lo que te importa.'**
  String get pnGeneralEncouragementNeutral01Body;

  /// No description provided for @pnGeneralEncouragementNeutral02Title.
  ///
  /// In es, this message translates to:
  /// **'Todavía cuenta'**
  String get pnGeneralEncouragementNeutral02Title;

  /// No description provided for @pnGeneralEncouragementNeutral02Body.
  ///
  /// In es, this message translates to:
  /// **'Aunque el día vaya rápido, aún puedes guardar un pequeño espacio para ti.'**
  String get pnGeneralEncouragementNeutral02Body;

  /// No description provided for @pnGeneralEncouragementNeutral02BodyWithName.
  ///
  /// In es, this message translates to:
  /// **'{displayName}, aunque el día vaya rápido, aún puedes guardar un pequeño espacio para ti.'**
  String pnGeneralEncouragementNeutral02BodyWithName(String displayName);

  /// No description provided for @pnGeneralProgressHabit01Title.
  ///
  /// In es, this message translates to:
  /// **'Un hábito que sigue vivo'**
  String get pnGeneralProgressHabit01Title;

  /// No description provided for @pnGeneralProgressHabit01Body.
  ///
  /// In es, this message translates to:
  /// **'{habitName} ya va en {progress}. Va cogiendo continuidad.'**
  String pnGeneralProgressHabit01Body(String habitName, String progress);

  /// No description provided for @pnGeneralEncouragementWeekday01Title.
  ///
  /// In es, this message translates to:
  /// **'Aún queda día'**
  String get pnGeneralEncouragementWeekday01Title;

  /// No description provided for @pnGeneralEncouragementWeekday01Body.
  ///
  /// In es, this message translates to:
  /// **'Si {weekday} te deja un hueco hacia las {timeOfDay}, puede ser un buen momento para volver a ti.'**
  String pnGeneralEncouragementWeekday01Body(String weekday, String timeOfDay);

  /// No description provided for @pnGeneralReflectionProgress01Title.
  ///
  /// In es, this message translates to:
  /// **'El día ya tiene historia'**
  String get pnGeneralReflectionProgress01Title;

  /// No description provided for @pnGeneralReflectionProgress01Body.
  ///
  /// In es, this message translates to:
  /// **'Has cerrado {completedCount} de {totalCount}. Quizá apetezca mirar qué te ayudó hoy.'**
  String pnGeneralReflectionProgress01Body(int completedCount, int totalCount);

  /// No description provided for @pnGeneralConsistencyName01Title.
  ///
  /// In es, this message translates to:
  /// **'Tu ritmo cuenta'**
  String get pnGeneralConsistencyName01Title;

  /// No description provided for @pnGeneralConsistencyName01Body.
  ///
  /// In es, this message translates to:
  /// **'{displayName}, ese {progress} habla de una constancia muy tuya.'**
  String pnGeneralConsistencyName01Body(String displayName, String progress);

  /// No description provided for @pnJournalNudgeMilestone7Insight01Title.
  ///
  /// In es, this message translates to:
  /// **'Primeras señales'**
  String get pnJournalNudgeMilestone7Insight01Title;

  /// No description provided for @pnJournalNudgeMilestone7Insight01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te ayudó a empezar y volver esta semana?'**
  String get pnJournalNudgeMilestone7Insight01Body;

  /// No description provided for @pnJournalNudgeMilestone7Change01Title.
  ///
  /// In es, this message translates to:
  /// **'Un comienzo que cambia'**
  String get pnJournalNudgeMilestone7Change01Title;

  /// No description provided for @pnJournalNudgeMilestone7Change01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué notas distinto después de estos primeros días?'**
  String get pnJournalNudgeMilestone7Change01Body;

  /// No description provided for @pnJournalNudgeMilestone7Ease01Title.
  ///
  /// In es, this message translates to:
  /// **'Tu forma de volver'**
  String get pnJournalNudgeMilestone7Ease01Title;

  /// No description provided for @pnJournalNudgeMilestone7Ease01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hizo más fácil retomar el hábito?'**
  String get pnJournalNudgeMilestone7Ease01Body;

  /// No description provided for @pnJournalNudgeMilestone7Return01Title.
  ///
  /// In es, this message translates to:
  /// **'Algo empieza a funcionar'**
  String get pnJournalNudgeMilestone7Return01Title;

  /// No description provided for @pnJournalNudgeMilestone7Return01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué parece estar funcionando para ti?'**
  String get pnJournalNudgeMilestone7Return01Body;

  /// No description provided for @pnJournalNudgeMilestone7Memory01Title.
  ///
  /// In es, this message translates to:
  /// **'Guarda este comienzo'**
  String get pnJournalNudgeMilestone7Memory01Title;

  /// No description provided for @pnJournalNudgeMilestone7Memory01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría recordar de esta primera semana?'**
  String get pnJournalNudgeMilestone7Memory01Body;

  /// No description provided for @pnJournalNudgeMilestone14Insight01Title.
  ///
  /// In es, this message translates to:
  /// **'Patrones que aparecen'**
  String get pnJournalNudgeMilestone14Insight01Title;

  /// No description provided for @pnJournalNudgeMilestone14Insight01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué patrón empiezas a reconocer en estas dos semanas?'**
  String get pnJournalNudgeMilestone14Insight01Body;

  /// No description provided for @pnJournalNudgeMilestone14Change01Title.
  ///
  /// In es, this message translates to:
  /// **'Cada vez más natural'**
  String get pnJournalNudgeMilestone14Change01Title;

  /// No description provided for @pnJournalNudgeMilestone14Change01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué parte del hábito empieza a salirte sin pensarlo tanto?'**
  String get pnJournalNudgeMilestone14Change01Body;

  /// No description provided for @pnJournalNudgeMilestone14Ease01Title.
  ///
  /// In es, this message translates to:
  /// **'Lo que te sostiene'**
  String get pnJournalNudgeMilestone14Ease01Title;

  /// No description provided for @pnJournalNudgeMilestone14Ease01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te ha ayudado a mantener el hábito estos días?'**
  String get pnJournalNudgeMilestone14Ease01Body;

  /// No description provided for @pnJournalNudgeMilestone14Return01Title.
  ///
  /// In es, this message translates to:
  /// **'Una forma que se consolida'**
  String get pnJournalNudgeMilestone14Return01Title;

  /// No description provided for @pnJournalNudgeMilestone14Return01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué has aprendido sobre tu manera de volver?'**
  String get pnJournalNudgeMilestone14Return01Body;

  /// No description provided for @pnJournalNudgeMilestone14Memory01Title.
  ///
  /// In es, this message translates to:
  /// **'Dos semanas en perspectiva'**
  String get pnJournalNudgeMilestone14Memory01Title;

  /// No description provided for @pnJournalNudgeMilestone14Memory01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué empieza a consolidarse en tu rutina?'**
  String get pnJournalNudgeMilestone14Memory01Body;

  /// No description provided for @pnJournalNudgeMilestone30Insight01Title.
  ///
  /// In es, this message translates to:
  /// **'Un mes de perspectiva'**
  String get pnJournalNudgeMilestone30Insight01Title;

  /// No description provided for @pnJournalNudgeMilestone30Insight01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué cambio ves al mirar atrás un mes?'**
  String get pnJournalNudgeMilestone30Insight01Body;

  /// No description provided for @pnJournalNudgeMilestone30Change01Title.
  ///
  /// In es, this message translates to:
  /// **'Ya forma parte de tus días'**
  String get pnJournalNudgeMilestone30Change01Title;

  /// No description provided for @pnJournalNudgeMilestone30Change01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué empieza a formar parte de tu rutina?'**
  String get pnJournalNudgeMilestone30Change01Body;

  /// No description provided for @pnJournalNudgeMilestone30Ease01Title.
  ///
  /// In es, this message translates to:
  /// **'Lo que has aprendido'**
  String get pnJournalNudgeMilestone30Ease01Title;

  /// No description provided for @pnJournalNudgeMilestone30Ease01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué has aprendido sobre lo que te ayuda a mantenerlo?'**
  String get pnJournalNudgeMilestone30Ease01Body;

  /// No description provided for @pnJournalNudgeMilestone30Return01Title.
  ///
  /// In es, this message translates to:
  /// **'Mirar hacia el próximo mes'**
  String get pnJournalNudgeMilestone30Return01Title;

  /// No description provided for @pnJournalNudgeMilestone30Return01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres llevar contigo al próximo mes?'**
  String get pnJournalNudgeMilestone30Return01Body;

  /// No description provided for @pnJournalNudgeMilestone30Memory01Title.
  ///
  /// In es, this message translates to:
  /// **'Lo que quieres conservar'**
  String get pnJournalNudgeMilestone30Memory01Title;

  /// No description provided for @pnJournalNudgeMilestone30Memory01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué merece quedarse de este mes?'**
  String get pnJournalNudgeMilestone30Memory01Body;

  /// No description provided for @pnJournalNudgePerfectDayInsight01Title.
  ///
  /// In es, this message translates to:
  /// **'Una pista de hoy'**
  String get pnJournalNudgePerfectDayInsight01Title;

  /// No description provided for @pnJournalNudgePerfectDayInsight01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué crees que te ayudó a completar tus hábitos?'**
  String get pnJournalNudgePerfectDayInsight01Body;

  /// No description provided for @pnJournalNudgePerfectDayDifference01Title.
  ///
  /// In es, this message translates to:
  /// **'Algo que repetirías'**
  String get pnJournalNudgePerfectDayDifference01Title;

  /// No description provided for @pnJournalNudgePerfectDayDifference01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hiciste hoy que te gustaría repetir?'**
  String get pnJournalNudgePerfectDayDifference01Body;

  /// No description provided for @pnJournalNudgePerfectDayDecision01Title.
  ///
  /// In es, this message translates to:
  /// **'Una decisión útil'**
  String get pnJournalNudgePerfectDayDecision01Title;

  /// No description provided for @pnJournalNudgePerfectDayDecision01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué decisión facilitó completar tus hábitos?'**
  String get pnJournalNudgePerfectDayDecision01Body;

  /// No description provided for @pnJournalNudgePerfectDayEnergy01Title.
  ///
  /// In es, this message translates to:
  /// **'Lo que te acompañó'**
  String get pnJournalNudgePerfectDayEnergy01Title;

  /// No description provided for @pnJournalNudgePerfectDayEnergy01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué momento te dio energía mientras hacías tus hábitos?'**
  String get pnJournalNudgePerfectDayEnergy01Body;

  /// No description provided for @pnJournalNudgePerfectDayEase01Title.
  ///
  /// In es, this message translates to:
  /// **'Lo que facilitó el día'**
  String get pnJournalNudgePerfectDayEase01Title;

  /// No description provided for @pnJournalNudgePerfectDayEase01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hizo más sencillo completar tus hábitos hoy?'**
  String get pnJournalNudgePerfectDayEase01Body;

  /// No description provided for @pnJournalNudgePerfectDayTomorrow01Title.
  ///
  /// In es, this message translates to:
  /// **'Una idea para mañana'**
  String get pnJournalNudgePerfectDayTomorrow01Title;

  /// No description provided for @pnJournalNudgePerfectDayTomorrow01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría probar mañana a partir de lo de hoy?'**
  String get pnJournalNudgePerfectDayTomorrow01Body;

  /// No description provided for @pnJournalNudgePerfectDayMoment01Title.
  ///
  /// In es, this message translates to:
  /// **'Un momento del proceso'**
  String get pnJournalNudgePerfectDayMoment01Title;

  /// No description provided for @pnJournalNudgePerfectDayMoment01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué momento de hoy te gustaría recordar de tus hábitos?'**
  String get pnJournalNudgePerfectDayMoment01Body;

  /// No description provided for @pnJournalNudgePerfectDayLearning01Title.
  ///
  /// In es, this message translates to:
  /// **'Lo que descubriste'**
  String get pnJournalNudgePerfectDayLearning01Title;

  /// No description provided for @pnJournalNudgePerfectDayLearning01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué descubriste sobre ti al completar tus hábitos?'**
  String get pnJournalNudgePerfectDayLearning01Body;

  /// No description provided for @pnJournalNudgePerfectDayFeeling01Title.
  ///
  /// In es, this message translates to:
  /// **'Cómo fue para ti'**
  String get pnJournalNudgePerfectDayFeeling01Title;

  /// No description provided for @pnJournalNudgePerfectDayFeeling01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te sentiste al terminar tus hábitos hoy?'**
  String get pnJournalNudgePerfectDayFeeling01Body;

  /// No description provided for @pnJournalNudgePerfectDayMarker01Title.
  ///
  /// In es, this message translates to:
  /// **'Una señal de tu proceso'**
  String get pnJournalNudgePerfectDayMarker01Title;

  /// No description provided for @pnJournalNudgePerfectDayMarker01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué señal te indica que la forma de hoy te funcionó?'**
  String get pnJournalNudgePerfectDayMarker01Body;

  /// No description provided for @pnJournalNudgePerfectDayMeaning01Title.
  ///
  /// In es, this message translates to:
  /// **'Lo que tuvo sentido'**
  String get pnJournalNudgePerfectDayMeaning01Title;

  /// No description provided for @pnJournalNudgePerfectDayMeaning01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué parte de completar tus hábitos tuvo más sentido para ti?'**
  String get pnJournalNudgePerfectDayMeaning01Body;

  /// No description provided for @pnJournalNudgePerfectDayNote01Title.
  ///
  /// In es, this message translates to:
  /// **'Una nota para mañana'**
  String get pnJournalNudgePerfectDayNote01Title;

  /// No description provided for @pnJournalNudgePerfectDayNote01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres dejar apuntado antes de cerrar el día?'**
  String get pnJournalNudgePerfectDayNote01Body;

  /// No description provided for @pnJournalNudgeEndOfDayReflection01Title.
  ///
  /// In es, this message translates to:
  /// **'Un momento para observar'**
  String get pnJournalNudgeEndOfDayReflection01Title;

  /// No description provided for @pnJournalNudgeEndOfDayReflection01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría observar de tu día, tal como fue?'**
  String get pnJournalNudgeEndOfDayReflection01Body;

  /// No description provided for @pnJournalNudgeEndOfDayEnergy01Title.
  ///
  /// In es, this message translates to:
  /// **'Tu energía hoy'**
  String get pnJournalNudgeEndOfDayEnergy01Title;

  /// No description provided for @pnJournalNudgeEndOfDayEnergy01Body.
  ///
  /// In es, this message translates to:
  /// **'¿En qué momento cambió tu energía durante el día?'**
  String get pnJournalNudgeEndOfDayEnergy01Body;

  /// No description provided for @pnJournalNudgeEndOfDayDrain01Title.
  ///
  /// In es, this message translates to:
  /// **'Lo que pesó hoy'**
  String get pnJournalNudgeEndOfDayDrain01Title;

  /// No description provided for @pnJournalNudgeEndOfDayDrain01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué parte del día se sintió más pesada?'**
  String get pnJournalNudgeEndOfDayDrain01Body;

  /// No description provided for @pnJournalNudgeEndOfDayMemory01Title.
  ///
  /// In es, this message translates to:
  /// **'Algo que queda'**
  String get pnJournalNudgeEndOfDayMemory01Title;

  /// No description provided for @pnJournalNudgeEndOfDayMemory01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué detalle de hoy te gustaría recordar?'**
  String get pnJournalNudgeEndOfDayMemory01Body;

  /// No description provided for @pnJournalNudgeEndOfDayDifference01Title.
  ///
  /// In es, this message translates to:
  /// **'Un detalle distinto'**
  String get pnJournalNudgeEndOfDayDifference01Title;

  /// No description provided for @pnJournalNudgeEndOfDayDifference01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué fue diferente hoy, aunque fuera pequeño?'**
  String get pnJournalNudgeEndOfDayDifference01Body;

  /// No description provided for @pnJournalNudgeEndOfDayLearning01Title.
  ///
  /// In es, this message translates to:
  /// **'Algo que observaste'**
  String get pnJournalNudgeEndOfDayLearning01Title;

  /// No description provided for @pnJournalNudgeEndOfDayLearning01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué aprendiste hoy sobre cómo transcurrió tu día?'**
  String get pnJournalNudgeEndOfDayLearning01Body;

  /// No description provided for @pnJournalNudgeEndOfDayDescribe01Title.
  ///
  /// In es, this message translates to:
  /// **'Ponle palabras al día'**
  String get pnJournalNudgeEndOfDayDescribe01Title;

  /// No description provided for @pnJournalNudgeEndOfDayDescribe01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo describirías tu día en una frase?'**
  String get pnJournalNudgeEndOfDayDescribe01Body;

  /// No description provided for @pnJournalNudgeEndOfDayKeep01Title.
  ///
  /// In es, this message translates to:
  /// **'Algo para guardar'**
  String get pnJournalNudgeEndOfDayKeep01Title;

  /// No description provided for @pnJournalNudgeEndOfDayKeep01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría conservar de hoy?'**
  String get pnJournalNudgeEndOfDayKeep01Body;

  /// No description provided for @pnJournalNudgeEndOfDaySurprise01Title.
  ///
  /// In es, this message translates to:
  /// **'Una sorpresa del día'**
  String get pnJournalNudgeEndOfDaySurprise01Title;

  /// No description provided for @pnJournalNudgeEndOfDaySurprise01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te sorprendió hoy?'**
  String get pnJournalNudgeEndOfDaySurprise01Body;

  /// No description provided for @pnJournalNudgeEndOfDayRelease01Title.
  ///
  /// In es, this message translates to:
  /// **'Dejar espacio'**
  String get pnJournalNudgeEndOfDayRelease01Title;

  /// No description provided for @pnJournalNudgeEndOfDayRelease01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría dejar atrás al terminar el día?'**
  String get pnJournalNudgeEndOfDayRelease01Body;

  /// No description provided for @pnJournalNudgeEndOfDayNotice01Title.
  ///
  /// In es, this message translates to:
  /// **'Algo que notaste'**
  String get pnJournalNudgeEndOfDayNotice01Title;

  /// No description provided for @pnJournalNudgeEndOfDayNotice01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué notaste hoy que merece un momento de atención?'**
  String get pnJournalNudgeEndOfDayNotice01Body;

  /// No description provided for @pnJournalNudgeEndOfDayQuestion01Title.
  ///
  /// In es, this message translates to:
  /// **'Una pregunta para cerrar'**
  String get pnJournalNudgeEndOfDayQuestion01Title;

  /// No description provided for @pnJournalNudgeEndOfDayQuestion01Body.
  ///
  /// In es, this message translates to:
  /// **'¿Qué pregunta te deja el día?'**
  String get pnJournalNudgeEndOfDayQuestion01Body;

  /// No description provided for @pnJournalNudgePromptMilestone7Insight01.
  ///
  /// In es, this message translates to:
  /// **'Al mirar estos primeros días, ¿qué te ayudó a empezar y volver?'**
  String get pnJournalNudgePromptMilestone7Insight01;

  /// No description provided for @pnJournalNudgePromptMilestone7Change01.
  ///
  /// In es, this message translates to:
  /// **'Después de esta primera semana, ¿qué notas diferente?'**
  String get pnJournalNudgePromptMilestone7Change01;

  /// No description provided for @pnJournalNudgePromptMilestone7Ease01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hizo más fácil retomar el hábito esta semana?'**
  String get pnJournalNudgePromptMilestone7Ease01;

  /// No description provided for @pnJournalNudgePromptMilestone7Return01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué parece estar funcionando para ti en este comienzo?'**
  String get pnJournalNudgePromptMilestone7Return01;

  /// No description provided for @pnJournalNudgePromptMilestone7Memory01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría recordar de esta primera semana?'**
  String get pnJournalNudgePromptMilestone7Memory01;

  /// No description provided for @pnJournalNudgePromptMilestone14Insight01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué patrón empiezas a reconocer después de estas dos semanas?'**
  String get pnJournalNudgePromptMilestone14Insight01;

  /// No description provided for @pnJournalNudgePromptMilestone14Change01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué parte del hábito empieza a sentirse más natural?'**
  String get pnJournalNudgePromptMilestone14Change01;

  /// No description provided for @pnJournalNudgePromptMilestone14Ease01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te ha ayudado a mantener el hábito estos días?'**
  String get pnJournalNudgePromptMilestone14Ease01;

  /// No description provided for @pnJournalNudgePromptMilestone14Return01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué estás aprendiendo sobre tu manera de volver?'**
  String get pnJournalNudgePromptMilestone14Return01;

  /// No description provided for @pnJournalNudgePromptMilestone14Memory01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué empieza a consolidarse en tu rutina?'**
  String get pnJournalNudgePromptMilestone14Memory01;

  /// No description provided for @pnJournalNudgePromptMilestone30Insight01.
  ///
  /// In es, this message translates to:
  /// **'Al mirar atrás un mes, ¿qué cambio ves?'**
  String get pnJournalNudgePromptMilestone30Insight01;

  /// No description provided for @pnJournalNudgePromptMilestone30Change01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué empieza a formar parte de tu rutina?'**
  String get pnJournalNudgePromptMilestone30Change01;

  /// No description provided for @pnJournalNudgePromptMilestone30Ease01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué has aprendido sobre lo que te ayuda a mantenerlo?'**
  String get pnJournalNudgePromptMilestone30Ease01;

  /// No description provided for @pnJournalNudgePromptMilestone30Return01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres llevar contigo al próximo mes?'**
  String get pnJournalNudgePromptMilestone30Return01;

  /// No description provided for @pnJournalNudgePromptMilestone30Memory01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué merece quedarse de este mes?'**
  String get pnJournalNudgePromptMilestone30Memory01;

  /// No description provided for @pnJournalNudgePromptPerfectDayInsight01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué crees que te ayudó a completar tus hábitos hoy?'**
  String get pnJournalNudgePromptPerfectDayInsight01;

  /// No description provided for @pnJournalNudgePromptPerfectDayDifference01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hiciste hoy que te gustaría repetir?'**
  String get pnJournalNudgePromptPerfectDayDifference01;

  /// No description provided for @pnJournalNudgePromptPerfectDayDecision01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué decisión facilitó completar tus hábitos?'**
  String get pnJournalNudgePromptPerfectDayDecision01;

  /// No description provided for @pnJournalNudgePromptPerfectDayEnergy01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué momento te dio energía mientras hacías tus hábitos?'**
  String get pnJournalNudgePromptPerfectDayEnergy01;

  /// No description provided for @pnJournalNudgePromptPerfectDayEase01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hizo más sencillo completar tus hábitos hoy?'**
  String get pnJournalNudgePromptPerfectDayEase01;

  /// No description provided for @pnJournalNudgePromptPerfectDayTomorrow01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría probar mañana a partir de lo de hoy?'**
  String get pnJournalNudgePromptPerfectDayTomorrow01;

  /// No description provided for @pnJournalNudgePromptPerfectDayMoment01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué momento de hoy te gustaría recordar de tus hábitos?'**
  String get pnJournalNudgePromptPerfectDayMoment01;

  /// No description provided for @pnJournalNudgePromptPerfectDayLearning01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué descubriste sobre ti al completar tus hábitos?'**
  String get pnJournalNudgePromptPerfectDayLearning01;

  /// No description provided for @pnJournalNudgePromptPerfectDayFeeling01.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te sentiste al terminar tus hábitos hoy?'**
  String get pnJournalNudgePromptPerfectDayFeeling01;

  /// No description provided for @pnJournalNudgePromptPerfectDayMarker01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te indica que la forma de hoy te funcionó?'**
  String get pnJournalNudgePromptPerfectDayMarker01;

  /// No description provided for @pnJournalNudgePromptPerfectDayMeaning01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué parte de completar tus hábitos tuvo más sentido para ti?'**
  String get pnJournalNudgePromptPerfectDayMeaning01;

  /// No description provided for @pnJournalNudgePromptPerfectDayNote01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres dejar apuntado antes de cerrar el día?'**
  String get pnJournalNudgePromptPerfectDayNote01;

  /// No description provided for @pnJournalNudgePromptEndOfDayReflection01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría observar de tu día, tal como fue?'**
  String get pnJournalNudgePromptEndOfDayReflection01;

  /// No description provided for @pnJournalNudgePromptEndOfDayEnergy01.
  ///
  /// In es, this message translates to:
  /// **'¿En qué momento cambió tu energía durante el día?'**
  String get pnJournalNudgePromptEndOfDayEnergy01;

  /// No description provided for @pnJournalNudgePromptEndOfDayDrain01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué parte del día se sintió más pesada?'**
  String get pnJournalNudgePromptEndOfDayDrain01;

  /// No description provided for @pnJournalNudgePromptEndOfDayMemory01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué detalle de hoy te gustaría recordar?'**
  String get pnJournalNudgePromptEndOfDayMemory01;

  /// No description provided for @pnJournalNudgePromptEndOfDayDifference01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué fue diferente hoy, aunque fuera pequeño?'**
  String get pnJournalNudgePromptEndOfDayDifference01;

  /// No description provided for @pnJournalNudgePromptEndOfDayLearning01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué aprendiste hoy sobre cómo transcurrió tu día?'**
  String get pnJournalNudgePromptEndOfDayLearning01;

  /// No description provided for @pnJournalNudgePromptEndOfDayDescribe01.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo describirías tu día en una frase?'**
  String get pnJournalNudgePromptEndOfDayDescribe01;

  /// No description provided for @pnJournalNudgePromptEndOfDayKeep01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría conservar de hoy?'**
  String get pnJournalNudgePromptEndOfDayKeep01;

  /// No description provided for @pnJournalNudgePromptEndOfDaySurprise01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te sorprendió hoy?'**
  String get pnJournalNudgePromptEndOfDaySurprise01;

  /// No description provided for @pnJournalNudgePromptEndOfDayRelease01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría dejar atrás al terminar el día?'**
  String get pnJournalNudgePromptEndOfDayRelease01;

  /// No description provided for @pnJournalNudgePromptEndOfDayNotice01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué notaste hoy que merece un momento de atención?'**
  String get pnJournalNudgePromptEndOfDayNotice01;

  /// No description provided for @pnJournalNudgePromptEndOfDayQuestion01.
  ///
  /// In es, this message translates to:
  /// **'¿Qué pregunta te deja el día?'**
  String get pnJournalNudgePromptEndOfDayQuestion01;

  /// No description provided for @feedbackSubmitErrorSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Vuelve a iniciar sesión.'**
  String get feedbackSubmitErrorSessionExpired;

  /// No description provided for @feedbackSubmitErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un problema de conexión al enviar tu feedback. Inténtalo de nuevo.'**
  String get feedbackSubmitErrorNetwork;

  /// No description provided for @feedbackSubmitErrorRejected.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido enviar tu feedback. Revisa el contenido e inténtalo otra vez.'**
  String get feedbackSubmitErrorRejected;

  /// No description provided for @feedbackSubmitErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un problema al enviar tu feedback. Inténtalo de nuevo.'**
  String get feedbackSubmitErrorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
