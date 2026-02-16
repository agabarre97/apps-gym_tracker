import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
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
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    final exercises = await Exercise.loadFromAsset(lang);
    if (!mounted) return;
    setState(() {
      _routines = routines;
      _allExercises = exercises;
      _sessions = sessions;
      _trainingDays = days.map((d) => _normalise(d.date)).toSet();
      _loading = false;
    });
  }

  DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  String _typeLabelFor(String type, AppLocalizations l10n) =>
      RoutineTypeHelper.labelFor(type, l10n);

  List<Routine> get _filteredRoutines {
    if (_routineTypeFilter == null) return _routines;
    return _routines.where((r) => r.type == _routineTypeFilter).toList();
  }

  /// Unique routine types present in the saved routines.
  List<String> get _availableTypes {
    final types = _routines.map((r) => r.type).toSet().toList();
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
    await _startWorkoutFlow(
        trackTime: false, date: _normalise(_selectedDay!));
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
          routines: _routines,
          onRoutineSelected: (r) => Navigator.of(context).pop(r),
        ),
      ),
    );
    if (routine == null || !mounted) return;

    // Mobility routine: go straight to timer
    if (routine.recommendedRoutineKey != null) {
      await _startMobilityFlow(routine, date);
      return;
    }

    // HIIT routine: open detail screen (which has its own timer entry)
    if (routine.type == 'hiit') {
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

    // Step 3: build session with auto-complete from previous
    final session = _buildNewSession(
      routine: routine,
      dayIndex: dayIndex,
      date: date,
      trackTime: trackTime,
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

  /// Loads the mobility routine asset and navigates to the timer screen.
  Future<void> _startMobilityFlow(Routine routine, DateTime date) async {
    final l10n = AppLocalizations.of(context)!;
    MobilityRoutine mobilityRoutine;
    try {
      mobilityRoutine = await MobilityRoutine.loadFromAsset(
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
        ),
      ),
    );

    if (result == true && mounted) {
      await _markDayTrained(date);
      _loadData();
    }
  }

  /// Opens existing workout sessions for the selected day.
  /// If there is only one session, goes directly to it.
  /// If multiple, shows a bottom sheet picker.
  Future<void> _viewSessionsForDay() async {
    final daySessions = _sessionsForSelectedDay;
    if (daySessions.isEmpty) return;

    if (daySessions.length == 1) {
      await _navigateToSession(daySessions.first);
    } else {
      await _showSessionPicker(daySessions);
    }
  }

  Future<void> _navigateToSession(WorkoutSession session) async {
    // Find the routine name
    String routineName = '';
    for (final r in _routines) {
      if (r.id == session.routineId) {
        routineName = r.name;
        break;
      }
    }
    if (routineName.isEmpty) routineName = session.routineId;

    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          session: session,
          allExercises: _allExercises,
          workoutSessionPort: widget.workoutSessionPort,
          routineName: routineName,
          trackTime: false, // no time tracking when viewing
        ),
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  /// Shows a bottom sheet listing all sessions for a given day.
  Future<void> _showSessionPicker(List<WorkoutSession> sessions) async {
    final l10n = AppLocalizations.of(context)!;

    final selected = await showModalBottomSheet<WorkoutSession>(
      context: context,
      builder: (ctx) {
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
              ...sessions.map((session) {
                final routineName = _routineNameForId(session.routineId);
                final dayLabel =
                    l10n.workoutDayLabel('${session.routineDayIndex + 1}');
                final timeInfo = _sessionTimeInfo(session, l10n);

                return ListTile(
                  leading: const Icon(Icons.fitness_center,
                      color: Colors.white70),
                  title: Text(routineName),
                  subtitle: Text(
                    '$dayLabel · $timeInfo',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white54),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.white38),
                  onTap: () => Navigator.pop(ctx, session),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await _navigateToSession(selected);
    }
  }

  String _routineNameForId(String routineId) {
    for (final r in _routines) {
      if (r.id == routineId) return r.name;
    }
    return routineId;
  }

  String _sessionTimeInfo(WorkoutSession session, AppLocalizations l10n) {
    if (session.startTime == null) return l10n.workoutSessionNoTime;
    final start = _formatTime(session.startTime!);
    final end = session.endTime != null
        ? _formatTime(session.endTime!)
        : '...';
    return l10n.workoutSessionTime(start, end);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Creates a [WorkoutSession] auto-filled from the last session of the same
  /// routine+day, or with 3 empty sets per exercise.
  WorkoutSession _buildNewSession({
    required Routine routine,
    required int dayIndex,
    required DateTime date,
    required bool trackTime,
  }) {
    final day = routine.days[dayIndex];

    // Find previous session for same routine + day
    final previous = _sessions
        .where((s) =>
            s.routineId == routine.id && s.routineDayIndex == dayIndex)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final prevSession = previous.isNotEmpty ? previous.first : null;

    // Build exercise list
    final exercises = day.exerciseKeys.map((key) {
      // Try to auto-fill from previous session
      if (prevSession != null) {
        final prevEx = prevSession.exercises
            .where((e) => e.exerciseKey == key)
            .toList();
        if (prevEx.isNotEmpty) {
          return WorkoutExercise(
            exerciseKey: key,
            sets: prevEx.first.sets
                .map((s) => ExerciseSet(reps: s.reps, weight: s.weight))
                .toList(),
            notes: '',
            completed: false,
          );
        }
      }
      return WorkoutExercise.empty(key);
    }).toList();

    return WorkoutSession(
      id: const Uuid().v4(),
      routineId: routine.id,
      routineDayIndex: dayIndex,
      date: date,
      startTime: trackTime ? DateTime.now() : null,
      exercises: exercises,
    );
  }

  /// Returns all workout sessions for the selected day.
  List<WorkoutSession> get _sessionsForSelectedDay {
    if (_selectedDay == null) return [];
    final norm = _normalise(_selectedDay!);
    return _sessions.where((s) => _normalise(s.date) == norm).toList();
  }

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar → profile
                  IconButton(
                    icon: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 18, color: Colors.white70),
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
                    // Show "View details" if there are sessions for this day
                    if (_sessionsForSelectedDay.isNotEmpty) ...[
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

                  // ── Type filter chips ──
                  if (_availableTypes.length > 1) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(l10n.landingFilterAll),
                              selected: _routineTypeFilter == null,
                              onSelected: (_) => setState(
                                  () => _routineTypeFilter = null),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          ..._availableTypes.map(
                            (type) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(_typeLabelFor(type, l10n)),
                                selected: _routineTypeFilter == type,
                                onSelected: (_) => setState(
                                    () => _routineTypeFilter = type),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ],
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
        // Merge: consider both TrainingDay marks and actual workout sessions
        final hasTrainingDay = _trainingDays.contains(norm);
        final hasSession = _sessions.any((s) => _normalise(s.date) == norm);
        return (hasTrainingDay || hasSession) ? ['trained'] : [];
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
        leading: Icon(RoutineTypeHelper.iconFor(routine.type), color: Colors.white70),
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
