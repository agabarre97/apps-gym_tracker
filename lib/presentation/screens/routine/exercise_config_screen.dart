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
    _configs = widget.exerciseKeys.map(
      (key) {
        final existing = byKey[key];
        if (existing != null && existing.setConfigs.isNotEmpty) {
          return existing;
        }
        return RoutineExerciseConfig(
          exerciseKey: key,
          setConfigs: const [
            RoutineSetConfig(),
            RoutineSetConfig(),
            RoutineSetConfig(),
          ],
        );
      },
    ).toList(growable: false);
  }

  String _nameForKey(String key) =>
      Exercise.nameForKey(widget.allExercises, key);

  void _updateConfig(int index, RoutineExerciseConfig config) {
    setState(() {
      _configs = List<RoutineExerciseConfig>.from(_configs)..[index] = config;
    });
  }

  void _addSet(int exerciseIndex) {
    final config = _configs[exerciseIndex];
    final updated = List<RoutineSetConfig>.from(config.setConfigs);

    final int nextTargetReps =
        updated.isNotEmpty ? updated.last.targetReps : 10;

    updated.add(RoutineSetConfig(targetReps: nextTargetReps));
    _updateConfig(exerciseIndex, config.copyWith(setConfigs: updated));
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    final config = _configs[exerciseIndex];
    if (config.setConfigs.length <= 1) return;
    final updated = List<RoutineSetConfig>.from(config.setConfigs)
      ..removeAt(setIndex);
    _updateConfig(exerciseIndex, config.copyWith(setConfigs: updated));
  }

  void _updateSetConfig(
    int exerciseIndex,
    int setIndex,
    RoutineSetConfig next,
  ) {
    final config = _configs[exerciseIndex];
    final updated = List<RoutineSetConfig>.from(config.setConfigs)
      ..[setIndex] = next;
    _updateConfig(exerciseIndex, config.copyWith(setConfigs: updated));
  }

  Future<void> _configureRest(int exerciseIndex) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (_) => _RestPickerSheet(
        initialSeconds: _configs[exerciseIndex].restSeconds,
      ),
    );
    if (!mounted) return;
    if (selected == null) return;
    if (selected < 0) {
      _updateConfig(
        exerciseIndex,
        _configs[exerciseIndex].copyWith(clearRestSeconds: true),
      );
      return;
    }
    _updateConfig(
      exerciseIndex,
      _configs[exerciseIndex].copyWith(restSeconds: selected),
    );
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
                final setConfigs = config.setConfigs.isEmpty
                    ? const [
                        RoutineSetConfig(),
                        RoutineSetConfig(),
                        RoutineSetConfig()
                      ]
                    : config.setConfigs;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _nameForKey(config.exerciseKey),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              key: ValueKey(
                                'exercise_config_rest_${config.exerciseKey}',
                              ),
                              onPressed: () => _configureRest(index),
                              icon:
                                  const Icon(Icons.hourglass_bottom, size: 16),
                              label: Text(
                                config.restSeconds == null
                                    ? l10n.mobilityRestOff
                                    : TimeFormatter.mmss(config.restSeconds!),
                              ),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(setConfigs.length, (setIndex) {
                          final setConfig = setConfigs[setIndex];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: context.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      l10n.workoutSet('${setIndex + 1}'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent, size: 20),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Eliminar',
                                      onPressed: setConfigs.length > 1
                                          ? () => _removeSet(index, setIndex)
                                          : null,
                                    ),
                                  ],
                                ),
                                _IntStepper(
                                  label: l10n.routineTargetReps,
                                  value: setConfig.targetReps,
                                  min: 1,
                                  max: 50,
                                  onChanged: (value) => _updateSetConfig(
                                    index,
                                    setIndex,
                                    setConfig.copyWith(targetReps: value),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Drop set',
                                        style: TextStyle(fontSize: 13)),
                                    Switch.adaptive(
                                      value: setConfig.hasDropSet,
                                      onChanged: (enabled) {
                                        _updateSetConfig(
                                          index,
                                          setIndex,
                                          enabled
                                              ? setConfig.copyWith(
                                                  dropSetCount:
                                                      setConfig.dropSetCount > 0
                                                          ? setConfig
                                                              .dropSetCount
                                                          : 1,
                                                  dropSetReps:
                                                      setConfig.dropSetReps ??
                                                          setConfig.targetReps,
                                                )
                                              : setConfig.copyWith(
                                                  dropSetCount: 0,
                                                  clearDropSetReps: true,
                                                ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                if (setConfig.hasDropSet) ...[
                                  _IntStepper(
                                    label: '# Drop sets',
                                    value: setConfig.dropSetCount,
                                    min: 1,
                                    max: 5,
                                    onChanged: (value) => _updateSetConfig(
                                      index,
                                      setIndex,
                                      setConfig.copyWith(dropSetCount: value),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _IntStepper(
                                    label: 'Reps drop',
                                    value: setConfig.dropSetReps ??
                                        setConfig.targetReps,
                                    min: 1,
                                    max: 50,
                                    onChanged: (value) => _updateSetConfig(
                                      index,
                                      setIndex,
                                      setConfig.copyWith(dropSetReps: value),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir serie'),
                          onPressed: () => _addSet(index),
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

class _IntStepper extends StatefulWidget {
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
  State<_IntStepper> createState() => _IntStepperState();
}

class _IntStepperState extends State<_IntStepper> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _IntStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDec = widget.value > widget.min;
    final canInc = widget.value < widget.max;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textSecondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed:
                  canDec ? () => widget.onChanged(widget.value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    widget.onChanged(parsed);
                  }
                },
              ),
            ),
            IconButton(
              onPressed:
                  canInc ? () => widget.onChanged(widget.value + 1) : null,
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
