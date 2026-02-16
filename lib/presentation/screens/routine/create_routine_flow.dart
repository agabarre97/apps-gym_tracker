import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/muscle_group.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_type_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/days_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/muscle_group_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_summary_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/mobility_subtype_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/mobility_option_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/mobility_routine_selection_screen.dart';

/// Orchestrates the multi-step routine creation wizard.
class CreateRoutineFlow extends StatefulWidget {
  const CreateRoutineFlow({
    super.key,
    required this.routinePort,
    required this.existingRoutines,
    @visibleForTesting this.preloadedExercises,
  });

  final RoutinePort routinePort;
  final List<Routine> existingRoutines;

  /// Exercises injected for testing (skips asset loading).
  @visibleForTesting
  final List<Exercise>? preloadedExercises;

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
  };

  /// Available recommended routines per mobility subtype.
  static const _routinesBySubType = <String, List<String>>{
    'tobillos': ['feet_ankles_2'],
    'cadera': ['pelvic_tilt', 'hips'],
  };

  // Accumulated state
  String? _selectedType;
  String? _selectedMobilitySubType;
  int _numDays = 3;
  int _currentDayIndex = 0;

  // Completed days
  final List<List<MuscleGroupCategory>> _dayMuscleGroups = [];
  final List<List<String>> _dayExerciseKeys = [];

  // Current day in-progress state
  List<MuscleGroupCategory> _currentMuscleSelection = [];
  List<String> _currentExerciseSelection = [];

  // All exercises (loaded once)
  List<Exercise> _allExercises = [];
  bool _exercisesLoaded = false;

  // Logical step
  _Step _step = _Step.type;

  Future<void> _loadExercises() async {
    if (_exercisesLoaded) return;
    if (widget.preloadedExercises != null) {
      _allExercises = widget.preloadedExercises!;
    } else {
      final lang = Localizations.localeOf(context).languageCode;
      _allExercises = await Exercise.loadFromAsset(lang);
    }
    _exercisesLoaded = true;
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
      final routines =
          _routinesBySubType[_selectedMobilitySubType] ?? const [];
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
      type: 'movilidad',
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
      _step = _Step.muscleGroups;
    });
  }

  void _onMuscleGroupsConfirmed(List<MuscleGroupCategory> groups) {
    setState(() {
      _currentMuscleSelection = groups;
      _step = _Step.exercises;
    });
  }

  void _onExercisesConfirmed(List<String> exerciseKeys) {
    setState(() {
      // Save completed day
      _dayMuscleGroups.add(List.of(_currentMuscleSelection));
      _dayExerciseKeys.add(List.of(exerciseKeys));

      // Clear current-day state
      _currentMuscleSelection = [];
      _currentExerciseSelection = [];

      if (_currentDayIndex < _numDays - 1) {
        _currentDayIndex++;
        _step = _Step.muscleGroups;
      } else {
        _step = _Step.summary;
      }
    });
  }

  Future<void> _editDayFromSummary(int dayIndex) async {
    final categories = _dayMuscleGroups[dayIndex];
    final currentKeys = _dayExerciseKeys[dayIndex];

    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => ExerciseSelectionScreen(
          currentDay: dayIndex + 1,
          totalDays: _numDays,
          selectedCategories: categories,
          allExercises: _allExercises,
          initialSelectedKeys: currentKeys,
          onConfirmed: (keys) => Navigator.of(context).pop(keys),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _dayExerciseKeys[dayIndex] = result;
    });
  }

  Future<void> _onSave(String name) async {
    final days = <RoutineDay>[];
    for (var i = 0; i < _dayMuscleGroups.length; i++) {
      days.add(RoutineDay(
        muscleGroups: _dayMuscleGroups[i].map((c) => c.name).toList(),
        exerciseKeys: _dayExerciseKeys[i],
      ));
    }

    final routine = Routine(
      id: _uuid.v4(),
      name: name,
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

        case _Step.days:
          _step = _Step.type;

        case _Step.muscleGroups:
          if (_currentDayIndex > 0) {
            // Go back to previous day's exercise selection.
            // Restore the completed day data as current-day state.
            _currentDayIndex--;
            _currentMuscleSelection = _dayMuscleGroups.removeLast();
            _currentExerciseSelection = _dayExerciseKeys.removeLast();
            _step = _Step.exercises;
          } else {
            // First day — go back to days slider
            _step = _Step.days;
          }

        case _Step.exercises:
          // Go back to muscle group selection for the same day.
          // _currentMuscleSelection is already set.
          _step = _Step.muscleGroups;

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
      case _Step.muscleGroups:
        _loadExercises();
        return MuscleGroupSelectionScreen(
          key: ValueKey('muscleGroups_$_currentDayIndex'),
          currentDay: _currentDayIndex + 1,
          totalDays: _numDays,
          initialSelection: _currentMuscleSelection,
          onConfirmed: _onMuscleGroupsConfirmed,
          onBack: _goBack,
        );
      case _Step.exercises:
        return ExerciseSelectionScreen(
          key: ValueKey('exercises_$_currentDayIndex'),
          currentDay: _currentDayIndex + 1,
          totalDays: _numDays,
          selectedCategories: _currentMuscleSelection,
          allExercises: _allExercises,
          initialSelectedKeys: _currentExerciseSelection,
          onConfirmed: _onExercisesConfirmed,
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

enum _Step { type, mobilitySubType, mobilityOption, mobilityRoutineSelection, days, muscleGroups, exercises, summary }
