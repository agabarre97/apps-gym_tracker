import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/export_sheet.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/muscle_group.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/presentation/components/delete_routine_dialog.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/workout/exercise_progress_screen.dart';

/// Read-only detail view for an existing routine.
///
/// Shows days with their muscle groups and exercises.
/// Allows editing exercises per day and deleting the entire routine
/// (with a confirmation dialog).
class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({
    super.key,
    required this.routine,
    required this.allRoutines,
    required this.routinePort,
    required this.allExercises,
    required this.workoutSessionPort,
  });

  final Routine routine;
  final List<Routine> allRoutines;
  final RoutinePort routinePort;
  final List<Exercise> allExercises;
  final WorkoutSessionPort workoutSessionPort;

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late Routine _routine;

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
  }

  // ── Helpers ──────────────────────────────────────────────────────

  /// Resolves an exercise key to its localized display name.
  String _nameForKey(String key) =>
      Exercise.nameForKey(widget.allExercises, key);

  /// Resolves muscle group category keys to enum values.
  List<MuscleGroupCategory> _categoriesFromKeys(List<String> keys) {
    return keys
        .map((k) {
          try {
            return MuscleGroupCategory.values.firstWhere((v) => v.name == k);
          } catch (_) {
            return null;
          }
        })
        .whereType<MuscleGroupCategory>()
        .toList();
  }

  // ── Export ──────────────────────────────────────────────────────

  void _handleExport() => showExportSheet(
        context,
        jsonString: _routine.toExportJsonString(),
      );

  // ── Delete ───────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDeleteRoutineDialog(
      context,
      routineName: _routine.name,
    );

    if (confirmed != true || !mounted) return;

    final updated =
        widget.allRoutines.where((r) => r.id != _routine.id).toList();
    await widget.routinePort.saveRoutines(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  // ── Edit day exercises ──────────────────────────────────────────

  Future<void> _editDay(int dayIndex) async {
    final day = _routine.days[dayIndex];
    final categories = _categoriesFromKeys(day.muscleGroups);

    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _EditDayExercisesScreen(
          dayIndex: dayIndex,
          totalDays: _routine.days.length,
          selectedCategories: categories,
          allExercises: widget.allExercises,
          initialSelectedKeys: day.exerciseKeys,
        ),
      ),
    );

    if (result == null || !mounted) return;

    // Update just this day's exercises
    final newDays = List<RoutineDay>.from(_routine.days);
    newDays[dayIndex] = RoutineDay(
      muscleGroups: day.muscleGroups,
      exerciseKeys: result,
    );

    final updatedRoutine = _routine.copyWith(days: newDays);

    // Persist
    final updatedList = widget.allRoutines.map((r) {
      return r.id == _routine.id ? updatedRoutine : r;
    }).toList();
    await widget.routinePort.saveRoutines(updatedList);

    setState(() => _routine = updatedRoutine);
  }

  // ── Progress ───────────────────────────────────────────────────

  void _viewProgress(int dayIndex, String exerciseKey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseProgressScreen(
          workoutSessionPort: widget.workoutSessionPort,
          routineId: _routine.id,
          routineDayIndex: dayIndex,
          exerciseKey: exerciseKey,
          exerciseDisplayName: _nameForKey(exerciseKey),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final labels = muscleGroupLabels(lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(_routine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.routineExport,
            onPressed: _handleExport,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Day summaries
                ...List.generate(_routine.days.length, (i) {
                  final day = _routine.days[i];
                  final groups = _categoriesFromKeys(day.muscleGroups);

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
                          // Edit button
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(l10n.routineEditDay),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _editDay(i),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${day.exerciseKeys.length} ${l10n.routineExercises}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
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
                                        labels[g] ?? g.name,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        ...day.exerciseKeys.map((key) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.fitness_center,
                                  size: 16, color: Colors.white54),
                              title: Text(_nameForKey(key),
                                  style: const TextStyle(fontSize: 13)),
                              trailing: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white60,
                                  visualDensity: VisualDensity.compact,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () => _viewProgress(i, key),
                                child: Text(
                                  l10n.routineViewProgress,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Delete button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.routineDelete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmDelete,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private wrapper to return exercise keys from the selection screen ────

class _EditDayExercisesScreen extends StatelessWidget {
  const _EditDayExercisesScreen({
    required this.dayIndex,
    required this.totalDays,
    required this.selectedCategories,
    required this.allExercises,
    required this.initialSelectedKeys,
  });

  final int dayIndex;
  final int totalDays;
  final List<MuscleGroupCategory> selectedCategories;
  final List<Exercise> allExercises;
  final List<String> initialSelectedKeys;

  @override
  Widget build(BuildContext context) {
    return ExerciseSelectionScreen(
      currentDay: dayIndex + 1,
      totalDays: totalDays,
      allExercises: allExercises,
      initialSelectedCategories: selectedCategories,
      initialSelectedKeys: initialSelectedKeys,
      onConfirmed: (result) =>
          Navigator.of(context).pop(result.selectedExerciseKeys),
      onBack: () => Navigator.of(context).pop(),
    );
  }
}
