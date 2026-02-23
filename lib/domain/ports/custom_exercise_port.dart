import 'package:gym_tracker/domain/entities/exercise.dart';

abstract class CustomExercisePort {
  Future<List<Exercise>> loadExercises();
  Future<void> saveExercises(List<Exercise> exercises);
  Future<void> deleteExercise(String key);
}
