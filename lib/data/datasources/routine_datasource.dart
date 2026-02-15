import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

/// Adapter implementing [RoutinePort] using [StoragePort].
class RoutineDatasource implements RoutinePort {
  const RoutineDatasource(this._storage);

  final StoragePort _storage;
  static const _key = 'routines';

  @override
  Future<List<Routine>> loadRoutines() async {
    final raw = await _storage.get(_key);
    if (raw == null) return [];
    return Routine.listFromJsonString(raw);
  }

  @override
  Future<void> saveRoutines(List<Routine> routines) =>
      _storage.set(_key, Routine.listToJsonString(routines));
}
