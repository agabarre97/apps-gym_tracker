import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';

/// Step screen used to configure default sets/reps/rest per exercise.
class ExerciseConfigScreen extends StatefulWidget {
  const ExerciseConfigScreen({
    super.key,
    required this.currentDay,
    required this.totalDays,
    required this.exerciseKeys,
    required this.allExercises,
    required this.onConfirmed,
    required this.onBack,
    this.initialConfigs = const [],
  });

  final int currentDay;
  final int totalDays;
  final List<String> exerciseKeys;
  final List<Exercise> allExercises;
  final List<RoutineExerciseConfig> initialConfigs;
  final ValueChanged<List<RoutineExerciseConfig>> onConfirmed;
  final VoidCallback onBack;

  @override
  State<ExerciseConfigScreen> createState() => _ExerciseConfigScreenState();
}

class _ExerciseConfigScreenState extends State<ExerciseConfigScreen> {
  late List<RoutineExerciseConfig> _configs;

  @override
  void initState() {
    super.initState();
    final byKey = <String, RoutineExerciseConfig>{
      for (final config in widget.initialConfigs) config.exerciseKey: config,
    };
    _configs = widget.exerciseKeys
        .map((key) => byKey[key] ?? RoutineExerciseConfig(exerciseKey: key))
        .toList(growable: false);
  }

  String _nameForKey(String key) =>
      Exercise.nameForKey(widget.allExercises, key);

  void _updateConfig(int index, RoutineExerciseConfig config) {
    setState(() {
      _configs = List<RoutineExerciseConfig>.from(_configs)..[index] = config;
    });
  }

  Future<void> _configureRest(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          _RestPickerSheet(initialSeconds: _configs[index].restSeconds),
    );
    if (!mounted) return;
    if (selected == null) return;
    if (selected < 0) {
      _updateConfig(index, _configs[index].copyWith(clearRestSeconds: true));
      return;
    }
    _updateConfig(index, _configs[index].copyWith(restSeconds: selected));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.workoutRestTimer,
        ),
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            l10n.routineDayOf('${widget.currentDay}', '${widget.totalDays}')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.routineExerciseConfigTitle,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _configs.length,
              itemBuilder: (context, index) {
                final config = _configs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameForKey(config.exerciseKey),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _IntStepper(
                                label: l10n.workoutSets,
                                value: config.sets,
                                min: 1,
                                max: 10,
                                onChanged: (value) => _updateConfig(
                                  index,
                                  config.copyWith(sets: value),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _IntStepper(
                                label: l10n.routineTargetReps,
                                value: config.targetReps,
                                min: 1,
                                max: 50,
                                onChanged: (value) => _updateConfig(
                                  index,
                                  config.copyWith(targetReps: value),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            key: ValueKey(
                              'exercise_config_rest_${config.exerciseKey}',
                            ),
                            onPressed: () => _configureRest(index),
                            icon: const Icon(Icons.hourglass_bottom, size: 16),
                            label: Text(
                              '${l10n.workoutRestTimer}: ${config.restSeconds == null ? l10n.mobilityRestOff : TimeFormatter.mmss(config.restSeconds!)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('exercise_config_next'),
                  onPressed: () => widget.onConfirmed(_configs),
                  child: Text(l10n.sharedNext),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntStepper extends StatelessWidget {
  const _IntStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canDec = value > min;
    final canInc = value < max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: context.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              onPressed: canDec ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            IconButton(
              onPressed: canInc ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
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
                      key: ValueKey('routine_rest_preset_$seconds'),
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
              key: const ValueKey('routine_rest_manual_seconds'),
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
                  key: const ValueKey('routine_rest_disable'),
                  onPressed: () => Navigator.of(context).pop(-1),
                  child: Text(l10n.mobilityRestOff),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('routine_rest_save'),
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
