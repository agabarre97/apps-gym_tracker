import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Main workout screen showing exercise cards with sets/reps/weight editing.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.session,
    required this.allExercises,
    required this.workoutSessionPort,
    required this.routineName,
    required this.trackTime,
  });

  final WorkoutSession session;
  final List<Exercise> allExercises;
  final WorkoutSessionPort workoutSessionPort;
  final String routineName;

  /// If true, an elapsed-time timer is displayed and start/end times recorded.
  final bool trackTime;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late WorkoutSession _session;

  /// Snapshot of the original session JSON to detect changes (view mode).
  late final String _originalJson;

  Timer? _timer;
  Duration _elapsed = Duration.zero;

  /// Index of the currently expanded exercise (-1 = none).
  int _expandedIndex = -1;

  /// Completion timestamp per (exerciseIndex, setIndex).
  ///
  /// Used to compute rest time as the interval between the end of
  /// consecutive sets.
  final Map<(int, int), DateTime> _setCompletionTimes = {};

  /// One TextEditingController per exercise key for the notes field.
  ///
  /// Created lazily and disposed in [dispose] to avoid leaking controllers
  /// that were previously created inside [build].
  final Map<String, TextEditingController> _notesControllers = {};

  /// Persists the session whenever the app is sent to background or
  /// detached (e.g. home button, incoming call) so data is not lost.
  late final AppLifecycleListener _lifecycleListener;

  TextEditingController _notesControllerFor(WorkoutExercise ex) =>
      _notesControllers.putIfAbsent(
        ex.exerciseKey,
        () => TextEditingController(text: ex.notes ?? ''),
      );

  /// Whether the session has been modified from its original state (view mode).
  bool get _hasChanges {
    return WorkoutSession.listToJsonString([_session]) != _originalJson;
  }

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycleListener.dispose();
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _nameForKey(String key) =>
      Exercise.nameForKey(widget.allExercises, key);

  // ── Persistence ────────────────────────────────────────────────

  Future<void> _persistSession() =>
      widget.workoutSessionPort.upsertSession(_session);

  // ── Exercise actions ───────────────────────────────────────────

  void _completeSet(int exIndex, int setIndex) {
    HapticFeedback.mediumImpact();
    final completedAt = DateTime.now();
    final ex = _session.exercises[exIndex];
    final updatedSets = List<ExerciseSet>.from(ex.sets);
    int? restSeconds;
    if (setIndex > 0) {
      final previousCompletion = _setCompletionTimes[(exIndex, setIndex - 1)];
      if (previousCompletion != null) {
        final diff = completedAt.difference(previousCompletion).inSeconds;
        if (diff > 0) restSeconds = diff;
      }
    }
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(
      completed: true,
      estimatedRestSeconds: restSeconds,
      clearRest: setIndex == 0,
    );
    _setCompletionTimes[(exIndex, setIndex)] = completedAt;
    _updateExerciseSets(exIndex, updatedSets);
    _persistSession();
  }

  int? _nextPendingSetIndex(WorkoutExercise exercise) {
    for (var index = 0; index < exercise.sets.length; index++) {
      if (!exercise.sets[index].completed) {
        return index;
      }
    }
    return null;
  }

  void _completeNextPendingSet(int exIndex) {
    final ex = _session.exercises[exIndex];
    final setIndex = _nextPendingSetIndex(ex);
    if (setIndex == null) return;
    _completeSet(exIndex, setIndex);
  }

  int _mapIndexAfterReorder(int index, int oldIndex, int newIndex) {
    if (index == oldIndex) return newIndex;
    if (oldIndex < newIndex && index > oldIndex && index <= newIndex) {
      return index - 1;
    }
    if (oldIndex > newIndex && index >= newIndex && index < oldIndex) {
      return index + 1;
    }
    return index;
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    setState(() {
      final updatedExercises = List<WorkoutExercise>.from(_session.exercises);
      final movedExercise = updatedExercises.removeAt(oldIndex);
      updatedExercises.insert(newIndex, movedExercise);

      if (_expandedIndex >= 0) {
        _expandedIndex = _mapIndexAfterReorder(
          _expandedIndex,
          oldIndex,
          newIndex,
        );
      }

      final updatedCompletionTimes = <(int, int), DateTime>{};
      for (final entry in _setCompletionTimes.entries) {
        final (exerciseIndex, setIndex) = entry.key;
        final mappedExerciseIndex = _mapIndexAfterReorder(
          exerciseIndex,
          oldIndex,
          newIndex,
        );
        updatedCompletionTimes[(mappedExerciseIndex, setIndex)] = entry.value;
      }
      _setCompletionTimes
        ..clear()
        ..addAll(updatedCompletionTimes);

      _session = _session.copyWith(exercises: updatedExercises);
    });

    unawaited(_persistSession());
  }

  void _finishExercise(int index) {
    setState(() {
      final ex = _session.exercises[index];
      final completedSets = ex.sets
          .map((set) => set.completed ? set : set.copyWith(completed: true))
          .toList();
      final updated = ex.copyWith(
        completed: true,
        sets: completedSets,
      );
      final list = List<WorkoutExercise>.from(_session.exercises);
      list[index] = updated;
      _session = _session.copyWith(exercises: list);
      _expandedIndex = -1;
    });
    _persistSession();
  }

  void _saveExercise(int index) {
    setState(() {
      final exercise = _session.exercises[index];
      final updated = exercise.copyWith(completed: true);
      final updatedExercises = List<WorkoutExercise>.from(_session.exercises);
      updatedExercises[index] = updated;
      _session = _session.copyWith(exercises: updatedExercises);
      _expandedIndex = -1;
    });
    _persistSession();
  }

  void _updateExerciseSets(int exIndex, List<ExerciseSet> newSets) {
    setState(() {
      final ex = _session.exercises[exIndex];
      final updated = ex.copyWith(sets: newSets);
      final list = List<WorkoutExercise>.from(_session.exercises);
      list[exIndex] = updated;
      _session = _session.copyWith(exercises: list);
    });
  }

  void _updateExerciseNotes(int exIndex, String notes) {
    final ex = _session.exercises[exIndex];
    final updated = ex.copyWith(notes: notes);
    final list = List<WorkoutExercise>.from(_session.exercises);
    list[exIndex] = updated;
    setState(() {
      _session = _session.copyWith(exercises: list);
    });
  }

  void _addSet(int exIndex) {
    final ex = _session.exercises[exIndex];
    final newSets = List<ExerciseSet>.from(ex.sets)
      ..add(const ExerciseSet(reps: 0, weight: 0));
    _updateExerciseSets(exIndex, newSets);
  }

  void _removeSet(int exIndex) {
    final ex = _session.exercises[exIndex];
    if (ex.sets.length <= 1) return;
    final lastIdx = ex.sets.length - 1;
    _setCompletionTimes.remove((exIndex, lastIdx));
    final newSets = List<ExerciseSet>.from(ex.sets)..removeLast();
    _updateExerciseSets(exIndex, newSets);
  }

  void _updateSet(int exIndex, int setIndex, {int? reps, double? weight}) {
    final ex = _session.exercises[exIndex];
    final newSets = List<ExerciseSet>.from(ex.sets);
    newSets[setIndex] = newSets[setIndex].copyWith(
      reps: reps,
      weight: weight,
    );
    _updateExerciseSets(exIndex, newSets);
  }

  Future<void> _openAddExercisePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final initialKeys = _session.exercises.map((e) => e.exerciseKey).toList();
    final availableCategories = byMuscleCategoryOrder;

    final result = await Navigator.of(context).push<ExerciseSelectionResult>(
      MaterialPageRoute(
        builder: (_) => ExerciseSelectionScreen(
          currentDay: 1,
          totalDays: 1,
          allExercises: widget.allExercises,
          availableCategories: availableCategories,
          initialSelectedCategories: const [],
          initialSelectedKeys: initialKeys,
          showDayProgress: false,
          titleOverride: l10n.routineSelectExercises,
          onConfirmed: (selectionResult) =>
              Navigator.of(context).pop(selectionResult),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );

    if (result == null) return;

    final existingByKey = {
      for (final exercise in _session.exercises) exercise.exerciseKey: exercise,
    };
    final updatedExercises = List<WorkoutExercise>.from(_session.exercises);

    for (final key in result.selectedExerciseKeys) {
      if (!existingByKey.containsKey(key)) {
        updatedExercises.add(WorkoutExercise.empty(key));
      }
    }

    if (updatedExercises.length == _session.exercises.length) return;

    setState(() {
      _session = _session.copyWith(exercises: updatedExercises);
    });
    await _persistSession();
  }

  // ── Finish / Save ───────────────────────────────────────────────

  /// Live workout mode: confirm before finishing.
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

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _discardSessionIfExists() async {
    final all = await widget.workoutSessionPort.loadSessions();
    final updated = all.where((session) => session.id != _session.id).toList();
    if (updated.length == all.length) return;
    await widget.workoutSessionPort.saveSessions(updated);
  }

  /// Live workout mode: prompt save/discard when leaving with back button.
  Future<void> _confirmExitTraining() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutFinish),
        content: Text(l10n.workoutSavePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.workoutSaveNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.workoutSaveYes),
          ),
        ],
      ),
    );
    if (shouldSave == null || !mounted) return;

    if (shouldSave) {
      _session = _session.copyWith(endTime: DateTime.now());
      await _persistSession();
    } else {
      await _discardSessionIfExists();
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  /// View/edit mode (calendar): just save and go back.
  Future<void> _saveChanges() async {
    _session = _session.copyWith(
      exercises: _session.exercises
          .map((exercise) => exercise.copyWith(completed: true))
          .toList(),
    );
    await _persistSession();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  // ── Rest stopwatch ─────────────────────────────────────────────

  void _showRestStopwatch() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (_) => const _RestStopwatchSheet(),
    );
  }

  // ── Elapsed time format ────────────────────────────────────────

  /// Brief summary for a completed exercise, e.g. "3x12 @ 60kg".
  String _briefSummary(WorkoutExercise ex) {
    if (ex.sets.isEmpty) return '';
    final parts = <String>[];
    for (final s in ex.sets) {
      final w = s.weight == s.weight.truncateToDouble()
          ? s.weight.toInt().toString()
          : s.weight
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
      parts.add('${s.reps}x${w}kg');
    }
    return parts.join(' | ');
  }

  /// Compute average rest seconds for an exercise (ignoring first set and nulls).
  String? _averageRestLabel(WorkoutExercise ex) {
    final rests = ex.sets
        .where((s) =>
            s.estimatedRestSeconds != null && s.estimatedRestSeconds! > 0)
        .map((s) => s.estimatedRestSeconds!)
        .toList();
    if (rests.isEmpty) return null;
    final avg = (rests.reduce((a, b) => a + b) / rests.length).round();
    return Duration(seconds: avg).toRestLabel();
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !widget.trackTime,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.trackTime) {
          _confirmExitTraining();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.routineName),
          actions: [
            IconButton(
              onPressed: _openAddExercisePicker,
              icon: const Icon(Icons.add),
              tooltip: l10n.workoutAddSet,
            ),
            if (widget.trackTime)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showRestStopwatch,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        minHeight: AppSizes.buttonHeightSmall),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 18, color: context.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _elapsed.toHumanReadable(),
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _session.exercises.length,
                onReorder: _reorderExercises,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) =>
                    _buildExerciseCard(index, l10n),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                          onPressed: _saveChanges,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(int index, AppLocalizations l10n) {
    final ex = _session.exercises[index];
    final isExpanded = _expandedIndex == index;
    final name = _nameForKey(ex.exerciseKey);
    final avgRest = _averageRestLabel(ex);
    final isViewMode = !widget.trackTime;
    final nextPendingSet = _nextPendingSetIndex(ex);
    final isSeriesProgressMode = !isViewMode && nextPendingSet != null;

    return ReorderableDragStartListener(
      key: ValueKey('workout-exercise-card-${ex.exerciseKey}'),
      index: index,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            _expandedIndex = isExpanded ? -1 : index;
          }),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: AppSizes.buttonHeightSmall),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: name + check ──
                  Row(
                    children: [
                      if (ex.completed)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.check_circle,
                              color: AppColors.success, size: 20),
                        ),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ex.completed
                                ? AppColors.success
                                : context.primary,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: context.textSecondary,
                      ),
                    ],
                  ),

                  // ── Brief summary when completed & collapsed ──
                  if (ex.completed && !isExpanded) ...[
                    const SizedBox(height: 6),
                    Text(
                      _briefSummary(ex),
                      style: TextStyle(fontSize: 12, color: context.textSubtle),
                    ),
                    if (avgRest != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.hourglass_bottom,
                              size: 12, color: context.textSubtle),
                          const SizedBox(width: 4),
                          Text(
                            l10n.workoutAvgRest(avgRest),
                            style: TextStyle(
                                fontSize: 11, color: context.textSubtle),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // ── Expanded content ──
                  if (isExpanded) ...[
                    const Divider(height: 20),
                    _buildSetsTable(index, ex, l10n),
                    const SizedBox(height: 8),
                    // Average rest summary
                    if (avgRest != null) ...[
                      Row(
                        children: [
                          Icon(Icons.hourglass_bottom,
                              size: 14, color: context.textSubtle),
                          const SizedBox(width: 4),
                          Text(
                            l10n.workoutAvgRest(avgRest),
                            style: TextStyle(
                                fontSize: 12, color: context.textSubtle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Add / Remove set
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(l10n.workoutAddSet,
                              style: const TextStyle(fontSize: 13)),
                          onPressed: () => _addSet(index),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.remove, size: 16),
                          label: Text(l10n.workoutRemoveSet,
                              style: const TextStyle(fontSize: 13)),
                          onPressed: ex.sets.length > 1
                              ? () => _removeSet(index)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Notes
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.workoutNotes,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      controller: _notesControllerFor(ex),
                      maxLines: 2,
                      onChanged: (v) => _updateExerciseNotes(index, v),
                    ),
                    const SizedBox(height: 12),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: Icon(
                          isSeriesProgressMode
                              ? Icons.task_alt_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(
                          isViewMode
                              ? l10n.workoutSaveExercise
                              : isSeriesProgressMode
                                  ? l10n
                                      .workoutFinishSet('${nextPendingSet + 1}')
                                  : l10n.workoutFinishExercise,
                        ),
                        onPressed: ex.completed
                            ? null
                            : isViewMode
                                ? () => _saveExercise(index)
                                : isSeriesProgressMode
                                    ? () => _completeNextPendingSet(index)
                                    : () => _finishExercise(index),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sets table ─────────────────────────────────────────────────

  Widget _buildSetsTable(
      int exIndex, WorkoutExercise ex, AppLocalizations l10n) {
    return Column(
      children: [
        // Header row
        Row(
          children: [
            const SizedBox(width: 52),
            Expanded(
              child: Text(l10n.workoutReps,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary)),
            ),
            Expanded(
              child: Text(l10n.workoutWeight,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Set rows
        ...List.generate(ex.sets.length, (setIdx) {
          final s = ex.sets[setIdx];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: s.completed ? AppColors.success : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 46,
                      child: Row(
                        children: [
                          if (s.completed)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.task_alt,
                                size: 14,
                                color: AppColors.success,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              l10n.workoutSet('${setIdx + 1}'),
                              style: TextStyle(
                                  fontSize: 11, color: context.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _StepperIntField(
                        value: s.reps,
                        step: 1,
                        onChanged: (v) => _updateSet(exIndex, setIdx, reps: v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StepperDoubleField(
                        value: s.weight,
                        step: 1.25,
                        onChanged: (v) =>
                            _updateSet(exIndex, setIdx, weight: v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Stepper field widgets ──────────────────────────────────────────

/// Integer field with -/+ buttons (step of 1, minimum 0).
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
  void didUpdateWidget(_StepperIntField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final text = widget.value == 0 ? '' : '${widget.value}';
      if (_controller.text != text) {
        _controller.text = text;
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _decrement() {
    final newVal = math.max(0, widget.value - widget.step);
    widget.onChanged(newVal);
  }

  void _increment() {
    widget.onChanged(widget.value + widget.step);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove, onTap: _decrement),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
            onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
          ),
        ),
        _StepButton(icon: Icons.add, onTap: _increment),
      ],
    );
  }
}

/// Double field with -/+ buttons (step of 1.25, minimum 0, max 2 decimals).
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
  void didUpdateWidget(_StepperDoubleField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final text = _display(widget.value);
      if (_controller.text != text) {
        _controller.text = text;
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _display(double v) {
    if (v == 0) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    // Show up to 2 decimals, trimming trailing zeros
    final s = v.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _decrement() {
    final newVal = math.max(0.0, widget.value - widget.step);
    // Round to 2 decimal places to avoid floating-point drift
    widget.onChanged(_round2(newVal));
  }

  void _increment() {
    widget.onChanged(_round2(widget.value + widget.step));
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove, onTap: _decrement),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_DecimalInputFormatter()],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v) ?? 0;
              widget.onChanged(_round2(parsed));
            },
          ),
        ),
        _StepButton(icon: Icons.add, onTap: _increment),
      ],
    );
  }
}

/// Small circular tap-target used as the +/- step button.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  // 44 dp is the Material minimum touch-target width; height is left
  // unconstrained so the button matches its sibling TextField height and
  // the expanded card stays within the ReorderableListView bounds.
  static const _minTouchWidth = 44.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _minTouchWidth),
        child:
            Center(child: Icon(icon, size: 22, color: context.textSecondary)),
      ),
    );
  }
}

/// Input formatter that allows at most one decimal separator and up to 2 decimal
/// places. Rejects invalid input and keeps the previous valid text.
class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    // Allow only digits and at most one dot
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) {
      return oldValue;
    }
    return newValue;
  }
}

// ── Rest stopwatch bottom sheet ─────────────────────────────────────

/// A standalone stopwatch widget displayed as a bottom sheet. It tracks rest
/// time between sets with centisecond precision and provides play, pause, and
/// reset controls. Completely independent from the session elapsed timer.
class _RestStopwatchSheet extends StatefulWidget {
  const _RestStopwatchSheet();

  @override
  State<_RestStopwatchSheet> createState() => _RestStopwatchSheetState();
}

class _RestStopwatchSheetState extends State<_RestStopwatchSheet> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  // 100 ms gives smooth centisecond updates at ~10 fps while cutting redraws by 3×.
  static const _tickInterval = Duration(milliseconds: 100);

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _start() {
    _stopwatch.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _pause() {
    _stopwatch.stop();
    _ticker?.cancel();
    setState(() {});
  }

  void _reset() {
    _stopwatch
      ..stop()
      ..reset();
    _ticker?.cancel();
    setState(() {});
  }

  String _formatStopwatch() => _stopwatch.elapsed.toStopwatch();

  @override
  Widget build(BuildContext context) {
    final isRunning = _stopwatch.isRunning;
    final hasElapsed = _stopwatch.elapsedMilliseconds > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_bottom,
                    size: 20, color: context.textSecondary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.workoutRestTimer ?? 'Descanso',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              _formatStopwatch(),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w300,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset button (square icon)
                _StopwatchButton(
                  icon: Icons.stop_rounded,
                  color: context.border,
                  activeColor: AppColors.destructive,
                  isActive: hasElapsed && !isRunning,
                  onTap: hasElapsed ? _reset : null,
                ),
                const SizedBox(width: 32),
                // Play / Pause button
                _StopwatchButton(
                  icon: isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: context.border,
                  activeColor:
                      isRunning ? AppColors.restTimer : AppColors.success,
                  isActive: true,
                  onTap: isRunning ? _pause : _start,
                  large: true,
                ),
                const SizedBox(width: 32),
                // Invisible spacer to keep play/pause centered
                const SizedBox(width: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular button used in the rest stopwatch controls.
class _StopwatchButton extends StatelessWidget {
  const _StopwatchButton({
    required this.icon,
    required this.color,
    required this.activeColor,
    required this.isActive,
    this.onTap,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final Color activeColor;
  final bool isActive;
  final VoidCallback? onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 48.0;
    final iconSize = large ? 32.0 : 24.0;
    final effectiveColor = isActive ? activeColor : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: effectiveColor, width: 2),
        ),
        child: Icon(icon, size: iconSize, color: effectiveColor),
      ),
    );
  }
}
