import 'package:gym_tracker/domain/entities/workout_session.dart';

/// Port for workout-session persistence.
abstract class WorkoutSessionPort {
  Future<List<WorkoutSession>> loadSessions();
  Future<void> saveSessions(List<WorkoutSession> sessions);
}
