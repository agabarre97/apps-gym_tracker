// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get sharedAppTitle => 'Gym: all in one';

  @override
  String get sharedNext => 'Siguiente';

  @override
  String get sharedBack => 'Atrás';

  @override
  String get sharedSkip => 'Omitir';

  @override
  String get sharedStart => 'Comenzar';

  @override
  String get sharedGain => 'Ganar';

  @override
  String get sharedLose => 'Perder';

  @override
  String get sharedMaintain => 'Mantener';

  @override
  String get sharedFieldRequired => 'Campo obligatorio';

  @override
  String sharedFieldInvalidRange(String min, String max) {
    return 'Valor fuera de rango ($min-$max)';
  }

  @override
  String get sharedNotAvailable => 'N/D';

  @override
  String get sharedLanguageToggle => 'Idioma';

  @override
  String sharedStepOf(String current, String total) {
    return 'Paso $current de $total';
  }

  @override
  String get sharedConfirm => 'Confirmar';

  @override
  String get sharedCancel => 'Cancelar';

  @override
  String get sharedSave => 'Guardar';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authSignUp => 'Crear cuenta';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authSignInWithGoogle => 'Continuar con Google';

  @override
  String get authSignOut => 'Cerrar sesión';

  @override
  String get authSignOutConfirm => '¿Quieres cerrar sesión?';

  @override
  String get authErrorWrongPassword => 'Contraseña incorrecta';

  @override
  String get authErrorEmailInUse => 'Este correo ya está registrado';

  @override
  String get authErrorInvalidEmail => 'Correo electrónico no válido';

  @override
  String get authErrorWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get authErrorUserNotFound => 'No existe una cuenta con este correo';

  @override
  String get authErrorGeneric => 'Error de autenticación. Inténtalo de nuevo';

  @override
  String get authSyncing => 'Sincronizando datos...';

  @override
  String get authOr => 'O';

  @override
  String get landingTrain => 'Entrenar';

  @override
  String get landingRoutines => 'Mis rutinas';

  @override
  String get landingCreateRoutine => 'Crear rutina';

  @override
  String get landingNoRoutines => 'Aún no tienes rutinas';

  @override
  String get landingRoutineName => 'Nombre de la rutina';

  @override
  String get landingDeleteRoutine => 'Eliminar';

  @override
  String get landingAddTraining => 'Añadir entrenamiento';

  @override
  String get landingViewDetails => 'Ver entrenamientos';

  @override
  String get landingFilterAll => 'Todos';

  @override
  String get landingMarkTrainingTitle => 'Registrar entrenamiento';

  @override
  String landingMarkTrainingBody(String routineName) {
    return '¿Registrar $routineName para este día?';
  }

  @override
  String get landingMarkTrainingConfirm => 'Registrar';

  @override
  String get landingTrainingMarked => 'Entrenamiento registrado';

  @override
  String get landingDeleteTrainingTitle => 'Eliminar entrenamiento';

  @override
  String landingDeleteTrainingBody(String name) {
    return '¿Eliminar $name de este día?';
  }

  @override
  String get landingDeleteTrainingConfirm => 'Eliminar';

  @override
  String get landingOptionalStartTime => 'Hora de inicio (opcional)';

  @override
  String get landingOptionalEndTime => 'Hora de fin (opcional)';

  @override
  String get landingNoTime => 'Sin hora';

  @override
  String get landingTrainingDeleted => 'Entrenamiento eliminado';

  @override
  String get landingTrainingTypeMobility => 'Movilidad';

  @override
  String get landingTrainingTypeHiit => 'HIIT';

  @override
  String get landingTrainingTypeWorkout => 'Musculación';

  @override
  String get routineSelectType => 'Tipo de rutina';

  @override
  String get routineMusculacion => 'Musculación';

  @override
  String get routinePliometricos => 'Pliométricos';

  @override
  String get routineMovilidad => 'Movilidad';

  @override
  String get routineHiit => 'HIIT';

  @override
  String get routineComingSoon => 'Próximamente';

  @override
  String get mobilityCadera => 'Cadera';

  @override
  String get mobilityTobillos => 'Tobillos';

  @override
  String get mobilityCustomRoutine => 'Crear rutina personalizada';

  @override
  String get mobilityRecommendedRoutine => 'Rutina recomendada';

  @override
  String get mobilityChooseOption => 'Elige una opción';

  @override
  String get mobilityFeetAnkles2 => 'Movilidad de tobillo';

  @override
  String get mobilityPelvicTilt => 'Inclinación Pélvica';

  @override
  String get mobilityHips => 'Caderas';

  @override
  String get mobilityRelajacion => 'Relajación';

  @override
  String get mobilitySleep => 'Sueño';

  @override
  String get mobilityTimerTitle => 'Movilidad';

  @override
  String mobilityExerciseOf(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get mobilityLeftSide => 'Lado izquierdo';

  @override
  String get mobilityRightSide => 'Lado derecho';

  @override
  String get mobilityBothSides => 'Ambos lados';

  @override
  String get mobilityRest => 'Descanso';

  @override
  String get mobilityRestOff => 'Sin descanso';

  @override
  String mobilityRestSeconds(Object seconds) {
    return '${seconds}s';
  }

  @override
  String get mobilityComplete => '¡Completado!';

  @override
  String get mobilitySound => 'Sonido';

  @override
  String get mobilityRestDuration => 'Descanso entre ejercicios';

  @override
  String get mobilitySettings => 'Ajustes';

  @override
  String get mobilityInfoInstructions => 'Instrucciones';

  @override
  String get mobilityInfoTips => 'Consejos';

  @override
  String get mobilityInfoModifications => 'Modificaciones';

  @override
  String get mobilityInfoBenefits => 'Beneficios';

  @override
  String get mobilitySingleLegStand => 'Apoyo a una pierna';

  @override
  String get mobilityAnkleCircles => 'Círculos de tobillo';

  @override
  String get mobilityHeelToToeRocks => 'Balanceo talón-punta';

  @override
  String get mobilityLateralFootRocks => 'Balanceo lateral del pie';

  @override
  String get mobilityKneeCircles => 'Círculos de rodilla';

  @override
  String get mobilitySoleusStretch => 'Estiramiento de sóleo';

  @override
  String get mobilityLeaningCalf => 'Estiramiento de gemelo';

  @override
  String get mobilityToeToWall => 'Punta contra pared';

  @override
  String get mobilityStandingQuad => 'Estiramiento de cuádriceps';

  @override
  String get mobilitySingleLegCalfStretch =>
      'Estiramiento de gemelo a una pierna';

  @override
  String get mobilitySingleLegShinStretch =>
      'Estiramiento de tibial a una pierna';

  @override
  String get mobilityToeStretch => 'Estiramiento de dedos';

  @override
  String get mobilityThunderbolt => 'Postura del rayo';

  @override
  String get mobilityToeSquat => 'Sentadilla de dedos';

  @override
  String get mobilityPelvicTiltExercise => 'Inclinación pélvica';

  @override
  String get mobilityGluteBridge => 'Puente de glúteos';

  @override
  String get mobilityKneesToChest => 'Rodillas al pecho';

  @override
  String get mobilitySingleKneeToChest => 'Rodilla al pecho';

  @override
  String get mobilityLyingQuadStretch => 'Estiramiento de cuádriceps tumbado';

  @override
  String get mobilityKneelingHipFlexor => 'Flexor de cadera de rodillas';

  @override
  String get mobilityCatCow => 'Gato-Vaca';

  @override
  String get mobilitySeatedButterfly => 'Mariposa sentada';

  @override
  String get mobilityLyingFigureFour => 'Figura cuatro tumbado';

  @override
  String get mobilityLizardPose => 'Postura del lagarto';

  @override
  String get mobilityPigeon => 'Paloma';

  @override
  String get mobilityFoldedButterfly => 'Mariposa plegada';

  @override
  String get mobilityHappyBaby => 'Bebé feliz';

  @override
  String get mobilityFrogPose => 'Postura de la rana';

  @override
  String get mobilitySquatStretch => 'Estiramiento en sentadilla';

  @override
  String get mobilityDoublePigeon => 'Doble paloma';

  @override
  String get mobilityReclinedButterfly => 'Mariposa reclinada';

  @override
  String get mobilityRagDoll => 'Muñeca de trapo';

  @override
  String get mobilityUpwardDog => 'Perro boca arriba';

  @override
  String get mobilityChildsPose => 'Postura del niño';

  @override
  String get mobilitySpinalTwist => 'Torsión espinal';

  @override
  String get mobilityQuadStretch => 'Estiramiento de cuádriceps';

  @override
  String get mobilityLegsUpWall => 'Piernas en la pared';

  @override
  String get mobilityRoutineNotFound => 'No se encontró la rutina de movilidad';

  @override
  String mobilityRoutineDuration(String minutes) {
    return '$minutes min';
  }

  @override
  String mobilityRoutineExerciseCount(String count) {
    return '$count ejercicios';
  }

  @override
  String get mobilityNextExercise => 'Siguiente';

  @override
  String get mobilityGetReady => '¡Prepárate!';

  @override
  String get mobilityFinishEarly => 'Finalizar';

  @override
  String get mobilityFinishEarlyConfirm => '¿Quieres finalizar la rutina?';

  @override
  String get hiitSelectExercises => 'Selecciona ejercicios';

  @override
  String get hiitEditExercises => 'Editar ejercicios';

  @override
  String get hiitWarningTooMany =>
      'No se recomienda seleccionar más de 6 ejercicios';

  @override
  String get hiitConfig => 'Configuración';

  @override
  String get hiitSets => 'Series';

  @override
  String get hiitWorkDuration => 'Tiempo de trabajo';

  @override
  String get hiitRestDuration => 'Descanso entre ejercicios';

  @override
  String get hiitSetRestDuration => 'Descanso entre series';

  @override
  String get hiitTotalDuration => 'Duración total';

  @override
  String get hiitTimerTitle => 'HIIT';

  @override
  String hiitSetOf(String current, String total) {
    return 'Serie $current / $total';
  }

  @override
  String hiitExerciseOf(String current, String total) {
    return 'Ejercicio $current / $total';
  }

  @override
  String get hiitRest => 'Descanso';

  @override
  String get hiitSetRest => 'Descanso entre series';

  @override
  String get hiitComplete => '¡Completado!';

  @override
  String get hiitGetReady => '¡Prepárate!';

  @override
  String get hiitFinishEarly => 'Finalizar';

  @override
  String get hiitFinishEarlyConfirm => '¿Quieres finalizar el HIIT?';

  @override
  String hiitSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String hiitMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String hiitExerciseCount(String count) {
    return '$count ejercicios';
  }

  @override
  String hiitSetCount(String count) {
    return '$count series';
  }

  @override
  String get hiitNextExercise => 'Siguiente';

  @override
  String get hiitSetComplete => 'Serie completada';

  @override
  String get routineSelectDays => '¿Cuántos días por semana?';

  @override
  String routineDayOf(String current, String total) {
    return 'Día $current de $total';
  }

  @override
  String routineDaysCount(String count) {
    return '$count días';
  }

  @override
  String get routineSelectMuscleGroups => 'Grupos musculares';

  @override
  String get exerciseSearchHint => 'Buscar ejercicio...';

  @override
  String get routineSelectExercises => 'Selecciona ejercicios';

  @override
  String get routineExerciseDetail => 'Detalle del ejercicio';

  @override
  String get routineAdd => 'Añadir';

  @override
  String get routineRemove => 'Quitar';

  @override
  String routineSelected(String count) {
    return '$count seleccionados';
  }

  @override
  String get routineSummaryTitle => 'Resumen de rutina';

  @override
  String get routineNameHint => 'Nombre de la rutina';

  @override
  String get routineNameRequired =>
      'Por favor, introduce un nombre para la rutina.';

  @override
  String get routineNeedsExercises =>
      'Añade al menos un ejercicio antes de guardar.';

  @override
  String get routineSave => 'Guardar rutina';

  @override
  String get routineDifficulty => 'Dificultad';

  @override
  String get routineMuscles => 'Músculos';

  @override
  String routineDayLabel(String day) {
    return 'Día $day';
  }

  @override
  String get routineExercises => 'ejercicios';

  @override
  String get routineDeleteTitle => 'Eliminar rutina';

  @override
  String routineDeleteConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?';
  }

  @override
  String get routineDelete => 'Eliminar';

  @override
  String get routineEditDay => 'Editar';

  @override
  String get routineViewProgress => 'Ver progreso';

  @override
  String get routineExport => 'Exportar';

  @override
  String get routineExportCopy => 'Copiar al portapapeles';

  @override
  String get routineExportShare => 'Compartir';

  @override
  String get routineExportPdf => 'Exportar PDF';

  @override
  String get routineExportPdfError => 'No se pudo exportar la rutina en PDF';

  @override
  String get routineExportCopied => 'Rutina copiada al portapapeles';

  @override
  String get routineImport => 'Importar rutina';

  @override
  String get routineImportHint => 'Pega aquí el JSON de la rutina';

  @override
  String get routineImportSuccess => 'Rutina importada correctamente';

  @override
  String get routineImportError => 'JSON no válido o formato incorrecto';

  @override
  String get customExerciseCreate => 'Crear ejercicio personalizado';

  @override
  String get customExerciseCreateTitle => 'Crear ejercicio personalizado';

  @override
  String get customExerciseCreatePersonalized =>
      'Crear ejercicio personalizado';

  @override
  String get customExerciseName => 'Nombre del ejercicio';

  @override
  String get customExerciseNameRequired => 'El nombre es obligatorio';

  @override
  String get customExerciseDescription => 'Descripción breve (opcional)';

  @override
  String get customExerciseMuscles => 'Grupos musculares';

  @override
  String get customExerciseMusclesRequired =>
      'Selecciona al menos un grupo muscular';

  @override
  String get customExerciseFront => 'Frontal';

  @override
  String get customExerciseBack => 'Posterior';

  @override
  String get customExerciseSaved => 'Ejercicio guardado';

  @override
  String get customExerciseNoResults => 'No hay ejercicios para esta búsqueda';

  @override
  String get customExerciseAddMuscleManual => 'Añadir músculo';

  @override
  String get customExerciseDeleteConfirmTitle => '¿Eliminar ejercicio?';

  @override
  String get customExerciseDeleteConfirmBody =>
      'Esta acción no se puede deshacer. Se eliminará de forma permanente.';

  @override
  String get customExerciseDelete => 'Eliminar';

  @override
  String get customExerciseCancel => 'Cancelar';

  @override
  String get progressTitle => 'Progreso';

  @override
  String get progressPeriod1m => '1 mes';

  @override
  String get progressPeriod3m => '3 meses';

  @override
  String get progressPeriod6m => '6 meses';

  @override
  String get progressPeriod12m => '12 meses';

  @override
  String get progressMetricVolume => 'Volumen (kg)';

  @override
  String get progressMetricMaxWeight => 'Peso máximo';

  @override
  String get progressMetricTotalReps => 'Reps totales';

  @override
  String get progressFirstRecord => 'Primer registro';

  @override
  String get progressLastRecord => 'Último registro';

  @override
  String get progressMinValue => 'Mínimo';

  @override
  String get progressMaxValue => 'Máximo';

  @override
  String get progressNoData => 'No hay datos en este periodo';

  @override
  String get progressHeaviestSet => 'Serie más pesada';

  @override
  String get progressCompareTitle => 'Comparar días';

  @override
  String get progressDay1 => 'Día 1';

  @override
  String get progressDay2 => 'Día 2';

  @override
  String get progressCompareXLabel => 'Peso (kg)';

  @override
  String get progressCompareYLabel => 'Repeticiones';

  @override
  String get workoutPickRoutine => 'Elige una rutina';

  @override
  String get workoutPickDay => 'Elige un día';

  @override
  String get workoutStart => 'Comenzar';

  @override
  String get workoutFinish => 'Finalizar entrenamiento';

  @override
  String get workoutFinishConfirm => '¿Quieres finalizar el entrenamiento?';

  @override
  String get workoutSavePrompt => '¿Quieres guardar el entrenamiento?';

  @override
  String get workoutSaveYes => 'Sí';

  @override
  String get workoutSaveNo => 'No';

  @override
  String get workoutSets => 'Series';

  @override
  String workoutSet(String n) {
    return 'Serie $n';
  }

  @override
  String get workoutReps => 'Reps';

  @override
  String get workoutWeight => 'Peso (kg)';

  @override
  String get workoutNotes => 'Observaciones';

  @override
  String workoutFinishSet(String n) {
    return 'Finalizar serie $n';
  }

  @override
  String get workoutSetCompleted => 'Finalizada';

  @override
  String get workoutFinishExercise => 'Finalizar ejercicio';

  @override
  String get workoutSaveExercise => 'Guardar';

  @override
  String get workoutExerciseDone => 'Hecho';

  @override
  String get workoutAddSet => 'Añadir serie';

  @override
  String get workoutRemoveSet => 'Quitar serie';

  @override
  String get workoutElapsed => 'Tiempo';

  @override
  String get workoutNoRoutines => 'Crea una rutina primero';

  @override
  String get workoutSessionInProgress => 'Entrenamiento en progreso';

  @override
  String get workoutSessionInProgressBody =>
      'Tienes un entrenamiento sin finalizar hoy. ¿Quieres retomarlo?';

  @override
  String get workoutSessionNew => 'Nuevo';

  @override
  String get workoutSessionResume => 'Retomar';

  @override
  String get workoutSaveChanges => 'Guardar entrenamiento';

  @override
  String get workoutRestTimer => 'Descanso';

  @override
  String workoutAvgRest(String rest) {
    return 'Descanso medio: $rest';
  }

  @override
  String get workoutSessionsForDay => 'Entrenamientos del día';

  @override
  String workoutSessionTime(String start, String end) {
    return '$start - $end';
  }

  @override
  String get workoutSessionNoTime => 'Sin registro de tiempo';

  @override
  String workoutDayLabel(String day) {
    return 'Día $day';
  }

  @override
  String get basicInfoTitle => 'Información básica';

  @override
  String get basicInfoBirthDate => 'Fecha de nacimiento';

  @override
  String get basicInfoBirthDateHint => 'Pulsa para seleccionar';

  @override
  String get basicInfoSex => 'Sexo';

  @override
  String get basicInfoSexMale => 'Hombre';

  @override
  String get basicInfoSexFemale => 'Mujer';

  @override
  String get basicInfoWeight => 'Peso (kg)';

  @override
  String get basicInfoHeight => 'Altura (cm)';

  @override
  String get basicInfoGymExperience => 'Experiencia en gimnasio';

  @override
  String get basicInfoExpLessThan1 => '<1 año';

  @override
  String get basicInfoExp1to3 => '1-3 años';

  @override
  String get basicInfoExp3to5 => '3-5 años';

  @override
  String get basicInfoExpMoreThan5 => '>5 años';

  @override
  String get advancedMeasures1Title => 'Medidas avanzadas';

  @override
  String get advancedMeasures1ArmSpan => 'Envergadura brazo a brazo (cm)';

  @override
  String get advancedMeasures1BicepsPerimeter => 'Perímetro de bíceps (cm)';

  @override
  String get advancedMeasures1ChestPerimeter => 'Perímetro de pecho (cm)';

  @override
  String get advancedMeasures2Title => 'Medidas avanzadas 2';

  @override
  String get advancedMeasures2WaistPerimeter => 'Perímetro de cintura (cm)';

  @override
  String get advancedMeasures2QuadPerimeter => 'Perímetro de cuádriceps (cm)';

  @override
  String get advancedMeasures2CalfPerimeter => 'Perímetro de pantorrilla (cm)';

  @override
  String get goalsTitle => 'Objetivos';

  @override
  String get goalsWeightObjective => 'Objetivo de peso';

  @override
  String get goalsTargetWeight => 'Peso objetivo (kg)';

  @override
  String get goalsKcalToGain => 'Kcal/día para ganar';

  @override
  String get goalsKcalToLose => 'Kcal/día para perder';

  @override
  String get welcomeTitle => 'Bienvenido';

  @override
  String get welcomeMotivationalGain =>
      'Es hora de construir. Cada repetición cuenta.';

  @override
  String get welcomeMotivationalLose => 'Más ligero, más fuerte, imparable.';

  @override
  String get welcomeMotivationalMaintain =>
      'Constancia es la clave. Sigue así.';

  @override
  String get profileSummaryTitle => 'Tu perfil';
}
