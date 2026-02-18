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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @sharedAppTitle.
  ///
  /// In es, this message translates to:
  /// **'Gym Tracker'**
  String get sharedAppTitle;

  /// No description provided for @sharedNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get sharedNext;

  /// No description provided for @sharedBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get sharedBack;

  /// No description provided for @sharedSkip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get sharedSkip;

  /// No description provided for @sharedStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get sharedStart;

  /// No description provided for @sharedGain.
  ///
  /// In es, this message translates to:
  /// **'Ganar'**
  String get sharedGain;

  /// No description provided for @sharedLose.
  ///
  /// In es, this message translates to:
  /// **'Perder'**
  String get sharedLose;

  /// No description provided for @sharedMaintain.
  ///
  /// In es, this message translates to:
  /// **'Mantener'**
  String get sharedMaintain;

  /// No description provided for @sharedFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get sharedFieldRequired;

  /// No description provided for @sharedFieldInvalidRange.
  ///
  /// In es, this message translates to:
  /// **'Valor fuera de rango ({min}-{max})'**
  String sharedFieldInvalidRange(String min, String max);

  /// No description provided for @sharedNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'N/D'**
  String get sharedNotAvailable;

  /// No description provided for @sharedLanguageToggle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get sharedLanguageToggle;

  /// No description provided for @sharedStepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String sharedStepOf(String current, String total);

  /// No description provided for @sharedConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get sharedConfirm;

  /// No description provided for @sharedCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get sharedCancel;

  /// No description provided for @sharedSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get sharedSave;

  /// No description provided for @authSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authSignUp;

  /// No description provided for @authEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPassword;

  /// No description provided for @authSignInWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authSignInWithGoogle;

  /// No description provided for @authSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get authSignOut;

  /// No description provided for @authSignOutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres cerrar sesión?'**
  String get authSignOutConfirm;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña incorrecta'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Este correo ya está registrado'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico no válido'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'No existe una cuenta con este correo'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error de autenticación. Inténtalo de nuevo'**
  String get authErrorGeneric;

  /// No description provided for @authSyncing.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando datos...'**
  String get authSyncing;

  /// No description provided for @authOr.
  ///
  /// In es, this message translates to:
  /// **'O'**
  String get authOr;

  /// No description provided for @loadingMotto.
  ///
  /// In es, this message translates to:
  /// **'Improve yourself'**
  String get loadingMotto;

  /// No description provided for @landingTrain.
  ///
  /// In es, this message translates to:
  /// **'Entrenar'**
  String get landingTrain;

  /// No description provided for @landingRoutines.
  ///
  /// In es, this message translates to:
  /// **'Mis rutinas'**
  String get landingRoutines;

  /// No description provided for @landingCreateRoutine.
  ///
  /// In es, this message translates to:
  /// **'Crear rutina'**
  String get landingCreateRoutine;

  /// No description provided for @landingNoRoutines.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes rutinas'**
  String get landingNoRoutines;

  /// No description provided for @landingRoutineName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la rutina'**
  String get landingRoutineName;

  /// No description provided for @landingDeleteRoutine.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get landingDeleteRoutine;

  /// No description provided for @landingAddTraining.
  ///
  /// In es, this message translates to:
  /// **'Añadir entrenamiento'**
  String get landingAddTraining;

  /// No description provided for @landingViewDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver entrenamientos'**
  String get landingViewDetails;

  /// No description provided for @landingFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get landingFilterAll;

  /// No description provided for @landingMarkTrainingTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar entrenamiento'**
  String get landingMarkTrainingTitle;

  /// No description provided for @landingMarkTrainingBody.
  ///
  /// In es, this message translates to:
  /// **'¿Registrar {routineName} para este día?'**
  String landingMarkTrainingBody(String routineName);

  /// No description provided for @landingMarkTrainingConfirm.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get landingMarkTrainingConfirm;

  /// No description provided for @landingTrainingMarked.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento registrado'**
  String get landingTrainingMarked;

  /// No description provided for @landingDeleteTrainingTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar entrenamiento'**
  String get landingDeleteTrainingTitle;

  /// No description provided for @landingDeleteTrainingBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar {name} de este día?'**
  String landingDeleteTrainingBody(String name);

  /// No description provided for @landingDeleteTrainingConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get landingDeleteTrainingConfirm;

  /// No description provided for @landingOptionalStartTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio (opcional)'**
  String get landingOptionalStartTime;

  /// No description provided for @landingOptionalEndTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de fin (opcional)'**
  String get landingOptionalEndTime;

  /// No description provided for @landingNoTime.
  ///
  /// In es, this message translates to:
  /// **'Sin hora'**
  String get landingNoTime;

  /// No description provided for @landingTrainingDeleted.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento eliminado'**
  String get landingTrainingDeleted;

  /// No description provided for @landingTrainingTypeMobility.
  ///
  /// In es, this message translates to:
  /// **'Movilidad'**
  String get landingTrainingTypeMobility;

  /// No description provided for @landingTrainingTypeHiit.
  ///
  /// In es, this message translates to:
  /// **'HIIT'**
  String get landingTrainingTypeHiit;

  /// No description provided for @landingTrainingTypeWorkout.
  ///
  /// In es, this message translates to:
  /// **'Musculación'**
  String get landingTrainingTypeWorkout;

  /// No description provided for @routineSelectType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de rutina'**
  String get routineSelectType;

  /// No description provided for @routineMusculacion.
  ///
  /// In es, this message translates to:
  /// **'Musculación'**
  String get routineMusculacion;

  /// No description provided for @routinePliometricos.
  ///
  /// In es, this message translates to:
  /// **'Pliométricos'**
  String get routinePliometricos;

  /// No description provided for @routineMovilidad.
  ///
  /// In es, this message translates to:
  /// **'Movilidad'**
  String get routineMovilidad;

  /// No description provided for @routineHiit.
  ///
  /// In es, this message translates to:
  /// **'HIIT'**
  String get routineHiit;

  /// No description provided for @routineComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get routineComingSoon;

  /// No description provided for @mobilityCadera.
  ///
  /// In es, this message translates to:
  /// **'Cadera'**
  String get mobilityCadera;

  /// No description provided for @mobilityTobillos.
  ///
  /// In es, this message translates to:
  /// **'Tobillos'**
  String get mobilityTobillos;

  /// No description provided for @mobilityCustomRoutine.
  ///
  /// In es, this message translates to:
  /// **'Crear rutina personalizada'**
  String get mobilityCustomRoutine;

  /// No description provided for @mobilityRecommendedRoutine.
  ///
  /// In es, this message translates to:
  /// **'Rutina recomendada'**
  String get mobilityRecommendedRoutine;

  /// No description provided for @mobilityChooseOption.
  ///
  /// In es, this message translates to:
  /// **'Elige una opción'**
  String get mobilityChooseOption;

  /// No description provided for @mobilityFeetAnkles2.
  ///
  /// In es, this message translates to:
  /// **'Movilidad de tobillo'**
  String get mobilityFeetAnkles2;

  /// No description provided for @mobilityPelvicTilt.
  ///
  /// In es, this message translates to:
  /// **'Inclinación Pélvica'**
  String get mobilityPelvicTilt;

  /// No description provided for @mobilityHips.
  ///
  /// In es, this message translates to:
  /// **'Caderas'**
  String get mobilityHips;

  /// No description provided for @mobilityRelajacion.
  ///
  /// In es, this message translates to:
  /// **'Relajación'**
  String get mobilityRelajacion;

  /// No description provided for @mobilitySleep.
  ///
  /// In es, this message translates to:
  /// **'Sueño'**
  String get mobilitySleep;

  /// No description provided for @mobilityTimerTitle.
  ///
  /// In es, this message translates to:
  /// **'Movilidad'**
  String get mobilityTimerTitle;

  /// No description provided for @mobilityExerciseOf.
  ///
  /// In es, this message translates to:
  /// **'{current} / {total}'**
  String mobilityExerciseOf(Object current, Object total);

  /// No description provided for @mobilityLeftSide.
  ///
  /// In es, this message translates to:
  /// **'Lado izquierdo'**
  String get mobilityLeftSide;

  /// No description provided for @mobilityRightSide.
  ///
  /// In es, this message translates to:
  /// **'Lado derecho'**
  String get mobilityRightSide;

  /// No description provided for @mobilityBothSides.
  ///
  /// In es, this message translates to:
  /// **'Ambos lados'**
  String get mobilityBothSides;

  /// No description provided for @mobilityRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get mobilityRest;

  /// No description provided for @mobilityRestOff.
  ///
  /// In es, this message translates to:
  /// **'Sin descanso'**
  String get mobilityRestOff;

  /// No description provided for @mobilityRestSeconds.
  ///
  /// In es, this message translates to:
  /// **'{seconds}s'**
  String mobilityRestSeconds(Object seconds);

  /// No description provided for @mobilityComplete.
  ///
  /// In es, this message translates to:
  /// **'¡Completado!'**
  String get mobilityComplete;

  /// No description provided for @mobilitySound.
  ///
  /// In es, this message translates to:
  /// **'Sonido'**
  String get mobilitySound;

  /// No description provided for @mobilityRestDuration.
  ///
  /// In es, this message translates to:
  /// **'Descanso entre ejercicios'**
  String get mobilityRestDuration;

  /// No description provided for @mobilitySettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get mobilitySettings;

  /// No description provided for @mobilityInfoInstructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones'**
  String get mobilityInfoInstructions;

  /// No description provided for @mobilityInfoTips.
  ///
  /// In es, this message translates to:
  /// **'Consejos'**
  String get mobilityInfoTips;

  /// No description provided for @mobilityInfoModifications.
  ///
  /// In es, this message translates to:
  /// **'Modificaciones'**
  String get mobilityInfoModifications;

  /// No description provided for @mobilityInfoBenefits.
  ///
  /// In es, this message translates to:
  /// **'Beneficios'**
  String get mobilityInfoBenefits;

  /// No description provided for @mobilitySingleLegStand.
  ///
  /// In es, this message translates to:
  /// **'Apoyo a una pierna'**
  String get mobilitySingleLegStand;

  /// No description provided for @mobilityAnkleCircles.
  ///
  /// In es, this message translates to:
  /// **'Círculos de tobillo'**
  String get mobilityAnkleCircles;

  /// No description provided for @mobilityHeelToToeRocks.
  ///
  /// In es, this message translates to:
  /// **'Balanceo talón-punta'**
  String get mobilityHeelToToeRocks;

  /// No description provided for @mobilityLateralFootRocks.
  ///
  /// In es, this message translates to:
  /// **'Balanceo lateral del pie'**
  String get mobilityLateralFootRocks;

  /// No description provided for @mobilityKneeCircles.
  ///
  /// In es, this message translates to:
  /// **'Círculos de rodilla'**
  String get mobilityKneeCircles;

  /// No description provided for @mobilitySoleusStretch.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento de sóleo'**
  String get mobilitySoleusStretch;

  /// No description provided for @mobilityLeaningCalf.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento de gemelo'**
  String get mobilityLeaningCalf;

  /// No description provided for @mobilityToeToWall.
  ///
  /// In es, this message translates to:
  /// **'Punta contra pared'**
  String get mobilityToeToWall;

  /// No description provided for @mobilityStandingQuad.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento de cuádriceps'**
  String get mobilityStandingQuad;

  /// No description provided for @mobilitySingleLegCalfStretch.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento de gemelo a una pierna'**
  String get mobilitySingleLegCalfStretch;

  /// No description provided for @mobilitySingleLegShinStretch.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento de tibial a una pierna'**
  String get mobilitySingleLegShinStretch;

  /// No description provided for @mobilityToeStretch.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento de dedos'**
  String get mobilityToeStretch;

  /// No description provided for @mobilityThunderbolt.
  ///
  /// In es, this message translates to:
  /// **'Postura del rayo'**
  String get mobilityThunderbolt;

  /// No description provided for @mobilityToeSquat.
  ///
  /// In es, this message translates to:
  /// **'Sentadilla de dedos'**
  String get mobilityToeSquat;

  /// No description provided for @mobilityPelvicTiltExercise.
  ///
  /// In es, this message translates to:
  /// **'Inclinación pélvica'**
  String get mobilityPelvicTiltExercise;

  /// No description provided for @mobilityGluteBridge.
  ///
  /// In es, this message translates to:
  /// **'Puente de glúteos'**
  String get mobilityGluteBridge;

  /// No description provided for @mobilityKneesToChest.
  ///
  /// In es, this message translates to:
  /// **'Rodillas al pecho'**
  String get mobilityKneesToChest;

  /// No description provided for @mobilitySingleKneeToChest.
  ///
  /// In es, this message translates to:
  /// **'Rodilla al pecho'**
  String get mobilitySingleKneeToChest;

  /// No description provided for @mobilityLyingQuadStretch.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento de cuádriceps tumbado'**
  String get mobilityLyingQuadStretch;

  /// No description provided for @mobilityKneelingHipFlexor.
  ///
  /// In es, this message translates to:
  /// **'Flexor de cadera de rodillas'**
  String get mobilityKneelingHipFlexor;

  /// No description provided for @mobilityCatCow.
  ///
  /// In es, this message translates to:
  /// **'Gato-Vaca'**
  String get mobilityCatCow;

  /// No description provided for @mobilitySeatedButterfly.
  ///
  /// In es, this message translates to:
  /// **'Mariposa sentada'**
  String get mobilitySeatedButterfly;

  /// No description provided for @mobilityLyingFigureFour.
  ///
  /// In es, this message translates to:
  /// **'Figura cuatro tumbado'**
  String get mobilityLyingFigureFour;

  /// No description provided for @mobilityLizardPose.
  ///
  /// In es, this message translates to:
  /// **'Postura del lagarto'**
  String get mobilityLizardPose;

  /// No description provided for @mobilityPigeon.
  ///
  /// In es, this message translates to:
  /// **'Paloma'**
  String get mobilityPigeon;

  /// No description provided for @mobilityFoldedButterfly.
  ///
  /// In es, this message translates to:
  /// **'Mariposa plegada'**
  String get mobilityFoldedButterfly;

  /// No description provided for @mobilityHappyBaby.
  ///
  /// In es, this message translates to:
  /// **'Bebé feliz'**
  String get mobilityHappyBaby;

  /// No description provided for @mobilityFrogPose.
  ///
  /// In es, this message translates to:
  /// **'Postura de la rana'**
  String get mobilityFrogPose;

  /// No description provided for @mobilitySquatStretch.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento en sentadilla'**
  String get mobilitySquatStretch;

  /// No description provided for @mobilityDoublePigeon.
  ///
  /// In es, this message translates to:
  /// **'Doble paloma'**
  String get mobilityDoublePigeon;

  /// No description provided for @mobilityReclinedButterfly.
  ///
  /// In es, this message translates to:
  /// **'Mariposa reclinada'**
  String get mobilityReclinedButterfly;

  /// No description provided for @mobilityRagDoll.
  ///
  /// In es, this message translates to:
  /// **'Muñeca de trapo'**
  String get mobilityRagDoll;

  /// No description provided for @mobilityUpwardDog.
  ///
  /// In es, this message translates to:
  /// **'Perro boca arriba'**
  String get mobilityUpwardDog;

  /// No description provided for @mobilityChildsPose.
  ///
  /// In es, this message translates to:
  /// **'Postura del niño'**
  String get mobilityChildsPose;

  /// No description provided for @mobilitySpinalTwist.
  ///
  /// In es, this message translates to:
  /// **'Torsión espinal'**
  String get mobilitySpinalTwist;

  /// No description provided for @mobilityQuadStretch.
  ///
  /// In es, this message translates to:
  /// **'Estiramiento de cuádriceps'**
  String get mobilityQuadStretch;

  /// No description provided for @mobilityLegsUpWall.
  ///
  /// In es, this message translates to:
  /// **'Piernas en la pared'**
  String get mobilityLegsUpWall;

  /// No description provided for @mobilityRoutineNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la rutina de movilidad'**
  String get mobilityRoutineNotFound;

  /// No description provided for @mobilityRoutineDuration.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String mobilityRoutineDuration(String minutes);

  /// No description provided for @mobilityRoutineExerciseCount.
  ///
  /// In es, this message translates to:
  /// **'{count} ejercicios'**
  String mobilityRoutineExerciseCount(String count);

  /// No description provided for @mobilityNextExercise.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get mobilityNextExercise;

  /// No description provided for @mobilityGetReady.
  ///
  /// In es, this message translates to:
  /// **'¡Prepárate!'**
  String get mobilityGetReady;

  /// No description provided for @mobilityFinishEarly.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get mobilityFinishEarly;

  /// No description provided for @mobilityFinishEarlyConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres finalizar la rutina?'**
  String get mobilityFinishEarlyConfirm;

  /// No description provided for @hiitSelectExercises.
  ///
  /// In es, this message translates to:
  /// **'Selecciona ejercicios'**
  String get hiitSelectExercises;

  /// No description provided for @hiitEditExercises.
  ///
  /// In es, this message translates to:
  /// **'Editar ejercicios'**
  String get hiitEditExercises;

  /// No description provided for @hiitWarningTooMany.
  ///
  /// In es, this message translates to:
  /// **'No se recomienda seleccionar más de 6 ejercicios'**
  String get hiitWarningTooMany;

  /// No description provided for @hiitConfig.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get hiitConfig;

  /// No description provided for @hiitSets.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get hiitSets;

  /// No description provided for @hiitWorkDuration.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de trabajo'**
  String get hiitWorkDuration;

  /// No description provided for @hiitRestDuration.
  ///
  /// In es, this message translates to:
  /// **'Descanso entre ejercicios'**
  String get hiitRestDuration;

  /// No description provided for @hiitSetRestDuration.
  ///
  /// In es, this message translates to:
  /// **'Descanso entre series'**
  String get hiitSetRestDuration;

  /// No description provided for @hiitTotalDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración total'**
  String get hiitTotalDuration;

  /// No description provided for @hiitTimerTitle.
  ///
  /// In es, this message translates to:
  /// **'HIIT'**
  String get hiitTimerTitle;

  /// No description provided for @hiitSetOf.
  ///
  /// In es, this message translates to:
  /// **'Serie {current} / {total}'**
  String hiitSetOf(String current, String total);

  /// No description provided for @hiitExerciseOf.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio {current} / {total}'**
  String hiitExerciseOf(String current, String total);

  /// No description provided for @hiitRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get hiitRest;

  /// No description provided for @hiitSetRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso entre series'**
  String get hiitSetRest;

  /// No description provided for @hiitComplete.
  ///
  /// In es, this message translates to:
  /// **'¡Completado!'**
  String get hiitComplete;

  /// No description provided for @hiitGetReady.
  ///
  /// In es, this message translates to:
  /// **'¡Prepárate!'**
  String get hiitGetReady;

  /// No description provided for @hiitFinishEarly.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get hiitFinishEarly;

  /// No description provided for @hiitFinishEarlyConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres finalizar el HIIT?'**
  String get hiitFinishEarlyConfirm;

  /// No description provided for @hiitSeconds.
  ///
  /// In es, this message translates to:
  /// **'{seconds}s'**
  String hiitSeconds(String seconds);

  /// No description provided for @hiitMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String hiitMinutes(String minutes);

  /// No description provided for @hiitExerciseCount.
  ///
  /// In es, this message translates to:
  /// **'{count} ejercicios'**
  String hiitExerciseCount(String count);

  /// No description provided for @hiitSetCount.
  ///
  /// In es, this message translates to:
  /// **'{count} series'**
  String hiitSetCount(String count);

  /// No description provided for @hiitNextExercise.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get hiitNextExercise;

  /// No description provided for @hiitSetComplete.
  ///
  /// In es, this message translates to:
  /// **'Serie completada'**
  String get hiitSetComplete;

  /// No description provided for @routineSelectDays.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántos días por semana?'**
  String get routineSelectDays;

  /// No description provided for @routineDayOf.
  ///
  /// In es, this message translates to:
  /// **'Día {current} de {total}'**
  String routineDayOf(String current, String total);

  /// No description provided for @routineDaysCount.
  ///
  /// In es, this message translates to:
  /// **'{count} días'**
  String routineDaysCount(String count);

  /// No description provided for @routineSelectMuscleGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos musculares'**
  String get routineSelectMuscleGroups;

  /// No description provided for @exerciseSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar ejercicio...'**
  String get exerciseSearchHint;

  /// No description provided for @routineSelectExercises.
  ///
  /// In es, this message translates to:
  /// **'Selecciona ejercicios'**
  String get routineSelectExercises;

  /// No description provided for @routineExerciseDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle del ejercicio'**
  String get routineExerciseDetail;

  /// No description provided for @routineAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get routineAdd;

  /// No description provided for @routineRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get routineRemove;

  /// No description provided for @routineSelected.
  ///
  /// In es, this message translates to:
  /// **'{count} seleccionados'**
  String routineSelected(String count);

  /// No description provided for @routineSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen de rutina'**
  String get routineSummaryTitle;

  /// No description provided for @routineNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la rutina'**
  String get routineNameHint;

  /// No description provided for @routineSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar rutina'**
  String get routineSave;

  /// No description provided for @routineDifficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get routineDifficulty;

  /// No description provided for @routineMuscles.
  ///
  /// In es, this message translates to:
  /// **'Músculos'**
  String get routineMuscles;

  /// No description provided for @routineDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Día {day}'**
  String routineDayLabel(String day);

  /// No description provided for @routineExercises.
  ///
  /// In es, this message translates to:
  /// **'ejercicios'**
  String get routineExercises;

  /// No description provided for @routineDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar rutina'**
  String get routineDeleteTitle;

  /// No description provided for @routineDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar \"{name}\"?'**
  String routineDeleteConfirm(String name);

  /// No description provided for @routineDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get routineDelete;

  /// No description provided for @routineEditDay.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get routineEditDay;

  /// No description provided for @routineViewProgress.
  ///
  /// In es, this message translates to:
  /// **'Ver progreso'**
  String get routineViewProgress;

  /// No description provided for @routineExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get routineExport;

  /// No description provided for @routineExportCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar al portapapeles'**
  String get routineExportCopy;

  /// No description provided for @routineExportShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get routineExportShare;

  /// No description provided for @routineExportPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar PDF'**
  String get routineExportPdf;

  /// No description provided for @routineExportPdfError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo exportar la rutina en PDF'**
  String get routineExportPdfError;

  /// No description provided for @routineExportCopied.
  ///
  /// In es, this message translates to:
  /// **'Rutina copiada al portapapeles'**
  String get routineExportCopied;

  /// No description provided for @routineImport.
  ///
  /// In es, this message translates to:
  /// **'Importar rutina'**
  String get routineImport;

  /// No description provided for @routineImportHint.
  ///
  /// In es, this message translates to:
  /// **'Pega aquí el JSON de la rutina'**
  String get routineImportHint;

  /// No description provided for @routineImportSuccess.
  ///
  /// In es, this message translates to:
  /// **'Rutina importada correctamente'**
  String get routineImportSuccess;

  /// No description provided for @routineImportError.
  ///
  /// In es, this message translates to:
  /// **'JSON no válido o formato incorrecto'**
  String get routineImportError;

  /// No description provided for @progressTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get progressTitle;

  /// No description provided for @progressPeriod1m.
  ///
  /// In es, this message translates to:
  /// **'1 mes'**
  String get progressPeriod1m;

  /// No description provided for @progressPeriod3m.
  ///
  /// In es, this message translates to:
  /// **'3 meses'**
  String get progressPeriod3m;

  /// No description provided for @progressPeriod6m.
  ///
  /// In es, this message translates to:
  /// **'6 meses'**
  String get progressPeriod6m;

  /// No description provided for @progressPeriod12m.
  ///
  /// In es, this message translates to:
  /// **'12 meses'**
  String get progressPeriod12m;

  /// No description provided for @progressMetricVolume.
  ///
  /// In es, this message translates to:
  /// **'Volumen (kg)'**
  String get progressMetricVolume;

  /// No description provided for @progressMetricMaxWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso máximo'**
  String get progressMetricMaxWeight;

  /// No description provided for @progressMetricTotalReps.
  ///
  /// In es, this message translates to:
  /// **'Reps totales'**
  String get progressMetricTotalReps;

  /// No description provided for @progressFirstRecord.
  ///
  /// In es, this message translates to:
  /// **'Primer registro'**
  String get progressFirstRecord;

  /// No description provided for @progressLastRecord.
  ///
  /// In es, this message translates to:
  /// **'Último registro'**
  String get progressLastRecord;

  /// No description provided for @progressMinValue.
  ///
  /// In es, this message translates to:
  /// **'Mínimo'**
  String get progressMinValue;

  /// No description provided for @progressMaxValue.
  ///
  /// In es, this message translates to:
  /// **'Máximo'**
  String get progressMaxValue;

  /// No description provided for @progressNoData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos en este periodo'**
  String get progressNoData;

  /// No description provided for @progressHeaviestSet.
  ///
  /// In es, this message translates to:
  /// **'Serie más pesada'**
  String get progressHeaviestSet;

  /// No description provided for @progressCompareTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparar días'**
  String get progressCompareTitle;

  /// No description provided for @progressDay1.
  ///
  /// In es, this message translates to:
  /// **'Día 1'**
  String get progressDay1;

  /// No description provided for @progressDay2.
  ///
  /// In es, this message translates to:
  /// **'Día 2'**
  String get progressDay2;

  /// No description provided for @progressCompareXLabel.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get progressCompareXLabel;

  /// No description provided for @progressCompareYLabel.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones'**
  String get progressCompareYLabel;

  /// No description provided for @workoutPickRoutine.
  ///
  /// In es, this message translates to:
  /// **'Elige una rutina'**
  String get workoutPickRoutine;

  /// No description provided for @workoutPickDay.
  ///
  /// In es, this message translates to:
  /// **'Elige un día'**
  String get workoutPickDay;

  /// No description provided for @workoutStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get workoutStart;

  /// No description provided for @workoutFinish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar entrenamiento'**
  String get workoutFinish;

  /// No description provided for @workoutFinishConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres finalizar el entrenamiento?'**
  String get workoutFinishConfirm;

  /// No description provided for @workoutSets.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get workoutSets;

  /// No description provided for @workoutSet.
  ///
  /// In es, this message translates to:
  /// **'Serie {n}'**
  String workoutSet(String n);

  /// No description provided for @workoutReps.
  ///
  /// In es, this message translates to:
  /// **'Reps'**
  String get workoutReps;

  /// No description provided for @workoutWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get workoutWeight;

  /// No description provided for @workoutNotes.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get workoutNotes;

  /// No description provided for @workoutFinishSet.
  ///
  /// In es, this message translates to:
  /// **'Finalizar serie {n}'**
  String workoutFinishSet(String n);

  /// No description provided for @workoutSetCompleted.
  ///
  /// In es, this message translates to:
  /// **'Finalizada'**
  String get workoutSetCompleted;

  /// No description provided for @workoutFinishExercise.
  ///
  /// In es, this message translates to:
  /// **'Finalizar ejercicio'**
  String get workoutFinishExercise;

  /// No description provided for @workoutSaveExercise.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get workoutSaveExercise;

  /// No description provided for @workoutExerciseDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get workoutExerciseDone;

  /// No description provided for @workoutAddSet.
  ///
  /// In es, this message translates to:
  /// **'Añadir serie'**
  String get workoutAddSet;

  /// No description provided for @workoutRemoveSet.
  ///
  /// In es, this message translates to:
  /// **'Quitar serie'**
  String get workoutRemoveSet;

  /// No description provided for @workoutElapsed.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get workoutElapsed;

  /// No description provided for @workoutNoRoutines.
  ///
  /// In es, this message translates to:
  /// **'Crea una rutina primero'**
  String get workoutNoRoutines;

  /// No description provided for @workoutSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get workoutSaveChanges;

  /// No description provided for @workoutRestTimer.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get workoutRestTimer;

  /// No description provided for @workoutAvgRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso medio: {rest}'**
  String workoutAvgRest(String rest);

  /// No description provided for @workoutSessionsForDay.
  ///
  /// In es, this message translates to:
  /// **'Entrenamientos del día'**
  String get workoutSessionsForDay;

  /// No description provided for @workoutSessionTime.
  ///
  /// In es, this message translates to:
  /// **'{start} - {end}'**
  String workoutSessionTime(String start, String end);

  /// No description provided for @workoutSessionNoTime.
  ///
  /// In es, this message translates to:
  /// **'Sin registro de tiempo'**
  String get workoutSessionNoTime;

  /// No description provided for @workoutDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Día {day}'**
  String workoutDayLabel(String day);

  /// No description provided for @basicInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Información básica'**
  String get basicInfoTitle;

  /// No description provided for @basicInfoBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get basicInfoBirthDate;

  /// No description provided for @basicInfoBirthDateHint.
  ///
  /// In es, this message translates to:
  /// **'Pulsa para seleccionar'**
  String get basicInfoBirthDateHint;

  /// No description provided for @basicInfoSex.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get basicInfoSex;

  /// No description provided for @basicInfoSexMale.
  ///
  /// In es, this message translates to:
  /// **'Hombre'**
  String get basicInfoSexMale;

  /// No description provided for @basicInfoSexFemale.
  ///
  /// In es, this message translates to:
  /// **'Mujer'**
  String get basicInfoSexFemale;

  /// No description provided for @basicInfoWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get basicInfoWeight;

  /// No description provided for @basicInfoHeight.
  ///
  /// In es, this message translates to:
  /// **'Altura (cm)'**
  String get basicInfoHeight;

  /// No description provided for @basicInfoGymExperience.
  ///
  /// In es, this message translates to:
  /// **'Experiencia en gimnasio'**
  String get basicInfoGymExperience;

  /// No description provided for @basicInfoExpLessThan1.
  ///
  /// In es, this message translates to:
  /// **'<1 año'**
  String get basicInfoExpLessThan1;

  /// No description provided for @basicInfoExp1to3.
  ///
  /// In es, this message translates to:
  /// **'1-3 años'**
  String get basicInfoExp1to3;

  /// No description provided for @basicInfoExp3to5.
  ///
  /// In es, this message translates to:
  /// **'3-5 años'**
  String get basicInfoExp3to5;

  /// No description provided for @basicInfoExpMoreThan5.
  ///
  /// In es, this message translates to:
  /// **'>5 años'**
  String get basicInfoExpMoreThan5;

  /// No description provided for @advancedMeasures1Title.
  ///
  /// In es, this message translates to:
  /// **'Medidas avanzadas 1'**
  String get advancedMeasures1Title;

  /// No description provided for @advancedMeasures1ArmSpan.
  ///
  /// In es, this message translates to:
  /// **'Envergadura brazo a brazo (cm)'**
  String get advancedMeasures1ArmSpan;

  /// No description provided for @advancedMeasures1BicepsPerimeter.
  ///
  /// In es, this message translates to:
  /// **'Perímetro de bíceps (cm)'**
  String get advancedMeasures1BicepsPerimeter;

  /// No description provided for @advancedMeasures1ChestPerimeter.
  ///
  /// In es, this message translates to:
  /// **'Perímetro de pecho (cm)'**
  String get advancedMeasures1ChestPerimeter;

  /// No description provided for @advancedMeasures2Title.
  ///
  /// In es, this message translates to:
  /// **'Medidas avanzadas 2'**
  String get advancedMeasures2Title;

  /// No description provided for @advancedMeasures2WaistPerimeter.
  ///
  /// In es, this message translates to:
  /// **'Perímetro de cintura (cm)'**
  String get advancedMeasures2WaistPerimeter;

  /// No description provided for @advancedMeasures2QuadPerimeter.
  ///
  /// In es, this message translates to:
  /// **'Perímetro de cuádriceps (cm)'**
  String get advancedMeasures2QuadPerimeter;

  /// No description provided for @advancedMeasures2CalfPerimeter.
  ///
  /// In es, this message translates to:
  /// **'Perímetro de pantorrilla (cm)'**
  String get advancedMeasures2CalfPerimeter;

  /// No description provided for @goalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivos'**
  String get goalsTitle;

  /// No description provided for @goalsWeightObjective.
  ///
  /// In es, this message translates to:
  /// **'Objetivo de peso'**
  String get goalsWeightObjective;

  /// No description provided for @goalsTargetWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso objetivo (kg)'**
  String get goalsTargetWeight;

  /// No description provided for @goalsKcalToGain.
  ///
  /// In es, this message translates to:
  /// **'Kcal/día para ganar'**
  String get goalsKcalToGain;

  /// No description provided for @goalsKcalToLose.
  ///
  /// In es, this message translates to:
  /// **'Kcal/día para perder'**
  String get goalsKcalToLose;

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get welcomeTitle;

  /// No description provided for @welcomeMotivationalGain.
  ///
  /// In es, this message translates to:
  /// **'Es hora de construir. Cada repetición cuenta.'**
  String get welcomeMotivationalGain;

  /// No description provided for @welcomeMotivationalLose.
  ///
  /// In es, this message translates to:
  /// **'Más ligero, más fuerte, imparable.'**
  String get welcomeMotivationalLose;

  /// No description provided for @welcomeMotivationalMaintain.
  ///
  /// In es, this message translates to:
  /// **'Constancia es la clave. Sigue así.'**
  String get welcomeMotivationalMaintain;

  /// No description provided for @profileSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil'**
  String get profileSummaryTitle;
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
