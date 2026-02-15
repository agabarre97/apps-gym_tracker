import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';

/// Adapter implementing [WorkoutSessionPort] using [StoragePort].
class WorkoutSessionDatasource implements WorkoutSessionPort {
  const WorkoutSessionDatasource(this._storage);

  final StoragePort _storage;
  static const _key = 'workout_sessions';

  @override
  Future<List<WorkoutSession>> loadSessions() async {
    final raw = await _storage.get(_key);
    if (raw == null || raw.isEmpty) return [];
    return WorkoutSession.listFromJsonString(raw);
  }

  @override
  Future<void> saveSessions(List<WorkoutSession> sessions) =>
      _storage.set(_key, WorkoutSession.listToJsonString(sessions));
}
