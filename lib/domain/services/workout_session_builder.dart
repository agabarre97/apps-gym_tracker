import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';

/// Pure-domain helper that builds a new [WorkoutSession] for a given routine
/// day, optionally pre-filling sets from the most recent matching session.
///
/// This was extracted from `LandingScreen` to keep the screen focused on
/// navigation and UI, while the session-creation logic stays in the domain.
class WorkoutSessionBuilder {
  const WorkoutSessionBuilder._();

  static DateTime _effectiveSessionTime(WorkoutSession session) {
    return session.startTime ?? session.date;
  }

  static List<ExerciseSet> _buildSetsFromConfig({
    required RoutineExerciseConfig config,
    required List<ExerciseSet> previousSets,
  }) {
    return List<ExerciseSet>.generate(
      config.sets,
      (index) {
        if (index < previousSets.length) {
          final previous = previousSets[index];
          return ExerciseSet(reps: previous.reps, weight: previous.weight);
        }
        return ExerciseSet(reps: config.targetReps, weight: 0);
      },
      growable: false,
    );
  }

  /// Builds a [WorkoutSession] for the given [routine] and [dayIndex],
  /// auto-filling exercise sets from the latest matching session in
  /// [previousSessions] that is not later than the target session time.
  ///
  /// - [id]: unique session identifier (typically a UUID).
  /// - [date]: calendar date for the session.
  /// - [trackTime]: if true, records the current time as [startTime].
  static WorkoutSession build({
    required String id,
    required Routine routine,
    required int dayIndex,
    required DateTime date,
    required bool trackTime,
    required List<WorkoutSession> previousSessions,
    DateTime? overrideStartTime,
    DateTime? overrideEndTime,
  }) {
    final day = routine.days[dayIndex];
    final targetSessionTime = overrideStartTime ?? date;

    // Find previous session for same routine + day, strictly in the past
    // (or exact same timestamp), relative to the target session time.
    final matching = previousSessions
        .where((session) =>
            session.routineId == routine.id &&
            session.routineDayIndex == dayIndex &&
            !_effectiveSessionTime(session).isAfter(targetSessionTime))
        .toList()
      ..sort((a, b) =>
          _effectiveSessionTime(b).compareTo(_effectiveSessionTime(a)));

    final prevSession = matching.isNotEmpty ? matching.first : null;

    // Build exercise list
    final exercises = day.exerciseKeys.map((key) {
      final config =
          day.configForExercise(key) ?? RoutineExerciseConfig(exerciseKey: key);
      if (prevSession != null) {
        final prevEx =
            prevSession.exercises.where((e) => e.exerciseKey == key).toList();
        if (prevEx.isNotEmpty) {
          return WorkoutExercise(
            exerciseKey: key,
            sets: _buildSetsFromConfig(
              config: config,
              previousSets: prevEx.first.sets,
            ),
            notes: '',
            completed: false,
            restSeconds: config.restSeconds,
          );
        }
      }
      return WorkoutExercise(
        exerciseKey: key,
        sets: _buildSetsFromConfig(config: config, previousSets: const []),
        restSeconds: config.restSeconds,
      );
    }).toList();

    return WorkoutSession(
      id: id,
      routineId: routine.id,
      routineDayIndex: dayIndex,
      date: date,
      startTime: overrideStartTime ?? (trackTime ? DateTime.now() : null),
      endTime: overrideEndTime,
      exercises: exercises,
    );
  }
}
