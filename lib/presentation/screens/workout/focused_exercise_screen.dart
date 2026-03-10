import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';

class FocusedExerciseScreen extends StatefulWidget {
  const FocusedExerciseScreen({
    super.key,
    required this.exerciseName,
    required this.exercise,
    this.enableTimer = true,
    this.isActiveWorkout = true,
    this.onExerciseUpdated,
  });

  final String exerciseName;
  final WorkoutExercise exercise;

  /// Whether to start the per-exercise stopwatch. Set to `false` in widget
  /// tests that rely on [pumpAndSettle] (periodic timers prevent settling).
  final bool enableTimer;

  /// When `false` (viewing a completed workout), hides the exercise stopwatch,
  /// the rest configuration card, and disables rest countdown timers.
  final bool isActiveWorkout;

  /// Optional callback invoked immediately whenever the exercise is modified
  /// (e.g. set completed, reps changed). Useful for continuous background saving.
  final ValueChanged<WorkoutExercise>? onExerciseUpdated;

  @override
  State<FocusedExerciseScreen> createState() => _FocusedExerciseScreenState();
}

class _FocusedExerciseScreenState extends State<FocusedExerciseScreen> {
  late WorkoutExercise _exercise;
  Map<int, DateTime> _setCompletionTimes = {};
  final Set<int> _previouslyCompletedSets = {};

  Timer? _restTicker;
  int _restRemainingSeconds = 0;
  int? _activeRestSetIndex;
  bool _saving = false;

  Timer? _exerciseTicker;
  int _exerciseElapsedSeconds = 0;

  bool get _restActive => _restRemainingSeconds > 0;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    for (var i = 0; i < _exercise.sets.length; i++) {
      if (_exercise.sets[i].completed) _previouslyCompletedSets.add(i);
    }
    _exerciseElapsedSeconds = widget.exercise.elapsedSeconds ?? 0;
    if (widget.enableTimer && widget.isActiveWorkout) _startExerciseTimer();
  }

  @override
  void dispose() {
    _restTicker?.cancel();
    _exerciseTicker?.cancel();
    super.dispose();
  }

  void _startExerciseTimer() {
    _exerciseTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _exerciseElapsedSeconds += 1;
      });
    });
  }

  void _updateSetAt(
    int setIndex, {
    int? reps,
    double? weight,
    int? targetReps,
  }) {
    final updatedSets = List<ExerciseSet>.from(_exercise.sets);
    final wasCompleted = updatedSets[setIndex].completed;
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(
      reps: reps,
      weight: weight,
      targetReps: targetReps,
      completed: wasCompleted ? false : null,
    );
    setState(() {
      _exercise = _exercise.copyWith(
        sets: updatedSets,
        completed: updatedSets.every((set) => set.completed),
      );
    });
    widget.onExerciseUpdated?.call(_exercise);
  }

  void _updateSetNotes(int setIndex, String notes) {
    final updatedSets = List<ExerciseSet>.from(_exercise.sets);
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(notes: notes);
    setState(() {
      _exercise = _exercise.copyWith(sets: updatedSets);
    });
    widget.onExerciseUpdated?.call(_exercise);
  }

  void _saveEditedSet(int setIndex) {
    final updatedSets = List<ExerciseSet>.from(_exercise.sets);
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(completed: true);
    _previouslyCompletedSets.add(setIndex);

    if (!updatedSets[setIndex].isDropSet) {
      final parentSeries = _mainSeriesNumberForIndex(setIndex);
      for (var i = setIndex + 1; i < updatedSets.length; i++) {
        if (updatedSets[i].isDropSet &&
            updatedSets[i].dropParentSetNumber == parentSeries) {
          updatedSets[i] = updatedSets[i].copyWith(completed: true);
          _previouslyCompletedSets.add(i);
        } else if (!updatedSets[i].isDropSet) {
          break;
        }
      }
    }

    setState(() {
      _exercise = _exercise.copyWith(
        sets: updatedSets,
        completed: updatedSets.every((set) => set.completed),
      );
    });
    widget.onExerciseUpdated?.call(_exercise);
  }

  void _setExerciseRest(int? seconds) {
    setState(() {
      _exercise = _exercise.copyWith(
        restSeconds: seconds,
        clearRestSeconds: seconds == null,
      );
    });
    widget.onExerciseUpdated?.call(_exercise);
  }

  Future<void> _configureExerciseRest() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (_) => _RestPickerSheet(initialSeconds: _exercise.restSeconds),
    );
    if (!mounted || selected == null) return;
    if (selected < 0) {
      _setExerciseRest(null);
      return;
    }
    _setExerciseRest(selected);
  }

  int _mainSeriesNumberForIndex(int index) {
    var mainCount = 0;
    for (var i = 0; i <= index && i < _exercise.sets.length; i++) {
      if (!_exercise.sets[i].isDropSet) mainCount += 1;
    }
    return math.max(1, mainCount);
  }

  void _remapCompletionTimesForInsertion(int insertedIndex) {
    final remapped = <int, DateTime>{};
    for (final entry in _setCompletionTimes.entries) {
      final nextKey = entry.key >= insertedIndex ? entry.key + 1 : entry.key;
      remapped[nextKey] = entry.value;
    }
    _setCompletionTimes = remapped;
  }

  void _remapCompletionTimesForDeletion(Set<int> deleted) {
    if (deleted.isEmpty) return;
    final remapped = <int, DateTime>{};
    for (final entry in _setCompletionTimes.entries) {
      if (deleted.contains(entry.key)) continue;
      final shift = deleted.where((idx) => idx < entry.key).length;
      remapped[entry.key - shift] = entry.value;
    }
    _setCompletionTimes = remapped;
  }

  void _startRestTimer({
    required int seconds,
    required int setIndex,
  }) {
    if (seconds <= 0) return;
    _restTicker?.cancel();
    setState(() {
      _restRemainingSeconds = seconds;
      _activeRestSetIndex = setIndex;
    });
    _restTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _restRemainingSeconds - 1;
      if (next <= 0) {
        _restTicker?.cancel();
        setState(() {
          _restRemainingSeconds = 0;
          _activeRestSetIndex = null;
        });
        return;
      }
      setState(() {
        _restRemainingSeconds = next;
      });
    });
  }

  void _skipRestTimer() {
    _restTicker?.cancel();
    setState(() {
      _restRemainingSeconds = 0;
      _activeRestSetIndex = null;
    });
  }

  Future<void> _completeSet(int setIndex) async {
    final set = _exercise.sets[setIndex];
    if (set.completed) return;
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    int? estimatedRestSeconds;
    if (setIndex > 0) {
      final prevCompletion = _setCompletionTimes[setIndex - 1];
      if (prevCompletion != null) {
        final diff = now.difference(prevCompletion).inSeconds;
        if (diff > 0) estimatedRestSeconds = diff;
      }
    }

    final updatedSets = List<ExerciseSet>.from(_exercise.sets);
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(
      completed: true,
      estimatedRestSeconds: estimatedRestSeconds,
      clearRest: setIndex == 0,
    );
    _setCompletionTimes[setIndex] = now;

    _previouslyCompletedSets.add(setIndex);

    if (!set.isDropSet) {
      final parentSeries = _mainSeriesNumberForIndex(setIndex);
      for (var i = setIndex + 1; i < updatedSets.length; i++) {
        if (updatedSets[i].isDropSet &&
            updatedSets[i].dropParentSetNumber == parentSeries) {
          updatedSets[i] = updatedSets[i].copyWith(
            completed: true,
            estimatedRestSeconds: null,
            clearRest: true,
          );
          _setCompletionTimes[i] = now;
          _previouslyCompletedSets.add(i);
        } else if (!updatedSets[i].isDropSet) {
          break;
        }
      }
    }

    setState(() {
      _exercise = _exercise.copyWith(
        sets: updatedSets,
        completed: updatedSets.every((item) => item.completed),
      );
    });
    widget.onExerciseUpdated?.call(_exercise);

    final restSeconds = _exercise.restSeconds ?? set.plannedRestSeconds;
    if (widget.isActiveWorkout && restSeconds != null && restSeconds > 0) {
      _startRestTimer(seconds: restSeconds, setIndex: setIndex);
    }
  }

  void _addRegularSet({int? insertAfter}) {
    final updatedSets = List<ExerciseSet>.from(_exercise.sets);
    final template = updatedSets.isNotEmpty
        ? updatedSets.last
        : const ExerciseSet(reps: 0, weight: 0);
    final newSet = ExerciseSet(
      reps: 0,
      weight: 0,
      targetReps: template.targetReps ?? 10,
      plannedRestSeconds: _exercise.restSeconds,
    );
    if (insertAfter == null || insertAfter >= updatedSets.length - 1) {
      updatedSets.add(newSet);
    } else {
      _remapCompletionTimesForInsertion(insertAfter + 1);
      updatedSets.insert(insertAfter + 1, newSet);
    }
    setState(() {
      _exercise = _exercise.copyWith(sets: updatedSets, completed: false);
    });
    widget.onExerciseUpdated?.call(_exercise);
  }

  void _insertDropSetAfter(int setIndex) {
    final source = _exercise.sets[setIndex];
    final updatedSets = List<ExerciseSet>.from(_exercise.sets);
    final parentSeries = source.isDropSet
        ? source.dropParentSetNumber ?? _mainSeriesNumberForIndex(setIndex)
        : _mainSeriesNumberForIndex(setIndex);
    final dropSet = ExerciseSet(
      reps: 0,
      weight: source.weight,
      targetReps: source.targetReps ?? source.reps,
      isDropSet: true,
      dropParentSetNumber: parentSeries,
    );
    var insertAt = setIndex + 1;
    while (insertAt < updatedSets.length &&
        updatedSets[insertAt].isDropSet &&
        updatedSets[insertAt].dropParentSetNumber == parentSeries) {
      insertAt++;
    }
    _remapCompletionTimesForInsertion(insertAt);
    updatedSets.insert(insertAt, dropSet);
    setState(() {
      _exercise = _exercise.copyWith(sets: updatedSets, completed: false);
    });
    widget.onExerciseUpdated?.call(_exercise);
  }

  void _toggleDropSet(int setIndex) {
    final current = _exercise.sets[setIndex];
    final updatedSets = List<ExerciseSet>.from(_exercise.sets);
    if (current.isDropSet) {
      updatedSets[setIndex] = current.copyWith(
        isDropSet: false,
        clearDropParentSetNumber: true,
      );
    } else {
      final parentSeries = math.max(1, _mainSeriesNumberForIndex(setIndex) - 1);
      updatedSets[setIndex] = current.copyWith(
        isDropSet: true,
        dropParentSetNumber: parentSeries,
      );
    }
    setState(() {
      _exercise = _exercise.copyWith(sets: updatedSets, completed: false);
    });
    widget.onExerciseUpdated?.call(_exercise);
  }

  void _deleteSeries(int setIndex) {
    final targetSet = _exercise.sets[setIndex];
    final updatedSets = List<ExerciseSet>.from(_exercise.sets);
    if (targetSet.isDropSet) {
      updatedSets.removeAt(setIndex);
      _remapCompletionTimesForDeletion({setIndex});
    } else {
      final parentSeries = _mainSeriesNumberForIndex(setIndex);
      final toDelete = <int>{setIndex};
      for (var i = 0; i < updatedSets.length; i++) {
        if (updatedSets[i].isDropSet &&
            updatedSets[i].dropParentSetNumber == parentSeries) {
          toDelete.add(i);
        }
      }
      final sorted = toDelete.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sorted) {
        updatedSets.removeAt(index);
      }
      _remapCompletionTimesForDeletion(toDelete);
    }
    if (updatedSets.isEmpty) {
      updatedSets.add(
        const ExerciseSet(
          reps: 0,
          weight: 0,
          targetReps: 10,
        ),
      );
    }
    setState(() {
      _exercise = _exercise.copyWith(sets: updatedSets, completed: false);
    });
    widget.onExerciseUpdated?.call(_exercise);
  }

  Future<void> _showAddSetSheet({int? sourceIndex}) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.workoutAddSet),
                onTap: () => Navigator.of(ctx).pop('regular'),
              ),
              ListTile(
                leading: const Icon(Icons.trending_down),
                title: const Text('Añadir drop set'),
                onTap: () => Navigator.of(ctx).pop('drop'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;

    final baseIndex = sourceIndex ??
        (_exercise.sets.isEmpty ? null : _exercise.sets.length - 1);
    if (action == 'regular') {
      _addRegularSet(insertAfter: baseIndex);
      return;
    }
    if (baseIndex == null) {
      _addRegularSet();
      return;
    }
    _insertDropSetAfter(baseIndex);
  }

  List<({int mainIndex, int seriesNumber, List<int> dropIndexes})> _groups() {
    final groups =
        <({int mainIndex, int seriesNumber, List<int> dropIndexes})>[];
    final bySeries = <int, int>{};
    var mainCount = 0;

    for (var index = 0; index < _exercise.sets.length; index++) {
      final set = _exercise.sets[index];
      if (!set.isDropSet) {
        mainCount += 1;
        groups.add(
            (mainIndex: index, seriesNumber: mainCount, dropIndexes: <int>[]));
        bySeries[mainCount] = groups.length - 1;
        continue;
      }
      final parent = set.dropParentSetNumber;
      if (parent != null && bySeries.containsKey(parent)) {
        groups[bySeries[parent]!].dropIndexes.add(index);
      } else if (groups.isNotEmpty) {
        groups.last.dropIndexes.add(index);
      }
    }
    return groups;
  }

  Future<void> _showSeriesMenu({
    required int setIndex,
    required bool canInsertDrop,
  }) async {
    final set = _exercise.sets[setIndex];
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(
                set.isDropSet
                    ? 'Convertir a serie normal'
                    : 'Convertir a drop set',
              ),
              onTap: () => Navigator.of(ctx).pop('toggle_drop'),
            ),
            if (canInsertDrop)
              ListTile(
                leading: const Icon(Icons.call_split),
                title: const Text('Insertar drop set debajo'),
                onTap: () => Navigator.of(ctx).pop('insert_drop'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.destructive),
              title: const Text('Eliminar serie'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    if (selected == 'toggle_drop') {
      _toggleDropSet(setIndex);
      return;
    }
    if (selected == 'insert_drop') {
      _insertDropSetAfter(setIndex);
      return;
    }
    if (selected == 'delete') {
      _deleteSeries(setIndex);
    }
  }

  Future<void> _saveAndReturn() async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    _exerciseTicker?.cancel();
    Navigator.of(context).pop(
      _exercise.copyWith(
        completed: _exercise.sets.every((set) => set.completed),
        elapsedSeconds: _exerciseElapsedSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = _groups();
    final restLabel = _exercise.restSeconds == null
        ? l10n.mobilityRestOff
        : TimeFormatter.mmss(_exercise.restSeconds!);
    final exerciseTimerLabel =
        Duration(seconds: _exerciseElapsedSeconds).toHumanReadable();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            if (widget.isActiveWorkout)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 18, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        exerciseTimerLabel,
                        style: TextStyle(
                            fontSize: 14, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.exerciseName,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.isActiveWorkout)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.hourglass_bottom),
                  title: Text(l10n.workoutRestTimer),
                  subtitle: Text(restLabel),
                  trailing: OutlinedButton(
                    onPressed: _configureExerciseRest,
                    child: Text(l10n.routineEditDay),
                  ),
                ),
              ),
            ...groups.map((group) {
              final mainSet = _exercise.sets[group.mainIndex];
              return Column(
                children: [
                  _SeriesCard(
                    title: l10n.workoutSet('${group.seriesNumber}'),
                    finishLabel: l10n.workoutFinishSet('${group.seriesNumber}'),
                    saveLabel: l10n.workoutSaveSet,
                    set: mainSet,
                    isCompleted: mainSet.completed,
                    wasEverCompleted:
                        _previouslyCompletedSets.contains(group.mainIndex),
                    isActiveRest:
                        _restActive && _activeRestSetIndex == group.mainIndex,
                    activeRestSeconds: _restRemainingSeconds,
                    restLabel: restLabel,
                    onSkipRest: _skipRestTimer,
                    onRepsChanged: (value) =>
                        _updateSetAt(group.mainIndex, reps: value),
                    onWeightChanged: (value) =>
                        _updateSetAt(group.mainIndex, weight: value),
                    onNotesChanged: (value) =>
                        _updateSetNotes(group.mainIndex, value),
                    onComplete: () => _completeSet(group.mainIndex),
                    onSaveEdited: () => _saveEditedSet(group.mainIndex),
                    onMenuPressed: () => _showSeriesMenu(
                      setIndex: group.mainIndex,
                      canInsertDrop: true,
                    ),
                  ),
                  ...group.dropIndexes.map((dropIndex) {
                    final dropSet = _exercise.sets[dropIndex];
                    return _SeriesCard(
                      title: 'Drop set',
                      finishLabel: l10n.workoutFinishSet('Drop'),
                      saveLabel: l10n.workoutSaveSet,
                      set: dropSet,
                      compact: true,
                      isCompleted: dropSet.completed,
                      wasEverCompleted:
                          _previouslyCompletedSets.contains(dropIndex),
                      isActiveRest:
                          _restActive && _activeRestSetIndex == dropIndex,
                      activeRestSeconds: _restRemainingSeconds,
                      restLabel: restLabel,
                      onSkipRest: _skipRestTimer,
                      onRepsChanged: (value) =>
                          _updateSetAt(dropIndex, reps: value),
                      onWeightChanged: (value) =>
                          _updateSetAt(dropIndex, weight: value),
                      onNotesChanged: (value) =>
                          _updateSetNotes(dropIndex, value),
                      onComplete: () => _completeSet(dropIndex),
                      onSaveEdited: () => _saveEditedSet(dropIndex),
                      onMenuPressed: () => _showSeriesMenu(
                        setIndex: dropIndex,
                        canInsertDrop: false,
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              );
            }),
            OutlinedButton.icon(
              onPressed: () => _showAddSetSheet(),
              icon: const Icon(Icons.add),
              label: Text(l10n.workoutAddSet),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _saveAndReturn,
                child: Text(l10n.workoutFinishExercise),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.title,
    required this.finishLabel,
    required this.saveLabel,
    required this.set,
    required this.isCompleted,
    this.wasEverCompleted = false,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onNotesChanged,
    required this.onComplete,
    required this.onSaveEdited,
    required this.onMenuPressed,
    required this.restLabel,
    required this.isActiveRest,
    required this.activeRestSeconds,
    required this.onSkipRest,
    this.compact = false,
  });

  final String title;
  final String finishLabel;
  final String saveLabel;
  final ExerciseSet set;
  final bool isCompleted;
  final bool wasEverCompleted;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onComplete;
  final VoidCallback onSaveEdited;
  final VoidCallback onMenuPressed;
  final String restLabel;
  final bool isActiveRest;
  final int activeRestSeconds;
  final VoidCallback onSkipRest;
  final bool compact;

  /// The set was completed before but then edited → show "Save" instead.
  bool get _needsResave => !set.completed && wasEverCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.only(bottom: 8, left: compact ? 20 : 0),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withValues(alpha: 0.08)
            : context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? AppColors.success : context.border,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 16,
                    color:
                        isCompleted ? AppColors.success : context.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.more_vert),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (!compact && set.targetReps != null) ...[
              Text(
                '${l10n.routineTargetReps}: ${set.targetReps ?? 0}${isActiveRest ? '' : ' · ${l10n.workoutRestTimer}: $restLabel'}',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 8),
            ],
            if (isActiveRest) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.restTimer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.restTimer.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer,
                        color: AppColors.restTimer, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        TimeFormatter.mmss(activeRestSeconds),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.restTimer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onSkipRest,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.restTimer,
                      ),
                      child: Text(l10n.sharedSkip),
                    ),
                  ],
                ),
              ),
            ],
            _SetInputEditor(
              reps: set.reps,
              weight: set.weight,
              onRepsChanged: onRepsChanged,
              onWeightChanged: onWeightChanged,
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              _NotesField(
                initialValue: set.notes,
                onChanged: onNotesChanged,
              ),
              const SizedBox(height: 8),
              if (!isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _needsResave ? onSaveEdited : onComplete,
                    icon: const Icon(Icons.task_alt_outlined),
                    label: Text(
                      _needsResave ? saveLabel : finishLabel,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetInputEditor extends StatelessWidget {
  const _SetInputEditor({
    required this.reps,
    required this.weight,
    required this.onRepsChanged,
    required this.onWeightChanged,
  });

  final int reps;
  final double weight;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepperIntField(
          value: reps,
          step: 1,
          onChanged: onRepsChanged,
        ),
        const SizedBox(height: 12),
        _StepperDoubleField(
          value: weight,
          step: 1.25,
          onChanged: onWeightChanged,
        ),
      ],
    );
  }
}

class _NotesField extends StatefulWidget {
  const _NotesField({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: l10n.workoutSetNotes,
        border: const OutlineInputBorder(),
        isDense: true,
        prefixIcon: const Icon(Icons.notes, size: 20),
      ),
      maxLines: 2,
      minLines: 1,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}

class _RestPickerSheet extends StatefulWidget {
  const _RestPickerSheet({this.initialSeconds});

  final int? initialSeconds;

  @override
  State<_RestPickerSheet> createState() => _RestPickerSheetState();
}

class _RestPickerSheetState extends State<_RestPickerSheet> {
  static const _presets = [30, 60, 90, 120, 180];
  late TextEditingController _manualController;
  int? _selectedSeconds;

  @override
  void initState() {
    super.initState();
    _selectedSeconds = widget.initialSeconds;
    _manualController = TextEditingController(
      text: widget.initialSeconds?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSave = (_selectedSeconds ?? 0) > 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workoutRestTimer,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets
                  .map(
                    (seconds) => ChoiceChip(
                      key: ValueKey('focused_rest_preset_$seconds'),
                      label: Text(TimeFormatter.mmss(seconds)),
                      selected: _selectedSeconds == seconds,
                      onSelected: (_) => setState(() {
                        _selectedSeconds = seconds;
                        _manualController.text = seconds.toString();
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('focused_rest_manual_seconds'),
              controller: _manualController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: '${l10n.workoutRestTimer} (s)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                setState(() {
                  _selectedSeconds = parsed;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.sharedCancel),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(-1),
                  child: Text(l10n.mobilityRestOff),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: canSave
                      ? () => Navigator.of(context).pop(_selectedSeconds)
                      : null,
                  child: Text(l10n.sharedSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperIntField extends StatefulWidget {
  const _StepperIntField({
    required this.value,
    required this.step,
    required this.onChanged,
  });

  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  State<_StepperIntField> createState() => _StepperIntFieldState();
}

class _StepperIntFieldState extends State<_StepperIntField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.value == 0 ? '' : '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _StepperIntField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value == 0 ? '' : '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: AppLocalizations.of(context)!.workoutReps,
      onDecrement: () =>
          widget.onChanged(math.max(0, widget.value - widget.step)),
      onIncrement: () => widget.onChanged(widget.value + widget.step),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) => widget.onChanged(int.tryParse(value) ?? 0),
      ),
    );
  }
}

class _StepperDoubleField extends StatefulWidget {
  const _StepperDoubleField({
    required this.value,
    required this.step,
    required this.onChanged,
  });

  final double value;
  final double step;
  final ValueChanged<double> onChanged;

  @override
  State<_StepperDoubleField> createState() => _StepperDoubleFieldState();
}

class _StepperDoubleFieldState extends State<_StepperDoubleField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _display(widget.value));
  }

  @override
  void didUpdateWidget(covariant _StepperDoubleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _display(widget.value);
    }
  }

  String _display(double v) {
    if (v == 0) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: AppLocalizations.of(context)!.workoutWeight,
      onDecrement: () =>
          widget.onChanged(math.max(0, widget.value - widget.step)),
      onIncrement: () => widget.onChanged(widget.value + widget.step),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        inputFormatters: [_DecimalInputFormatter()],
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) => widget.onChanged(double.tryParse(value) ?? 0),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.label,
    required this.child,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final Widget child;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: child,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ],
        ),
      ],
    );
  }
}

class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) {
      return oldValue;
    }
    return newValue;
  }
}
