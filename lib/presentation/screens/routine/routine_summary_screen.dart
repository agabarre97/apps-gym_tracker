import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Final screen of the routine creation flow.
///
/// Shows a summary of all days with their muscle groups and exercises,
/// lets the user name the routine, and saves it.
class RoutineSummaryScreen extends StatefulWidget {
  const RoutineSummaryScreen({
    super.key,
    required this.type,
    required this.dayMuscleGroups,
    required this.dayExerciseKeys,
    required this.dayExerciseConfigs,
    required this.allExercises,
    required this.onSave,
    required this.onBack,
    this.onEditDay,
  });

  final String type;
  final List<List<String>> dayMuscleGroups;
  final List<List<String>> dayExerciseKeys;
  final List<List<RoutineExerciseConfig>> dayExerciseConfigs;
  final List<Exercise> allExercises;

  final Future<void> Function(String name) onSave;
  final VoidCallback onBack;

  /// Called when the user taps "Edit" on a day card. If null, no edit button.
  final void Function(int dayIndex)? onEditDay;

  @override
  State<RoutineSummaryScreen> createState() => _RoutineSummaryScreenState();
}

class _RoutineSummaryScreenState extends State<RoutineSummaryScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Resolves an exercise key to its localized display name.
  String _nameForKey(String key) {
    final match = widget.allExercises.where((e) => e.key == key);
    return match.isNotEmpty ? match.first.name : key;
  }

  RoutineExerciseConfig? _configForExercise(int dayIndex, String exerciseKey) {
    if (dayIndex >= widget.dayExerciseConfigs.length) return null;
    for (final config in widget.dayExerciseConfigs[dayIndex]) {
      if (config.exerciseKey == exerciseKey) return config;
    }
    return null;
  }

  String _configSummary(RoutineExerciseConfig config, AppLocalizations l10n) {
    if (config.setConfigs.isEmpty) return '';
    final totalSeries = config.setConfigs.length;
    final reps = config.setConfigs.map((set) => set.targetReps).toList();
    final minReps = reps.reduce((a, b) => a < b ? a : b);
    final maxReps = reps.reduce((a, b) => a > b ? a : b);
    final dropSets = config.setConfigs.fold<int>(
      0,
      (sum, set) => sum + set.dropSetCount,
    );
    final repsLabel = minReps == maxReps ? '$minReps' : '$minReps-$maxReps';
    final dropLabel = dropSets > 0 ? ' · Drop: $dropSets' : '';
    return '$totalSeries ${l10n.workoutSets.toLowerCase()} · $repsLabel ${l10n.workoutReps.toLowerCase()}$dropLabel';
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routineSummaryTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Name field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.routineNameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // Day summaries
                ...List.generate(widget.dayMuscleGroups.length, (i) {
                  final exerciseKeys = widget.dayExerciseKeys[i];
                  final groups = Exercise.categoriesForDay(
                    allExercises: widget.allExercises,
                    exerciseKeysForDay: exerciseKeys,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.routineDayLabel('${i + 1}'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (widget.onEditDay != null)
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(l10n.routineEditDay),
                              style: TextButton.styleFrom(
                                foregroundColor: context.textSecondary,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => widget.onEditDay!(i),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${exerciseKeys.length} ${l10n.routineExercises}',
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 12),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: groups
                                .map((g) => Chip(
                                      label: Text(
                                        categoryLabelForLocale(g, lang),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        ...exerciseKeys.map((key) {
                          final config = _configForExercise(i, key);
                          final subtitle = config == null
                              ? null
                              : _configSummary(config, l10n);
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.fitness_center,
                                size: 16, color: context.textSecondary),
                            title: Text(_nameForKey(key),
                                style: const TextStyle(fontSize: 13)),
                            subtitle: subtitle == null
                                ? null
                                : Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.textSubtle,
                                    ),
                                  ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Save button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _nameController.text.trim().isNotEmpty && !_saving
                      ? _handleSave
                      : null,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.routineSave),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
