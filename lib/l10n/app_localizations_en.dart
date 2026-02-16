// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sharedAppTitle => 'Gym Tracker';

  @override
  String get sharedNext => 'Next';

  @override
  String get sharedBack => 'Back';

  @override
  String get sharedSkip => 'Skip';

  @override
  String get sharedStart => 'Start';

  @override
  String get sharedGain => 'Gain';

  @override
  String get sharedLose => 'Lose';

  @override
  String get sharedMaintain => 'Maintain';

  @override
  String get sharedFieldRequired => 'Required field';

  @override
  String sharedFieldInvalidRange(String min, String max) {
    return 'Value out of range ($min-$max)';
  }

  @override
  String get sharedNotAvailable => 'N/A';

  @override
  String get sharedLanguageToggle => 'Language';

  @override
  String sharedStepOf(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get sharedConfirm => 'Confirm';

  @override
  String get sharedCancel => 'Cancel';

  @override
  String get sharedSave => 'Save';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignInWithGoogle => 'Continue with Google';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authSignOutConfirm => 'Do you want to sign out?';

  @override
  String get authErrorWrongPassword => 'Wrong password';

  @override
  String get authErrorEmailInUse => 'This email is already registered';

  @override
  String get authErrorInvalidEmail => 'Invalid email address';

  @override
  String get authErrorWeakPassword => 'Password must be at least 6 characters';

  @override
  String get authErrorUserNotFound => 'No account found with this email';

  @override
  String get authErrorGeneric => 'Authentication error. Please try again';

  @override
  String get authSyncing => 'Syncing data...';

  @override
  String get authOr => 'OR';

  @override
  String get loadingMotto => 'Improve yourself';

  @override
  String get landingTrain => 'Train';

  @override
  String get landingRoutines => 'My routines';

  @override
  String get landingCreateRoutine => 'Create routine';

  @override
  String get landingNoRoutines => 'No routines yet';

  @override
  String get landingRoutineName => 'Routine name';

  @override
  String get landingDeleteRoutine => 'Delete';

  @override
  String get landingAddTraining => 'Add training';

  @override
  String get landingViewDetails => 'View details';

  @override
  String get landingFilterAll => 'All';

  @override
  String get routineSelectType => 'Routine type';

  @override
  String get routineMusculacion => 'Strength';

  @override
  String get routineAbdominales => 'Abs';

  @override
  String get routinePliometricos => 'Plyometrics';

  @override
  String get routineMovilidad => 'Mobility';

  @override
  String get routineHiit => 'HIIT';

  @override
  String get routineComingSoon => 'Coming soon';

  @override
  String get mobilityCadera => 'Hips';

  @override
  String get mobilityTobillos => 'Ankles';

  @override
  String get mobilityCustomRoutine => 'Create custom routine';

  @override
  String get mobilityRecommendedRoutine => 'Recommended routine';

  @override
  String get mobilityChooseOption => 'Choose an option';

  @override
  String get mobilityFeetAnkles2 => 'Feet & Ankles 2';

  @override
  String get mobilityPelvicTilt => 'Pelvic Tilt';

  @override
  String get mobilityHips => 'Hips';

  @override
  String get mobilityRelajacion => 'Relaxation';

  @override
  String get mobilitySleep => 'Sleep';

  @override
  String get mobilityTimerTitle => 'Mobility';

  @override
  String mobilityExerciseOf(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get mobilityLeftSide => 'Left side';

  @override
  String get mobilityRightSide => 'Right side';

  @override
  String get mobilityBothSides => 'Both sides';

  @override
  String get mobilityRest => 'Rest';

  @override
  String get mobilityRestOff => 'Off';

  @override
  String mobilityRestSeconds(Object seconds) {
    return '${seconds}s';
  }

  @override
  String get mobilityComplete => 'Complete!';

  @override
  String get mobilitySound => 'Sound';

  @override
  String get mobilityRestDuration => 'Rest between exercises';

  @override
  String get mobilitySettings => 'Settings';

  @override
  String get mobilityInfoInstructions => 'Instructions';

  @override
  String get mobilityInfoTips => 'Tips';

  @override
  String get mobilityInfoModifications => 'Modifications';

  @override
  String get mobilityInfoBenefits => 'Benefits';

  @override
  String get mobilitySingleLegStand => 'Single leg stand';

  @override
  String get mobilityAnkleCircles => 'Ankle circles';

  @override
  String get mobilityHeelToToeRocks => 'Heel-to-toe rocks';

  @override
  String get mobilityLateralFootRocks => 'Lateral foot rocks';

  @override
  String get mobilityKneeCircles => 'Knee circles';

  @override
  String get mobilitySoleusStretch => 'Soleus stretch';

  @override
  String get mobilityLeaningCalf => 'Leaning calf stretch';

  @override
  String get mobilityToeToWall => 'Toe-to-wall stretch';

  @override
  String get mobilityStandingQuad => 'Standing quad stretch';

  @override
  String get mobilitySingleLegCalfStretch => 'Single leg calf stretch';

  @override
  String get mobilitySingleLegShinStretch => 'Single leg shin stretch';

  @override
  String get mobilityToeStretch => 'Toe stretch';

  @override
  String get mobilityThunderbolt => 'Thunderbolt pose';

  @override
  String get mobilityToeSquat => 'Toe squat';

  @override
  String get mobilityPelvicTiltExercise => 'Pelvic Tilt';

  @override
  String get mobilityGluteBridge => 'Glute Bridge';

  @override
  String get mobilityKneesToChest => 'Knees to Chest';

  @override
  String get mobilitySingleKneeToChest => 'Single Knee to Chest';

  @override
  String get mobilityLyingQuadStretch => 'Lying Quad Stretch';

  @override
  String get mobilityKneelingHipFlexor => 'Kneeling Hip Flexor';

  @override
  String get mobilityCatCow => 'Cat-Cow';

  @override
  String get mobilitySeatedButterfly => 'Seated Butterfly';

  @override
  String get mobilityLyingFigureFour => 'Lying Figure Four';

  @override
  String get mobilityLizardPose => 'Lizard Pose';

  @override
  String get mobilityPigeon => 'Pigeon';

  @override
  String get mobilityFoldedButterfly => 'Folded Butterfly';

  @override
  String get mobilityHappyBaby => 'Happy Baby';

  @override
  String get mobilityFrogPose => 'Frog Pose';

  @override
  String get mobilitySquatStretch => 'Squat Stretch';

  @override
  String get mobilityDoublePigeon => 'Double Pigeon';

  @override
  String get mobilityReclinedButterfly => 'Reclined Butterfly';

  @override
  String get mobilityRagDoll => 'Rag Doll';

  @override
  String get mobilityUpwardDog => 'Upward Dog';

  @override
  String get mobilityChildsPose => 'Child\'s Pose';

  @override
  String get mobilitySpinalTwist => 'Spinal Twist';

  @override
  String get mobilityQuadStretch => 'Quad Stretch';

  @override
  String get mobilityLegsUpWall => 'Legs-up-wall';

  @override
  String get mobilityRoutineNotFound => 'Mobility routine not found';

  @override
  String mobilityRoutineDuration(String minutes) {
    return '$minutes min';
  }

  @override
  String mobilityRoutineExerciseCount(String count) {
    return '$count exercises';
  }

  @override
  String get mobilityNextExercise => 'Next';

  @override
  String get mobilityGetReady => 'Get ready!';

  @override
  String get mobilityFinishEarly => 'Finish';

  @override
  String get mobilityFinishEarlyConfirm => 'Do you want to finish the routine?';

  @override
  String get routineSelectDays => 'How many days per week?';

  @override
  String routineDayOf(String current, String total) {
    return 'Day $current of $total';
  }

  @override
  String routineDaysCount(String count) {
    return '$count days';
  }

  @override
  String get routineSelectMuscleGroups => 'Muscle groups';

  @override
  String get routineSelectExercises => 'Select exercises';

  @override
  String get routineExerciseDetail => 'Exercise detail';

  @override
  String get routineAdd => 'Add';

  @override
  String get routineRemove => 'Remove';

  @override
  String routineSelected(String count) {
    return '$count selected';
  }

  @override
  String get routineSummaryTitle => 'Routine summary';

  @override
  String get routineNameHint => 'Routine name';

  @override
  String get routineSave => 'Save routine';

  @override
  String get routineDifficulty => 'Difficulty';

  @override
  String get routineMuscles => 'Muscles';

  @override
  String routineDayLabel(String day) {
    return 'Day $day';
  }

  @override
  String get routineExercises => 'exercises';

  @override
  String get routineDeleteTitle => 'Delete routine';

  @override
  String routineDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get routineDelete => 'Delete';

  @override
  String get routineEditDay => 'Edit';

  @override
  String get routineViewProgress => 'View progress';

  @override
  String get routineExport => 'Export';

  @override
  String get routineExportCopy => 'Copy to clipboard';

  @override
  String get routineExportShare => 'Share';

  @override
  String get routineExportCopied => 'Routine copied to clipboard';

  @override
  String get routineImport => 'Import routine';

  @override
  String get routineImportHint => 'Paste routine JSON here';

  @override
  String get routineImportSuccess => 'Routine imported successfully';

  @override
  String get routineImportError => 'Invalid JSON or wrong format';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressPeriod1m => '1 month';

  @override
  String get progressPeriod3m => '3 months';

  @override
  String get progressPeriod6m => '6 months';

  @override
  String get progressPeriod12m => '12 months';

  @override
  String get progressMetricVolume => 'Volume (kg)';

  @override
  String get progressMetricMaxWeight => 'Max weight';

  @override
  String get progressMetricTotalReps => 'Total reps';

  @override
  String get progressFirstRecord => 'First record';

  @override
  String get progressLastRecord => 'Last record';

  @override
  String get progressMinValue => 'Min';

  @override
  String get progressMaxValue => 'Max';

  @override
  String get progressNoData => 'No data for this period';

  @override
  String get progressHeaviestSet => 'Heaviest set';

  @override
  String get progressCompareTitle => 'Compare days';

  @override
  String get progressDay1 => 'Day 1';

  @override
  String get progressDay2 => 'Day 2';

  @override
  String get progressCompareXLabel => 'Weight (kg)';

  @override
  String get progressCompareYLabel => 'Reps';

  @override
  String get workoutPickRoutine => 'Choose a routine';

  @override
  String get workoutPickDay => 'Choose a day';

  @override
  String get workoutStart => 'Start';

  @override
  String get workoutFinish => 'Finish workout';

  @override
  String get workoutFinishConfirm => 'Finish the workout?';

  @override
  String get workoutSets => 'Sets';

  @override
  String workoutSet(String n) {
    return 'Set $n';
  }

  @override
  String get workoutReps => 'Reps';

  @override
  String get workoutWeight => 'Weight (kg)';

  @override
  String get workoutNotes => 'Notes';

  @override
  String get workoutSaveExercise => 'Save';

  @override
  String get workoutExerciseDone => 'Done';

  @override
  String get workoutAddSet => 'Add set';

  @override
  String get workoutRemoveSet => 'Remove set';

  @override
  String get workoutElapsed => 'Time';

  @override
  String get workoutNoRoutines => 'Create a routine first';

  @override
  String get workoutSaveChanges => 'Save changes';

  @override
  String workoutAvgRest(String rest) {
    return 'Avg rest: $rest';
  }

  @override
  String get workoutSessionsForDay => 'Sessions for this day';

  @override
  String workoutSessionTime(String start, String end) {
    return '$start - $end';
  }

  @override
  String get workoutSessionNoTime => 'No time recorded';

  @override
  String workoutDayLabel(String day) {
    return 'Day $day';
  }

  @override
  String get basicInfoTitle => 'Basic Info';

  @override
  String get basicInfoBirthDate => 'Date of birth';

  @override
  String get basicInfoBirthDateHint => 'Tap to select';

  @override
  String get basicInfoSex => 'Sex';

  @override
  String get basicInfoSexMale => 'Male';

  @override
  String get basicInfoSexFemale => 'Female';

  @override
  String get basicInfoWeight => 'Weight (kg)';

  @override
  String get basicInfoHeight => 'Height (cm)';

  @override
  String get basicInfoGymExperience => 'Gym experience';

  @override
  String get basicInfoExpLessThan1 => '<1 year';

  @override
  String get basicInfoExp1to3 => '1-3 years';

  @override
  String get basicInfoExp3to5 => '3-5 years';

  @override
  String get basicInfoExpMoreThan5 => '>5 years';

  @override
  String get advancedMeasures1Title => 'Advanced Measures 1';

  @override
  String get advancedMeasures1ArmSpan => 'Arm-to-arm span (cm)';

  @override
  String get advancedMeasures1BicepsPerimeter => 'Biceps perimeter (cm)';

  @override
  String get advancedMeasures1ChestPerimeter => 'Chest perimeter (cm)';

  @override
  String get advancedMeasures2Title => 'Advanced Measures 2';

  @override
  String get advancedMeasures2WaistPerimeter => 'Waist perimeter (cm)';

  @override
  String get advancedMeasures2QuadPerimeter => 'Quad perimeter (cm)';

  @override
  String get advancedMeasures2CalfPerimeter => 'Calf perimeter (cm)';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsWeightObjective => 'Weight objective';

  @override
  String get goalsTargetWeight => 'Target weight (kg)';

  @override
  String get goalsKcalToGain => 'Kcal/day to gain';

  @override
  String get goalsKcalToLose => 'Kcal/day to lose';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeMotivationalGain => 'Time to build. Every rep counts.';

  @override
  String get welcomeMotivationalLose => 'Lighter, stronger, unstoppable.';

  @override
  String get welcomeMotivationalMaintain => 'Consistency is key. Keep it up.';

  @override
  String get profileSummaryTitle => 'Your Profile';
}
