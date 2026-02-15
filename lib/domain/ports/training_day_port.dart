import 'package:gym_tracker/domain/entities/training_day.dart';

/// Port for training-day persistence.
abstract class TrainingDayPort {
  Future<List<TrainingDay>> loadTrainingDays();
  Future<void> saveTrainingDays(List<TrainingDay> days);
}
