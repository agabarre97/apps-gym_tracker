import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/ports/custom_exercise_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

class CustomExerciseDatasource implements CustomExercisePort {
  const CustomExerciseDatasource(this._storage);

  final StoragePort _storage;
  static const _key = 'custom_exercises';

  @override
  Future<List<Exercise>> loadExercises() async {
    final raw = await _storage.get(_key);
    if (raw == null || raw.isEmpty) return const [];
    return Exercise.listFromJsonString(raw);
  }

  @override
  Future<void> saveExercises(List<Exercise> exercises) =>
      _storage.set(_key, Exercise.listToJsonString(exercises));

  @override
  Future<void> deleteExercise(String key) async {
    final exercises = await loadExercises();
    final filteredExercises =
        exercises.where((exercise) => exercise.key != key).toList();
    await saveExercises(filteredExercises);
  }
}
