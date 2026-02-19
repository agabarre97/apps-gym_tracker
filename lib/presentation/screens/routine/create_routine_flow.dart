import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_tracker/data/datasources/asset_data_loader.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_config.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_type_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/days_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_summary_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/mobility_subtype_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/mobility_option_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/mobility_routine_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_exercise_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_config_screen.dart';

/// Orchestrates the multi-step routine creation wizard.
class CreateRoutineFlow extends StatefulWidget {
  const CreateRoutineFlow({
    super.key,
    required this.routinePort,
    required this.existingRoutines,
    @visibleForTesting this.preloadedExercises,
    @visibleForTesting this.preloadedHiitExercises,
  });

  final RoutinePort routinePort;
  final List<Routine> existingRoutines;

  /// Exercises injected for testing (skips asset loading).
  @visibleForTesting
  final List<Exercise>? preloadedExercises;

  /// HIIT exercises injected for testing (skips asset loading).
  @visibleForTesting
  final List<HiitExercise>? preloadedHiitExercises;

  @override
  State<CreateRoutineFlow> createState() => _CreateRoutineFlowState();
}

class _CreateRoutineFlowState extends State<CreateRoutineFlow> {
  static const _uuid = Uuid();

  // ── Mobility routine registry ──────────────────────────────────

  /// Localized display name for each recommended mobility routine key.
  static final Map<String, String Function(AppLocalizations)>
      _routineNameGetters = {
    'feet_ankles_2': (l) => l.mobilityFeetAnkles2,
    'pelvic_tilt': (l) => l.mobilityPelvicTilt,
    'hips': (l) => l.mobilityHips,
    'sleep': (l) => l.mobilitySleep,
  };

  /// Available recommended routines per mobility subtype.
  static const _routinesBySubType = <String, List<String>>{
    'tobillos': ['feet_ankles_2'],
    'cadera': ['pelvic_tilt', 'hips'],
    'relajacion': ['sleep'],
  };

  // Accumulated state
  String? _selectedType;
  String? _selectedMobilitySubType;
  int _numDays = 3;
  int _currentDayIndex = 0;

  // Completed days
  final List<List<String>> _dayMuscleGroups = [];
  final List<List<String>> _dayExerciseKeys = [];

  // Current day in-progress state
  List<String> _currentMuscleSelection = [];
  List<String> _currentExerciseSelection = [];
  List<String> _availableCategories = [];

  // All exercises (loaded once)
  List<Exercise> _allExercises = [];
  bool _exercisesLoaded = false;

  // HIIT state
  List<HiitExercise> _hiitExercises = [];
  bool _hiitExercisesLoaded = false;
  List<String> _hiitSelectedKeys = [];

  // Logical step
  _Step _step = _Step.type;

  Future<void> _loadExercises() async {
    if (_exercisesLoaded) return;
    if (widget.preloadedExercises != null) {
      _allExercises = widget.preloadedExercises!;
      _availableCategories = byMuscleCategoryOrder;
    } else {
      final lang = Localizations.localeOf(context).languageCode;
      final catalog = await AssetDataLoader.loadByMuscleCatalog(lang);
      _allExercises = catalog.exercises;
      _availableCategories = catalog.categories;
    }
    _exercisesLoaded = true;
    if (mounted) setState(() {});
  }

  Future<void> _loadHiitExercises() async {
    if (_hiitExercisesLoaded) return;
    if (widget.preloadedHiitExercises != null) {
      _hiitExercises = widget.preloadedHiitExercises!;
    } else {
      final lang = Localizations.localeOf(context).languageCode;
      _hiitExercises = await AssetDataLoader.loadHiitExercises(lang);
    }
    _hiitExercisesLoaded = true;
    if (mounted) setState(() {});
  }

  // ── Import ────────────────────────────────────────────────────

  Future<void> _onImport() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final jsonString = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.routineImport,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: l10n.routineImportHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(l10n.routineImport),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (jsonString == null || jsonString.trim().isEmpty || !mounted) return;

    try {
      final routine = Routine.fromImportJsonString(
        jsonString,
        id: _uuid.v4(),
      );
      final updated = [...widget.existingRoutines, routine];
      await widget.routinePort.saveRoutines(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineImportSuccess)),
      );
      Navigator.of(context).pop(true);
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineImportError)),
      );
    }
  }

  // ── Forward navigation ────────────────────────────────────────

  void _onTypeSelected(String type) {
    setState(() {
      _selectedType = type;
      if (type == 'movilidad') {
        _step = _Step.mobilitySubType;
      } else if (type == 'hiit') {
        _step = _Step.hiitExercises;
      } else {
        _step = _Step.days;
      }
    });
  }

  void _onMobilitySubTypeSelected(String subType) {
    setState(() {
      _selectedMobilitySubType = subType;
      _step = _Step.mobilityOption;
    });
  }

  Future<void> _onMobilityOptionSelected(String option) async {
    if (option == 'recommended') {
      final routines = _routinesBySubType[_selectedMobilitySubType] ?? const [];
      if (routines.length == 1) {
        await _saveRecommendedMobilityRoutine(routines.first);
      } else if (routines.isNotEmpty) {
        setState(() => _step = _Step.mobilityRoutineSelection);
      }
      return;
    }
    // Custom: not implemented yet
    if (option == 'custom') {
      // TODO: navigate to custom mobility flow
      return;
    }
  }

  Future<void> _saveRecommendedMobilityRoutine(String routineKey) async {
    final l10n = AppLocalizations.of(context)!;
    final nameGetter = _routineNameGetters[routineKey];
    final name = nameGetter != null ? nameGetter(l10n) : routineKey;

    final routine = Routine(
      id: _uuid.v4(),
      name: name,
      type: RoutineType.movilidad.value,
      days: const [],
      recommendedRoutineKey: routineKey,
    );

    final updated = [...widget.existingRoutines, routine];
    await widget.routinePort.saveRoutines(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _onDaysConfirmed(int days) {
    setState(() {
      _numDays = days;
      _currentDayIndex = 0;
      _dayMuscleGroups.clear();
      _dayExerciseKeys.clear();
      _currentMuscleSelection = [];
      _currentExerciseSelection = [];
      _step = _Step.exercises;
    });
  }

  void _onExercisesConfirmed(ExerciseSelectionResult result) {
    setState(() {
      // Save completed day
      _dayMuscleGroups.add(List.of(result.selectedCategories));
      _dayExerciseKeys.add(List.of(result.selectedExerciseKeys));

      // Clear current-day state
      _currentMuscleSelection = [];
      _currentExerciseSelection = [];

      if (_currentDayIndex < _numDays - 1) {
        _currentDayIndex++;
        _step = _Step.exercises;
      } else {
        _step = _Step.summary;
      }
    });
  }

  void _onHiitExercisesConfirmed(List<String> keys) {
    setState(() {
      _hiitSelectedKeys = keys;
      _step = _Step.hiitConfig;
    });
  }

  Future<void> _onHiitSave({
    required String name,
    required int sets,
    required int workSeconds,
    required int restSeconds,
    required int setRestSeconds,
  }) async {
    final routine = Routine(
      id: _uuid.v4(),
      name: name,
      type: RoutineType.hiit.value,
      days: [
        RoutineDay(
          muscleGroups: const [],
          exerciseKeys: _hiitSelectedKeys,
        ),
      ],
      hiitConfig: HiitConfig(
        sets: sets,
        workSeconds: workSeconds,
        restSeconds: restSeconds,
        setRestSeconds: setRestSeconds,
      ),
    );

    final updated = [...widget.existingRoutines, routine];
    await widget.routinePort.saveRoutines(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _editDayFromSummary(int dayIndex) async {
    final categories = _dayMuscleGroups[dayIndex];
    final currentKeys = _dayExerciseKeys[dayIndex];

    final result = await Navigator.of(context).push<ExerciseSelectionResult>(
      MaterialPageRoute(
        builder: (_) => ExerciseSelectionScreen(
          currentDay: dayIndex + 1,
          totalDays: _numDays,
          allExercises: _allExercises,
          availableCategories: _availableCategories,
          initialSelectedCategories: categories,
          initialSelectedKeys: currentKeys,
          onConfirmed: (selectionResult) =>
              Navigator.of(context).pop(selectionResult),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _dayMuscleGroups[dayIndex] = result.selectedCategories;
      _dayExerciseKeys[dayIndex] = result.selectedExerciseKeys;
    });
  }

  Future<void> _onSave(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.routineNameRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final days = <RoutineDay>[];
    for (var i = 0; i < _dayMuscleGroups.length; i++) {
      days.add(RoutineDay(
        muscleGroups: _dayMuscleGroups[i],
        exerciseKeys: _dayExerciseKeys[i],
      ));
    }

    if (days.isEmpty || days.every((d) => d.exerciseKeys.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.routineNeedsExercises),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final routine = Routine(
      id: _uuid.v4(),
      name: trimmedName,
      type: _selectedType!,
      days: days,
    );

    final updated = [...widget.existingRoutines, routine];
    await widget.routinePort.saveRoutines(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true); // signal success
  }

  // ── Back navigation ───────────────────────────────────────────

  void _goBack() {
    setState(() {
      switch (_step) {
        case _Step.type:
          Navigator.of(context).pop();
          return;

        case _Step.mobilitySubType:
          _step = _Step.type;
          return;

        case _Step.mobilityOption:
          _step = _Step.mobilitySubType;
          return;

        case _Step.mobilityRoutineSelection:
          _step = _Step.mobilityOption;
          return;

        case _Step.hiitExercises:
          _step = _Step.type;
          return;

        case _Step.hiitConfig:
          _step = _Step.hiitExercises;
          return;

        case _Step.days:
          _step = _Step.type;

        case _Step.exercises:
          if (_currentDayIndex > 0 && _dayExerciseKeys.isNotEmpty) {
            _currentDayIndex--;
            _currentMuscleSelection = _dayMuscleGroups.removeLast();
            _currentExerciseSelection = _dayExerciseKeys.removeLast();
            _step = _Step.exercises;
          } else {
            _step = _Step.days;
          }

        case _Step.summary:
          // Go back to last day's exercise selection.
          _currentDayIndex = _numDays - 1;
          _currentMuscleSelection = _dayMuscleGroups.removeLast();
          _currentExerciseSelection = _dayExerciseKeys.removeLast();
          _step = _Step.exercises;
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.type,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _Step.type:
        return RoutineTypeScreen(
          onTypeSelected: _onTypeSelected,
          onBack: () => Navigator.of(context).pop(),
          onImport: _onImport,
        );
      case _Step.mobilitySubType:
        return MobilitySubTypeScreen(
          onSubTypeSelected: _onMobilitySubTypeSelected,
          onBack: _goBack,
        );
      case _Step.mobilityOption:
        return MobilityOptionScreen(
          subType: _selectedMobilitySubType!,
          customEnabled: false,
          recommendedEnabled:
              (_routinesBySubType[_selectedMobilitySubType]?.isNotEmpty ??
                  false),
          onOptionSelected: _onMobilityOptionSelected,
          onBack: _goBack,
        );
      case _Step.mobilityRoutineSelection:
        final routines =
            _routinesBySubType[_selectedMobilitySubType] ?? const [];
        return MobilityRoutineSelectionScreen(
          routineKeys: routines,
          routineNameGetters: _routineNameGetters,
          onRoutineSelected: _saveRecommendedMobilityRoutine,
          onBack: _goBack,
        );
      case _Step.days:
        return DaysSelectionScreen(
          initialDays: _numDays,
          onConfirmed: _onDaysConfirmed,
          onBack: _goBack,
        );
      case _Step.exercises:
        _loadExercises();
        if (!_exercisesLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return ExerciseSelectionScreen(
          key: ValueKey('exercises_$_currentDayIndex'),
          currentDay: _currentDayIndex + 1,
          totalDays: _numDays,
          allExercises: _allExercises,
          availableCategories: _availableCategories,
          initialSelectedCategories: _currentMuscleSelection,
          initialSelectedKeys: _currentExerciseSelection,
          onConfirmed: _onExercisesConfirmed,
          onBack: _goBack,
        );
      case _Step.hiitExercises:
        _loadHiitExercises();
        return HiitExerciseSelectionScreen(
          key: const ValueKey('hiitExercises'),
          exercises: _hiitExercises,
          initialSelectedKeys: _hiitSelectedKeys,
          onConfirmed: _onHiitExercisesConfirmed,
          onBack: _goBack,
        );
      case _Step.hiitConfig:
        return HiitConfigScreen(
          exerciseCount: _hiitSelectedKeys.length,
          onSave: _onHiitSave,
          onBack: _goBack,
        );
      case _Step.summary:
        return RoutineSummaryScreen(
          type: _selectedType!,
          dayMuscleGroups: _dayMuscleGroups,
          dayExerciseKeys: _dayExerciseKeys,
          allExercises: _allExercises,
          onSave: _onSave,
          onBack: _goBack,
          onEditDay: _editDayFromSummary,
        );
    }
  }
}

enum _Step {
  type,
  mobilitySubType,
  mobilityOption,
  mobilityRoutineSelection,
  hiitExercises,
  hiitConfig,
  days,
  exercises,
  summary,
}
