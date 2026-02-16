import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';

/// Pure-domain helper that builds a new [WorkoutSession] for a given routine
/// day, optionally pre-filling sets from the most recent matching session.
///
/// This was extracted from `LandingScreen` to keep the screen focused on
/// navigation and UI, while the session-creation logic stays in the domain.
class WorkoutSessionBuilder {
  const WorkoutSessionBuilder._();

  /// Builds a [WorkoutSession] for the given [routine] and [dayIndex],
  /// auto-filling exercise sets from the latest matching session in
  /// [previousSessions] when available.
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

    // Find previous session for same routine + day
    final matching = previousSessions
        .where((s) =>
            s.routineId == routine.id && s.routineDayIndex == dayIndex)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final prevSession = matching.isNotEmpty ? matching.first : null;

    // Build exercise list
    final exercises = day.exerciseKeys.map((key) {
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
