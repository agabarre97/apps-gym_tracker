import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:gym_tracker/data/datasources/asset_data_loader.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/services/workout_session_builder.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/domain/ports/auth_port.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/domain/ports/sync_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/domain/ports/training_day_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/domain/ports/hiit_session_port.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/components/language_selector.dart';
import 'package:gym_tracker/presentation/components/routine_type_helper.dart';
import 'package:gym_tracker/presentation/screens/auth/auth_screen.dart';
import 'package:gym_tracker/presentation/screens/profile_summary_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/create_routine_flow.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_detail_screen.dart';
import 'package:gym_tracker/presentation/screens/mobility/mobility_routine_detail_screen.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_detail_screen.dart';
import 'package:gym_tracker/presentation/screens/workout/routine_picker_screen.dart';
import 'package:gym_tracker/presentation/screens/workout/day_picker_screen.dart';
import 'package:gym_tracker/presentation/screens/workout/workout_session_screen.dart';
import 'package:gym_tracker/presentation/screens/mobility/mobility_timer_screen.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:uuid/uuid.dart';

// ── Unified training entry for the day view ──────────────────────

enum _TrainingEntryType { workout, mobility, hiit }

class _TrainingEntry {
  const _TrainingEntry({
    required this.type,
    required this.id,
    required this.displayName,
    this.subtitle,
    this.startTime,
    this.endTime,
    this.workoutSession,
    this.mobilitySession,
    this.hiitSession,
  });

  final _TrainingEntryType type;
  final String id;
  final String displayName;
  final String? subtitle;
  final DateTime? startTime;
  final DateTime? endTime;
  final WorkoutSession? workoutSession;
  final MobilitySession? mobilitySession;
  final HiitSession? hiitSession;

  IconData get icon {
    switch (type) {
      case _TrainingEntryType.workout:
        return Icons.fitness_center;
      case _TrainingEntryType.mobility:
        return Icons.self_improvement;
      case _TrainingEntryType.hiit:
        return Icons.timer;
    }
  }
}

/// Main landing screen shown after onboarding is complete.
///
/// Contains: calendar, "Train" button, routines list, profile avatar.
class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    required this.storage,
    required this.profilePort,
    required this.routinePort,
    required this.trainingDayPort,
    required this.workoutSessionPort,
    required this.mobilitySessionPort,
    required this.hiitSessionPort,
    required this.onLocaleChanged,
    this.authPort,
    this.syncedStorage,
  });

  final StoragePort storage;
  final ProfilePort profilePort;
  final RoutinePort routinePort;
  final TrainingDayPort trainingDayPort;
  final WorkoutSessionPort workoutSessionPort;
  final MobilitySessionPort mobilitySessionPort;
  final HiitSessionPort hiitSessionPort;
  final ValueChanged<Locale> onLocaleChanged;
  final AuthPort? authPort;
  final SyncPort? syncedStorage;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<Routine> _routines = [];
  List<Exercise> _allExercises = [];
  List<WorkoutSession> _sessions = [];
  List<MobilitySession> _mobilitySessions = [];
  List<HiitSession> _hiitSessions = [];
  Set<DateTime> _trainingDays = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  String? _routineTypeFilter; // null = all

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final routines = await widget.routinePort.loadRoutines();
    final days = await widget.trainingDayPort.loadTrainingDays();
    final sessions = await widget.workoutSessionPort.loadSessions();
    final mobilitySessions = await widget.mobilitySessionPort.loadSessions();
    final hiitSessions = await widget.hiitSessionPort.loadSessions();
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    final exercises = await AssetDataLoader.loadExercises(lang);
    if (!mounted) return;
    setState(() {
      _routines = routines;
      _allExercises = exercises;
      _sessions = sessions;
      _mobilitySessions = mobilitySessions;
      _hiitSessions = hiitSessions;
      _trainingDays = days.map((d) => _normalise(d.date)).toSet();
      _loading = false;
    });
  }

  DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  String _typeLabelFor(String type, AppLocalizations l10n) =>
      RoutineTypeHelper.labelFor(type, l10n);

  /// Active (non-archived) routines, optionally filtered by type.
  List<Routine> get _filteredRoutines {
    final active = _routines.where((r) => !r.isArchived);
    if (_routineTypeFilter == null) return active.toList();
    return active.where((r) => r.type == _routineTypeFilter).toList();
  }

  /// Unique routine types present in the active (non-archived) routines.
  List<String> get _availableTypes {
    final types = _routines
        .where((r) => !r.isArchived)
        .map((r) => r.type)
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  // ── Routines ──────────────────────────────────────────────────

  Future<void> _openCreateRoutineFlow() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateRoutineFlow(
          routinePort: widget.routinePort,
          existingRoutines: _routines,
        ),
      ),
    );
    if (result == true) {
      _loadData(); // reload routines
    }
  }

  /// Whether the selected day is today or in the past (not a future day).
  bool get _isSelectedDayPastOrToday {
    if (_selectedDay == null) return false;
    final today = _normalise(DateTime.now());
    final sel = _normalise(_selectedDay!);
    return !sel.isAfter(today);
  }

  /// Marks a day as trained in the calendar.
  Future<void> _markDayTrained(DateTime day) async {
    final norm = _normalise(day);
    if (_trainingDays.contains(norm)) return;
    setState(() => _trainingDays.add(norm));
    final list = _trainingDays.map((d) => TrainingDay(date: d)).toList();
    await widget.trainingDayPort.saveTrainingDays(list);
  }

  // ── Workout flow ──────────────────────────────────────────────

  /// Starts the Train flow (with time tracking) from the Train button.
  Future<void> _startTrainFlow() async {
    if (_routines.isEmpty) return;
    await _startWorkoutFlow(trackTime: true, date: _normalise(DateTime.now()));
  }

  /// Starts the Add-training flow for a past or today day (no time tracking).
  Future<void> _startAddTrainingFlow() async {
    if (_routines.isEmpty || _selectedDay == null) return;
    await _startWorkoutFlow(trackTime: false, date: _normalise(_selectedDay!));
  }

  /// Navigates to RoutinePicker → DayPicker → WorkoutSession,
  /// or directly to MobilityTimerScreen for mobility routines.
  Future<void> _startWorkoutFlow({
    required bool trackTime,
    required DateTime date,
  }) async {
    // Step 1: pick routine
    final routine = await Navigator.of(context).push<Routine>(
      MaterialPageRoute(
        builder: (_) => RoutinePickerScreen(
          routines: _routines.where((r) => !r.isArchived).toList(),
          onRoutineSelected: (r) => Navigator.of(context).pop(r),
        ),
      ),
    );
    if (routine == null || !mounted) return;

    // ── Mobility / HIIT quick-log (calendar add, no timer) ──
    final isMobility = routine.recommendedRoutineKey != null;
    final isHiit = routine.type == 'hiit';

    if (!trackTime && (isMobility || isHiit)) {
      await _quickLogTraining(routine, date);
      return;
    }

    // Mobility routine: go straight to timer
    if (isMobility) {
      await _startMobilityFlow(routine, date);
      return;
    }

    // HIIT routine: open detail screen (which has its own timer entry)
    if (isHiit) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => HiitDetailScreen(
            routine: routine,
            allRoutines: _routines,
            routinePort: widget.routinePort,
            hiitSessionPort: widget.hiitSessionPort,
          ),
        ),
      );
      if (result == true && mounted) {
        await _markDayTrained(date);
        _loadData();
      }
      return;
    }

    // Step 2: pick day
    final dayIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => DayPickerScreen(
          routine: routine,
          onDaySelected: (i) => Navigator.of(context).pop(i),
        ),
      ),
    );
    if (dayIndex == null || !mounted) return;

    // Step 2b: optional time input for retroactive entries
    DateTime? retroStartTime;
    DateTime? retroEndTime;
    if (!trackTime) {
      final l10n = AppLocalizations.of(context)!;
      final times = await _showTimeInputPage(l10n);
      if (times == null || !mounted) return;
      if (times.start != null) {
        retroStartTime = date.add(
            Duration(hours: times.start!.hour, minutes: times.start!.minute));
      }
      if (times.end != null) {
        retroEndTime = date
            .add(Duration(hours: times.end!.hour, minutes: times.end!.minute));
      }
    }

    // Step 3: build session with auto-complete from previous
    final session = _buildNewSession(
      routine: routine,
      dayIndex: dayIndex,
      date: date,
      trackTime: trackTime,
      startTime: retroStartTime,
      endTime: retroEndTime,
    );

    // Step 4: navigate to workout screen
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          session: session,
          allExercises: _allExercises,
          workoutSessionPort: widget.workoutSessionPort,
          routineName: routine.name,
          trackTime: trackTime,
        ),
      ),
    );

    if (result == true && mounted) {
      await _markDayTrained(date);
      _loadData();
    }
  }

  /// Shows a time-input bottom sheet, then creates a real session record
  /// for mobility / HIIT routines added from the calendar.
  Future<void> _quickLogTraining(Routine routine, DateTime date) async {
    final l10n = AppLocalizations.of(context)!;
    final times = await _showTimeInputPage(l10n);
    if (times == null || !mounted) return; // user cancelled

    final isMobility = routine.recommendedRoutineKey != null;

    DateTime? toDateTime(TimeOfDay? t) =>
        t != null ? date.add(Duration(hours: t.hour, minutes: t.minute)) : null;

    final startDt = toDateTime(times.start);
    final endDt = toDateTime(times.end);

    if (isMobility) {
      final session = MobilitySession(
        id: const Uuid().v4(),
        routineKey: routine.recommendedRoutineKey!,
        date: date,
        startTime: startDt,
        endTime: endDt,
      );
      final all = [..._mobilitySessions, session];
      await widget.mobilitySessionPort.saveSessions(all);
    } else {
      final session = HiitSession(
        id: const Uuid().v4(),
        routineName: routine.name,
        date: date,
        startTime: startDt,
        endTime: endDt,
      );
      final all = [..._hiitSessions, session];
      await widget.hiitSessionPort.saveSessions(all);
    }

    await _markDayTrained(date);
    _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.landingTrainingMarked)),
    );
  }

  /// Navigates to a full-screen page with optional start/end time pickers.
  /// Returns a record with optional [TimeOfDay] values, or null if cancelled.
  Future<({TimeOfDay? start, TimeOfDay? end})?> _showTimeInputPage(
      AppLocalizations l10n) {
    return Navigator.of(context).push<({TimeOfDay? start, TimeOfDay? end})>(
      MaterialPageRoute(
        builder: (_) => _TimeInputPage(
          title: l10n.landingMarkTrainingTitle,
          startTimeLabel: l10n.landingOptionalStartTime,
          endTimeLabel: l10n.landingOptionalEndTime,
          noTimeLabel: l10n.landingNoTime,
          cancelLabel: l10n.sharedCancel,
          confirmLabel: l10n.landingMarkTrainingConfirm,
        ),
      ),
    );
  }

  /// Loads the mobility routine asset and navigates to the timer screen.
  Future<void> _startMobilityFlow(Routine routine, DateTime date) async {
    final l10n = AppLocalizations.of(context)!;
    MobilityRoutine mobilityRoutine;
    try {
      mobilityRoutine = await AssetDataLoader.loadMobilityRoutine(
        routine.recommendedRoutineKey!,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mobilityRoutineNotFound)),
      );
      return;
    }
    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MobilityTimerScreen(
          routine: mobilityRoutine,
          mobilitySessionPort: widget.mobilitySessionPort,
          routineName: routine.name,
          autoStart: true,
        ),
      ),
    );

    if (result == true && mounted) {
      await _markDayTrained(date);
      _loadData();
    }
  }

  // ── View / manage sessions for a day ────────────────────────────

  /// Opens the unified training list for the selected day.
  Future<void> _viewSessionsForDay() async {
    final entries = _entriesForSelectedDay;
    if (entries.isEmpty) return;

    await _showUnifiedSessionPicker(entries);
  }

  /// Builds a sorted list of [_TrainingEntry] for the selected day, merging
  /// workout, mobility and HIIT sessions. Entries with startTime come first
  /// (ascending), entries without startTime are appended at the end.
  List<_TrainingEntry> get _entriesForSelectedDay {
    if (_selectedDay == null) return [];
    final norm = _normalise(_selectedDay!);
    final l10n = AppLocalizations.of(context)!;

    final entries = <_TrainingEntry>[];

    // Workout sessions
    for (final s in _sessions) {
      if (_normalise(s.date) != norm) continue;
      entries.add(_TrainingEntry(
        type: _TrainingEntryType.workout,
        id: s.id,
        displayName: _routineNameForId(s.routineId),
        subtitle: l10n.workoutDayLabel('${s.routineDayIndex + 1}'),
        startTime: s.startTime,
        endTime: s.endTime,
        workoutSession: s,
      ));
    }

    // Mobility sessions
    for (final s in _mobilitySessions) {
      if (_normalise(s.date) != norm) continue;
      entries.add(_TrainingEntry(
        type: _TrainingEntryType.mobility,
        id: s.id,
        displayName: _mobilityRoutineName(s.routineKey, l10n),
        startTime: s.startTime,
        endTime: s.endTime,
        mobilitySession: s,
      ));
    }

    // HIIT sessions
    for (final s in _hiitSessions) {
      if (_normalise(s.date) != norm) continue;
      entries.add(_TrainingEntry(
        type: _TrainingEntryType.hiit,
        id: s.id,
        displayName: s.routineName,
        startTime: s.startTime,
        endTime: s.endTime,
        hiitSession: s,
      ));
    }

    // Sort: entries with startTime ascending, then those without
    entries.sort((a, b) {
      if (a.startTime != null && b.startTime != null) {
        return a.startTime!.compareTo(b.startTime!);
      }
      if (a.startTime != null) return -1;
      if (b.startTime != null) return 1;
      return 0;
    });

    return entries;
  }

  String _mobilityRoutineName(String routineKey, AppLocalizations l10n) {
    for (final r in _routines) {
      if (r.recommendedRoutineKey == routineKey) return r.name;
    }
    return l10n.landingTrainingTypeMobility;
  }

  Future<void> _navigateToWorkoutSession(WorkoutSession session) async {
    String routineName = _routineNameForId(session.routineId);

    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          session: session,
          allExercises: _allExercises,
          workoutSessionPort: widget.workoutSessionPort,
          routineName: routineName,
          trackTime: false,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  /// Shows a bottom sheet listing all training entries for the day.
  Future<void> _showUnifiedSessionPicker(List<_TrainingEntry> entries) async {
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            // Re-compute entries so deletions are reflected immediately
            final currentEntries = _entriesForSelectedDay;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l10n.workoutSessionsForDay,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...currentEntries.map((entry) {
                    final timeText = _entryTimeText(entry, l10n);
                    final subtitleParts = <String>[
                      _entryTypeLabel(entry, l10n),
                      if (entry.subtitle != null) entry.subtitle!,
                      timeText,
                    ];

                    return ListTile(
                      leading: Icon(entry.icon, color: Colors.white70),
                      title: Text(entry.displayName),
                      subtitle: Text(
                        subtitleParts.join(' · '),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            tooltip: l10n.landingDeleteTrainingConfirm,
                            onPressed: () async {
                              final navigator = Navigator.of(ctx);
                              await _confirmDeleteEntry(entry, l10n);
                              if (!mounted) return;
                              if (_entriesForSelectedDay.isEmpty) {
                                if (navigator.mounted) {
                                  navigator.pop();
                                }
                              } else {
                                setSheetState(() {});
                              }
                            },
                          ),
                          if (entry.type == _TrainingEntryType.workout)
                            const Icon(Icons.chevron_right,
                                color: Colors.white38),
                        ],
                      ),
                      onTap: entry.type == _TrainingEntryType.workout
                          ? () {
                              Navigator.pop(ctx);
                              _navigateToWorkoutSession(entry.workoutSession!);
                            }
                          : null,
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _entryTypeLabel(_TrainingEntry entry, AppLocalizations l10n) {
    switch (entry.type) {
      case _TrainingEntryType.workout:
        return l10n.landingTrainingTypeWorkout;
      case _TrainingEntryType.mobility:
        return l10n.landingTrainingTypeMobility;
      case _TrainingEntryType.hiit:
        return l10n.landingTrainingTypeHiit;
    }
  }

  String _entryTimeText(_TrainingEntry entry, AppLocalizations l10n) {
    if (entry.startTime == null) return l10n.landingNoTime;
    final start = _formatTime(entry.startTime!);
    final end = entry.endTime != null ? _formatTime(entry.endTime!) : '...';
    return l10n.workoutSessionTime(start, end);
  }

  /// Confirms and deletes a training entry for the selected day.
  Future<void> _confirmDeleteEntry(
      _TrainingEntry entry, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.landingDeleteTrainingTitle),
        content: Text(l10n.landingDeleteTrainingBody(entry.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.sharedCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.landingDeleteTrainingConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    switch (entry.type) {
      case _TrainingEntryType.workout:
        _sessions = _sessions.where((s) => s.id != entry.id).toList();
        await widget.workoutSessionPort.saveSessions(_sessions);
        break;
      case _TrainingEntryType.mobility:
        _mobilitySessions =
            _mobilitySessions.where((s) => s.id != entry.id).toList();
        await widget.mobilitySessionPort.saveSessions(_mobilitySessions);
        break;
      case _TrainingEntryType.hiit:
        _hiitSessions = _hiitSessions.where((s) => s.id != entry.id).toList();
        await widget.hiitSessionPort.saveSessions(_hiitSessions);
        break;
    }

    // Remove TrainingDay mark if no sessions remain for this day
    await _removeTrainingDayIfEmpty();

    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.landingTrainingDeleted)),
    );
  }

  /// Removes the TrainingDay marker for the selected day if no session records
  /// exist for it (across all three session types).
  Future<void> _removeTrainingDayIfEmpty() async {
    if (_selectedDay == null) return;
    final norm = _normalise(_selectedDay!);

    final hasWorkout = _sessions.any((s) => _normalise(s.date) == norm);
    final hasMobility =
        _mobilitySessions.any((s) => _normalise(s.date) == norm);
    final hasHiit = _hiitSessions.any((s) => _normalise(s.date) == norm);

    if (!hasWorkout && !hasMobility && !hasHiit) {
      _trainingDays.remove(norm);
      final list = _trainingDays.map((d) => TrainingDay(date: d)).toList();
      await widget.trainingDayPort.saveTrainingDays(list);
    }
  }

  String _routineNameForId(String routineId) {
    for (final r in _routines) {
      if (r.id == routineId) return r.name;
    }
    return routineId;
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Creates a [WorkoutSession] auto-filled from the closest previous session
  /// in time (same routine+day), or with 3 empty sets per exercise.
  WorkoutSession _buildNewSession({
    required Routine routine,
    required int dayIndex,
    required DateTime date,
    required bool trackTime,
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      WorkoutSessionBuilder.build(
        id: const Uuid().v4(),
        routine: routine,
        dayIndex: dayIndex,
        date: date,
        trackTime: trackTime,
        previousSessions: _sessions,
        overrideStartTime: startTime,
        overrideEndTime: endTime,
      );

  /// Whether any training entry exists for the selected day.
  bool get _hasEntriesForSelectedDay => _entriesForSelectedDay.isNotEmpty;

  Future<void> _openRoutineDetail(Routine routine) async {
    final bool? result;

    if (routine.recommendedRoutineKey != null) {
      result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MobilityRoutineDetailScreen(
            routine: routine,
            allRoutines: _routines,
            routinePort: widget.routinePort,
            mobilitySessionPort: widget.mobilitySessionPort,
          ),
        ),
      );
    } else if (routine.type == 'hiit') {
      result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => HiitDetailScreen(
            routine: routine,
            allRoutines: _routines,
            routinePort: widget.routinePort,
            hiitSessionPort: widget.hiitSessionPort,
          ),
        ),
      );
    } else {
      result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => RoutineDetailScreen(
            routine: routine,
            allRoutines: _routines,
            routinePort: widget.routinePort,
            allExercises: _allExercises,
            workoutSessionPort: widget.workoutSessionPort,
          ),
        ),
      );
    }

    if (result == true) {
      _loadData(); // reload after edit or delete
    }
  }

  // ── Sign out ───────────────────────────────────────────────────

  Future<void> _executeSignOut() async {
    final authPort = widget.authPort;
    if (authPort == null) return;

    await authPort.signOut();
    widget.syncedStorage?.setUserId(null);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => _SignedOutRedirect(
          authPort: authPort,
          syncedStorage: widget.syncedStorage!,
          profilePort: widget.profilePort,
          storage: widget.storage,
          routinePort: widget.routinePort,
          trainingDayPort: widget.trainingDayPort,
          workoutSessionPort: widget.workoutSessionPort,
          mobilitySessionPort: widget.mobilitySessionPort,
          hiitSessionPort: widget.hiitSessionPort,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
      (_) => false,
    );
  }

  // ── Navigation ─────────────────────────────────────────────────

  Future<void> _goToProfile() async {
    final profile = await widget.profilePort.loadProfile();
    if (!mounted || profile == null) return;

    final signedOut = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileSummaryScreen(
          profile: profile,
          storage: widget.storage,
          email: widget.authPort?.currentUser?.email,
          onSignOut: widget.authPort != null ? () => true : null,
        ),
      ),
    );

    if (signedOut == true && mounted) {
      await _executeSignOut();
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: avatar + language ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar → profile
                  IconButton(
                    icon: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child:
                          Icon(Icons.person, size: 18, color: Colors.white70),
                    ),
                    onPressed: _goToProfile,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Language toggle
                      LanguageSelector(
                        onLocaleChanged: widget.onLocaleChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Scrollable content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── Calendar ──
                  _buildCalendar(l10n),

                  // ── Calendar action buttons (today or past day) ──
                  if (_isSelectedDayPastOrToday) ...[
                    const SizedBox(height: 12),
                    // Always show "Add training" for past or today
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(l10n.landingAddTraining),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.greenAccent,
                          side: const BorderSide(color: Colors.greenAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _startAddTrainingFlow,
                      ),
                    ),
                    // Show "View workouts" if there are sessions for this day
                    if (_hasEntriesForSelectedDay) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.visibility, size: 20),
                          label: Text(l10n.landingViewDetails),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _viewSessionsForDay,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ] else
                    const SizedBox(height: 24),

                  // ── Train button ──
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _startTrainFlow,
                      child: Text(l10n.landingTrain),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Routines header + create ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.landingRoutines,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _openCreateRoutineFlow,
                        tooltip: l10n.landingCreateRoutine,
                      ),
                    ],
                  ),

                  // ── Type filter dropdown ──
                  if (_availableTypes.length > 1) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _routineTypeFilter,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            prefixIcon: const Icon(Icons.tune,
                                size: 18, color: Colors.white54),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.greenAccent),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          dropdownColor: const Color(0xFF2C2C2E),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          iconEnabledColor: Colors.white70,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                l10n.landingFilterAll,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            ..._availableTypes.map(
                              (type) => DropdownMenuItem<String?>(
                                value: type,
                                child: Text(
                                  _typeLabelFor(type, l10n),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _routineTypeFilter = value);
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // ── Routines list ──
                  if (_routines.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          l10n.landingNoRoutines,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    ..._filteredRoutines.map(
                      (routine) => _RoutineTile(
                        routine: routine,
                        onTap: () => _openRoutineDetail(routine),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(AppLocalizations l10n) {
    return TableCalendar(
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) =>
          _selectedDay != null && isSameDay(_selectedDay, day),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
      },
      onPageChanged: (focused) => _focusedDay = focused,
      calendarStyle: CalendarStyle(
        // Trained-day marker
        markerDecoration: const BoxDecoration(
          color: Colors.greenAccent,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(color: Colors.white),
        selectedDecoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white),
        defaultTextStyle: const TextStyle(color: Colors.white70),
        weekendTextStyle: const TextStyle(color: Colors.white54),
        outsideTextStyle: const TextStyle(color: Colors.white24),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white70),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white70),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white54, fontSize: 12),
        weekendStyle: TextStyle(color: Colors.white38, fontSize: 12),
      ),
      eventLoader: (day) {
        final norm = _normalise(day);
        final hasTrainingDay = _trainingDays.contains(norm);
        final hasWorkout = _sessions.any((s) => _normalise(s.date) == norm);
        final hasMobility =
            _mobilitySessions.any((s) => _normalise(s.date) == norm);
        final hasHiit = _hiitSessions.any((s) => _normalise(s.date) == norm);
        return (hasTrainingDay || hasWorkout || hasMobility || hasHiit)
            ? ['trained']
            : [];
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
      ),
      startingDayOfWeek: StartingDayOfWeek.monday,
      locale: Localizations.localeOf(context).languageCode,
    );
  }
}

// ── Routine tile ─────────────────────────────────────────────────

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.routine, this.onTap});

  final Routine routine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(RoutineTypeHelper.iconFor(routine.type),
            color: Colors.white70),
        title: Text(routine.name),
        subtitle: routine.days.isNotEmpty
            ? Text(
                l10n.routineDaysCount('${routine.days.length}'),
                style: const TextStyle(fontSize: 12, color: Colors.white38),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

// ── Time picker row for the time-input bottom sheet ──────────────

/// Full-screen page for optional start/end time input when logging a past
/// training. Returns a `({TimeOfDay? start, TimeOfDay? end})` record via
/// [Navigator.pop], or `null` if the user navigates back.
class _TimeInputPage extends StatefulWidget {
  const _TimeInputPage({
    required this.title,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.noTimeLabel,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String startTimeLabel;
  final String endTimeLabel;
  final String noTimeLabel;
  final String cancelLabel;
  final String confirmLabel;

  @override
  State<_TimeInputPage> createState() => _TimeInputPageState();
}

class _TimeInputPageState extends State<_TimeInputPage> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _TimePickerRow(
              label: widget.startTimeLabel,
              value: _startTime != null
                  ? _formatTime(_startTime!)
                  : widget.noTimeLabel,
              hasValue: _startTime != null,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _startTime ?? TimeOfDay.now(),
                );
                if (picked != null) setState(() => _startTime = picked);
              },
              onClear: _startTime != null
                  ? () => setState(() => _startTime = null)
                  : null,
            ),
            const SizedBox(height: 12),
            _TimePickerRow(
              label: widget.endTimeLabel,
              value: _endTime != null
                  ? _formatTime(_endTime!)
                  : widget.noTimeLabel,
              hasValue: _endTime != null,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
                );
                if (picked != null) setState(() => _endTime = picked);
              },
              onClear: _endTime != null
                  ? () => setState(() => _endTime = null)
                  : null,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(widget.cancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (start: _startTime, end: _endTime),
                    ),
                    child: Text(widget.confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: hasValue ? Colors.white : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.white38),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(Icons.access_time, size: 20, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

/// Helper widget that re-shows the AuthScreen after sign-out.
class _SignedOutRedirect extends StatelessWidget {
  const _SignedOutRedirect({
    required this.authPort,
    required this.syncedStorage,
    required this.profilePort,
    required this.storage,
    required this.routinePort,
    required this.trainingDayPort,
    required this.workoutSessionPort,
    required this.mobilitySessionPort,
    required this.hiitSessionPort,
    required this.onLocaleChanged,
  });

  final AuthPort authPort;
  final SyncPort syncedStorage;
  final ProfilePort profilePort;
  final StoragePort storage;
  final RoutinePort routinePort;
  final TrainingDayPort trainingDayPort;
  final WorkoutSessionPort workoutSessionPort;
  final MobilitySessionPort mobilitySessionPort;
  final HiitSessionPort hiitSessionPort;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      authPort: authPort,
      syncedStorage: syncedStorage,
      onAuthenticated: (authContext) {
        Navigator.of(authContext).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LandingScreen(
              storage: storage,
              profilePort: profilePort,
              routinePort: routinePort,
              trainingDayPort: trainingDayPort,
              workoutSessionPort: workoutSessionPort,
              mobilitySessionPort: mobilitySessionPort,
              hiitSessionPort: hiitSessionPort,
              onLocaleChanged: onLocaleChanged,
              authPort: authPort,
              syncedStorage: syncedStorage,
            ),
          ),
        );
      },
    );
  }
}
