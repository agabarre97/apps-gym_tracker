import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _nameForKey(String key) =>
      Exercise.nameForKey(widget.allExercises, key);

  // ── Persistence ────────────────────────────────────────────────

  Future<void> _persistSession() async {
    final all = await widget.workoutSessionPort.loadSessions();
    final idx = all.indexWhere((s) => s.id == _session.id);
    if (idx >= 0) {
      all[idx] = _session;
    } else {
      all.add(_session);
    }
    await widget.workoutSessionPort.saveSessions(all);
  }

  // ── Exercise actions ───────────────────────────────────────────

  void _saveExercise(int index) {
    setState(() {
      final ex = _session.exercises[index];
      final updated = ex.copyWith(completed: true);
      final list = List<WorkoutExercise>.from(_session.exercises);
      list[index] = updated;
      _session = _session.copyWith(exercises: list);
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
      Navigator.of(context).pop(true); // signal refresh
    }
  }

  /// View/edit mode (calendar): just save and go back.
  Future<void> _saveChanges() async {
    await _persistSession();
    if (mounted) {
      Navigator.of(context).pop(true); // signal refresh
    }
  }

  // ── Elapsed time format ────────────────────────────────────────

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  /// Brief summary for a completed exercise, e.g. "3x12 @ 60kg".
  String _briefSummary(WorkoutExercise ex) {
    if (ex.sets.isEmpty) return '';
    final parts = <String>[];
    for (final s in ex.sets) {
      final w = s.weight == s.weight.truncateToDouble()
          ? s.weight.toInt().toString()
          : s.weight.toStringAsFixed(1);
      parts.add('${s.reps}x${w}kg');
    }
    return parts.join(' | ');
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // In live workout mode, intercept back to confirm finish.
    // In view/edit mode (calendar), allow free back navigation.
    return PopScope(
      canPop: !widget.trackTime,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.trackTime) _confirmFinish();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.routineName),
          actions: [
            if (widget.trackTime)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 18, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_elapsed),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _session.exercises.length,
                itemBuilder: (context, index) =>
                    _buildExerciseCard(index, l10n),
              ),
            ),
            // Bottom action button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: widget.trackTime
                      // Live workout: "Finalizar entrenamiento" always enabled
                      ? FilledButton.icon(
                          icon: const Icon(Icons.flag),
                          label: Text(l10n.workoutFinish),
                          onPressed: _confirmFinish,
                        )
                      // View/edit from calendar: "Guardar cambios" only if modified
                      : FilledButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(l10n.workoutSaveChanges),
                          onPressed: _hasChanges ? _saveChanges : null,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _expandedIndex = isExpanded ? -1 : index;
        }),
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
                          color: Colors.greenAccent, size: 20),
                    ),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            ex.completed ? Colors.greenAccent : Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                ],
              ),

              // ── Brief summary when completed & collapsed ──
              if (ex.completed && !isExpanded) ...[
                const SizedBox(height: 6),
                Text(
                  _briefSummary(ex),
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ],

              // ── Expanded content ──
              if (isExpanded) ...[
                const Divider(height: 20),
                _buildSetsTable(index, ex, l10n),
                const SizedBox(height: 8),
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
                      onPressed:
                          ex.sets.length > 1 ? () => _removeSet(index) : null,
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
                  controller: TextEditingController(text: ex.notes),
                  maxLines: 2,
                  onChanged: (v) => _updateExerciseNotes(index, v),
                ),
                const SizedBox(height: 12),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(l10n.workoutSaveExercise),
                    onPressed: () => _saveExercise(index),
                  ),
                ),
              ],
            ],
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
            const SizedBox(width: 40), // set number column
            Expanded(
              child: Text(l10n.workoutReps,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54)),
            ),
            Expanded(
              child: Text(l10n.workoutWeight,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Set rows
        ...List.generate(ex.sets.length, (setIdx) {
          final s = ex.sets[setIdx];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    l10n.workoutSet('${setIdx + 1}'),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _IntField(
                      value: s.reps,
                      onChanged: (v) =>
                          _updateSet(exIndex, setIdx, reps: v),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _DoubleField(
                      value: s.weight,
                      onChanged: (v) =>
                          _updateSet(exIndex, setIdx, weight: v),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Small field widgets ────────────────────────────────────────────

class _IntField extends StatelessWidget {
  const _IntField({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value == 0 ? '' : '$value'),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      ),
      onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
    );
  }
}

class _DoubleField extends StatelessWidget {
  const _DoubleField({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final display =
        value == 0 ? '' : (value == value.truncateToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(1));
    return TextField(
      controller: TextEditingController(text: display),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      ),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }
}
