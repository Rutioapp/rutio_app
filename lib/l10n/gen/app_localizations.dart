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

  /// No description provided for @homeEmptyStateMultiline.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes hábitos activos.`nPulsa “Nuevo” para añadir el primero.'**
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

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountHelperText.
  ///
  /// In es, this message translates to:
  /// **'Elimina los datos de la cuenta almacenados en este dispositivo.'**
  String get settingsDeleteAccountHelperText;

  /// No description provided for @settingsDeleteAccountConfirmationTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar cuenta?'**
  String get settingsDeleteAccountConfirmationTitle;

  /// No description provided for @settingsDeleteAccountConfirmationBody.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta y los datos asociados almacenados en este dispositivo se eliminarán de forma permanente. Esta acción no se puede deshacer.'**
  String get settingsDeleteAccountConfirmationBody;

  /// No description provided for @settingsDeleteAccountConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar permanentemente'**
  String get settingsDeleteAccountConfirmAction;

  /// No description provided for @settingsDeleteAccountError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido eliminar los datos de tu cuenta en este dispositivo. Inténtalo de nuevo.'**
  String get settingsDeleteAccountError;

  /// No description provided for @settingsDeleteAccountSuccess.
  ///
  /// In es, this message translates to:
  /// **'Los datos de tu cuenta se han eliminado de este dispositivo.'**
  String get settingsDeleteAccountSuccess;

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
  /// **'Estadisticas'**
  String get habitStatsTitle;

  /// No description provided for @habitStatsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay habitos para mostrar.'**
  String get habitStatsEmpty;

  /// No description provided for @habitStatsMetricCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get habitStatsMetricCompleted;

  /// No description provided for @habitStatsMetricCompletionDescription.
  ///
  /// In es, this message translates to:
  /// **'{done}/{total} dias'**
  String habitStatsMetricCompletionDescription(int done, int total);

  /// No description provided for @habitStatsMetricConsistency.
  ///
  /// In es, this message translates to:
  /// **'Consistencia'**
  String get habitStatsMetricConsistency;

  /// No description provided for @habitStatsMetricConsistencyDescription.
  ///
  /// In es, this message translates to:
  /// **'Ultimos {window} dias'**
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
  /// **'Ultimas 4 semanas'**
  String get habitStatsChartLastFourWeeksTitle;

  /// No description provided for @habitStatsChartWeekSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Completado por dia'**
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
  /// **'Cuando lo cumples mejor?'**
  String get habitStatsBestTimeSectionTitle;

  /// No description provided for @habitStatsBestTimeSectionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Basado en tus registros, tus momentos mas consistentes'**
  String get habitStatsBestTimeSectionSubtitle;

  /// No description provided for @habitStatsMonthCalendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario del mes'**
  String get habitStatsMonthCalendarTitle;

  /// No description provided for @habitStatsTabSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get habitStatsTabSummaryTitle;

  /// No description provided for @habitStatsTabLastDaysTitle.
  ///
  /// In es, this message translates to:
  /// **'Ultimos {days} dias'**
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
  /// **'{count} dia'**
  String habitStatsTabDayUnit(int count);

  /// No description provided for @habitStatsTabTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'total'**
  String get habitStatsTabTotalLabel;

  /// No description provided for @habitStatsTabCompletionWindow.
  ///
  /// In es, this message translates to:
  /// **'{done} / {total} dias'**
  String habitStatsTabCompletionWindow(int done, int total);

  /// No description provided for @habitStatsTabCounterHint.
  ///
  /// In es, this message translates to:
  /// **'Cuenta el numero de veces completado cada dia'**
  String get habitStatsTabCounterHint;

  /// No description provided for @habitStatsTabCheckHint.
  ///
  /// In es, this message translates to:
  /// **'Dias en los que completaste este habito'**
  String get habitStatsTabCheckHint;

  /// No description provided for @habitStatsTabFireStreakTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha de fuego'**
  String get habitStatsTabFireStreakTitle;

  /// No description provided for @habitStatsTabStreakInARow.
  ///
  /// In es, this message translates to:
  /// **'{days} dias seguidos'**
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
  /// **'{percent}% ultimos 30 dias'**
  String habitStatsTabLast30DaysPercent(int percent);

  /// No description provided for @habitStatsTabLegendaryRecordTitle.
  ///
  /// In es, this message translates to:
  /// **'Record legendario'**
  String get habitStatsTabLegendaryRecordTitle;

  /// No description provided for @habitStatsTabRecordStreak.
  ///
  /// In es, this message translates to:
  /// **'{days} dias de racha'**
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
  /// **'Menu'**
  String get diaryMenuTooltip;

  /// No description provided for @diaryCloseSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cerrar busqueda'**
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
  /// **'Fijar: proximamente'**
  String get diaryPinSoon;

  /// No description provided for @diaryDeleteEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar entrada'**
  String get diaryDeleteEntryTitle;

  /// No description provided for @diaryDeleteEntryBody.
  ///
  /// In es, this message translates to:
  /// **'Seguro que quieres eliminar esta entrada?'**
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
  /// **'Dias'**
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
  /// **'Habitos'**
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
  /// **'Hoy aun no has escrito'**
  String get diarySummaryEmptyTitle;

  /// No description provided for @diarySummaryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un minuto puede cambiar tu dia'**
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
  /// **'Estas cuidando tu mundo interior'**
  String get diarySummaryFewTitle;

  /// No description provided for @diarySummaryFewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sigue asi'**
  String get diarySummaryFewSubtitle;

  /// No description provided for @diarySummaryManyTitle.
  ///
  /// In es, this message translates to:
  /// **'Dia muy consciente'**
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
  /// **'¿COMO TE SENTISTE?'**
  String get diaryComposerMoodSectionUpper;

  /// No description provided for @diaryComposerTitleUpper.
  ///
  /// In es, this message translates to:
  /// **'TITULO'**
  String get diaryComposerTitleUpper;

  /// No description provided for @diaryComposerReflectionUpper.
  ///
  /// In es, this message translates to:
  /// **'REFLEXION'**
  String get diaryComposerReflectionUpper;

  /// No description provided for @diaryComposerTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Como resumirias hoy?'**
  String get diaryComposerTitleHint;

  /// No description provided for @diaryComposerHabitReflectionHint.
  ///
  /// In es, this message translates to:
  /// **'Que paso hoy con tu habito? Que sentiste? Que aprendiste?'**
  String get diaryComposerHabitReflectionHint;

  /// No description provided for @diaryComposerPersonalReflectionHint.
  ///
  /// In es, this message translates to:
  /// **'Que tienes en mente? Que quieres dejar por escrito hoy?'**
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
  /// **'Ligada a habito'**
  String get diaryComposerTypeHabit;

  /// No description provided for @diaryComposerTypePersonal.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get diaryComposerTypePersonal;

  /// No description provided for @diaryComposerSelectHabit.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar habito'**
  String get diaryComposerSelectHabit;

  /// No description provided for @diaryComposerTapToChooseHabit.
  ///
  /// In es, this message translates to:
  /// **'Toca para elegir un habito'**
  String get diaryComposerTapToChooseHabit;

  /// No description provided for @diaryComposerWriteSomethingError.
  ///
  /// In es, this message translates to:
  /// **'Escribe algo para guardar la entrada'**
  String get diaryComposerWriteSomethingError;

  /// No description provided for @diaryComposerSelectHabitError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un habito'**
  String get diaryComposerSelectHabitError;

  /// No description provided for @diaryComposerNoActiveHabits.
  ///
  /// In es, this message translates to:
  /// **'No hay habitos activos para seleccionar'**
  String get diaryComposerNoActiveHabits;

  /// No description provided for @diaryComposerSelectHabitSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar habito'**
  String get diaryComposerSelectHabitSheetTitle;

  /// No description provided for @diaryDetailScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrada'**
  String get diaryDetailScreenTitle;

  /// No description provided for @diaryDetailTopHabitUpper.
  ///
  /// In es, this message translates to:
  /// **'ENTRADA DE HABITO'**
  String get diaryDetailTopHabitUpper;

  /// No description provided for @diaryDetailTopPersonalUpper.
  ///
  /// In es, this message translates to:
  /// **'ENTRADA PERSONAL'**
  String get diaryDetailTopPersonalUpper;

  /// No description provided for @diaryDetailFallbackHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrada de habito'**
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
  /// **'Dia de habito'**
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
  /// **'Habito'**
  String get habitStatsHabitFallbackTitle;

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
  /// **'{count} dia'**
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
  /// **'{label}: {next} dias'**
  String habitStatsMilestoneProgress(String label, int next);

  /// No description provided for @habitStatsThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get habitStatsThisWeek;

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
  /// **'Mas'**
  String get habitStatsLegendMore;

  /// No description provided for @habitStatsDayTooltip.
  ///
  /// In es, this message translates to:
  /// **'Dia {day}'**
  String habitStatsDayTooltip(int day);

  /// No description provided for @habitStatsThisHabitFallback.
  ///
  /// In es, this message translates to:
  /// **'este habito'**
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
  /// **'llegar a los {days} dias'**
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
  /// **', cuando sueles ser mas constante.'**
  String get habitStatsMotivationBestTimeTail;

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
  /// **'Permisos de notificacion denegados.'**
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
  /// **'Como lo mides?'**
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
  /// **'Cuantas veces al dia?'**
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
  /// **'Cada dia'**
  String get editHabitFrequencyDaily;

  /// No description provided for @editHabitFrequencySpecificDays.
  ///
  /// In es, this message translates to:
  /// **'Dias concretos'**
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
  /// **'Marca cuantas veces quieres completarlo.'**
  String get editHabitWeeklyGoalSubtitle;

  /// No description provided for @editHabitReminderDailyTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificacion diaria'**
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
  /// **'Habito completado: {habitName}'**
  String diaryAfterCompleteTitle(String habitName);

  /// No description provided for @diaryAfterCompletePrompt.
  ///
  /// In es, this message translates to:
  /// **'Quieres anadir una nota rapida?'**
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
  /// **'DIA'**
  String get diaryCardTypeHabitShort;

  /// No description provided for @diaryCardTypePersonalShort.
  ///
  /// In es, this message translates to:
  /// **'NOTA'**
  String get diaryCardTypePersonalShort;

  /// No description provided for @diaryShowMore.
  ///
  /// In es, this message translates to:
  /// **'Ver mas'**
  String get diaryShowMore;

  /// No description provided for @diaryShowLess.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get diaryShowLess;

  /// No description provided for @diaryStreakLabel.
  ///
  /// In es, this message translates to:
  /// **'Racha: {count} dia{sufix}'**
  String diaryStreakLabel(int count, String sufix);

  /// No description provided for @diaryEmotionalStreakTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha emocional'**
  String get diaryEmotionalStreakTitle;

  /// No description provided for @diaryDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} dia{sufix}'**
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
  /// **'Nuevo habito'**
  String get createHabitNewHabitTitle;

  /// No description provided for @createHabitSaveHabit.
  ///
  /// In es, this message translates to:
  /// **'Guardar habito'**
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
  /// **'Tus emojis recientes apareceran aqui'**
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
  /// **'No hay habitos para mostrar en este filtro.'**
  String get monthlyEmptyFilteredMessage;

  /// No description provided for @monthlyElapsedDaysWeek.
  ///
  /// In es, this message translates to:
  /// **'{elapsed} dias transcurridos · semana {week}'**
  String monthlyElapsedDaysWeek(int elapsed, int week);

  /// No description provided for @monthlyFilterSummaryFamily.
  ///
  /// In es, this message translates to:
  /// **'Familia: {family}'**
  String monthlyFilterSummaryFamily(String family);

  /// No description provided for @monthlyFilterSummaryHabit.
  ///
  /// In es, this message translates to:
  /// **'Habito: {habit}'**
  String monthlyFilterSummaryHabit(String habit);

  /// No description provided for @monthlyFilterSummaryAll.
  ///
  /// In es, this message translates to:
  /// **'Todos los habitos'**
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
  /// **'Habito'**
  String get monthlyFilterModeHabit;

  /// No description provided for @monthlyApplyAction.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get monthlyApplyAction;

  /// No description provided for @monthlySelectHabitLabel.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un habito'**
  String get monthlySelectHabitLabel;

  /// No description provided for @monthlyHabitSelectorTitle.
  ///
  /// In es, this message translates to:
  /// **'VER HABITO'**
  String get monthlyHabitSelectorTitle;

  /// No description provided for @monthlyHabitFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Habito'**
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
  /// **'{count} dia{sufix}'**
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
