import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/services/routine_pdf_export_service.dart';
import 'package:gym_tracker/presentation/components/export_sheet.dart';
import 'package:gym_tracker/presentation/components/pdf_share_helper.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/ports/custom_exercise_port.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/presentation/components/delete_routine_dialog.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_config_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/workout/exercise_progress_screen.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

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
    required this.profilePort,
    this.customExercisePort,
  });

  final Routine routine;
  final List<Routine> allRoutines;
  final RoutinePort routinePort;
  final List<Exercise> allExercises;
  final WorkoutSessionPort workoutSessionPort;
  final ProfilePort profilePort;
  final CustomExercisePort? customExercisePort;

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

  List<RoutineExerciseConfig> _buildConfigsForKeys(
    List<String> exerciseKeys, {
    List<RoutineExerciseConfig> previous = const [],
  }) {
    final byKey = <String, RoutineExerciseConfig>{
      for (final config in previous) config.exerciseKey: config,
    };
    return exerciseKeys
        .map((key) => byKey[key] ?? RoutineExerciseConfig(exerciseKey: key))
        .toList(growable: false);
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

  // ── Export ──────────────────────────────────────────────────────

  void _handleExport() => showExportSheet(
        context,
        jsonString: _routine.toExportJsonString(),
        onExportPdf: _exportPdf,
      );

  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final sessions = await widget.workoutSessionPort.loadSessions();
      final routineSessions = sessions
          .where((session) => session.routineId == _routine.id)
          .toList()
        ..sort(_compareSessionDesc);
      final latestSession =
          routineSessions.isEmpty ? null : routineSessions.first;

      final bytes = await RoutinePdfExportService.buildWorkoutRoutinePdf(
        routine: _routine,
        allExercises: widget.allExercises,
        lastSession: latestSession,
        generatedAt: DateTime.now(),
      );

      await sharePdfBytes(
        pdfBytes: bytes,
        fileName: 'rutina_${_routine.name}_export.pdf',
      );
    } catch (error, stackTrace) {
      debugPrint('Routine PDF export failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineExportPdfError)),
      );
    }
  }

  int _compareSessionDesc(WorkoutSession a, WorkoutSession b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;

    final aStart = a.startTime;
    final bStart = b.startTime;
    if (aStart == null && bStart == null) return 0;
    if (aStart == null) return 1;
    if (bStart == null) return -1;
    return bStart.compareTo(aStart);
  }

  // ── Delete ───────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDeleteRoutineDialog(
      context,
      routineName: _routine.name,
    );

    if (confirmed != true || !mounted) return;

    final updated = widget.allRoutines.map((r) {
      return r.id == _routine.id ? r.copyWith(isArchived: true) : r;
    }).toList();
    await widget.routinePort.saveRoutines(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  // ── Edit day exercises ──────────────────────────────────────────

  Future<void> _editDay(int dayIndex) async {
    final day = _routine.days[dayIndex];
    final categories = day.muscleGroups;
    final availableCategories = byMuscleCategoryOrder;

    final selectionResult =
        await Navigator.of(context).push<ExerciseSelectionResult>(
      MaterialPageRoute(
        builder: (_) => ExerciseSelectionScreen(
          currentDay: dayIndex + 1,
          totalDays: _routine.days.length,
          initialSelectedCategories: categories,
          availableCategories: availableCategories,
          allExercises: widget.allExercises,
          customExercisePort: widget.customExercisePort,
          initialSelectedKeys: day.exerciseKeys,
          onConfirmed: (result) => Navigator.of(context).pop(result),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );

    if (selectionResult == null || !mounted) return;

    final configured =
        await Navigator.of(context).push<List<RoutineExerciseConfig>>(
      MaterialPageRoute(
        builder: (_) => ExerciseConfigScreen(
          currentDay: dayIndex + 1,
          totalDays: _routine.days.length,
          exerciseKeys: selectionResult.selectedExerciseKeys,
          allExercises: widget.allExercises,
          initialConfigs: _buildConfigsForKeys(
            selectionResult.selectedExerciseKeys,
            previous: day.exerciseConfigs,
          ),
          onConfirmed: (configs) => Navigator.of(context).pop(configs),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (configured == null || !mounted) return;

    // Update this day with selected exercises and their configuration.
    final newDays = List<RoutineDay>.from(_routine.days);
    newDays[dayIndex] = RoutineDay(
      muscleGroups: selectionResult.selectedCategories,
      exerciseKeys: selectionResult.selectedExerciseKeys,
      exerciseConfigs: configured,
    );

    final updatedRoutine = _routine.copyWith(days: newDays);

    await _saveRoutine(updatedRoutine);
  }

  Future<void> _saveRoutine(Routine updatedRoutine) async {
    final updatedList = widget.allRoutines.map((r) {
      return r.id == _routine.id ? updatedRoutine : r;
    }).toList();
    await widget.routinePort.saveRoutines(updatedList);
    if (!mounted) return;
    setState(() => _routine = updatedRoutine);
  }

  void _reorderDayExercises(int dayIndex, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final day = _routine.days[dayIndex];
    final reorderedKeys = List<String>.from(day.exerciseKeys);
    final moved = reorderedKeys.removeAt(oldIndex);
    reorderedKeys.insert(newIndex, moved);

    final updatedDays = List<RoutineDay>.from(_routine.days);
    updatedDays[dayIndex] = RoutineDay(
      muscleGroups: day.muscleGroups,
      exerciseKeys: reorderedKeys,
      exerciseConfigs: reorderedKeys
          .map((key) =>
              day.configForExercise(key) ??
              RoutineExerciseConfig(exerciseKey: key))
          .toList(growable: false),
    );
    final updatedRoutine = _routine.copyWith(days: updatedDays);

    setState(() => _routine = updatedRoutine);
    unawaited(_saveRoutine(updatedRoutine));
  }

  // ── Progress ───────────────────────────────────────────────────

  Future<void> _viewProgress(int dayIndex, String exerciseKey) async {
    final profile = await widget.profilePort.loadProfile();
    if (!mounted || profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseProgressScreen(
          workoutSessionPort: widget.workoutSessionPort,
          profile: profile,
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
                  final groups = Exercise.categoriesForDay(
                    allExercises: widget.allExercises,
                    exerciseKeysForDay: day.exerciseKeys,
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
                          // Edit button
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(l10n.routineEditDay),
                            style: TextButton.styleFrom(
                              foregroundColor: context.textSecondary,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _editDay(i),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${day.exerciseKeys.length} ${l10n.routineExercises}',
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
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) =>
                              _reorderDayExercises(i, oldIndex, newIndex),
                          children:
                              day.exerciseKeys.asMap().entries.map((entry) {
                            final exerciseIndex = entry.key;
                            final key = entry.value;
                            return ListTile(
                              key: ValueKey('routine-day-$i-exercise-$key'),
                              dense: true,
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 16,
                                    color: context.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  ReorderableDragStartListener(
                                    index: exerciseIndex,
                                    child: Icon(
                                      Icons.drag_handle,
                                      key: ValueKey(
                                          'routine-day-$i-drag-handle-$key'),
                                      size: 18,
                                      color: context.textSubtle,
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                _nameForKey(key),
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: () {
                                final config = day.configForExercise(key);
                                if (config == null) return null;
                                return Text(
                                  _configSummary(config, l10n),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.textSubtle,
                                  ),
                                );
                              }(),
                              trailing: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: context.textDisabled,
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
                            );
                          }).toList(),
                        ),
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
                    foregroundColor: AppColors.destructive,
                    side: const BorderSide(color: AppColors.destructive),
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
