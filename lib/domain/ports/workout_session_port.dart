import 'package:gym_tracker/domain/entities/workout_session.dart';

/// Port for workout-session persistence.
abstract class WorkoutSessionPort {
  Future<List<WorkoutSession>> loadSessions();
  Future<void> saveSessions(List<WorkoutSession> sessions);

  /// Insert or replace a single [session] by its [WorkoutSession.id].
  ///
  /// Implementations should update the stored entry in-place without rewriting
  /// the entire list to avoid O(n) read-modify-write on every set completion.
  ///
  /// Default implementation falls back to load → replace → save so existing
  /// adapters remain functional without code changes.
  Future<void> upsertSession(WorkoutSession session) async {
    final all = await loadSessions();
    final index = all.indexWhere((s) => s.id == session.id);
    final updated = List<WorkoutSession>.from(all);
    if (index >= 0) {
      updated[index] = session;
    } else {
      updated.add(session);
    }
    await saveSessions(updated);
  }
}
