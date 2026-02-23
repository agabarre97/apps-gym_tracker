import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/custom_exercise_datasource.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

class _InMemoryStoragePort implements StoragePort {
  final Map<String, String> _store = {};

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> set(String key, String value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);
}

void main() {
  test(
      'CustomExerciseDatasource saveExercises persists and loadExercises restores data',
      () async {
    final storage = _InMemoryStoragePort();
    final datasource = CustomExerciseDatasource(storage);

    const exercises = [
      Exercise(
        key: 'custom_push_up',
        name: 'Custom Push Up',
        description: 'Desc',
        muscleGroups: ['chest'],
        difficulty: 2,
        categoryKeys: ['chest'],
      ),
    ];

    await datasource.saveExercises(exercises);
    final loaded = await datasource.loadExercises();

    expect(loaded.length, 1);
    expect(loaded.first.key, 'custom_push_up');
    expect(loaded.first.name, 'Custom Push Up');
    expect(loaded.first.categoryKeys, ['chest']);
  });
}
