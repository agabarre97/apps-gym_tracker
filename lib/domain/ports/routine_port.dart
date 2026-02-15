import 'package:gym_tracker/domain/entities/routine.dart';

/// Port for routine persistence.
abstract class RoutinePort {
  Future<List<Routine>> loadRoutines();
  Future<void> saveRoutines(List<Routine> routines);
}
