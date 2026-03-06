import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/ports/custom_exercise_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/workout/focused_exercise_screen.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.session,
    required this.allExercises,
    required this.workoutSessionPort,
    required this.routineName,
    required this.trackTime,
    this.customExercisePort,
    this.enableExerciseTimer = true,
  });

  final WorkoutSession session;
  final List<Exercise> allExercises;
  final WorkoutSessionPort workoutSessionPort;
  final String routineName;
  final CustomExercisePort? customExercisePort;
  final bool trackTime;
  final bool enableExerciseTimer;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late WorkoutSession _session;
  late final String _originalJson;
  late final AppLifecycleListener _lifecycleListener;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  List<WorkoutSession>? _previousSessions;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _originalJson = WorkoutSession.listToJsonString([widget.session]);
    if (widget.trackTime && _session.startTime != null) {
      _elapsed = DateTime.now().difference(_session.startTime!);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = DateTime.now().difference(_session.startTime!);
        });
      });
    }
    _lifecycleListener = AppLifecycleListener(
      onHide: _persistSession,
      onPause: _persistSession,
      onDetach: _persistSession,
    );
    if (widget.trackTime) {
      _persistSession();
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _previousSessions = await widget.workoutSessionPort.loadSessions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      WorkoutSession.listToJsonString([_session]) != _originalJson;

  Future<void> _persistSession() =>
      widget.workoutSessionPort.upsertSession(_session);

  String _nameForKey(String key) =>
      Exercise.nameForKey(widget.allExercises, key);

  void _reorderExercises(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final exercises = List<WorkoutExercise>.from(_session.exercises);
    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);
    setState(() {
      _session = _session.copyWith(exercises: exercises);
    });
    _persistSession();
  }

  Future<void> _openExercise(int index) async {
    final updatedExercise = await Navigator.of(context).push<WorkoutExercise>(
      MaterialPageRoute(
        builder: (_) => FocusedExerciseScreen(
          exerciseName: _nameForKey(_session.exercises[index].exerciseKey),
          exercise: _session.exercises[index],
          enableTimer: widget.enableExerciseTimer,
          isActiveWorkout: widget.trackTime,
          onExerciseUpdated: (updated) {
            // Continuous save during active workouts
            if (!widget.trackTime) return;
            final exercises = List<WorkoutExercise>.from(_session.exercises)
              ..[index] = updated;
            setState(() {
              _session = _session.copyWith(exercises: exercises);
            });
            _persistSession();
          },
        ),
      ),
    );
    if (updatedExercise == null || !mounted) return;
    final updated = List<WorkoutExercise>.from(_session.exercises)
      ..[index] = updatedExercise;
    setState(() {
      _session = _session.copyWith(exercises: updated);
    });
    await _persistSession();
  }

  WorkoutExercise _buildExerciseWithHistory(String exerciseKey) {
    if (_previousSessions == null) return WorkoutExercise.empty(exerciseKey);
    for (final session in _previousSessions!.reversed) {
      if (session.id == _session.id) continue;
      for (final ex in session.exercises) {
        if (ex.exerciseKey == exerciseKey && ex.sets.isNotEmpty) {
          return WorkoutExercise(
            exerciseKey: exerciseKey,
            sets: ex.sets
                .map((s) => ExerciseSet(
                      reps: s.reps,
                      weight: s.weight,
                      targetReps: s.targetReps,
                      plannedRestSeconds: s.plannedRestSeconds,
                      isDropSet: s.isDropSet,
                      dropParentSetNumber: s.dropParentSetNumber,
                      notes: s.notes,
                    ))
                .toList(),
            restSeconds: ex.restSeconds,
          );
        }
      }
    }
    return WorkoutExercise.empty(exerciseKey);
  }

  Future<void> _openAddExercisePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final initialKeys = _session.exercises.map((e) => e.exerciseKey).toList();
    final result = await Navigator.of(context).push<ExerciseSelectionResult>(
      MaterialPageRoute(
        builder: (_) => ExerciseSelectionScreen(
          currentDay: 1,
          totalDays: 1,
          allExercises: widget.allExercises,
          availableCategories: byMuscleCategoryOrder,
          initialSelectedCategories: const [],
          initialSelectedKeys: initialKeys,
          showDayProgress: false,
          titleOverride: l10n.routineSelectExercises,
          customExercisePort: widget.customExercisePort,
          onConfirmed: (selectionResult) =>
              Navigator.of(context).pop(selectionResult),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (result == null) return;

    final selectedKeys = result.selectedExerciseKeys;
    final existingByKey = {
      for (final ex in _session.exercises) ex.exerciseKey: ex,
    };

    final updated = <WorkoutExercise>[];
    for (final key in selectedKeys) {
      if (existingByKey.containsKey(key)) {
        updated.add(existingByKey[key]!);
      } else {
        updated.add(_buildExerciseWithHistory(key));
      }
    }

    setState(() {
      _session = _session.copyWith(exercises: updated);
    });
    await _persistSession();
  }

  Future<void> _confirmDeleteExercise(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameForKey(_session.exercises[index].exerciseKey);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutDeleteExercise),
        content: Text(l10n.workoutDeleteExerciseConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.sharedCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.workoutDeleteExercise),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final updated = List<WorkoutExercise>.from(_session.exercises)
      ..removeAt(index);
    setState(() {
      _session = _session.copyWith(exercises: updated);
    });
    await _persistSession();
  }

  Future<void> _confirmFinish() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutFinish),
        content: Text(l10n.workoutFinishConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.sharedCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.sharedConfirm),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    _session = _session.copyWith(endTime: DateTime.now());
    await _persistSession();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmDiscardSession() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutDiscardSessionConfirmTitle),
        content: Text(l10n.workoutDiscardSessionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.sharedCancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.workoutDiscardSession),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final all = await widget.workoutSessionPort.loadSessions();
    final updated = all.where((session) => session.id != _session.id).toList();
    if (updated.length != all.length) {
      await widget.workoutSessionPort.saveSessions(updated);
    }

    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  Future<void> _saveChanges() async {
    _session = _session.copyWith(
      exercises: _session.exercises
          .map(
            (exercise) => exercise.copyWith(
              completed: exercise.sets.every((set) => set.completed),
            ),
          )
          .toList(),
    );
    await _persistSession();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _briefSummary(WorkoutExercise ex) {
    if (ex.sets.isEmpty) return '';
    return ex.sets.map((set) {
      final weight = set.weight == set.weight.truncateToDouble()
          ? set.weight.toInt().toString()
          : set.weight
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
      return '${set.reps}x$weight';
    }).join(' | ');
  }

  String _plannedSummary(WorkoutExercise ex, AppLocalizations l10n) {
    if (ex.sets.isEmpty) return '';
    final targetReps = ex.sets
        .map((set) => set.targetReps ?? set.reps)
        .where((value) => value > 0)
        .toList();
    final drops = ex.sets.where((set) => set.isDropSet).length;
    final repsLabel = targetReps.isEmpty
        ? '-'
        : targetReps.length == 1
            ? '${targetReps.first}'
            : '${targetReps.reduce((a, b) => a < b ? a : b)}-${targetReps.reduce((a, b) => a > b ? a : b)}';
    final dropLabel = drops > 0 ? ' · Drop: $drops' : '';
    return '${ex.sets.length} ${l10n.workoutSets.toLowerCase()} · $repsLabel ${l10n.workoutReps.toLowerCase()}$dropLabel';
  }

  String? _averageRestLabel(WorkoutExercise ex) {
    final rests = ex.sets
        .where((set) => (set.estimatedRestSeconds ?? 0) > 0)
        .map((set) => set.estimatedRestSeconds!)
        .toList();
    if (rests.isEmpty) return null;
    final avg = (rests.reduce((a, b) => a + b) / rests.length).round();
    return Duration(seconds: avg).toRestLabel();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineName),
        actions: [
          IconButton(
            onPressed: _openAddExercisePicker,
            icon: const Icon(Icons.add),
            tooltip: l10n.routineSelectExercises,
          ),
          if (widget.trackTime) ...[
            IconButton(
              onPressed: _confirmDiscardSession,
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.destructive),
              tooltip: l10n.workoutDiscardSession,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _elapsed.toHumanReadable(),
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              buildDefaultDragHandles: false,
              itemCount: _session.exercises.length,
              onReorder: _reorderExercises,
              itemBuilder: (context, index) {
                final exercise = _session.exercises[index];
                final avgRest = _averageRestLabel(exercise);
                return Card(
                  key: ValueKey('${exercise.exerciseKey}_$index'),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        color: context.textSecondary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Icon(
                          exercise.completed
                              ? Icons.check_circle
                              : Icons.fitness_center,
                          color: exercise.completed
                              ? AppColors.success
                              : context.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_nameForKey(exercise.exerciseKey)),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          exercise.completed
                              ? _briefSummary(exercise)
                              : _plannedSummary(exercise, l10n),
                          style: TextStyle(
                              fontSize: 12, color: context.textSecondary),
                        ),
                        if (avgRest != null)
                          Text(
                            l10n.workoutAvgRest(avgRest),
                            style: TextStyle(
                                fontSize: 11, color: context.textSubtle),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _confirmDeleteExercise(index),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.destructive),
                          visualDensity: VisualDensity.compact,
                          tooltip: l10n.workoutDeleteExercise,
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openExercise(index),
                          icon: Icon(
                            exercise.completed ? Icons.edit : Icons.play_arrow,
                          ),
                          label: Text(
                            exercise.completed
                                ? l10n.routineEditDay
                                : l10n.sharedStart,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _openExercise(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: widget.trackTime
                  ? FilledButton.icon(
                      icon: const Icon(Icons.flag),
                      label: Text(l10n.workoutFinish),
                      onPressed: _confirmFinish,
                    )
                  : FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(l10n.workoutSaveChanges),
                      onPressed: _hasChanges ? _saveChanges : null,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
