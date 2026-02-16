import 'dart:async';
import 'dart:math' as math;

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

  // ── Rest-time tracking (in-memory, not persisted) ──────────────
  /// First edit timestamp per (exerciseIndex, setIndex).
  final Map<(int, int), DateTime> _firstEditTimes = {};

  /// Last edit timestamp per (exerciseIndex, setIndex).
  final Map<(int, int), DateTime> _lastEditTimes = {};

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
    final lastIdx = ex.sets.length - 1;
    _firstEditTimes.remove((exIndex, lastIdx));
    _lastEditTimes.remove((exIndex, lastIdx));
    final newSets = List<ExerciseSet>.from(ex.sets)..removeLast();
    _updateExerciseSets(exIndex, newSets);
  }

  void _updateSet(int exIndex, int setIndex, {int? reps, double? weight}) {
    final now = DateTime.now();
    final key = (exIndex, setIndex);

    // Track first and last edit timestamps for rest estimation
    _firstEditTimes.putIfAbsent(key, () => now);
    _lastEditTimes[key] = now;

    // Compute estimated rest for this set (skip the first set)
    int? restSeconds;
    if (setIndex > 0) {
      final prevKey = (exIndex, setIndex - 1);
      final prevLastEdit = _lastEditTimes[prevKey];
      final thisFirstEdit = _firstEditTimes[key];
      if (prevLastEdit != null && thisFirstEdit != null) {
        restSeconds = thisFirstEdit.difference(prevLastEdit).inSeconds;
        if (restSeconds < 0) restSeconds = null;
      }
    }

    final ex = _session.exercises[exIndex];
    final newSets = List<ExerciseSet>.from(ex.sets);
    newSets[setIndex] = newSets[setIndex].copyWith(
      reps: reps,
      weight: weight,
      estimatedRestSeconds: restSeconds,
      clearRest: setIndex == 0,
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
      Navigator.of(context).pop(true);
    }
  }

  /// View/edit mode (calendar): just save and go back.
  Future<void> _saveChanges() async {
    await _persistSession();
    if (mounted) {
      Navigator.of(context).pop(true);
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
          : s.weight.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      parts.add('${s.reps}x${w}kg');
    }
    return parts.join(' | ');
  }

  /// Compute average rest seconds for an exercise (ignoring first set and nulls).
  String? _averageRestLabel(WorkoutExercise ex) {
    final rests = ex.sets
        .where((s) => s.estimatedRestSeconds != null && s.estimatedRestSeconds! > 0)
        .map((s) => s.estimatedRestSeconds!)
        .toList();
    if (rests.isEmpty) return null;
    final avg = (rests.reduce((a, b) => a + b) / rests.length).round();
    return _formatRestSeconds(avg);
  }

  String _formatRestSeconds(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    }
    return '${seconds}s';
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
    final avgRest = _averageRestLabel(ex);

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
                if (avgRest != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.hourglass_bottom,
                          size: 12, color: Colors.white24),
                      const SizedBox(width: 4),
                      Text(
                        l10n.workoutAvgRest(avgRest),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white24),
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
                      const Icon(Icons.hourglass_bottom,
                          size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        l10n.workoutAvgRest(avgRest),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white38),
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
            const SizedBox(width: 36),
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
                      width: 36,
                      child: Text(
                        l10n.workoutSet('${setIdx + 1}'),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white54),
                      ),
                    ),
                    Expanded(
                      child: _StepperIntField(
                        value: s.reps,
                        step: 1,
                        onChanged: (v) =>
                            _updateSet(exIndex, setIdx, reps: v),
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
    _controller = TextEditingController(
        text: widget.value == 0 ? '' : '${widget.value}');
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
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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

  static double _round2(double v) =>
      (v * 100).roundToDouble() / 100;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove, onTap: _decrement),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_DecimalInputFormatter()],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: Colors.white54),
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
