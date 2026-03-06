import 'package:flutter/material.dart';
import 'package:gym_tracker/data/datasources/asset_data_loader.dart';
import 'package:gym_tracker/domain/entities/mobility_exercise_info.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/services/routine_pdf_export_service.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/delete_routine_dialog.dart';
import 'package:gym_tracker/presentation/components/export_sheet.dart';
import 'package:gym_tracker/presentation/components/mobility_exercise_detail_sheet.dart';
import 'package:gym_tracker/presentation/components/mobility_exercise_tile.dart';
import 'package:gym_tracker/presentation/components/pdf_share_helper.dart';
import 'package:gym_tracker/presentation/screens/mobility/mobility_timer_screen.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Detail screen for a mobility routine.
///
/// Shows every exercise in its own card (no day grouping).
/// Start and delete buttons at the bottom, properly spaced.
class MobilityRoutineDetailScreen extends StatefulWidget {
  const MobilityRoutineDetailScreen({
    super.key,
    required this.routine,
    required this.allRoutines,
    required this.routinePort,
    required this.mobilitySessionPort,
  });

  final Routine routine;
  final List<Routine> allRoutines;
  final RoutinePort routinePort;
  final MobilitySessionPort mobilitySessionPort;

  @override
  State<MobilityRoutineDetailScreen> createState() =>
      _MobilityRoutineDetailScreenState();
}

class _MobilityRoutineDetailScreenState
    extends State<MobilityRoutineDetailScreen> {
  MobilityRoutine? _mobilityRoutine;
  Map<String, MobilityExerciseInfo> _exerciseInfoMap = const {};
  bool _loading = true;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _loadRoutine();
    }
  }

  Future<void> _loadRoutine() async {
    final key = widget.routine.recommendedRoutineKey;
    if (key == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final results = await Future.wait([
        AssetDataLoader.loadMobilityRoutine(key),
        AssetDataLoader.loadMobilityExerciseInfo(lang),
      ]);
      setState(() {
        _mobilityRoutine = results[0] as MobilityRoutine;
        _exerciseInfoMap = results[1] as Map<String, MobilityExerciseInfo>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _handleExport() => showExportSheet(
        context,
        jsonString: widget.routine.toExportJsonString(),
        onExportPdf: _exportPdf,
      );

  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final sessions = await widget.mobilitySessionPort.loadSessions();
      final routineSessions = sessions
          .where((session) =>
              session.routineKey == widget.routine.recommendedRoutineKey)
          .toList()
        ..sort(_compareSessionDesc);
      final latestSession =
          routineSessions.isEmpty ? null : routineSessions.first;

      final bytes = await RoutinePdfExportService.buildMobilityRoutinePdf(
        routine: widget.routine,
        mobilityRoutine: _mobilityRoutine,
        lastSession: latestSession,
        generatedAt: DateTime.now(),
        exerciseNameByKey: {
          if (_mobilityRoutine != null)
            for (final exercise in _mobilityRoutine!.exercises)
              exercise.key: mobilityExerciseDisplayName(exercise.key, l10n),
        },
      );

      await sharePdfBytes(
        pdfBytes: bytes,
        fileName: 'rutina_movilidad_${widget.routine.name}_export.pdf',
      );
    } catch (error, stackTrace) {
      debugPrint('Mobility PDF export failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineExportPdfError)),
      );
    }
  }

  int _compareSessionDesc(MobilitySession a, MobilitySession b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    final aStart = a.startTime;
    final bStart = b.startTime;
    if (aStart == null && bStart == null) return 0;
    if (aStart == null) return 1;
    if (bStart == null) return -1;
    return bStart.compareTo(aStart);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDeleteRoutineDialog(
      context,
      routineName: widget.routine.name,
    );

    if (confirmed != true || !mounted) return;

    final updated = widget.allRoutines.map((r) {
      return r.id == widget.routine.id ? r.copyWith(isArchived: true) : r;
    }).toList();
    await widget.routinePort.saveRoutines(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _startRoutine() async {
    final mr = _mobilityRoutine;
    if (mr == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MobilityTimerScreen(
          routine: mr,
          mobilitySessionPort: widget.mobilitySessionPort,
          routineName: widget.routine.name,
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
        title: Text(widget.routine.name),
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
          : _mobilityRoutine == null
              ? Center(
                  child: Text(
                    l10n.mobilityRoutineNotFound,
                    style: TextStyle(color: context.textSecondary),
                  ),
                )
              : _buildContent(l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final mr = _mobilityRoutine!;

    return Column(
      children: [
        // Header info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 20, color: context.textSecondary),
              const SizedBox(width: 8),
              Text(
                l10n.mobilityRoutineDuration('${mr.totalDurationMinutes}'),
                style: TextStyle(fontSize: 14, color: context.textSecondary),
              ),
              const SizedBox(width: 24),
              Icon(Icons.format_list_numbered,
                  size: 20, color: context.textSecondary),
              const SizedBox(width: 8),
              Text(
                l10n.mobilityRoutineExerciseCount('${mr.exercises.length}'),
                style: TextStyle(fontSize: 14, color: context.textSecondary),
              ),
            ],
          ),
        ),
        const Divider(),

        // Exercise cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: mr.exercises.length,
            itemBuilder: (context, index) {
              final exercise = mr.exercises[index];
              final info = _exerciseInfoMap[exercise.key];
              return MobilityExerciseTile(
                exercise: exercise,
                index: index,
                l10n: l10n,
                variant: MobilityExerciseTileVariant.detailed,
                onTap: info != null
                    ? () => showMobilityExerciseDetailSheet(
                          context,
                          exercise: exercise,
                          info: info,
                        )
                    : null,
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
                // Start button
                SizedBox(
                  width: double.infinity,
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
                const SizedBox(height: 10),
                // Delete button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
