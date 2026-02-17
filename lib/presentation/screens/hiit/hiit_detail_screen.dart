import 'package:flutter/material.dart';
import 'package:gym_tracker/data/datasources/asset_data_loader.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/ports/hiit_session_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/services/routine_pdf_export_service.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/delete_routine_dialog.dart';
import 'package:gym_tracker/presentation/components/export_sheet.dart';
import 'package:gym_tracker/presentation/components/pdf_share_helper.dart';
import 'package:gym_tracker/presentation/components/time_wheel_picker.dart';
import 'package:gym_tracker/domain/entities/hiit_config.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_exercise_selection_screen.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_timer_screen.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';

/// Detail screen for an existing HIIT routine.
///
/// Displays exercise list, configuration summary, and offers
/// settings adjustment before starting the timer.
class HiitDetailScreen extends StatefulWidget {
  const HiitDetailScreen({
    super.key,
    required this.routine,
    required this.allRoutines,
    required this.routinePort,
    required this.hiitSessionPort,
    @visibleForTesting this.preloadedExercises,
  });

  final Routine routine;
  final List<Routine> allRoutines;
  final RoutinePort routinePort;
  final HiitSessionPort hiitSessionPort;

  /// HIIT exercises injected for testing (skips asset loading).
  @visibleForTesting
  final List<HiitExercise>? preloadedExercises;

  @override
  State<HiitDetailScreen> createState() => _HiitDetailScreenState();
}

class _HiitDetailScreenState extends State<HiitDetailScreen> {
  List<HiitExercise> _allHiitExercises = [];
  bool _loading = true;
  bool _loadStarted = false;

  /// Mutable copy of the routine so exercise edits can be tracked locally.
  late Routine _currentRoutine;

  // Mutable config that can be adjusted before starting
  late int _sets;
  late int _workSeconds;
  late int _restSeconds;
  late int _setRestSeconds;

  @override
  void initState() {
    super.initState();
    _currentRoutine = widget.routine;
    _sets = widget.routine.hiitSets ?? HiitConfig.defaultSets;
    _workSeconds =
        widget.routine.hiitWorkSeconds ?? HiitConfig.defaultWorkSeconds;
    _restSeconds =
        widget.routine.hiitRestSeconds ?? HiitConfig.defaultRestSeconds;
    _setRestSeconds =
        widget.routine.hiitSetRestSeconds ?? HiitConfig.defaultSetRestSeconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _loadExercises();
    }
  }

  Future<void> _loadExercises() async {
    try {
      if (widget.preloadedExercises != null) {
        _allHiitExercises = widget.preloadedExercises!;
      } else {
        final lang = Localizations.localeOf(context).languageCode;
        _allHiitExercises = await AssetDataLoader.loadHiitExercises(lang);
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<HiitExercise> get _routineExercises {
    if (_currentRoutine.days.isEmpty) return [];
    final keys = _currentRoutine.days.first.exerciseKeys;
    return keys.map((key) {
      try {
        return _allHiitExercises.firstWhere((e) => e.key == key);
      } catch (_) {
        return HiitExercise(key: key, name: key, description: '');
      }
    }).toList();
  }

  int get _totalDurationSeconds {
    final exerciseCount = _routineExercises.length;
    if (exerciseCount == 0) return 0;
    final workPerSet = exerciseCount * _workSeconds;
    final restPerSet = (exerciseCount - 1) * _restSeconds;
    final setRest = (_sets - 1) * _setRestSeconds;
    return _sets * (workPerSet + restPerSet) + setRest;
  }

  String _formatDuration(int totalSeconds) =>
      TimeFormatter.duration(totalSeconds);

  void _handleExport() => showExportSheet(
        context,
        jsonString: _currentRoutine.toExportJsonString(),
        onExportPdf: _exportPdf,
      );

  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final sessions = await widget.hiitSessionPort.loadSessions();
      final routineSessions = sessions
          .where((session) => session.routineName == _currentRoutine.name)
          .toList()
        ..sort(_compareSessionDesc);
      final latestSession =
          routineSessions.isEmpty ? null : routineSessions.first;

      final bytes = await RoutinePdfExportService.buildHiitRoutinePdf(
        routine: _currentRoutine,
        routineExercises: _routineExercises,
        lastSession: latestSession,
        generatedAt: DateTime.now(),
      );

      await sharePdfBytes(
        pdfBytes: bytes,
        fileName: 'rutina_hiit_${_currentRoutine.name}_export.pdf',
      );
    } catch (error, stackTrace) {
      debugPrint('HIIT PDF export failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineExportPdfError)),
      );
    }
  }

  int _compareSessionDesc(HiitSession a, HiitSession b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    final aStart = a.startTime;
    final bStart = b.startTime;
    if (aStart == null && bStart == null) return 0;
    if (aStart == null) return 1;
    if (bStart == null) return -1;
    return bStart.compareTo(aStart);
  }

  /// Opens the exercise selection screen pre-filled with the current
  /// exercise keys, allowing the user to add or remove exercises.
  Future<void> _editExercises() async {
    final currentKeys = _currentRoutine.days.isNotEmpty
        ? _currentRoutine.days.first.exerciseKeys
        : <String>[];

    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => HiitExerciseSelectionScreen(
          exercises: _allHiitExercises,
          initialSelectedKeys: currentKeys,
          onConfirmed: (keys) => Navigator.of(context).pop(keys),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );

    if (result == null || !mounted) return;

    // Build updated routine with new exercise keys
    final updatedRoutine = _currentRoutine.copyWith(
      days: [
        RoutineDay(
          muscleGroups: const [],
          exerciseKeys: result,
        ),
      ],
    );

    // Persist the change
    final updatedList = widget.allRoutines.map((r) {
      return r.id == updatedRoutine.id ? updatedRoutine : r;
    }).toList();
    await widget.routinePort.saveRoutines(updatedList);

    if (!mounted) return;
    setState(() {
      _currentRoutine = updatedRoutine;
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDeleteRoutineDialog(
      context,
      routineName: _currentRoutine.name,
    );

    if (confirmed != true || !mounted) return;

    final updated = widget.allRoutines.map((r) {
      return r.id == _currentRoutine.id ? r.copyWith(isArchived: true) : r;
    }).toList();
    await widget.routinePort.saveRoutines(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showSettings() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.hiitConfig,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Sets
                    _SettingsRow(
                      label: l10n.hiitSets,
                      value: '$_sets',
                      onDecrement: _sets > 1
                          ? () {
                              setSheetState(() => _sets--);
                              setState(() {});
                            }
                          : null,
                      onIncrement: _sets < 10
                          ? () {
                              setSheetState(() => _sets++);
                              setState(() {});
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Work duration
                    _buildSettingsTimeRow(
                      label: l10n.hiitWorkDuration,
                      value: _workSeconds,
                      min: HiitConfig.minWorkSeconds,
                      max: HiitConfig.maxWorkSeconds,
                      onChanged: (v) {
                        setSheetState(() => _workSeconds = v);
                        setState(() {});
                      },
                    ),

                    // Rest between exercises
                    _buildSettingsTimeRow(
                      label: l10n.hiitRestDuration,
                      value: _restSeconds,
                      min: HiitConfig.minRestSeconds,
                      max: HiitConfig.maxRestSeconds,
                      onChanged: (v) {
                        setSheetState(() => _restSeconds = v);
                        setState(() {});
                      },
                    ),

                    // Rest between sets
                    _buildSettingsTimeRow(
                      label: l10n.hiitSetRestDuration,
                      value: _setRestSeconds,
                      min: HiitConfig.minSetRestSeconds,
                      max: HiitConfig.maxSetRestSeconds,
                      onChanged: (v) {
                        setSheetState(() => _setRestSeconds = v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startRoutine() async {
    final exercises = _routineExercises;
    if (exercises.isEmpty) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HiitTimerScreen(
          exercises: exercises,
          routineName: _currentRoutine.name,
          sets: _sets,
          workSeconds: _workSeconds,
          restSeconds: _restSeconds,
          setRestSeconds: _setRestSeconds,
          hiitSessionPort: widget.hiitSessionPort,
          autoStart: true,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoutine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.routineExport,
            onPressed: _handleExport,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final exercises = _routineExercises;

    return Column(
      children: [
        // Header info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_totalDurationSeconds),
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.format_list_numbered,
                  size: 20, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                l10n.hiitExerciseCount('${exercises.length}'),
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.repeat, size: 20, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                l10n.hiitSetCount('$_sets'),
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ],
          ),
        ),

        // Config summary chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.fitness_center, size: 16),
                label: Text(l10n.hiitSeconds('$_workSeconds')),
              ),
              Chip(
                avatar: const Icon(Icons.pause, size: 16),
                label: Text(l10n.hiitSeconds('$_restSeconds')),
              ),
              Chip(
                avatar: const Icon(Icons.snooze, size: 16),
                label: Text(l10n.hiitSeconds('$_setRestSeconds')),
              ),
            ],
          ),
        ),
        const Divider(),

        // Exercise header with edit button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.hiitSelectExercises,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: l10n.hiitEditExercises,
                color: Colors.white54,
                onPressed: _editExercises,
              ),
            ],
          ),
        ),

        // Exercise cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white12,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exercise.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            if (exercise.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                exercise.description,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom action buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Settings + Start row
                Row(
                  children: [
                    // Settings button
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _showSettings,
                        icon: const Icon(Icons.settings, size: 18),
                        label: Text(l10n.hiitConfig),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Start button
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _startRoutine,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.sharedStart),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Delete button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTimeRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          TimeWheelPicker(
            minSeconds: min,
            maxSeconds: max,
            stepSeconds: HiitConfig.stepSeconds,
            selectedSeconds: value,
            onChanged: onChanged,
            height: 100,
            width: 80,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    this.onDecrement,
    this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrement,
              iconSize: 20,
            ),
            SizedBox(
              width: 28,
              child: Text(value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrement,
              iconSize: 20,
            ),
          ],
        ),
      ],
    );
  }
}
